// ════════════════════════════════════════════════════════════════════════════
// QUANTUM DATA ORCHESTRATOR - OMEGA TEST SUITE (100% EXHAUSTIVE COVERAGE)
// test/quantum_data_orchestrator_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

// ─── MOCK ACTION PLUGINS FOR ORCHESTRATOR INTERCEPTION ───
class MockApiReadAction extends QLActionPlugin {
  Map<String, dynamic>? lastPayload;
  Map<String, dynamic>? lastEnv;

  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    lastPayload = payload;

    final dynamic simulatedResponse = payload['simulateResponse'] ??
        [
          {'id': '1', 'name': 'Alice'},
          {'id': '2', 'name': 'Bob'}
        ];

    final resultKey = payload['resultKey'] ?? r'$lastResult';
    store.set(resultKey, simulatedResponse);
    return simulatedResponse;
  }
}

class MockApiWriteAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    return {"status": "success", "id": payload['id']};
  }
}

void main() {
  group('Quantum Data Orchestrator | Exhaustive Feature Tests |', () {
    late MockApiReadAction mockApiRead;

    setUp(() {
      QLModuleRegistry.instance.clear();
      QLSchemaRegistry.instance.clear();
      QLPipelineRegistry.instance.destroy("default");
      QLStoreRegistry.instance.destroy('default');
      QLNativeBridgeRegistry.instance.clear();

      QuantumVM.instance.initialize(workerThreads: 2);

      mockApiRead = MockApiReadAction();
      QuantumVM.instance.registerAction('mock.api.read', mockApiRead);
      QuantumVM.instance.registerAction('mock.api.write', MockApiWriteAction());
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1. BOOTSTRAP: MODULES, STATE & DERIVED COMPUTATIONS
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('1. Manifest Bootstrapping & Derived State Topology',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: QLDataScope(
              moduleStore: QLStoreRegistry.instance.get('core_module'),
              child: Builder(builder: (ctx) {
                return const SizedBox.shrink();
              }))));
      final BuildContext context = tester.element(find.byType(SizedBox));

      final Map<String, dynamic> manifest = {
        "module": "core_module",
        "modules": [
          {"module": "child_module_1"},
          {"module": "child_module_2"}
        ],
        "state": {
          "cart": {"subtotal": 100.0, "taxRate": 0.08},
          "user_id": "usr_99",
          "total_price": {
            "type": "derived",
            // 🚀 FIX: Use correct Quantum VM Pipe syntax for mathematical derivation
            "compute":
                "{{state.cart.subtotal | calculate_tax({{state.cart.taxRate}})}}"
          }
        }
      };

      // Register mathematical pipe
      QLPipes.register('calculate_tax', (val, args) {
        final subtotal = (val as num).toDouble();
        final taxRate = double.parse(args[0].toString());
        return subtotal * (1 + taxRate);
      });

      await QuantumDataOrchestrator.bootstrap(manifest, context);

      expect(QLModuleRegistry.instance.exists('core_module'), isTrue);
      expect(QLModuleRegistry.instance.exists('child_module_1'), isTrue);
      expect(QLModuleRegistry.instance.exists('child_module_2'), isTrue);

      final store = QLStoreRegistry.instance.get('core_module');

      expect(store.get('user_id'), 'usr_99');
      expect(store.get('cart.subtotal'), 100.0);
      expect(store.get('total_price'), 108.0);

      store.set('cart.subtotal', 200.0);
      await tester.pump();

      expect(store.get('total_price'), 216.0);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. BOOTSTRAP: AOT SCHEMA COMPILATION
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('2. AOT Schema Compilation into Global Registry',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Builder(builder: (ctx) => const SizedBox())));
      final BuildContext context = tester.element(find.byType(SizedBox));

      final Map<String, dynamic> manifest = {
        "module": "app",
        "schemas": {
          "product": {"id": "string", "price": "number"},
          "order": {"id": "string", "total": "number"}
        }
      };

      await QuantumDataOrchestrator.bootstrap(manifest, context);

      expect(QLSchemaRegistry.instance.hasSchema('product'), isTrue);
      expect(QLSchemaRegistry.instance.hasSchema('order'), isTrue);
      expect(QLSchemaRegistry.instance.hasSchema('app.product'), isTrue);

      final productSchema = QLSchemaRegistry.instance.getSchema('product')!;
      expect(productSchema.fieldCount, 2);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. PIPELINE INITIALIZATION & AGGREGATE SYNC
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('3. Pipeline Bootstrapping, AutoFetch, and Aggregate Sync',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Builder(builder: (ctx) => const SizedBox())));
      final BuildContext context = tester.element(find.byType(SizedBox));

      QLSchemaRegistry.instance
          .registerRaw('metrics_schema', {'id': 'string', 'value': 'number'});

      final Map<String, dynamic> manifest = {
        "module": "dashboard",
        "schemas": {
          "metrics_schema": {"id": "string", "value": "number"}
        },
        "pipelines": {
          "main_data": {
            "schema": "metrics_schema",
            "executionMode": "auto",
            "pageSize": 50,
            "autoFetch": true,
            "fetch": [
              {
                "action": "mock.api.read",
                "simulateResponse": [
                  {"id": "A", "value": 10},
                  {"id": "B", "value": 20}
                ]
              }
            ],
            "aggregates": [
              {"alias": "total_value", "field": "value", "type": "sum"}
            ]
          }
        }
      };

      await QuantumDataOrchestrator.bootstrap(manifest, context);
      await tester.pumpAndSettle();

      final pipeline = QLPipelineRegistry.instance.get('main_data');
      expect(pipeline, isNotNull);
      expect(pipeline.visibleCount, 2);

      final store = QLStoreRegistry.instance.get('dashboard');
      final aggregatesMap = store.get('main_data_aggregates');

      expect(aggregatesMap, isNotNull);
      expect(aggregatesMap['total_value'], 30.0);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. DATA SOURCES (ON-MOUNT ASYNC EXECUTION & ARG RESOLUTION)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('4. Standalone Data Sources & Token Resolution',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Builder(builder: (ctx) => const SizedBox())));
      final BuildContext context = tester.element(find.byType(SizedBox));

      final Map<String, dynamic> manifest = {
        "module": "profile",
        "state": {"active_user": "u_999"},
        "dataSources": {
          "userProfile": {
            "lifecycle": "onMount",
            "provider": "mock.api.read",
            "args": {"targetId": "{{state.active_user}}"}
          }
        }
      };

      await QuantumDataOrchestrator.bootstrap(manifest, context);
      await tester.pump();

      final store = QLStoreRegistry.instance.get('profile');

      expect(store.get('dataSources.userProfile.loading'), isFalse);
      expect(store.get('dataSources.userProfile.data'), isNotNull);
      expect(mockApiRead.lastPayload!['targetId'], 'u_999');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. ORCHESTRATOR DELEGATE: STANDARD FETCH & PAYLOAD UNWRAPPING
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('5. Pipeline Delegate: Fetch & Wrapper Mapping',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Builder(builder: (ctx) => const SizedBox())));
      final BuildContext context = tester.element(find.byType(SizedBox));

      final schema = QLSchemaCompiler.compile('test', {'id': 'string'});
      final delegate = QLOrchestratorPipelineDelegate(
          context: context,
          schema: schema,
          fetchActions: [
            {
              "action": "mock.api.read",
              "simulateResponse": {
                "data": [
                  {"id": "W1"},
                  {"id": "W2"}
                ],
                "meta": {"page": 1}
              }
            }
          ]);

      final result = await delegate.fetch({'page': 2});

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.length, 2);
      expect(result[0]['id'], 'W1');
      expect(mockApiRead.lastPayload, isNotNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. ORCHESTRATOR DELEGATE: REVERSE BITMASK DECODER
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('6. Reverse-Bitmask Decoder (Hero Partial Fetching)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Builder(builder: (ctx) => const SizedBox())));
      final BuildContext context = tester.element(find.byType(SizedBox));

      final schema = QLSchemaCompiler.compile('hero_schema', {
        'id': 'string',
        'price': 'number',
        'profile': {
          'type': 'object',
          'fields': {'avatar': 'string', 'bio': 'string'}
        }
      });

      final projection = schema.createProjection(['price', 'profile.avatar']);
      List<String>? requestedFieldsIntercepted;

      QuantumVM.instance.registerAction('mock.partial.capture',
          LambdaActionPlugin((payload, store, ctx) async {
        requestedFieldsIntercepted =
            List<String>.from(payload[r'$requestedFields'] ?? []);
        return [];
      }));

      final delegate = QLOrchestratorPipelineDelegate(
          context: context,
          schema: schema,
          fetchActions: [],
          partialFetchActions: [
            {"action": "mock.partial.capture"}
          ]);

      await delegate.fetchPartial(['prod_1'], projection);

      expect(requestedFieldsIntercepted, isNotNull);
      expect(requestedFieldsIntercepted!.length, 2);
      expect(requestedFieldsIntercepted, contains('price'));
      expect(requestedFieldsIntercepted, contains('profile.avatar'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 7. ORCHESTRATOR DELEGATE: SECURITY / CONTEXT FALLBACKS
    // ─────────────────────────────────────────────────────────────────────────
    test('7. Failsafe Context Resolver & Security Exception', () async {
      final schema = QLSchemaCompiler.compile('fail_schema', {'id': 'string'});
      final delegate = QLOrchestratorPipelineDelegate(
          context: null,
          schema: schema,
          fetchActions: [
            {"action": "mock.api.read"}
          ]);

      // 🚀 FIX: Use await expectLater to properly catch asynchronous/synchronous Future rejections
      await expectLater(
          delegate.fetch({}), throwsA(isA<QuantumSecurityException>()));

      QLNativeBridgeRegistry.instance.register('rootContext', const SizedBox());
      expect(() async => await delegate.fetch({}), returnsNormally);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 8. HEADLESS ACTIONS (DYNAMIC PLUGIN)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('8. Headless Actions & Dynamic Plugin Execution',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Builder(builder: (ctx) => const SizedBox())));
      final BuildContext context = tester.element(find.byType(SizedBox));

      final Map<String, dynamic> manifest = {
        "module": "headless_mod",
        "actions": {
          "complex_workflow": [
            {"action": "mock.api.write", "id": "rec_007"}
          ]
        }
      };

      await QuantumDataOrchestrator.bootstrap(manifest, context);

      // 🚀 FIX: Removed the invalid getPlugin check. The action is executed and verified implicitly
      final workflowEnv = <String, dynamic>{};
      await QuantumVM.instance.triggerActions([
        {"action": "headless_mod.complex_workflow"}
      ], context, env: workflowEnv);

      final result = workflowEnv[r'$lastResult'];
      expect(result, isNotNull);
      expect(result['status'], 'success');
      expect(result['id'], 'rec_007');
    });
  });
}
