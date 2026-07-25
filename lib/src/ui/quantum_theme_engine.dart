// ════════════════════════════════════════════════════════════════════════════
// QUANTUM THEME ENGINE (QTE) v14.0 — OMEGA DoD 4x32 SIMD CORE (QLE Enhanced)
// quantum_theme_engine.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Barrel import covers all quantum ecosystem dependencies (including QLE).
import '../../quantum.dart';

// ────────────────────────────────────────────────────────────────────────────
// §0 — SHARED SIMD POINTER OFFSETS (Fixed Memory Map)
// ────────────────────────────────────────────────────────────────────────────

abstract final class QF32 {
  static const int padTop = 0;
  static const int padRight = 1;
  static const int padBottom = 2;
  static const int padLeft = 3;

  static const int marTop = 4;
  static const int marRight = 5;
  static const int marBottom = 6;
  static const int marLeft = 7;

  static const int fontSize = 8;
  static const int blurSigma = 9;
  static const int radius = 10;
  static const int borderWidth = 11;
  static const int opacity = 12;
  static const int letterSpacing = 13;
  static const int width = 14;
  static const int height = 15;
  static const int gap = 16;
  static const int lineHeight = 17;
  static const int shadowBlur = 18;
  static const int shadowSpread = 19;
  static const int reserved = 20;
}

abstract final class QC32 {
  static const int background = 0;
  static const int text = 1;
  static const int border = 2;
  static const int shadow = 3;
  static const int gradientFrom = 4;
  static const int gradientTo = 5;
  static const int gradientVia = 6;
  static const int accent = 7;

  // Hover / Interaction Targets
  static const int hoverBackground = 8;
  static const int hoverText = 9;
  static const int hoverBorder = 10;
  static const int hoverShadow = 11;
}

// NEW: Integers memory map for Grid Spans, Counters, and Object Pointers
abstract final class QI32 {
  static const int imageId = 0;
  static const int gridColsStrId = 1; // Object ID for column template string
  static const int gridRowsStrId = 2; // Object ID for row template string
  static const int colSpan = 3;
  static const int rowSpan = 4;
  static const int colStart = 5;
  static const int rowStart = 6;
  static const int reserved = 7;
}

// ────────────────────────────────────────────────────────────────────────────
// §1 — CATEGORIZED FLAGS (4x32 Bit Architecture)
// ────────────────────────────────────────────────────────────────────────────

abstract final class QLayoutFlags {
  static const int isFlex = 1 << 0;
  static const int isStack = 1 << 1;
  static const int flexCol = 1 << 2;
  static const int wrap = 1 << 3;
  static const int expand = 1 << 4;

  // Main Axis
  static const int justifyCenter = 1 << 5;
  static const int justifyBetween = 1 << 6;
  static const int justifyEnd = 1 << 7;
  static const int justifyAround = 1 << 8;
  static const int justifyEvenly = 1 << 9;

  // Cross Axis
  static const int itemsCenter = 1 << 10;
  static const int itemsEnd = 1 << 11;
  static const int itemsStretch = 1 << 12;
  static const int itemsBaseline = 1 << 13;

  // Positioning
  static const int absolute = 1 << 14;
  static const int relative = 1 << 15;
  static const int fill = 1 << 16;

  // Grid Integrations
  static const int isGrid = 1 << 17;
  static const int isMasonry = 1 << 18;
}

abstract final class QRenderFlags {
  static const int hasBox = 1 << 0;
  static const int hasBorder = 1 << 1;
  static const int hasShadow = 1 << 2;
  static const int hasBlur = 1 << 3;
  static const int hasGradient = 1 << 4;
  static const int hasImage = 1 << 5;
  static const int hasClip = 1 << 6;
  static const int hasRoundedClip = 1 << 7;

  static const int gradToRight = 1 << 8;
  static const int gradToBottom = 1 << 9;
  static const int gradToBR = 1 << 10;

  static const int isCircle = 1 << 11;
}

abstract final class QTextFlags {
  static const int isText = 1 << 0;
  static const int textCenter = 1 << 1;
  static const int textRight = 1 << 2;
  static const int textLeft = 1 << 3;
  static const int textJustify = 1 << 4;

  static const int fontBold = 1 << 5;
  static const int fontItalic = 1 << 6;
  static const int textEllipsis = 1 << 7;
  static const int underline = 1 << 8;
  static const int strikeThrough = 1 << 9;
}

abstract final class QStateFlags {
  static const int hoverable = 1 << 0;
  static const int focusable = 1 << 1;
  static const int pressed = 1 << 2;
  static const int disabled = 1 << 3;

  // Track if interaction requires color lerping
  static const int hasHoverBg = 1 << 4;
  static const int hasHoverText = 1 << 5;
  static const int hasHoverBorder = 1 << 6;
  static const int hasInteractiveScale = 1 << 7;
}

abstract final class QContextBits {
  static const int light = 1 << 0;
  static const int dark = 1 << 1;
  static const int sm = 1 << 2;
  static const int md = 1 << 3;
  static const int lg = 1 << 4;
  static const int xl = 1 << 5;
  static const int rtl = 1 << 6;
}

// ────────────────────────────────────────────────────────────────────────────
// §2 — TOKEN STRUCTS & DICTIONARY
// ────────────────────────────────────────────────────────────────────────────

extension type const QToken(int id) {
  @pragma('vm:prefer-inline')
  int get fPtr => id * QSimdArena.floatStride;
  @pragma('vm:prefer-inline')
  int get cPtr => id * QSimdArena.colorStride;
  @pragma('vm:prefer-inline')
  int get iPtr => id * QSimdArena.intStride;
}

final class QTokenRecord {
  final int id;
  final String key;
  final int contextMask;
  final int baseFlags;
  final int? aliasOf;
  const QTokenRecord({
    required this.id,
    required this.key,
    required this.contextMask,
    required this.baseFlags,
    required this.aliasOf,
  });
}

final class QThemeToken {
  final int color;
  final double? number;
  final String? text;
  const QThemeToken.color(this.color)
      : number = null,
        text = null;
  const QThemeToken.number(this.number)
      : color = 0,
        text = null;
  const QThemeToken.text(this.text)
      : color = 0,
        number = null;
}

final class QThemeDictionary {
  final Map<String, QThemeToken> values;
  final Map<String, String> aliases;
  final int version;

  const QThemeDictionary({
    required this.values,
    required this.aliases,
    required this.version,
  });

  factory QThemeDictionary.empty() {
    return const QThemeDictionary(
      values: <String, QThemeToken>{},
      aliases: <String, String>{},
      version: 0,
    );
  }

  factory QThemeDictionary.fromJson(Map<String, dynamic> json) {
    final Map<String, QThemeToken> values = <String, QThemeToken>{};
    final Map<String, String> aliases = <String, String>{};

    void ingestGroup(String groupName, Object? group) {
      if (group is! Map) return;
      group.forEach((dynamic k, dynamic v) {
        final String key = '$groupName.$k';

        if (groupName == 'aliases') {
          aliases[key] = v?.toString() ?? '';
          return;
        }

        if (v is num) {
          values[key] = QThemeToken.number(v.toDouble());
        } else if (v is String) {
          if (v.startsWith('#')) {
            values[key] = QThemeToken.color(QLParserUtils.parseHexColor(v));
          } else if (groupName == 'labels' ||
              groupName == 'text' ||
              groupName == 'content') {
            values[key] = QThemeToken.text(v);
          } else {
            aliases[key] = v;
          }
        } else if (v is Map) {
          final Map<String, dynamic> vm = Map<String, dynamic>.from(v as Map);
          final Object? color = vm['color'];
          final Object? number = vm['number'];
          final Object? text = vm['text'];
          if (color is String) {
            values[key] = QThemeToken.color(QLParserUtils.parseHexColor(color));
          } else if (number is num) {
            values[key] = QThemeToken.number(number.toDouble());
          } else if (text is String) {
            values[key] = QThemeToken.text(text);
          }
        }
      });
    }

    json.forEach((dynamic k, dynamic v) {
      if (v is Map) {
        ingestGroup(k.toString(), v);
      }
    });

    return QThemeDictionary(values: values, aliases: aliases, version: 1);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'values': values.map((key, value) {
          if (value.color != 0) {
            return MapEntry(key, <String, dynamic>{'color': value.color});
          }
          if (value.number != null) {
            return MapEntry(key, <String, dynamic>{'number': value.number});
          }
          return MapEntry(key, <String, dynamic>{'text': value.text});
        }),
        'aliases': aliases,
        'version': version,
      };

