// ════════════════════════════════════════════════════════════════════════════
// QUANTUM VIRTUAL MACHINE (QVM) v11.0 - GOD-MODE OMEGA CORE
// quantum_vm.dart
//
// BREAKTHROUGHS & REFACTORING:
// 1. Data Store / Runtime Caches fully decoupled to quantum_state.dart.
// 2. O(1) AST "Colon Syntax" (Base:Sub) & Alias Registry natively integrated.
// 3. Implicit Behaviors: Eliminates AST nesting overhead by pushing logic into cores.
// 4. Array-based Box Model integration ready via QSimdArena bypasses.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:quantum_layout/quantum.dart';
part 'quantum_vm_components.dart';

class QuantumSecurityException implements Exception {
  final String message;
  const QuantumSecurityException(this.message);
  @override
  String toString() => 'QuantumSecurityException: $message';
}

class QLSchemaSlice {
  final String name;
  final Map<String, dynamic> definition;

  const QLSchemaSlice(this.name, this.definition);
}

class QLLazySchemaView {
  final String id;
  final Map<String, dynamic> _source;
  final QLRuntimeCache<QLSchemaSlice> _cache;

  QLLazySchemaView(this.id, Map<String, dynamic> source,
      {QLRuntimeCache<QLSchemaSlice>? cache})
      : _source = source,
        _cache = cache ?? QuantumVM.instance.schemaSlices;

  QLSchemaSlice? field(String name) {
    final raw = _source[name];
    if (raw is! Map) return null;
    final key = Object.hash(id, name);
    return _cache.getOrPut(key, () {
      return QLSchemaSlice(name, Map<String, dynamic>.unmodifiable(raw));
    });
  }

  Iterable<String> get fieldNames => _source.keys;

  Map<String, dynamic> pick(Iterable<String> names) {
    final out = <String, dynamic>{};
    for (final name in names) {
      final slice = field(name);
      if (slice != null && slice.name.isNotEmpty) {
        out[name] = slice.definition;
      }
    }
    return out;
  }
}

enum QLModuleVisibility { public, local, owner, secure }

class QLModuleAccessPolicy {
  final QLModuleVisibility visibility;
  final Set<String> allowModules;
  final String? ownerId;

  const QLModuleAccessPolicy({
    this.visibility = QLModuleVisibility.public,
    this.allowModules = const {},
    this.ownerId,
  });

  factory QLModuleAccessPolicy.from(dynamic raw) {
    if (raw is! Map) return const QLModuleAccessPolicy();
    final visibility = switch (raw['visibility']?.toString()) {
      'local' => QLModuleVisibility.local,
      'owner' => QLModuleVisibility.owner,
      'secure' => QLModuleVisibility.secure,
      _ => QLModuleVisibility.public,
    };
    return QLModuleAccessPolicy(
      visibility: visibility,
      allowModules: (raw['allow'] as List?)?.map((e) => e.toString()).toSet() ??
          const <String>{},
      ownerId: raw['owner']?.toString() ?? raw['ownerId']?.toString(),
    );
  }

  bool allows({
    required String requester,
    required String target,
    String? ownerId,
  }) {
    if (requester == target) return true;
    if (allowModules.contains(requester) || allowModules.contains('*')) {
      return true;
    }
    return switch (visibility) {
      QLModuleVisibility.public => true,
      QLModuleVisibility.local =>
        _localPrefix(requester) == _localPrefix(target),
      QLModuleVisibility.owner =>
        this.ownerId != null && this.ownerId == ownerId,
      QLModuleVisibility.secure => false,
    };
  }

  static String _localPrefix(String id) {
    final split = id.split(RegExp(r'[:/.]'));
    return split.isEmpty ? id : split.first;
  }
}

class QLModuleRecord {
  final String id;
  final Map<String, dynamic> manifest;
  final QLModuleAccessPolicy access;
  final DateTime registeredAt;
  final int versionHash;

  const QLModuleRecord({
    required this.id,
    required this.manifest,
    required this.access,
    required this.registeredAt,
    required this.versionHash,
  });

  bool get hasRenderableNode =>
      manifest.containsKey('ui') ||
      manifest.containsKey('view') ||
      manifest.containsKey('block') ||
      manifest.containsKey('type') ||
      manifest.containsKey('children');

  dynamic get renderNode =>
      manifest['ui'] ?? manifest['view'] ?? manifest['block'] ?? manifest;
}

class QLModuleRegistry {
  static final QLModuleRegistry instance = QLModuleRegistry._();
  QLModuleRegistry._();

  final Map<String, QLModuleRecord> _modules = {};
  final QLRuntimeCache<dynamic> _sectionCache = QLRuntimeCache<dynamic>(
      config: const QLRuntimeCacheConfig(
          maxEntries: 4096, maxWeight: 4 * 1024 * 1024));

  QLModuleRecord register(Map<String, dynamic> manifest, {String? id}) {
    final moduleId = id ??
        manifest['module']?.toString() ??
        manifest['id']?.toString() ??
        'default';
    final safeManifest = Map<String, dynamic>.unmodifiable(manifest);
    final record = QLModuleRecord(
      id: moduleId,
      manifest: safeManifest,
      access: QLModuleAccessPolicy.from(manifest['access']),
      registeredAt: DateTime.now(),
      versionHash: QLStableHasher.of(safeManifest),
    );
    _modules[moduleId] = record;
    _sectionCache.remove(moduleId);

    final nested = manifest['modules'];
    if (nested is Map) {
      nested.forEach((nestedId, raw) {
        if (raw is Map) {
          register(Map<String, dynamic>.from(raw), id: nestedId.toString());
        }
      });
    } else if (nested is List) {
      for (final raw in nested) {
        if (raw is Map) register(Map<String, dynamic>.from(raw));
      }
    }
    return record;
  }

  bool exists(String id) => _modules.containsKey(id);
  QLModuleRecord? get(String id) => _modules[id];

  QLModuleRecord require(String id) {
    final record = _modules[id];
    if (record == null) {
      throw QuantumSecurityException('Module not registered: $id');
    }
    return record;
  }

  bool canUse(String requester, String target, {String? ownerId}) {
    final record = _modules[target];
    if (record == null) return false;
    return record.access
        .allows(requester: requester, target: target, ownerId: ownerId);
  }

