/*
 * ============================================================================
 * File: quantum_vm_registry.dart
 * 
 * Description:
 * The module and schema registry for the QuantumVM. It handles the registration, 
 * versioning, and access control of extension bundles, layout matrices, and reusable 
 * design system schemas.
 * 
 * Key Components:
 * - QLModuleRegistry: Core registry orchestrating modules and caching their definitions.
 * - QLModuleAccessPolicy: Enforces visibility bounds (e.g., public, local, secure) on modules.
 * - QLModuleRegistryQEEBridge: Migration utility to synchronize legacy modules to the new QEE.
 * 
 * Dependencies/Relationships:
 * A part of quantum_vm.dart. It interacts with the Quantum Execution Engine (QEE) 
 * to provide module synchronization and policy checks.
 * 
 * Notes:
 * The bridge extension highlights an architectural transition towards QEE, 
 * mapping legacy visibility settings to QNodeRegistry policies.
 * ============================================================================
 */
// quantum_vm_registry.dart
// Module, Schema, and Extension Bundle Registry for QuantumVM.

part of 'quantum_vm.dart';

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

/// Extension exposing read-only inspector APIs on [QLModuleRegistry] for the QEE.
extension QLModuleRegistryInspector on QLModuleRegistry {
  /// All registered module IDs.
  List<String> get registeredModuleIds =>
      List<String>.unmodifiable(_modules.keys);

  /// All registered module records as an unmodifiable list.
  List<QLModuleRecord> get allModules =>
      List<QLModuleRecord>.unmodifiable(_modules.values);
}

// ─────────────────────────────────────────────────────────────────────────────
// QEE BRIDGE — QLModuleRegistry → QModuleNode conversion
//
// Converts an existing QLModuleRecord into a QModuleConfig that can be
// registered with QNodeRegistry. This lets the legacy QLModuleRegistry and
// the new QEE coexist during the migration: all modules that already exist in
// QLModuleRegistry can be mirrored into QEE without re-declaring them.
//
// Usage:
//   await QLModuleRegistry.instance.syncToQEE(appId: 'root');
// ─────────────────────────────────────────────────────────────────────────────

extension QLModuleRegistryQEEBridge on QLModuleRegistry {
  /// Convert a single [QLModuleRecord] to a [QModuleConfig] for QNodeRegistry.
  ///
  /// Policy mapping:
  ///   QLModuleVisibility.public  → QModuleKind.public
  ///   QLModuleVisibility.local   → QModuleKind.private
  ///   QLModuleVisibility.owner   → QModuleKind.shared  (allowedApps = {ownerId})
  ///   QLModuleVisibility.secure  → QModuleKind.private
  static QModuleConfig recordToQEEConfig(
    QLModuleRecord record, {
    String? appId,
    String? assetPath,
  }) {
    // Map QL visibility → QEE module kind + policy
    final kind = switch (record.access.visibility) {
      QLModuleVisibility.public => QModuleKind.public,
      QLModuleVisibility.local => QModuleKind.private,
      QLModuleVisibility.owner => QModuleKind.shared,
      QLModuleVisibility.secure => QModuleKind.private,
    };

    final allowedIds = switch (record.access.visibility) {
      QLModuleVisibility.owner => record.access.ownerId != null
          ? {record.access.ownerId!}
          : record.access.allowModules,
      QLModuleVisibility.local => record.access.allowModules,
      _ => record.access.allowModules,
    };

    final policy = QModulePolicy(
      kind: kind,
      allowedAppIds: allowedIds.toList(),
      requireAuth: record.access.visibility == QLModuleVisibility.secure,
    );

    // Extract slices from the manifest
    final slices = _extractSlices(record.manifest);

    // Extract data sources
    final dataSources = _extractDataSources(record.manifest);

    // Extract macros, schemas, actions
    final macros = _extractMap(record.manifest, 'macros');
    final schemas = _extractMap(record.manifest, 'schemas');
    final actions = _extractMap(record.manifest, 'actions');

    // Extract imports
    final imports = _extractList(record.manifest, 'uses') +
        _extractList(record.manifest, 'imports');

    return QModuleConfig(
      moduleId: record.id,
      appId: appId,
      assetPath: assetPath,
      policy: policy,
      slices: slices,
      dataSources: dataSources,
      macros: macros,
      schemas: schemas,
      actions: actions,
      imports: imports,
    );
  }