  QThemeDictionary merge(QThemeDictionary other) {
    if (other.version == version &&
        identical(other.values, values) &&
        identical(other.aliases, aliases)) {
      return this;
    }
    final mergedValues = <String, QThemeToken>{...values, ...other.values};
    final mergedAliases = <String, String>{...aliases, ...other.aliases};
    return QThemeDictionary(
      values: Map<String, QThemeToken>.unmodifiable(mergedValues),
      aliases: Map<String, String>.unmodifiable(mergedAliases),
      version: version >= other.version ? version + 1 : other.version + 1,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §4 — THEME GRAPH (AOT Resolution)
// ────────────────────────────────────────────────────────────────────────────

final class QThemeGraph {
  final Map<String, int> nameToId = <String, int>{};
  final List<QTokenRecord> records = <QTokenRecord>[];
  final Map<int, int> resolvedColors = <int, int>{};
  final Map<int, double> resolvedNumbers = <int, double>{};
  final Map<int, String> resolvedText = <int, String>{};

  int version = 0;
  QThemeDictionary dictionary = QThemeDictionary.empty();

  void load(QThemeDictionary next) {
    dictionary = next;
    version = next.version;
    nameToId.clear();
    records.clear();
    resolvedColors.clear();
    resolvedNumbers.clear();
    resolvedText.clear();

    int nextId = 1;
    for (final entry in next.values.entries) {
      nameToId[entry.key] = nextId;
      records.add(QTokenRecord(
        id: nextId,
        key: entry.key,
        contextMask: 0,
        baseFlags: 0,
        aliasOf: null,
      ));
      nextId++;
    }
    for (final entry in next.aliases.entries) {
      nameToId.putIfAbsent(entry.key, () {
        final int id = nextId++;
        records.add(QTokenRecord(
          id: id,
          key: entry.key,
          contextMask: 0,
          baseFlags: 0,
          aliasOf: null,
        ));
        return id;
      });
    }

    _resolveAll();
  }

  void _resolveAll() {
    final Map<String, int> visiting = <String, int>{};

    int resolveColorByName(String name) {
      final int? id = nameToId[name];
      if (id == null) return 0;
      final int? cached = resolvedColors[id];
      if (cached != null) return cached;

      final QThemeToken? direct = dictionary.values[name];
      if (direct != null) {
        if (direct.color != 0) {
          resolvedColors[id] = direct.color;
          return direct.color;
        }
        if (direct.number != null) {
          final int asColor = (direct.number!.round() & 0xffffffff);
          resolvedColors[id] = asColor;
          return asColor;
        }
      }

      final String? alias = dictionary.aliases[name];
      if (alias == null) return 0;
      if (visiting.containsKey(name)) {
        throw StateError('Cyclic theme alias detected at "$name"');
      }
      visiting[name] = 1;
      final int resolved = alias.startsWith('#')
          ? QLParserUtils.parseHexColor(alias)
          : resolveColorByName(alias);
      visiting.remove(name);
      resolvedColors[id] = resolved;
      return resolved;
    }

    for (final name in nameToId.keys) {
      final int id = nameToId[name]!;
      final token = dictionary.values[name];
      if (token != null) {
        if (token.color != 0) resolvedColors[id] = token.color;
        if (token.number != null) resolvedNumbers[id] = token.number!;
        if (token.text != null) resolvedText[id] = token.text!;
      }

      final String? alias = dictionary.aliases[name];
      if (alias != null) {
        if (alias.startsWith('#')) {
          resolvedColors[id] = QLParserUtils.parseHexColor(alias);
        } else if (nameToId.containsKey(alias)) {
          resolvedColors[id] = resolveColorByName(alias);
        } else {
          resolvedText[id] = alias;
        }
      }
    }
  }

  int color(String name, {int fallback = 0}) {
    final int? id = nameToId[name];
    if (id == null) return fallback;
    return resolvedColors[id] ?? fallback;
  }

  double number(String name, {double fallback = 0.0}) {
    final int? id = nameToId[name];
    if (id == null) return fallback;
    return resolvedNumbers[id] ?? fallback;
  }

  String text(String name, {String fallback = ''}) {
    final int? id = nameToId[name];
    if (id == null) return fallback;
    return resolvedText[id] ?? fallback;
  }

  bool contains(String name) => nameToId.containsKey(name);

  List<String> names() => List<String>.unmodifiable(nameToId.keys);

  Map<String, dynamic> snapshot() => <String, dynamic>{
        'version': version,
        'names': names(),
        'colors': <String, int>{
          for (final entry in nameToId.entries)
            if (resolvedColors.containsKey(entry.value))
              entry.key: resolvedColors[entry.value]!,
        },
        'numbers': <String, double>{
          for (final entry in nameToId.entries)
            if (resolvedNumbers.containsKey(entry.value))
              entry.key: resolvedNumbers[entry.value]!,
        },
        'text': <String, String>{
          for (final entry in nameToId.entries)
            if (resolvedText.containsKey(entry.value))
              entry.key: resolvedText[entry.value]!,
        },
      };
}

// ────────────────────────────────────────────────────────────────────────────
// §5 — MORPHER & COLOR LERP
// ────────────────────────────────────────────────────────────────────────────

abstract final class QMorpher {
  static void lerpFast(
      QSimdArena start, QSimdArena end, double t, QSimdArena out) {
    final Float32x4 t4 = Float32x4.splat(t);
    final Float32x4 invT4 = Float32x4.splat(1.0 - t);

    final int lenF = start.f32x4.length;
    for (int i = 0; i < lenF; i++) {
      out.f32x4[i] = (start.f32x4[i] * invT4) + (end.f32x4[i] * t4);
    }

    final int lenC = start.c32.length;
    for (int i = 0; i < lenC; i++) {
      out.c32[i] = _lerpColorFast(start.c32[i], end.c32[i], t);
    }

    if (t > 0.5) {
      final int lenI = start.i32.length;
      for (int i = 0; i < lenI; i++) out.i32[i] = end.i32[i];

      final int lenFlags = start.layoutFlags.length;
      for (int i = 0; i < lenFlags; i++) {
        out.layoutFlags[i] = end.layoutFlags[i];
        out.renderFlags[i] = end.renderFlags[i];
        out.textFlags[i] = end.textFlags[i];
        out.stateFlags[i] = end.stateFlags[i];
      }
    }
  }

  @pragma('vm:prefer-inline')
  static int _lerpColorFast(int a, int b, double t) {
    if (a == b || a == 0 || b == 0) return t > 0.5 ? b : a;

    final int ta = (t * 256).toInt();
    final int invTa = 256 - ta;

    final int alpha =
        (((a >> 24) & 0xff) * invTa + ((b >> 24) & 0xff) * ta) >> 8;
    final int red = (((a >> 16) & 0xff) * invTa + ((b >> 16) & 0xff) * ta) >> 8;
    final int green = (((a >> 8) & 0xff) * invTa + ((b >> 8) & 0xff) * ta) >> 8;
    final int blue = ((a & 0xff) * invTa + (b & 0xff) * ta) >> 8;

    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §6 — TOKENIZER UTILITIES
// ────────────────────────────────────────────────────────────────────────────

abstract final class QStyleTokenizer {
  static List<String> splitTokens(String input) {
    if (input.isEmpty) return const <String>[];
    final List<String> out = <String>[];
    int start = 0;
    final int len = input.length;
    for (int i = 0; i <= len; i++) {
      final bool end = i == len;
      final bool space = !end && input.codeUnitAt(i) == 32;
      if (end || space) {
        if (i > start) out.add(input.substring(start, i));
        start = i + 1;
      }
    }
    return out;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §7 — SIMD ARENA (The Memory Heart)
// ────────────────────────────────────────────────────────────────────────────

class QSimdArena {
  static const int floatStride = 24;
  static const int colorStride = 16;
  static const int intStride =
      8; // Expanded to 8 to support Grid properties natively

  int _capacity;

  late Float32List f32;
  late Uint32List c32;
  late Int32List i32;
  late Float32x4List f32x4;

  late Uint32List layoutFlags;
  late Uint32List renderFlags;
  late Uint32List textFlags;
  late Uint32List stateFlags;

  late List<Object?> objects;

  int _nextObjId = 1;
  int _nextId = 1;

  QSimdArena({required int capacity}) : _capacity = capacity {
    _initBuffers();
  }

  void _initBuffers() {
    final ByteBuffer fBuffer = Float32List(_capacity * floatStride).buffer;
    final ByteBuffer cBuffer = Uint32List(_capacity * colorStride).buffer;
    final ByteBuffer iBuffer = Int32List(_capacity * intStride).buffer;

    f32 = fBuffer.asFloat32List();
    c32 = cBuffer.asUint32List();
    i32 = iBuffer.asInt32List();
    f32x4 = fBuffer.asFloat32x4List();

    layoutFlags = Uint32List(_capacity);
    renderFlags = Uint32List(_capacity);
    textFlags = Uint32List(_capacity);
    stateFlags = Uint32List(_capacity);

    objects = List<Object?>.filled(_capacity, null, growable: true);
    _nextObjId = 1;
    _nextId = 1;
  }

  void clear() {
    f32.fillRange(0, f32.length, 0.0);
    c32.fillRange(0, c32.length, 0);
    i32.fillRange(0, i32.length, 0);

    layoutFlags.fillRange(0, layoutFlags.length, 0);
    renderFlags.fillRange(0, renderFlags.length, 0);
    textFlags.fillRange(0, textFlags.length, 0);
    stateFlags.fillRange(0, stateFlags.length, 0);

    objects.fillRange(0, objects.length, null);
    _nextObjId = 1;
    _nextId = 1;
  }

  @pragma('vm:prefer-inline')
  int allocate() {
    if (_nextId >= _capacity) _expand();
    return _nextId++;
  }

  int registerObject(Object obj) {
    if (_nextObjId >= objects.length) {
      objects.addAll(List<Object?>.filled(objects.length, null));
    }
    objects[_nextObjId] = obj;
    return _nextObjId++;
  }

  void _expand() {
    final int newCap = _capacity * 2;
    final Float32List newF32 = Float32List(newCap * floatStride)
      ..setAll(0, f32);
    final Uint32List newC32 = Uint32List(newCap * colorStride)..setAll(0, c32);
    final Int32List newI32 = Int32List(newCap * intStride)..setAll(0, i32);

    final Uint32List newLFlags = Uint32List(newCap)..setAll(0, layoutFlags);
    final Uint32List newRFlags = Uint32List(newCap)..setAll(0, renderFlags);
    final Uint32List newTFlags = Uint32List(newCap)..setAll(0, textFlags);
    final Uint32List newSFlags = Uint32List(newCap)..setAll(0, stateFlags);

    _capacity = newCap;
    f32 = newF32;
    c32 = newC32;
    i32 = newI32;
    f32x4 = newF32.buffer.asFloat32x4List();

    layoutFlags = newLFlags;
    renderFlags = newRFlags;
    textFlags = newTFlags;
    stateFlags = newSFlags;
  }

  void copyFrom(QSimdArena other) {
    if (other._capacity > _capacity) {
      _capacity = other._capacity;
      _initBuffers();
    }

    f32x4.setAll(0, other.f32x4);
    c32.setAll(0, other.c32);
    i32.setAll(0, other.i32);

    layoutFlags.setAll(0, other.layoutFlags);
    renderFlags.setAll(0, other.renderFlags);
    textFlags.setAll(0, other.textFlags);
    stateFlags.setAll(0, other.stateFlags);

    if (objects.length < other.objects.length) {
      objects.addAll(
          List<Object?>.filled(other.objects.length - objects.length, null));
    }
    for (int i = 0; i < other._nextObjId; i++) {
      objects[i] = other.objects[i];
    }

    _nextId = other._nextId;
    _nextObjId = other._nextObjId;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §8 — COMPILER (Token to Memory Map)
// ────────────────────────────────────────────────────────────────────────────

class QCompiler {
  final QSimdArena _arena;
  final QThemeGraph _theme;
  final LinkedHashMap<int, QToken> _cache = LinkedHashMap<int, QToken>();
  final LinkedHashMap<int, int> _cacheVersion = LinkedHashMap<int, int>();
  static const int _maxCache = 8192;

  QCompiler(this._arena, {QThemeGraph? theme})
      : _theme = theme ?? QThemeGraph();

  void setThemeGraph(QThemeGraph theme) {
    _theme.load(theme.dictionary);
  }

  QToken compile(
    String cssTokens, {
    List<dynamic>? padding,
    List<dynamic>? margin,
    num? gap,
    int contextMask = 0,
  }) {
    final int hash = Object.hash(
      cssTokens,
      contextMask,
      padding != null ? Object.hashAll(padding) : 0,
      margin != null ? Object.hashAll(margin) : 0,
      gap,
    );

    if (_cache.containsKey(hash)) {
      final cached = _cache.remove(hash)!;
      final cachedVersion = _cacheVersion.remove(hash)!;
      _cache[hash] = cached;
      _cacheVersion[hash] = cachedVersion;
      if (cachedVersion != _theme.version) {
        _parse(cssTokens, cached.id, padding, margin, gap, contextMask);
        _cacheVersion[hash] = _theme.version;
      }
      return cached;
    }

    final int id = _arena.allocate();
    final QToken ptr = QToken(id);

    _parse(cssTokens, id, padding, margin, gap, contextMask);

    if (_cache.length >= _maxCache) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
      _cacheVersion.remove(firstKey);
    }
    _cache[hash] = ptr;
    _cacheVersion[hash] = _theme.version;
    return ptr;
  }

  void _parse(
    String src,
    int id,
    List<dynamic>? padding,
    List<dynamic>? margin,
    num? gap,
    int contextMask,
  ) {
    final int fPtr = id * QSimdArena.floatStride;
    final int iPtr = id * QSimdArena.intStride;

    // Reset Defaults
    _arena.f32[fPtr + QF32.opacity] = 1.0;
    _arena.f32[fPtr + QF32.width] = -1.0;
    _arena.f32[fPtr + QF32.height] = -1.0;
    _arena.f32[fPtr + QF32.lineHeight] = 1.2;

    // Grid Spans Defaults
    _arena.i32[iPtr + QI32.colSpan] = 1;
    _arena.i32[iPtr + QI32.rowSpan] = 1;
    _arena.i32[iPtr + QI32.colStart] = 0;
    _arena.i32[iPtr + QI32.rowStart] = 0;

    if (padding != null) _applyInsets(fPtr, QF32.padTop, padding);
    if (margin != null) _applyInsets(fPtr, QF32.marTop, margin);
    if (gap != null) _arena.f32[fPtr + QF32.gap] = gap.toDouble();

    final List<String> tokens = QStyleTokenizer.splitTokens(src);
    for (final token in tokens) {
      _applyToken(token, id, contextMask);
    }
  }

  @pragma('vm:prefer-inline')
  void _applyInsets(int fPtr, int baseOffset, List<dynamic> values) {
    if (values.isEmpty) return;
    if (values.length == 1) {
      final v = (values[0] as num).toDouble();
      _arena.f32[fPtr + baseOffset + 0] = v;
      _arena.f32[fPtr + baseOffset + 1] = v;
      _arena.f32[fPtr + baseOffset + 2] = v;
      _arena.f32[fPtr + baseOffset + 3] = v;
    } else if (values.length == 2) {
      final v = (values[0] as num).toDouble();
      final h = (values[1] as num).toDouble();
      _arena.f32[fPtr + baseOffset + 0] = v;
      _arena.f32[fPtr + baseOffset + 1] = h;
      _arena.f32[fPtr + baseOffset + 2] = v;
      _arena.f32[fPtr + baseOffset + 3] = h;
    } else if (values.length >= 4) {
      _arena.f32[fPtr + baseOffset + 0] = (values[0] as num).toDouble();
      _arena.f32[fPtr + baseOffset + 1] = (values[1] as num).toDouble();
      _arena.f32[fPtr + baseOffset + 2] = (values[2] as num).toDouble();
      _arena.f32[fPtr + baseOffset + 3] = (values[3] as num).toDouble();
    }
  }

  bool _matchContext(int tokenMask, int activeMask) =>
      tokenMask == 0 || (tokenMask & activeMask) == tokenMask;

  int _parseContextPrefix(String token) {
    int mask = 0;
    int cursor = 0;
    while (true) {
      final int colon = token.indexOf(':', cursor);
      if (colon <= cursor) break;
      final String prefix = token.substring(cursor, colon);
      switch (prefix) {
        case 'dark':
          mask |= QContextBits.dark;
          break;
        case 'light':
          mask |= QContextBits.light;
          break;
        case 'sm':
          mask |= QContextBits.sm;
          break;
        case 'md':
          mask |= QContextBits.md;
          break;
        case 'lg':
          mask |= QContextBits.lg;
          break;
        case 'xl':
          mask |= QContextBits.xl;
          break;
        case 'rtl':
          mask |= QContextBits.rtl;
          break;
      }
      cursor = colon + 1;
      if (cursor >= token.length) break;
    }
    return mask;
  }

  String _stripContextPrefixes(String token) {
    int cursor = 0;
    while (true) {
      final int colon = token.indexOf(':', cursor);
      if (colon <= cursor) break;
      final String prefix = token.substring(cursor, colon);
      switch (prefix) {
        case 'dark':
        case 'light':
        case 'sm':
        case 'md':
        case 'lg':
        case 'xl':
        case 'rtl':
        case 'hover':
        case 'focus':
        case 'pressed':
        case 'disabled':
          cursor = colon + 1;
          continue;
        default:
          return token.substring(cursor);
      }
    }
    return token.substring(cursor);
  }

  void _applyToken(String rawToken, int id, int activeContextMask) {
    final int tokenMask = _parseContextPrefix(rawToken);
    if (!_matchContext(tokenMask, activeContextMask)) return;

    // Detect Interaction Prefix purely for state mapping
    bool isHover = rawToken.contains('hover:');

    final String token = _stripContextPrefixes(rawToken);
    if (token.isEmpty) return;

    final int fPtr = id * QSimdArena.floatStride;
    final int cPtr = id * QSimdArena.colorStride;
    final int iPtr = id * QSimdArena.intStride;

    // ── LAYOUT FLAGS ──
    if (token == 'row' || token == 'flex-row') {
      _arena.layoutFlags[id] |= QLayoutFlags.isFlex;
      return;
    }
    if (token == 'col' ||
        token == 'column' ||
        token == 'flex-col' ||
        token == 'v') {
      _arena.layoutFlags[id] |= (QLayoutFlags.isFlex | QLayoutFlags.flexCol);
      return;
    }
    if (token == 'grid') {
      _arena.layoutFlags[id] |= QLayoutFlags.isGrid;
      return;
    }
    if (token == 'masonry') {
      _arena.layoutFlags[id] |= QLayoutFlags.isMasonry;
      return;
    }
    if (token == 'wrap') {
      _arena.layoutFlags[id] |= (QLayoutFlags.isFlex | QLayoutFlags.wrap);
      return;
    }
    if (token == 'stack') {
      _arena.layoutFlags[id] |= QLayoutFlags.isStack;
      return;
    }
    if (token == 'absolute') {
      _arena.layoutFlags[id] |= QLayoutFlags.absolute;
      return;
    }
    if (token == 'relative') {
      _arena.layoutFlags[id] |= QLayoutFlags.relative;
      return;
    }
    if (token == 'fill' || token == 'inset-0') {
      _arena.layoutFlags[id] |= QLayoutFlags.fill;
      return;
    }

    if (token == 'flex-center' || token == 'center') {
      _arena.layoutFlags[id] |= (QLayoutFlags.isFlex |
          QLayoutFlags.justifyCenter |
          QLayoutFlags.itemsCenter);
      return;
    }
    if (token == 'expand' ||
        token == 'expanded' ||
        token == 'flex-1' ||
        token == 'flex-auto') {
      _arena.layoutFlags[id] |= QLayoutFlags.expand;
      return;
    }

    // ── GRID SPANS AND STARTS (Native integration with QLE) ──
    if (token.startsWith('grid-cols-')) {
      final String val = token.substring(10);
      int? count = int.tryParse(val);
      final String template =
          count != null ? List.filled(count, '1fr').join(' ') : val;
      _arena.i32[iPtr + QI32.gridColsStrId] = _arena.registerObject(template);
      return;
    }
    if (token.startsWith('grid-rows-')) {
      final String val = token.substring(10);
      int? count = int.tryParse(val);
      final String template =
          count != null ? List.filled(count, '1fr').join(' ') : val;
      _arena.i32[iPtr + QI32.gridRowsStrId] = _arena.registerObject(template);
      return;
    }
    if (token.startsWith('col-span-')) {
      _arena.i32[iPtr + QI32.colSpan] = int.tryParse(token.substring(9)) ?? 1;
      return;
    }
    if (token.startsWith('row-span-')) {
      _arena.i32[iPtr + QI32.rowSpan] = int.tryParse(token.substring(9)) ?? 1;
      return;
    }
    if (token.startsWith('col-start-')) {
      _arena.i32[iPtr + QI32.colStart] = int.tryParse(token.substring(10)) ?? 0;
      return;
    }
    if (token.startsWith('row-start-')) {
      _arena.i32[iPtr + QI32.rowStart] = int.tryParse(token.substring(10)) ?? 0;
      return;
    }

    if (token.startsWith('justify-')) {
      if (token == 'justify-center')
        _arena.layoutFlags[id] |= QLayoutFlags.justifyCenter;
      else if (token == 'justify-between')
        _arena.layoutFlags[id] |= QLayoutFlags.justifyBetween;
      else if (token == 'justify-end')
        _arena.layoutFlags[id] |= QLayoutFlags.justifyEnd;
      else if (token == 'justify-around')
        _arena.layoutFlags[id] |= QLayoutFlags.justifyAround;
      else if (token == 'justify-evenly')
        _arena.layoutFlags[id] |= QLayoutFlags.justifyEvenly;
      return;
    }
    if (token.startsWith('items-')) {
      if (token == 'items-center')
        _arena.layoutFlags[id] |= QLayoutFlags.itemsCenter;
      else if (token == 'items-end')
        _arena.layoutFlags[id] |= QLayoutFlags.itemsEnd;
      else if (token == 'items-stretch')
        _arena.layoutFlags[id] |= QLayoutFlags.itemsStretch;
      else if (token == 'items-baseline')
        _arena.layoutFlags[id] |= QLayoutFlags.itemsBaseline;
      return;
    }

    final int c1 = token.codeUnitAt(0);
    final int len = token.length;

    // ── SPACING (Gap, Padding, Margin) ──
    if (c1 == 112 || c1 == 109 || c1 == 103) {
      if (token.startsWith('gap-')) {
        _arena.f32[fPtr + QF32.gap] =
            QLParserUtils.parseDecimal(token, 4, len, 1.0);
        return;
      }
      final bool isPad = c1 == 112;
      if (c1 == 112 || c1 == 109) {
        final int c2 = len > 1 ? token.codeUnitAt(1) : 0;
        final int bT = isPad ? QF32.padTop : QF32.marTop;
        final int bR = isPad ? QF32.padRight : QF32.marRight;
        final int bB = isPad ? QF32.padBottom : QF32.marBottom;
        final int bL = isPad ? QF32.padLeft : QF32.marLeft;

        if (c2 == 45) {
          final double v = QLParserUtils.parseDecimal(token, 2, len, 1.0);
          _arena.f32[fPtr + bT] = v;
          _arena.f32[fPtr + bR] = v;
          _arena.f32[fPtr + bB] = v;
          _arena.f32[fPtr + bL] = v;
          return;
        } else if (len > 2 && token.codeUnitAt(2) == 45) {
          final double v = QLParserUtils.parseDecimal(token, 3, len, 1.0);
          if (c2 == 120) {
            _arena.f32[fPtr + bL] = v;
            _arena.f32[fPtr + bR] = v;
          } else if (c2 == 121) {
            _arena.f32[fPtr + bT] = v;
            _arena.f32[fPtr + bB] = v;
          } else if (c2 == 116)
            _arena.f32[fPtr + bT] = v;
          else if (c2 == 114)
            _arena.f32[fPtr + bR] = v;
          else if (c2 == 98)
            _arena.f32[fPtr + bB] = v;
          else if (c2 == 108) _arena.f32[fPtr + bL] = v;
          return;
        }
      }
    }

    // ── SIZING ──
    if (c1 == 119 && len >= 3 && token.codeUnitAt(1) == 45) {
      _arena.f32[fPtr + QF32.width] = token.codeUnitAt(2) == 102
          ? double.infinity
          : QLParserUtils.parseDecimal(token, 2, len, 1.0);
      return;
    }
    if (c1 == 104 && len >= 3 && token.codeUnitAt(1) == 45) {
      _arena.f32[fPtr + QF32.height] = token.codeUnitAt(2) == 102
          ? double.infinity
          : QLParserUtils.parseDecimal(token, 2, len, 1.0);
      return;
    }

    // ── RENDER FLAGS (Colors, Borders, Shadows) ──
    if (token.startsWith('bg-')) {
      _arena.renderFlags[id] |= QRenderFlags.hasBox;
      if (token.startsWith('bg-[url(')) {
        _arena.renderFlags[id] |= QRenderFlags.hasImage;
        final String url = token.substring(8, len - 2);
        if (url.isNotEmpty && !url.contains('{{'))
          _arena.i32[iPtr + QI32.imageId] =
              _arena.registerObject(NetworkImage(url));
      } else if (token.startsWith('bg-gradient-to-')) {
        _arena.renderFlags[id] |= QRenderFlags.hasGradient;
        final String dir = token.substring(15);
        if (dir.startsWith('r'))
          _arena.renderFlags[id] |= QRenderFlags.gradToRight;
        else if (dir.startsWith('b'))
          _arena.renderFlags[id] |= QRenderFlags.gradToBR;
        else
          _arena.renderFlags[id] |= QRenderFlags.gradToBottom;
      } else {
        final int c = _parseColorish(token.substring(3));
        if (isHover) {
          _arena.c32[cPtr + QC32.hoverBackground] = c;
          _arena.stateFlags[id] |= QStateFlags.hasHoverBg;
        } else {
          _arena.c32[cPtr + QC32.background] = c;
          _arena.renderFlags[id] |= QRenderFlags.hasBox;
        }
      }
      return;
    }

    if (token.startsWith('text-')) {
      _arena.textFlags[id] |= QTextFlags.isText;
      final String tail = token.substring(5);
      if (tail == '3xl')
        _arena.f32[fPtr + QF32.fontSize] = 30.0;
      else if (tail == '2xl')
        _arena.f32[fPtr + QF32.fontSize] = 24.0;
      else if (tail == 'xl')
        _arena.f32[fPtr + QF32.fontSize] = 20.0;
      else if (tail == 'sm')
        _arena.f32[fPtr + QF32.fontSize] = 12.0;
      else if (tail == 'lg')
        _arena.f32[fPtr + QF32.fontSize] = 18.0;
      else if (tail == 'center')
        _arena.textFlags[id] |= QTextFlags.textCenter;
      else if (tail == 'right')
        _arena.textFlags[id] |= QTextFlags.textRight;
      else if (tail == 'left')
        _arena.textFlags[id] |= QTextFlags.textLeft;
      else if (tail == 'justify')
        _arena.textFlags[id] |= QTextFlags.textJustify;
      else if (tail == 'ellipsis')
        _arena.textFlags[id] |= QTextFlags.textEllipsis;
      else {
        final int c = _parseColorish(tail);
        if (isHover) {
          _arena.c32[cPtr + QC32.hoverText] = c;
          _arena.stateFlags[id] |= QStateFlags.hasHoverText;
        } else {
          _arena.c32[cPtr + QC32.text] = c;
        }
      }
      return;
    }

    if (token.startsWith('border')) {
      _arena.renderFlags[id] |= (QRenderFlags.hasBox | QRenderFlags.hasBorder);
      if (len == 6) {
        _arena.f32[fPtr + QF32.borderWidth] = 1.0;
        _arena.c32[cPtr + QC32.border] = 0xFFE2E8F0;
      } else if (len > 7 && token.codeUnitAt(6) == 45) {
        final int c = token.codeUnitAt(7);
        if (c >= 48 && c <= 57) {
          _arena.f32[fPtr + QF32.borderWidth] =
              QLParserUtils.parseDecimal(token, 7, len, 1.0);
        } else {
          final int cVal = _parseColorish(token.substring(7));
          if (isHover) {
            _arena.c32[cPtr + QC32.hoverBorder] = cVal;
            _arena.stateFlags[id] |= QStateFlags.hasHoverBorder;
          } else {
            _arena.c32[cPtr + QC32.border] = cVal;
          }
        }
      }
      return;
    }

    if (token.startsWith('shadow')) {
      _arena.renderFlags[id] |= (QRenderFlags.hasBox | QRenderFlags.hasShadow);
      _arena.c32[cPtr + QC32.shadow] = 0x22000000;
      _arena.f32[fPtr + QF32.shadowBlur] = 16.0;
      if (len > 6 && token.codeUnitAt(6) == 45) {
        final String variant = token.substring(7);
        if (variant == 'sm')
          _arena.f32[fPtr + QF32.shadowBlur] = 4.0;
        else if (variant == 'lg')
          _arena.f32[fPtr + QF32.shadowBlur] = 24.0;
        else if (variant == 'glow') {
          _arena.f32[fPtr + QF32.shadowBlur] = 32.0;
          _arena.f32[fPtr + QF32.shadowSpread] = 8.0;
        }
      }
      return;
    }

    if (token.startsWith('blur')) {
      _arena.renderFlags[id] |= (QRenderFlags.hasBox | QRenderFlags.hasBlur);
      _arena.f32[fPtr + QF32.blurSigma] = (len > 5 && token.codeUnitAt(4) == 45)
          ? QLParserUtils.parseDecimal(token, 5, len, 1.0) / 4.0
          : 16.0;
      return;
    }

    // Shape Modifiers
    if (token.startsWith('rounded')) {
      _arena.renderFlags[id] |= QRenderFlags.hasBox;
      double r = 8.0;
      if (len > 8) {
        final int rc = token.codeUnitAt(8);
        if (rc == 102)
          r = 9999.0;
        else if (rc == 108)
          r = 16.0;
        else if (rc == 115)
          r = 4.0;
        else if (rc == 110)
          r = 0.0;
        else if (rc >= 48 && rc <= 57)
          r = QLParserUtils.parseDecimal(token, 8, len, 1.0);
      }
      _arena.f32[fPtr + QF32.radius] = r;
      if (token.startsWith('rounded-full'))
        _arena.renderFlags[id] |= QRenderFlags.hasRoundedClip;
      return;
    }

    if (token == 'circle') {
      _arena.renderFlags[id] |= (QRenderFlags.hasBox |
          QRenderFlags.isCircle |
          QRenderFlags.hasRoundedClip);
      return;
    }
    if (token == 'overflow-hidden') {
      _arena.renderFlags[id] |= (QRenderFlags.hasBox | QRenderFlags.hasClip);
      return;
    }
    if (token.startsWith('opacity-')) {
      _arena.f32[fPtr + QF32.opacity] =
          QLParserUtils.parseDecimal(token, 8, len) / 100.0;
      return;
    }

    // Typography
    if (token == 'font-bold') {
      _arena.textFlags[id] |= (QTextFlags.isText | QTextFlags.fontBold);
      return;
    }
    if (token == 'italic') {
      _arena.textFlags[id] |= (QTextFlags.isText | QTextFlags.fontItalic);
      return;
    }
    if (token == 'underline') {
      _arena.textFlags[id] |= (QTextFlags.isText | QTextFlags.underline);
      return;
    }
    if (token == 'line-through') {
      _arena.textFlags[id] |= (QTextFlags.isText | QTextFlags.strikeThrough);
      return;
    }
    if (token == 'leading-tight') {
      _arena.f32[fPtr + QF32.lineHeight] = 1.1;
      return;
    }
    if (token == 'leading-relaxed') {
      _arena.f32[fPtr + QF32.lineHeight] = 1.625;
      return;
    }
    if (token == 'tracking-wide') {
      _arena.f32[fPtr + QF32.letterSpacing] = 1.5;
      return;
    }

    // States
    if (token == 'hover') _arena.stateFlags[id] |= QStateFlags.hoverable;
    if (token == 'focus') _arena.stateFlags[id] |= QStateFlags.focusable;
    if (token == 'pressed') _arena.stateFlags[id] |= QStateFlags.pressed;
    if (token == 'disabled') _arena.stateFlags[id] |= QStateFlags.disabled;
    if (token == 'interactive')
      _arena.stateFlags[id] |=
          (QStateFlags.hoverable | QStateFlags.hasInteractiveScale);
  }

  int _parseColorish(String value) {
    if (value.isEmpty) return 0;
    final int themed = _theme.color(value, fallback: 0);
    if (themed != 0) return themed;
    final int slash = value.lastIndexOf('/');
    if (slash > 0 && slash < value.length - 1) {
      final String head = value.substring(0, slash);
      final String alphaText = value.substring(slash + 1);
      final int base = _theme.color(head, fallback: 0) != 0
          ? _theme.color(head)
          : QLParserUtils.parseColor(head, 0, head.length);
      final int pct = int.tryParse(alphaText) ?? 100;
      return QLParserUtils.applyOpacity(base, pct.clamp(0, 100) / 100.0);
    }
    return QLParserUtils.parseColor(value, 0, value.length);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §9 — THE ENGINE SINGLETON
// ────────────────────────────────────────────────────────────────────────────

class QEngine {
  static final QEngine instance = QEngine._();
  QEngine._();

  QSimdArena? _mem;
  QSimdArena? _targetMem;
  QCompiler? _compiler;
  QLSoAEngine? _ecs;
  AnimationController? _activeController;
  VoidCallback? _tickListener;
  bool _initialized = false;

  final QLSignal<int> tick = QLSignal(0);
  final QThemeGraph theme = QThemeGraph();

  void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  QSimdArena get mem {
    _ensureInitialized();
    return _mem!;
  }

  QSimdArena get targetMem {
    _ensureInitialized();
    return _targetMem!;
  }

  QCompiler get compiler {
    _ensureInitialized();
    return _compiler!;
  }

  QLSoAEngine get ecs {
    _ensureInitialized();
    return _ecs!;
  }

  void initialize({int initialCapacity = 4096, int ecsCapacity = 100000}) {
    if (_initialized) return;

    _mem = QSimdArena(capacity: initialCapacity);
    _targetMem = QSimdArena(capacity: initialCapacity);
    _compiler = QCompiler(_mem!, theme: theme);
    _ecs = QLSoAEngine(ecsCapacity);
    _initialized = true;

    _tickListener = () {
      final localEcs = _ecs;
      if (localEcs == null || localEcs.activeCount == 0) return;
      localEcs.computeWorldTransforms();
      localEcs.executeSystem((entity) => localEcs.updateSpatialHash(entity));
    };
    tick.addListener(_tickListener!);
  }

  void dispose() {
    _activeController?.dispose();
    _activeController = null;
    if (_tickListener != null) {
      tick.removeListener(_tickListener!);
      _tickListener = null;
    }
    _initialized = false;
    _mem = null;
    _targetMem = null;
    _compiler = null;
    _ecs = null;
  }

  QToken compileStyle(String style, {int contextMask = 0}) {
    final normalized = style.trim().replaceAll(RegExp(r'\s+'), ' ');
    return compiler.compile(normalized, contextMask: contextMask);
  }

  void loadThemeDictionary(QThemeDictionary dictionary) {
    theme.load(dictionary);
  }

  void animateTheme(
    VoidCallback targetMutations,
    TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final QSimdArena current = mem;
    final QSimdArena target = targetMem;

    target.copyFrom(current);
    final QSimdArena? previousMem = _mem;
    final QCompiler? previousCompiler = _compiler;

    _mem = target;
    _compiler = QCompiler(target, theme: theme);
    if (previousCompiler != null) {
      _compiler!._cache.addAll(previousCompiler._cache);
      _compiler!._cacheVersion.addAll(previousCompiler._cacheVersion);
    }
    try {
      targetMutations();
    } finally {
      _mem = previousMem;
      _compiler = previousCompiler;
    }

    _activeController?.dispose();
    final AnimationController ctrl =
        AnimationController(vsync: vsync, duration: duration);
    _activeController = ctrl;

    ctrl.addListener(() {
      QMorpher.lerpFast(current, target, ctrl.value, current);
      tick.value++;
    });

    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (identical(_activeController, ctrl)) _activeController = null;
        ctrl.dispose();
      }
    });

    ctrl.forward(from: 0.0);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §10 — THE CORE WIDGET (O(1) Rendering & CSS Cascading)
// ────────────────────────────────────────────────────────────────────────────

// ───────────────────────────────────────────────────────────────────────
//  UPDATED CORE `Q` WIDGET (quantum_theme_engine.dart)
// ────────────────────────────────────────────────────────────────────────────
class Q extends StatefulWidget {
  final String style;
  final List<dynamic>? padding;
  final List<dynamic>? margin;
  final num? gap;
  final String? text;
  final List<Widget>? children;
  final VoidCallback? onTap;
  final bool suppressParentData;

  // 🚀 NEW: Hardware Signal Passthroughs
  final QLSignal<Matrix4>? transform3D;
  final QLSignal<double>? opacitySignal;

  const Q(
    this.style, {
    super.key,
    this.padding,
    this.margin,
    this.gap,
    this.text,
    this.children,
    this.onTap,
    this.suppressParentData = false,
    this.transform3D,
    this.opacitySignal,
  });

  factory Q.merge(
    List<dynamic> styles, {
    Key? key,
    List<dynamic>? padding,
    List<dynamic>? margin,
    num? gap,
    String? text,
    List<Widget>? children,
    VoidCallback? onTap,
    bool suppressParentData = false,
  }) {
    final String mergedStyle = styles
        .where((s) => s != null && s != false && s != '')
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return Q(
      mergedStyle,
      key: key,
      padding: padding,
      margin: margin,
      gap: gap,
      text: text,
      children: children,
      onTap: onTap,
      suppressParentData: suppressParentData,
    );
  }

  @override
  State<Q> createState() => _QState();
}

class _QState extends State<Q> {
  late QToken _compiledToken;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _compiledToken = QEngine.instance.compiler.compile(
      widget.style,
      padding: widget.padding,
      margin: widget.margin,
      gap: widget.gap,
    );
  }

  @override
  void didUpdateWidget(covariant Q oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style ||
        oldWidget.padding != widget.padding ||
        oldWidget.margin != widget.margin ||
        oldWidget.gap != widget.gap) {
      _compiledToken = QEngine.instance.compiler.compile(
        widget.style,
        padding: widget.padding,
        margin: widget.margin,
        gap: widget.gap,
      );
    }
  }

  int _contextMaskFromBuild(BuildContext context) {
    int mask = 0;
    final Brightness brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark)
      mask |= QContextBits.dark;
    else
      mask |= QContextBits.light;

    final double width = MediaQuery.maybeOf(context)?.size.width ?? 0;
    if (width < 640) {
      mask |= QContextBits.sm;
    } else if (width < 1024) {
      mask |= QContextBits.md;
    } else if (width < 1440) {
      mask |= QContextBits.lg;
    } else {
      mask |= QContextBits.xl;
    }

    if (Directionality.maybeOf(context) == TextDirection.rtl)
      mask |= QContextBits.rtl;

    return mask;
  }

  @override
  Widget build(BuildContext context) {
    final int contextMask = _contextMaskFromBuild(context);
    final QToken compiled = QEngine.instance.compiler.compile(
      widget.style,
      padding: widget.padding,
      margin: widget.margin,
      gap: widget.gap,
      contextMask: contextMask,
    );

    final QSimdArena mem = QEngine.instance.mem;
    final int id = compiled.id;
    final int lFlags = mem.layoutFlags[id];
    final int rFlags = mem.renderFlags[id];
    final int tFlags = mem.textFlags[id];
    final int sFlags = mem.stateFlags[id];

    // 🚀 O(1) BARE TEXT BYPASS
    if (lFlags == 0 &&
        rFlags == 0 &&
        sFlags == 0 &&
        widget.text != null &&
        widget.children == null &&
        widget.transform3D == null &&
        widget.opacitySignal == null) {
      return _buildText(mem, compiled, tFlags, widget.text!);
    }

    // Builder function that applies the core DOM structure
    Widget constructDom() {
      Widget node = _buildChildren(mem, compiled, lFlags, tFlags);

      // Apply Decoration / Backgrounds
      if (rFlags != 0 || sFlags != 0) {
        node = _buildBox(mem, compiled, rFlags, sFlags, node, context);
      }

      // Apply Hardware Injection
      if (widget.transform3D != null) {
        node = Transform(
            transform: widget.transform3D!.value,
            alignment: Alignment.center,
            child: node);
      }
      if (widget.opacitySignal != null) {
        node = Opacity(
            opacity: widget.opacitySignal!.value.clamp(0.0, 1.0), child: node);
      }

      // Universal Interaction
      if (sFlags != 0 || widget.onTap != null) {
        final bool hasScale = (sFlags & QStateFlags.hasInteractiveScale) != 0;

        if (hasScale) {
          node = QLSensor(
            onTap: widget.onTap,
            scaleOnHover: true,
            scaleOnTap: true,
            onHoverChange: (hovered) {
              if (mounted) setState(() => _isHovered = hovered);
            },
            child: node,
          );
        } else {
          // Pure CSS hover without physics
          node = MouseRegion(
            cursor: widget.onTap != null
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            onEnter: (_) {
              if (mounted) setState(() => _isHovered = true);
            },
            onExit: (_) {
              if (mounted) setState(() => _isHovered = false);
            },
            // 🚀 THE FIX: Only spawn an opaque GestureDetector if we ACTUALLY have a tap action!
            // Otherwise, we just return the node, letting parent detectors catch the tap.
            child: widget.onTap != null
                ? GestureDetector(
                    onTap: widget.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: node,
                  )
                : node,
          );
        }
      }

      // Apply Grid Scope Extrusions natively
      final int iPtr = compiled.iPtr;
      if (!widget.suppressParentData &&
          (mem.i32[iPtr + QI32.colSpan] > 1 ||
              mem.i32[iPtr + QI32.rowSpan] > 1)) {
        node = QuantumItem(
          colSpan: mem.i32[iPtr + QI32.colSpan],
          rowSpan: mem.i32[iPtr + QI32.rowSpan],
          colStart: mem.i32[iPtr + QI32.colStart],
          rowStart: mem.i32[iPtr + QI32.rowStart],
          child: node,
        );
      }
      return node;
    }

    // 🚀 THE ULTIMATE FPS FIX: Does this node ACTUALLY need to animate?
    // If it has no hover states, no explicit signals, and no theme mutations pending, DO NOT USE AnimatedBuilder!
    if (sFlags == 0 &&
        widget.transform3D == null &&
        widget.opacitySignal == null) {
      return constructDom();
    }

    // 🚀 ONLY attach heavy listeners if physics or interactions are required.
    final List<Listenable> animations = [QEngine.instance.tick];
    if (widget.transform3D != null) animations.add(widget.transform3D!);
    if (widget.opacitySignal != null) animations.add(widget.opacitySignal!);

    return AnimatedBuilder(
      animation: animations.length == 1
          ? animations.first
          : Listenable.merge(animations),
      builder: (context, _) => constructDom(),
    );
  }

  Widget _buildText(
      QSimdArena mem, QToken compiled, int tFlags, String textData) {
    final int fPtr = compiled.fPtr;
    final int cPtr = compiled.cPtr;

    final Color color = _isHovered &&
            (mem.stateFlags[compiled.id] & QStateFlags.hasHoverText) != 0
        ? Color(mem.c32[cPtr + QC32.hoverText])
        : Color(mem.c32[cPtr + QC32.text]);

    final double size = mem.f32[fPtr + QF32.fontSize];

    return Text(
      textData,
      textAlign: (tFlags & QTextFlags.textCenter) != 0
          ? TextAlign.center
          : (tFlags & QTextFlags.textRight) != 0
              ? TextAlign.right
              : (tFlags & QTextFlags.textJustify) != 0
                  ? TextAlign.justify
                  : TextAlign.start,
      overflow: (tFlags & QTextFlags.textEllipsis) != 0
          ? TextOverflow.ellipsis
          : null,
      style: TextStyle(
        color: color.alpha == 0 ? null : color,
        fontSize: size > 0 ? size : 14.0,
        fontWeight: (tFlags & QTextFlags.fontBold) != 0
            ? FontWeight.bold
            : FontWeight.normal,
        fontStyle: (tFlags & QTextFlags.fontItalic) != 0
            ? FontStyle.italic
            : FontStyle.normal,
        decoration: (tFlags & QTextFlags.underline) != 0
            ? TextDecoration.underline
            : (tFlags & QTextFlags.strikeThrough) != 0
                ? TextDecoration.lineThrough
                : TextDecoration.none,
        letterSpacing: mem.f32[fPtr + QF32.letterSpacing] != 0
            ? mem.f32[fPtr + QF32.letterSpacing]
            : null,
        height: mem.f32[fPtr + QF32.lineHeight],
      ),
    );
  }

  Widget _buildChildren(
      QSimdArena mem, QToken compiled, int lFlags, int tFlags) {
    final List<Widget> kids = [];
    if (widget.text != null)
      kids.add(_buildText(mem, compiled, tFlags, widget.text!));
    if (widget.children != null) kids.addAll(widget.children!);

    Widget tree = kids.isEmpty
        ? const SizedBox.shrink()
        : (kids.length == 1 && lFlags == 0
            ? kids.first
            : Stack(children: kids));

    if (lFlags != 0) {
      final bool isCol = (lFlags & QLayoutFlags.flexCol) != 0;

      MainAxisAlignment mainAlign = MainAxisAlignment.start;
      if ((lFlags & QLayoutFlags.justifyCenter) != 0)
        mainAlign = MainAxisAlignment.center;
      else if ((lFlags & QLayoutFlags.justifyBetween) != 0)
        mainAlign = MainAxisAlignment.spaceBetween;
      else if ((lFlags & QLayoutFlags.justifyEnd) != 0)
        mainAlign = MainAxisAlignment.end;
      else if ((lFlags & QLayoutFlags.justifyAround) != 0)
        mainAlign = MainAxisAlignment.spaceAround;
      else if ((lFlags & QLayoutFlags.justifyEvenly) != 0)
        mainAlign = MainAxisAlignment.spaceEvenly;

      CrossAxisAlignment crossAlign = CrossAxisAlignment.start;
      if ((lFlags & QLayoutFlags.itemsCenter) != 0)
        crossAlign = CrossAxisAlignment.center;
      else if ((lFlags & QLayoutFlags.itemsEnd) != 0)
        crossAlign = CrossAxisAlignment.end;
      else if ((lFlags & QLayoutFlags.itemsStretch) != 0)
        crossAlign = CrossAxisAlignment.stretch;
      else if ((lFlags & QLayoutFlags.itemsBaseline) != 0)
        crossAlign = CrossAxisAlignment.baseline;

      final double gap = mem.f32[compiled.fPtr + QF32.gap];

      if ((lFlags & QLayoutFlags.wrap) != 0) {
        WrapAlignment wrapAlign = WrapAlignment.start;
        if ((lFlags & QLayoutFlags.justifyCenter) != 0)
          wrapAlign = WrapAlignment.center;
        else if ((lFlags & QLayoutFlags.justifyBetween) != 0)
          wrapAlign = WrapAlignment.spaceBetween;
        else if ((lFlags & QLayoutFlags.justifyEnd) != 0)
          wrapAlign = WrapAlignment.end;

        tree = Wrap(
          direction: isCol ? Axis.vertical : Axis.horizontal,
          spacing: gap,
          runSpacing: gap,
          alignment: wrapAlign,
          crossAxisAlignment: crossAlign == CrossAxisAlignment.center
              ? WrapCrossAlignment.center
              : WrapCrossAlignment.start,
          children: kids,
        );
      } else if ((lFlags & (QLayoutFlags.isGrid | QLayoutFlags.isMasonry)) !=
          0) {
        // NATIVE QLE GRID DELEGATION
        final bool isMasonry = (lFlags & QLayoutFlags.isMasonry) != 0;
        final int colObjId = mem.i32[compiled.iPtr + QI32.gridColsStrId];
        final int rowObjId = mem.i32[compiled.iPtr + QI32.gridRowsStrId];
        final String colStr =
            colObjId > 0 ? mem.objects[colObjId] as String : '1fr';
        final String rowStr =
            rowObjId > 0 ? mem.objects[rowObjId] as String : 'auto';

        tree = QuantumLayoutScope(
          layoutType: isMasonry ? 'masonry' : 'grid',
          child: QuantumGrid(
            columns: colStr,
            rows: rowStr,
            columnGap: gap,
            rowGap: gap,
            flow: isMasonry ? QFlowDirection.masonry : QFlowDirection.row,
            alignItems: crossAlign == CrossAxisAlignment.center
                ? QAlign.center
                : QAlign.stretch,
            justifyItems: mainAlign == MainAxisAlignment.center
                ? QAlign.center
                : QAlign.stretch,
            children: kids,
          ),
        );
      } else if ((lFlags & QLayoutFlags.isFlex) != 0) {
        // NATIVE QLE FLEX DELEGATION (Gap handling offloaded to QLE)
        tree = QuantumLayoutScope(
            layoutType: isCol ? 'col' : 'row',
            child: QuantumFlex(
              direction: isCol ? Axis.vertical : Axis.horizontal,
              gap: gap,
              mainAxisAlignment: mainAlign,
              crossAxisAlignment: crossAlign,
              mainAxisSize: MainAxisSize.min,
              children: kids,
            ));
      }

      if ((lFlags & QLayoutFlags.expand) != 0) tree = Expanded(child: tree);
      if ((lFlags & QLayoutFlags.absolute) != 0)
        tree = Positioned(child: tree); // Expand bounds manually later
      if ((lFlags & QLayoutFlags.fill) != 0)
        tree = Positioned.fill(child: tree);
    }

    // 🚀 NATIVE CSS INHERITANCE: If Text styles are set on a parent, push them to the context!
    if (tFlags != 0 &&
        (tFlags & QTextFlags.isText) == 0 &&
        widget.text == null) {
      final Color color = _isHovered &&
              (mem.stateFlags[compiled.id] & QStateFlags.hasHoverText) != 0
          ? Color(mem.c32[compiled.cPtr + QC32.hoverText])
          : Color(mem.c32[compiled.cPtr + QC32.text]);

      if (color.alpha > 0) {
        tree = DefaultTextStyle.merge(
          style: TextStyle(color: color),
          child:
              IconTheme.merge(data: IconThemeData(color: color), child: tree),
        );
      }
    }

    return tree;
  }

  Widget _buildBox(QSimdArena mem, QToken compiled, int rFlags, int sFlags,
      Widget child, BuildContext context) {
    final int fPtr = compiled.fPtr;
    final int cPtr = compiled.cPtr;
    final int iPtr = compiled.iPtr;

    final Color bgColor = _isHovered && (sFlags & QStateFlags.hasHoverBg) != 0
        ? Color(mem.c32[cPtr + QC32.hoverBackground])
        : Color(mem.c32[cPtr + QC32.background]);

    final Color borderColor =
        _isHovered && (sFlags & QStateFlags.hasHoverBorder) != 0
            ? Color(mem.c32[cPtr + QC32.hoverBorder])
            : Color(mem.c32[cPtr + QC32.border]);

    final double w = mem.f32[fPtr + QF32.width];
    final double h = mem.f32[fPtr + QF32.height];
    final double radius = mem.f32[fPtr + QF32.radius];
    final double opacity = mem.f32[fPtr + QF32.opacity];

    Decoration? dec;
    if (bgColor.alpha > 0 ||
        (rFlags & QRenderFlags.hasBorder) != 0 ||
        (rFlags & QRenderFlags.hasShadow) != 0 ||
        (rFlags & QRenderFlags.hasGradient) != 0 ||
        (rFlags & QRenderFlags.hasImage) != 0) {
      // 1. Resolve Gradients
      Gradient? grad;
      if ((rFlags & QRenderFlags.hasGradient) != 0) {
        Alignment endAlign = Alignment.bottomCenter;
        if ((rFlags & QRenderFlags.gradToRight) != 0) {
          endAlign = Alignment.centerRight;
        } else if ((rFlags & QRenderFlags.gradToBR) != 0) {
          endAlign = Alignment.bottomRight;
        }

        final List<Color> colors = <Color>[
          Color(mem.c32[cPtr + QC32.gradientFrom])
        ];
        if (mem.c32[cPtr + QC32.gradientVia] != 0) {
          colors.add(Color(mem.c32[cPtr + QC32.gradientVia]));
        }
        colors.add(Color(mem.c32[cPtr + QC32.gradientTo]));

        grad = LinearGradient(
          begin: Alignment.topLeft,
          end: endAlign,
          colors: colors,
        );
      }

      // 2. Resolve Background Images
      DecorationImage? bgImage;
      if ((rFlags & QRenderFlags.hasImage) != 0 &&
          mem.i32[iPtr + QI32.imageId] != 0) {
        final obj = mem.objects[mem.i32[iPtr + QI32.imageId]];
        if (obj is ImageProvider) {
          bgImage = DecorationImage(image: obj, fit: BoxFit.cover);
        }
      }

      // 3. Construct Box Decoration
      dec = BoxDecoration(
        color: grad == null && bgImage == null && bgColor.alpha > 0
            ? bgColor
            : null,
        gradient: grad,
        image: bgImage,
        shape: (rFlags & QRenderFlags.isCircle) != 0
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: (rFlags & QRenderFlags.isCircle) == 0 && radius > 0
            ? BorderRadius.circular(radius)
            : null,
        border: (rFlags & QRenderFlags.hasBorder) != 0
            ? Border.all(
                color: borderColor,
                width: mem.f32[fPtr + QF32.borderWidth],
              )
            : null,
        boxShadow: (rFlags & QRenderFlags.hasShadow) != 0
            ? [
                BoxShadow(
                  color: Color(mem.c32[cPtr + QC32.shadow]),
                  blurRadius: mem.f32[fPtr + QF32.shadowBlur],
                  spreadRadius: mem.f32[fPtr + QF32.shadowSpread],
                  offset: Offset(0, mem.f32[fPtr + QF32.shadowBlur] * 0.5),
                )
              ]
            : null,
      );
    }

    // 🚀 THE ULTIMATE 1-PIXEL OVERFLOW ARMOR
    final Clip clipBehavior =
        ((rFlags & QRenderFlags.hasClip) != 0 || dec != null)
            ? Clip.hardEdge
            : Clip.none;

    if (clipBehavior != Clip.none && dec == null) {
      dec = const BoxDecoration();
    }

    Widget node = child;

    final QuantumScrollScope? scrollScope = QuantumScrollScope.of(context);
    final pad = EdgeInsets.fromLTRB(
        mem.f32[fPtr + QF32.padLeft],
        mem.f32[fPtr + QF32.padTop],
        mem.f32[fPtr + QF32.padRight],
        mem.f32[fPtr + QF32.padBottom]);
    final mar = EdgeInsets.fromLTRB(
        mem.f32[fPtr + QF32.marLeft],
        mem.f32[fPtr + QF32.marTop],
        mem.f32[fPtr + QF32.marRight],
        mem.f32[fPtr + QF32.marBottom]);
// 🚀 READ SCROLL SCOPE DIRECTLY: Eliminates the heavy LayoutBuilder completely!
    final bool insideVerticalScroll = scrollScope?.axis == Axis.vertical;
    final bool insideHorizontalScroll = scrollScope?.axis == Axis.horizontal;

    final double? safeW = (w == double.infinity)
        ? (insideHorizontalScroll ? null : double.infinity)
        : (w >= 0 ? w : null);

    final double? safeH = (h == double.infinity)
        ? (insideVerticalScroll ? null : double.infinity)
        : (h >= 0 ? h : null);

    // 🚀 O(1) BYPASS: If there are no physical dimensions or decorations, return raw child
    if (safeW == null &&
        safeH == null &&
        dec == null &&
        pad == EdgeInsets.zero &&
        mar == EdgeInsets.zero) {
      node = child;
    } else {
      node = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: safeW,
        height: safeH,
        padding: pad,
        margin: mar,
        decoration: dec,
        clipBehavior: clipBehavior,
        child: node,
      );
    }

    if (opacity >= 0.0 && opacity < 1.0) {
      node = Opacity(opacity: opacity, child: node);
    }

    if ((rFlags & QRenderFlags.hasBlur) != 0) {
      node = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: mem.f32[fPtr + QF32.blurSigma],
            sigmaY: mem.f32[fPtr + QF32.blurSigma],
          ),
          child: node,
        ),
      );
    }

    return node;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §11 — SPACE PORTAL
// ────────────────────────────────────────────────────────────────────────────

abstract final class QSpace {
  static void warpIntoSpace({
    required BuildContext context,
    required Widget child,
    double startX = 0.0,
    double startY = 0.0,
  }) {
    QuantumOverlay.instance.mount(
      context,
      QLSpatialConfig.window(
        initialX: startX,
        initialY: startY,
      ),
      (ctx, close) => child,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §12 — THEME PRESET HELPERS
// ────────────────────────────────────────────────────────────────────────────

abstract final class QThemePresets {
  static QThemeDictionary fromMap(Map<String, dynamic> map) =>
      QThemeDictionary.fromJson(map);

  static QThemeDictionary darkVivid() {
    return QThemeDictionary.fromJson(<String, dynamic>{
      'colors': <String, dynamic>{
        'brand-primary': '#3B82F6',
        'brand-secondary': '#8B5CF6',
        'surface': '#0F172A',
        'surface-2': '#111827',
        'text': '#E5E7EB',
        'muted': '#94A3B8',
        'border': '#334155',
      },
      'spacing': <String, dynamic>{
        'xs': 4,
        'sm': 8,
        'md': 12,
        'lg': 16,
        'xl': 24,
      },
      'radius': <String, dynamic>{
        'sm': 6,
        'md': 10,
        'lg': 16,
        'xl': 24,
      },
    });
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §13 — OPTIONAL EXTENSIONS FOR STRICTER BEST PRACTICE USE
// ────────────────────────────────────────────────────────────────────────────

extension QThemeGraphExtension on QThemeGraph {
  void loadFromMap(Map<String, dynamic> map) =>
      load(QThemeDictionary.fromJson(map));
}

extension QCompilerThemeExtension on QCompiler {
  void loadTheme(QThemeDictionary dictionary) {
    QEngine.instance.loadThemeDictionary(dictionary);
    _theme.load(dictionary);
  }
}
