/*
 * ============================================================================
 * File: quantum_data_orchestrator.dart
 * 
 * Description:
 * Responsible for bootstrapping and orchestrating data structures from SDUI 
 * manifests. It parses JSON manifests and wires up modules, schemas, data 
 * sources, slice pipelines, and dynamic actions within the Quantum framework.
 * 
 * Key Components:
 * - QuantumDataOrchestrator: Static bootstrap and initialization orchestrator.
 * - QLOrchestratorPipelineDelegate: Connects a data pipeline to the VM for data fetching.
 * 
 * Dependencies/Relationships:
 * Interacts heavily with QuantumVM and delegates actual data management to 
 * quantum_data_pipeline.dart and quantum_data_state.dart.
 * 
 * Notes:
 * Keeps state storage out of this file. Focuses purely on declarative parsing 
 * and registration during app or domain bootstrap.
 * ============================================================================
 */
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../foundation/quantum_isolate_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quantum_data_pipeline.dart';
import 'quantum_data_state.dart';
import 'package:quantum_layout/quantum.dart'
    hide
        QLStoreRegistry,
        QLMutationFn,
        QLQueryFn,
        QLSliceRegistry,
        QLStoreSlice,
        QLDataStore,
        QLActionPlugin;

/// Bootstrap/orchestration only.
/// State storage and pipeline evaluation live in their own files.
abstract final class QuantumDataOrchestrator {
  static Future<void> bootstrapString(
      String rawManifest, BuildContext? ctx) async {
    final Map<String, dynamic> safeManifest = await QLIsolateBridge.safeRun(() {
      return QLFormatParser.parse(rawManifest);
    });
    await bootstrap(safeManifest, ctx);
  }

  static Future<void> bootstrapAsset(
      String assetPath, BuildContext? ctx) async {
    final String rawString = await rootBundle.loadString(assetPath);
    await bootstrapString(rawString, ctx);
  }

  static Future<void> bootstrap(
      Map<String, dynamic> manifest, BuildContext? ctx) async {
    final String namespace = (manifest['module'] ?? 'default').toString();
    final BuildContext resolvedCtx = QLRuntimeSupport.resolveContext(ctx);

    QLModuleRegistry.instance.register(manifest, id: namespace);

    final nested = manifest['modules'];
    if (nested is Map) {
      for (final entry in nested.entries) {
        if (entry.value is Map) {
          await bootstrap(
            Map<String, dynamic>.from(entry.value as Map),
            resolvedCtx,
          );
        }
      }
    } else if (nested is List) {
      for (final raw in nested) {
        if (raw is Map) {
          await bootstrap(Map<String, dynamic>.from(raw), resolvedCtx);
        }
      }
    }

    final targetStore = QLStoreRegistry.instance.get(namespace);

    if (manifest['schemas'] is Map) {
      (manifest['schemas'] as Map).forEach((schemaName, def) {
        final localName = schemaName.toString();
        final qualifiedName = '$namespace.$localName';
        final schemaDef = QLRuntimeSupport.mapOf(def);

        QLSchemaRegistry.instance.registerRaw(localName, schemaDef);
        QLSchemaRegistry.instance.registerRaw(qualifiedName, schemaDef);

        final compiledLocal = QLSchemaCompiler.compile(localName, schemaDef);
        QLSchemaRegistry.instance.register(compiledLocal);

        final compiledQualified =
            QLSchemaCompiler.compile(qualifiedName, schemaDef);
        QLSchemaRegistry.instance.register(compiledQualified);
      });
    }

    if (manifest['actions'] is Map) {
      Map<String, dynamic>.from(manifest['actions'] as Map)
          .forEach((actionName, steps) {
        QuantumVM.instance.registerAction(
          '$namespace.$actionName',
          _DynamicActionPlugin(_normalizeSteps(steps)),
        );
      });
    }

    if (manifest['dataSources'] is Map) {
      _initializeDataSources(
        Map<String, dynamic>.from(manifest['dataSources'] as Map),
        targetStore,
        resolvedCtx,
      );
    }

    if (manifest['slices'] is Map) {
      _initializeSlices(
        namespace,
        Map<String, dynamic>.from(manifest['slices'] as Map),
        resolvedCtx,
      );
    }
  }