  List<String> importsFor(String moduleId) {
    final record = _modules[moduleId];
    if (record == null) return const [];
    final raw = record.manifest['uses'] ??
        record.manifest['imports'] ??
        record.manifest['dependencies'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  dynamic section(String moduleId, Object path,
      {String requester = 'default', String? ownerId}) {
    if (!canUse(requester, moduleId, ownerId: ownerId)) {
      throw QuantumSecurityException(
          'Module "$requester" cannot access "$moduleId".');
    }
    final record = require(moduleId);
    final key =
        Object.hash(moduleId, requester, path.toString(), record.versionHash);
    return _sectionCache.getOrPut(key, () {
      final strides =
          path is List<dynamic> ? path : QLPathUtils.resolve(path.toString());
      dynamic current = record.manifest;
      for (final stride in strides) {
        if (current is Map) {
          current = current[stride.toString()];
        } else if (current is List && stride is int) {
          current =
              stride >= 0 && stride < current.length ? current[stride] : null;
        } else {
          return null;
        }
      }
      return current;
    });
  }

  Map<String, dynamic> macrosFor(String moduleId, {String? ownerId}) {
    if (!exists(moduleId)) return const <String, dynamic>{};

    final merged = <String, dynamic>{};
    for (final dep in importsFor(moduleId)) {
      if (canUse(moduleId, dep, ownerId: ownerId)) {
        final depMacros = section(dep, 'macros', requester: moduleId);
        if (depMacros is Map)
          merged.addAll(Map<String, dynamic>.from(depMacros));
      }
    }
    final own = section(moduleId, 'macros', requester: moduleId);
    if (own is Map) merged.addAll(Map<String, dynamic>.from(own));
    return merged;
  }

  void clear({String? moduleId}) {
    if (moduleId == null) {
      _modules.clear();
      _sectionCache.clear();
    } else {
      _modules.remove(moduleId);
      _sectionCache.clear();
    }
  }

  QLRuntimeCacheStats get cacheStats => _sectionCache.stats;

  /// Export a snapshot of registered modules and their declared usage.
  Map<String, dynamic> snapshot({String requester = 'default'}) =>
      <String, dynamic>{
        'count': _modules.length,
        'modules': _modules.values
            .map((record) => <String, dynamic>{
                  'id': record.id,
                  'registeredAt': record.registeredAt.toIso8601String(),
                  'versionHash': record.versionHash,
                  'visibility': record.access.visibility.name,
                  'ownerId': record.access.ownerId,
                  'imports': importsFor(record.id),
                  'hasRenderableNode': record.hasRenderableNode,
                  'keys': record.manifest.keys.toList(growable: false),
                  'manifest': record.manifest,
                })
            .toList(growable: false),
      };

  List<String> ids() => _modules.keys.toList(growable: false);
}

class QLRegistryEntry {
  final String id;
  final String kind;
  final String name;
  final String description;
  final String engine;
  final List<String> tags;
  final Map<String, dynamic> params;
  final Map<String, dynamic> metadata;
  final DateTime registeredAt;

  const QLRegistryEntry({
    required this.id,
    required this.kind,
    required this.name,
    required this.description,
    required this.engine,
    required this.tags,
    required this.params,
    required this.metadata,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'kind': kind,
        'name': name,
        'description': description,
        'engine': engine,
        'tags': tags,
        'params': params,
        if (metadata['paramSchema'] != null)
          'paramSchema': metadata['paramSchema'],
        if (metadata['infoSchema'] != null)
          'infoSchema': metadata['infoSchema'],
        'metadata': metadata,
        'registeredAt': registeredAt.toIso8601String(),
      };
}

@immutable
class QuantumExtensionBundle {
  final Map<String, QLPlugin> plugins;
  final Map<String, QLActionPlugin> actions;
  final Map<String, Map<String, dynamic>> aliases;
  final Map<String, Map<String, String>> slotTypes;
  final Map<String, Map<String, dynamic>> slotNodes;
  final Map<String, Map<String, dynamic>> metadata;

  const QuantumExtensionBundle({
    this.plugins = const {},
    this.actions = const {},
    this.aliases = const {},
    this.slotTypes = const {},
    this.slotNodes = const {},
    this.metadata = const {},
  });
}

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
    // ── STRING PIPES ──────────────────────────────────────────────────────────
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
    // ── NUMBER PIPES ──────────────────────────────────────────────────────────
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
    // ── DATE PIPES ────────────────────────────────────────────────────────────
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
    // ── LIST PIPES ────────────────────────────────────────────────────────────
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
    // ── MAP PIPES ─────────────────────────────────────────────────────────────
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
    // ── TYPE / LOGIC PIPES ────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// ZERO-GC SIGNAL BATCHING
// Defers all signal notifications until the batch ends, preventing N rebuilds
// from N consecutive signal.value = ... assignments.
// Usage: QLSignalBatch.run(() { store.set('a', 1); store.set('b', 2); });
// ─────────────────────────────────────────────────────────────────────────────
abstract final class QLSignalBatch {
  static bool _inBatch = false;
  static final List<ChangeNotifier> _pending = [];

  /// Run [fn] inside a batch. All QLSignal/ChangeNotifier notifications queued
  /// inside [fn] are deferred and fired once, in order, when [fn] returns.
  static void run(void Function() fn) {
    _inBatch = true;
    try {
      fn();
    } finally {
      _inBatch = false;
      for (final s in _pending) {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        s.notifyListeners();
      }
      _pending.clear();
    }
  }

  static void enqueue(ChangeNotifier s) {
    if (_inBatch && !_pending.contains(s)) _pending.add(s);
  }

  static bool get isActive => _inBatch;
}

// ─────────────────────────────────────────────────────────────────────────────
// PLUGIN STREAM REGISTRY
// Platform plugins register named Dart Streams here for hook:observable nodes.
// ─────────────────────────────────────────────────────────────────────────────
abstract final class QLPluginStreamRegistry {
  static final Map<String, Stream<dynamic>> _streams = {};
  static void register(String key, Stream<dynamic> s) => _streams[key] = s;
  static Stream<dynamic>? get(String key) => _streams[key];
  static bool has(String key) => _streams.containsKey(key);
  static void unregister(String key) => _streams.remove(key);
  static Iterable<String> get keys => _streams.keys;
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
      
      final actualSubType = subType.isNotEmpty ? subType : (out['props']?['__subType']?.toString() ?? '');

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
            throw const FormatException('Slider defaultValue outside min/max range');
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

    // ── SLOT SHORTHAND: #slotName keys in props → slots map ──────────────────
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

    // ── $try / $catch / $finally → hook:error_boundary ───────────────────────
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

    // ── $async → system:async with loading/data/error slots ──────────────────
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

    // ── $stream → data:stream reactive signal binding ─────────────────────────
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

    // ── $machine → control:machine ────────────────────────────────────────────
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

    // ── $throttle / $debounce → system:throttle/debounce wrapper ─────────────
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

    // ── $portal → portal:overlay_entry transport ──────────────────────────────
    if (node.containsKey(r'$portal')) {
      final portalName = node[r'$portal'].toString();
      final inner = _deepCopy(node)..remove(r'$portal');
      return _processNode({
        'type': 'portal',
        'props': {'__subType': 'overlay_entry', 'portalName': portalName},
        'slots': {'content': inner},
      }, macros, currentEnv, depth + 1, parentPath);
    }

    // ── $reactive_map → data:diff animated list ───────────────────────────────
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

    // ── $compose → behavior chain via behaviors prop ──────────────────────────
    if (node.containsKey(r'$compose')) {
      final behaviors = node[r'$compose'] as List? ?? [];
      final inner = _deepCopy(node)..remove(r'$compose');
      inner['props'] ??= <String, dynamic>{};
      (inner['props'] as Map)['behaviors'] = behaviors.take(8).toList();
      return _processNode(inner, macros, currentEnv, depth + 1, parentPath);
    }

    // ── $watch → mark signal dependency for reactive boundary ────────────────
    if (node.containsKey(r'$watch')) {
      final inner = _deepCopy(node)..remove(r'$watch');
      inner['props'] ??= <String, dynamic>{};
      (inner['props'] as Map)[r'$watch'] = node[r'$watch'].toString();
      return _processNode(inner, macros, currentEnv, depth + 1, parentPath);
    }

    // ── $parallel → fan-out concurrent children ───────────────────────────────
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

// ───────────────────────────────────────────────────────────────────────
//  QL AST INSPECTOR (O(1) Memoized Reactivity Checks)
// ────────────────────────────────────────────────────────────────────────────
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

// ───────────────────────────────────────────────────────────────────────
//  QL PATH RESOLVER (Unified Fast-Path Data Fetching)
// ────────────────────────────────────────────────────────────────────────────
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
      current = (scope?.localStore ?? scope?.moduleStore ?? globalStore).get(strides.sublist(1));
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
    // 🚀 SINGLE UNIFIED PATH RESOLUTION
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

// Note: Apply the exact same QLAstInspector.isReactive check to _MicroSliverPlugin and _MicroLayoutPlugin.
abstract class QLPlugin {
  String get type;
  Map<String, dynamic> get defaultProps => const {};
}

abstract class QLWidgetCapability {
  Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store);
}

abstract class QLSliverCapability {
  Widget buildSliver(BuildContext ctx, QLBlueprint node, QLDataStore store);
}

abstract class QLLayoutCapability {
  Widget buildLayout(BuildContext ctx, QLBlueprint node, List<Widget> children,
      QLDataStore store);
}

abstract class QLGraphicsCapability {
  QLFragmentDraw buildFragment(
      QLContext ctx, QLBlueprint node, QLDataStore store);
}

abstract class QLKineticCapability {
  Widget buildKinetic(QLContext ctx, QLBlueprint node,
      QLAnimCompositor compositor, QLDataStore store);
}

abstract class QLComputeCapability {
  QLWorkerTask<dynamic, dynamic> buildTask(QLContext ctx, QLBlueprint node);
  dynamic buildInput(QLContext ctx, QLBlueprint node);
  void onTaskCompleted(QLContext ctx, dynamic result, QLDataStore store);
}

abstract class QLSandboxCapability {
  Future<dynamic> executeSandboxed(
      String script, Map<String, dynamic> memoryEnv);
}

abstract class QLSensorCapability {
  Widget buildSensor(
      QLContext ctx, QLBlueprint node, Widget child, QLDataStore store);
}

typedef ActionMiddleware = Future<void> Function(
    String action, Map<String, dynamic> payload, Future<void> Function() next);

class QuantumVM {
  static final QuantumVM instance = QuantumVM._();
  QuantumVM._();

  static SessionContext _sessionFromEnv(Map<String, dynamic> env) {
    final dynamic raw = env['session'] ?? env['auth'] ?? env['context'];
    if (raw is SessionContext) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return SessionContext(
        userId: map['userId']?.toString(),
        sessionId: map['sessionId']?.toString(),
        accessToken: map['accessToken']?.toString(),
        refreshToken: map['refreshToken']?.toString(),
        expiresAt: map['expiresAt'] is DateTime
            ? map['expiresAt'] as DateTime
            : DateTime.tryParse(map['expiresAt']?.toString() ?? ''),
        claims: map['claims'] is Map
            ? Map<String, dynamic>.from(map['claims'] as Map)
            : <String, dynamic>{},
        authProviderUsed: map['authProviderUsed']?.toString() ?? 'none',
        deviceId: map['deviceId']?.toString(),
      );
    }
    return const SessionContext(claims: <String, dynamic>{
      'roles': <String>['guest']
    });
  }

  QuantumPermissionDecision _nodePermissionDecision(
    BuildContext ctx,
    QLBlueprint node,
  ) {
    final Map<String, dynamic> env = QLDataScope.of(ctx);
    final dynamic rule = node.props['permission'] ??
        node.props['permissions'] ??
        node.props['guard'] ??
        node.props['visibleIf'] ??
        node.props['policy'];
    if (rule == null) {
      return const QuantumPermissionDecision.allow('no node rule');
    }
    return QuantumPermissionEngine.instance.evaluate(
      rule,
      QuantumPermissionContext.fromSession(
        _sessionFromEnv(env),
        env: <String, dynamic>{...env, 'node': node.toJson()},
        data: node.props,
        scope: 'sdui',
        resource: node.type,
        operation: 'render',
        feature: node.props['feature']?.toString(),
        schema: node.props['schema']?.toString(),
      ),
      meta: <String, dynamic>{'path': node.debugPath},
    );
  }

  final Map<String, int> _actionGenerations = {};
  int _globalActionDepth = 0;
  final Map<String, Map<String, dynamic>> _defaultSlotNodes = {};
  void registerDefaultSlotNodes(String alias, Map<String, dynamic> slots) {
    _defaultSlotNodes[alias] = slots;
    _registryEntries['slotnodes:$alias'] = QLRegistryEntry(
      id: 'slotnodes:$alias',
      kind: 'slotnodes',
      name: alias,
      description: 'Default slot nodes for $alias',
      engine: 'QuantumVM',
      tags: const ['slots', 'layout'],
      params: const {},
      metadata: {'slots': slots},
      registeredAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? getDefaultSlotNodes(String alias) =>
      _defaultSlotNodes[alias];

  QuantumDesignSystemBundle installDesignSystemManifest(
    Map<String, dynamic> manifest, {
    String? manifestId,
    bool overwrite = true,
  }) {
    final bundle = QuantumDesignSystemCompiler.compile(
      manifest,
      manifestId: manifestId,
    );
    if (!overwrite && _designSystems.containsKey(bundle.id)) {
      return _designSystems[bundle.id]!;
    }

    _designSystems[bundle.id] = bundle;
    _localManifests.put(bundle.id, Map<String, dynamic>.from(bundle.manifest),
        weight: QLRuntimeCacheSizer.estimate(bundle.manifest));

    bundle.aliases.forEach((alias, payload) {
      if (!overwrite && hasAlias(alias)) return;
      final targetType =
          payload['target']?.toString() ?? payload['type']?.toString() ?? '';
      if (targetType.isEmpty) return;
      defineAlias(
        alias,
        targetType,
        defaultProps: payload['props'] is Map
            ? Map<String, dynamic>.from(payload['props'] as Map)
            : const <String, dynamic>{},
        description: payload['description']?.toString(),
        metadata: payload['metadata'] is Map
            ? Map<String, dynamic>.from(payload['metadata'] as Map)
            : const <String, dynamic>{},
        tags: _asStringList(payload['tags']),
      );
    });

    bundle.slotTypes.forEach((name, payload) {
      if (!overwrite && getSlotTypes(name) != null) return;
      registerSlotTypes(
        name,
        Map<String, String>.fromEntries(
          payload.entries.map(
            (entry) => MapEntry(entry.key.toString(), entry.value.toString()),
          ),
        ),
      );
    });

    bundle.slotNodes.forEach((name, payload) {
      if (!overwrite && getDefaultSlotNodes(name) != null) return;
      registerDefaultSlotNodes(name, Map<String, dynamic>.from(payload));
    });

    bundle.templates.forEach((name, payload) {
      if (!overwrite && QJsonTemplateEngine_D.lookup(name) != null) return;
      final Map<String, dynamic> def = Map<String, dynamic>.from(payload);
      def.putIfAbsent('name', () => name);
      QJsonTemplateEngine_D.define(def);
    });

    bundle.layouts.forEach((name, payload) {
      if (!overwrite && QMatrixLayoutRegistry.has(name)) return;
      final Map<String, dynamic> def = Map<String, dynamic>.from(payload);
      def.putIfAbsent('name', () => name);
      defineMatrixLayoutJson(def);
    });

    void registerSectionEntries(
      String kind,
      Map<String, Map<String, dynamic>> section,
    ) {
      for (final entry in section.entries) {
        final sectionName = entry.key;
        _registryEntries['design_system:${bundle.id}:$kind:$sectionName'] =
            QLRegistryEntry(
          id: 'design_system:${bundle.id}:$kind:$sectionName',
          kind: kind,
          name: sectionName,
          description: entry.value['description']?.toString() ??
              '$kind $sectionName from ${bundle.id}',
          engine: 'QuantumDesignSystemCompiler',
          tags: ['design_system', 'manifest', kind],
          params: Map<String, dynamic>.from(entry.value),
          metadata: {
            'designSystem': bundle.id,
            'section': kind,
            'name': sectionName,
          },
          registeredAt: DateTime.now(),
        );
      }
    }

    for (final entry in bundle.components.entries) {
      final name = entry.key;
      final raw = Map<String, dynamic>.from(entry.value);
      raw.putIfAbsent('name', () => name);
      final compiled = _compileDefinitionFromRaw(
        raw,
        debugPath: 'design_system:${bundle.id}:component:$name',
        fallbackName: name,
        sourceNode: QLBlueprint(
          type: 'component',
          props: const <String, dynamic>{},
          children: const <QLBlueprint>[],
          debugPath: 'design_system:${bundle.id}:component:$name',
        ),
      );
      _registerComponentDefinition(compiled);
    }
    registerSectionEntries('native_component', bundle.components);
    registerSectionEntries('template', bundle.templates);
    registerSectionEntries('layout', bundle.layouts);
    registerSectionEntries('action', bundle.actions);
    registerSectionEntries('behavior', bundle.behaviors);
    registerSectionEntries('workflow', bundle.workflows);
    registerSectionEntries('state_machine', bundle.stateMachines);
    registerSectionEntries('route', bundle.routes);
    registerSectionEntries('pack', bundle.packs);

    // Re-install structured schemas using the registry's own compiler when the
    // manifest provides raw schema maps. This keeps schema metadata visible in
    // the catalog without hard-coding any special-case widgets.
    if (bundle.coreSchemas.isNotEmpty || bundle.aliasSchemas.isNotEmpty) {
      QuantumCoreSchemaRegistry.instance.installDefaults(
        coreSchemas: bundle.coreSchemas,
        aliasSchemas: bundle.aliasSchemas,
      );
    }

    _registryEntries['design_system:${bundle.id}'] = QLRegistryEntry(
      id: 'design_system:${bundle.id}',
      kind: 'design_system',
      name: bundle.id,
      description:
          bundle.metadata['description']?.toString() ?? 'Design system bundle',
      engine: 'QuantumDesignSystemCompiler',
      tags: const ['design_system', 'manifest'],
      params: {
        'fingerprint': bundle.fingerprint,
        'sections': bundle.sectionCount,
        'tokens': bundle.tokens.keys.toList(growable: false),
      },
      metadata: bundle.toMap(),
      registeredAt: DateTime.now(),
    );

    return bundle;
  }

  QuantumDesignSystemBundle? getDesignSystemManifest(String id) =>
      _designSystems[id];

  Map<String, QuantumDesignSystemBundle> designSystemSnapshot() =>
      Map<String, QuantumDesignSystemBundle>.unmodifiable(_designSystems);

  List<String> designSystemIds() =>
      List<String>.unmodifiable(_designSystems.keys);

  Map<String, dynamic>? describeDesignSystem(String id) {
    final bundle = _designSystems[id];
    return bundle?.toMap();
  }

  // 🚀 ALIAS REGISTRY
  final Map<String, Map<String, dynamic>> _aliases = {};

  static Map<String, dynamic> _cloneMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.fromEntries(
        raw.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
      );
    }
    return <String, dynamic>{};
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    if (raw is String && raw.isNotEmpty) return <String>[raw];
    return const <String>[];
  }

  static Map<String, dynamic> _schemaForValue(dynamic value) {
    if (value == null) {
      return const <String, dynamic>{'type': 'dynamic', 'nullable': true};
    }
    if (value is bool) {
      return const <String, dynamic>{'type': 'bool'};
    }
    if (value is int) {
      return const <String, dynamic>{'type': 'int'};
    }
    if (value is double) {
      return const <String, dynamic>{'type': 'double'};
    }
    if (value is String) {
      return <String, dynamic>{'type': 'String', 'example': value};
    }
    if (value is List) {
      return <String, dynamic>{
        'type': 'List<dynamic>',
        'items': value.isEmpty
            ? const <String, dynamic>{'type': 'dynamic'}
            : _schemaForValue(value.first),
      };
    }
    if (value is Map) {
      return <String, dynamic>{
        'type': 'Map<String, dynamic>',
        'properties': _schemaForMap(_cloneMap(value)),
      };
    }
    return <String, dynamic>{'type': value.runtimeType.toString()};
  }

  static Map<String, dynamic> _schemaForMap(Map<String, dynamic> map) {
    return <String, dynamic>{
      'type': 'object',
      'properties': {
        for (final entry in map.entries)
          entry.key: _schemaForValue(entry.value),
      },
      'required': map.keys.toList(growable: false),
    };
  }

  static String _humanizeTarget(String targetType) {
    final parts = targetType.split(':');
    return parts.isEmpty ? targetType : parts.last;
  }

  static const Map<String, List<String>> _omniCoreSubtypes =
      <String, List<String>>{
    'action': <String>[
      'double_tap',
      'focus',
      'gesture',
      'hover',
      'link',
      'long_press',
      'pointer',
      'press',
      'raw_pointer',
      'tap',
      'viewport'
    ],
    'box': <String>[
      'aspect',
      'builder',
      'col',
      'expanded',
      'flexible',
      'grid',
      'layer',
      'masonry',
      'matrix',
      'measure',
      'morph',
      'responsive',
      'row',
      'safe',
      'scroll',
      'shell',
      'split',
      'stack',
      'sticky',
      'surface',
      'viewport',
      'virtual_grid',
      'wrap'
    ],
    'canvas': <String>['draw', 'plot', 'shader', 'shape'],
    'chart': <String>[
      'line',
      'bar',
      'area',
      'pie',
      'donut',
      'radar',
      'scatter',
      'bubble',
      'candlestick',
      'funnel',
      'waterfall',
      'histogram',
      'gauge',
      'sparkline',
      'treemap',
      'sankey'
    ],
    'collab': <String>['awareness', 'cursor', 'lock', 'patch', 'presence'],
    'control': <String>[
      'accordion',
      'architecture',
      'flow',
      'form_scope',
      'machine',
      'optimistic',
      'reducer',
      'saga',
      'stepper',
      'tabs',
      'tca'
    ],
    'data': <String>[
      'aggregate',
      'cursor',
      'diff',
      'grid',
      'infinite',
      'kanban',
      'masonry',
      'paginated',
      'realtime',
      'repeat',
      'slice',
      'sliver',
      'sliver_plane',
      'stream',
      'table',
      'timeline',
      'virtual_scroll'
    ],
    'decoration': <String>[
      'badge',
      'blur',
      'border',
      'gradient',
      'rich',
      'ripple',
      'shadow',
      'skeleton',
      'span',
      'text'
    ],
    'field': <String>[
      'cell',
      'checkbox',
      'email',
      'multiline',
      'number',
      'password',
      'radio',
      'rich_text',
      'search',
      'slider',
      'tel',
      'text',
      'textarea',
      'toggle',
      'url'
    ],
    'hook': <String>[
      'atom',
      'bridge',
      'change',
      'delegate',
      'effect',
      'error_boundary',
      'guard',
      'interval',
      'lifecycle',
      'memo',
      'mount',
      'observable',
      'ref',
      'scope',
      'slice',
      'store'
    ],
    'media': <String>[
      'audio',
      'audio_visualizer',
      'avatar',
      'camera',
      'canvas_video',
      'icon',
      'path',
      'stream',
      'svg_path',
      'video',
      'webrtc'
    ],
    'portal': <String>[
      'action_sheet',
      'alert',
      'anchored_floating',
      'centered',
      'confirm',
      'context_menu',
      'context_panel',
      'dialog',
      'docked',
      'drawer',
      'dropdown',
      'edge_attached',
      'expandable_inline',
      'flyout',
      'form_modal',
      'full_page_sheet',
      'full_screen',
      'full_screen_surface',
      'immersive_editor',
      'inline_details',
      'inline_editor',
      'inspector',
      'lightbox',
      'left_panel',
      'menu',
      'mobile_sheet',
      'modal',
      'navigation_rail',
      'nonModal',
      'non_modal',
      'overlay',
      'overlay_entry',
      'persistent_drawer',
      'persistent_panel',
      'popover',
      'popup_modal',
      'right_panel',
      'sheet',
      'sidebar',
      'side_sheet',
      'toast',
      'temporary_overlay',
      'tooltip',
      'utility_panel',
      'window'
    ],
    'stream': <String>['multiplex', 'ring', 'sse', 'tick', 'ws'],
    'template': <String>[],
    'layout': <String>[],
    'component': <String>[
      'define',
      'use',
      'instance',
      'render',
      'scoped',
      'link'
    ],
    'system': <String>[
      'async',
      'clipboard',
      'data_pipe',
      'debounce',
      'download',
      'geo',
      'haptic',
      'kinetic_pipe',
      'macro',
      'notification',
      'omega_macro',
      'repeater',
      'sensor',
      'share',
      'store_provider',
      'sync_scroll',
      'throttle',
      'ticker',
      'timer',
      'upload',
      'worker'
    ],
    'text': <String>['code', 'h1', 'h2', 'h3', 'label', 'rich'],
    'visual': <String>[
      'action',
      'animation',
      'box',
      'canvas',
      'chart',
      'compose',
      'connect',
      'control',
      'data',
      'decoration',
      'delegate',
      'field',
      'layer',
      'layout',
      'media',
      'overlay',
      'portal',
      'scene',
      'shell',
      'stack',
      'surface',
      'system',
      'template',
      'text'
    ],
  };

  static Map<String, dynamic> _coreParamSchema(String type) {
    final subtypes = _omniCoreSubtypes[type] ?? const <String>[];
    return <String, dynamic>{
      'type': 'object',
      'properties': {
        '__subType': {'type': 'String', 'enum': subtypes},
        'style': {'type': 'String'},
        'props': {'type': 'Map<String, dynamic>'},
        'slots': {'type': 'Map<String, dynamic>'},
        'children': {'type': 'List<dynamic>'},
        'metadata': {'type': 'Map<String, dynamic>'},
        'actions': {'type': 'List<dynamic>'},
        'tags': {'type': 'List<dynamic>'},
      },
      'required': const <String>[],
      'subtypes': subtypes,
    };
  }

  static Map<String, dynamic> _coreInfoSchema({
    required String type,
    required String description,
    required List<String> tags,
    required String engine,
  }) {
    final subtypes = _omniCoreSubtypes[type] ?? const <String>[];
    return <String, dynamic>{
      'name': type,
      'kind': 'core',
      'description': description,
      'engine': engine,
      'tags': List<String>.unmodifiable(tags),
      'subtypes': subtypes,
      'subtypeCount': subtypes.length,
    };
  }

  static final Map<String, Map<String, String>> _omniCoreFeaturePropTypes =
      <String, Map<String, String>>{
    'action': <String, String>{
      'bindPressure': 'String',
      'bindState': 'String',
      'bindX': 'String',
      'bindY': 'String',
      'disabled': 'bool',
      'href': 'String',
      'icon': 'Widget',
      'loading': 'bool',
      'margin': 'List<dynamic>',
      'matrixBind': 'String',
      'onBlur': 'VoidCallback',
      'onClick': 'VoidCallback',
      'onDoubleTap': 'VoidCallback',
      'onEnter': 'VoidCallback',
      'onFocus': 'VoidCallback',
      'onHover': 'VoidCallback',
      'onKeyPress': 'VoidCallback',
      'onLongPress': 'VoidCallback',
      'onNavigate': 'VoidCallback',
      'onPan': 'VoidCallback',
      'onRelease': 'VoidCallback',
      'onScale': 'VoidCallback',
      'onTap': 'VoidCallback',
      'onUnhover': 'VoidCallback',
      'padding': 'List<dynamic>',
      'text': 'String',
      'value': 'String',
    },
    'animation': <String, String>{
      'animationType': 'String',
      'bind': 'String',
      'blur': 'double',
      'child': 'Widget',
      'color': 'Color',
      'count': 'int',
      'decimals': 'int',
      'delayMs': 'int',
      'durationMs': 'int',
      'first': 'Widget',
      'from': 'double',
      'fromX': 'double',
      'fromY': 'double',
      'height': 'double',
      'key': 'String',
      'radius': 'double',
      'second': 'Widget',
      'showFirst': 'bool',
      'steps': 'List<dynamic>',
      'tint': 'Color',
      'to': 'double',
      'toX': 'double',
      'toY': 'double',
      'width': 'double',
    },
    'box': <String, String>{
      'absorbPointer': 'bool',
      'animate': 'bool',
      'aspectBox': 'bool',
      'bind': 'String',
      'bottom': 'bool',
      'clip': 'bool',
      'clipKind': 'String',
      'cols': 'String',
      'constrained': 'bool',
      'curve': 'String',
      'dense': 'bool',
      'direction': 'String',
      'disabled': 'bool',
      'dragAxis': 'String',
      'dragData': 'String',
      'dragOpacity': 'double',
      'draggable': 'bool',
      'durationMs': 'int',
      'expand': 'bool',
      'fill': 'String',
      'flex': 'int',
      'floating': 'bool',
      'fractional': 'bool',
      'fractions': 'List<dynamic>',
      'gap': 'double',
      'gridCols': 'String',
      'gridRows': 'String',
      'height': 'double',
      'heightFactor': 'double',
      'heroFlight': 'bool',
      'heroTag': 'String',
      'hideOnDrag': 'bool',
      'id': 'dynamic',
      'ignorePointer': 'bool',
      'items': 'String',
      'justify': 'String',
      'left': 'bool',
      'lockAspect': 'bool',
      'longPressDraggable': 'bool',
      'margin': 'List<dynamic>',
      'matrix': 'String',
      'matrixBind': 'String',
      'maxHeight': 'double',
      'maxWidth': 'double',
      'minHeight': 'double',
      'minWidth': 'double',
      'offstage': 'bool',
      'onClick': 'VoidCallback',
      'opacity': 'double',
      'opacityBind': 'String',
      'padding': 'List<dynamic>',
      'pinned': 'bool',
      'ratio': 'double',
      'repaintBoundary': 'bool',
      'resize': 'bool',
      'right': 'bool',
      'rotate': 'bool',
      'rotateTurns': 'double',
      'rows': 'String',
      'scale': 'String',
      'scrollable': 'bool',
      'semanticLabel': 'String',
      'semantics': 'bool',
      'snapGrid': 'double',
      'style': 'String',
      'top': 'bool',
      'transform': 'bool',
      'transformBind': 'String',
      'transition': 'String',
      'variant': 'String',
      'width': 'double',
      'widthFactor': 'double',
    },
    'canvas': <String, String>{
      'baseline': 'String',
      'bind': 'String',
      'color': 'Color',
      'commands': 'List<dynamic>',
      'fillColor': 'Color',
      'gapX': 'double',
      'mode': 'String',
      'scaleY': 'double',
      'shapeDef': 'Map<String, dynamic>',
      'src': 'String',
      'stepX': 'double',
      'thickness': 'double',
      'uniformBind': 'String',
    },
    'collab': <String, String>{
      'as': 'String',
      'key': 'String',
      'patch': 'Map<String, dynamic>',
      'resource': 'String',
      'room': 'String',
      'store': 'String',
      'userId': 'String',
    },
    'component': <String, String>{
      'animations': 'dynamic',
      'batch': 'dynamic',
      'cache': 'dynamic',
      'capabilities': 'dynamic',
      'component': 'dynamic',
      'computed': 'dynamic',
      'cursor': 'dynamic',
      'definition': 'dynamic',
      'description': 'String',
      'features': 'dynamic',
      'fields': 'dynamic',
      'guard': 'dynamic',
      'hooks': 'dynamic',
      'links': 'dynamic',
      'media': 'dynamic',
      'name': 'String',
      'network': 'dynamic',
      'omni': 'dynamic',
      'pagination': 'dynamic',
      'payload': 'dynamic',
      'permissions': 'dynamic',
      'policies': 'dynamic',
      'policy': 'dynamic',
      'presentation': 'dynamic',
      'preview': 'bool',
      'projection': 'dynamic',
      'props': 'dynamic',
      'render': 'bool',
      'resource': 'dynamic',
      'resources': 'dynamic',
      'runtime': 'dynamic',
      'select': 'dynamic',
      'slots': 'dynamic',
      'spec': 'dynamic',
      'state': 'dynamic',
      'stream': 'dynamic',
      'ui': 'dynamic',
      'variants': 'dynamic',
    },
    'connect': <String, String>{
      'activeRole': 'String',
      'altThreshold': 'double',
      'cancelThreshold': 'double',
      'channel': 'String',
      'contract': 'String',
      'fallback': 'String',
      'focusChannel': 'String',
      'heroTag': 'String',
      'longPressReveal': 'bool',
      'onAlt': 'VoidCallback',
      'onBack': 'VoidCallback',
      'onCancel': 'VoidCallback',
      'onClose': 'VoidCallback',
      'onCommit': 'VoidCallback',
      'onDismissed': 'VoidCallback',
      'onRefresh': 'VoidCallback',
      'phaseChannel': 'String',
      'roleNames': 'List<dynamic>',
      'scale': 'double',
      'text': 'String',
    },
    'control': <String, String>{
      'action': 'String',
      'actions': 'Map<String, dynamic>',
      'context': 'Map<String, dynamic>',
      'disposeFlowState': 'bool',
      'heroKey': 'String',
      'id': 'String',
      'initial': 'String',
      'initialIndex': 'int',
      'initialState': 'Map<String, dynamic>',
      'namespace': 'String',
      'optimisticData': 'Map<String, dynamic>',
      'rollbackOn': 'String',
      'routeKey': 'String',
      'selectionKey': 'String',
      'stateKey': 'String',
      'states': 'Map<String, dynamic>',
      'steps': 'List<dynamic>',
    },
    'data': <String, String>{
      'action': 'String',
      'as': 'String',
      'bind': 'String',
      'channel': 'String',
      'cols': 'String',
      'cursorKey': 'String',
      'direction': 'String',
      'empty': 'Widget',
      'gap': 'double',
      'header': 'Widget',
      'indexAs': 'String',
      'itemHeight': 'double',
      'key': 'String',
      'limit': 'int',
      'onEndReached': 'VoidCallback',
      'onReorder': 'VoidCallback',
      'pageSize': 'int',
      'pipeline': 'String',
      'searchBind': 'String',
      'sources': 'List<dynamic>',
      'start': 'int',
    },
    'decoration': <String, String>{
      'absorbPointer': 'bool',
      'beginColor': 'Color',
      'blur': 'double',
      'clip': 'bool',
      'color': 'Color',
      'endColor': 'Color',
      'fontSize': 'double',
      'height': 'double',
      'highlightColor': 'Color',
      'ignorePointer': 'bool',
      'label': 'String',
      'mergeStyle': 'String',
      'onDoubleTap': 'VoidCallback',
      'onHover': 'VoidCallback',
      'onLongPress': 'VoidCallback',
      'onTap': 'VoidCallback',
      'radius': 'double',
      'right': 'double',
      'sigma': 'double',
      'splashColor': 'Color',
      'spread': 'double',
      'style': 'String',
      'suppressParentData': 'bool',
      'textColor': 'Color',
      'tintColor': 'Color',
      'top': 'double',
      'width': 'double',
      'x': 'double',
      'y': 'double',
    },
    'field': <String, String>{
      'bind': 'String',
      'decimal': 'bool',
      'disabled': 'bool',
      'divisions': 'int',
      'id': 'String',
      'initialValue': 'bool',
      'label': 'String',
      'max': 'double',
      'maxLines': 'int',
      'min': 'double',
      'minLines': 'int',
      'placeholder': 'String',
      'prefix': 'Widget',
      'radius': 'double',
      'readOnly': 'bool',
      'suffix': 'Widget',
    },
    'hook': <String, String>{
      'action': 'dynamic',
      'as': 'String',
      'bind': 'String',
      'bridge': 'Map<String, dynamic>',
      'catch': 'Widget',
      'delegateProps': 'Map<String, dynamic>',
      'deps': 'List<dynamic>',
      'enabled': 'bool',
      'fallback': 'Widget',
      'finally': 'Widget',
      'id': 'String',
      'initial': 'dynamic',
      'initialState': 'Map<String, dynamic>',
      'key': 'String',
      'locals': 'dynamic',
      'memo': 'dynamic',
      'memoKey': 'dynamic',
      'ms': 'int',
      'onEffect': 'VoidCallback',
      'onMount': 'VoidCallback',
      'onUnmount': 'VoidCallback',
      'path': 'String',
      'payload': 'dynamic',
      'runOnMount': 'bool',
      'scope': 'Map<String, dynamic>',
      'store': 'String',
      'stream': 'String',
      'target': 'String',
      'try': 'Widget',
      'value': 'dynamic',
    },
    'layout': <String, String>{
      'align': 'String',
      'id': 'String',
      'layoutId': 'String',
      'match': 'String',
      'selectable': 'bool',
      'selectedStyle': 'String',
      'style': 'String',
      'text': 'String',
      'value': 'String',
    },
    'media': <String, String>{
      'allowBatch': 'bool',
      'audioUrl': 'String',
      'autoPlay': 'bool',
      'bind': 'String',
      'blurIntensity': 'double',
      'codePoint': 'int',
      'color': 'Color',
      'count': 'int',
      'error': 'Widget',
      'fill': 'Color',
      'fit': 'String',
      'fontFamily': 'String',
      'height': 'double',
      'id': 'String',
      'loop': 'bool',
      'mode': 'String',
      'path': 'String',
      'placeholder': 'Widget',
      'placeholderBase64': 'String',
      'poster': 'String',
      'progressive': 'bool',
      'quality': 'int',
      'roomId': 'String',
      'showSubtitles': 'bool',
      'size': 'double',
      'src': 'String',
      'stroke': 'Color',
      'strokeWidth': 'double',
      'subtitleOffsetMs': 'int',
      'subtitleUrl': 'String',
      'url': 'String',
      'width': 'double',
    },
    'portal': <String, String>{
      'align': 'String',
      'allowResize': 'bool',
      'barrierColor': 'Color',
      'barrierDismissible': 'bool',
      'barrierOpacity': 'double',
      'bgBlurSigma': 'double',
      'bgEffect': 'String',
      'bgZoomDepth': 'double',
      'clipSheet': 'bool',
      'content': 'Widget',
      'cornerRadius': 'double',
      'durationMs': 'double',
      'edge': 'String',
      'enableDrag': 'bool',
      'extrude3D': 'bool',
      'h': 'double',
      'isModal': 'bool',
      'matchAnchorWidth': 'bool',
      'resizeEdges': 'String',
      'rootBgColor': 'Color',
      'sheetAlignment': 'String',
      'sheetPadding': 'double',
      'sheetPaddingBottom': 'double',
      'sheetPaddingLeft': 'double',
      'sheetPaddingRight': 'double',
      'sheetPaddingTop': 'double',
      'showDragHandle': 'bool',
      'trigger': 'Widget',
      'triggerBind': 'String',
      'w': 'double',
      'x': 'double',
      'y': 'double',
    },
    'stream': <String, String>{
      'as': 'String',
      'bind': 'String',
      'capacity': 'int',
      'channels': 'List<dynamic>',
      'ms': 'int',
      'statusKey': 'String',
      'url': 'String',
    },
    'system': <String, String>{
      'action': 'String',
      'as': 'String',
      'autoStart': 'bool',
      'axis': 'String',
      'bind': 'String',
      'bindOutput': 'String',
      'bindSource': 'String',
      'bindX': 'String',
      'bindY': 'String',
      'copy': 'String',
      'damping': 'double',
      'direction': 'String',
      'indexAs': 'String',
      'initialState': 'Map<String, dynamic>',
      'interval': 'int',
      'mode': 'String',
      'ms': 'int',
      'onTick': 'VoidCallback',
      'outputBind': 'String',
      'params': 'Map<String, dynamic>',
      'pipeline': 'String',
      'props': 'Map<String, dynamic>',
      'size': 'int',
      'stiffness': 'double',
      'task': 'String',
      'template': 'Map<String, dynamic>',
      'type': 'String',
    },
    'template': <String, String>{
      'activeFill': 'String',
      'avatars': 'List<dynamic>',
      'backText': 'String',
      'bind': 'String',
      'categories': 'List<dynamic>',
      'cells': 'List<dynamic>',
      'children': 'List<dynamic>',
      'columns': 'List<dynamic>',
      'doneText': 'String',
      'dragData': 'String',
      'entries': 'List<dynamic>',
      'heroId': 'String',
      'index': 'int',
      'initialIndex': 'int',
      'intent': 'String',
      'itemScale': 'String',
      'itemStyle': 'String',
      'items': 'List<dynamic>',
      'label': 'String',
      'level': 'int',
      'magneto': 'bool',
      'magnetoIntensity': 'double',
      'maxVisible': 'int',
      'multiple': 'bool',
      'nextText': 'String',
      'onDone': 'List<dynamic>',
      'onDrop': 'VoidCallback',
      'onSelect': 'List<dynamic>',
      'onToggle': 'List<dynamic>',
      'prevText': 'String',
      'rows': 'List<dynamic>',
      'selected': 'bool',
      'steps': 'List<dynamic>',
      'subtitle': 'String',
    },
    'text': <String, String>{
      'maxLines': 'int',
      'overflow': 'String',
      'selectable': 'bool',
      'softWrap': 'bool',
      'style': 'String',
      'text': 'String',
      'value': 'String',
    },
    'visual': <String, String>{
      'animationType': 'String',
      'body': 'Widget',
      'boxType': 'String',
      'canvasType': 'dynamic',
      'chartType': 'String',
      'child': 'Widget',
      'chrome': 'Widget',
      'clip': 'bool',
      'connectType': 'dynamic',
      'content': 'Widget',
      'delegateProps': 'Map<String, dynamic>',
      'fieldType': 'String',
      'footer': 'Widget',
      'header': 'Widget',
      'isComplex': 'bool',
      'layout': 'String',
      'mediaType': 'String',
      'overlay': 'Widget',
      'portalType': 'dynamic',
      'systemType': 'String',
      'target': 'String',
      'templateName': 'dynamic',
      'willChange': 'bool',
    },
  };

  static final Map<String, Map<String, dynamic>> _omniCoreFeatureCatalog =
      <String, Map<String, dynamic>>{
    'action': <String, dynamic>{
      'sourceFile': 'omni_cores/action_core.dart',
      'aliasCount': 10,
      'defineCount': 0,
      'propCount': 27,
      'featureProps': <String>[
        'bindPressure',
        'bindState',
        'bindX',
        'bindY',
        'disabled',
        'href',
        'icon',
        'loading',
        'margin',
        'matrixBind',
        'onBlur',
        'onClick',
        'onDoubleTap',
        'onEnter',
        'onFocus',
        'onHover',
        'onKeyPress',
        'onLongPress',
        'onNavigate',
        'onPan',
        'onRelease',
        'onScale',
        'onTap',
        'onUnhover',
        'padding',
        'text',
        'value',
      ],
      'propTypes': <String, String>{
        'bindPressure': 'String',
        'bindState': 'String',
        'bindX': 'String',
        'bindY': 'String',
        'disabled': 'bool',
        'href': 'String',
        'icon': 'Widget',
        'loading': 'bool',
        'margin': 'List<dynamic>',
        'matrixBind': 'String',
        'onBlur': 'VoidCallback',
        'onClick': 'VoidCallback',
        'onDoubleTap': 'VoidCallback',
        'onEnter': 'VoidCallback',
        'onFocus': 'VoidCallback',
        'onHover': 'VoidCallback',
        'onKeyPress': 'VoidCallback',
        'onLongPress': 'VoidCallback',
        'onNavigate': 'VoidCallback',
        'onPan': 'VoidCallback',
        'onRelease': 'VoidCallback',
        'onScale': 'VoidCallback',
        'onTap': 'VoidCallback',
        'onUnhover': 'VoidCallback',
        'padding': 'List<dynamic>',
        'text': 'String',
        'value': 'String',
      },
    },
    'animation': <String, dynamic>{
      'sourceFile': 'omni_cores/animation_core.dart',
      'aliasCount': 14,
      'defineCount': 0,
      'propCount': 24,
      'featureProps': <String>[
        'animationType',
        'bind',
        'blur',
        'child',
        'color',
        'count',
        'decimals',
        'delayMs',
        'durationMs',
        'first',
        'from',
        'fromX',
        'fromY',
        'height',
        'key',
        'radius',
        'second',
        'showFirst',
        'steps',
        'tint',
        'to',
        'toX',
        'toY',
        'width',
      ],
      'propTypes': <String, String>{
        'animationType': 'String',
        'bind': 'String',
        'blur': 'double',
        'child': 'Widget',
        'color': 'Color',
        'count': 'int',
        'decimals': 'int',
        'delayMs': 'int',
        'durationMs': 'int',
        'first': 'Widget',
        'from': 'double',
        'fromX': 'double',
        'fromY': 'double',
        'height': 'double',
        'key': 'String',
        'radius': 'double',
        'second': 'Widget',
        'showFirst': 'bool',
        'steps': 'List<dynamic>',
        'tint': 'Color',
        'to': 'double',
        'toX': 'double',
        'toY': 'double',
        'width': 'double',
      },
    },
    'box': <String, dynamic>{
      'sourceFile': 'omni_cores/box_core.dart',
      'aliasCount': 17,
      'defineCount': 0,
      'propCount': 72,
      'featureProps': <String>[
        'absorbPointer',
        'animate',
        'aspectBox',
        'bind',
        'bottom',
        'clip',
        'clipKind',
        'cols',
        'constrained',
        'curve',
        'dense',
        'direction',
        'disabled',
        'dragAxis',
        'dragData',
        'dragOpacity',
        'draggable',
        'durationMs',
        'expand',
        'fill',
        'flex',
        'floating',
        'fractional',
        'fractions',
        'gap',
        'gridCols',
        'gridRows',
        'height',
        'heightFactor',
        'heroFlight',
        'heroTag',
        'hideOnDrag',
        'id',
        'ignorePointer',
        'items',
        'justify',
        'left',
        'lockAspect',
        'longPressDraggable',
        'margin',
        'matrix',
        'matrixBind',
        'maxHeight',
        'maxWidth',
        'minHeight',
        'minWidth',
        'offstage',
        'onClick',
        'opacity',
        'opacityBind',
        'padding',
        'pinned',
        'ratio',
        'repaintBoundary',
        'resize',
        'right',
        'rotate',
        'rotateTurns',
        'rows',
        'scale',
        'scrollable',
        'semanticLabel',
        'semantics',
        'snapGrid',
        'style',
        'top',
        'transform',
        'transformBind',
        'transition',
        'variant',
        'width',
        'widthFactor',
      ],
      'propTypes': <String, String>{
        'absorbPointer': 'bool',
        'animate': 'bool',
        'aspectBox': 'bool',
        'bind': 'String',
        'bottom': 'bool',
        'clip': 'bool',
        'clipKind': 'String',
        'cols': 'String',
        'constrained': 'bool',
        'curve': 'String',
        'dense': 'bool',
        'direction': 'String',
        'disabled': 'bool',
        'dragAxis': 'String',
        'dragData': 'String',
        'dragOpacity': 'double',
        'draggable': 'bool',
        'durationMs': 'int',
        'expand': 'bool',
        'fill': 'String',
        'flex': 'int',
        'floating': 'bool',
        'fractional': 'bool',
        'fractions': 'List<dynamic>',
        'gap': 'double',
        'gridCols': 'String',
        'gridRows': 'String',
        'height': 'double',
        'heightFactor': 'double',
        'heroFlight': 'bool',
        'heroTag': 'String',
        'hideOnDrag': 'bool',
        'id': 'dynamic',
        'ignorePointer': 'bool',
        'items': 'String',
        'justify': 'String',
        'left': 'bool',
        'lockAspect': 'bool',
        'longPressDraggable': 'bool',
        'margin': 'List<dynamic>',
        'matrix': 'String',
        'matrixBind': 'String',
        'maxHeight': 'double',
        'maxWidth': 'double',
        'minHeight': 'double',
        'minWidth': 'double',
        'offstage': 'bool',
        'onClick': 'VoidCallback',
        'opacity': 'double',
        'opacityBind': 'String',
        'padding': 'List<dynamic>',
        'pinned': 'bool',
        'ratio': 'double',
        'repaintBoundary': 'bool',
        'resize': 'bool',
        'right': 'bool',
        'rotate': 'bool',
        'rotateTurns': 'double',
        'rows': 'String',
        'scale': 'String',
        'scrollable': 'bool',
        'semanticLabel': 'String',
        'semantics': 'bool',
        'snapGrid': 'double',
        'style': 'String',
        'top': 'bool',
        'transform': 'bool',
        'transformBind': 'String',
        'transition': 'String',
        'variant': 'String',
        'width': 'double',
        'widthFactor': 'double',
      },
    },
    'canvas': <String, dynamic>{
      'sourceFile': 'omni_cores/canvas_core.dart',
      'aliasCount': 1,
      'defineCount': 0,
      'propCount': 13,
      'featureProps': <String>[
        'baseline',
        'bind',
        'color',
        'commands',
        'fillColor',
        'gapX',
        'mode',
        'scaleY',
        'shapeDef',
        'src',
        'stepX',
        'thickness',
        'uniformBind',
      ],
      'propTypes': <String, String>{
        'baseline': 'String',
        'bind': 'String',
        'color': 'Color',
        'commands': 'List<dynamic>',
        'fillColor': 'Color',
        'gapX': 'double',
        'mode': 'String',
        'scaleY': 'double',
        'shapeDef': 'Map<String, dynamic>',
        'src': 'String',
        'stepX': 'double',
        'thickness': 'double',
        'uniformBind': 'String',
      },
    },
    'collab': <String, dynamic>{
      'sourceFile': 'omni_cores/collab_core.dart',
      'aliasCount': 4,
      'defineCount': 0,
      'propCount': 7,
      'featureProps': <String>[
        'as',
        'key',
        'patch',
        'resource',
        'room',
        'store',
        'userId',
      ],
      'propTypes': <String, String>{
        'as': 'String',
        'key': 'String',
        'patch': 'Map<String, dynamic>',
        'resource': 'String',
        'room': 'String',
        'store': 'String',
        'userId': 'String',
      },
    },
    'component': <String, dynamic>{
      'sourceFile': 'quantum_vm_components.dart',
      'aliasCount': 4,
      'defineCount': 0,
      'propCount': 38,
      'featureProps': <String>[
        'animations',
        'batch',
        'cache',
        'capabilities',
        'component',
        'computed',
        'cursor',
        'definition',
        'description',
        'features',
        'fields',
        'guard',
        'hooks',
        'links',
        'media',
        'name',
        'network',
        'omni',
        'pagination',
        'payload',
        'permissions',
        'policies',
        'policy',
        'presentation',
        'preview',
        'projection',
        'props',
        'render',
        'resource',
        'resources',
        'runtime',
        'select',
        'slots',
        'spec',
        'state',
        'stream',
        'ui',
        'variants',
      ],
      'propTypes': <String, String>{
        'animations': 'dynamic',
        'batch': 'dynamic',
        'cache': 'dynamic',
        'capabilities': 'dynamic',
        'component': 'dynamic',
        'computed': 'dynamic',
        'cursor': 'dynamic',
        'definition': 'dynamic',
        'description': 'String',
        'features': 'dynamic',
        'fields': 'dynamic',
        'guard': 'dynamic',
        'hooks': 'dynamic',
        'links': 'dynamic',
        'media': 'dynamic',
        'name': 'String',
        'network': 'dynamic',
        'omni': 'dynamic',
        'pagination': 'dynamic',
        'payload': 'dynamic',
        'permissions': 'dynamic',
        'policies': 'dynamic',
        'policy': 'dynamic',
        'presentation': 'dynamic',
        'preview': 'bool',
        'projection': 'dynamic',
        'props': 'dynamic',
        'render': 'bool',
        'resource': 'dynamic',
        'resources': 'dynamic',
        'runtime': 'dynamic',
        'select': 'dynamic',
        'slots': 'dynamic',
        'spec': 'dynamic',
        'state': 'dynamic',
        'stream': 'dynamic',
        'ui': 'dynamic',
        'variants': 'dynamic',
      },
    },
    'connect': <String, dynamic>{
      'sourceFile': 'omni_cores/connect_core.dart',
      'aliasCount': 11,
      'defineCount': 2,
      'propCount': 20,
      'featureProps': <String>[
        'activeRole',
        'altThreshold',
        'cancelThreshold',
        'channel',
        'contract',
        'fallback',
        'focusChannel',
        'heroTag',
        'longPressReveal',
        'onAlt',
        'onBack',
        'onCancel',
        'onClose',
        'onCommit',
        'onDismissed',
        'onRefresh',
        'phaseChannel',
        'roleNames',
        'scale',
        'text',
      ],
      'propTypes': <String, String>{
        'activeRole': 'String',
        'altThreshold': 'double',
        'cancelThreshold': 'double',
        'channel': 'String',
        'contract': 'String',
        'fallback': 'String',
        'focusChannel': 'String',
        'heroTag': 'String',
        'longPressReveal': 'bool',
        'onAlt': 'VoidCallback',
        'onBack': 'VoidCallback',
        'onCancel': 'VoidCallback',
        'onClose': 'VoidCallback',
        'onCommit': 'VoidCallback',
        'onDismissed': 'VoidCallback',
        'onRefresh': 'VoidCallback',
        'phaseChannel': 'String',
        'roleNames': 'List<dynamic>',
        'scale': 'double',
        'text': 'String',
      },
    },
    'control': <String, dynamic>{
      'sourceFile': 'omni_cores/control_core.dart',
      'aliasCount': 10,
      'defineCount': 0,
      'propCount': 17,
      'featureProps': <String>[
        'action',
        'actions',
        'context',
        'disposeFlowState',
        'heroKey',
        'id',
        'initial',
        'initialIndex',
        'initialState',
        'namespace',
        'optimisticData',
        'rollbackOn',
        'routeKey',
        'selectionKey',
        'stateKey',
        'states',
        'steps',
      ],
      'propTypes': <String, String>{
        'action': 'String',
        'actions': 'Map<String, dynamic>',
        'context': 'Map<String, dynamic>',
        'disposeFlowState': 'bool',
        'heroKey': 'String',
        'id': 'String',
        'initial': 'String',
        'initialIndex': 'int',
        'initialState': 'Map<String, dynamic>',
        'namespace': 'String',
        'optimisticData': 'Map<String, dynamic>',
        'rollbackOn': 'String',
        'routeKey': 'String',
        'selectionKey': 'String',
        'stateKey': 'String',
        'states': 'Map<String, dynamic>',
        'steps': 'List<dynamic>',
      },
    },
    'data': <String, dynamic>{
      'sourceFile': 'omni_cores/data_core.dart',
      'aliasCount': 2,
      'defineCount': 0,
      'propCount': 21,
      'featureProps': <String>[
        'action',
        'as',
        'bind',
        'channel',
        'cols',
        'cursorKey',
        'direction',
        'empty',
        'gap',
        'header',
        'indexAs',
        'itemHeight',
        'key',
        'limit',
        'onEndReached',
        'onReorder',
        'pageSize',
        'pipeline',
        'searchBind',
        'sources',
        'start',
      ],
      'propTypes': <String, String>{
        'action': 'String',
        'as': 'String',
        'bind': 'String',
        'channel': 'String',
        'cols': 'String',
        'cursorKey': 'String',
        'direction': 'String',
        'empty': 'Widget',
        'gap': 'double',
        'header': 'Widget',
        'indexAs': 'String',
        'itemHeight': 'double',
        'key': 'String',
        'limit': 'int',
        'onEndReached': 'VoidCallback',
        'onReorder': 'VoidCallback',
        'pageSize': 'int',
        'pipeline': 'String',
        'searchBind': 'String',
        'sources': 'List<dynamic>',
        'start': 'int',
      },
    },
    'decoration': <String, dynamic>{
      'sourceFile': 'omni_cores/decoration_core.dart',
      'aliasCount': 3,
      'defineCount': 0,
      'propCount': 29,
      'featureProps': <String>[
        'absorbPointer',
        'beginColor',
        'blur',
        'clip',
        'color',
        'endColor',
        'fontSize',
        'height',
        'highlightColor',
        'ignorePointer',
        'label',
        'mergeStyle',
        'onDoubleTap',
        'onHover',
        'onLongPress',
        'onTap',
        'radius',
        'right',
        'sigma',
        'splashColor',
        'spread',
        'style',
        'suppressParentData',
        'textColor',
        'tintColor',
        'top',
        'width',
        'x',
        'y',
      ],
      'propTypes': <String, String>{
        'absorbPointer': 'bool',
        'beginColor': 'Color',
        'blur': 'double',
        'clip': 'bool',
        'color': 'Color',
        'endColor': 'Color',
        'fontSize': 'double',
        'height': 'double',
        'highlightColor': 'Color',
        'ignorePointer': 'bool',
        'label': 'String',
        'mergeStyle': 'String',
        'onDoubleTap': 'VoidCallback',
        'onHover': 'VoidCallback',
        'onLongPress': 'VoidCallback',
        'onTap': 'VoidCallback',
        'radius': 'double',
        'right': 'double',
        'sigma': 'double',
        'splashColor': 'Color',
        'spread': 'double',
        'style': 'String',
        'suppressParentData': 'bool',
        'textColor': 'Color',
        'tintColor': 'Color',
        'top': 'double',
        'width': 'double',
        'x': 'double',
        'y': 'double',
      },
    },
    'field': <String, dynamic>{
      'sourceFile': 'omni_cores/field_core.dart',
      'aliasCount': 10,
      'defineCount': 0,
      'propCount': 16,
      'featureProps': <String>[
        'bind',
        'decimal',
        'disabled',
        'divisions',
        'id',
        'initialValue',
        'label',
        'max',
        'maxLines',
        'min',
        'minLines',
        'placeholder',
        'prefix',
        'radius',
        'readOnly',
        'suffix',
      ],
      'propTypes': <String, String>{
        'bind': 'String',
        'decimal': 'bool',
        'disabled': 'bool',
        'divisions': 'int',
        'id': 'String',
        'initialValue': 'bool',
        'label': 'String',
        'max': 'double',
        'maxLines': 'int',
        'min': 'double',
        'minLines': 'int',
        'placeholder': 'String',
        'prefix': 'Widget',
        'radius': 'double',
        'readOnly': 'bool',
        'suffix': 'Widget',
      },
    },
    'hook': <String, dynamic>{
      'sourceFile': 'omni_cores/hook_core.dart',
      'aliasCount': 9,
      'defineCount': 0,
      'propCount': 30,
      'featureProps': <String>[
        'action',
        'as',
        'bind',
        'bridge',
        'catch',
        'delegateProps',
        'deps',
        'enabled',
        'fallback',
        'finally',
        'id',
        'initial',
        'initialState',
        'key',
        'locals',
        'memo',
        'memoKey',
        'ms',
        'onEffect',
        'onMount',
        'onUnmount',
        'path',
        'payload',
        'runOnMount',
        'scope',
        'store',
        'stream',
        'target',
        'try',
        'value',
      ],
      'propTypes': <String, String>{
        'action': 'dynamic',
        'as': 'String',
        'bind': 'String',
        'bridge': 'Map<String, dynamic>',
        'catch': 'Widget',
        'delegateProps': 'Map<String, dynamic>',
        'deps': 'List<dynamic>',
        'enabled': 'bool',
        'fallback': 'Widget',
        'finally': 'Widget',
        'id': 'String',
        'initial': 'dynamic',
        'initialState': 'Map<String, dynamic>',
        'key': 'String',
        'locals': 'dynamic',
        'memo': 'dynamic',
        'memoKey': 'dynamic',
        'ms': 'int',
        'onEffect': 'VoidCallback',
        'onMount': 'VoidCallback',
        'onUnmount': 'VoidCallback',
        'path': 'String',
        'payload': 'dynamic',
        'runOnMount': 'bool',
        'scope': 'Map<String, dynamic>',
        'store': 'String',
        'stream': 'String',
        'target': 'String',
        'try': 'Widget',
        'value': 'dynamic',
      },
    },
    'layout': <String, dynamic>{
      'sourceFile': 'omni_cores/layout_core.dart',
      'aliasCount': 38,
      'defineCount': 0,
      'propCount': 9,
      'featureProps': <String>[
        'align',
        'id',
        'layoutId',
        'match',
        'selectable',
        'selectedStyle',
        'style',
        'text',
        'value',
      ],
      'propTypes': <String, String>{
        'align': 'String',
        'id': 'String',
        'layoutId': 'String',
        'match': 'String',
        'selectable': 'bool',
        'selectedStyle': 'String',
        'style': 'String',
        'text': 'String',
        'value': 'String',
      },
    },
    'media': <String, dynamic>{
      'sourceFile': 'omni_cores/media_core.dart',
      'aliasCount': 4,
      'defineCount': 0,
      'propCount': 32,
      'featureProps': <String>[
        'allowBatch',
        'audioUrl',
        'autoPlay',
        'bind',
        'blurIntensity',
        'codePoint',
        'color',
        'count',
        'error',
        'fill',
        'fit',
        'fontFamily',
        'height',
        'id',
        'loop',
        'mode',
        'path',
        'placeholder',
        'placeholderBase64',
        'poster',
        'progressive',
        'quality',
        'roomId',
        'showSubtitles',
        'size',
        'src',
        'stroke',
        'strokeWidth',
        'subtitleOffsetMs',
        'subtitleUrl',
        'url',
        'width',
      ],
      'propTypes': <String, String>{
        'allowBatch': 'bool',
        'audioUrl': 'String',
        'autoPlay': 'bool',
        'bind': 'String',
        'blurIntensity': 'double',
        'codePoint': 'int',
        'color': 'Color',
        'count': 'int',
        'error': 'Widget',
        'fill': 'Color',
        'fit': 'String',
        'fontFamily': 'String',
        'height': 'double',
        'id': 'String',
        'loop': 'bool',
        'mode': 'String',
        'path': 'String',
        'placeholder': 'Widget',
        'placeholderBase64': 'String',
        'poster': 'String',
        'progressive': 'bool',
        'quality': 'int',
        'roomId': 'String',
        'showSubtitles': 'bool',
        'size': 'double',
        'src': 'String',
        'stroke': 'Color',
        'strokeWidth': 'double',
        'subtitleOffsetMs': 'int',
        'subtitleUrl': 'String',
        'url': 'String',
        'width': 'double',
      },
    },
    'portal': <String, dynamic>{
      'sourceFile': 'omni_cores/portal_core.dart',
      'aliasCount': 6,
      'defineCount': 0,
      'propCount': 32,
      'featureProps': <String>[
        'align',
        'allowResize',
        'barrierColor',
        'barrierDismissible',
        'barrierOpacity',
        'bgBlurSigma',
        'bgEffect',
        'bgZoomDepth',
        'clipSheet',
        'content',
        'cornerRadius',
        'durationMs',
        'edge',
        'enableDrag',
        'extrude3D',
        'h',
        'isModal',
        'matchAnchorWidth',
        'resizeEdges',
        'rootBgColor',
        'sheetAlignment',
        'sheetPadding',
        'sheetPaddingBottom',
        'sheetPaddingLeft',
        'sheetPaddingRight',
        'sheetPaddingTop',
        'showDragHandle',
        'trigger',
        'triggerBind',
        'w',
        'x',
        'y',
      ],
      'propTypes': <String, String>{
        'align': 'String',
        'allowResize': 'bool',
        'barrierColor': 'Color',
        'barrierDismissible': 'bool',
        'barrierOpacity': 'double',
        'bgBlurSigma': 'double',
        'bgEffect': 'String',
        'bgZoomDepth': 'double',
        'clipSheet': 'bool',
        'content': 'Widget',
        'cornerRadius': 'double',
        'durationMs': 'double',
        'edge': 'String',
        'enableDrag': 'bool',
        'extrude3D': 'bool',
        'h': 'double',
        'isModal': 'bool',
        'matchAnchorWidth': 'bool',
        'resizeEdges': 'String',
        'rootBgColor': 'Color',
        'sheetAlignment': 'String',
        'sheetPadding': 'double',
        'sheetPaddingBottom': 'double',
        'sheetPaddingLeft': 'double',
        'sheetPaddingRight': 'double',
        'sheetPaddingTop': 'double',
        'showDragHandle': 'bool',
        'trigger': 'Widget',
        'triggerBind': 'String',
        'w': 'double',
        'x': 'double',
        'y': 'double',
      },
    },
    'stream': <String, dynamic>{
      'sourceFile': 'omni_cores/stream_core.dart',
      'aliasCount': 4,
      'defineCount': 0,
      'propCount': 7,
      'featureProps': <String>[
        'as',
        'bind',
        'capacity',
        'channels',
        'ms',
        'statusKey',
        'url',
      ],
      'propTypes': <String, String>{
        'as': 'String',
        'bind': 'String',
        'capacity': 'int',
        'channels': 'List<dynamic>',
        'ms': 'int',
        'statusKey': 'String',
        'url': 'String',
      },
    },
    'system': <String, dynamic>{
      'sourceFile': 'omni_cores/system_core.dart',
      'aliasCount': 4,
      'defineCount': 0,
      'propCount': 27,
      'featureProps': <String>[
        'action',
        'as',
        'autoStart',
        'axis',
        'bind',
        'bindOutput',
        'bindSource',
        'bindX',
        'bindY',
        'copy',
        'damping',
        'direction',
        'indexAs',
        'initialState',
        'interval',
        'mode',
        'ms',
        'onTick',
        'outputBind',
        'params',
        'pipeline',
        'props',
        'size',
        'stiffness',
        'task',
        'template',
        'type',
      ],
      'propTypes': <String, String>{
        'action': 'String',
        'as': 'String',
        'autoStart': 'bool',
        'axis': 'String',
        'bind': 'String',
        'bindOutput': 'String',
        'bindSource': 'String',
        'bindX': 'String',
        'bindY': 'String',
        'copy': 'String',
        'damping': 'double',
        'direction': 'String',
        'indexAs': 'String',
        'initialState': 'Map<String, dynamic>',
        'interval': 'int',
        'mode': 'String',
        'ms': 'int',
        'onTick': 'VoidCallback',
        'outputBind': 'String',
        'params': 'Map<String, dynamic>',
        'pipeline': 'String',
        'props': 'Map<String, dynamic>',
        'size': 'int',
        'stiffness': 'double',
        'task': 'String',
        'template': 'Map<String, dynamic>',
        'type': 'String',
      },
    },
    'template': <String, dynamic>{
      'sourceFile': 'omni_cores/template_core.dart',
      'aliasCount': 51,
      'defineCount': 0,
      'propCount': 34,
      'featureProps': <String>[
        'activeFill',
        'avatars',
        'backText',
        'bind',
        'categories',
        'cells',
        'children',
        'columns',
        'doneText',
        'dragData',
        'entries',
        'heroId',
        'index',
        'initialIndex',
        'intent',
        'itemScale',
        'itemStyle',
        'items',
        'label',
        'level',
        'magneto',
        'magnetoIntensity',
        'maxVisible',
        'multiple',
        'nextText',
        'onDone',
        'onDrop',
        'onSelect',
        'onToggle',
        'prevText',
        'rows',
        'selected',
        'steps',
        'subtitle',
      ],
      'propTypes': <String, String>{
        'activeFill': 'String',
        'avatars': 'List<dynamic>',
        'backText': 'String',
        'bind': 'String',
        'categories': 'List<dynamic>',
        'cells': 'List<dynamic>',
        'children': 'List<dynamic>',
        'columns': 'List<dynamic>',
        'doneText': 'String',
        'dragData': 'String',
        'entries': 'List<dynamic>',
        'heroId': 'String',
        'index': 'int',
        'initialIndex': 'int',
        'intent': 'String',
        'itemScale': 'String',
        'itemStyle': 'String',
        'items': 'List<dynamic>',
        'label': 'String',
        'level': 'int',
        'magneto': 'bool',
        'magnetoIntensity': 'double',
        'maxVisible': 'int',
        'multiple': 'bool',
        'nextText': 'String',
        'onDone': 'List<dynamic>',
        'onDrop': 'VoidCallback',
        'onSelect': 'List<dynamic>',
        'onToggle': 'List<dynamic>',
        'prevText': 'String',
        'rows': 'List<dynamic>',
        'selected': 'bool',
        'steps': 'List<dynamic>',
        'subtitle': 'String',
      },
    },
    'text': <String, dynamic>{
      'sourceFile': 'omni_cores/text_core.dart',
      'aliasCount': 0,
      'defineCount': 0,
      'propCount': 7,
      'featureProps': <String>[
        'maxLines',
        'overflow',
        'selectable',
        'softWrap',
        'style',
        'text',
        'value',
      ],
      'propTypes': <String, String>{
        'maxLines': 'int',
        'overflow': 'String',
        'selectable': 'bool',
        'softWrap': 'bool',
        'style': 'String',
        'text': 'String',
        'value': 'String',
      },
    },
    'visual': <String, dynamic>{
      'sourceFile': 'omni_cores/visual_core.dart',
      'aliasCount': 5,
      'defineCount': 0,
      'propCount': 23,
      'featureProps': <String>[
        'animationType',
        'body',
        'boxType',
        'canvasType',
        'chartType',
        'child',
        'chrome',
        'clip',
        'connectType',
        'content',
        'delegateProps',
        'fieldType',
        'footer',
        'header',
        'isComplex',
        'layout',
        'mediaType',
        'overlay',
        'portalType',
        'systemType',
        'target',
        'templateName',
        'willChange',
      ],
      'propTypes': <String, String>{
        'animationType': 'String',
        'body': 'Widget',
        'boxType': 'String',
        'canvasType': 'dynamic',
        'chartType': 'String',
        'child': 'Widget',
        'chrome': 'Widget',
        'clip': 'bool',
        'connectType': 'dynamic',
        'content': 'Widget',
        'delegateProps': 'Map<String, dynamic>',
        'fieldType': 'String',
        'footer': 'Widget',
        'header': 'Widget',
        'isComplex': 'bool',
        'layout': 'String',
        'mediaType': 'String',
        'overlay': 'Widget',
        'portalType': 'dynamic',
        'systemType': 'String',
        'target': 'String',
        'templateName': 'dynamic',
        'willChange': 'bool',
      },
    },
  };

  static Map<String, dynamic> _coreFeatureSchema(
    String type, {
    required String description,
    required List<String> tags,
    required String engine,
  }) {
    final String core = type.contains(':') ? type.split(':').first : type;
    final Map<String, String> propTypes =
        _omniCoreFeaturePropTypes[core] ?? const <String, String>{};
    final List<String> subtypes = _omniCoreSubtypes[core] ?? const <String>[];
    final Map<String, dynamic> properties = <String, dynamic>{
      '__subType': {'type': 'string', 'enum': subtypes},
      'style': {'type': 'string'},
      'props': {'type': 'object'},
      'slots': {'type': 'object'},
      'children': {'type': 'array'},
      'metadata': {'type': 'object'},
      'actions': {'type': 'array'},
      'tags': {'type': 'array'},
      for (final entry in propTypes.entries)
        entry.key: (() {
          final t = entry.value;
          if (t.startsWith('List')) return {'type': 'array', 'originalType': t};
          if (t.startsWith('Map')) return {'type': 'object', 'originalType': t};
          switch (t) {
            case 'String':
            case 'Color':
              return {'type': 'string', 'originalType': t};
            case 'int':
            case 'double':
            case 'num':
              return {'type': 'number', 'originalType': t};
            case 'bool':
              return {'type': 'boolean', 'originalType': t};
            default:
              return {'type': 'object', 'originalType': t};
          }
        })(),
    };
    return <String, dynamic>{
      'paramSchema': <String, dynamic>{
        'type': 'object',
        'properties': properties,
        'required': const <String>[],
        'additionalProperties': true,
        'subtypes': subtypes,
        'featureProps': propTypes.keys.toList(growable: false),
      },
      'infoSchema': _buildInfoSchema(
        name: core,
        kind: 'core',
        description: description,
        tags: tags,
        engine: engine,
        extra: <String, dynamic>{
          'sourceFile': _omniCoreFeatureCatalog[core]?['sourceFile'],
          'aliasCount': _omniCoreFeatureCatalog[core]?['aliasCount'],
          'defineCount': _omniCoreFeatureCatalog[core]?['defineCount'],
          'propCount': _omniCoreFeatureCatalog[core]?['propCount'],
          'featureProps': _omniCoreFeatureCatalog[core]?['featureProps'],
          'propTypes': propTypes,
          'subtypes': subtypes,
        },
      ),
      'featureProps':
          _omniCoreFeatureCatalog[core]?['featureProps'] ?? const <String>[],
      'propTypes': propTypes,
      'sourceFile': _omniCoreFeatureCatalog[core]?['sourceFile'],
      'aliasCount': _omniCoreFeatureCatalog[core]?['aliasCount'],
      'defineCount': _omniCoreFeatureCatalog[core]?['defineCount'],
    };
  }

  static Map<String, dynamic> _buildInfoSchema({
    required String name,
    required String kind,
    required String description,
    required List<String> tags,
    required String engine,
    Map<String, dynamic>? extra,
  }) {
    return <String, dynamic>{
      'name': name,
      'kind': kind,
      'description': description,
      'engine': engine,
      'tags': List<String>.unmodifiable(tags),
      if (extra != null && extra.isNotEmpty) 'details': extra,
    };
  }

  void defineAlias(String alias, String targetType,
      {Map<String, dynamic> defaultProps = const {},
      String? description,
      Map<String, dynamic> metadata = const {},
      List<String> tags = const []}) {
    final Map<String, dynamic> clonedProps =
        Map<String, dynamic>.from(defaultProps);
    final String resolvedDescription = description ?? 'Alias for $targetType';
    final List<String> resolvedTags = tags.isNotEmpty
        ? List<String>.unmodifiable(tags)
        : List<String>.unmodifiable(<String>[
            'alias',
            targetType.split(':').first,
            _humanizeTarget(targetType),
          ]);
    final Map<String, dynamic> defaultPropsSchema = _schemaForMap(clonedProps);
    final Map<String, dynamic> featureSchema = _coreFeatureSchema(
      targetType,
      description: resolvedDescription,
      tags: resolvedTags,
      engine: 'QuantumVM',
    );
    final String targetKind =
        targetType.contains(':') ? targetType.split(':').first : targetType;
    final Map<String, dynamic> paramSchema = Map<String, dynamic>.from(
      featureSchema['paramSchema'] as Map? ?? defaultPropsSchema,
    );
    final Map<String, dynamic> infoSchema = Map<String, dynamic>.from(
      featureSchema['infoSchema'] as Map? ??
          _buildInfoSchema(
            name: alias,
            kind: 'alias',
            description: resolvedDescription,
            tags: resolvedTags,
            engine: 'QuantumVM',
            extra: <String, dynamic>{
              'targetType': targetType,
              'targetKind': targetKind,
              'targetName': _humanizeTarget(targetType),
              'defaultProps': clonedProps,
              'defaultPropsSchema': defaultPropsSchema,
            },
          ),
    )
      ..['alias'] = alias
      ..['targetType'] = targetType
      ..['targetKind'] = targetKind
      ..['targetName'] = _humanizeTarget(targetType)
      ..['defaultPropsSchema'] = defaultPropsSchema;

    _aliases[alias] = {'type': targetType, 'props': clonedProps};
    _registryEntries['alias:$alias'] = QLRegistryEntry(
      id: 'alias:$alias',
      kind: 'alias',
      name: alias,
      description: resolvedDescription,
      engine: 'QuantumVM',
      tags: resolvedTags,
      params: {
        'targetType': targetType,
        'defaultProps': clonedProps,
        'paramSchema': paramSchema,
      },
      metadata: {
        ...metadata,
        'targetType': targetType,
        'targetKind': targetKind,
        'targetName': _humanizeTarget(targetType),
        'paramSchema': paramSchema,
        'infoSchema': infoSchema,
        'featureProps': featureSchema['featureProps'],
        'propTypes': featureSchema['propTypes'],
        'sourceFile': featureSchema['sourceFile'],
        'aliasCount': featureSchema['aliasCount'],
        'defineCount': featureSchema['defineCount'],
        'defaultPropsSchema': defaultPropsSchema,
        'description': resolvedDescription,
      },
      registeredAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? getAlias(String alias) => _aliases[alias];

  final Map<String, QLPlugin> _plugins = {};
  final Map<String, QLActionPlugin> _actions = {};
  final Map<String, QLRegistryEntry> _registryEntries = {};
  final Map<String, Map<String, String>> _slotDefaults = {};
  final Map<String, QuantumDesignSystemBundle> _designSystems = {};

  final QLDataStore store = QLStoreRegistry.instance.defaultStore;
  final QLRuntimeCache<QLSchemaSlice> schemaSlices =
      QLRuntimeCache<QLSchemaSlice>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 4096, maxWeight: 2 * 1024 * 1024));
  final QLRuntimeCache<QToken> _styleTokens = QLRuntimeCache<QToken>(
      config:
          const QLRuntimeCacheConfig(maxEntries: 4096, maxWeight: 1024 * 1024));
  final QLRuntimeCache<Map<String, dynamic>> _localManifests =
      QLRuntimeCache<Map<String, dynamic>>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 128, maxWeight: 12 * 1024 * 1024));

