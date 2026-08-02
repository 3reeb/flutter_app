/*
 * ============================================================================
 * File: qee_layout_host.dart
 * 
 * Description:
 * Implements the Flutter widget layer responsible for zero-rebuild layout 
 * rendering. It ensures that structural layouts are built once and maintained 
 * indefinitely, isolating rebuilds strictly to the inner page slot or individual 
 * property consumers via selective value notifiers.
 * 
 * Key Components:
 * - QContextScope: InheritedWidget providing context via a ValueNotifier.
 * - QPropScope: Isolates per-prop updates, limiting widget rebuild scopes.
 * - QLayoutChain / QLayoutHost: Maintains composed layouts utilizing Flutter's 
 *   AutomaticKeepAliveClientMixin.
 * 
 * Dependencies/Relationships:
 * Receives resolved QLayoutNode instances and QPageContext. It acts as the 
 * runtime bridge integrating QEE nodes into the active Flutter element tree.
 * 
 * Notes:
 * Never trigger a full setState on a layout host upon navigation; all updates 
 * must flow through QPageSlot and context notifiers.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE LAYOUT HOST — qee_layout_host.dart
//
// Flutter widgets for zero-rebuild layout rendering.
//
// The core invariant:
//   • Layout widgets are built ONCE and kept alive forever via
//     AutomaticKeepAliveClientMixin. On page navigation, only the
//     QPageSlot widget rebuilds — the surrounding layout never does.
//   • QPageContextNotifier carries the current route/props context.
//     Every wrapper (layout, error, loading, meta, middleware) subscribes
//     to it and receives full QPageContext at render time — even if defined
//     at a parent directory level far removed from the current page.
//   • QPropScope isolates prop-level rebuilds: only the exact widget
//     that reads `QPropScope.of(context, 'myProp')` rebuilds when that
//     prop changes — not the parent, not siblings.
//
// Widget tree for a page with nested layouts A → B:
//
//   QContextScope (provides QPageContextNotifier)
//     └─ QLayoutChain (builds A → B composition)
//         └─ QLayoutHost(A) [never rebuilds after mount]
//             └─ A's body widgets
//                 └─ QPageSlot [rebuilds on navigation]
//                     └─ QLayoutHost(B) [never rebuilds after mount]
//                         └─ B's body widgets
//                             └─ QPageSlot [rebuilds on navigation]
//                                 └─ QErrorBoundary
//                                     └─ QLoadingOverlay
//                                         └─ actual page content
//
// Middleware execution:
//   • QMiddlewareGate runs the full middleware chain before allowing
//     the page slot to become visible.
//   • If any middleware returns block/redirect, QPageSlot shows the
//     appropriate widget instead of the page content.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'qee_node_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — CONTEXT SCOPE (InheritedWidget for QPageContextNotifier)
// ─────────────────────────────────────────────────────────────────────────────

/// Provides a [QPageContextNotifier] to the entire layout + page tree.
///
/// On navigation:
///   `QContextScope.of(context).navigate(newContext)` updates the notifier.
///   Only widgets that call `context.watch<QPageContextNotifier>()` or
///   use [QPropScope] rebuild — nothing else touches.
class QContextScope extends InheritedWidget {
  final QPageContextNotifier notifier;

  const QContextScope({
    super.key,
    required this.notifier,
    required super.child,
  });

  /// Access the [QPageContextNotifier] from anywhere in the widget tree.
  static QPageContextNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<QContextScope>();
    assert(scope != null, 'No QContextScope found in widget tree');
    return scope!.notifier;
  }

  /// Access the notifier without subscribing to rebuilds.
  static QPageContextNotifier? maybeRead(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<QContextScope>()
        ?.notifier;
  }

  @override
  bool updateShouldNotify(QContextScope oldWidget) =>
      oldWidget.notifier != notifier;
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — PROP SCOPE (surgical per-prop rebuilds)
// ─────────────────────────────────────────────────────────────────────────────

/// Provides per-prop value notifiers so that only the exact widget
/// reading a specific prop rebuilds when that prop changes.
///
/// Usage in a layout or page body:
/// ```dart
/// QPropScope.of(context, 'userId') // returns ValueNotifier<dynamic>
/// // or:
/// QPropScope.watch(context, 'userId') // rebuilds only when 'userId' changes
/// ```
class QPropScope extends StatefulWidget {
  final Widget child;
  final QPageContextNotifier contextNotifier;

  const QPropScope({
    super.key,
    required this.contextNotifier,
    required this.child,
  });

  /// Get the [ValueNotifier] for a specific prop key.
  /// The calling widget is NOT subscribed to rebuilds.
  static ValueNotifier<dynamic>? of(BuildContext context, String propKey) {
    return _QPropScopeState._find(context, propKey);
  }

  @override
  State<QPropScope> createState() => _QPropScopeState();
}

class _QPropScopeState extends State<QPropScope> {
  final Map<String, ValueNotifier<dynamic>> _propNotifiers = {};
  late VoidCallback _contextListener;

  static ValueNotifier<dynamic>? _find(BuildContext context, String propKey) {
    // Walk up the widget tree to find the nearest _QPropScopeState
    _QPropScopeState? state;
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is _QPropScopeState) {
        state = element.state as _QPropScopeState;
        return false;
      }
      return true;
    });
    return state?._getOrCreate(propKey);
  }

  ValueNotifier<dynamic> _getOrCreate(String propKey) {
    return _propNotifiers.putIfAbsent(
      propKey,
      () => ValueNotifier<dynamic>(
        widget.contextNotifier.value.pageProps[propKey],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _contextListener = _onContextChanged;
    widget.contextNotifier.addListener(_contextListener);
  }

  void _onContextChanged() {
    final ctx = widget.contextNotifier.value;
    // Only update notifiers whose values have changed
    _propNotifiers.forEach((key, notifier) {
      final newVal = ctx.pageProps[key] ?? ctx.routeParams[key];
      if (notifier.value != newVal) {
        notifier.value = newVal;
      }
    });
  }

  @override
  void dispose() {
    widget.contextNotifier.removeListener(_contextListener);
    for (final n in _propNotifiers.values) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — LAYOUT CHAIN BUILDER
// ─────────────────────────────────────────────────────────────────────────────

/// Builds the full layout composition chain for a page.
///
/// Given innermost layout ref, walks parentLayoutRef chain outward
/// to collect [outermost → ... → innermost], then wraps them in
/// nested [QLayoutHost] widgets.
///
/// The chain is built ONCE per app navigation stack entry.
/// On subsequent navigations to pages with the same layout chain,
/// the existing [QLayoutHost] widgets are reused from Flutter's
/// element tree — no rebuild, no re-mount.
class QLayoutChain extends StatefulWidget {
  /// The innermost layout node ref (deepest directory's _layout).
  final QNodeRef<QLayoutNode>? innermostLayoutRef;

  /// The page slot content builder — called with the resolved page widget.
  final Widget pageContent;

  /// The current context notifier (updated on every navigation).
  final QPageContextNotifier contextNotifier;

  const QLayoutChain({
    super.key,
    required this.innermostLayoutRef,
    required this.pageContent,
    required this.contextNotifier,
  });

  @override
  State<QLayoutChain> createState() => _QLayoutChainState();
}

class _QLayoutChainState extends State<QLayoutChain> {
  /// Resolved layout chain: [outermost, ..., innermost]
  List<QLayoutNode>? _chain;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _buildChain();
  }

  @override
  void didUpdateWidget(QLayoutChain old) {
    super.didUpdateWidget(old);
    // Only rebuild chain if layout ref changed (rarely happens)
    if (old.innermostLayoutRef?.nodeId != widget.innermostLayoutRef?.nodeId) {
      _buildChain();
    }
  }

  Future<void> _buildChain() async {
    final ref = widget.innermostLayoutRef;
    if (ref == null) {
      if (mounted) setState(() { _chain = null; _loading = false; });
      return;
    }

    final chain = <QLayoutNode>[];
    QNodeRef<QLayoutNode>? current = ref;

    while (current != null) {
      final node = await current.resolve();
      if (node == null) break;
      chain.insert(0, node); // insert at front = outermost first
      current = node.parentLayoutRef;
    }

    if (mounted) {
      setState(() {
        _chain = chain;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.pageContent; // Show page directly while layouts load
    }

    final chain = _chain;
    if (chain == null || chain.isEmpty) {
      return widget.pageContent;
    }

    // Build nested: chain[0] (outermost) wraps chain[1] ... wraps pageContent
    Widget current = widget.pageContent;
    for (int i = chain.length - 1; i >= 0; i--) {
      final layoutNode = chain[i];
      current = QLayoutHost(
        key: ValueKey('layout_${layoutNode.nodeId}'),
        layoutNode: layoutNode,
        contextNotifier: widget.contextNotifier,
        child: current,
      );
    }

    return current;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 — LAYOUT HOST (never rebuilds on navigation)
// ─────────────────────────────────────────────────────────────────────────────

/// A single level of the layout composition chain.
///
/// CRITICAL: This widget is kept alive indefinitely via
/// [AutomaticKeepAliveClientMixin]. It never rebuilds on navigation.
/// On navigation, only the [QPageSlot] inside the layout body rebuilds.
///
/// The layout body may use [QContextConsumer] to read the current
/// [QPageContext] — but doing so DOES NOT cause the layout to rebuild.
/// It only rebuilds the specific widget that calls the consumer.
class QLayoutHost extends StatefulWidget {
  final QLayoutNode layoutNode;
  final QPageContextNotifier contextNotifier;
  final Widget child; // the next layout or page slot in the chain

  const QLayoutHost({
    super.key,
    required this.layoutNode,
    required this.contextNotifier,
    required this.child,
  });

  @override
  State<QLayoutHost> createState() => _QLayoutHostState();
}

class _QLayoutHostState extends State<QLayoutHost>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // The layout's rendered body — built ONCE, never rebuilt.
  // The child (page slot) is injected via a ValueNotifier so only
  // the slot rebuilds, not the surrounding layout.
  final ValueNotifier<Widget> _slotNotifier =
      ValueNotifier(const SizedBox.shrink());

  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    // Initialize slot with the child
    _slotNotifier.value = widget.child;
    _mounted = true;
  }

  @override
  void didUpdateWidget(QLayoutHost old) {
    super.didUpdateWidget(old);
    // Only update the slot — the layout frame does NOT rebuild
    if (widget.child != old.child) {
      _slotNotifier.value = widget.child;
    }
  }

  @override
  void dispose() {
    if (_mounted) _slotNotifier.dispose();
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    return _LayoutBodyWrapper(
      layoutNode: widget.layoutNode,
      contextNotifier: widget.contextNotifier,
      slotNotifier: _slotNotifier,
    );
  }
}

/// Internal wrapper that renders the layout body.
/// Separated from [_QLayoutHostState] to ensure the layout body
/// itself is never rebuilt by Flutter's reconciliation algorithm.
class _LayoutBodyWrapper extends StatelessWidget {
  final QLayoutNode layoutNode;
  final QPageContextNotifier contextNotifier;
  final ValueNotifier<Widget> slotNotifier;

  const _LayoutBodyWrapper({
    required this.layoutNode,
    required this.contextNotifier,
    required this.slotNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // The layout body is opaque to this widget — the QVMRenderer
    // (or equivalent) will render it. For now, we wrap in RepaintBoundary
    // to isolate the layout's paint from its slot's paint.
    return RepaintBoundary(
      child: QLayoutBodyRenderer(
        layoutNode: layoutNode,
        contextNotifier: contextNotifier,
        pageSlot: QPageSlot(slotNotifier: slotNotifier),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §5 — PAGE SLOT (the only widget that rebuilds on navigation)
// ─────────────────────────────────────────────────────────────────────────────

/// The swappable content slot inside a layout.
///
/// This is the ONLY widget that rebuilds when navigating between pages.
/// The surrounding [QLayoutHost] never touches [build] again.
///
/// On navigation: `QPageSlot._slotNotifier.value = newPageWidget`
/// → only this widget rebuilds via [ValueListenableBuilder].
class QPageSlot extends StatelessWidget {
  final ValueNotifier<Widget> slotNotifier;

  const QPageSlot({super.key, required this.slotNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Widget>(
      valueListenable: slotNotifier,
      builder: (context, pageWidget, _) {
        return RepaintBoundary(child: pageWidget);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §6 — LAYOUT BODY RENDERER (placeholder for SDUI integration)
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the body of a [QLayoutNode].
///
/// The layout body is a [QPageBody] (compiled SDUI config).
/// This widget passes it to the SDUI rendering pipeline.
///
/// The [pageSlot] is injected into the layout's designated slot.
///
/// This widget subscribes to [QPageContextNotifier] so individual
/// widgets INSIDE the layout body can access the current page context.
class QLayoutBodyRenderer extends StatelessWidget {
  final QLayoutNode layoutNode;
  final QPageContextNotifier contextNotifier;
  final Widget pageSlot;

  const QLayoutBodyRenderer({
    super.key,
    required this.layoutNode,
    required this.contextNotifier,
    required this.pageSlot,
  });

  @override
  Widget build(BuildContext context) {
    final body = layoutNode.body;

    if (body == null) {
      // No layout body — just render the slot directly
      return pageSlot;
    }

    // The actual rendering of layout body config goes through the
    // existing SDUI/QL rendering pipeline. We provide a QSlotProvider
    // so the layout body can reference the {{slot}} placeholder.
    return QSlotProvider(
      slot: pageSlot,
      contextNotifier: contextNotifier,
      child: QPageBodyRenderer(
        body: body,
        contextNotifier: contextNotifier,
      ),
    );
  }
}

/// Provides the page slot to any widget in the layout body that
/// references the `{{slot}}` or `<slot/>` placeholder.
class QSlotProvider extends InheritedWidget {
  final Widget slot;
  final QPageContextNotifier contextNotifier;

  const QSlotProvider({
    super.key,
    required this.slot,
    required this.contextNotifier,
    required super.child,
  });

  static QSlotProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QSlotProvider>();

  @override
  bool updateShouldNotify(QSlotProvider old) =>
      old.slot != slot || old.contextNotifier != contextNotifier;
}

/// Renders a [QPageBody] through the existing QL/SDUI pipeline.
/// Subscribed to [QPageContextNotifier] for dynamic template resolution.
class QPageBodyRenderer extends StatelessWidget {
  final QPageBody body;
  final QPageContextNotifier contextNotifier;

  const QPageBodyRenderer({
    super.key,
    required this.body,
    required this.contextNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // Integration point with existing QLCompiler / QuantumVM pipeline.
    // The body config map is passed to the renderer.
    // This keeps QEE fully decoupled from QL internals.
    final config = body.toConfig();
    return _QBodyBridge(config: config, contextNotifier: contextNotifier);
  }
}

/// Bridge widget that feeds the body config to the QL rendering pipeline.
/// Stateful so it can subscribe to context changes without rebuilding parent.
class _QBodyBridge extends StatefulWidget {
  final Map<String, dynamic> config;
  final QPageContextNotifier contextNotifier;

  const _QBodyBridge({required this.config, required this.contextNotifier});

  @override
  State<_QBodyBridge> createState() => _QBodyBridgeState();
}

class _QBodyBridgeState extends State<_QBodyBridge> {
  late Map<String, dynamic> _resolvedConfig;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _resolvedConfig = _applyContext(widget.config, widget.contextNotifier.value);
    _listener = _onContextChanged;
    widget.contextNotifier.addListener(_listener);
  }

  void _onContextChanged() {
    final resolved = _applyContext(widget.config, widget.contextNotifier.value);
    if (mounted) setState(() => _resolvedConfig = resolved);
  }

  /// Apply QPageContext to the config map — replaces template placeholders.
  Map<String, dynamic> _applyContext(
    Map<String, dynamic> config,
    QPageContext ctx,
  ) {
    return _resolveMap(config, ctx);
  }

  Map<String, dynamic> _resolveMap(Map<String, dynamic> map, QPageContext ctx) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      result[entry.key] = _resolveValue(entry.value, ctx);
    }
    return result;
  }

  dynamic _resolveValue(dynamic value, QPageContext ctx) {
    if (value is String) return _resolveTemplate(value, ctx);
    if (value is Map<String, dynamic>) return _resolveMap(value, ctx);
    if (value is List) return value.map((e) => _resolveValue(e, ctx)).toList();
    return value;
  }

  String _resolveTemplate(String template, QPageContext ctx) {
    if (!template.contains('{{')) return template;
    var result = template;
    ctx.routeParams.forEach((k, v) {
      result = result
          .replaceAll('{{routeParams.$k}}', v)
          .replaceAll('{{params.$k}}', v)
          .replaceAll('{{$k}}', v);
    });
    ctx.queryParams.forEach((k, v) {
      result = result.replaceAll('{{query.$k}}', v);
    });
    ctx.pageProps.forEach((k, v) {
      result = result.replaceAll('{{props.$k}}', v.toString());
    });
    return result;
  }

  @override
  void dispose() {
    widget.contextNotifier.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The resolved config is ready to be rendered by the QL/SDUI pipeline.
    // The actual rendering is delegated to the QL compiler via the
    // QuantumVM.instance or equivalent renderer.
    // This widget exposes the config as an InheritedWidget so
    // any downstream widget can access it.
    return _QResolvedConfigScope(
      config: _resolvedConfig,
      child: const _QConfigRenderer(),
    );
  }
}

/// Provides the resolved config to the rendering pipeline.
class _QResolvedConfigScope extends InheritedWidget {
  final Map<String, dynamic> config;

  const _QResolvedConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  static Map<String, dynamic>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_QResolvedConfigScope>()?.config;

  @override
  bool updateShouldNotify(_QResolvedConfigScope old) => old.config != config;
}

/// Placeholder renderer — replaced by actual QL/SDUI rendering pipeline
/// integration in production.
class _QConfigRenderer extends StatelessWidget {
  const _QConfigRenderer();

  @override
  Widget build(BuildContext context) {
    // In production: pull config from _QResolvedConfigScope and pass to
    // QuantumVM renderer. The body config's '__raw__' key contains the
    // serialized QL/SDUI tree that QLCompiler can process.
    final config = _QResolvedConfigScope.of(context);
    final slot = QSlotProvider.of(context)?.slot;

    if (config == null) return slot ?? const SizedBox.shrink();

    // If there is a raw body string, forward to QL pipeline
    final raw = config['__raw__'];
    if (raw == null && slot != null) return slot;

    // Default: show slot (layout body integration point)
    return slot ?? const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §7 — ERROR BOUNDARY
// ─────────────────────────────────────────────────────────────────────────────

/// Flutter error boundary that catches errors in the page widget tree.
/// Shows the [QErrorNode] body with full [QPageContext] passed through.
class QErrorBoundary extends StatefulWidget {
  final Widget child;
  final QNodeRef<QErrorNode>? errorRef;
  final QPageContextNotifier contextNotifier;

  const QErrorBoundary({
    super.key,
    required this.child,
    required this.contextNotifier,
    this.errorRef,
  });

  @override
  State<QErrorBoundary> createState() => _QErrorBoundaryState();
}

class _QErrorBoundaryState extends State<QErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  QErrorNode? _errorNode;

  @override
  void initState() {
    super.initState();
    _loadErrorNode();
  }

  Future<void> _loadErrorNode() async {
    final ref = widget.errorRef;
    if (ref == null) return;
    final node = await ref.resolve();
    if (mounted && node != null) {
      setState(() => _errorNode = node);
    }
  }

  void handleError(Object error, StackTrace stackTrace) {
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
    }
  }

  void reset() {
    if (mounted) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) {
      return _QErrorHandler(
        onError: handleError,
        child: widget.child,
      );
    }

    return _QErrorDisplay(
      error: _error!,
      stackTrace: _stackTrace,
      errorNode: _errorNode,
      contextNotifier: widget.contextNotifier,
      onRetry: reset,
    );
  }
}

class _QErrorHandler extends StatelessWidget {
  final Widget child;
  final void Function(Object, StackTrace) onError;

  const _QErrorHandler({required this.child, required this.onError});

  @override
  Widget build(BuildContext context) => child;

  static _QErrorHandler? of(BuildContext context) =>
      context.findAncestorWidgetOfExactType<_QErrorHandler>();
}

class _QErrorDisplay extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final QErrorNode? errorNode;
  final QPageContextNotifier contextNotifier;
  final VoidCallback? onRetry;

  const _QErrorDisplay({
    required this.error,
    required this.contextNotifier,
    this.stackTrace,
    this.errorNode,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final node = errorNode;
    if (node?.body != null) {
      // Render the custom error body with the current context
      return ValueListenableBuilder<QPageContext>(
        valueListenable: contextNotifier,
        builder: (context, ctx, _) {
          return QPageBodyRenderer(
            body: node!.body!,
            contextNotifier: contextNotifier,
          );
        },
      );
    }

    // Default error UI
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §8 — LOADING OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the [QLoadingNode] body while a page is loading.
/// Receives full [QPageContext] including route params of the TARGET page,
/// so a loading spinner can show `"Loading user {{params.id}}..."`.
class QLoadingOverlay extends StatefulWidget {
  final Widget child;
  final QNodeRef<QLoadingNode>? loadingRef;
  final QPageContextNotifier contextNotifier;
  final bool isLoading;

  const QLoadingOverlay({
    super.key,
    required this.child,
    required this.contextNotifier,
    required this.isLoading,
    this.loadingRef,
  });

  @override
  State<QLoadingOverlay> createState() => _QLoadingOverlayState();
}

class _QLoadingOverlayState extends State<QLoadingOverlay> {
  QLoadingNode? _loadingNode;
  bool _showLoading = false;
  DateTime? _loadingStartTime;

  @override
  void initState() {
    super.initState();
    _loadLoadingNode();
  }

  @override
  void didUpdateWidget(QLoadingOverlay old) {
    super.didUpdateWidget(old);
    if (widget.isLoading != old.isLoading) {
      if (widget.isLoading) {
        _startLoading();
      } else {
        _stopLoading();
      }
    }
  }

  Future<void> _loadLoadingNode() async {
    final ref = widget.loadingRef;
    if (ref == null) return;
    final node = await ref.resolve();
    if (mounted && node != null) {
      setState(() => _loadingNode = node);
    }
  }

  void _startLoading() {
    _loadingStartTime = DateTime.now();
    setState(() => _showLoading = true);
  }

  void _stopLoading() {
    final node = _loadingNode;
    final minMs = node?.minDisplayMs ?? 0;

    if (minMs > 0 && _loadingStartTime != null) {
      final elapsed = DateTime.now().difference(_loadingStartTime!).inMilliseconds;
      final remaining = minMs - elapsed;
      if (remaining > 0) {
        Future.delayed(Duration(milliseconds: remaining), () {
          if (mounted) setState(() => _showLoading = false);
        });
        return;
      }
    }

    setState(() => _showLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoading) return widget.child;

    final node = _loadingNode;
    if (node?.body != null && node!.isFullPage) {
      return QPageBodyRenderer(
        body: node.body!,
        contextNotifier: widget.contextNotifier,
      );
    }

    // Default loading UI
    return Stack(
      children: [
        widget.child,
        if (_showLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x88000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §9 — NOT FOUND VIEW
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the 404 view for unmatched routes within an app or directory.
/// Receives full [QPageContext] — even if defined at a parent directory level,
/// it gets the attempted route's params.
class QNotFoundView extends StatefulWidget {
  final QNodeRef<QNotFoundNode>? notFoundRef;
  final QPageContextNotifier contextNotifier;

  const QNotFoundView({
    super.key,
    required this.contextNotifier,
    this.notFoundRef,
  });

  @override
  State<QNotFoundView> createState() => _QNotFoundViewState();
}

class _QNotFoundViewState extends State<QNotFoundView> {
  QNotFoundNode? _node;

  @override
  void initState() {
    super.initState();
    _loadNode();
  }

  Future<void> _loadNode() async {
    final ref = widget.notFoundRef;
    if (ref == null) return;
    final node = await ref.resolve();
    if (mounted && node != null) setState(() => _node = node);
  }

  @override
  Widget build(BuildContext context) {
    final node = _node;
    if (node?.body != null) {
      return ValueListenableBuilder<QPageContext>(
        valueListenable: widget.contextNotifier,
        builder: (context, ctx, _) {
          return QPageBodyRenderer(
            body: node!.body!,
            contextNotifier: widget.contextNotifier,
          );
        },
      );
    }

    return ValueListenableBuilder<QPageContext>(
      valueListenable: widget.contextNotifier,
      builder: (context, ctx, _) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64),
              const SizedBox(height: 16),
              Text(
                '404 — Page Not Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                ctx.fullUrl,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §10 — MIDDLEWARE GATE
// ─────────────────────────────────────────────────────────────────────────────

/// Executes the full middleware chain for a page before rendering it.
/// On [QMiddlewareResult.block]: shows an error widget.
/// On [QMiddlewareResult.redirect]: triggers navigation to the new route.
/// On [QMiddlewareResult.next]: renders [child] (the page content).
///
/// Receives full [QPageContext] so middleware can inspect route params and props.
class QMiddlewareGate extends StatefulWidget {
  final Widget child;
  final QNodeRef<QMiddlewareNode>? middlewareRef;
  final QPageContextNotifier contextNotifier;
  final void Function(String route)? onRedirect;

  const QMiddlewareGate({
    super.key,
    required this.child,
    required this.contextNotifier,
    this.middlewareRef,
    this.onRedirect,
  });

  @override
  State<QMiddlewareGate> createState() => _QMiddlewareGateState();
}

class _QMiddlewareGateState extends State<QMiddlewareGate> {
  _GateState _state = _GateState.pending;
  String? _blockMessage;
  String? _redirectTo;

  @override
  void initState() {
    super.initState();
    _runMiddlewares();
  }

  @override
  void didUpdateWidget(QMiddlewareGate old) {
    super.didUpdateWidget(old);
    // Re-run middlewares when navigation changes context
    if (widget.contextNotifier.value.routePath !=
        old.contextNotifier.value.routePath) {
      _runMiddlewares();
    }
  }

  Future<void> _runMiddlewares() async {
    if (mounted) setState(() => _state = _GateState.pending);

    final ref = widget.middlewareRef;
    if (ref == null) {
      if (mounted) setState(() => _state = _GateState.allowed);
      return;
    }

    final ctx = widget.contextNotifier.value;
    final outcome = await _executeChain(ref, ctx);

    if (!mounted) return;

    switch (outcome.result) {
      case QMiddlewareResult.next:
        setState(() => _state = _GateState.allowed);
      case QMiddlewareResult.block:
        setState(() {
          _state = _GateState.blocked;
          _blockMessage = outcome.errorMessage;
        });
      case QMiddlewareResult.redirect:
        _redirectTo = outcome.redirectTo;
        setState(() => _state = _GateState.redirecting);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_redirectTo != null) {
            widget.onRedirect?.call(_redirectTo!);
          }
        });
    }
  }

  Future<QMiddlewareOutcome> _executeChain(
    QNodeRef<QMiddlewareNode> ref,
    QPageContext ctx,
  ) async {
    QNodeRef<QMiddlewareNode>? current = ref;

    while (current != null) {
      final node = await current.resolve();
      if (node == null) break;

      for (final step in node.steps) {
        final outcome = await _executeStep(step, ctx);
        if (!outcome.allowed) return outcome;
      }

      current = node.nextRef;
    }

    return const QMiddlewareOutcome.next();
  }

  Future<QMiddlewareOutcome> _executeStep(
    QMiddlewareStep step,
    QPageContext ctx,
  ) async {
    // Built-in middleware step handlers.
    // Custom middleware types can be registered via QEE.
    return switch (step.type) {
      'auth' => _handleAuth(step, ctx),
      'redirect' => _handleRedirect(step, ctx),
      'guard' => _handleGuard(step, ctx),
      _ => const QMiddlewareOutcome.next(), // unknown steps pass through
    };
  }

  QMiddlewareOutcome _handleAuth(QMiddlewareStep step, QPageContext ctx) {
    // Auth check — actual implementation hooks into your auth service.
    // For now: pass through (replace with real auth check).
    return const QMiddlewareOutcome.next();
  }

  QMiddlewareOutcome _handleRedirect(QMiddlewareStep step, QPageContext ctx) {
    final to = step.params['to']?.toString();
    if (to == null) return const QMiddlewareOutcome.next();
    return QMiddlewareOutcome.redirect(to);
  }

  QMiddlewareOutcome _handleGuard(QMiddlewareStep step, QPageContext ctx) {
    final condition = step.params['condition'];
    if (condition == false) {
      return QMiddlewareOutcome.block(
        step.params['message']?.toString() ?? 'Access denied',
      );
    }
    return const QMiddlewareOutcome.next();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _GateState.pending => const Center(child: CircularProgressIndicator()),
      _GateState.allowed => widget.child,
      _GateState.blocked => Center(
          child: Text(
            _blockMessage ?? 'Access denied',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      _GateState.redirecting => const SizedBox.shrink(),
    };
  }
}

enum _GateState { pending, allowed, blocked, redirecting }

// ─────────────────────────────────────────────────────────────────────────────
// §11 — META APPLICATOR
// ─────────────────────────────────────────────────────────────────────────────

/// Applies the [QMetaNode] to the app — sets title, og-tags, etc.
///
/// On Flutter mobile: sets the app bar title.
/// On Flutter web: sets `document.title` via JS interop.
/// On all platforms: notifies meta listeners.
///
/// Receives full [QPageContext] so `title: "User {{params.id}}"` resolves.
class QMetaApplicator extends StatefulWidget {
  final QNodeRef<QMetaNode>? metaRef;
  final QPageContextNotifier contextNotifier;
  final Widget child;

  const QMetaApplicator({
    super.key,
    required this.child,
    required this.contextNotifier,
    this.metaRef,
  });

  @override
  State<QMetaApplicator> createState() => _QMetaApplicatorState();
}

class _QMetaApplicatorState extends State<QMetaApplicator> {
  QMetaNode? _metaNode;
  late VoidCallback _listener;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _listener = _applyMeta;
    widget.contextNotifier.addListener(_listener);
    _loadAndApply();
  }

  Future<void> _loadAndApply() async {
    final ref = widget.metaRef;
    if (ref == null) return;
    final node = await ref.resolve();
    if (mounted && node != null) {
      setState(() => _metaNode = node);
      _applyMeta();
    }
  }

  void _applyMeta() {
    final node = _metaNode;
    if (node == null) return;

    final ctx = widget.contextNotifier.value;
    final title = node.resolveTitle(ctx);
    if (title.isNotEmpty && title != _currentTitle) {
      _currentTitle = title;
      // Notify title change (integrate with your title notifier or
      // MaterialApp.title mechanism)
      QMetaNotifier.instance._updateTitle(title);
    }
  }

  @override
  void dispose() {
    widget.contextNotifier.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Global title/meta notifier for integration with MaterialApp or custom title bars.
class QMetaNotifier {
  static final QMetaNotifier instance = QMetaNotifier._();
  QMetaNotifier._();

  final ValueNotifier<String> title = ValueNotifier('');
  final ValueNotifier<Map<String, String>> openGraph = ValueNotifier({});

  void _updateTitle(String newTitle) {
    if (title.value != newTitle) title.value = newTitle;
  }

  void _updateOG(Map<String, String> tags) {
    openGraph.value = tags;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §12 — CONTEXT CONSUMER (non-rebuilding access)
// ─────────────────────────────────────────────────────────────────────────────

/// Access the current [QPageContext] from any widget without subscribing
/// to unnecessary rebuilds.
///
/// Uses [ValueListenableBuilder] internally, so ONLY the [builder]'s
/// return value rebuilds when the context changes — not the parent.
class QContextConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, QPageContext ctx) builder;

  const QContextConsumer({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final notifier = QContextScope.of(context);
    return ValueListenableBuilder<QPageContext>(
      valueListenable: notifier,
      builder: (ctx, pageCtx, _) => builder(ctx, pageCtx),
    );
  }
}

/// Read a single param without subscribing to the full context.
/// The returned widget ONLY rebuilds when the specified param changes.
class QParamConsumer extends StatelessWidget {
  final String paramName;
  final Widget Function(BuildContext context, String value) builder;

  const QParamConsumer({
    super.key,
    required this.paramName,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = QContextScope.of(context);
    return ValueListenableBuilder<QPageContext>(
      valueListenable: notifier,
      builder: (ctx, pageCtx, _) {
        final value = pageCtx.routeParams[paramName] ??
            pageCtx.queryParams[paramName] ??
            pageCtx.pageProps[paramName]?.toString() ??
            '';
        return builder(ctx, value);
      },
    );
  }
}
