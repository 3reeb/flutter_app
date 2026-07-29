// quantum_core.dart
library quantum_core;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:yaml/yaml.dart';
import 'dart:math' as math;

abstract final class QLNodeState {
  static const int idle = 0;
  static const int dirty = 1 << 0;
  static const int validating = 1 << 1;
  static const int hasError = 1 << 2;
  static const int hasWarning = 1 << 3;
  static const int syncing = 1 << 4;
  static const int hardwareLocked = 1 << 5;
  static const int streaming = 1 << 6;
  static const int disabled = 1 << 7;
  static const int readOnly = 1 << 8;
  static const int sleeping = 1 << 9;
  static const int custom1 = 1 << 10;
  static const int custom2 = 1 << 11;
  static const int custom3 = 1 << 12;
}

enum QLSleepPolicy { never, manual, auto }

class QLNodeError {
  final String message;
  final int severity; // 1 = warning, 2 = error
  const QLNodeError(this.message, {this.severity = 2});
}

typedef QLValidator<T> = QLNodeError? Function(T value, Object graph);
typedef QLAsyncValidator<T> = Future<QLNodeError?> Function(
    T value, Object graph);
// typedef QLMiddleware<T> = T Function(T incoming, T current);
typedef QLFastMiddleware<T> = T Function(T incoming, T current);
typedef QLValueTransform<T> = T Function(T incoming);

abstract final class QLFieldType {
  static const int string = 1;
  static const int number = 2;
  static const int boolean = 3;
  static const int date = 4;
  static const int json = 5;
  static const int object = 6;
  static const int relation = 7;
  static const int relationship = 8;
  static const int block = 9;
  static const int enumeration = 10;
  static const int array = 11;
  static const int tree = 12;
  static const int secure = 13;
  static const int lookup = 14;
  static const int textarea = 15;
  static const int media = 16;
  static const int bigInt = 17;
  static const int smallInt = 18;
  static const int decimal = 19;
  static const int char = 20;
  static const int flags = 21;
}

abstract final class QLFieldFlags {
  static const int none = 0;
  static const int isVirtual = 1 << 0;
  static const int isComputed = 1 << 1;
  static const int isRequired = 1 << 2;
  static const int hasMany = 1 << 3;
  static const int isUnique = 1 << 4;
  static const int isIndexed = 1 << 5;
  static const int isHidden = 1 << 6;
  static const int isReadOnly = 1 << 7;
}

abstract final class QLPathUtils {
  static final LinkedHashMap<String, List<dynamic>> _cache =
      LinkedHashMap<String, List<dynamic>>();
  static const int _maxCache = 4096;
  static final RegExp _splitter = RegExp(r'\.|\[|\]');

  @pragma('vm:prefer-inline')
  static List<dynamic> resolve(String path) {
    final cached = _cache.remove(path);
    if (cached != null) {
      _cache[path] = cached;
      return cached;
    }

    if (path.isEmpty) return const <dynamic>[];

    final List<dynamic> strides = <dynamic>[];
    int segmentStart = 0;
    for (int i = 0; i <= path.length; i++) {
      final bool isBreak;
      if (i == path.length) {
        isBreak = true;
      } else {
        final int code = path.codeUnitAt(i);
        isBreak = code == 46 || code == 91 || code == 93; // . [ ]
      }
      if (!isBreak) continue;
      if (i > segmentStart) {
        final String token = path.substring(segmentStart, i);
        final int? numIdx = int.tryParse(token);
        strides.add(numIdx ?? token);
      }
      segmentStart = i + 1;
    }

    final List<dynamic> immutableStrides = List<dynamic>.unmodifiable(strides);
    _cache[path] = immutableStrides;
    if (_cache.length > _maxCache) {
      _cache.remove(_cache.keys.first);
    }
    return immutableStrides;
  }

  @pragma('vm:prefer-inline')
  static String canonicalize(Iterable<dynamic> strides) {
    final iterator = strides.iterator;
    if (!iterator.moveNext()) return '';
    final StringBuffer sb = StringBuffer(iterator.current.toString());
    while (iterator.moveNext()) {
      final dynamic s = iterator.current;
      if (s is int) {
        sb.write('[$s]');
      } else {
        sb.write('.');
        sb.write(s.toString());
      }
    }
    return sb.toString();
  }

  static List<String> prefixes(String path) {
    final strides = resolve(path);
    if (strides.isEmpty) return const [];
    final List<String> out = <String>[];
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < strides.length; i++) {
      final dynamic s = strides[i];
      if (i == 0) {
        buffer.write(s.toString());
      } else if (s is int) {
        buffer.write('[$s]');
      } else {
        buffer.write('.');
        buffer.write(s.toString());
      }
      out.add(buffer.toString());
    }
    return out;
  }

  static String join(String base, String relative) {
    if (base.isEmpty) return relative;
    if (relative.isEmpty) return base;
    return '$base.$relative';
  }

  static String parentOf(String path) {
    final segs = resolve(path);
    if (segs.length <= 1) return '';
    return canonicalize(segs.sublist(0, segs.length - 1));
  }

  static String lastSegment(String path) {
    final segs = resolve(path);
    if (segs.isEmpty) return '';
    return segs.last.toString();
  }

  static void clearCache() => _cache.clear();
}

