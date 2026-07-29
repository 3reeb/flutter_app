// ════════════════════════════════════════════════════════════════════════════
// QUANTUM VIRTUAL MACHINE INITIALIZER v13.0 - OMEGA BUILD
// quantum_vm_init.dart
//
// ENHANCEMENTS:
// 1. Workspace Plugin: Mounts the Macro-Spatial 2D layout engine.
// 2. Item Factory Plugin: Mounts the V-DOM lazily using Pipeline memory.
// 3. Scene Plugin: The Canvas Portal into the C++ ECS Engine.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'dart:typed_data';
// Ecosystem Integrations
import '../ui/quantum_theme_engine.dart';
import '../ui/quantum_components.dart';
import '../ui/quantum_behaviors.dart';
import '../ui/quantum_navigation_engine.dart';
import 'quantum_data_orchestrator.dart';
import 'quantum_omni_registry.dart';
import 'quantum_core_schema_registry.dart';
import 'quantum_sdui_type_engine.dart';
import 'quantum_vm.dart';
import 'quantum_data_pipeline.dart';
import 'package:quantum_layout/quantum.dart';
class _BuiltInActionPlugin extends QLActionPlugin {
  final Future<dynamic> Function(
      Map<String, dynamic>, QLDataStore, BuildContext) func;
  _BuiltInActionPlugin(this.func);
  @override
  Future<dynamic> execute(
          Map<String, dynamic> p, QLDataStore s, BuildContext c) =>
      func(p, s, c);
}