  static List<dynamic> _normalizeSteps(dynamic steps) {
    if (steps is List) return List<dynamic>.from(steps);
    return <dynamic>[steps];
  }

  static void _initializeSlices(String parentNamespace,
      Map<String, dynamic> slicesDef, BuildContext? ctx) {
    slicesDef.forEach((sliceName, rawDef) {
      if (rawDef is! Map) return;

      final def = Map<String, dynamic>.from(rawDef);
      final ns = '$parentNamespace.$sliceName';
      final slice = QLStoreSlice.fromMap(ns, Map<String, dynamic>.from(def));

      QLSliceRegistry.instance.mount(slice);
      _registerSlicePipelines(ns, slice, ctx);
    });
  }

  static void _registerSlicePipelines(
      String namespace, QLStoreSlice slice, BuildContext? ctx) {
    if (slice.pipelines.isEmpty) return;
    final sliceStore = QLStoreRegistry.instance.get(namespace);
    final resolvedCtx = QLRuntimeSupport.resolveContext(ctx);

    slice.pipelines.forEach((pipelineName, rawCfg) {
      if (rawCfg is! Map) return;
      final cfg = Map<String, dynamic>.from(rawCfg);
      final String pipelineId = '$namespace.$pipelineName';
      final String schemaName =
          cfg['schema']?.toString() ?? slice.schema?.toString() ?? '';
      final QLSchemaBlueprint? schema =
          QLSchemaRegistry.instance.getSchema(schemaName) ??
              QLSchemaRegistry.instance.getSchema('$namespace.$schemaName');
      if (schema == null) {
        debugPrint(
          'QuantumDataOrchestrator: schema "$schemaName" not found for slice pipeline "$pipelineId".',
        );
        return;
      }

      final delegate = QLOrchestratorPipelineDelegate(
        fetchActions: List<dynamic>.from(cfg['fetch'] as List? ?? const []),
        partialFetchActions:
            List<dynamic>.from(cfg['fetchPartial'] as List? ?? const []),
        context: resolvedCtx,
        schema: schema,
        select: cfg['select'] is Iterable
            ? List<String>.from(
                (cfg['select'] as Iterable).map((e) => e.toString()),
              )
            : (cfg['fields'] is Iterable
                ? List<String>.from(
                    (cfg['fields'] as Iterable).map((e) => e.toString()),
                  )
                : const <String>[]),
      );

      final pipeline = QLDataPipeline(
        id: pipelineId,
        schema: schema,
        executionMode: cfg['executionMode'] == 'server'
            ? QLExecutionMode.server
            : cfg['executionMode'] == 'client'
                ? QLExecutionMode.client
                : cfg['executionMode'] == 'isolate'
                    ? QLExecutionMode.isolate
                    : QLExecutionMode.auto,
        pageSize: (cfg['pageSize'] as num?)?.toInt() ?? 0,
        delegate: delegate,
      );

      if (cfg['aggregates'] is List) {
        final ops = (cfg['aggregates'] as List)
            .whereType<Map>()
            .map((o) => QLAggregateOp(
                  alias: o['alias']?.toString() ?? '',
                  field: o['field']?.toString() ?? '',
                  type: o['type']?.toString() ?? 'count',
                ))
            .where((op) => op.alias.isNotEmpty && op.field.isNotEmpty)
            .toList(growable: false);
        if (ops.isNotEmpty) pipeline.registerAggregates(ops);
      }

      QLPipelineRegistry.instance.register(pipeline);

      final String? bindPath =
          cfg['bind']?.toString() ?? cfg['stateKey']?.toString();
      if (bindPath != null && bindPath.isNotEmpty) {
        void syncBoundState() {
          final rows = List.generate(pipeline.visibleCount, (i) {
            final realIdx = pipeline.visibleIndices.value[i];
            return pipeline.getAsMap(realIdx);
          }, growable: false);
          sliceStore.set(bindPath, rows);
        }

        pipeline.visibleIndices.addListener(syncBoundState);
        syncBoundState();
      }

      if (cfg['autoFetch'] == true) {
        unawaited(delegate.fetch(const {}).then((data) {
          pipeline.ingest(data);
        }));
      }
    });
  }