abstract class QLDisposable {
  void dispose();
}

class QLProjection {
  final Uint32List _mask;
  QLProjection(int fieldCount) : _mask = Uint32List((fieldCount + 31) >> 5);

  void select(int fieldIndex) {
    _mask[fieldIndex >> 5] |= (1 << (fieldIndex & 31));
  }

  bool isSelected(int fieldIndex) {
    return (_mask[fieldIndex >> 5] & (1 << (fieldIndex & 31))) != 0;
  }
}

class QLChangeBatch {
  final List<String> paths;
  const QLChangeBatch(this.paths);
}

class QLFieldPathView {
  final String path;
  const QLFieldPathView(this.path);
}

// ════════════════════════════════════════════════════════════════════════════
// NEW INJECTION: UNIVERSAL FORMAT PARSER (quantum_core.dart)
// ════════════════════════════════════════════════════════════════════════════

abstract final class QLFormatParser {
  /// Takes ANY string (JSON or YAML), auto-detects the format, parses it,
  /// and guarantees a framework-safe, fully mutable Dart Map.
  static Map<String, dynamic> parse(String rawString) {
    final cleanString = rawString.trimLeft();
    if (cleanString.isEmpty) return {};

    // 1. FAST PATH: JSON Auto-Detection
    if (cleanString.startsWith('{') || cleanString.startsWith('[')) {
      try {
        final decoded = jsonDecode(cleanString);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
      } catch (_) {
        // Silent catch: Fall back to YAML parser
      }
    }

    // 2. ROBUST PATH: YAML Parsing with Absolute Crash Immunity
    try {
      final yamlDoc = loadYaml(cleanString);
      final cleanMap = _cleanYamlNode(yamlDoc);
      return cleanMap is Map ? Map<String, dynamic>.from(cleanMap) : {};
    } catch (_) {
      // If the string is absolute garbage, return an empty map. Never crash.
      return {};
    }
  }

  static dynamic _cleanYamlNode(dynamic node) {
    if (node is YamlMap) {
      final map = <String, dynamic>{};
      for (final entry in node.entries) {
        map[entry.key.toString()] = _cleanYamlNode(entry.value);
      }
      return map;
    } else if (node is YamlList) {
      return node.map((item) => _cleanYamlNode(item)).toList(growable: true);
    }
    return node;
  }
}

abstract final class QParser {
  static const int _maxCap = 10000;
  static const int _maxCacheSize = 2048;

  static final Map<String, List<QSize>> _cache =
      LinkedHashMap<String, List<QSize>>();

  static List<QSize> parse(String template) {
    final trimmed = template.trim();
    if (trimmed.isEmpty) return const [QAuto()];

    final cached = _cache[trimmed];
    if (cached != null) return cached;

    final tokens = _tokenize(trimmed);
    final resolved = _flatten(tokens.map(_evalToken).toList(growable: false));

    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[trimmed] = resolved;
    return resolved;
  }