  final Expando<_QLRenderHints> _renderHints = Expando<_QLRenderHints>();

  final Map<int, Timer> _debouncers = {};
  List<ActionMiddleware> _middlewares = [];

  QLWorkerPool? _workerPool;
  QLWorkerPool get workerPool =>
      _workerPool ??
      (throw StateError(
          'QuantumVM WorkerPool not initialized. Call initialize() first.'));

  QLAnimCompositor? _compositor;
  QLAnimCompositor get compositor =>
      _compositor ??
      (throw StateError(
          'QuantumVM Compositor not initialized. Wrap app in QuantumVMRoot.'));

  bool _isInitialized = false;

  void initialize({int workerThreads = 4}) {
    if (_isInitialized) return;
    _workerPool = QLWorkerPool(size: workerThreads);

    // 🚀 HOOK: Wire state slice registry directly to VM action dispatcher!
    QLSliceRegistry.actionRegistrar = registerAction;
    _registerCoreStateActions();

    _isInitialized = true;
  }

  void _registerCoreStateActions() {
    registerAction(
      'state.set',
      LambdaActionPlugin((p, s, c) async {
        final key = p['key']?.toString();
        if (key == null || key.isEmpty) return null;
        final val = p.containsKey('value') ? p['value'] : p['data'];
        s.set(key, val);
        return val;
      }),
      description: 'Set a value in the global store',
      params: const {'key': 'String', 'value': 'dynamic'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );

    registerAction(
      'state.merge',
      LambdaActionPlugin((p, s, c) async {
        final raw = p['data'];
        if (raw is Map<String, dynamic>) {
          s.merge(raw);
        } else if (raw is Map) {
          s.merge(Map<String, dynamic>.from(raw));
        }
        return raw;
      }),
      description: 'Merge a map into the global store',
      params: const {'data': 'Map<String, dynamic>'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );

    registerAction(
      'state.toggle',
      LambdaActionPlugin((p, s, c) async {
        final key = p['key']?.toString();
        if (key == null || key.isEmpty) return null;
        final next = !(s.get(key) == true);
        s.set(key, next);
        return next;
      }),
      description: 'Toggle a boolean flag in the global store',
      params: const {'key': 'String'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );

    registerAction(
      'state.remove',
      LambdaActionPlugin((p, s, c) async {
        final key = p['key']?.toString();
        if (key == null || key.isEmpty) return null;
        s.sweep(key);
        return key;
      }),
      description: 'Remove a path from the global store',
      params: const {'key': 'String'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );
  }

  void installBundle(QuantumExtensionBundle bundle, {bool overwrite = true}) {
    bundle.plugins.forEach((name, plugin) {
      if (!overwrite && hasPlugin(name)) return;
      registerPlugin(
        plugin,
        metadata: bundle.metadata[name] ?? const {},
      );
    });

    bundle.actions.forEach((name, action) {
      if (!overwrite && hasAction(name)) return;
      registerAction(
        name,
        action,
        metadata: bundle.metadata[name] ?? const {},
      );
    });

    bundle.aliases.forEach((alias, payload) {
      if (!overwrite && hasAlias(alias)) return;
      final targetType = payload['type']?.toString() ?? '';
      if (targetType.isEmpty) return;
      final defaultProps = Map<String, dynamic>.from(
        payload['props'] as Map? ?? const {},
      );
      defineAlias(
        alias,
        targetType,
        defaultProps: defaultProps,
        description: payload['description']?.toString(),
        metadata: Map<String, dynamic>.from(
          payload['metadata'] as Map? ?? const {},
        ),
        tags: _asStringList(payload['tags']),
      );
    });

    bundle.slotTypes.forEach((alias, types) {
      if (!overwrite && getSlotTypes(alias) != null) return;
      registerSlotTypes(alias, Map<String, String>.from(types));
    });

    bundle.slotNodes.forEach((alias, slots) {
      if (!overwrite && getDefaultSlotNodes(alias) != null) return;
      registerDefaultSlotNodes(alias, Map<String, dynamic>.from(slots));
    });
  }

  void attachCompositor(TickerProvider vsync) {
    if (_compositor != null) {
      try {
        _compositor!.dispose();
      } catch (_) {}
    }
    _compositor = QLAnimCompositor(vsync: vsync);
    _compositor!.activate();
  }

  void registerPlugin(
    QLPlugin p, {
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) {
    final Map<String, dynamic> resolvedParams = params.isNotEmpty
        ? Map<String, dynamic>.from(params)
        : Map<String, dynamic>.from(p.defaultProps);
    final Map<String, dynamic> paramSchema = _schemaForMap(resolvedParams);
    final String resolvedDescription =
        description ?? _inferPluginDescription(p);
    final List<String> resolvedTags =
        tags.isNotEmpty ? List<String>.unmodifiable(tags) : _inferPluginTags(p);
    final String engineName = engine ?? p.runtimeType.toString();
    final String pluginKind = _inferPluginKind(p);
    final Map<String, dynamic> coreSchema =
        _omniCoreFeatureCatalog.containsKey(p.type)
            ? _coreFeatureSchema(
                p.type,
                description: resolvedDescription,
                tags: resolvedTags,
                engine: engineName,
              )
            : _omniCoreSubtypes.containsKey(p.type)
                ? <String, dynamic>{
                    'paramSchema': _coreParamSchema(p.type),
                    'infoSchema': _coreInfoSchema(
                      type: p.type,
                      description: resolvedDescription,
                      tags: resolvedTags,
                      engine: engineName,
                    ),
                    'subtypes': _omniCoreSubtypes[p.type],
                  }
                : const <String, dynamic>{};
    _plugins[p.type] = p;
    _registryEntries['plugin:${p.type}'] = QLRegistryEntry(
      id: 'plugin:${p.type}',
      kind: pluginKind,
      name: p.type,
      description: resolvedDescription,
      engine: engineName,
      tags: resolvedTags,
      params: resolvedParams,
      metadata: {
        ..._inferPluginMetadata(p),
        ...metadata,
        ...coreSchema,
        'paramSchema': coreSchema['paramSchema'] ?? paramSchema,
        'infoSchema': coreSchema['infoSchema'] ??
            _buildInfoSchema(
              name: p.type,
              kind: pluginKind,
              description: resolvedDescription,
              tags: resolvedTags,
              engine: engineName,
              extra: <String, dynamic>{
                'params': resolvedParams,
                'defaultProps': Map<String, dynamic>.from(p.defaultProps),
              },
            ),
      },
      registeredAt: DateTime.now(),
    );
  }

  void registerAction(
    String name,
    QLActionPlugin p, {
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) {
    final Map<String, dynamic> resolvedParams =
        Map<String, dynamic>.from(params);
    final Map<String, dynamic> paramSchema = _schemaForMap(resolvedParams);
    final String resolvedDescription = description ?? 'Action $name';
    final List<String> resolvedTags =
        tags.isNotEmpty ? List<String>.unmodifiable(tags) : const ['action'];
    _actions[name] = p;
    _registryEntries['action:$name'] = QLRegistryEntry(
      id: 'action:$name',
      kind: 'action',
      name: name,
      description: resolvedDescription,
      engine: engine ?? p.runtimeType.toString(),
      tags: resolvedTags,
      params: resolvedParams,
      metadata: {
        ...metadata,
        'paramSchema': paramSchema,
        'infoSchema': _buildInfoSchema(
          name: name,
          kind: 'action',
          description: resolvedDescription,
          tags: resolvedTags,
          engine: engine ?? p.runtimeType.toString(),
          extra: <String, dynamic>{'params': resolvedParams},
        ),
      },
      registeredAt: DateTime.now(),
    );
  }

  void registerSlotTypes(String alias, Map<String, String> types) {
    final Map<String, String> resolvedTypes = Map<String, String>.from(types);
    final Map<String, dynamic> resolvedTypesDynamic =
        Map<String, dynamic>.from(resolvedTypes);
    _slotDefaults[alias] = resolvedTypes;
    _registryEntries['slottype:$alias'] = QLRegistryEntry(
      id: 'slottype:$alias',
      kind: 'slottype',
      name: alias,
      description: 'Slot types for $alias',
      engine: 'QuantumVM',
      tags: const ['slots'],
      params: {
        'types': resolvedTypes,
        'paramSchema': _schemaForMap(resolvedTypesDynamic),
      },
      metadata: {
        'types': resolvedTypes,
        'paramSchema': _schemaForMap(resolvedTypesDynamic),
        'infoSchema': _buildInfoSchema(
          name: alias,
          kind: 'slottype',
          description: 'Slot types for $alias',
          tags: const ['slots'],
          engine: 'QuantumVM',
          extra: <String, dynamic>{'types': resolvedTypes},
        ),
      },
      registeredAt: DateTime.now(),
    );
  }

  Map<String, String>? getSlotTypes(String alias) => _slotDefaults[alias];
  void setMiddlewares(List<ActionMiddleware> m) {
    _middlewares = [
      TelemetryVMBridge.buildActionMiddleware(),
      ...m,
    ];
  }

  QLRegistryEntry? registryEntry(String key, {String? kind}) {
    if (key.contains(':') && _registryEntries.containsKey(key)) {
      return _registryEntries[key];
    }
    if (kind != null) {
      final direct = _registryEntries['$kind:$key'];
      if (direct != null) return direct;
    }
    for (final entry in _aggregateRegistryEntries()) {
      if (entry.name == key && (kind == null || entry.kind == kind)) {
        return entry;
      }
    }
    return null;
  }

  List<QLRegistryEntry> registryEntries({String? kind, String? query}) {
    final q = query?.trim().toLowerCase() ?? '';

    bool matches(QLRegistryEntry e) {
      if (kind != null && e.kind != kind) return false;
      if (q.isEmpty) return true;
      if (e.id.toLowerCase().contains(q)) return true;
      if (e.kind.toLowerCase().contains(q)) return true;
      if (e.name.toLowerCase().contains(q)) return true;
      if (e.description.toLowerCase().contains(q)) return true;
      if (e.engine.toLowerCase().contains(q)) return true;
      if (e.params.toString().toLowerCase().contains(q)) return true;
      if (e.metadata.toString().toLowerCase().contains(q)) return true;
      for (final tag in e.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }

    final items =
        _aggregateRegistryEntries().where(matches).toList(growable: false);
    items.sort((a, b) => a.name.compareTo(b.name));
    return List<QLRegistryEntry>.unmodifiable(items);
  }

  List<QLRegistryEntry> _aggregateRegistryEntries() {
    final items = <QLRegistryEntry>[];
    items.addAll(_registryEntries.values);

    for (final componentName in _componentDefinitionsByName.keys) {
      final item = _nativeComponentDescribe(componentName);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: item['id']?.toString() ?? 'native_component:$componentName',
          kind: item['kind']?.toString() ?? 'native_component',
          name: item['name']?.toString() ?? componentName,
          description: item['description']?.toString() ??
              'Native component $componentName',
          engine: item['engine']?.toString() ?? 'QuantumVM',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt:
              DateTime.tryParse(item['registeredAt']?.toString() ?? '') ??
                  DateTime.now(),
        ));
      }
    }

    for (final module in QLModuleRegistry.instance.allModules) {
      items.add(QLRegistryEntry(
        id: 'module:${module.id}',
        kind: 'module',
        name: module.id,
        description: module.manifest['description']?.toString() ?? '',
        engine: 'QLModuleRegistry',
        tags: _asStringList(
            module.manifest['tags'] ?? module.manifest['keywords']),
        params: {
          'imports': QLModuleRegistry.instance.importsFor(module.id),
          'access': module.access.visibility.name,
        },
        metadata: module.manifest,
        registeredAt: module.registeredAt,
      ));

      final macros = module.manifest['macros'];
      if (macros is Map) {
        for (final entry in macros.entries) {
          items.add(QLRegistryEntry(
            id: 'macro:${module.id}:${entry.key}',
            kind: 'macro',
            name: entry.key.toString(),
            description: 'Macro ${entry.key} from module ${module.id}',
            engine: 'QLModuleRegistry',
            tags: const ['macro'],
            params: entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : {'value': entry.value},
            metadata: {
              'module': module.id,
              'macro': entry.key,
            },
            registeredAt: module.registeredAt,
          ));
        }
      }
    }

    for (final name in QJsonTemplateEngine_D.registryNames) {
      final item = QJsonTemplateEngine_D.describe(name);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: 'template:$name',
          kind: 'template',
          name: name,
          description: item['description']?.toString() ?? '',
          engine: item['engine']?.toString() ?? 'QJsonTemplateEngine_D',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt: DateTime.now(),
        ));
      }
    }

    for (final name in QMatrixLayoutRegistry.registryNames) {
      final item = QMatrixLayoutRegistry.describe(name);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: 'layout:$name',
          kind: 'layout',
          name: name,
          description: item['description']?.toString() ?? '',
          engine: item['engine']?.toString() ?? 'QMatrixLayoutRegistry',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt: DateTime.now(),
        ));
      }
    }

    for (final name in QLSchemaRegistry.instance.allSchemaNames) {
      final item = QLSchemaRegistry.instance.describe(name);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: 'schema:$name',
          kind: 'schema',
          name: name,
          description: item['description']?.toString() ?? '',
          engine: item['engine']?.toString() ?? 'QLSchemaRegistry',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt: DateTime.now(),
        ));
      }
    }

    for (final pipeName in QLPipes.registry.keys) {
      items.add(QLRegistryEntry(
        id: 'pipe:$pipeName',
        kind: 'pipe',
        name: pipeName,
        description: 'Pipe transform $pipeName',
        engine: 'QLPipes',
        tags: const ['pipe'],
        params: const {},
        metadata: const {},
        registeredAt: DateTime.now(),
      ));
    }

    return items;
  }

  Map<String, dynamic> registrySnapshot({String? kind, String? query}) {
    final items = registryEntries(kind: kind, query: query)
        .map((e) => e.toMap())
        .toList(growable: false);
    return {
      'counts': {
        'actions': _actions.length,
        'plugins': _plugins.length,
        'aliases': _aliases.length,
        'slotTypes': _slotDefaults.length,
        'slotNodes': _defaultSlotNodes.length,
        'internalRegistryItems': _registryEntries.length,
        'registryItems': items.length,
        'components': _componentDefinitionsByName.length,
        'modules': QLModuleRegistry.instance.registeredModuleIds.length,
        'macros': items.where((e) => e['kind'] == 'macro').length,
        'schemas': QLSchemaRegistry.instance.allSchemaNames.length,
        'templates': QJsonTemplateEngine_D.registryNames.length,
        'designSystems': _designSystems.length,
        'layouts': QMatrixLayoutRegistry.registryNames.length,
        'coreFiles': QLCoreFileRegistry.instance.count,
        'pipes': QLPipes.registry.length,
      },
      'items': items,
    };
  }

  Map<String, dynamic>? describeRegistryItem(String key, {String? kind}) {
    final entry = registryEntry(key, kind: kind);
    if (entry != null) return entry.toMap();

    final module = QLModuleRegistry.instance.get(key);
    if (module != null) {
      return {
        'id': module.id,
        'kind': 'module',
        'name': module.id,
        'description': module.manifest['description']?.toString() ?? '',
        'engine': 'QLModuleRegistry',
        'tags': _asStringList(
            module.manifest['tags'] ?? module.manifest['keywords']),
        'params': {
          'imports': QLModuleRegistry.instance.importsFor(module.id),
          'access': module.access.visibility.name,
        },
        'metadata': module.manifest,
        'registeredAt': module.registeredAt.toIso8601String(),
      };
    }

    final template = QJsonTemplateEngine_D.describe(key);
    if (template != null) return template;
    final layout = QMatrixLayoutRegistry.describe(key);
    if (layout != null) return layout;
    final schema = QLSchemaRegistry.instance.describe(key);
    if (schema != null) return schema;
    final coreFile = QLCoreFileRegistry.instance.descriptorByKey(key);
    if (coreFile != null) {
      return coreFile.toMap();
    }
    final component = _nativeComponentDescribe(key);
    if (component != null) {
      return component;
    }
    if (QLPipes.registry.containsKey(key)) {
      return {
        'id': 'pipe:$key',
        'kind': 'pipe',
        'name': key,
        'description': 'Pipe transform $key',
        'engine': 'QLPipes',
        'tags': ['pipe'],
        'params': const {},
        'metadata': const {},
      };
    }
    return null;
  }

  List<String> registeredRegistryKinds() => const [
        'action',
        'plugin',
        'alias',
        'slottype',
        'slotnodes',
        'module',
        'macro',
        'template',
        'layout',
        'schema',
        'pipe',
      ];

  // ─────────────────────────────────────────────────────────────────────────
  //  DYNAMIC DSL OPERATOR CATALOGUE
  //  All $-prefixed compile-time operators supported by the QVM compiler.
  // ─────────────────────────────────────────────────────────────────────────
  static const List<Map<String, String>> _dslOperators = <Map<String, String>>[
    {
      'name': r'$define',
      'description':
          'Declare compile-time named macros. Children can invoke them via \$call or by type name.',
      'valueType': 'Map<String, Node>',
    },
    {
      'name': r'$let',
      'description':
          'Declare compile-time local variables, resolved structurally from the compile-env.',
      'valueType': 'Map<String, dynamic>',
    },
    {
      'name': r'$if',
      'description':
          'Conditional render guard. Falsy conditions remove the node from the tree.',
      'valueType': 'dynamic',
    },
    {
      'name': r'$repeat',
      'description':
          'List renderer. Iterates the bound path, exposing each item via `as` binding.',
      'valueType': 'String (bind path)',
    },
    {
      'name': r'$call',
      'description':
          'Invoke a previously \$define-d macro by name, forwarding caller props.',
      'valueType': 'String (macro name)',
    },
    {
      'name': r'$switch',
      'description':
          'Multi-branch compile-time switch. Matches `\$switch` value against `cases` keys.',
      'valueType': 'dynamic',
    },
    {
      'name': r'$async',
      'description':
          'Async data loader. Fires an action and renders loading/data/error slots.',
      'valueType': 'Map<String, dynamic>',
    },
    {
      'name': r'$stream',
      'description': 'Reactive stream subscription binding.',
      'valueType': 'String | Map',
    },
    {
      'name': r'$machine',
      'description':
          'Finite state machine node. Wraps children in a control:machine scope.',
      'valueType': 'Map<String, dynamic>',
    },
    {
      'name': r'$portal',
      'description': 'Renders content into a named portal overlay entry.',
      'valueType': 'String (portal name)',
    },
    {
      'name': r'$watch',
      'description': 'Mark a reactive signal dependency for the node.',
      'valueType': 'String (signal path)',
    },
    {
      'name': r'$try',
      'description':
          'Error boundary shorthand. Maps to hook:error_boundary slots.',
      'valueType': 'Node',
    },
    {
      'name': r'$layout',
      'description':
          'Named-area CSS-grid-style layout. Rows are ASCII art strings mapping slot names.',
      'valueType': 'List<String> (rows)',
    },
    {
      'name': r'$compose',
      'description':
          'Attach behavior mixins to the node via the `behaviors` prop.',
      'valueType': 'List<String>',
    },
    {
      'name': r'$apply',
      'description': 'Apply prop/style overrides to all direct children.',
      'valueType': 'Map<String, dynamic>',
    },
    {
      'name': r'$scope',
      'description': 'Prefix all descendant bind paths with a namespace scope.',
      'valueType': 'String (scope prefix)',
    },
    {
      'name': r'$spread',
      'description': 'Spread a runtime object into the node\'s props.',
      'valueType': 'String (bind path)',
    },
    {
      'name': r'$throttle',
      'description':
          'Throttle descendant event handling to at most once per N ms.',
      'valueType': 'int (ms)',
    },
    {
      'name': r'$debounce',
      'description': 'Debounce descendant event handling by N ms.',
      'valueType': 'int (ms)',
    },
    {
      'name': r'$parallel',
      'description': 'Fan-out: render up to 8 concurrent child nodes.',
      'valueType': 'List<Node>',
    },
    {
      'name': r'$reactive_map',
      'description': 'Animated diff list — only re-renders changed items.',
      'valueType': 'String | Map',
    },
    {
      'name': r'$classes',
      'description': 'Declare @ClassName shorthand aliases for style strings.',
      'valueType': 'Map<String, String>',
    },
  ];

  /// Returns the static list of all DSL \$-operators the VM compiler supports.
  List<Map<String, String>> dslOperatorsSnapshot() =>
      List<Map<String, String>>.unmodifiable(_dslOperators);

  /// Returns a dynamic snapshot of every registered OmniCore and any
  /// additional plugin whose name matches an omni-core name (e.g., q_omni_manifold).
  /// Keys are the core type names; values contain subtypes + fullTypes + all prop schemas.
  Map<String, dynamic> omniCoresSnapshot() {
    final result = <String, dynamic>{};

    // 1. Start with the canonical static subtypes table
    for (final entry in _omniCoreSubtypes.entries) {
      final name = entry.key;
      final subtypes = entry.value;
      final registryEntry = _registryEntries['plugin:$name'];

      final computedMetadata = _coreFeatureSchema(
        name,
        description: registryEntry?.description ?? 'Omni core: $name',
        tags: registryEntry?.tags.toList() ?? [name, 'core'],
        engine: registryEntry?.engine ?? 'QuantumVM',
      );

      result[name] = <String, dynamic>{
        'subtypes': List<String>.unmodifiable(subtypes),
        'subtypeCount': subtypes.length,
        'fullTypes': <String>[
          name,
          for (final s in subtypes) '$name:$s',
        ],
        ...computedMetadata,
        if (registryEntry != null) ...registryEntry.metadata,
      };
    }

    // 2. Overlay any EXTRA plugins that are not in _omniCoreSubtypes,
    //    so q_omni_manifold and any future define() calls are included.
    for (final pluginEntry in _plugins.entries) {
      final name = pluginEntry.key;
      // Skip sub-type keys (e.g. 'box:row') — they belong to their parent core
      if (name.contains(':')) continue;
      if (result.containsKey(name)) continue;

      final subtypes = _omniCoreSubtypes[name] ?? const <String>[];
      final registryEntry = _registryEntries['plugin:$name'];

      final computedMetadata = _coreFeatureSchema(
        name,
        description: registryEntry?.description ?? 'Omni core: $name',
        tags: registryEntry?.tags.toList() ?? [name, 'core'],
        engine: registryEntry?.engine ?? 'QuantumVM',
      );

      result[name] = <String, dynamic>{
        'subtypes': List<String>.unmodifiable(subtypes),
        'subtypeCount': subtypes.length,
        'fullTypes': <String>[
          name,
          for (final s in subtypes) '$name:$s',
        ],
        ...computedMetadata,
        if (registryEntry != null) ...registryEntry.metadata,
      };
    }

    return Map<String, dynamic>.unmodifiable(result);
  }

  /// Returns a snapshot of all registered aliases with their target type and default props.
  Map<String, dynamic> aliasRegistrySnapshot() {
    final result = <String, dynamic>{};
    for (final entry in _aliases.entries) {
      result[entry.key] = Map<String, dynamic>.unmodifiable(entry.value);
    }
    return Map<String, dynamic>.unmodifiable(result);
  }

  /// Returns a snapshot of all installed design systems with their tokens.
  Map<String, dynamic> designSystemsExportSnapshot() {
    final result = <String, dynamic>{};
    for (final entry in _designSystems.entries) {
      final bundle = entry.value;
      result[entry.key] = bundle.toMap();
    }
    return Map<String, dynamic>.unmodifiable(result);
  }

  /// Returns a merged snapshot of all design-system tokens, keyed by token name.
  /// Later-installed design systems overwrite earlier ones for duplicate token names.
  Map<String, dynamic> themeConfigSnapshot() {
    final tokens = <String, dynamic>{};
    for (final bundle in _designSystems.values) {
      tokens.addAll(bundle.tokens);
    }
    return <String, dynamic>{
      'tokens': Map<String, dynamic>.unmodifiable(tokens),
      'designSystemIds': List<String>.unmodifiable(_designSystems.keys),
    };
  }

  static List<String> _asStringList(dynamic raw) {
    if (raw is List)
      return raw.map((e) => e.toString()).toList(growable: false);
    if (raw is Set) return raw.map((e) => e.toString()).toList(growable: false);
    if (raw is String && raw.isNotEmpty) return [raw];
    return const [];
  }

  static String _inferPluginKind(QLPlugin p) {
    if (p is QLLayoutCapability) return 'layout';
    if (p is QLWidgetCapability) return 'widget';
    if (p is QLSliverCapability) return 'sliver';
    if (p is QLGraphicsCapability) return 'graphics';
    if (p is QLKineticCapability) return 'kinetic';
    if (p is QLSensorCapability) return 'sensor';
    return 'plugin';
  }

  static String _inferPluginDescription(QLPlugin p) =>
      '${p.runtimeType} (${_inferPluginKind(p)})';

  static List<String> _inferPluginTags(QLPlugin p) {
    final tags = <String>[_inferPluginKind(p)];
    if (p is QLWidgetCapability) tags.add('widget');
    if (p is QLLayoutCapability) tags.add('layout');
    if (p is QLSliverCapability) tags.add('sliver');
    if (p is QLGraphicsCapability) tags.add('graphics');
    if (p is QLKineticCapability) tags.add('kinetic');
    if (p is QLSensorCapability) tags.add('sensor');
    return List<String>.unmodifiable(tags.toSet());
  }

  static Map<String, dynamic> _inferPluginMetadata(QLPlugin p) {
    return {
      'defaultProps': p.defaultProps,
      'capabilities': _inferPluginTags(p),
      'runtimeType': p.runtimeType.toString(),
    };
  }

  QLPlugin? getPlugin(String type) => _plugins[type];

  QToken compileStyle(String style) {
    final normalized = mergeStyleTokens([style]);
    return _styleTokens.getOrPut(
      normalized,
      () {
        try {
          return QEngine.instance.compiler.compile(normalized);
        } on StateError {
          QEngine.instance.initialize();
          return QEngine.instance.compiler.compile(normalized);
        }
      },
      weight: normalized.length + 64,
    );
  }

  void dispose() {
    try {
      _workerPool?.dispose();
    } catch (_) {}
    try {
      _compositor?.dispose();
    } catch (_) {}
    _workerPool = null;
    _compositor = null;
    _isInitialized = false;
    _actionGenerations.clear();
    _globalActionDepth = 0;
    _defaultSlotNodes.clear();
    _aliases.clear();
    _plugins.clear();
    _actions.clear();
    _registryEntries.clear();
    _slotDefaults.clear();
    _debouncers.values.forEach((t) => t.cancel());
    _debouncers.clear();
    _middlewares = [];
    QLSliceRegistry.actionRegistrar = null;
    clearRuntimeCaches();
  }

  QLLazySchemaView lazySchema(String id, Map<String, dynamic> schema) =>
      QLLazySchemaView(id, schema, cache: schemaSlices);

  QLModuleRecord registerModule(Map<String, dynamic> manifest, {String? id}) =>
      QLModuleRegistry.instance.register(manifest, id: id);

  Future<void> bootstrapModule(Map<String, dynamic> manifest,
      {BuildContext? context, String? id}) {
    registerModule(manifest, id: id);
    return QuantumDataOrchestrator.bootstrap(manifest, context);
  }

  dynamic modulePart(String moduleId, Object path,
          {String requester = 'default', String? ownerId}) =>
      QLModuleRegistry.instance
          .section(moduleId, path, requester: requester, ownerId: ownerId);

  Map<String, dynamic> moduleMacros(String moduleId, {String? ownerId}) =>
      QLModuleRegistry.instance.macrosFor(moduleId, ownerId: ownerId);

  Future<Map<String, dynamic>> loadLocalManifest(String assetPath,
      {bool useCache = true}) async {
    if (useCache) {
      final cached = _localManifests.get(assetPath);
      if (cached != null) return cached;
    }

    final rawString = await rootBundle.loadString(assetPath, cache: useCache);

    final Map<String, dynamic> manifest = await QLIsolateBridge.safeRun(() {
      final parsed = QLFormatParser.parse(rawString);
      if (parsed.isEmpty) {
        throw QuantumSecurityException(
            'Manifest at $assetPath parsed to an empty or invalid structure.');
      }
      return parsed;
    });

    if (useCache) {
      _localManifests.put(assetPath, manifest,
          weight: rawString.length + QLRuntimeCacheSizer.estimate(manifest));
    }
    return manifest;
  }

  Future<QLBlueprint> compileStringAsync(
    String rawData, {
    Map<String, dynamic> macros = const {},
    Map<String, dynamic> env = const {},
  }) async {
    final int cacheKey = rawData.hashCode;
    final cached = QLCompiler._blueprintCache.get(cacheKey);
    if (cached != null) return cached;

    final Map<String, dynamic> safeMap = await QLIsolateBridge.safeRun(() {
      return QLFormatParser.parse(rawData);
    });

    final uiNode =
        safeMap['ui'] ?? safeMap['view'] ?? safeMap['template'] ?? safeMap;

    final blueprint = await QLCompiler.compileAsync(uiNode, macros, env);

    QLCompiler._blueprintCache.put(cacheKey, blueprint);
    return blueprint;
  }

  Future<QLBlueprint> warmManifestCache(
    Map<String, dynamic> manifest, {
    Map<String, dynamic> macros = const {},
    Map<String, dynamic> env = const {},
  }) {
    final uiNode = manifest['ui'] ?? manifest;
    final compileEnv = manifest['env'] is Map
        ? <String, dynamic>{
            ...Map<String, dynamic>.from(manifest['env'] as Map),
            ...env,
          }
        : env;
    return QLCompiler.compileAsync(uiNode, macros, compileEnv);
  }

  void clearRuntimeCaches({
    bool compiler = true,
    bool style = true,
    bool schema = true,
    bool state = true,
  }) {
    if (compiler) QLCompiler.clearCaches();
    if (style) _styleTokens.clear();
    if (schema) schemaSlices.clear();
    if (compiler) _localManifests.clear();
    if (compiler) QLModuleRegistry.instance.clear();
    if (state) {
      store.clearCache();
      // Since stores are managed in QLStoreRegistry, we might need a method there to clear caches.
      // Assuming QLStoreRegistry exposes its internal stores or has a clearCaches method.
    }
  }

  Map<String, Map<String, int>> runtimeCacheStats() {
    final compilerStats =
        QLCompiler.cacheStats().map((k, v) => MapEntry(k, v.toMap()));
    return {
      ...compilerStats,
      'style': _styleTokens.stats.toMap(),
      'localManifests': _localManifests.stats.toMap(),
      'modules': QLModuleRegistry.instance.cacheStats.toMap(),
      'schemaSlices': schemaSlices.stats.toMap(),
      'state': store.cacheStats.toMap(),
    };
  }

  Future<void> triggerActions(List<dynamic>? actionList, BuildContext? ctx,
      {Map<String, dynamic>? env}) async {
    if (actionList == null) return;

    _globalActionDepth++;
    if (_globalActionDepth > 50) {
      _globalActionDepth = 0;
      throw const QuantumSecurityException(
          'Action Guard: Maximum execution limits exceeded (50 levels).');
    }

    try {
      final Map<String, dynamic> pipelineEnv = env ??
          Map<String, dynamic>.from(
              (ctx != null && ctx.mounted) ? QLDataScope.of(ctx) : const {});

      final QLDataStore contextStore =
          ctx != null ? QLDataScope.resolveStore(ctx) : store;
      final Stopwatch watchdog = Stopwatch()..start();
      int executionCount = 0;

      final String chainId = actionList.toString().hashCode.toString();
      final int currentGen = (_actionGenerations[chainId] ?? 0) + 1;
      _actionGenerations[chainId] = currentGen;

      for (final def in actionList) {
        if (++executionCount > 100 || watchdog.elapsedMilliseconds > 250) {
          throw QuantumSecurityException(
              'Action Guard: Maximum execution limits exceeded (${watchdog.elapsedMilliseconds}ms / $executionCount calls).');
        }

        if (_actionGenerations[chainId] != currentGen) {
          if (kDebugMode) {
            debugPrint('QuantumVM: Aborted stale async action chain.');
          }
          return;
        }

        String? actionName;
        Map<String, dynamic> actionMap = {};

        if (def is List && def.isNotEmpty) {
          actionName = def[0].toString();
          if (def.length > 1 && def[1] is Map) {
            actionMap = Map<String, dynamic>.from(def[1]);
          }
        } else if (def is Map) {
          actionMap = Map<String, dynamic>.from(def);
          actionName = actionMap.remove('action')?.toString();
        }

        if (actionName == null || !_actions.containsKey(actionName)) {
          print(
              'ACTION SKIP: actionName=$actionName, hasKey=${_actions.containsKey(actionName)}');
          continue;
        }

        print('ACTION EXECUTING: $actionName');

        final Map<String, dynamic> payload = actionMap.map((k, v) => MapEntry(
            k, QLDataBinder.resolveAOT(v, ctx, pipelineEnv, contextStore)));

        dynamic actionResult;
        Future<void> executeChain(int index) async {
          if (index < _middlewares.length) {
            await _middlewares[index](
                actionName!, payload, () => executeChain(index + 1));
          } else {
            actionResult = await _actions[actionName!]!.execute(
                payload, contextStore, ctx ?? const _QEEDummyContext());
          }
        }

        try {
          final int debounceMs = actionMap['debounce'] as int? ?? 0;
          if (debounceMs > 0) {
            final int hash = def.toString().hashCode;
            _debouncers[hash]?.cancel();
            final Completer<void> completer = Completer<void>();
            _debouncers[hash] =
                Timer(Duration(milliseconds: debounceMs), () async {
              try {
                if (_actionGenerations[chainId] == currentGen) {
                  await executeChain(0);
                }
                completer.complete();
              } catch (e, st) {
                completer.completeError(e, st);
              }
            });
            await completer.future;
          } else {
            await executeChain(0);
          }

          if (_actionGenerations[chainId] != currentGen) return;

          pipelineEnv['\$lastResult'] = actionResult;
        } catch (e, st) {
          if (actionMap['onError'] != null) {
            pipelineEnv['\$error'] = e.toString();
            await triggerActions(actionMap['onError'] as List<dynamic>, ctx,
                env: pipelineEnv);
            break;
          }
          Error.throwWithStackTrace(e, st);
        }
      }
      watchdog.stop();
    } finally {
      _globalActionDepth--;
    }
  }

  Widget renderWidget(BuildContext ctx, QLBlueprint node, {String? keySuffix}) {
    var hints = _renderHints[node];
    if (hints == null) {
      hints = _QLRenderHints(
        hasDeps: node.style?.contains('{{') == true || _hasTokens(node.props),
      );
      _renderHints[node] = hints;
    }

    final decision = _nodePermissionDecision(ctx, node);
    if (!decision.allowed) {
      return const SizedBox.shrink();
    }

    if (hints.hasDeps) {
      return _QLReactiveNodeBoundary(node: node, keySuffix: keySuffix);
    }
    return _assembleNode(ctx, node, QLDataScope.of(ctx),
        QLDataScope.resolveStore(ctx), keySuffix);
  }

  bool _hasTokens(dynamic target) {
    if (target is String) return target.contains('{{');
    if (target is Map) {
      if (target['_isTokenized'] == true) return true;
      for (final v in target.values) {
        if (_hasTokens(v)) return true;
      }
    }
    if (target is List) {
      for (final v in target) {
        if (_hasTokens(v)) return true;
      }
    }
    return false;
  }

  Widget _assembleNode(BuildContext ctx, QLBlueprint node,
      Map<String, dynamic> env, QLDataStore store, String? keySuffix) {
    if (node.props.containsKey(r'$if')) {
      final dynamic condition =
          QLDataBinder.resolveAOT(node.props[r'$if'], ctx, env, store);
      if (condition == false ||
          condition == 'false' ||
          condition == 0 ||
          condition == '0' ||
          condition == null ||
          condition == '') {
        return const SizedBox.shrink();
      }
    }

    String nodeType = node.type.toString();
    final aliasDef = getAlias(nodeType);
    if (aliasDef != null) nodeType = aliasDef['type'].toString();

    final String nodeBaseType =
        nodeType.contains(':') ? nodeType.split(':').first : nodeType;
    final String renderType = nodeBaseType;

    final QLPlugin? plugin = _plugins[renderType];
    final _QLComponentDefinition? nativeComponent =
        _componentDefinitionsByName[renderType];
    final QuantumComponentBuilder? componentBuilder = null;

    const Set<String> nativeTypes = {
      'row',
      'col',
      'column',
      '->',
      'v',
      'wrap',
      'center',
      'stack',
      'grid',
      'grid_item',
      'wrapper',
      'empty'
    };

    if (nativeComponent != null && plugin == null) {
      return _QLComponentRuntimeHost(
        definition: nativeComponent,
        sourceNode: node,
        sourceCtx: _AliasContext(QLContext(ctx, node, env, store)),
      );
    }

    Widget content = const SizedBox.shrink();

    final String reactiveStyle =
        QLDataBinder.resolveAOT(node.props['style'], ctx, env, store)
                ?.toString() ??
            '';
    final String baseStyle = node.style ?? '';
    final String resolvedStyle = '$baseStyle $reactiveStyle'.trim();

    List<Widget> buildChildren() {
      return node.children
          .map((c) => renderWidget(ctx, c))
          .toList(growable: false);
    }

    if (plugin != null) {
      if (plugin is QLComputeCapability) {
        return _QLHeadlessComputeNode(
            node: node,
            capability: plugin as QLComputeCapability,
            store: store,
            workerPool: workerPool);
      }
      if (plugin is QLGraphicsCapability) {
        final drawFn = (plugin as QLGraphicsCapability)
            .buildFragment(QLContext(ctx, node, env, store), node, store);
        content = QLSceneLayerWidget(
            isComplex: true,
            willChange: true,
            builder: (context, layer) {
              layer.update(node.hashCode, drawFn);
              return const SizedBox.shrink();
            });
      } else if (plugin is QLKineticCapability) {
        content = (plugin as QLKineticCapability).buildKinetic(
            QLContext(ctx, node, env, store), node, compositor, store);
      } else if (plugin is QLWidgetCapability) {
        content = (plugin as QLWidgetCapability).buildWidget(ctx, node, store);
      } else if (plugin is QLSliverCapability) {
        content = CustomScrollView(slivers: [
          (plugin as QLSliverCapability).buildSliver(ctx, node, store)
        ]);
      } else if (plugin is QLLayoutCapability) {
        content = (plugin as QLLayoutCapability)
            .buildLayout(ctx, node, buildChildren(), store);
      }
      if (plugin is QLSensorCapability) {
        content = (plugin as QLSensorCapability).buildSensor(
            QLContext(ctx, node, env, store), node, content, store);
      }
    } else if (componentBuilder != null) {
      content = componentBuilder(ctx, node, store);
    } else {
      final children = buildChildren();

      // 🚀 EXTRACT TAP & TEXT NATIVELY
      final QLContext nodeCtx = QLContext(ctx, node, env, store);
      final VoidCallback? tapHandler = nodeCtx.action('onClick') ??
          nodeCtx.action('onTap') ??
          nodeCtx.action('action');
      final String? nodeText =
          QLDataBinder.resolveAOT(node.props['text'], ctx, env, store)
              ?.toString();

      if (renderType == 'grid' || renderType == 'masonry') {
        final layout = node.props['layout'] as Map? ?? {};
        final cols = node.props['gridCols'] ?? layout['cols'] ?? '1fr 1fr';
        final rows = node.props['gridRows'] ?? layout['rows'] ?? 'auto';
        final dynamic gapProp =
            QLDataBinder.resolveAOT(node.props['gap'], ctx, env, store) ??
                layout['gap'];
        final num gap = gapProp is num
            ? gapProp
            : (num.tryParse(gapProp?.toString() ?? '') ?? 0);

        content = Q(
          '$renderType grid-cols-$cols grid-rows-$rows $resolvedStyle',
          gap: gap > 0 ? gap : null,
          text: nodeText,
          onTap: tapHandler,
          children: children.isEmpty ? null : children,
          suppressParentData: true,
        );
      } else if (renderType == 'grid_item') {
        Widget inner = children.firstOrNull ?? const SizedBox.shrink();
        if (tapHandler != null) {
          inner = GestureDetector(
              onTap: tapHandler,
              behavior: HitTestBehavior.opaque,
              child: inner);
        }
        content = QuantumItem(
          rowStart: (node.props['rowStart'] as num?)?.toInt() ?? 0,
          rowEnd: (node.props['rowEnd'] as num?)?.toInt() ?? 0,
          colStart: (node.props['colStart'] as num?)?.toInt() ?? 0,
          colEnd: (node.props['colEnd'] as num?)?.toInt() ?? 0,
          rowSpan: (node.props['rowSpan'] as num?)?.toInt() ?? 1,
          colSpan: (node.props['colSpan'] as num?)?.toInt() ?? 1,
          zIndex: (node.props['zIndex'] as num?)?.toInt() ?? 0,
          alignSelf: QAlign.stretch,
          justifySelf: QAlign.stretch,
          child: inner,
        );
      } else if (renderType == 'empty') {
        content = const SizedBox.shrink();
      } else {
        String combinedStyle = resolvedStyle;
        if (renderType == 'row' || renderType == '->')
          combinedStyle = 'row $combinedStyle';
        if (renderType == 'col' || renderType == 'column' || renderType == 'v')
          combinedStyle = 'col $combinedStyle';
        if (renderType == 'wrap') combinedStyle = 'wrap $combinedStyle';
        if (renderType == 'center')
          combinedStyle = 'flex-center $combinedStyle';

        final String justify =
            QLDataBinder.resolveAOT(node.props['justify'], ctx, env, store)
                    ?.toString() ??
                '';
        final String items =
            QLDataBinder.resolveAOT(node.props['items'], ctx, env, store)
                    ?.toString() ??
                '';
        final bool clip =
            QLDataBinder.resolveAOT(node.props['clip'], ctx, env, store) ==
                true;
        final dynamic gapProp =
            QLDataBinder.resolveAOT(node.props['gap'], ctx, env, store);
        final num gap = gapProp is num
            ? gapProp
            : (num.tryParse(gapProp?.toString() ?? '') ?? 0);

        if (justify.isNotEmpty)
          combinedStyle = '$combinedStyle justify-$justify';
        if (items.isNotEmpty) combinedStyle = '$combinedStyle items-$items';
        if (clip) combinedStyle = '$combinedStyle overflow-hidden';

        content = Q(combinedStyle,
            text: nodeText,
            gap: gap > 0 ? gap : null,
            onTap: tapHandler,
            children: children.isEmpty ? null : children,
            suppressParentData: true);
      }
    }

    // 🚀 UNIVERSAL PLUGIN TAP FALLBACK
    if (plugin != null && renderType != 'action') {
      final QLContext nodeCtx = QLContext(ctx, node, env, store);
      final VoidCallback? tapHandler = nodeCtx.action('onClick') ??
          nodeCtx.action('onTap') ??
          nodeCtx.action('action');
      if (tapHandler != null) {
        content = GestureDetector(
          onTap: tapHandler,
          behavior: HitTestBehavior.opaque,
          child: content,
        );
      }
    }

    final String? nodeId = node.props['id'] ?? node.props['key'];
    if (nodeId != null || keySuffix != null) {
      content = KeyedSubtree(
          key: ValueKey('${nodeId ?? ''}_${keySuffix ?? ''}'), child: content);
    }

    return content;
  }
}