  static void _initializeDataSources(
      Map<String, dynamic> sources, QLDataStore store, BuildContext? ctx) {
    sources.forEach((sourceId, config) {
      final mapConfig = QLRuntimeSupport.mapOf(config);
      final String signalKey = 'dataSources.$sourceId';
      final handle = QLDataSourceRegistry.instance
          .register(sourceId.toString(), mapConfig);
      store.bindAsync(signalKey, handle.signal);

      if (mapConfig['lifecycle'] == 'onMount' && ctx != null && ctx.mounted) {
        unawaited(handle.refresh());
      }
    });
  }

  static Future<dynamic> executeDataSource(
      String sourceId,
      Map<String, dynamic> config,
      QLAsyncSignal<dynamic> asyncSignal,
      BuildContext? ctx,
      QLDataStore store) async {
    final String providerAction = config['provider']?.toString() ?? '';
    if (providerAction.isEmpty) return null;

    final Map<String, dynamic> rawArgs = QLRuntimeSupport.mapOf(config['args']);
    final Map<String, dynamic> execution =
        QLRuntimeSupport.mapOf(config['execution']);

    final BuildContext resolvedCtx = QLRuntimeSupport.resolveContext(ctx);

    final Map<String, dynamic> args = <String, dynamic>{};
    rawArgs.forEach((k, v) {
      if (v is String && v.contains('{{')) {
        final parsed = QLCompiler.parseTokensAndDeps(v);
        args[k] = QLDataBinder.resolveAOT(
          {'_isTokenized': true, 'tokens': parsed.tokens},
          resolvedCtx,
          {},
          store,
        );
      } else {
        args[k] = QLDataBinder.resolveAOT(v, resolvedCtx, {}, store);
      }
    });

    // 1. We remove `return await` because load() is void.
    // 2. We just pass the Future factory closure into the signal.
    asyncSignal.load(() async {
      final Map<String, dynamic> pipelineEnv = <String, dynamic>{};
      await QuantumVM.instance.triggerActions(
        [
          {'action': providerAction, ...args}
        ],
        resolvedCtx,
        env: pipelineEnv,
      );

      final dynamic fetchedData = QLRuntimeSupport.lastResult(pipelineEnv);

      if (execution['thread'] == 'isolate' && !kIsWeb) {
        final dynamic buffer = fetchedData is Uint8List
            ? QLTransferableBuffer.encode(fetchedData)
            : fetchedData;

        final pipeline = List<String>.from(execution['pipeline'] ?? const []);
        final signal = QuantumVM.instance.workerPool
            .submit(QLZeroCopyPipelineTask(pipeline), buffer);

        if (signal.data.value != null) return signal.data.value;

        final completer = Completer<dynamic>();
        void listener() {
          final value = signal.data.value;
          if (value != null && !completer.isCompleted) {
            signal.data.removeListener(listener);
            completer.complete(value);
          }
        }

        signal.data.addListener(listener);
        return await completer.future;
      }

      return fetchedData;
    });

    // We return null immediately, as the asyncSignal handles the reactive state distribution.
    return null;
  }