void initQuantumBuiltIns(QuantumVM vm) {
  // 1. Register Omni Components (Buttons, Inputs, Selects, Cards)
  registerOmniComponents(vm);
  registerConnectOmniNodes(vm);
  QuantumCoreSchemaRegistry.instance.installDefaults();

  // Register SDUI JSON DSL definitions (templates & layouts)
  vm.registerJsonDslPlugins();

  vm.define('empty', (ctx) => const SizedBox.shrink());

  // 🚀 THE FIX: Register the universal 'slot' plugin
  // This allows layout files to render router pages (like $page) natively!
  vm.define('slot', (ctx) {
    // Look for the name of the slot, usually 'page' or 'default'
    final String name = ctx.string('name', fallback: 'default');

    // 1. Check if the router passed a compiled widget into the environment (e.g., $page)
    final dynamic envWidget = ctx.env['\$$name'] ?? ctx.env[name];
    // if (envWidget is Widget) {
    //   // If CSS styles are applied directly to the slot tag, wrap it in a QLBox
    //   final String style = ctx.node.style ?? '';
    //   if (style.isNotEmpty) {
    //     return QLBox(style: style, suppressParentData: true, child: envWidget);
    //   }
    //   return envWidget;
    // }

    // 2. Standard SDUI nested slot resolution
    final Widget? slotWidget = ctx.slot(name);
    if (slotWidget != null) return slotWidget;

    // 3. Fallback to children if provided in the YAML
    if (ctx.children.isNotEmpty) {
      if (ctx.children.length == 1) return ctx.children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ctx.children,
      );
    }

    return const SizedBox.shrink();
  });

  // ── THE OMEGA ECS RENDERER (The Canvas Portal) ──
  vm.define('scene', (ctx) {
    return QLSceneLayerWidget(
      isComplex: true,
      willChange: true,
      builder: (context, layer) {
        final bridge = QLSoASceneBridge(
          ecs: QEngine.instance.ecs,
          layer: layer,
          drawFactory: (ecs, entityId) {
            return (Canvas canvas, Size size) {
              final t = ecs.comp('transform');
              final b = ecs.comp('bounds');
              final v = ecs.comp('visual');

              final double x = t.get(entityId, 6); // WORLD X
              final double y = t.get(entityId, 7); // WORLD Y
              final double w = b.get(entityId, 0);
              final double h = b.get(entityId, 1);

              final int colorVal = v.get(entityId, 0).toInt();
              final Paint paint = Paint()
                ..color = colorVal == 0 ? Colors.blue : Color(colorVal);

              canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
            };
          },
        );
        QEngine.instance.tick.addListener(() {
          bridge.syncAll(
              zLevelFn: (e) =>
                  QEngine.instance.ecs.comp('visual').get(e, 1).toInt());
        });
        return const SizedBox.expand();
      },
    );
  });

  vm.registerAction('schema.export_bundle',
      _BuiltInActionPlugin((payload, store, ctx) async {
    return QuantumSduiTypeEngine.exportSnapshot(
      kind: payload['kind']?.toString(),
      query: payload['query']?.toString(),
      includeRegistry: payload['includeRegistry'] as bool? ?? true,
      includeCoreSchemas: payload['includeCoreSchemas'] as bool? ?? true,
      includeDesignSystems: payload['includeDesignSystems'] as bool? ?? true,
      includeOmniCores: payload['includeOmniCores'] as bool? ?? true,
      includeDslOperators: payload['includeDslOperators'] as bool? ?? true,
      includeAliasRegistry: payload['includeAliasRegistry'] as bool? ?? true,
      includeOrchestrator: payload['includeOrchestrator'] as bool? ?? true,
    );
  }),
      description: 'Export the live SDUI schema bundle as JSON data',
      params: const {
        'kind': 'String',
        'query': 'String',
        'includeRegistry': 'bool',
        'includeCoreSchemas': 'bool',
        'includeDesignSystems': 'bool',
        'includeOmniCores': 'bool',
        'includeDslOperators': 'bool',
        'includeAliasRegistry': 'bool',
        'includeOrchestrator': 'bool',
      },
      engine: 'QuantumVM',
      tags: const ['schema', 'export', 'sdui']);

  vm.registerAction('schema.export_json',
      _BuiltInActionPlugin((payload, store, ctx) async {
    return QuantumSduiTypeEngine.exportJson(
      kind: payload['kind']?.toString(),
      query: payload['query']?.toString(),
      includeRegistry: payload['includeRegistry'] as bool? ?? true,
      includeCoreSchemas: payload['includeCoreSchemas'] as bool? ?? true,
      includeDesignSystems: payload['includeDesignSystems'] as bool? ?? true,
      includeOmniCores: payload['includeOmniCores'] as bool? ?? true,
      includeDslOperators: payload['includeDslOperators'] as bool? ?? true,
      includeAliasRegistry: payload['includeAliasRegistry'] as bool? ?? true,
      includeOrchestrator: payload['includeOrchestrator'] as bool? ?? true,
    );
  }),
      description: 'Export the live SDUI schema bundle as pretty JSON',
      params: const {
        'kind': 'String',
        'query': 'String',
        'includeRegistry': 'bool',
        'includeCoreSchemas': 'bool',
        'includeDesignSystems': 'bool',
        'includeOmniCores': 'bool',
        'includeDslOperators': 'bool',
        'includeAliasRegistry': 'bool',
        'includeOrchestrator': 'bool',
      },
      engine: 'QuantumVM',
      tags: const ['schema', 'export', 'json']);

  vm.registerAction('schema.export_ts',
      _BuiltInActionPlugin((payload, store, ctx) async {
    return QuantumSduiTypeEngine.exportTypeScriptBundle(
      kind: payload['kind']?.toString(),
      query: payload['query']?.toString(),
      bundleName: payload['bundleName']?.toString() ?? 'quantumSduiBundle',
      engineImportPath: payload['engineImportPath']?.toString() ??
          './quantum_sdui_type_engine',
      includeRegistry: payload['includeRegistry'] as bool? ?? true,
      includeCoreSchemas: payload['includeCoreSchemas'] as bool? ?? true,
      includeDesignSystems: payload['includeDesignSystems'] as bool? ?? true,
      includeOmniCores: payload['includeOmniCores'] as bool? ?? true,
      includeDslOperators: payload['includeDslOperators'] as bool? ?? true,
      includeAliasRegistry: payload['includeAliasRegistry'] as bool? ?? true,
      includeOrchestrator: payload['includeOrchestrator'] as bool? ?? true,
    );
  }),
      description:
          'Export a TypeScript bundle for the live SDUI schema catalog',
      params: const {
        'kind': 'String',
        'query': 'String',
        'bundleName': 'String',
        'engineImportPath': 'String',
        'includeRegistry': 'bool',
        'includeCoreSchemas': 'bool',
        'includeDesignSystems': 'bool',
        'includeOmniCores': 'bool',
        'includeDslOperators': 'bool',
        'includeAliasRegistry': 'bool',
        'includeOrchestrator': 'bool',
      },
      engine: 'QuantumVM',
      tags: const ['schema', 'export', 'typescript', 'sdui']);

  vm.registerAction('schema.export_orchestrator',
      _BuiltInActionPlugin((payload, store, ctx) async {
    return QuantumDataOrchestrator.snapshot();
  }),
      description: 'Export the live QuantumDataOrchestrator manifest snapshot',
      params: const {},
      engine: 'QuantumVM',
      tags: const ['schema', 'export', 'orchestrator']);

  vm.registerAction('mock.get_employees',
      LambdaActionPlugin((payload, store, ctx) async {
    // Simulating an API network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Generating 1,000 Employees to prove the engine handles massive data perfectly
    return List.generate(
        1000,
        (i) => {
              "id": "emp_$i",
              "name": "Employee $i",
              "role": i % 3 == 0
                  ? "Senior Engineer"
                  : (i % 2 == 0 ? "Product Designer" : "Manager"),
              "avatar": "https://i.pravatar.cc/150?u=$i",
              "status": i % 5 == 0 ? "Offline" : "Active",
              "performance": 80 + (i % 20)
            });
  }),
      description: 'Generate a large synthetic employee dataset',
      params: const {},
      engine: 'QuantumVM',
      tags: const ['mock', 'data']);

  // 🚀 GLUE 2: System Action Arsenal
  vm.registerAction('pipeline.refresh',
      _BuiltInActionPlugin((payload, store, ctx) async {
    final pId = payload['pipelineId']?.toString();
    if (pId == null) return;
    final p = QLPipelineRegistry.instance.get(pId);
    if (p.delegate != null) {
      final data = await p.delegate!.fetch({});
      p.ingest(data);
    }
  }),
      description: 'Refresh a pipeline from its delegate',
      params: const {'pipelineId': 'String'},
      engine: 'QuantumVM',
      tags: const ['pipeline', 'refresh']);

  vm.registerAction('pipeline.patch',
      _BuiltInActionPlugin((payload, store, ctx) async {
    final pId = payload['pipelineId']?.toString();
    final rId = payload['recordId']?.toString();
    final deltaRaw = payload['delta'];
    final delta =
        deltaRaw is Map ? Map<String, dynamic>.from(deltaRaw as Map) : null;
    if (pId != null && rId != null && delta != null) {
      QLPipelineRegistry.instance.get(pId).patch(rId, delta);
    }
  }),
      description: 'Patch a record in a pipeline',
      params: const {
        'pipelineId': 'String',
        'recordId': 'String',
        'delta': 'Map'
      },
      engine: 'QuantumVM',
      tags: const ['pipeline', 'patch']);

  vm.registerAction('state.increment',
      LambdaActionPlugin((payload, store, ctx) async {
    final key = payload['key']?.toString() ?? payload['path']?.toString();
    if (key == null || key.isEmpty) return null;
    final num amount = (payload['amount'] as num?) ??
        (payload['delta'] as num?) ??
        1;
    final current = store.get(key);
    num base = 0;
    if (current is num) {
      base = current;
    } else if (current is String) {
      base = num.tryParse(current) ?? 0;
    }
    final num next = (current is int && amount is int)
        ? (base.toInt() + amount.toInt())
        : (base.toDouble() + amount.toDouble());
    store.set(key, next is int ? next.toInt() : next);
    return next is int ? next.toInt() : next;
  }),
      description: 'Increment a numeric value in the shared store',
      params: const {'key': 'String', 'amount': 'dynamic'},
      engine: 'QuantumVM',
      tags: const ['state', 'core']);

  vm.registerAction('increment',
      LambdaActionPlugin((payload, store, ctx) async {
    final key = payload['path']?.toString() ?? payload['key']?.toString();
    if (key == null || key.isEmpty) return null;
    final num amount = (payload['amount'] as num?) ??
        (payload['delta'] as num?) ??
        1;
    final current = store.get(key);
    num base = 0;
    if (current is num) {
      base = current;
    } else if (current is String) {
      base = num.tryParse(current) ?? 0;
    }
    final num next = (current is int && amount is int)
        ? (base.toInt() + amount.toInt())
        : (base.toDouble() + amount.toDouble());
    store.set(key, next is int ? next.toInt() : next);
    return next is int ? next.toInt() : next;
  }),
      description: 'Increment a numeric store value',
      params: const {'path': 'String', 'amount': 'dynamic'},
      engine: 'QuantumVM',
      tags: const ['state', 'core']);

  vm.registerAction('state.toggle',
      LambdaActionPlugin((payload, store, ctx) async {
    final key = payload['key']?.toString() ?? payload['path']?.toString();
    if (key == null || key.isEmpty) return null;
    final current = store.get(key);
    final bool next = !(current as bool? ?? false);
    store.set(key, next);
    return next;
  }),
      description: 'Toggle a boolean value in the shared store',
      params: const {'key': 'String'},
      engine: 'QuantumVM',
      tags: const ['state', 'core']);

  vm.registerAction('toggle',
      LambdaActionPlugin((payload, store, ctx) async {
    final key = payload['path']?.toString() ?? payload['key']?.toString();
    if (key == null || key.isEmpty) return null;
    final current = store.get(key);
    final bool next = !(current as bool? ?? false);
    store.set(key, next);
    return next;
  }),
      description: 'Toggle a boolean store value',
      params: const {'path': 'String'},
      engine: 'QuantumVM',
      tags: const ['state', 'core']);

  vm.registerAction('state.set',
      LambdaActionPlugin((payload, store, ctx) async {
    final key = payload['key']?.toString();
    if (key == null || key.isEmpty) return null;
    final value =
        payload.containsKey('value') ? payload['value'] : payload['data'];
    store.set(key, value);
    return value;
  }),
      description: 'Set a value in the shared store',
      params: const {'key': 'String', 'value': 'dynamic'},
      engine: 'QuantumVM',
      tags: const ['state', 'core']);

  vm.registerAction('registry.inspect',
      LambdaActionPlugin((payload, store, ctx) async {
    final kind = payload['kind']?.toString();
    final query = payload['query']?.toString();
    final name = payload['name']?.toString();
    if (name != null && name.isNotEmpty) {
      return QuantumVM.instance.describeRegistryItem(name, kind: kind);
    }
    return QuantumVM.instance.registrySnapshot(kind: kind, query: query);
  }),
      description: 'Inspect registry entries and snapshots',
      params: const {'name': 'String?', 'kind': 'String?', 'query': 'String?'},
      engine: 'QuantumVM',
      tags: const ['registry', 'inspect']);

  vm.registerAction('registry.get',
      LambdaActionPlugin((payload, store, ctx) async {
    final name = payload['name']?.toString() ?? payload['path']?.toString();
    final kind = payload['kind']?.toString();
    if (name == null || name.isEmpty) return null;
    return QuantumVM.instance.describeRegistryItem(name, kind: kind);
  }),
      description: 'Get a single registry record',
      params: const {'name': 'String', 'kind': 'String?'},
      engine: 'QuantumVM',
      tags: const ['registry', 'get']);

  vm.registerAction('registry.search',
      LambdaActionPlugin((payload, store, ctx) async {
    final query = payload['query']?.toString() ?? '';
    final kind = payload['kind']?.toString();
    return QuantumVM.instance
        .registryEntries(kind: kind, query: query)
        .map((e) => e.toMap())
        .toList(growable: false);
  }),
      description: 'Search registry entries',
      params: const {'query': 'String', 'kind': 'String?'},
      engine: 'QuantumVM',
      tags: const ['registry', 'search']);

  vm.registerAction('overlay.close',
      _BuiltInActionPlugin((payload, store, ctx) async {
    QuantumOverlay.instance.closeTop();
  }),
      description: 'Close the current overlay stack top',
      params: const {},
      engine: 'QuantumVM',
      tags: const ['overlay']);

  vm.registerAction('overlay.open',
      _BuiltInActionPlugin((payload, store, ctx) async {
    final Map<String, dynamic> config = payload['config'] ?? {};
    final Map<String, dynamic> blueprint = payload['blueprint'] ?? {};

    ctx.mountOverlay(
        QLSpatialConfig.dialog(
          barrierDismissible: config['barrierDismissible'] ?? true,
          // style: config['style']
        ),
        (c, close) => QuantumVM.instance
            .renderWidget(c, QLBlueprint.fromJson(blueprint)));
  }),
      description: 'Open a new overlay surface',
      params: const {'config': 'Map', 'blueprint': 'Map'},
      engine: 'QuantumVM',
      tags: const ['overlay']);