  /// Sync all currently registered [QLModuleRecord]s into [QNodeRegistry].
  ///
  /// Skips modules that are already stored at the same [versionHash].
  /// Safe to call multiple times — uses upsert internally.
  Future<int> syncToQEE({String? appId}) async {
    int synced = 0;
    for (final record in allModules) {
      try {
        final config = QLModuleRegistryQEEBridge.recordToQEEConfig(
          record,
          appId: appId,
        );
        await QNodeRegistry.instance.upsertModule(config);
        synced++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[QEE Bridge] Failed to sync module ${record.id}: $e');
        }
      }
    }
    return synced;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static List<QSliceConfig> _extractSlices(Map<String, dynamic> manifest) {
    final slicesRaw = manifest['slices'] ?? manifest['state'];
    if (slicesRaw is! Map) return const [];

    return slicesRaw.entries.map<QSliceConfig>((entry) {
      final name = entry.key.toString();
      final raw = entry.value;
      if (raw is! Map) {
        return QSliceConfig(
          sliceName: name,
          fields: {
            name: QSliceField(
              fieldName: name,
              type: 'dynamic',
              isStatic: true,
              staticValue: raw,
            ),
          },
        );
      }

      final fields = <String, QSliceField>{};
      for (final fieldEntry in raw.entries) {
        final fieldName = fieldEntry.key.toString();
        final fieldRaw = fieldEntry.value;
        final isStatic =
            fieldRaw is! Map || (fieldRaw as Map).containsKey('static');
        fields[fieldName] = QSliceField(
          fieldName: fieldName,
          type: (fieldRaw is Map ? fieldRaw['type']?.toString() : null) ??
              'dynamic',
          defaultValue: fieldRaw is Map ? fieldRaw['default'] : fieldRaw,
          isStatic: isStatic,
          staticValue: isStatic
              ? (fieldRaw is Map ? fieldRaw['static'] ?? fieldRaw : fieldRaw)
              : null,
        );
      }

      return QSliceConfig(sliceName: name, fields: fields);
    }).toList(growable: false);
  }

  static List<QDataSourceConfig> _extractDataSources(
      Map<String, dynamic> manifest) {
    final raw = manifest['dataSources'] ?? manifest['data_sources'];
    if (raw is! List) return const [];

    return raw.whereType<Map>().map<QDataSourceConfig>((ds) {
      return QDataSourceConfig(
        id: ds['id']?.toString() ?? '',
        type: ds['type']?.toString() ?? 'rest',
        endpoint: ds['endpoint']?.toString() ?? ds['url']?.toString() ?? '',
        method: ds['method']?.toString() ?? 'GET',
        headers: _toStringMap(ds['headers']),
        queryParams: _toStringMap(ds['params'] ?? ds['query']),
        body: ds['body'] is Map
            ? Map<String, dynamic>.from(ds['body'] as Map)
            : const {},
        cacheSeconds:
            (ds['cache'] as num?)?.toInt() ?? (ds['ttl'] as num?)?.toInt() ?? 0,
        requiresAuth: ds['auth'] == true || ds['requiresAuth'] == true,
      );
    }).toList(growable: false);
  }

  static Map<String, dynamic> _extractMap(
      Map<String, dynamic> manifest, String key) {
    final raw = manifest[key];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static List<String> _extractList(Map<String, dynamic> manifest, String key) {
    final raw = manifest[key];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  static Map<String, String> _toStringMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }
}
