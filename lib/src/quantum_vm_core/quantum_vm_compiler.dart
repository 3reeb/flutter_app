// quantum_vm_compiler.dart
// Core AST, Compilation, and Data Binding logic for QuantumVM.

part of 'quantum_vm.dart';

abstract final class QLStableHasher {
  static int of(dynamic value, [int depth = 0]) {
    if (depth > 12 || value == null) return 0;
    if (value is String || value is num || value is bool) return value.hashCode;
    if (value is QLBlueprint) {
      return Object.hash(
          value.type, value.style, of(value.props, depth + 1), value.debugPath);
    }
    if (value is List) {
      var hash = value.length;
      for (final item in value) {
        hash = Object.hash(hash, of(item, depth + 1));
      }
      return hash;
    }
    if (value is Map) {
      var hash = value.length;
      for (final entry in value.entries) {
        hash = Object.hash(
          hash,
          entry.key.toString(),
          of(entry.value, depth + 1),
        );
      }
      return hash;
    }
    return value.hashCode;
  }
}

abstract class QLPipes {
  static final Map<String, dynamic Function(dynamic, List<String>)> registry = {
    'uppercase': (val, args) => val?.toString().toUpperCase(),
    'lowercase': (val, args) => val?.toString().toLowerCase(),
    'default': (val, args) => val ?? args.firstOrNull,
    'multiply': (val, args) =>
        (num.tryParse(val.toString()) ?? 0) *
        (num.tryParse(args.firstOrNull ?? '1') ?? 1),
    'currency': (val, args) {
      final symbol = args.isNotEmpty ? args.first : r'$';
      final amount = num.tryParse(val?.toString() ?? '') ?? 0;
      return '$symbol${amount.toStringAsFixed(2)}';
    },
    'eq': (val, args) => val.toString() == args.firstOrNull,
    'not': (val, args) => val == null || val == false || val == 0 || val == '',
    'filter': (val, args) {
      if (val is! Iterable || args.isEmpty) return val;
      final parts = args[0].split(':').map((s) => s.trim()).toList();
      if (parts.length != 2) return val;
      return val
          .where(
              (item) => item is Map && item[parts[0]]?.toString() == parts[1])
          .toList();
    },
    'count': (val, args) {
      if (val is Iterable || val is Map) return val.length;
      return 0;
    },
    'substring': (val, args) {
      if (val == null) return '';
      final str = val.toString();
      final start = int.tryParse(args.isNotEmpty ? args[0] : '0') ?? 0;
      final end = args.length > 1 ? int.tryParse(args[1]) : null;
      if (start >= str.length) return '';
      if (end != null && end <= str.length) return str.substring(start, end);
      return str.substring(start);
    },
    'switch': (val, args) {
      final Map<String, String> cases = {};
      for (final arg in args) {
        final parts = arg.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim().replaceAll("'", "").replaceAll('"', '');
          final value = parts[1].trim().replaceAll("'", "").replaceAll('"', '');
          cases[key] = value;
        }
      }
      return cases[val.toString()] ?? val;
    },
    'groupBy': (val, args) {
      if (val is! Iterable || args.isEmpty) return val;
      final key = args[0];
      final Map<String, List<dynamic>> grouped = {};
      for (var item in val) {
        if (item is Map) {
          final groupKey = item[key]?.toString() ?? 'unknown';
          grouped.putIfAbsent(groupKey, () => []).add(item);
        }
      }
      return grouped.entries
          .map((e) => {"key": e.key, "items": e.value})
          .toList();
    },
    'sortBy': (val, args) {
      if (val is! Iterable || args.isEmpty) return val;
      final parts = args[0].split(':').map((s) => s.trim()).toList();
      final key = parts[0];
      final isDesc = parts.length > 1 && parts[1].toLowerCase() == 'desc';
      final list = val.toList();
      list.sort((a, b) {
        final aVal = (a as Map)[key];
        final bVal = (b as Map)[key];
        if (aVal is num && bVal is num)
          return isDesc ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
        return isDesc
            ? bVal.toString().compareTo(aVal.toString())
            : aVal.toString().compareTo(bVal.toString());
      });
      return list;
    },
    // â”€â”€ STRING PIPES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'truncate': (val, args) {
      final s = val?.toString() ?? '';
      final n = int.tryParse(args.firstOrNull ?? '100') ?? 100;
      final sfx = args.length > 1 ? args[1] : '...';
      return s.length > n ? '${s.substring(0, n)}$sfx' : s;
    },
    'pad': (val, args) {
      final s = val?.toString() ?? '';
      final n = int.tryParse(args.firstOrNull ?? '2') ?? 2;
      final ch = args.length > 1 ? args[1] : '0';
      final side = args.length > 2 ? args[2] : 'left';
      return side == 'right' ? s.padRight(n, ch) : s.padLeft(n, ch);
    },
    'trim': (val, args) => val?.toString().trim() ?? '',
    'replace': (val, args) => args.length < 2
        ? (val?.toString() ?? '')
        : (val?.toString() ?? '').replaceAll(args[0], args[1]),
    'split': (val, args) =>
        (val?.toString() ?? '').split(args.firstOrNull ?? ','),
    'starts_with': (val, args) =>
        (val?.toString() ?? '').startsWith(args.firstOrNull ?? ''),
    'ends_with': (val, args) =>
        (val?.toString() ?? '').endsWith(args.firstOrNull ?? ''),
    'contains': (val, args) =>
        (val?.toString() ?? '').contains(args.firstOrNull ?? ''),
    'uri_encode': (val, args) => Uri.encodeComponent(val?.toString() ?? ''),
    'uri_decode': (val, args) => Uri.decodeComponent(val?.toString() ?? ''),
    // â”€â”€ NUMBER PIPES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'abs': (val, args) => (num.tryParse(val?.toString() ?? '') ?? 0).abs(),
    'ceil': (val, args) => (num.tryParse(val?.toString() ?? '') ?? 0).ceil(),
    'floor': (val, args) => (num.tryParse(val?.toString() ?? '') ?? 0).floor(),
    'round': (val, args) {
      final d = int.tryParse(args.firstOrNull ?? '0') ?? 0;
      final n = num.tryParse(val?.toString() ?? '') ?? 0;
      if (d == 0) return n.round();
      final f = math.pow(10, d);
      return (n * f).round() / f;
    },
    'clamp': (val, args) {
      if (args.length < 2) return val;
      final n = num.tryParse(val?.toString() ?? '') ?? 0;
      return n.clamp(num.tryParse(args[0]) ?? 0, num.tryParse(args[1]) ?? 0);
    },
    'int': (val, args) =>
        int.tryParse(val?.toString() ?? '') ??
        (num.tryParse(val?.toString() ?? '') ?? 0).toInt(),
    'float': (val, args) => double.tryParse(val?.toString() ?? ''),
    'percent': (val, args) {
      final total = num.tryParse(args.firstOrNull ?? '100') ?? 100;
      final n = num.tryParse(val?.toString() ?? '') ?? 0;
      return total == 0 ? 0.0 : (n / total * 100);
    },
    'bytes': (val, args) {
      final n = num.tryParse(val?.toString() ?? '') ?? 0;
      if (n < 1024) return '${n.round()} B';
      if (n < 1048576) return '${(n / 1024).toStringAsFixed(1)} KB';
      if (n < 1073741824) return '${(n / 1048576).toStringAsFixed(1)} MB';
      return '${(n / 1073741824).toStringAsFixed(1)} GB';
    },
    // â”€â”€ DATE PIPES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'ago': (val, args) {
      final dt =
          val is DateTime ? val : DateTime.tryParse(val?.toString() ?? '');
      if (dt == null) return val?.toString() ?? '';
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 30) return '${diff.inDays}d ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).round()}mo ago';
      return '${(diff.inDays / 365).round()}y ago';
    },
    'date_iso': (val, args) => val is DateTime
        ? val.toIso8601String()
        : (DateTime.tryParse(val?.toString() ?? '')?.toIso8601String() ??
            (val?.toString() ?? '')),
    'unix_ms': (val, args) => val is DateTime
        ? val.millisecondsSinceEpoch
        : (DateTime.tryParse(val?.toString() ?? '')?.millisecondsSinceEpoch ??
            0),
    // â”€â”€ LIST PIPES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'first': (val, args) => val is List && val.isNotEmpty ? val.first : val,
    'last': (val, args) => val is List && val.isNotEmpty ? val.last : val,
    'nth': (val, args) {
      if (val is! List) return val;
      final n = int.tryParse(args.firstOrNull ?? '0') ?? 0;
      return (n >= 0 && n < val.length) ? val[n] : null;
    },
    'length': (val, args) {
      if (val is List) return val.length;
      if (val is Map) return val.length;
      if (val is String) return val.length;
      return 0;
    },
    'join': (val, args) => val is List
        ? val.join(args.firstOrNull ?? ', ')
        : (val?.toString() ?? ''),
    'compact': (val, args) => val is List
        ? val.where((e) => e != null && e != '' && e != false).toList()
        : val,
    'flatten': (val, args) =>
        val is List ? val.expand((e) => e is List ? e : [e]).toList() : val,
    'unique': (val, args) => val is List ? val.toSet().toList() : val,
    'unique_by': (val, args) {
      if (val is! List || args.isEmpty) return val;
      final seen = <dynamic>{};
      return val
          .where((e) => e is Map ? seen.add(e[args[0]]) : seen.add(e))
          .toList();
    },
    'sort': (val, args) {
      if (val is! List) return val;
      final list = List.from(val);
      final key = args.firstOrNull;
      final desc = args.length > 1 && args[1] == 'desc';
      list.sort((a, b) {
        final av = key != null && a is Map ? a[key] : a;
        final bv = key != null && b is Map ? b[key] : b;
        final cmp = av is num && bv is num
            ? av.compareTo(bv)
            : av.toString().compareTo(bv.toString());
        return desc ? -cmp : cmp;
      });
      return list;
    },
    'reverse': (val, args) => val is List ? val.reversed.toList() : val,
    'map': (val, args) => val is List && args.isNotEmpty
        ? val.map((e) => e is Map ? e[args[0]] : e).toList()
        : val,
    'pluck': (val, args) => val is List && args.isNotEmpty
        ? val.map((e) => e is Map ? e[args[0]] : e).toList()
        : val,
    'sum': (val, args) {
      if (val is! List) return num.tryParse(val?.toString() ?? '') ?? 0;
      return val.fold<num>(0, (acc, e) {
        final n = args.isNotEmpty && e is Map ? e[args[0]] : e;
        return acc + (num.tryParse(n?.toString() ?? '') ?? 0);
      });
    },
    'avg': (val, args) {
      if (val is! List || val.isEmpty) return 0;
      final total = val.fold<num>(0, (acc, e) {
        final n = args.isNotEmpty && e is Map ? e[args[0]] : e;
        return acc + (num.tryParse(n?.toString() ?? '') ?? 0);
      });
      return total / val.length;
    },
    'min_val': (val, args) {
      if (val is! List || val.isEmpty) return null;
      return val
          .map((e) => args.isNotEmpty && e is Map ? e[args[0]] : e)
          .map((e) => num.tryParse(e?.toString() ?? '') ?? 0)
          .reduce((a, b) => a < b ? a : b);
    },
    'max_val': (val, args) {
      if (val is! List || val.isEmpty) return null;
      return val
          .map((e) => args.isNotEmpty && e is Map ? e[args[0]] : e)
          .map((e) => num.tryParse(e?.toString() ?? '') ?? 0)
          .reduce((a, b) => a > b ? a : b);
    },
    'chunk': (val, args) {
      if (val is! List) return val;
      final n = int.tryParse(args.firstOrNull ?? '10') ?? 10;
      final chunks = <List>[];
      for (var i = 0; i < val.length; i += n) {
        chunks.add(val.sublist(i, math.min(i + n, val.length)));
      }
      return chunks;
    },
    'slice': (val, args) {
      if (val is! List || args.isEmpty) return val;
      final start = int.tryParse(args[0]) ?? 0;
      final end = args.length > 1 ? int.tryParse(args[1]) : null;
      return val.sublist(start, end != null ? math.min(end, val.length) : null);
    },
    // â”€â”€ MAP PIPES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'keys': (val, args) => val is Map ? val.keys.toList() : [],
    'values': (val, args) => val is Map ? val.values.toList() : [],
    'pick': (val, args) => val is Map && args.isNotEmpty
        ? {
            for (final k in args)
              if (val.containsKey(k)) k: val[k]
          }
        : val,
    'omit': (val, args) => val is Map && args.isNotEmpty
        ? {
            for (final e in val.entries)
              if (!args.contains(e.key)) e.key: e.value
          }
        : val,
    'get': (val, args) {
      if (args.isEmpty || val == null) return val;
      dynamic cur = val;
      for (final k in args[0].split('.')) {
        if (cur is Map)
          cur = cur[k];
        else
          return null;
      }
      return cur;
    },
    'has': (val, args) =>
        val is Map && args.isNotEmpty && val.containsKey(args[0]),
    // â”€â”€ TYPE / LOGIC PIPES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'bool': (val, args) =>
        val == true || val == 'true' || val == 1 || val == '1',
    'string': (val, args) => val?.toString() ?? '',
    'is_null': (val, args) => val == null,
    'not_empty': (val, args) => val != null && val.toString().isNotEmpty,
    'is_empty': (val, args) => val == null || val.toString().isEmpty,
    'ternary': (val, args) {
      if (args.length < 2) return val;
      return (val == true || val == 'true' || val == 1) ? args[0] : args[1];
    },
    'json': (val, args) {
      try {
        return jsonEncode(val);
      } catch (_) {
        return val?.toString() ?? '';
      }
    },
    'parse': (val, args) {
      try {
        return jsonDecode(val?.toString() ?? '{}');
      } catch (_) {
        return val;
      }
    },
    'hash': (val, args) => val.hashCode.abs().toString(),
  };

  static void register(
          String name, dynamic Function(dynamic, List<String>) transform) =>
      registry[name] = transform;
}