  /// Export a structured snapshot of the current orchestrator state.
  ///
  /// This is safe to embed in SDUI JSON because it only contains metadata
  /// about manifests, pipelines, stores, and slices.
  static Map<String, dynamic> snapshot() {
    final moduleSnapshot = QLModuleRegistry.instance.snapshot();
    final pipelineSnapshot = QLPipelineRegistry.instance.snapshot();
    final storeSnapshot = QLStoreRegistry.instance.snapshot();
    final sliceSnapshot = QLSliceRegistry.instance.snapshot();
    final dataSourceSnapshot = QLDataSourceRegistry.instance.snapshot();

    final modules = List<Map<String, dynamic>>.from(
      moduleSnapshot['modules'] as List? ?? const [],
    );
    final pipelines = List<Map<String, dynamic>>.from(
      pipelineSnapshot['pipelines'] as List? ?? const [],
    );
    final stores = List<Map<String, dynamic>>.from(
      storeSnapshot['namespaces'] as List? ?? const [],
    );
    final slices = List<Map<String, dynamic>>.from(
      sliceSnapshot['namespaces'] as List? ?? const [],
    );
    final dataSources = List<Map<String, dynamic>>.from(
      dataSourceSnapshot['sources'] as List? ?? const [],
    );

    return <String, dynamic>{
      'modules': modules,
      'pipelines': pipelines,
      'stores': stores,
      'slices': slices,
      'dataSources': dataSources,
    };
  }
}

class _DynamicActionPlugin extends QLActionPlugin {
  final List<dynamic> steps;

  _DynamicActionPlugin(this.steps);

  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final env = Map<String, dynamic>.from(payload);
    await QuantumVM.instance.triggerActions(steps, ctx, env: env);
    return env[r'$lastResult'];
  }
}

class QLOrchestratorPipelineDelegate implements QLPipelineDelegate {
  final List<dynamic> fetchActions;
  final List<dynamic>? partialFetchActions;
  final BuildContext? context;
  final QLSchemaBlueprint schema;
  final List<String> select;

  QLOrchestratorPipelineDelegate({
    required this.fetchActions,
    this.partialFetchActions,
    this.context,
    required this.schema,
    this.select = const <String>[],
  });

  @override
  Future<List<Map<String, dynamic>>> fetch(Map<String, dynamic> state) async {
    if (fetchActions.isEmpty) return const [];

    final env = <String, dynamic>{
      r'$pipelineState': state,
      if (select.isNotEmpty) 'select': select,
      if (select.isNotEmpty) 'fields': select,
    };

    final augmentedActions = fetchActions.map((a) {
      if (a is Map) return {...a, r'$pipelineState': state};
      return a;
    }).toList(growable: false);

    await QuantumVM.instance.triggerActions(
      augmentedActions,
      context ?? _getFallbackContext(),
      env: env,
    );

    return QLRuntimeSupport.recordsOf(QLRuntimeSupport.lastResult(env));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPartial(
      List<String> ids, QLProjection projection) async {
    if (partialFetchActions == null || partialFetchActions!.isEmpty) {
      return const [];
    }

    final requestedFields = <String>[];
    for (final spec in schema.fields) {
      if (projection.isSelected(spec.index)) {
        requestedFields.add(spec.path.toString());
      }
    }
    if (select.isNotEmpty) {
      for (final field in select) {
        if (!requestedFields.contains(field)) requestedFields.add(field);
      }
    }

    final env = <String, dynamic>{
      r'$requestedIds': ids,
      r'$requestedFields': requestedFields,
      if (select.isNotEmpty) 'select': select,
    };

    final augmentedActions = partialFetchActions!.map((a) {
      if (a is Map) {
        return {
          ...a,
          r'$requestedIds': ids,
          r'$requestedFields': requestedFields,
          if (select.isNotEmpty) 'select': select,
        };
      }
      return a;
    }).toList(growable: false);

    await QuantumVM.instance.triggerActions(
      augmentedActions,
      context ?? _getFallbackContext(),
      env: env,
    );

    return QLRuntimeSupport.recordsOf(QLRuntimeSupport.lastResult(env));
  }

  BuildContext _getFallbackContext() {
    return QLRuntimeSupport.resolveContext(context);
  }
}
