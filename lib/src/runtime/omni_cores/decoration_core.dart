part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildDecoration


Widget _buildDecoration(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'merge');

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
    if (ctx.children.length == 1) {
      body = ctx.children.first;
    } else {
      body = Q('col w-full', children: ctx.children);
    }
  } else {
    body = const SizedBox.shrink();
  }

  if (subType == 'blur') {
    double sigma = ctx.number('sigma', fallback: 10.0);
    if (sigma.isNaN || sigma < 0) sigma = 0.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(color: ctx.color('tintColor', fallback: const Color(0x1AFFFFFF)), child: body),
      ),
    );
  }
  if (subType == 'gradient') {
    return DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [ctx.color('beginColor', fallback: Colors.blue) ?? Colors.blue, ctx.color('endColor', fallback: Colors.purple) ?? Colors.purple])), child: body);
  }
  if (subType == 'border') {
    double width = ctx.number('width', fallback: 1.0);
    if (width.isNaN || width < 0) width = 0.0;
    double radius = ctx.number('radius', fallback: 0.0);
    if (radius.isNaN || radius < 0 || radius.isInfinite) radius = 0.0;
    return DecoratedBox(decoration: BoxDecoration(border: Border.all(color: ctx.color('color', fallback: Colors.black) ?? Colors.black, width: width), borderRadius: BorderRadius.circular(radius)), child: body);
  }
  if (subType == 'shadow') {
    return DecoratedBox(decoration: BoxDecoration(boxShadow: [BoxShadow(color: ctx.color('color', fallback: Colors.black26) ?? Colors.black26, blurRadius: ctx.number('blur', fallback: 4.0), spreadRadius: ctx.number('spread', fallback: 0.0), offset: Offset(ctx.number('x', fallback: 0.0), ctx.number('y', fallback: 2.0)))]), child: body);
  }
  if (subType == 'badge') {
    final String label = ctx.string('label');
    if (label.isEmpty) return body;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        Positioned(
          right: ctx.number('right', fallback: -8.0), top: ctx.number('top', fallback: -8.0),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: ctx.color('color', fallback: Colors.red), borderRadius: BorderRadius.circular(10)), child: Text(label, style: TextStyle(color: ctx.color('textColor', fallback: Colors.white), fontSize: ctx.number('fontSize', fallback: 10.0)))),
        ),
      ],
    );
  }
  if (subType == 'skeleton') {
    return _QLSkeletonWidget(width: ctx.number('width', fallback: double.infinity), height: ctx.number('height', fallback: double.infinity), borderRadius: ctx.number('radius', fallback: 8.0));
  }
  if (subType == 'ripple') {
    return InkWell(
      onTap: () => ctx.action('onTap')?.call(),
      splashColor: ctx.color('splashColor'),
      highlightColor: ctx.color('highlightColor'),
      child: body,
    );
  }


  final String mergedStyle = [ctx.string('mergeStyle'), ctx.string('style')]
      .where((s) => s.trim().isNotEmpty)
      .join(' ')
      .trim();

  Widget node = body;
  if (mergedStyle.isNotEmpty) {
    node = QLBox(
      style: mergedStyle,
      suppressParentData: ctx.boolean('suppressParentData', fallback: false),
      child: node,
    );
  }

  if (ctx.boolean('clip', fallback: false)) {
    node = ClipRect(child: node);
  }
  if (ctx.boolean('ignorePointer', fallback: false)) {
    node = IgnorePointer(ignoring: true, child: node);
  }
  if (ctx.boolean('absorbPointer', fallback: false)) {
    node = AbsorbPointer(absorbing: true, child: node);
  }
  if (ctx.prop('onTap') != null ||
      ctx.prop('onDoubleTap') != null ||
      ctx.prop('onLongPress') != null) {
    node = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          ctx.prop('onTap') == null ? null : () => ctx.action('onTap')?.call(),
      onDoubleTap: ctx.prop('onDoubleTap') == null
          ? null
          : () => ctx.action('onDoubleTap')?.call(),
      onLongPress: ctx.prop('onLongPress') == null
          ? null
          : () => ctx.action('onLongPress')?.call(),
      child: node,
    );
  }

  if (ctx.prop('onHover') != null) {
    node = MouseRegion(
      onEnter: (_) =>
          ctx.action('onHover', localPayload: {'hovered': true})?.call(),
      onExit: (_) =>
          ctx.action('onHover', localPayload: {'hovered': false})?.call(),
      child: node,
    );
  }

  node = _applyImplicitBehaviors(rawCtx, node);

  return node;
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 11: TEMPLATE (Native Hybrids & Slot Passthrough)
// ════════════════════════════════════════════════════════════════════════════

void _registerDecorationAliases(QuantumVM vm) {
  vm.defineAlias('decorate', 'decoration:merge', description: 'Decoration merge alias.', tags: const ['decoration', 'alias']);
  vm.defineAlias('highlight', 'decoration:text', description: 'Highlight text decoration alias.', tags: const ['decoration', 'alias']);
  vm.defineAlias('markup', 'decoration:text', description: 'Markup text decoration alias.', tags: const ['decoration', 'alias']);
}
