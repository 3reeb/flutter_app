// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI REGISTRY — DECORATION ENGINE
// Part of quantum_omni_registry.dart
// ════════════════════════════════════════════════════════════════════════════

part of '../quantum_omni_registry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — CORE DECORATION BUILDER
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildDecoration(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'merge');

  // 1. Resolve Body Content
  Widget body;
  if (subType == 'text' ||
      subType == 'rich' ||
      subType == 'span' ||
      ctx.prop('text') != null ||
      ctx.prop('parts') != null ||
      ctx.prop('spans') != null ||
      ctx.prop('segments') != null) {
    body = _buildDecorationRichText(rawCtx);
  } else if (ctx.children.isNotEmpty) {
    // 🚀 EXTREME FLATTENING: Use raw Column instead of Q('col w-full') to avoid token compilation overhead
    body = ctx.children.length == 1
        ? ctx.children.first
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ctx.children);
  } else {
    body = const SizedBox.shrink();
  }

  // 2. Apply Specific Decoration Subtypes
  if (subType == 'blur') {
    double sigma = ctx.number('sigma', fallback: 10.0);
    if (sigma.isNaN || sigma < 0) sigma = 0.0;
    body = ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColoredBox(
          color: ctx.color('tintColor', fallback: const Color(0x1AFFFFFF))!,
          child: body,
        ),
      ),
    );
  } else if (subType == 'gradient') {
    body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ctx.color('beginColor', fallback: Colors.blue) ?? Colors.blue,
            ctx.color('endColor', fallback: Colors.purple) ?? Colors.purple,
          ],
        ),
      ),
      child: body,
    );
  } else if (subType == 'border') {
    double width = ctx.number('width', fallback: 1.0);
    if (width.isNaN || width < 0) width = 0.0;
    double radius = ctx.number('radius', fallback: 0.0);
    if (radius.isNaN || radius < 0 || radius.isInfinite) radius = 0.0;

    body = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: ctx.color('color', fallback: Colors.black) ?? Colors.black,
          width: width,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: body,
    );
  } else if (subType == 'shadow') {
    body = DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color:
                ctx.color('color', fallback: Colors.black26) ?? Colors.black26,
            blurRadius: ctx.number('blur', fallback: 4.0),
            spreadRadius: ctx.number('spread', fallback: 0.0),
            offset: Offset(
                ctx.number('x', fallback: 0.0), ctx.number('y', fallback: 2.0)),
          )
        ],
      ),
      child: body,
    );
  } else if (subType == 'badge') {
    final String label = ctx.string('label');
    if (label.isNotEmpty) {
      body = Stack(
        clipBehavior: Clip.none,
        children: [
          body,
          Positioned(
            right: ctx.number('right', fallback: -8.0),
            top: ctx.number('top', fallback: -8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ctx.color('color', fallback: Colors.red),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: ctx.color('textColor', fallback: Colors.white),
                  fontSize: ctx.number('fontSize', fallback: 10.0),
                ),
              ),
            ),
          ),
        ],
      );
    }
  } else if (subType == 'skeleton') {
    return _QLSkeletonWidget(
      width: ctx.number('width', fallback: double.infinity),
      height: ctx.number('height', fallback: double.infinity),
      borderRadius: ctx.number('radius', fallback: 8.0),
    );
  } else if (subType == 'ripple') {
    // 🚀 ROBUST TAP FALLBACK FOR RIPPLE
    final VoidCallback? tapAction =
        ctx.action('onClick') ?? ctx.action('onTap') ?? ctx.action('action');
    return InkWell(
      onTap: tapAction,
      splashColor: ctx.color('splashColor'),
      highlightColor: ctx.color('highlightColor'),
      child: body,
    );
  }

  // 3. Apply Merged Styles (Cascading Engine)
  final String mergedStyle = [ctx.string('mergeStyle'), ctx.string('style')]
      .where((s) => s.trim().isNotEmpty)
      .join(' ')
      .trim();

  Widget node = body;

  if (mergedStyle.isNotEmpty) {
    // 🚀 EXTREME FLATTENING: Use raw Q widget
    node = Q(
      mergedStyle,
      suppressParentData: ctx.boolean('suppressParentData',
          fallback: true), // Prevent parent data conflicts
      children: [node],
    );
  }

  // 4. Structural Modifiers
  if (ctx.boolean('clip', fallback: false)) {
    node = ClipRect(child: node);
  }
  if (ctx.boolean('ignorePointer', fallback: false)) {
    node = IgnorePointer(ignoring: true, child: node);
  }
  if (ctx.boolean('absorbPointer', fallback: false)) {
    node = AbsorbPointer(absorbing: true, child: node);
  }

  // 5. Consolidated Interaction Modifiers
  final VoidCallback? tapAction =
      ctx.action('onClick') ?? ctx.action('onTap') ?? ctx.action('action');
  final VoidCallback? doubleTapAction = ctx.action('onDoubleTap');
  final VoidCallback? longPressAction = ctx.action('onLongPress');
  final VoidCallback? hoverEnterAction =
      ctx.action('onHover', localPayload: {'hovered': true});
  final VoidCallback? hoverExitAction =
      ctx.action('onHover', localPayload: {'hovered': false});

  if (tapAction != null ||
      doubleTapAction != null ||
      longPressAction != null ||
      hoverEnterAction != null ||
      hoverExitAction != null) {
    node = MouseRegion(
      onEnter: hoverEnterAction != null ? (_) => hoverEnterAction() : null,
      onExit: hoverExitAction != null ? (_) => hoverExitAction() : null,
      cursor: tapAction != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tapAction,
        onDoubleTap: doubleTapAction,
        onLongPress: longPressAction,
        child: node,
      ),
    );
  }

  // 6. Final Implicit Behaviors (Drag, Drop, Magneto, Tooltip)
  node = _applyImplicitBehaviors(ctx, node);

  return node;
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — ALIAS REGISTRATION
// ─────────────────────────────────────────────────────────────────────────────

void _registerDecorationAliases(QuantumVM vm) {
  vm.defineAlias('decorate', 'decoration:merge',
      description: 'Decoration merge alias.',
      tags: const ['decoration', 'alias']);
  vm.defineAlias('highlight', 'decoration:text',
      description: 'Highlight text decoration alias.',
      tags: const ['decoration', 'alias']);
  vm.defineAlias('markup', 'decoration:text',
      description: 'Markup text decoration alias.',
      tags: const ['decoration', 'alias']);
}
