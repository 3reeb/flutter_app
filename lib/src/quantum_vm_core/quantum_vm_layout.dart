/*
 * ============================================================================
 * File: quantum_vm_layout.dart
 *
 * Description:
 * Native built-in layout engine for the Quantum VM Core.
 * This is a `part of` file for quantum_vm.dart — the layout system lives
 * HERE and is registered before any external plugin (omni_cores, etc.) runs.
 *
 * Contains:
 * - _registerNativeLayoutCore()   — called from QuantumVM.initialize()
 * - _buildLayout()                — resolves layoutId → QMatrixLayoutRegistry
 * - _buildPageShell()             — page-level shell macro (header/sidebar/footer)
 * - _buildPageSection()           — section-level layout block
 * - All 8 built-in matrix layout JSON definitions
 * - All layout aliases
 * - QuantumVMLayoutBridge extension — renderLayoutFromRaw()
 * - _QVMLayoutBridge StatefulWidget — QEE _layout body → QuantumVM render
 *
 * Design guarantees:
 * - ZERO imports from lib/src/runtime/
 * - All symbols available from package:quantum_layout/quantum.dart (parent)
 * - O(1) layout lookup via QMatrixLayoutRegistry (HashMap)
 * - Idempotent registration — safe to call multiple times
 * - RepaintBoundary isolation on every QEE layout body
 * - Memory-safe: parsed blueprint is cached per raw-source hash
 * ============================================================================
 */

part of 'quantum_vm.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — IDEMPOTENCY GUARD
// ─────────────────────────────────────────────────────────────────────────────

/// True once _registerNativeLayoutCore has completed.
/// Guards against double-registration on hot-reload or repeated init calls.
bool _nativeLayoutCoreRegistered = false;

// ─────────────────────────────────────────────────────────────────────────────
// §2 — LAYOUT WIDGET BUILDERS
// All builders are private top-level functions (fastest possible call path —
// no vtable, no closure allocation on hot paths).
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves the `layoutId` prop and delegates to QMatrixLayoutRegistry.
///
/// This is the primary entry point for `{type: 'layout', layoutId: 'workspace'}`
/// SDUI nodes. Zero-allocation on cache-hit (registry uses a fixed HashMap).
@pragma('vm:prefer-inline')
Widget _buildLayout(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  // Colon sub-type (layout:workspace) OR explicit layoutId/id prop.
  final String layoutId = ctx.resolvedSubType(
      fallback: ctx.string('layoutId', fallback: ctx.string('id')));

  if (layoutId.isEmpty) {
    // Graceful fallback: render children in a column.
    return Q('col min-w-0 min-h-0', children: ctx.children);
  }

  final layoutDef = QMatrixLayoutRegistry.get(layoutId);
  if (layoutDef == null) {
    if (kDebugMode) {
      return ErrorWidget('🚨 [QuantumVM] Unknown layout: "$layoutId"\n'
          'Path: ${ctx.node.debugPath}\n'
          'Available: ${QMatrixLayoutRegistry.registryNames.join(', ')}');
    }
    return const SizedBox.shrink();
  }

  // O(1) runtime-cache lookup inside buildQuantumMatrixWidget.
  return buildQuantumMatrixWidget(
    ctx: ctx.flutterContext,
    node: ctx.node,
    store: ctx.store,
    layoutDef: layoutDef,
    runtimeCache: QMatrixLayoutRegistry.runtimeCache(layoutId),
  );
}