class QLBlueprint {
  final String type;
  final Map<String, dynamic> props;
  final String? style;
  final List<QLBlueprint> children;
  final Map<String, QLBlueprint> slots;
  final String debugPath;

  const QLBlueprint({
    required this.type,
    required this.props,
    this.style,
    required this.children,
    this.slots = const {},
    this.debugPath = 'root',
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'props': props,
        if (style != null) 'style': style,
        if (children.isNotEmpty)
          'children': children.map((c) => c.toJson()).toList(growable: false),
        if (slots.isNotEmpty)
          'slots': slots.map((k, v) => MapEntry(k, v.toJson())),
        'debugPath': debugPath,
      };

  factory QLBlueprint.fromJson(Map<String, dynamic> json,
      {String path = 'root'}) {
    final normalized = QLCompiler._normalizeNode(json);

    return QLBlueprint(
      type: normalized['type']?.toString() ?? 'box',
      props: normalized['props'] is Map
          ? Map<String, dynamic>.from(normalized['props'])
          : {},
      style: normalized['style']?.toString(),
      children: (normalized['children'] as List?)
              ?.whereType<Map>()
              .toList()
              .asMap()
              .entries
              .map((e) => QLBlueprint.fromJson(
                  Map<String, dynamic>.from(e.value),
                  path: '$path.children[${e.key}]'))
              .toList() ??
          [],
      slots: (normalized['slots'] as Map?)?.map((k, v) => MapEntry(
              k.toString(),
              QLBlueprint.fromJson(Map<String, dynamic>.from(v as Map),
                  path: '$path.slots[$k]'))) ??
          {},
      debugPath: path,
    );
  }
}

abstract final class QLCompiler {
  static const int _maxAstDepth = 128;
  static final QLRuntimeCache<Map<String, dynamic>> _macroExpansionCache =
      QLRuntimeCache<Map<String, dynamic>>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 1536, maxWeight: 3 * 1024 * 1024));
  static final QLRuntimeCache<QLBlueprint> _blueprintCache =
      QLRuntimeCache<QLBlueprint>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 768, maxWeight: 6 * 1024 * 1024));
  static final QLRuntimeCache<ParsedToken> _tokenCache =
      QLRuntimeCache<ParsedToken>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 4096, maxWeight: 2 * 1024 * 1024));

  static Map<String, dynamic> _deepCopy(Map source) {
    final Map<String, dynamic> copy = {};
    source.forEach((k, v) {
      final String keyStr = k.toString();
      if (v is Map) {
        copy[keyStr] = _deepCopy(v);
      } else if (v is List) {
        copy[keyStr] = _deepCopyList(v);
      } else {
        copy[keyStr] = v;
      }
    });
    return copy;
  }

  static List<dynamic> _deepCopyList(List<dynamic> source) {
    return source.map((v) {
      if (v is Map) return _deepCopy(v);
      if (v is List) return _deepCopyList(v);
      return v;
    }).toList();
  }

  static Future<QLBlueprint> compileAsync(
      dynamic rawNode, Map<String, dynamic> macros,
      [Map<String, dynamic> env = const {}]) async {
    final cached = _blueprintCache.get(_compileCacheKey(rawNode, macros, env));
    if (cached != null) return cached;
    if (kIsWeb || rawNode.toString().length < 5000) {
      return compile(rawNode, macros, env);
    }
    final compiled =
        await QLIsolateBridge.safeRun(() => compile(rawNode, macros, env));
    _blueprintCache.put(_compileCacheKey(rawNode, macros, env), compiled);
    return compiled;
  }

  static QLBlueprint compile(dynamic rawNode, Map<String, dynamic> macros,
      [Map<String, dynamic> env = const {}]) {
    final int cacheKey = _compileCacheKey(rawNode, macros, env);
    final cached = _blueprintCache.get(cacheKey);
    if (cached != null) return cached;

    final mutableRoot = _normalizeNode(rawNode);
    final List<QLBlueprint> nodes =
        _processNode(mutableRoot, macros, env, 0, '');
    final blueprint = nodes.isNotEmpty
        ? nodes.first
        : const QLBlueprint(type: 'box:col', props: {}, children: []);
    _blueprintCache.put(cacheKey, blueprint);
    return blueprint;
  }

  static int _compileCacheKey(dynamic rawNode, Map<String, dynamic> macros,
          Map<String, dynamic> env) =>
      Object.hash(
        QLStableHasher.of(rawNode),
        QLStableHasher.of(macros),
        QLStableHasher.of(env),
      );

  static Map<String, dynamic> _normalizeNode(dynamic raw) {
    Map<String, dynamic> out;

    if (raw is Map) {
      out = _deepCopy(raw).cast<String, dynamic>();
    } else if (raw is String) {
      out = {
        'type': 'text',
        'props': {'text': raw}
      };
    } else if (raw is! List || raw.isEmpty) {
      out = {'type': 'empty'};
    } else {
      out = {};
      final String rawType = raw[0].toString();
      final parts = rawType.split('.');
      String type = parts[0];

      if (type == '->') type = 'box:row';
      if (type == 'v') type = 'box:col';

      out['type'] = type;

      String style = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      Map<String, dynamic> props = {};
      Map<String, dynamic> slots = {};
      List<dynamic> children = [];

      for (int i = 1; i < raw.length; i++) {
        final item = raw[i];
        if (item is Map && i == 1) {
          item.forEach((k, v) {
            if (k == r'$slots' && v is Map)
              slots.addAll(Map<String, dynamic>.from(v));
            else
              props[k] = v;
          });
        } else if (item is String) {
          if (i == 1 && props.isEmpty && children.isEmpty) {
            if ((type.startsWith('text') || type.startsWith('action')) &&
                raw.length == 2) {
              props['text'] = item;
            } else {
              style = style.isEmpty ? item : '$style $item';
            }
          } else {
            children.add({
              'type': 'text',
              'props': {'text': item}
            });
          }
        } else {
          if (item is List &&
              item.isNotEmpty &&
              (item[0] is List || item[0] is Map)) {
            for (final subItem in item) {
              final Map<String, dynamic> normalizedSub =
                  _normalizeNode(subItem);
              if (normalizedSub['props'] != null &&
                  normalizedSub['props']['slot'] != null) {
                final String slotName =
                    normalizedSub['props'].remove('slot').toString();
                slots[slotName] = normalizedSub;
              } else {
                children.add(normalizedSub);
              }
            }
          } else {
            final Map<String, dynamic> normalizedChild = _normalizeNode(item);
            if (normalizedChild['props'] != null &&
                normalizedChild['props']['slot'] != null) {
              final String slotName =
                  normalizedChild['props'].remove('slot').toString();
              slots[slotName] = normalizedChild;
            } else {
              children.add(normalizedChild);
            }
          }
        }
      }

      if (style.isNotEmpty) out['style'] = style;
      if (props.isNotEmpty) out['props'] = props;
      if (slots.isNotEmpty) out['slots'] = slots;
      if (children.isNotEmpty) out['children'] = children;
    }

    if (out.containsKey('type') && out['type'] == null) {
      throw const FormatException('Node missing type');
    }

    if (out['type'] != null) {
      String type = out['type'].toString();

      final aliasDef = QuantumVM.instance.getAlias(type);
      if (aliasDef != null) {
        type = aliasDef['type'] as String;
        final defaultProps =
            Map<String, dynamic>.from(aliasDef['props'] as Map? ?? {});
        out['props'] ??= <String, dynamic>{};
        defaultProps.forEach((k, v) => out['props'].putIfAbsent(k, () => v));
      }

      final colonParts = type.split(':');
      final String baseType = colonParts[0];
      final String subType = colonParts.length > 1 ? colonParts[1] : '';

      if (baseType == 'box' && subType.isNotEmpty) {
        out['type'] = type;
      } else {
        out['type'] = baseType;
        if (subType.isNotEmpty) {
          out['props'] ??= <String, dynamic>{};
          out['props']['__subType'] = subType;
        }
      }

      final actualSubType = subType.isNotEmpty
          ? subType
          : (out['props']?['__subType']?.toString() ?? '');

      if (baseType == 'data' && actualSubType == 'paginated') {
        if (out['props']?['pageSize'] == null) {
          throw const FormatException('data:paginated requires pageSize');
        }
      }

      if (baseType == 'data' && actualSubType == 'diff') {
        if (out['props']?['keyBy'] == null && out['props']?['key'] == null) {
          throw const FormatException('data:diff requires keyBy or key');
        }
      }

      if (baseType == 'field' && actualSubType == 'slider') {
        final props = out['props'] as Map?;
        if (props != null && props.containsKey('defaultValue')) {
          final val = num.tryParse(props['defaultValue'].toString());
          final min = num.tryParse(props['min']?.toString() ?? '0') ?? 0;
          final max = num.tryParse(props['max']?.toString() ?? '100') ?? 100;
          if (val != null && (val < min || val > max)) {
            throw const FormatException(
                'Slider defaultValue outside min/max range');
          }
        }
      }
    }

    if (out['name'] != null) {
      out['props'] ??= <String, dynamic>{};
      out['props']['name'] = out['name'];
    }
    if (out['slot'] != null) {
      out['props'] ??= <String, dynamic>{};
      out['props']['slot'] = out['slot'];
    }

    if (out['props'] != null) {
      _parseMicroActions(out['props']);
    }

    if (out['type'] == 'box:split') {
      out['style'] = mergeStyleTokens([out['style'], 'min-w-0 min-h-0']);
    }

    return out;
  }

  static void _parseMicroActions(Map<String, dynamic> props) {
    for (final key in props.keys.toList()) {
      if (key.startsWith('on') && props[key] is List) {
        final List events = props[key];
        if (events.isNotEmpty && events.first is String) {
          final List<Map<String, dynamic>> parsedActions = [];
          for (final dynamic rawCmd in events) {
            if (rawCmd == null) continue;
            final String cmd = rawCmd.toString();
            final Map<String, dynamic> action = {};
            final colonIdx = cmd.indexOf(':');
            if (colonIdx == -1) {
              action['action'] = cmd.trim();
            } else {
              action['action'] = cmd.substring(0, colonIdx).trim();
              final payloadStr = cmd.substring(colonIdx + 1).trim();
              final eqIdx = payloadStr.indexOf('=');
              if (eqIdx != -1) {
                action[payloadStr.substring(0, eqIdx).trim()] =
                    payloadStr.substring(eqIdx + 1).trim();
              } else {
                if (action['action'].toString().startsWith('route.')) {
                  action['path'] = payloadStr;
                } else {
                  action['value'] = payloadStr;
                }
              }
            }
            parsedActions.add(action);
          }
          props[key] = parsedActions;
        }
      }
    }
  }

  static List<QLBlueprint> _processNode(
      dynamic rawNode,
      Map<String, dynamic> macros,
      Map<String, dynamic> compileEnv,
      int depth,
      String parentPath) {
    if (depth > _maxAstDepth)
      throw const QuantumSecurityException('SDUI AST Overflow Guard.');

    final Map<String, dynamic> node = _normalizeNode(rawNode);
    final Map<String, dynamic> currentEnv = {...compileEnv, ...?node['env']};

    if (node.containsKey(r'$define')) {
      (node[r'$define'] as Map).forEach((k, v) => macros[k.toString()] = v);
    }

    if (node.containsKey(r'$let')) {
      final Map letVars =
          _injectCompileTimeStructurally(node[r'$let'], currentEnv);
      currentEnv.addAll(letVars.cast<String, dynamic>());
    }

    if (node.containsKey(r'$classes')) {
      currentEnv['__classes'] = {
        ...(currentEnv['__classes'] ?? {}),
        ...(node[r'$classes'] as Map)
      };
    }

    if (node.containsKey(r'$scope')) {
      final String addedScope =
          _injectCompileTimeStructurally(node[r'$scope'], currentEnv)
              .toString();
      final String prevScope = currentEnv['__scope'] ?? '';
      currentEnv['__scope'] =
          prevScope.isEmpty ? addedScope : '$prevScope.$addedScope';
    }

    if (node.containsKey(r'$switch')) {
      final String val =
          _injectCompileTimeStructurally(node[r'$switch'], currentEnv)
              .toString();
      final Map cases = node['cases'] ?? {};
      dynamic matched = cases[val] ?? node['default'];
      if (matched == null) return [];
      return _processNode(matched, macros, currentEnv, depth + 1, parentPath);
    }

    if (node.containsKey(r'$repeat')) {
      final Map<String, dynamic> repeatProps = {
        'bind': node[r'$repeat'],
        'as': node['as'] ?? 'item',
        'indexAs': node['indexAs'] ?? 'index',
        '__subType': 'repeater',
      };
      final Map<String, dynamic> repeaterNode = {
        'type': 'system',
        'props': repeatProps,
        'children': [
          _deepCopy(node)
            ..remove(r'$repeat')
            ..remove('as')
            ..remove('indexAs')
        ]
      };
      return _processNode(
          repeaterNode, macros, currentEnv, depth + 1, parentPath);
    }

    if (node.containsKey(r'$if')) {
      final dynamic condition =
          _injectCompileTimeStructurally(node[r'$if'], currentEnv);
      if (condition == false ||
          condition == 'false' ||
          condition == 0 ||
          condition == '0' ||
          condition == null ||
          condition == '') {
        return const [];
      }
    }

    if (node.containsKey(r'$call')) {
      final String macroName = node[r'$call'].toString();
      if (macros.containsKey(macroName)) {
        final Map<String, dynamic> expandedMacro = _expandMacro(
            macroName, node, _deepCopy(macros[macroName]), currentEnv);
        return _processNode(
            expandedMacro, macros, currentEnv, depth + 1, parentPath);
      }
    }

    final String? directMacroName = node['type']?.toString();
    if (directMacroName != null && macros.containsKey(directMacroName)) {
      final Map<String, dynamic> expandedMacro = _expandMacro(directMacroName,
          node, _deepCopy(macros[directMacroName]), currentEnv);
      return _processNode(
          expandedMacro, macros, currentEnv, depth + 1, parentPath);
    }

    if (node.containsKey(r'$apply')) {
      final Map applyDef = node[r'$apply'] is Map
          ? Map<String, dynamic>.from(node[r'$apply'] as Map)
          : <String, dynamic>{};
      final Map<String, dynamic> overrideProps =
          Map<String, dynamic>.from(applyDef['props'] as Map? ?? const {});
      final String? styleStr = applyDef['style']?.toString();
      final bool isMerge = applyDef['mode'] != 'override';

      final List rawChildren = node['children'] is List
          ? List<dynamic>.from(node['children'] as List)
          : const <dynamic>[];
      final List<QLBlueprint> comp = [];
      for (int i = 0; i < rawChildren.length; i++) {
        final Map<String, dynamic> child = _normalizeNode(rawChildren[i]);
        child['props'] ??= <String, dynamic>{};
        if (overrideProps.isNotEmpty) {
          if (isMerge) {
            (child['props'] as Map).addAll(overrideProps);
          } else {
            child['props'] = Map<String, dynamic>.from(overrideProps);
          }
        }
        if (styleStr != null) {
          child['style'] = isMerge && child['style'] != null
              ? '${child['style']} $styleStr'.trim()
              : styleStr;
        }
        comp.addAll(
            _processNode(child, macros, currentEnv, depth + 1, parentPath));
      }
      return comp;
    }

    if (node.containsKey(r'$layout')) {
      final List<String> layoutRows = (node[r'$layout'] as List).cast<String>();
      final Map slots = node['slots'] ?? {};
      final Map<String, _GridRect> rects = {};

      for (int r = 0; r < layoutRows.length; r++) {
        final cols = layoutRows[r]
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .toList();
        for (int c = 0; c < cols.length; c++) {
          final slot = cols[c];
          if (slot == '.') continue;
          if (!rects.containsKey(slot)) {
            rects[slot] = _GridRect(r, c, r, c);
          } else {
            if (r > rects[slot]!.maxR) rects[slot]!.maxR = r;
            if (c > rects[slot]!.maxC) rects[slot]!.maxC = c;
          }
        }
      }

      final List<dynamic> gridChildren = [];
      rects.forEach((slotName, rect) {
        final slotData = slots[slotName];
        if (slotData != null) {
          gridChildren.add({
            "type": "box:grid_item",
            "props": {
              "rowStart": rect.minR + 1,
              "rowEnd": rect.maxR + 2,
              "colStart": rect.minC + 1,
              "colEnd": rect.maxC + 2,
            },
            "children": [slotData]
          });
        }
      });

      node['type'] = 'box:grid';
      node['props'] ??= <String, dynamic>{};
      node['props']['gridRows'] = 'repeat(${layoutRows.length}, auto)';
      node['props']['gridCols'] =
          'repeat(${layoutRows.first.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length}, 1fr)';
      if (node.containsKey('gap')) node['props']['gap'] = node['gap'];
      node['children'] = gridChildren;
      node.remove('slots');
    }

    // â”€â”€ SLOT SHORTHAND: #slotName keys in props â†’ slots map â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node['props'] is Map) {
      final propsMap = node['props'] as Map<String, dynamic>;
      final slotKeys = propsMap.keys.where((k) => k.startsWith('#')).toList();
      if (slotKeys.isNotEmpty) {
        node['slots'] ??= <String, dynamic>{};
        for (final k in slotKeys) {
          (node['slots'] as Map)[k.substring(1)] = propsMap.remove(k);
        }
      }
    }

    // â”€â”€ $try / $catch / $finally â†’ hook:error_boundary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$try')) {
      return _processNode({
        'type': 'hook',
        'props': {'__subType': 'error_boundary'},
        'slots': {
          'try': node[r'$try'] ?? node,
          if (node[r'$catch'] != null) 'catch': node[r'$catch'],
          if (node[r'$finally'] != null) 'finally': node[r'$finally'],
        },
      }, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $async â†’ system:async with loading/data/error slots â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$async')) {
      final def = node[r'$async'] is Map
          ? node[r'$async'] as Map<String, dynamic>
          : <String, dynamic>{};
      return _processNode({
        'type': 'system',
        'props': {
          '__subType': 'async',
          'action': def['action'] ?? '',
          'params': def['params'] ?? const <String, dynamic>{}
        },
        'slots': {
          if (node[r'$loading'] != null) 'loading': node[r'$loading'],
          if (def[r'$loading'] != null) 'loading': def[r'$loading'],
          if (node[r'$data'] != null) 'data': node[r'$data'],
          if (def[r'$data'] != null) 'data': def[r'$data'],
          if (node[r'$error'] != null) 'error': node[r'$error'],
          if (def[r'$error'] != null) 'error': def[r'$error'],
        },
        if (node['children'] != null) 'children': node['children'],
      }, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $stream â†’ data:stream reactive signal binding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$stream')) {
      final def = node[r'$stream'] is Map
          ? node[r'$stream'] as Map<String, dynamic>
          : <String, dynamic>{'bind': node[r'$stream']};
      return _processNode({
        'type': 'data',
        'props': {
          '__subType': 'stream',
          'bind': def['bind'] ?? '',
          'as': def['as'] ?? 'item'
        },
        if (node['children'] != null) 'children': node['children'],
        if (node['slots'] != null) 'slots': node['slots'],
      }, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $machine â†’ control:machine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$machine')) {
      final def = node[r'$machine'] is Map
          ? node[r'$machine'] as Map<String, dynamic>
          : <String, dynamic>{};
      final Map<String, dynamic> machineNode = {
        'type': 'control',
        'props': {
          '__subType': 'machine',
          'id': def['id'] ?? 'machine_${node.hashCode}',
          'initial': def['initial'] ?? '',
          'states': def['states'] ?? const <String, dynamic>{},
          'context': def['context'] ?? const <String, dynamic>{}
        },
        if (node['children'] != null) 'children': node['children'],
      };

      if (node['type'] == null || node['type'] == 'wrapper') {
        return _processNode(
            machineNode, macros, currentEnv, depth + 1, parentPath);
      }

      if (node['children'] is List) {
        final List children = List<dynamic>.from(node['children'] as List);
        if (children.isNotEmpty) {
          final dynamic firstChild = children.removeAt(0);
          node['children'] = [
            {
              ...machineNode,
              'children': [firstChild],
            },
            ...children,
          ];
        } else {
          node['children'] = [machineNode];
        }
      } else {
        node['children'] = [machineNode];
      }
    }

    // â”€â”€ $throttle / $debounce â†’ system:throttle/debounce wrapper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$throttle') || node.containsKey(r'$debounce')) {
      final ms = (node[r'$throttle'] ?? node[r'$debounce']) as int? ?? 100;
      final mode = node.containsKey(r'$throttle') ? 'throttle' : 'debounce';
      return _processNode({
        'type': 'system',
        'props': {'__subType': mode, 'ms': ms},
        if (node['children'] != null) 'children': node['children'],
        if (node['slots'] != null) 'slots': node['slots'],
      }, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $portal â†’ portal:overlay_entry transport â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$portal')) {
      final portalName = node[r'$portal'].toString();
      final inner = _deepCopy(node)..remove(r'$portal');
      return _processNode({
        'type': 'portal',
        'props': {'__subType': 'overlay_entry', 'portalName': portalName},
        'slots': {'content': inner},
      }, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $reactive_map â†’ data:diff animated list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$reactive_map')) {
      final def = node[r'$reactive_map'] is Map
          ? node[r'$reactive_map'] as Map<String, dynamic>
          : <String, dynamic>{'bind': node[r'$reactive_map']};
      return _processNode({
        'type': 'data',
        'props': {
          '__subType': 'diff',
          'bind': def['bind'] ?? '',
          'key': def['key'] ?? 'id',
          'as': def['as'] ?? 'item'
        },
        'children': node['children'] ?? [],
      }, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $compose â†’ behavior chain via behaviors prop â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$compose')) {
      final behaviors = node[r'$compose'] as List? ?? [];
      final inner = _deepCopy(node)..remove(r'$compose');
      inner['props'] ??= <String, dynamic>{};
      (inner['props'] as Map)['behaviors'] = behaviors.take(8).toList();
      return _processNode(inner, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $watch â†’ mark signal dependency for reactive boundary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$watch')) {
      final inner = _deepCopy(node)..remove(r'$watch');
      inner['props'] ??= <String, dynamic>{};
      (inner['props'] as Map)[r'$watch'] = node[r'$watch'].toString();
      return _processNode(inner, macros, currentEnv, depth + 1, parentPath);
    }

    // â”€â”€ $parallel â†’ fan-out concurrent children â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (node.containsKey(r'$parallel')) {
      final items = (node[r'$parallel'] as List? ?? []).take(8).toList();
      return _processNode({'type': 'box:col', 'children': items}, macros,
          currentEnv, depth + 1, parentPath);
    }

    final dynamic explicitName =
        node['name'] ?? (node['props'] is Map ? node['props']['name'] : null);
    final String currentPath = explicitName != null
        ? (parentPath.isEmpty
            ? explicitName.isEmpty
                ? "root"
                : explicitName.toString()
            : '$parentPath.${explicitName.toString()}')
        : (parentPath.isEmpty ? 'root' : parentPath);

    // final String currentPath = parentPath.isEmpty ? 'root' : parentPath;

    final String resolvedType =
        _injectCompileTime(node['type']?.toString() ?? 'box:col', currentEnv);

    final Map<String, dynamic> safeProps = {};
    if (node['props'] == null) node['props'] = <String, dynamic>{};

    if (node.containsKey(r'$spread') ||
        (node['props'] as Map).containsKey(r'$spread')) {
      final spreadPath = node[r'$spread'] ?? node['props'][r'$spread'];
      final spreadData = _injectCompileTimeStructurally(spreadPath, currentEnv);
      if (spreadData is Map)
        safeProps.addAll(spreadData.cast<String, dynamic>());
      (node['props'] as Map).remove(r'$spread');
    }

    if (node['text'] != null)
      safeProps['text'] =
          _injectCompileTimeStructurally(node['text'], currentEnv);

    (node['props'] as Map).forEach((k, v) {
      safeProps[k.toString()] = _injectCompileTimeStructurally(v, currentEnv);
    });

    if (safeProps.containsKey('bind') && currentEnv.containsKey('__scope')) {
      final scope = currentEnv['__scope'];
      if (scope != null && scope.toString().isNotEmpty) {
        final b = safeProps['bind'].toString();
        if (!b.startsWith('/')) {
          safeProps['bind'] = '$scope.$b';
        } else {
          safeProps['bind'] = b.substring(1);
        }
      }
    }

    _tokenizeNodeProperties(safeProps, 0);

    final List<QLBlueprint> children = [];
    if (node['children'] != null && node['children'] is List) {
      final List rawChildren = node['children'];
      for (int i = 0; i < rawChildren.length; i++) {
        children.addAll(_processNode(rawChildren[i], macros, currentEnv,
            depth + 1, currentPath.isEmpty ? '[$i]' : '$currentPath[$i]'));
      }
    }

    String? compiledStyle;
    if (node['styles'] is List) {
      compiledStyle =
          _injectCompileTime((node['styles'] as List).join(' '), currentEnv);
    } else if (node['style'] is String) {
      compiledStyle = _injectCompileTime(node['style'], currentEnv);
    }

    if (compiledStyle != null &&
        compiledStyle.contains('@') &&
        currentEnv.containsKey('__classes')) {
      final classes = currentEnv['__classes'] as Map;
      classes.forEach((k, v) {
        compiledStyle = compiledStyle!.replaceAll('@$k', v.toString());
      });
    }

    final Map<String, QLBlueprint> resolvedSlots = {};
    if (node['slots'] is Map) {
      (node['slots'] as Map).forEach((k, v) {
        final List<QLBlueprint> compiledSlot = _processNode(
            v, macros, currentEnv, depth + 1, '$currentPath.slots[$k]');
        if (compiledSlot.isNotEmpty) {
          resolvedSlots[k.toString()] = compiledSlot.first;
        }
      });
    }

    QLBlueprint coreBlueprint = QLBlueprint(
      type: resolvedType,
      props: Map.unmodifiable(safeProps),
      style: compiledStyle,
      children: List.unmodifiable(children),
      slots: resolvedSlots,
      debugPath: currentPath,
    );

    if (node['state'] != null) {
      final Map<String, dynamic> childProps =
          Map<String, dynamic>.from(safeProps)
            ..remove('name')
            ..remove('slot');
      final QLBlueprint childBlueprint = QLBlueprint(
        type: resolvedType,
        props: Map.unmodifiable(childProps),
        style: compiledStyle,
        children: List.unmodifiable(children),
        slots: resolvedSlots,
        debugPath: currentPath,
      );

      return [
        QLBlueprint(
          type: 'system',
          props: {
            '__subType': 'store_provider',
            'initialState':
                _injectCompileTimeStructurally(node['state'], currentEnv)
          },
          debugPath: '$currentPath.store_provider',
          children: [childBlueprint],
        )
      ];
    }

    return [coreBlueprint];
  }

  static Map<String, dynamic> _expandMacro(
      String macroName,
      Map<String, dynamic> callerNode,
      Map<String, dynamic> macroDef,
      Map<String, dynamic> env) {
    final int cacheKey = Object.hash(macroName, QLStableHasher.of(callerNode),
        QLStableHasher.of(macroDef), QLStableHasher.of(env));
    final cached = _macroExpansionCache.get(cacheKey);
    if (cached != null) return _deepCopy(cached);

    final Map<String, dynamic> macroEnv = Map.from(env);
    final Map<String, dynamic> defaultProps = _macroDefaultProps(macroDef, env);
    final Map<String, dynamic> callerProps = _macroCallerProps(callerNode, env);
    final Map<String, dynamic> mergedProps = {
      ...defaultProps,
      ...callerProps,
    };
    macroEnv['props'] = mergedProps;
    macroEnv[r'$props'] = mergedProps;

    final _QLMacroSlots macroSlots =
        _collectMacroSlots(macroName, callerNode, macroDef, env);
    macroEnv['slots'] = macroSlots.callerSlots;
    macroEnv[r'$slots'] = macroSlots.callerSlots;

    final Map<String, dynamic> macroView = _macroView(macroDef);
    final Map<String, dynamic> expanded =
        (_injectCompileTimeStructurally(macroView, macroEnv) as Map)
            .cast<String, dynamic>();

    expanded['props'] = {
      ...defaultProps,
      ...(expanded['props'] is Map
          ? Map<String, dynamic>.from(expanded['props'] as Map)
          : const <String, dynamic>{}),
      ...callerProps,
    };

    final dynamic withSlots = _injectMacroSlots(expanded, macroSlots);
    final Map<String, dynamic> slotted = withSlots is Map
        ? withSlots.cast<String, dynamic>()
        : {
            'type': 'box:col',
            'children': withSlots is List ? withSlots : [withSlots]
          };

    final Map<String, dynamic> exposedSlots = {};
    if (slotted['slots'] is Map) {
      exposedSlots.addAll(Map<String, dynamic>.from(slotted['slots'] as Map));
    }
    exposedSlots.addAll(macroSlots.defaultSlots);
    exposedSlots.addAll(macroSlots.callerSlots);
    if (exposedSlots.isNotEmpty) slotted['slots'] = exposedSlots;

    if (callerNode['style'] != null)
      slotted['style'] =
          '${slotted['style'] ?? ''} ${callerNode['style']}'.trim();

    _macroExpansionCache.put(cacheKey, _deepCopy(slotted));
    return slotted;
  }

  static Map<String, dynamic> _macroView(Map<String, dynamic> macroDef) {
    final dynamic view =
        macroDef[r'$view'] ?? macroDef['view'] ?? macroDef['template'];
    if (view is Map) return _deepCopy(view);
    if (macroDef['schema'] is Map &&
        (macroDef['type'] == null || macroDef['view'] != null)) {
      return _deepCopy(macroDef['schema'] as Map);
    }
    final copy = _deepCopy(macroDef);
    copy.remove('defaultProps');
    copy.remove('defaultSlots');
    copy.remove(r'$slots');
    copy.remove(r'$view');
    copy.remove('view');
    copy.remove('template');
    return copy;
  }

  static Map<String, dynamic> _macroDefaultProps(
      Map<String, dynamic> macroDef, Map<String, dynamic> env) {
    final Map<String, dynamic> defaults = {};
    if (macroDef['defaultProps'] is Map) {
      defaults.addAll(Map<String, dynamic>.from(
          _injectCompileTimeStructurally(macroDef['defaultProps'], env)
              as Map));
    }
    if (macroDef.containsKey(r'$props') && macroDef[r'$props'] is Map) {
      defaults.addAll(Map<String, dynamic>.from(
          _injectCompileTimeStructurally(macroDef[r'$props'], env) as Map));
    }
    if ((macroDef.containsKey('view') ||
            macroDef.containsKey(r'$view') ||
            macroDef.containsKey('template')) &&
        macroDef['props'] is Map) {
      defaults.addAll(Map<String, dynamic>.from(
          _injectCompileTimeStructurally(macroDef['props'], env) as Map));
    }
    return defaults;
  }

  static Map<String, dynamic> _macroCallerProps(
      Map<String, dynamic> callerNode, Map<String, dynamic> env) {
    if (callerNode['props'] is! Map) return {};
    return Map<String, dynamic>.from(
        _injectCompileTimeStructurally(callerNode['props'], env) as Map);
  }

  static _QLMacroSlots _collectMacroSlots(
      String macroName,
      Map<String, dynamic> callerNode,
      Map<String, dynamic> macroDef,
      Map<String, dynamic> env) {
    final Map<String, dynamic> callerSlots = {};
    final Map<String, dynamic> defaultSlots = {};

    void addSlot(Map<String, dynamic> target, String name, dynamic raw) {
      final dynamic injected = _injectCompileTimeStructurally(raw, env);
      target[name] =
          injected is Map ? injected.cast<String, dynamic>() : injected;
    }

    final vmDefaults = QuantumVM.instance.getDefaultSlotNodes(macroName);
    if (vmDefaults != null) {
      vmDefaults.forEach((k, v) => addSlot(defaultSlots, k.toString(), v));
    }
    final dynamic macroDefaultSlots =
        macroDef['defaultSlots'] ?? macroDef[r'$slots'];
    if (macroDefaultSlots is Map) {
      macroDefaultSlots
          .forEach((k, v) => addSlot(defaultSlots, k.toString(), v));
    }

    if (callerNode['slots'] is Map) {
      (callerNode['slots'] as Map)
          .forEach((k, v) => addSlot(callerSlots, k.toString(), v));
    }

    final List<dynamic> defaultChildren = [];
    if (callerNode['children'] is List) {
      for (final rawChild in callerNode['children'] as List) {
        final Map<String, dynamic> child = _normalizeNode(rawChild);
        final props = child['props'];
        final dynamic slotName = props is Map ? props.remove('slot') : null;
        if (slotName == null) {
          defaultChildren.add(child);
        } else {
          callerSlots[slotName.toString()] = child;
        }
      }
    }
    if (defaultChildren.isNotEmpty && !callerSlots.containsKey('default')) {
      callerSlots['default'] = defaultChildren.length == 1
          ? defaultChildren.first
          : {'type': 'box:col', 'children': defaultChildren};
    }

    return _QLMacroSlots(
      callerSlots: callerSlots,
      defaultSlots: defaultSlots,
    );
  }

  static dynamic _injectMacroSlots(dynamic target, _QLMacroSlots slots) {
    if (target is List) {
      final List<dynamic> output = [];
      for (final item in target) {
        final dynamic injected = _injectMacroSlots(item, slots);
        if (injected is _QLMacroSlotEmpty) continue;
        if (injected is _QLMacroSlotList) {
          output.addAll(injected.children);
        } else {
          output.add(injected);
        }
      }
      return output;
    }

    if (target is! Map) return target;
    final Map<String, dynamic> node = _deepCopy(target);
    final dynamic slotShortcut = node[r'$slot'];
    final String type = node['type']?.toString() ?? '';
    if (slotShortcut != null || type == 'slot') {
      final props = node['props'] is Map ? node['props'] as Map : const {};
      final String slotName =
          (slotShortcut ?? node['name'] ?? props['name'] ?? 'default')
              .toString();
      final dynamic replacement =
          slots.callerSlots[slotName] ?? slots.defaultSlots[slotName];
      if (replacement != null) return _deepCopySlotValue(replacement);

      final dynamic fallback =
          node['fallback'] ?? props['fallback'] ?? node['children'];
      if (fallback is List && fallback.isNotEmpty) {
        return _QLMacroSlotList(
            fallback.map((child) => _injectMacroSlots(child, slots)).toList());
      }
      if (fallback is Map) return _injectMacroSlots(fallback, slots);
      return const _QLMacroSlotEmpty();
    }

    if (node['children'] is List) {
      node['children'] = _injectMacroSlots(node['children'], slots);
    }
    if (node['slots'] is Map) {
      final Map<String, dynamic> nextSlots = {};
      (node['slots'] as Map).forEach((k, v) {
        final dynamic injected = _injectMacroSlots(v, slots);
        if (injected is! _QLMacroSlotEmpty) nextSlots[k.toString()] = injected;
      });
      node['slots'] = nextSlots;
    }
    return node;
  }

  static dynamic _deepCopySlotValue(dynamic value) {
    if (value is Map) return _deepCopy(value);
    if (value is List) return _deepCopyList(value);
    return value;
  }

  static String _injectCompileTime(String target, Map<String, dynamic> env) {
    if (!target.contains('{{')) return target;
    return target.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
      final pathToken = match.group(0)!;
      final val = _getRawCompileTime(pathToken, env);
      return val != null ? val.toString() : pathToken;
    });
  }

  static dynamic _injectCompileTimeStructurally(
      dynamic target, Map<String, dynamic> env) {
    if (target is String &&
        target.startsWith('{{') &&
        target.endsWith('}}') &&
        target.indexOf('{{') == 0 &&
        target.lastIndexOf('}}') == target.length - 2) {
      final raw = _getRawCompileTime(target, env);
      if (raw != null) return raw;
    }
    if (target is String) return _injectCompileTime(target, env);
    if (target is Map) {
      final Map<String, dynamic> safeMap = {};
      target.forEach((k, v) =>
          safeMap[k.toString()] = _injectCompileTimeStructurally(v, env));
      return safeMap;
    }
    if (target is List)
      return target.map((v) => _injectCompileTimeStructurally(v, env)).toList();
    return target;
  }

  static dynamic _getRawCompileTime(
      String pathToken, Map<String, dynamic> env) {
    if (!pathToken.startsWith('{{') || !pathToken.endsWith('}}')) return null;
    final tokenContent = pathToken.substring(2, pathToken.length - 2).trim();
    final pipeParts = tokenContent.split('|').map((s) => s.trim()).toList();
    final path = pipeParts.first;
    final strides = QLPathUtils.resolve(path);

    dynamic current = env;
    int startIndex = 0;
    if (strides.isNotEmpty &&
        (strides.first == 'state' || strides.first == r'$state')) {
      if (!env.containsKey('state') && !env.containsKey(r'$state'))
        startIndex = 1;
    }

    for (int i = startIndex; i < strides.length && current != null; i++) {
      final s = strides[i];
      if (current is Map && current.containsKey(s.toString()))
        current = current[s.toString()];
      else if (current is List && s is int && s >= 0 && s < current.length)
        current = current[s];
      else {
        current = null;
        break;
      }
    }

    if (current != null && pipeParts.length > 1) {
      for (int i = 1; i < pipeParts.length; i++) {
        final match = RegExp(r'^(\w+)(?:\((.*)\))?$').firstMatch(pipeParts[i]);
        if (match != null && QLPipes.registry.containsKey(match.group(1))) {
          final argsRaw = match.group(2);
          final args = argsRaw != null && argsRaw.isNotEmpty
              ? argsRaw
                  .split(',')
                  .map((s) => s.trim().replaceAll("'", "").replaceAll('"', ''))
                  .toList()
              : <String>[];
          current = QLPipes.registry[match.group(1)]!(current, args);
        }
      }
    }
    return current;
  }

  static void _tokenizeNodeProperties(Map target, int depth) {
    if (depth > _maxAstDepth) return;
    for (final k in target.keys.toList()) {
      final v = target[k];
      if (v is String && v.contains('{{')) {
        final parsed = parseTokensAndDeps(v);
        target[k] = {
          "_isTokenized": true,
          "tokens": parsed.tokens,
          "deps": List<dynamic>.from(parsed.deps)
        };
      } else if (v is Map) {
        _tokenizeNodeProperties(v, depth + 1);
      } else if (v is List) {
        for (var i = 0; i < v.length; i++) {
          if (v[i] is Map)
            _tokenizeNodeProperties(v[i] as Map, depth + 1);
          else if (v[i] is String && (v[i] as String).contains('{{')) {
            final parsed = parseTokensAndDeps(v[i] as String);
            v[i] = {
              "_isTokenized": true,
              "tokens": parsed.tokens,
              "deps": List<dynamic>.from(parsed.deps)
            };
          }
        }
      }
    }
  }

  static ParsedToken parseTokensAndDeps(String input) {
    final cached = _tokenCache.get(input);
    if (cached != null) return cached;

    final tokens = [];
    final deps = <String>{};
    int i = 0, lastEnd = 0;

    while (i < input.length - 1) {
      if (input[i] == '{' && input[i + 1] == '{') {
        if (i > lastEnd) tokens.add(input.substring(lastEnd, i));
        i += 2;
        int start = i, braces = 2;
        while (i < input.length && braces > 0) {
          if (input[i] == '}')
            braces--;
          else if (input[i] == '{') braces++;
          i++;
        }
        final tokenContent = input.substring(start, i - 2).trim();
        final pipeParts = tokenContent.split('|').map((s) => s.trim()).toList();
        final path = pipeParts.first;

        String normalizedPath = path;
        if (path.startsWith('state.'))
          normalizedPath = path.substring(6);
        else if (path.startsWith(r'$state.'))
          normalizedPath = path.substring(7);
        deps.add(normalizedPath);

        final pipes = pipeParts.skip(1).map((p) {
          final match = RegExp(r'^(\w+)(?:\((.*)\))?$').firstMatch(p);
          if (match == null) return {'name': p, 'args': <String>[]};
          final argsRaw = match.group(2);
          final args = <String>[];
          if (argsRaw != null && argsRaw.isNotEmpty) {
            int a = 0, j = 0, b = 0;
            while (j < argsRaw.length) {
              if (argsRaw[j] == '{')
                b++;
              else if (argsRaw[j] == '}')
                b--;
              else if (argsRaw[j] == ',' && b == 0) {
                args.add(argsRaw
                    .substring(a, j)
                    .trim()
                    .replaceAll("'", "")
                    .replaceAll('"', ''));
                a = j + 1;
              }
              j++;
            }
            args.add(argsRaw
                .substring(a)
                .trim()
                .replaceAll("'", "")
                .replaceAll('"', ''));
            for (final arg in args) {
              if (arg.startsWith('{{') && arg.endsWith('}}')) {
                String argPath =
                    arg.substring(2, arg.length - 2).split('|').first.trim();
                if (argPath.startsWith('state.'))
                  argPath = argPath.substring(6);
                if (argPath.startsWith(r'$state.'))
                  argPath = argPath.substring(7);
                deps.add(argPath);
              }
            }
          }
          return {'name': match.group(1), 'args': args};
        }).toList();

        tokens.add({"_bind": QLPathUtils.resolve(path), "pipes": pipes});
        lastEnd = i;
      } else {
        i++;
      }
    }
    if (lastEnd < input.length) tokens.add(input.substring(lastEnd));
    return _tokenCache.put(input, ParsedToken(tokens, deps),
        weight: input.length + QLRuntimeCacheSizer.estimate(tokens));
  }

  static void clearCaches() {
    _macroExpansionCache.clear();
    _blueprintCache.clear();
    _tokenCache.clear();
  }

  static Map<String, QLRuntimeCacheStats> cacheStats() => {
        'macros': _macroExpansionCache.stats,
        'blueprints': _blueprintCache.stats,
        'tokens': _tokenCache.stats,
      };
}

