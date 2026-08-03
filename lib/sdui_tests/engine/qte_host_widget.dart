/*
 * ============================================================================
 * File: qte_host_widget.dart
 * 
 * Description:
 * Provides the visual hosting environment for Quantum Test Engine (QTE) tests.
 * It wraps Server-Driven UI (SDUI) blueprints in a controlled Flutter widget tree,
 * complete with a fixed viewport size, a dedicated data store, and mocked initial state,
 * allowing tests to run in a deterministic sandbox.
 * 
 * Key Components:
 * - QTEDataScope: Injects test-scoped data into a QLDataStore before children are built.
 * - QTEHostWidget: The root MaterialApp shell that sets up the test viewport and encapsulates the SDUI rendering.
 * - QTEHostBuilder: A factory utility to build the QTEHostWidget from a parsed QTETestFile JSON definition.
 * 
 * Dependencies/Relationships:
 * Depends on Flutter material library, quantum_layout, and qte_schema.dart.
 * It acts as the bridge between the test definitions and the actual QuantumVM renderer.
 * 
 * Notes:
 * Mocks defined in the test file are seeded into the store prior to rendering, which
 * allows network or data source interactions to be intercepted and resolved locally
 * within the test environment.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE HOST WIDGET — qte_host_widget.dart
// Wraps SDUI in a controlled test environment with fixed viewport & data store.
// ══════════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:quantum_layout/quantum.dart';
import 'qte_schema.dart';

/// Injects test-scoped data into a QLDataStore before building children.
class QTEDataScope extends StatefulWidget {
  final QLDataStore store;
  final Map<String, dynamic> initialState;
  final Map<String, dynamic> env;
  final Widget child;

  const QTEDataScope({
    super.key,
    required this.store,
    required this.initialState,
    required this.env,
    required this.child,
  });

  @override
  State<QTEDataScope> createState() => _QTEDataScopeState();
}

class _QTEDataScopeState extends State<QTEDataScope> {
  @override
  void initState() {
    super.initState();
    // Seed initial state
    widget.initialState.forEach((key, value) {
      widget.store.set(key, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return QLDataScope(
      localData: widget.env,
      localStore: widget.store,
      moduleStore: widget.store,
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// The root host widget for QTE tests.
/// Provides a fixed viewport, MaterialApp shell, and seeded data store.
class QTEHostWidget extends StatelessWidget {
  final QLBlueprint blueprint;
  final QLDataStore store;
  final QTEViewport viewport;
  final Map<String, dynamic> initialState;
  final Map<String, dynamic> env;
  final Map<String, dynamic> macros;

  const QTEHostWidget({
    super.key,
    required this.blueprint,
    required this.store,
    required this.viewport,
    this.initialState = const {},
    this.env = const {},
    this.macros = const {},
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QTE Host',
      theme: ThemeData.light(useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(viewport.width, viewport.height),
          devicePixelRatio: viewport.pixelRatio,
        ),
        child: SizedBox(
          width: viewport.width,
          height: viewport.height,
          child: QTEDataScope(
            store: store,
            initialState: initialState,
            env: env,
            child: _SDUIRenderer(
              blueprint: blueprint,
              store: store,
              env: env,
              macros: macros,
            ),
          ),
        ),
      ),
    );
  }
}

class _SDUIRenderer extends StatefulWidget {
  final QLBlueprint blueprint;
  final QLDataStore store;
  final Map<String, dynamic> env;
  final Map<String, dynamic> macros;

  const _SDUIRenderer({
    required this.blueprint,
    required this.store,
    required this.env,
    required this.macros,
  });

  @override
  State<_SDUIRenderer> createState() => _SDUIRendererState();
}

class _SDUIRendererState extends State<_SDUIRenderer> {
  @override
  void initState() {
    super.initState();
    widget.store.addPersistenceListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removePersistenceListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return QuantumVM.instance.renderWidget(
      context,
      widget.blueprint,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QTE Host Builder — builds the host from a raw JSON test file
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QTEHostBuilder {
  static void _injectTestKeys(Map<String, dynamic> node) {
    // No-op: QuantumVM automatically wraps nodes with testId in a KeyedSubtree.
  }

  /// Build a QTEHostWidget from a parsed QTETestFile.
  /// Returns both the widget and the store for engine access.
  static ({QTEHostWidget widget, QLDataStore store}) build(QTETestFile testFile) {
    final store = QLDataStore(namespace: 'default');

    // Seed mocks into store (mock data sources response preview)
    for (final mock in testFile.mocks) {
      if (mock.response != null) {
        store.set('__mock.${mock.sourceId}.${mock.operation}', mock.response);
      }
    }

    final Map<String, dynamic> sdui = Map<String, dynamic>.from(testFile.sdui);
    _injectTestKeys(sdui);
    final blueprint = QLBlueprint.fromJson(sdui);

    final widget = QTEHostWidget(
      blueprint: blueprint,
      store: store,
      viewport: testFile.viewport,
      initialState: testFile.initialState,
      env: testFile.env,
    );

    return (widget: widget, store: store);
  }
}
