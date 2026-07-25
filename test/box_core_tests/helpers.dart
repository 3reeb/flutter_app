// ════════════════════════════════════════════════════════════════════════════
// BOX-CORE TEST HELPERS
// test/box_core_tests/helpers.dart
//
// Shared utilities for ALL box_core SDUI JSON widget tests.
// Every test file in this folder imports this.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL SETUP / TEARDOWN
// Call these in setUpAll / tearDownAll of every test group.
// ─────────────────────────────────────────────────────────────────────────────

void boxCoreSetUp() {
  QLModuleRegistry.instance.clear();
  QLSchemaRegistry.instance.clear();
  QLPipelineRegistry.instance.destroy('default');
  QLStoreRegistry.instance.destroy('default');
  QuantumVM.instance.clearRuntimeCaches();
  clearQuantumInputRegistry();

  QEngine.instance.initialize(initialCapacity: 4096);
  QuantumVM.instance.initialize(workerThreads: 1);
  registerOmniComponents(QuantumVM.instance);

  // Standard action helper used throughout box tests
  QuantumVM.instance.registerAction(
    'state.set',
    LambdaActionPlugin((p, s, c) async {
      s.set(p['key'].toString(), p['value']);
    }),
  );
  QuantumVM.instance.registerAction(
    'state.increment',
    LambdaActionPlugin((p, s, c) async {
      final key = p['key'].toString();
      final current = (s.get(key) as num?) ?? 0;
      s.set(key, current + 1);
    }),
  );
}

void boxCoreTearDown() {
  // Nothing required but keep the hook for future cleanup
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET FACTORY
// Wraps any SDUI JSON in a MaterialApp + Scaffold + bounded SizedBox + store.
// ─────────────────────────────────────────────────────────────────────────────

/// Build a fully mounted widget from SDUI JSON.
/// [screenW] / [screenH] control the bounded size available to the widget tree.
/// [initialStore] pre-seeds the reactive store before rendering.
Widget buildTestWrapper(
  Map<String, dynamic> uiJson, {
  Map<String, dynamic>? initialStore,
  double screenW = 800,
  double screenH = 1200,
}) {
  final store = QLStoreRegistry.instance.defaultStore;
  initialStore?.forEach((k, v) => store.set(k, v));

  final ast = QLBlueprint.fromJson(uiJson);
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: screenW,
        height: screenH,
        child: QLOverlayRoot(
          child: QLDataScope(
            moduleStore: store,
            child: Builder(
              builder: (ctx) => QuantumVM.instance.renderWidget(ctx, ast),
            ),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE ACCESS HELPER
// ─────────────────────────────────────────────────────────────────────────────

QLDataStore get testStore => QLStoreRegistry.instance.defaultStore;

// ─────────────────────────────────────────────────────────────────────────────
// COMMON SDUI PRIMITIVES (text leaf, spacer, color box)
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> textLeaf(String label, {String? style}) => {
      'type': 'text',
      if (style != null) 'style': style,
      'props': {'text': label},
    };

Map<String, dynamic> colorBox(String style, {String label = ''}) => {
      'type': 'box:col',
      'style': style,
      'children': [
        if (label.isNotEmpty) textLeaf(label),
      ],
    };