  static List<String> _tokenize(String s) {
    final tokens = <String>[];
    int depth = 0;
    int start = 0;

    for (int i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x28) {
        depth++;
      } else if (c == 0x29) {
        depth = math.max(0, depth - 1);
      } else if (c == 0x2C && depth == 0) {
        if (i > start) tokens.add(s.substring(start, i));
        start = i + 1;
      } else if (c == 0x20 && depth == 0) {
        if (i > start) tokens.add(s.substring(start, i));
        start = i + 1;
      }
    }
    if (start < s.length) tokens.add(s.substring(start));
    return tokens.where((t) => t.trim().isNotEmpty).toList();
  }

  static QSize _evalToken(String token) {
    final t = token.trim();
    if (t.isEmpty || t == 'auto' || t == 'min-content' || t == 'max-content') {
      return const QAuto();
    }

    final len = t.length;
    final last = t.codeUnitAt(len - 1);
    final prev = len > 1 ? t.codeUnitAt(len - 2) : 0;

    if (prev == 0x66 && last == 0x72) {
      return QFraction(QLParserUtils.parseDecimal(t, 0, len - 2));
    }
    if (prev == 0x70 && last == 0x78) {
      return QFixed(QLParserUtils.parseDecimal(t, 0, len - 2));
    }
    if (last == 0x25) {
      return QFraction(QLParserUtils.parseDecimal(t, 0, len - 1));
    }

    if (t.startsWith('minmax(') && last == 0x29) {
      final inner = t.substring(7, len - 1);
      final parts = _splitArgs(inner);
      if (parts.length == 2)
        return QMinMax(_evalToken(parts[0]), _evalToken(parts[1]));
      return const QAuto();
    }

    if (t.startsWith('fit-content(') && last == 0x29) {
      return QFitContent(QLParserUtils.parseDecimal(t, 12, len - 1));
    }

    if (t.startsWith('repeat(') && last == 0x29) {
      final inner = t.substring(7, len - 1);
      final parts = _splitArgs(inner);
      if (parts.length >= 2) {
        final tracks = parts.sublist(1).map(_evalToken).toList(growable: false);
        final head = parts[0].trim();
        if (head == 'auto-fill') return QAutoFill(tracks);
        if (head == 'auto-fit') return QAutoFit(tracks);
        final count = (int.tryParse(head) ?? 1).clamp(1, _maxCap);
        return QRepeat(count, tracks);
      }
    }

    final parsed = QLParserUtils.parseDecimal(t, 0, len);
    if (parsed.isNaN || parsed.isInfinite) return const QAuto();
    return QFixed(parsed);
  }

  static List<String> _splitArgs(String s) {
    final parts = <String>[];
    int depth = 0;
    int start = 0;

    for (int i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x28) {
        depth++;
      } else if (c == 0x29) {
        depth = math.max(0, depth - 1);
      } else if (c == 0x2C && depth == 0) {
        parts.add(s.substring(start, i).trim());
        start = i + 1;
      }
    }
    final tail = s.substring(start).trim();
    if (tail.isNotEmpty) parts.add(tail);
    return parts;
  }

  static List<QSize> _flatten(List<QSize> tracks) {
    final result = <QSize>[];
    for (final t in tracks) {
      if (t is QRepeat) {
        for (int i = 0; i < t.count; i++) result.addAll(t.tracks);
      } else {
        result.add(t);
      }
    }
    return result;
  }
}

sealed class QSize {
  const QSize();
}

class QFixed extends QSize {
  final double px;
  const QFixed(this.px);
}

class QFraction extends QSize {
  final double fr;
  const QFraction(this.fr);
}

class QAuto extends QSize {
  const QAuto();
}

class QFitContent extends QSize {
  final double maxPx;
  const QFitContent(this.maxPx);
}

class QMinMax extends QSize {
  final QSize min;
  final QSize max;
  const QMinMax(this.min, this.max);
}

class QRepeat extends QSize {
  final int count;
  final List<QSize> tracks;
  const QRepeat(this.count, this.tracks);
}

class QAutoFit extends QSize {
  final List<QSize> tracks;
  const QAutoFit(this.tracks);
}

class QAutoFill extends QSize {
  final List<QSize> tracks;
  const QAutoFill(this.tracks);
}

abstract final class QLParserUtils {
  @pragma('vm:prefer-inline')
  static double parseDecimal(String src, int s, int e,
      [double multiplier = 1.0]) {
    double val = 0.0, fraction = 0.0, divisor = 10.0;
    bool isFraction = false;
    for (int i = s; i < e; i++) {
      final int c = src.codeUnitAt(i);
      if (c == 46) {
        isFraction = true;
      } else if (c >= 48 && c <= 57) {
        if (isFraction) {
          fraction += (c - 48) / divisor;
          divisor *= 10;
        } else {
          val = val * 10 + (c - 48);
        }
      }
    }
    return (val + fraction) * multiplier;
  }