class QuantumVMRoot extends StatefulWidget {
  final Widget child;
  final int workerThreads;

  const QuantumVMRoot({super.key, required this.child, this.workerThreads = 4});

  @override
  State<QuantumVMRoot> createState() => _QuantumVMRootState();
}

class _QuantumVMRootState extends State<QuantumVMRoot>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    QuantumVM.instance.initialize(workerThreads: widget.workerThreads);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) QuantumVM.instance.attachCompositor(this);
    });
  }

  @override
  void dispose() {
    try {
      QuantumVM.instance.compositor.dispose();
    } catch (_) {}
    try {
      QuantumVM.instance.workerPool.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 FOREVER FIX: One AnimatedBuilder for the entire app!
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: QEngine.instance.tick,
        builder: (context, child) => widget.child,
      ),
    );
  }
}

class _QLHeadlessComputeNode extends StatefulWidget {
  final QLBlueprint node;
  final QLComputeCapability capability;
  final QLDataStore store;
  final QLWorkerPool workerPool;

  const _QLHeadlessComputeNode({
    required this.node,
    required this.capability,
    required this.store,
    required this.workerPool,
  });

  @override
  State<_QLHeadlessComputeNode> createState() => _QLHeadlessComputeNodeState();
}

class _QLHeadlessComputeNodeState extends State<_QLHeadlessComputeNode> {
  QLAsyncSignal<dynamic>? _signal;