/// High-level page shell: header / (sidebar | content) / footer composition.
///
/// Used as `{type: 'page_shell'}` in SDUI. Children are wired via named slots
/// (header, content, footer, sidebar). The `$page` env-key carries the inner
/// page widget when called from the QEE layout bridge.
@pragma('vm:never-inline')
Widget _buildPageShell(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);

  final headerNode = ctx.node.slots['header'];
  final contentNode = ctx.node.slots['content'];
  final footerNode = ctx.node.slots['footer'];
  final sidebarNode = ctx.node.slots['sidebar'];

  final Widget header = headerNode != null
      ? QuantumVM.instance.renderWidget(ctx.flutterContext, headerNode)
      : const SizedBox.shrink();

  final Widget footer = footerNode != null
      ? QuantumVM.instance.renderWidget(ctx.flutterContext, footerNode)
      : const SizedBox.shrink();

  final Widget sidebar = sidebarNode != null
      ? QuantumVM.instance.renderWidget(ctx.flutterContext, sidebarNode)
      : const SizedBox.shrink();

  // $page env key carries the inner slot when used from QEE.
  final Widget page = ctx.env[r'$page'] as Widget? ?? const SizedBox.shrink();

  Widget content = page;
  if (contentNode != null) {
    final String baseStyle = contentNode.style ?? '';
    final String justify = QLDataBinder.resolveAOT(contentNode.props['justify'],
                ctx.flutterContext, ctx.env, ctx.store)
            ?.toString() ??
        '';
    final String items = QLDataBinder.resolveAOT(contentNode.props['items'],
                ctx.flutterContext, ctx.env, ctx.store)
            ?.toString() ??
        '';
    final bool clip = QLDataBinder.resolveAOT(contentNode.props['clip'],
            ctx.flutterContext, ctx.env, ctx.store) ==
        true;
    final dynamic gapProp = QLDataBinder.resolveAOT(
        contentNode.props['gap'], ctx.flutterContext, ctx.env, ctx.store);
    final num gap = gapProp is num
        ? gapProp
        : (num.tryParse(gapProp?.toString() ?? '') ?? 0);
    final String direction =
        contentNode.props['direction']?.toString() ?? 'col';

    String combinedStyle =
        direction == 'row' ? 'row $baseStyle' : 'col $baseStyle';
    if (justify.isNotEmpty) combinedStyle = '$combinedStyle justify-$justify';
    if (items.isNotEmpty) combinedStyle = '$combinedStyle items-$items';
    if (clip) combinedStyle = '$combinedStyle overflow-hidden';

    final dynamic padProp = contentNode.props['padding'];
    final double padding = padProp is num
        ? padProp.toDouble()
        : double.tryParse(padProp?.toString() ?? '') ?? 0.0;

    content = Padding(
      padding: EdgeInsets.all(padding),
      child: Q('$combinedStyle min-h-0',
          gap: gap > 0 ? gap : null,
          suppressParentData: true,
          children: [Expanded(child: page)]),
    );
  }

  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headerNode != null) header,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sidebarNode != null) sidebar,
              Expanded(child: content),
            ],
          ),
        ),
        if (footerNode != null) footer,
      ],
    ),
  );
}