// ─── 🚀 FEATURE 1: Q_REPEATER (Universal Iterator) ───
  vm.define('q_repeater', (ctx) {
    final String pId = ctx.string('pipeline');
    if (!QLPipelineRegistry.instance.exists(pId))
      return const SizedBox.shrink();

    final pipeline = QLPipelineRegistry.instance.get(pId);

    // 🚀 THE FIX: Get the raw AST blueprint, do NOT render it yet!
    final QLBlueprint templateNode = ctx.node.children.first;

    return AnimatedBuilder(
        animation: pipeline.visibleIndices,
        builder: (context, _) {
          final List<Widget> items =
              List.generate(pipeline.visibleCount, (index) {
            final realIdx = pipeline.visibleIndices.value[index];
            final itemData = pipeline.rawRecords[realIdx];

            return KeyedSubtree(
              key: ValueKey(itemData[0]), // Assumes ID at idx 0
              child: QLDataScope(
                localData: {'item': itemData, 'index': index},
                // 🚀 THE FIX: Use a Builder so the VM compiles this using the local QLDataScope!
                child: Builder(
                  builder: (innerCtx) =>
                      QuantumVM.instance.renderWidget(innerCtx, templateNode),
                ),
              ),
            );
          });

          if (ctx.string('behavior') == 'fluid_board') {
            return QLFluidBoard(
              crossAxisCount: ctx.integer('cols', fallback: 1),
              gap: ctx.number('gap', fallback: 16),
              onReorder: (o, n) => ctx.action('onReorder',
                  localPayload: {'old': o, 'new': n})?.call(),
              children: items,
            );
          }

          if (ctx.boolean('scrollable')) {
            return ListView(
              shrinkWrap: true,
              scrollDirection: ctx.string('direction') == 'horizontal'
                  ? Axis.horizontal
                  : Axis.vertical,
              children: items,
            );
          }

          return Wrap(
              spacing: ctx.number('gap'),
              runSpacing: ctx.number('gap'),
              children: items);
        });
  });
  // ─── 🚀 FEATURE 2: VECTOR ROW (Hardware Table Linker) ───
  vm.define('vector_row', (ctx) {
    final String ctrlId = ctx.string('vectorController');
    // Using DataStore to hold the Layout Controller instance
    final QLTableLayoutController? ctrl =
        ctx.store.get(ctrlId) as QLTableLayoutController?;
    if (ctrl == null) return const SizedBox.shrink();

    return AnimatedBuilder(
        animation: ctrl.version,
        builder: (context, _) {
          return SizedBox(
            height: ctx.number('height', fallback: 48),
            child: Stack(
                children: ctx.children.asMap().entries.map((e) {
              final int logicalIdx = ctrl.activeOrder[e.key];
              return Positioned(
                left: ctrl.offsetsX[logicalIdx],
                width: ctrl.widths[logicalIdx],
                top: 0,
                bottom: 0,
                child: e.value,
              );
            }).toList()),
          );
        });
  });

  // ─── 🚀 FEATURE 3: SPATIAL PROJECTION (Isolate Calendar Math) ───
  vm.define('q_spatial_projection', (ctx) {
    final String pId = ctx.string('pipeline');
    if (!QLPipelineRegistry.instance.exists(pId))
      return const SizedBox.shrink();

    final pipeline = QLPipelineRegistry.instance.get(pId);
    final Map projectionRules = ctx.map('projection');
    final Widget template = QuantumVM.instance
        .renderWidget(ctx.flutterContext, ctx.node.children.first);

    // Offload heavy coordinate math to Isolate
    final taskSignal = QuantumVM.instance.workerPool.submit(
        QLSpatialProjectionTask(),
        {'records': pipeline.rawRecords, 'projection': projectionRules});

    return AnimatedBuilder(
        animation: Listenable.merge([pipeline.visibleIndices, taskSignal.data]),
        builder: (context, _) {
          final Float64List? bounds = taskSignal.data.value;
          if (bounds == null)
            return const Center(child: CircularProgressIndicator());

          return Stack(
              children: List.generate(pipeline.visibleCount, (i) {
            final realIdx = pipeline.visibleIndices.value[i];
            return Positioned(
                left: bounds[i * 4 + 0],
                top: bounds[i * 4 + 1],
                width: bounds[i * 4 + 2],
                height: bounds[i * 4 + 3],
                child: QLDataScope(
                    localData: {'item': pipeline.rawRecords[realIdx]},
                    child: template));
          }));
        });
  });
}

class LambdaActionPlugin extends QLActionPlugin {
  final Future<dynamic> Function(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) func;

  LambdaActionPlugin(this.func);

  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    return await func(payload, store, ctx);
  }
}