  @override
  void initState() {
    super.initState();
    _executeTask();
  }

  void _executeTask() {
    final ctx = QLContext(context, widget.node,
        QLDataScope.ofNode(context)?.localData ?? const {}, widget.store);
    final task = widget.capability.buildTask(ctx, widget.node);
    final input = widget.capability.buildInput(ctx, widget.node);

    _signal = widget.workerPool.submit(task, input);

    _signal!.data.addListener(() {
      if (_signal!.data.value != null && mounted) {
        widget.capability
            .onTaskCompleted(ctx, _signal!.data.value, widget.store);
      }
    });
  }

  @override
  void dispose() {
    _signal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class QLContext {
  final BuildContext flutterContext;
  final QLBlueprint node;
  final Map<String, dynamic> env;
  final QLDataStore store;

  final Map<String, dynamic> _propCache = {};

  QLContext(this.flutterContext, this.node, this.env, this.store);

  T prop<T>(String key, {T? fallback}) {
    if (_propCache.containsKey(key)) {
      final cached = _propCache[key];
      if (cached is T) return cached;
    }

    final dynamic raw = node.props[key];
    if (raw == null) return _returnFallback<T>(fallback);

    final dynamic resolved =
        QLDataBinder.resolveAOT(raw, flutterContext, env, store);
    if (resolved == null) return _returnFallback<T>(fallback);

    if (resolved is T) {
      _propCache[key] = resolved;
      return resolved;
    }

    final T? coerced = _coerceType<T>(resolved);
    if (coerced != null) {
      _propCache[key] = coerced;
      return coerced;
    }

    return _returnFallback<T>(fallback);
  }

  String string(String key, {String fallback = ''}) =>
      prop<String>(key, fallback: fallback);
  double number(String key, {double fallback = 0.0}) =>
      prop<double>(key, fallback: fallback);
  Color? color(String key, {Color? fallback}) {
    final raw = prop<dynamic>(key);
    if (raw == null) return fallback;
    if (raw is Color) return raw;
    if (raw is int) return Color(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        int c = QLParserUtils.parseColor(raw, 0, raw.length);
        if (c == 0) return fallback;
        return Color(c);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  bool boolean(String key, {bool fallback = false}) =>
      prop<bool>(key, fallback: fallback);
  int integer(String key, {int fallback = 0}) =>
      prop<int>(key, fallback: fallback);
  List<dynamic> list(String key, {List<dynamic> fallback = const []}) =>
      List<dynamic>.from(prop<List>(key, fallback: fallback));

  VoidCallback? action(String eventKey, {Map<String, dynamic>? localPayload}) {
    dynamic rawActions = node.props[eventKey];

    // Allow both the legacy list form and the newer single-action map form.
    List<dynamic>? actions;
    if (rawActions is List) {
      actions = rawActions;
    } else if (rawActions is Map) {
      actions = <dynamic>[Map<String, dynamic>.from(rawActions)];
    }

    // 🚀 FALLBACK LOGIC: If looking for onClick, also check onTap and action.
    if (actions == null) {
      final eventsMap = node.props['events'];
      if (eventsMap is Map) {
        final rawEventActions = eventsMap[eventKey];
        if (rawEventActions is List) {
          actions = rawEventActions;
        } else if (rawEventActions is Map) {
          actions = <dynamic>[Map<String, dynamic>.from(rawEventActions)];
        }
      }
    }

    if (actions == null && eventKey == 'onClick') {
      final onTap = node.props['onTap'];
      final action = node.props['action'];
      if (onTap is List) {
        actions = onTap;
      } else if (onTap is Map) {
        actions = <dynamic>[Map<String, dynamic>.from(onTap)];
      } else if (action is List) {
        actions = action;
      } else if (action is Map) {
        actions = <dynamic>[Map<String, dynamic>.from(action)];
      }
    }

    if (actions == null) return null;

    return () => QuantumVM.instance.triggerActions(actions!, flutterContext,
        env: {...env, ...?localPayload});
  }

  Map<K, V> map<K, V>(String key, {Map<K, V> fallback = const {}}) =>
      prop<Map<K, V>>(key, fallback: fallback);

  QLLazySchemaView schema(String key, {String? id}) {
    final raw = prop<Map<String, dynamic>>(key, fallback: const {});
    final schemaId = id ??
        '${node.debugPath}:$key:${node.props[key] == null ? 0 : QLStableHasher.of(node.props[key])}';
    return QuantumVM.instance.lazySchema(schemaId, raw);
  }

  Map<String, dynamic> schemaFields(String key, Iterable<String> fields,
          {String? id}) =>
      schema(key, id: id).pick(fields);

  Map<String, dynamic> schemaField(String key, String field, {String? id}) =>
      schema(key, id: id).field(field)?.definition ?? const {};

  E enumValue<E extends Enum>(String key, List<E> values,
      {required E fallback}) {
    final raw = string(key);
    if (raw.isEmpty) return fallback;
    return values.firstWhere((e) => e.name.toLowerCase() == raw.toLowerCase(),
        orElse: () => fallback);
  }

  List<Widget> get children => node.children
      .where((c) => c.props['slot'] == null)
      .map((c) => QuantumVM.instance.renderWidget(flutterContext, c))
      .toList();

  Widget? slot(String slotName) {
    final QLBlueprint? childNode = node.slots[slotName] ??
        node.children.where((c) => c.props['slot'] == slotName).firstOrNull;
    if (childNode != null) {
      final Map<String, dynamic> resolvedProps = {};
      node.props.forEach((k, v) {
        resolvedProps[k] =
            QLDataBinder.resolveAOT(v, flutterContext, env, store);
      });
      return QLDataScope(
        localData: {...env, ...resolvedProps},
        moduleStore: store,
        child: QuantumVM.instance.renderWidget(flutterContext, childNode),
      );
    }
    return null;
  }

  T _returnFallback<T>(T? fallback) {
    if (fallback != null) return fallback;
    if (null is T) return null as T;
    if (T == String) return '' as T;
    if (T == double) return 0.0 as T;
    if (T == int) return 0 as T;
    if (T == bool) return false as T;
    throw ArgumentError(
        'Required SDUI property of type $T was null and no fallback was provided.');
  }

  T? _coerceType<T>(dynamic resolved) {
    final String str = resolved.toString().trim();
    if (T == String) return str as T;
    if (T == double) {
      if (resolved is num) return resolved.toDouble() as T;
      return (double.tryParse(str) ?? int.tryParse(str)?.toDouble()) as T?;
    }
    if (T == int) {
      if (resolved is num) return resolved.toInt() as T;
      return (int.tryParse(str) ?? double.tryParse(str)?.toInt()) as T?;
    }
    if (T == bool) {
      if (resolved is bool) return resolved as T;
      final lower = str.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on')
        return true as T;
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off')
        return false as T;
      return null;
    }
    if (T == Color) {
      if (resolved is Color) return resolved as T;
      if (resolved is int) return Color(resolved) as T;
      if (resolved is String && str.isNotEmpty) {
        return Color(QLParserUtils.parseColor(str, 0, str.length)) as T;
      }
      return null;
    }
    if (T == List || T == List<dynamic>) {
      if (resolved is List) return resolved as T;
      return [resolved] as T;
    }
    if (T == Map || T == Map<String, dynamic>) {
      if (resolved is Map) return Map<String, dynamic>.from(resolved) as T;
      return null;
    }
    return null;
  }
}

class _QLAutoReactiveNode extends StatefulWidget {
  final QLBlueprint node;
  final Widget Function(QLContext ctx) builder;
  final bool isSliver;

  const _QLAutoReactiveNode(this.node, this.builder, {this.isSliver = false});

  @override
  State<_QLAutoReactiveNode> createState() => _QLAutoReactiveNodeState();
}

class _QLAutoReactiveNodeState extends State<_QLAutoReactiveNode> {
  final Set<String> deps = {};
  Listenable _mergedListenable = _NoopListenable.instance;
  QLDataStore? _resolvedStore;

  @override
  void initState() {
    super.initState();
    _extractDeps(widget.node.props, deps);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = QLDataScope.resolveStore(context);
    if (_resolvedStore != store) {
      _resolvedStore = store;
      _buildSignals();
    }
  }

  void _buildSignals() {
    if (deps.isEmpty || _resolvedStore == null) {
      _mergedListenable = _NoopListenable.instance;
      return;
    }
    final List<Listenable> signals = [];
    for (final d in deps) {
      if (!d.startsWith('item.') && !d.startsWith(r'$env.')) {
        signals.add(_resolvedStore!.signal(d));
      }
    }
    _mergedListenable = Listenable.merge(signals);
  }

  void _extractDeps(dynamic value, Set<String> deps) {
    if (value is Map) {
      if (value['_isTokenized'] == true)
        deps.addAll((value['deps'] as List).cast<String>());
      for (final v in value.values) _extractDeps(v, deps);
    } else if (value is List) {
      for (final v in value) _extractDeps(v, deps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> env =
        QLDataScope.ofNode(context)?.localData ?? const {};
    final QLDataStore store =
        _resolvedStore ?? QLStoreRegistry.instance.defaultStore;

    if (deps.isEmpty) return _buildSafeContent(env, store);

    return AnimatedBuilder(
      animation: _mergedListenable,
      builder: (context, child) => _buildSafeContent(env, store),
    );
  }

  Widget _buildSafeContent(Map<String, dynamic> env, QLDataStore store) {
    try {
      return widget.builder(QLContext(context, widget.node, env, store));
    } catch (e, st) {
      debugPrint('🚨 [QuantumVM] Crash in ${widget.node.type}: $e\n$st');
      return const SizedBox.shrink();
    }
  }
}

class _QLReactiveNodeBoundary extends StatefulWidget {
  final QLBlueprint node;
  final String? keySuffix;
  const _QLReactiveNodeBoundary({required this.node, this.keySuffix});
  @override
  State<_QLReactiveNodeBoundary> createState() =>
      _QLReactiveNodeBoundaryState();
}

class _QLReactiveNodeBoundaryState extends State<_QLReactiveNodeBoundary> {
  final Set<String> deps = {};
  Listenable _mergedListenable = _NoopListenable.instance;

  QLDataStore? _moduleStore;
  QLDataStore? _localStore;

  @override
  void initState() {
    super.initState();
    _extractDeps(widget.node.props, deps);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = QLDataScope.ofNode(context);
    final moduleStore =
        scope?.moduleStore ?? QLStoreRegistry.instance.defaultStore;
    final localStore = scope?.localStore;

    if (_moduleStore != moduleStore || _localStore != localStore) {
      _moduleStore = moduleStore;
      _localStore = localStore;
      _buildSignals();
    }
  }

  void _buildSignals() {
    if (deps.isEmpty) {
      _mergedListenable = _NoopListenable.instance;
      return;
    }

    final List<Listenable> signals = [];
    for (final d in deps) {
      if (d.startsWith('item.') || d.startsWith(r'$env.')) continue;

      if (d.startsWith(r'$local')) {
        if (_localStore != null) {
          signals.add(_localStore!.signal(d.replaceFirst(r'$local.', '')));
        }
        continue;
      }

      if (d.startsWith('@')) {
        final ns = d.substring(1).split('.').first;
        signals.add(QLStoreRegistry.instance
            .get(ns)
            .signal(d.substring(ns.length + 2)));
        continue;
      }

      if (_moduleStore != null) {
        signals.add(_moduleStore!.signal(d));
      }
    }

    _mergedListenable =
        signals.isEmpty ? _NoopListenable.instance : Listenable.merge(signals);
  }

  void _extractDeps(dynamic value, Set<String> deps) {
    if (value is Map) {
      if (value['_isTokenized'] == true)
        deps.addAll((value['deps'] as List).cast<String>());
      for (final v in value.values) _extractDeps(v, deps);
    } else if (value is List) {
      for (final v in value) _extractDeps(v, deps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> env =
        QLDataScope.ofNode(context)?.localData ?? const {};
    final QLDataStore store = _localStore ?? _moduleStore ?? QuantumVM.instance.store;

    Widget content;
    if (deps.isEmpty) {
      content = _buildSafeContent(context, env, store);
    } else {
      content = AnimatedBuilder(
          animation: _mergedListenable,
          builder: (context, child) => _buildSafeContent(context, env, store));
    }
    return content;
  }

  Widget _buildSafeContent(
      BuildContext ctx, Map<String, dynamic> env, QLDataStore store) {
    try {
      TelemetryVMBridge.onReactiveBuild(widget.node.debugPath);
      return QuantumVM.instance
          ._assembleNode(ctx, widget.node, env, store, widget.keySuffix);
    } catch (e, st) {
      debugPrint(
          '🚨 [QuantumVM] Crash in node <${widget.node.type}> at [${widget.node.debugPath}]\nError: $e\n$st');
      return kDebugMode
          ? ErrorWidget('Crash at ${widget.node.debugPath}\n$e')
          : const SizedBox.shrink();
    }
  }
}

extension QuantumVMMicroPlugin on QuantumVM {
  void define(
    String type,
    Widget Function(QLContext ctx) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroWidgetPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineSliver(
    String type,
    Widget Function(QLContext ctx) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroSliverPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineLayout(
    String type,
    Widget Function(QLContext ctx, List<Widget> children) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroLayoutPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineGraphics(
    String type,
    QLFragmentDraw Function(QLContext ctx) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroGraphicsPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineKinetic(
    String type,
    Widget Function(QLContext ctx, QLAnimCompositor compositor) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroKineticPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineSensor(
    String type,
    void Function(QLContext ctx, QLPointerEvent event) onSensorData, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroSensorPlugin(type, onSensorData, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );
}

// ADD THIS HELPER JUST ABOVE THE PLUGINS IF NOT ALREADY THERE
// 🚀 BULLETPROOF STATIC CHECKER
bool _nodeHasTokens(dynamic target) {
  if (target == null) return false;
  if (target is String) return target.contains('{{');
  if (target is Map) {
    if (target['_isTokenized'] == true) return true;
    if (target.containsKey(r'$bind') || target.containsKey('bind')) return true;
    for (final v in target.values) {
      if (_nodeHasTokens(v)) return true;
    }
  }
  if (target is List) {
    for (final v in target) {
      if (_nodeHasTokens(v)) return true;
    }
  }
  return false;
}

// 🚀 THE ULTIMATE STATIC CHECKER
bool _nodeIsReactive(dynamic target) {
  if (target == null) return false;
  if (target is String) return target.contains('{{');
  if (target is Map) {
    if (target['_isTokenized'] == true) return true;
    if (target.containsKey(r'$bind') ||
        target.containsKey('bind') ||
        target.containsKey(r'$if') ||
        target.containsKey(r'$repeat')) return true;
    for (final v in target.values) {
      if (_nodeIsReactive(v)) return true;
    }
  }
  if (target is List) {
    for (final v in target) {
      if (_nodeIsReactive(v)) return true;
    }
  }
  return false;
}

// Inside your MicroPlugins (quantum_vm.dart):
class _MicroWidgetPlugin extends QLPlugin implements QLWidgetCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx) builder;
  _MicroWidgetPlugin(this.type, this.builder, this.defaultProps);

  @override
  Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store) {
    // 🚀 O(1) MEMOIZED CHECK: Kills recursive AST crawling
    if (!QLAstInspector.isReactive(node.props) &&
        !QLAstInspector.isReactive(node.style) &&
        !QLAstInspector.isReactive(node.type)) {
      return builder(QLContext(
          ctx, node, QLDataScope.ofNode(ctx)?.localData ?? const {}, store));
    }
    return _QLAutoReactiveNode(node, builder, isSliver: false);
  }
}

// Apply the exact same _nodeIsReactive check to _MicroSliverPlugin and _MicroLayoutPlugin!
class _MicroSliverPlugin extends QLPlugin implements QLSliverCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx) builder;
  _MicroSliverPlugin(this.type, this.builder, this.defaultProps);

  @override
  Widget buildSliver(BuildContext ctx, QLBlueprint node, QLDataStore store) {
    if (!_nodeHasTokens(node.props) && !_nodeHasTokens(node.style)) {
      return builder(QLContext(
          ctx, node, QLDataScope.ofNode(ctx)?.localData ?? const {}, store));
    }
    return _QLAutoReactiveNode(node, builder, isSliver: true);
  }
}

class _MicroLayoutPlugin extends QLPlugin implements QLLayoutCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx, List<Widget> children) builder;
  _MicroLayoutPlugin(this.type, this.builder, this.defaultProps);

  @override
  Widget buildLayout(BuildContext ctx, QLBlueprint node, List<Widget> children,
      QLDataStore store) {
    return builder(
        QLContext(
            ctx, node, QLDataScope.ofNode(ctx)?.localData ?? const {}, store),
        children);
  }
}

class _MicroGraphicsPlugin extends QLPlugin implements QLGraphicsCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final QLFragmentDraw Function(QLContext ctx) builder;
  _MicroGraphicsPlugin(this.type, this.builder, this.defaultProps);
  @override
  QLFragmentDraw buildFragment(
          QLContext ctx, QLBlueprint node, QLDataStore store) =>
      builder(ctx);
}

class _MicroKineticPlugin extends QLPlugin implements QLKineticCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx, QLAnimCompositor compositor) builder;
  _MicroKineticPlugin(this.type, this.builder, this.defaultProps);
  @override
  Widget buildKinetic(QLContext ctx, QLBlueprint node,
          QLAnimCompositor compositor, QLDataStore store) =>
      builder(ctx, compositor);
}

class _MicroSensorPlugin extends QLPlugin implements QLSensorCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final void Function(QLContext ctx, QLPointerEvent event) onSensorData;
  _MicroSensorPlugin(this.type, this.onSensorData, this.defaultProps);
  @override
  Widget buildSensor(
      QLContext ctx, QLBlueprint node, Widget child, QLDataStore store) {
    return QLOmniSensor(
        onTouchUpdate: (event) => onSensorData(ctx, event), child: child);
  }
}

abstract final class QLRouteBuilder {
  static QLRoute localJson({
    required String path,
    required Map<String, dynamic> Function(QLRouteInfo) schemaBuilder,
    Map<String, dynamic> macros = const {},
    QLTransitionType transition = QLTransitionType.slideRight,
  }) {
    return QLRoute(
      path: path,
      transition: transition,
      builder: (context, info) => QLSmartView(
        manifest: schemaBuilder(info),
        macros: macros,
        routeInfo: info,
      ),
    );
  }

  static QLRoute localJsonAsset({
    required String path,
    required String assetPath,
    Map<String, dynamic> macros = const {},
    Widget? loadingWidget,
    QLTransitionType transition = QLTransitionType.slideRight,
  }) {
    return QLRoute(
      path: path,
      transition: transition,
      builder: (context, info) => FutureBuilder<Map<String, dynamic>>(
        future: QuantumVM.instance.loadLocalManifest(assetPath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return loadingWidget ?? const SizedBox.shrink();
          }
          return QLSmartView(
            manifest: snapshot.data!,
            macros: macros,
            routeInfo: info,
            loadingWidget: loadingWidget,
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // NEW INJECTION: UNIVERSAL ROUTE BUILDER (quantum_navigation_engine.dart)
  // ════════════════════════════════════════════════════════════════════════════

  static QLRoute localAsset({
    required String path,
    required String assetPath,
    Map<String, dynamic> macros = const {},
    Widget? loadingWidget,
    QLTransitionType transition = QLTransitionType.slideRight,
  }) {
    return QLRoute(
      path: path,
      transition: transition,
      builder: (context, info) => FutureBuilder<Map<String, dynamic>>(
        future: QuantumVM.instance.loadLocalManifest(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Load Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return loadingWidget ?? const SizedBox.shrink();
          }
          return QLSmartView(
            manifest: snapshot.data!,
            macros: macros,
            routeInfo: info,
            loadingWidget: loadingWidget,
          );
        },
      ),
    );
  }
}

class QLSmartView extends StatefulWidget {
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> macros;
  final Widget? loadingWidget;
  final QLRouteInfo? routeInfo;

  /// Called when manifest bootstrap/compilation throws. If omitted, a
  /// minimal built-in error widget is shown in debug mode (so failures are
  /// impossible to miss during development) and, in release mode, the
  /// previous [loadingWidget] state is kept -- matching this widget's old
  /// (silent) behavior for release builds by default, but now the error is
  /// always still reported via [QLErrorBoundaryScope] and [onCompileError]
  /// regardless of which UI path is shown.
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;

  /// Called whenever manifest bootstrap/compilation throws, in addition to
  /// (not instead of) reporting to the nearest [QLErrorBoundaryScope] if one
  /// is present. Use this to log/report even when you don't need custom
  /// error UI.
  final void Function(Object error, StackTrace stackTrace)? onCompileError;

  QLSmartView({
    super.key,
    Map<String, dynamic>? manifest,
    Map<String, dynamic>? schema,
    this.macros = const {},
    this.loadingWidget,
    this.routeInfo,
    this.errorBuilder,
    this.onCompileError,
  })  : assert(manifest != null || schema != null,
            'QLSmartView requires either manifest or schema.'),
        manifest = manifest ?? schema!;

  @override
  State<QLSmartView> createState() => _QLSmartViewState();
}

class _QLSmartViewState extends State<QLSmartView> {
  QLBlueprint? _compiledAST;
  Object? _compileError;
  StackTrace? _compileStackTrace;

  @override
  void reassemble() {
    super.reassemble();
    _processManifest();
  }

  @override
  void initState() {
    super.initState();
    _processManifest();
  }

  @override
  void didUpdateWidget(covariant QLSmartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final manifestChanged = !identical(widget.manifest, oldWidget.manifest);
    final macrosChanged = !mapEquals(widget.macros, oldWidget.macros);
    final routeChanged = widget.routeInfo != oldWidget.routeInfo;
    if (manifestChanged || macrosChanged || routeChanged) {
      _processManifest();
    }
  }

  Future<void> _processManifest() async {
    try {
      await QuantumDataOrchestrator.bootstrap(widget.manifest, context);

      final uiNode = widget.manifest['ui'] ?? widget.manifest;
      final Map<String, dynamic> compileEnv = widget.manifest['env'] is Map
          ? Map<String, dynamic>.from(widget.manifest['env'])
          : {};

      if (widget.routeInfo != null) {
        compileEnv[r'$route'] = {
          'path': widget.routeInfo!.path,
          'param': widget.routeInfo!.params,
          'query': widget.routeInfo!.queryParams,
        };
      }

      final int ticket = TelemetryVMBridge.beginSmartViewCompile(
          widget.manifest['id']?.toString() ?? 'view');
      final QLBlueprint ast =
          await QLCompiler.compileAsync(uiNode, widget.macros, compileEnv);
      TelemetryVMBridge.endSmartViewCompile(ticket);
      if (mounted) {
        setState(() {
          _compiledAST = ast;
          _compileError = null;
          _compileStackTrace = null;
        });
      }
    } catch (e, st) {
      // Previously: print(e); print(st); -- with nothing else. That left
      // this widget stuck on `loadingWidget` forever with zero way for the
      // app (or a human debugging it) to discover a manifest failed to
      // compile short of reading raw console output.
      if (kDebugMode) {
        debugPrint('🚨 QuantumVM Compilation Error: $e');
        debugPrintStack(stackTrace: st);
      }
      widget.onCompileError?.call(e, st);
      // Route into the framework's existing error-boundary mechanism if
      // this QLSmartView happens to be inside one, so ancestor retry/UI
      // logic (QLErrorBoundary) can react the same way it would to any
      // other subtree error.
      QLErrorBoundaryScope.maybeOf(context)?.report(
        e,
        stackTrace: st,
        context: 'QLSmartView(${widget.manifest['id'] ?? 'unknown'})',
      );
      if (mounted) {
        setState(() {
          _compileError = e;
          _compileStackTrace = st;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_compileError != null) {
      final err = _compileError!;
      final st = _compileStackTrace ?? StackTrace.empty;
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(err, st);
      }
      if (kDebugMode) {
        // No custom errorBuilder was given: fail loudly in debug so this
        // is never mistaken for "still loading" during development.
        return Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF3A0000),
          child: Text(
            'QLSmartView failed to compile manifest '
            '"${widget.manifest['id'] ?? ''}":\n$err',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }
      // Release build, no errorBuilder provided: preserve the previous
      // (silent-to-the-UI) behavior rather than surprising an app that
      // hasn't opted into custom error UI -- the error is still reported
      // above via onCompileError / QLErrorBoundaryScope either way.
      return widget.loadingWidget ?? const SizedBox.shrink();
    }
    if (_compiledAST == null)
      return widget.loadingWidget ?? const SizedBox.shrink();

    final Map<String, dynamic> rootData = {};
    if (widget.routeInfo != null) {
      rootData['\$route'] = {
        'path': widget.routeInfo!.path,
        'param': widget.routeInfo!.params,
        'query': widget.routeInfo!.queryParams,
      };
    }

    return QLDataScope(
      moduleStore:
          QLStoreRegistry.instance.get(widget.manifest['module'] ?? 'default'),
      localData: rootData,
      child: QuantumVM.instance.renderWidget(context, _compiledAST!),
    );
  }
}

class _QLRenderHints {
  final bool hasDeps;
  const _QLRenderHints({required this.hasDeps});
}

class _GridRect {
  int minR, minC, maxR, maxC;
  _GridRect(this.minR, this.minC, this.maxR, this.maxC);
}

class _NoopListenable implements Listenable {
  const _NoopListenable._();
  static const _NoopListenable instance = _NoopListenable._();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

// ════════════════════════════════════════════════════════════════════════════
// QEE INSPECTION EXTENSIONS  (added for quantum_embodiment_engine.dart)
// These are thin read-only views — they never mutate VM state.
// ════════════════════════════════════════════════════════════════════════════

/// Extension exposing read-only inspector APIs on [QuantumVM] for the QEE.
extension QuantumVMInspector on QuantumVM {
  /// All registered action names.
  List<String> get registeredActionNames =>
      List<String>.unmodifiable(_actions.keys);

  /// All registered plugin type names.
  List<String> get registeredPluginNames =>
      List<String>.unmodifiable(_plugins.keys);

  /// All registered alias names.
  List<String> get registeredAliasNames =>
      List<String>.unmodifiable(_aliases.keys);

  /// True if an action with [name] is registered.
  bool hasAction(String name) => _actions.containsKey(name);

  /// True if a plugin with [type] is registered.
  bool hasPlugin(String type) => _plugins.containsKey(type);

  /// True if an alias with [name] is registered.
  bool hasAlias(String name) => _aliases.containsKey(name);
}

/// Extension exposing read-only inspector APIs on [QLModuleRegistry] for the QEE.
extension QLModuleRegistryInspector on QLModuleRegistry {
  /// All registered module IDs.
  List<String> get registeredModuleIds =>
      List<String>.unmodifiable(_modules.keys);

  /// All registered module records as an unmodifiable list.
  List<QLModuleRecord> get allModules =>
      List<QLModuleRecord>.unmodifiable(_modules.values);
}

/// A dummy context used for headless engine tests when [triggerActions] is called without a UI.
class _QEEDummyContext implements BuildContext {
  const _QEEDummyContext();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Cannot call BuildContext methods in headless engine tests.');
}

class QLLazySchemaViewReadPlan {
  final List<String> requested;
  final List<String> available;
  final List<String> missing;

  const QLLazySchemaViewReadPlan({
    required this.requested,
    required this.available,
    required this.missing,
  });

  bool get needsFetch => missing.isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'requested': requested,
        'available': available,
        'missing': missing,
        'needsFetch': needsFetch,
      };
}

extension QLLazySchemaViewSmartSelect on QLLazySchemaView {
  List<String> normalizeSelection(Iterable<String>? names) {
    final raw = names
            ?.map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (raw.isEmpty) return fieldNames.toList(growable: false);
    return raw.toList(growable: false);
  }

  QLLazySchemaViewReadPlan buildReadPlan(Iterable<String>? names) {
    final requested = normalizeSelection(names);
    final available = <String>[];
    final missing = <String>[];
    for (final name in requested) {
      // Renamed local variable from 'field' to 'fieldSlice' to avoid shadowing the 'field()' method
      final fieldSlice = field(name);
      if (fieldSlice == null) {
        missing.add(name);
      } else {
        available.add(name);
      }
    }
    return QLLazySchemaViewReadPlan(
      requested: requested,
      available: available,
      missing: missing,
    );
  }

  Map<String, dynamic> project(Iterable<String>? names) =>
      pick(normalizeSelection(names));

  bool hasAll(Iterable<String>? names) => !buildReadPlan(names).needsFetch;

  Iterable<String> missingFields(Iterable<String>? names) =>
      buildReadPlan(names).missing;
}