  @pragma('vm:prefer-inline')
  static int parseColor(String src, int s, int e) {
    if (e - s == 0) return 0xFF000000;
    if (src.codeUnitAt(s) == 91 && src.codeUnitAt(s + 1) == 35) {
      int hex = 0;
      final int hexStart = s + 2;
      final int hexEnd = e - 1;
      final int hexLen = hexEnd - hexStart;

      for (int i = hexStart; i < hexEnd; i++) {
        int c = src.codeUnitAt(i);
        hex <<= 4;
        if (c >= 48 && c <= 57)
          hex |= (c - 48);
        else if (c >= 65 && c <= 70)
          hex |= (c - 55);
        else if (c >= 97 && c <= 102) hex |= (c - 87);
      }
      if (hexLen == 3) {
        int r = (hex >> 8) & 0xF;
        int g = (hex >> 4) & 0xF;
        int b = hex & 0xF;
        return 0xFF000000 |
            (r << 20) |
            (r << 16) |
            (g << 12) |
            (g << 8) |
            (b << 4) |
            b;
      } else if (hexLen == 4) {
        int a = (hex >> 12) & 0xF;
        int r = (hex >> 8) & 0xF;
        int g = (hex >> 4) & 0xF;
        int b = hex & 0xF;
        return (a << 28) |
            (a << 24) |
            (r << 20) |
            (r << 16) |
            (g << 12) |
            (g << 8) |
            (b << 4) |
            b;
      } else if (hexLen == 6) {
        return 0xFF000000 | hex;
      } else if (hexLen == 8) {
        return hex;
      }
      return 0xFF000000 | hex;
    }

    // Hex String directly
    if (src.codeUnitAt(s) == 35 ||
        (src.codeUnitAt(s) == 48 &&
            (src.codeUnitAt(s + 1) == 120 || src.codeUnitAt(s + 1) == 88))) {
      int startOffset = src.codeUnitAt(s) == 35 ? s + 1 : s + 2;
      int hex = 0;
      for (int i = startOffset; i < e; i++) {
        int c = src.codeUnitAt(i);
        hex <<= 4;
        if (c >= 48 && c <= 57)
          hex |= (c - 48);
        else if (c >= 65 && c <= 70)
          hex |= (c - 55);
        else if (c >= 97 && c <= 102) hex |= (c - 87);
      }
      int hexLen = e - startOffset;
      if (hexLen == 6) return 0xFF000000 | hex;
      if (hexLen == 8) return hex;
      return 0xFF000000 | hex;
    }

    int slashIdx = -1;
    for (int i = s; i < e; i++) {
      if (src.codeUnitAt(i) == 47) {
        slashIdx = i;
        break;
      }
    }

    final int colorEnd = slashIdx != -1 ? slashIdx : e;
    final String colorName = src.substring(s, colorEnd);

    int baseColor = 0xFF888888;
    if (colorName.startsWith('transparent'))
      baseColor = 0x00000000;
    else if (colorName.startsWith('white'))
      baseColor = 0xFFFFFFFF;
    else if (colorName.startsWith('black'))
      baseColor = 0xFF000000;
    else if (colorName.startsWith('primary') || colorName.startsWith('blue'))
      baseColor = 0xFF3B82F6;
    else if (colorName.startsWith('error') || colorName.startsWith('red'))
      baseColor = 0xFFEF4444;
    else if (colorName.startsWith('success') || colorName.startsWith('emerald'))
      baseColor = 0xFF10B981;
    else if (colorName.startsWith('cyan-300'))
      baseColor = 0xFF67E8F9;
    else if (colorName.startsWith('cyan'))
      baseColor = 0xFF06B6D4;
    else if (colorName.startsWith('purple'))
      baseColor = 0xFFA855F7;
    else if (colorName.startsWith('slate-900'))
      baseColor = 0xFF0F172A;
    else if (colorName.startsWith('slate-800'))
      baseColor = 0xFF1E293B;
    else if (colorName.startsWith('slate-600'))
      baseColor = 0xFF475569;
    else if (colorName.startsWith('slate-400'))
      baseColor = 0xFF94A3B8;
    else if (colorName.startsWith('slate-100'))
      baseColor = 0xFFF1F5F9;
    else if (colorName.startsWith('slate')) baseColor = 0xFF64748B;

    if (slashIdx != -1 && slashIdx + 1 < e) {
      final double opacityPct = parseDecimal(src, slashIdx + 1, e);
      final int alpha = ((opacityPct / 100.0) * 255).toInt().clamp(0, 255);
      return (alpha << 24) | (baseColor & 0x00FFFFFF);
    }
    return baseColor;
  }

  /// Parses a hex string (e.g., "#3B82F6", "#FFF", "#80000000") into a 32-bit ARGB integer.
  static int parseHexColor(String hex) {
    hex = hex.replaceAll('#', '').trim();
    if (hex.length == 3) {
      // RGB -> AARRGGBB
      final String r = hex[0];
      final String g = hex[1];
      final String b = hex[2];
      hex = 'FF$r$r$g$g$b$b';
    } else if (hex.length == 4) {
      // ARGB -> AARRGGBB
      final String a = hex[0];
      final String r = hex[1];
      final String g = hex[2];
      final String b = hex[3];
      hex = '$a$a$r$r$g$g$b$b';
    } else if (hex.length == 6) {
      // RRGGBB -> AARRGGBB
      hex = 'FF$hex';
    }
    return int.tryParse(hex, radix: 16) ?? 0xFF000000;
  }

  /// Takes an ARGB integer color and applies a double opacity (0.0 to 1.0).
  static int applyOpacity(int color, double opacity) {
    if (opacity < 0.0) opacity = 0.0;
    if (opacity > 1.0) opacity = 1.0;

    // Extract the current alpha channel
    final int currentAlpha = (color >> 24) & 0xFF;
    // Calculate new alpha based on the multiplier
    final int newAlpha = (currentAlpha * opacity).round().clamp(0, 255);

    // Combine new alpha with the existing RGB channels
    return (newAlpha << 24) | (color & 0x00FFFFFF);
  }
}