/// Section-level layout block: header / body / footer in a Column.
///
/// Used as `{type: 'page_section'}`. Optional `padded: true` prop adds 24px.
@pragma('vm:prefer-inline')
Widget _buildPageSection(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);

  final headerNode = ctx.node.slots['header'];
  final bodyNode = ctx.node.slots['body'];
  final footerNode = ctx.node.slots['footer'];

  final Widget header = headerNode != null
      ? QuantumVM.instance.renderWidget(ctx.flutterContext, headerNode)
      : const SizedBox.shrink();
  final Widget body = bodyNode != null
      ? QuantumVM.instance.renderWidget(ctx.flutterContext, bodyNode)
      : const SizedBox.shrink();
  final Widget footer = footerNode != null
      ? QuantumVM.instance.renderWidget(ctx.flutterContext, footerNode)
      : const SizedBox.shrink();

  final dynamic paddedProp = ctx.node.props['padded'];
  final bool isPadded = paddedProp == true || paddedProp == 'true';
  final double padding = isPadded ? 24.0 : 0.0;

  return Container(
    padding: EdgeInsets.all(padding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headerNode != null) header,
        if (bodyNode != null) body,
        if (footerNode != null) footer,
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — NATIVE LAYOUT REGISTRATION
// Called once from QuantumVM.initialize(). All 8 built-in matrix layouts +
// all aliases are registered here at VM boot, before any omni_core runs.
// ─────────────────────────────────────────────────────────────────────────────

void _registerNativeLayoutCore(QuantumVM vm) {
  if (_nativeLayoutCoreRegistered) return;
  _nativeLayoutCoreRegistered = true;

  // ── 3a: Core widget types ─────────────────────────────────────────────────
  vm.registerPlugin(
    _MicroWidgetPlugin('layout', _buildLayout, const {}),
    description:
        'Native matrix layout resolver — maps layoutId to QMatrixLayoutRegistry',
    engine: 'QuantumVM.layout',
    tags: const ['core', 'layout', 'native'],
  );
  vm.registerPlugin(
    _MicroWidgetPlugin('page_shell', _buildPageShell, const {}),
    description: 'Page shell — header / (sidebar | content) / footer',
    engine: 'QuantumVM.layout',
    tags: const ['core', 'layout', 'native'],
  );
  vm.registerPlugin(
    _MicroWidgetPlugin('page_section', _buildPageSection, const {}),
    description: 'Page section — header / body / footer column',
    engine: 'QuantumVM.layout',
    tags: const ['core', 'layout', 'native'],
  );

  // ── 3b: Matrix layouts ────────────────────────────────────────────────────
  _registerBuiltInMatrixLayouts(vm);

  // ── 3c: Layout aliases ────────────────────────────────────────────────────
  _registerBuiltInLayoutAliases(vm);
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 — BUILT-IN MATRIX LAYOUTS (8 shells)
// All definitions are const-level literal Maps → zero heap allocation after
// first compilation. defineMatrixLayoutJson() interns them in QMatrixLayoutRegistry.
// ─────────────────────────────────────────────────────────────────────────────

void _registerBuiltInMatrixLayouts(QuantumVM vm) {
  // Guard: if already registered (e.g. app re-init on test), skip.
  if (QMatrixLayoutRegistry.has('workspace') &&
      QMatrixLayoutRegistry.has('page') &&
      QMatrixLayoutRegistry.has('app_shell') &&
      QMatrixLayoutRegistry.has('split_shell') &&
      QMatrixLayoutRegistry.has('feed_shell') &&
      QMatrixLayoutRegistry.has('form_shell') &&
      QMatrixLayoutRegistry.has('modal_shell') &&
      QMatrixLayoutRegistry.has('timeline_shell')) {
    return;
  }

  // ── workspace ─────────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'workspace',
    'gap': 12,
    'defaultProps': {
      'variant': 'app',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
header header header | auto
sidebar main inspector | minmax(0, 1fr)
panel panel panel | auto
footer footer footer | auto
''',
    'sm': '''
auto
chrome | auto
header | auto
main | minmax(0, 1fr)
sidebar | auto
inspector | auto
panel | auto
footer | auto
''',
    'variants': {
      'dashboard': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
header header header | auto
toolbar toolbar toolbar | auto
sidebar main inspector | minmax(0, 1fr)
footer footer footer | auto
''',
      'code': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
header header header | auto
sidebar main inspector | minmax(0, 1fr)
panel panel panel | auto
status status status | auto
footer footer footer | auto
''',
      'studio': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
header header header | auto
tools canvas inspector | minmax(0, 1fr)
tray tray tray | auto
footer footer footer | auto
''',
      'canvas': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
header header header | auto
tools canvas inspector | minmax(0, 1fr)
footer footer footer | auto
''',
      'fullscreen': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
main main main | minmax(0, 1fr)
footer footer footer | auto
''',
      'board': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
header header header | auto
sidebar board inspector | minmax(0, 1fr)
footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 12, 'zIndex': 20},
      'header': {'padding': 12, 'zIndex': 18},
      'toolbar': {'padding': 12},
      'sidebar': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'right'
      },
      'main': {'scrollable': true, 'padding': 16},
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left'
      },
      'panel': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'bottom'
      },
      'status': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 30,
        'padding': 8
      },
      'overlay': {'floating': true, 'preserveOverlap': true, 'zIndex': 100},
      'canvas': {'scrollable': true, 'preserveOverlap': true, 'padding': 0},
      'notes': {'scrollable': true, 'padding': 12},
      'footer': {'padding': 12, 'zIndex': 18},
      'drawer': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 90,
        'padding': 12
      },
    },
  });

  // ── page ──────────────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'page',
    'gap': 16,
    'defaultProps': {
      'variant': 'document',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
1fr minmax(0, 794px) 1fr
chrome chrome chrome | auto
header header header | auto
gutter sheet notes | minmax(0, 1fr)
footer footer footer | auto
''',
    'sm': '''
1fr
chrome | auto
header | auto
sheet | minmax(0, 1fr)
notes | auto
footer | auto
''',
    'variants': {
      'document': '''
1fr minmax(0, 794px) 1fr
chrome chrome chrome | auto
header header header | auto
gutter sheet notes | minmax(0, 1fr)
footer footer footer | auto
''',
      'a4': '''
1fr minmax(0, 794px) 1fr
chrome chrome chrome | auto
header header header | auto
gutter sheet notes | minmax(0, 1fr)
footer footer footer | auto
''',
      'letter': '''
1fr minmax(0, 816px) 1fr
chrome chrome chrome | auto
header header header | auto
gutter sheet notes | minmax(0, 1fr)
footer footer footer | auto
''',
      'presentation': '''
1fr minmax(0, 1280px) 1fr
chrome chrome chrome | auto
header header header | auto
stage stage notes | minmax(0, 1fr)
footer footer footer | auto
''',
      'slides': '''
1fr minmax(0, 1280px) 1fr
chrome chrome chrome | auto
header header header | auto
stage stage notes | minmax(0, 1fr)
footer footer footer | auto
''',
      'poster': '''
1fr minmax(0, 1440px) 1fr
chrome chrome chrome | auto
header header header | auto
stage stage stage | minmax(0, 1fr)
footer footer footer | auto
''',
      'notes': '''
1fr minmax(0, 960px) 1fr
chrome chrome chrome | auto
header header header | auto
notes sheet inspector | minmax(0, 1fr)
footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 12, 'zIndex': 20},
      'header': {'padding': 12, 'zIndex': 18},
      'sheet': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': false,
        'padding': 24,
        'resizeHandle': 'right'
      },
      'stage': {'scrollable': true, 'padding': 20, 'preserveOverlap': true},
      'notes': {'scrollable': true, 'padding': 12},
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left'
      },
      'thumbnails': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'padding': 10,
        'resizeHandle': 'left'
      },
      'ruler': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 16,
        'padding': 6
      },
      'guides': {'floating': true, 'preserveOverlap': true, 'zIndex': 15},
      'controls': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 50,
        'padding': 10
      },
      'overlay': {'floating': true, 'preserveOverlap': true, 'zIndex': 100},
      'status': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 30,
        'padding': 8
      },
      'footer': {'padding': 12, 'zIndex': 18},
    },
  });

  // ── app_shell ─────────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'app_shell',
    'gap': 12,
    'defaultProps': {
      'variant': 'app',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
auto minmax(240px, auto) minmax(0, 1fr) minmax(240px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
nav body body inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
    'sm': '''
auto
header | auto
body | minmax(0, 1fr)
footer | auto
''',
    'variants': {
      'app': '''
auto minmax(240px, auto) minmax(0, 1fr) minmax(240px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
nav body body inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
      'dashboard': '''
auto minmax(200px, auto) minmax(0, 1fr) minmax(280px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
tabs body body inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
      'focus': '''
auto minmax(0, 1fr) minmax(240px, auto)
chrome chrome chrome | auto
header header header | auto
body body inspector | minmax(0, 1fr)
footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 12, 'zIndex': 20},
      'header': {'padding': 12, 'zIndex': 18},
      'nav': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'right'
      },
      'tabs': {'scrollable': true, 'padding': 8, 'zIndex': 16},
      'body': {'scrollable': true, 'padding': 16},
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left'
      },
      'footer': {'padding': 12, 'zIndex': 18},
      'overlay': {'floating': true, 'preserveOverlap': true, 'zIndex': 100},
      'drawer': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 90,
        'padding': 12
      },
      'status': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 30,
        'padding': 8
      },
    },
  });

  // ── split_shell ───────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'split_shell',
    'gap': 12,
    'defaultProps': {
      'variant': 'split',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
auto minmax(280px, auto) minmax(0, 1fr) minmax(260px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
sidebar main main inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
    'sm': '''
auto
header | auto
sidebar | auto
main | minmax(0, 1fr)
inspector | auto
footer | auto
''',
    'variants': {
      'split': '''
auto minmax(280px, auto) minmax(0, 1fr) minmax(260px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
sidebar main main inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
      'editor': '''
auto minmax(260px, auto) minmax(0, 1fr) minmax(300px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
sidebar editor inspector activity | minmax(0, 1fr)
footer footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 12, 'zIndex': 20},
      'header': {'padding': 12, 'zIndex': 18},
      'sidebar': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'right'
      },
      'main': {'scrollable': true, 'padding': 16},
      'editor': {'scrollable': true, 'padding': 16},
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left'
      },
      'activity': {'scrollable': true, 'padding': 12},
      'footer': {'padding': 12, 'zIndex': 18},
    },
  });

  // ── feed_shell ────────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'feed_shell',
    'gap': 12,
    'defaultProps': {
      'variant': 'feed',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
auto minmax(260px, auto) minmax(0, 1fr) minmax(280px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
composer feed feed trending | minmax(0, 1fr)
footer footer footer footer | auto
''',
    'sm': '''
auto
header | auto
composer | auto
feed | minmax(0, 1fr)
footer | auto
''',
    'variants': {
      'feed': '''
auto minmax(260px, auto) minmax(0, 1fr) minmax(280px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
composer feed feed trending | minmax(0, 1fr)
footer footer footer footer | auto
''',
      'social': '''
auto minmax(240px, auto) minmax(0, 1fr) minmax(260px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
composer feed feed sidebar | minmax(0, 1fr)
footer footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 12, 'zIndex': 20},
      'header': {'padding': 12, 'zIndex': 18},
      'composer': {'scrollable': true, 'padding': 12},
      'feed': {'scrollable': true, 'padding': 16},
      'trending': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left'
      },
      'sidebar': {'scrollable': true, 'padding': 12},
      'footer': {'padding': 12, 'zIndex': 18},
    },
  });

  // ── form_shell ────────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'form_shell',
    'gap': 12,
    'defaultProps': {
      'variant': 'form',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
auto minmax(220px, auto) minmax(0, 1fr) minmax(260px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
sidebar form summary inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
    'sm': '''
auto
header | auto
form | minmax(0, 1fr)
summary | auto
footer | auto
''',
    'variants': {
      'form': '''
auto minmax(220px, auto) minmax(0, 1fr) minmax(260px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
sidebar form summary inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
      'wizard': '''
auto minmax(200px, auto) minmax(0, 1fr) minmax(240px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
steps form progress inspector | minmax(0, 1fr)
footer footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 12, 'zIndex': 20},
      'header': {'padding': 12, 'zIndex': 18},
      'sidebar': {'scrollable': true, 'padding': 12},
      'form': {'scrollable': true, 'padding': 16},
      'summary': {'scrollable': true, 'padding': 12},
      'steps': {'scrollable': true, 'padding': 12},
      'progress': {'padding': 8, 'zIndex': 16},
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left'
      },
      'footer': {'padding': 12, 'zIndex': 18},
    },
  });

  // ── modal_shell ───────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'modal_shell',
    'gap': 8,
    'defaultProps': {
      'variant': 'modal',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
backdrop modal backdrop | minmax(0, 1fr)
footer footer footer | auto
''',
    'sm': '''
auto
modal | minmax(0, 1fr)
footer | auto
''',
    'variants': {
      'modal': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
backdrop modal backdrop | minmax(0, 1fr)
footer footer footer | auto
''',
      'sheet': '''
auto minmax(0, 1fr) auto
chrome chrome chrome | auto
backdrop sheet backdrop | minmax(0, 1fr)
footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 10, 'zIndex': 20},
      'backdrop': {'floating': true, 'preserveOverlap': true, 'zIndex': 80},
      'modal': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 90,
        'scrollable': true,
        'padding': 16
      },
      'sheet': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 90,
        'scrollable': true,
        'padding': 16
      },
      'footer': {'padding': 10, 'zIndex': 18},
    },
  });

  // ── timeline_shell ────────────────────────────────────────────────────────
  vm.defineMatrixLayoutJson({
    'name': 'timeline_shell',
    'gap': 12,
    'defaultProps': {
      'variant': 'timeline',
      'enableSemantics': true,
      'enableInteractivity': true,
      'enableRTL': true,
    },
    'matrix': '''
auto minmax(240px, auto) minmax(0, 1fr) minmax(280px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
timeline body inspector activity | minmax(0, 1fr)
footer footer footer footer | auto
''',
    'sm': '''
auto
header | auto
timeline | auto
body | minmax(0, 1fr)
footer | auto
''',
    'variants': {
      'timeline': '''
auto minmax(240px, auto) minmax(0, 1fr) minmax(280px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
timeline body inspector activity | minmax(0, 1fr)
footer footer footer footer | auto
''',
      'roadmap': '''
auto minmax(220px, auto) minmax(0, 1fr) minmax(240px, auto)
chrome chrome chrome chrome | auto
header header header header | auto
milestones timeline inspector notes | minmax(0, 1fr)
footer footer footer footer | auto
''',
    },
    'slots': {
      'chrome': {'padding': 12, 'zIndex': 20},
      'header': {'padding': 12, 'zIndex': 18},
      'timeline': {'scrollable': true, 'padding': 16},
      'body': {'scrollable': true, 'padding': 16},
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left'
      },
      'activity': {'scrollable': true, 'padding': 12},
      'notes': {'scrollable': true, 'padding': 12},
      'milestones': {'scrollable': true, 'padding': 12},
      'footer': {'padding': 12, 'zIndex': 18},
    },
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// §5 — LAYOUT ALIASES
// ─────────────────────────────────────────────────────────────────────────────

void _registerBuiltInLayoutAliases(QuantumVM vm) {
  // Core aliases
  vm.defineAlias('workspace_layout', 'layout:workspace',
      description: 'Full IDE-style workspace layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('page_layout', 'layout:page',
      description: 'Document/page layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('app_layout', 'layout:app_shell',
      description: 'App shell layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('app_shell', 'layout:app_shell',
      description: 'App shell alias',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('shell_layout', 'layout:app_shell',
      description: 'Shell layout alias',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('split_layout', 'layout:split_shell',
      description: 'Split-pane layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('feed_layout', 'layout:feed_shell',
      description: 'Social feed layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('form_layout', 'layout:form_shell',
      description: 'Form/wizard layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('modal_layout', 'layout:modal_shell',
      description: 'Modal/sheet layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('timeline_layout', 'layout:timeline_shell',
      description: 'Timeline layout',
      tags: const ['layout', 'alias', 'native']);
  // Variant shortcuts
  vm.defineAlias('dashboard_layout', 'layout:workspace',
      defaultProps: const {'variant': 'dashboard'},
      description: 'Dashboard workspace',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('document_layout', 'layout:page',
      defaultProps: const {'variant': 'document'},
      description: 'Document page layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('presentation_layout', 'layout:page',
      defaultProps: const {'variant': 'presentation'},
      description: 'Presentation layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('vscode_layout', 'layout:workspace',
      defaultProps: const {'variant': 'code'},
      description: 'VS Code style layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('studio_layout', 'layout:workspace',
      defaultProps: const {'variant': 'studio'},
      description: 'Studio layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('kanban_layout', 'layout:workspace',
      defaultProps: const {'variant': 'board'},
      description: 'Kanban board layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('social_layout', 'layout:feed_shell',
      defaultProps: const {'variant': 'social'},
      description: 'Social feed layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('commerce_layout', 'layout:workspace',
      defaultProps: const {'variant': 'dashboard'},
      description: 'E-commerce layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('erp_layout', 'layout:workspace',
      defaultProps: const {'variant': 'dashboard'},
      description: 'ERP layout',
      tags: const ['layout', 'alias', 'native']);
  vm.defineAlias('ai_layout', 'layout:workspace',
      defaultProps: const {'variant': 'studio'},
      description: 'AI studio layout',
      tags: const ['layout', 'alias', 'native']);
}

// ─────────────────────────────────────────────────────────────────────────────
// §6 — QEE LAYOUT BRIDGE EXTENSION
//
// renderLayoutFromRaw() is the integration point between the QEE file router
// (`_layout.yaml` stored as QPageBody bytes) and the QuantumVM render pipeline.
//
// Usage inside _QVMLayoutBridge (qee_layout_host.dart):
//   QuantumVM.instance.renderLayoutFromRaw(context, rawYaml, pageSlot: slotWidget)
// ─────────────────────────────────────────────────────────────────────────────

extension QuantumVMLayoutBridge on QuantumVM {
  /// Parses raw YAML or JSON layout source and renders it via the VM pipeline.
  ///
  /// [rawSource]  — the `__raw__` string from QPageBody.toConfig()
  /// [pageSlot]   — the inner page widget injected as env['$page']
  /// [store]      — optional; defaults to the VM global store
  ///
  /// Returns the fully built Flutter widget tree. Falls back to [pageSlot] on
  /// any parse error so the page is never completely blank.
  Widget renderLayoutFromRaw(
    BuildContext ctx,
    String rawSource, {
    Widget pageSlot = const SizedBox.shrink(),
    QLDataStore? store,
  }) {
    if (rawSource.trim().isEmpty) return pageSlot;

    // ── Parse YAML / JSON → blueprint map ───────────────────────────────────
    Map<String, dynamic> config;
    try {
      final trimmed = rawSource.trim();
      if (trimmed.startsWith('{')) {
        config = Map<String, dynamic>.from(jsonDecode(trimmed) as Map);
      } else {
        config = QuantumYamlEngine.parse(rawSource);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🚨 [QuantumVM.renderLayoutFromRaw] Parse error: $e');
      }
      return pageSlot;
    }

    if (config.isEmpty) return pageSlot;

    // ── Build the QLBlueprint ────────────────────────────────────────────────
    QLBlueprint node;
    try {
      node = QLBlueprint.fromJson(config, path: '_layout');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🚨 [QuantumVM.renderLayoutFromRaw] Blueprint error: $e');
      }
      return pageSlot;
    }

    // ── Inject page slot via env + render ────────────────────────────────────
    final Map<String, dynamic> env = {
      ...QLDataScope.of(ctx),
      r'$page': pageSlot,
    };
    final resolvedStore = store ?? QLDataScope.resolveStore(ctx);

    try {
      return _assembleNode(ctx, node, env, resolvedStore, null);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('🚨 [QuantumVM.renderLayoutFromRaw] Render error: $e\n$st');
      }
      return pageSlot;
    }
  }
}