class ParsedToken {
  final List<dynamic> tokens;
  final Set<String> deps;
  ParsedToken(this.tokens, this.deps);
}

class _QLMacroSlots {
  final Map<String, dynamic> callerSlots;
  final Map<String, dynamic> defaultSlots;

  const _QLMacroSlots({
    required this.callerSlots,
    required this.defaultSlots,
  });
}

class _QLMacroSlotList {
  final List<dynamic> children;
  const _QLMacroSlotList(this.children);
}

class _QLMacroSlotEmpty {
  const _QLMacroSlotEmpty();
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  QL AST INSPECTOR (O(1) Memoized Reactivity Checks)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
abstract final class QLAstInspector {
  // Cache prevents deep-traversing the same JSON maps repeatedly.
  static final QLRuntimeCache<bool> _cache = QLRuntimeCache(
      config:
          const QLRuntimeCacheConfig(maxEntries: 4096, maxWeight: 512 * 1024));

  static bool isReactive(dynamic target) {
    if (target == null) return false;
    if (target is String) return target.contains('{{');

    if (target is Map) {
      final int hash = QLStableHasher.of(target);
      final bool? cached = _cache.get(hash);
      if (cached != null) return cached;

      bool reactive = false;
      if (target['_isTokenized'] == true ||
          target.containsKey(r'$bind') ||
          target.containsKey('bind') ||
          target.containsKey(r'$if') ||
          target.containsKey(r'$repeat')) {
        reactive = true;
      } else {
        for (final v in target.values) {
          if (isReactive(v)) {
            reactive = true;
            break;
          }
        }
      }
      _cache.put(hash, reactive, weight: 64);
      return reactive;
    }

    if (target is List) {
      for (final v in target) {
        if (isReactive(v)) return true;
      }
    }
    return false;
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  QL PATH RESOLVER (Unified Fast-Path Data Fetching)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
abstract final class QLPathResolver {
  static dynamic read(String rawPath, BuildContext? ctx,
      Map<String, dynamic> env, QLDataStore globalStore) {
    if (rawPath.isEmpty) return null;
    final strides = QLPathUtils.resolve(rawPath);
    if (strides.isEmpty) return null;

    final root = strides.first.toString();
    dynamic current;

    // 1. Resolve Root Scope natively via O(1) checks
    final int char0 = root.codeUnitAt(0);

    if (char0 == 64) {
      // '@' Namespace
      current = QLStoreRegistry.instance
          .get(root.substring(1))
          .get(strides.sublist(1));
    } else if (root == 'state' || root == r'$state') {
      final scope = ctx != null ? QLDataScope.readNode(ctx) : null;
      current = (scope?.localStore ?? scope?.moduleStore ?? globalStore)
          .get(strides.sublist(1));
    } else if (root == r'$env') {
      current = strides.length > 1 ? env[strides[1].toString()] : null;
    } else if (root == r'$local') {
      current = ctx != null
          ? QLDataScope.readNode(ctx)?.localStore?.get(strides.sublist(1))
          : null;
    } else if (root == r'$route') {
      current = env[r'$route'] ??
          (ctx != null
              ? QLDataScope.readNode(ctx)?.localData[r'$route']
              : null);
      for (int i = 1; i < strides.length && current != null; i++) {
        current = (current is Map && strides[i] is String)
            ? current[strides[i]]
            : null;
      }
    } else if (env.containsKey(root)) {
      current = env[root];
      for (int i = 1; i < strides.length && current != null; i++) {
        final key = strides[i];
        if (current is Map && key is String)
          current = current[key];
        else if (current is List && key is int)
          current = current[key];
        else {
          current = null;
          break;
        }
      }
    } else {
      // Global Fallback
      current = globalStore.get(strides);
    }

    return current;
  }
}

abstract final class QLDataBinder {
  static dynamic resolveAOT(dynamic propValue, BuildContext? ctx,
      Map<String, dynamic> env, QLDataStore globalStore) {
    if (propValue is List) {
      return propValue
          .map((v) => resolveAOT(v, ctx, env, globalStore))
          .toList();
    }

    if (propValue is Map) {
      if (propValue['_isTokenized'] == true) {
        final List tokens = propValue['tokens'] as List;
        if (tokens.length == 1 && tokens[0] is Map) {
          return _processToken(tokens[0], ctx, env, globalStore);
        }

        final StringBuffer buffer = StringBuffer();
        for (int i = 0; i < tokens.length; i++) {
          final token = tokens[i];
          buffer.write(token is String
              ? token
              : _processToken(token, ctx, env, globalStore)?.toString() ?? '');
        }
        return buffer.toString();
      } else {
        final Map<String, dynamic> safeMap = {};
        propValue.forEach((k, v) {
          safeMap[k.toString()] = resolveAOT(v, ctx, env, globalStore);
        });
        return safeMap;
      }
    }

    return propValue;
  }

// Inside QLDataBinder
  static dynamic _processToken(Map token, BuildContext? ctx,
      Map<String, dynamic> env, QLDataStore globalStore) {
    // ًںڑ€ SINGLE UNIFIED PATH RESOLUTION
    dynamic val = QLPathResolver.read(
        (token['_bind'] as List).join('.'), ctx, env, globalStore);

    final List? pipes = token['pipes'] as List?;
    if (pipes != null) {
      for (final pipeDef in pipes) {
        final transform = QLPipes.registry[pipeDef['name']];
        if (transform != null) {
          final resolvedArgs = (pipeDef['args'] as List)
              .map((arg) {
                if (arg is String &&
                    arg.startsWith('{{') &&
                    arg.endsWith('}}')) {
                  final innerToken = arg.substring(2, arg.length - 2).trim();
                  return QLPathResolver.read(innerToken, ctx, env, globalStore)
                          ?.toString() ??
                      arg;
                }
                return arg;
              })
              .toList()
              .cast<String>();
          val = transform(val, resolvedArgs);
        }
      }
    }
    return val;
  }
}
