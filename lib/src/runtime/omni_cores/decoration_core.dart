/*
 * ============================================================================
 * File: decoration_core.dart
 * 
 * Description:
 * Handles visual embellishments in the Quantum Omni Registry, resolving blur effects, 
 * gradients, borders, shadows, badges, ripples, and rich text formatting onto widgets.
 * 
 * Key Components:
 * - _buildDecoration: Core builder pipeline for wrapping widgets with visual styling.
 * - Decoration subtypes: Implementations for blur, gradient, badge, shadow, etc.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart.
 * 
 * Notes:
 * Heavily relies on cascading styles and composition without deep nesting.
 * ============================================================================
 */
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

final QuantumDomain decorationDomain = quantumDomain('decoration')
    .surface('decoration', _buildDecoration, defaultSurface: true)
    .install((vm) {
      vm.defineAlias('decorate', 'decoration:merge',
          description: 'Decoration merge alias.',
          tags: const ['decoration', 'alias']);
      vm.defineAlias('highlight', 'decoration:text',
          description: 'Highlight text decoration alias.',
          tags: const ['decoration', 'alias']);
      vm.defineAlias('markup', 'decoration:text',
          description: 'Markup text decoration alias.',
          tags: const ['decoration', 'alias']);
    })
    .build();

class DecorationCoreExporter implements QuantumCoreExporter {
  const DecorationCoreExporter();

  @override
  void export(QuantumVM vm) {
    vm.installDomain(decorationDomain);
  }
}

TextStyle _resolveDecorationTextStyle(
  _AliasContext ctx, {
  String extraStyle = '',
}) {
  String styleStr = '';
  final String subtype = ctx.resolvedSubType(fallback: 'p');
  if (subtype == 'h1') {
    styleStr = 'text-3xl font-bold';
  } else if (subtype == 'h2') {
    styleStr = 'text-2xl font-bold';
  } else if (subtype == 'h3') {
    styleStr = 'text-xl font-bold';
  } else if (subtype == 'label') {
    styleStr = 'text-xs font-semibold uppercase tracking-wide';
  } else {
    styleStr = 'text-md';
  }

  final String nodeStyle = ctx.node.style ?? '';
  final String propStyle = ctx.string('style');
  final String combinedStyle = [nodeStyle, propStyle, extraStyle]
      .where((s) => s.trim().isNotEmpty)
      .join(' ')
      .trim();
  if (combinedStyle.isNotEmpty) styleStr += ' $combinedStyle';
  if (subtype == 'code') styleStr = '$styleStr font-mono text-sm';
  if (subtype == 'rich') styleStr = '$styleStr leading-relaxed';

  final QToken ptr = QEngine.instance.compiler.compile(styleStr);
  final QSimdArena mem = QEngine.instance.mem;

  // 🚀 FIX: Use 4x32 textFlags instead of deprecated single flags array
  final int tFlags = mem.textFlags[ptr.id];
  final int fPtr = ptr.fPtr;
  final int cPtr = ptr.cPtr;

  return TextStyle(
    color: Color(mem.c32[cPtr + QC32.text] != 0
        ? mem.c32[cPtr + QC32.text]
        : 0xFF0F172A),
    fontSize: mem.f32[fPtr + QF32.fontSize] > 0
        ? mem.f32[fPtr + QF32.fontSize]
        : 14.0,
    fontWeight: (tFlags & QTextFlags.fontBold) != 0
        ? FontWeight.bold
        : FontWeight.normal,
    fontStyle: (tFlags & QTextFlags.fontItalic) != 0
        ? FontStyle.italic
        : FontStyle.normal,
    // 🚀 NEW: Support underline & strike-through mapped from the new compiler
    decoration: (tFlags & QTextFlags.underline) != 0
        ? TextDecoration.underline
        : ((tFlags & QTextFlags.strikeThrough) != 0
            ? TextDecoration.lineThrough
            : TextDecoration.none),
    letterSpacing: mem.f32[fPtr + QF32.letterSpacing] != 0
        ? mem.f32[fPtr + QF32.letterSpacing]
        : null,
    height: mem.f32[fPtr + QF32.lineHeight],
  );
}

InlineSpan _buildDecorationPartSpan(
  _AliasContext ctx,
  Map<String, dynamic> part,
  TextStyle baseStyle,
) {
  final String text = (part['text'] ?? part['value'] ?? '').toString();
  final String style = (part['style'] ?? part['textStyle'] ?? '').toString();
  final bool selected = part['selected'] == true;
  final String selectedStyle =
      (part['selectedStyle'] ?? part['highlightStyle'] ?? '').toString();
  final String mergedStyle = [style, if (selected) selectedStyle]
      .where((s) => s.trim().isNotEmpty)
      .join(' ')
      .trim();
  final TextStyle spanStyle = mergedStyle.isEmpty
      ? baseStyle
      : baseStyle
          .merge(_resolveDecorationTextStyle(ctx, extraStyle: mergedStyle));

  final dynamic child = part['child'] ?? part['widget'] ?? part['content'];
  final dynamic action = part['onTap'] ?? part['action'];
  if (child is Map) {
    final blueprint = QLBlueprint.fromJson(
      Map<String, dynamic>.from(child.cast<String, dynamic>()),
      path: '${ctx.node.debugPath}.decoration.part',
    );
    final Widget widget =
        QuantumVM.instance.renderWidget(ctx.flutterContext, blueprint);
    if (action != null || selected) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: action == null
              ? null
              : () => ctx.action(action.toString())?.call(),
          child: widget,
        ),
      );
    }
    return WidgetSpan(alignment: PlaceholderAlignment.middle, child: widget);
  }

  if (action != null) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ctx.action(action.toString())?.call(),
        child: Text(text, style: spanStyle),
      ),
    );
  }

  return TextSpan(text: text, style: spanStyle);
}

Widget _buildDecorationRichText(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final TextAlign align = ctx.string('align') == 'center'
      ? TextAlign.center
      : (ctx.string('align') == 'right' ? TextAlign.right : TextAlign.start);
  final bool selectable = ctx.boolean('selectable', fallback: false);
  final TextStyle baseStyle = _resolveDecorationTextStyle(ctx);
  final String text = ctx.string('text', fallback: ctx.string('value'));
  final dynamic rawParts =
      ctx.prop('parts') ?? ctx.prop('spans') ?? ctx.prop('segments');

  final List<InlineSpan> spans = <InlineSpan>[];
  if (rawParts is List && rawParts.isNotEmpty) {
    for (final part in rawParts) {
      if (part is Map) {
        spans.add(_buildDecorationPartSpan(
          ctx,
          Map<String, dynamic>.from(part.cast<String, dynamic>()),
          baseStyle,
        ));
      } else {
        spans.add(TextSpan(text: part.toString(), style: baseStyle));
      }
    }
  } else if (text.isNotEmpty) {
    final String match = ctx.string('match');
    final dynamic selectedChild =
        ctx.prop('selectedChild') ?? ctx.prop('replaceChild');
    final String selectedStyle = ctx.string('selectedStyle');
    if (match.isNotEmpty && text.contains(match)) {
      final parts = text.split(match);
      for (int i = 0; i < parts.length; i++) {
        final chunk = parts[i];
        if (chunk.isNotEmpty) {
          spans.add(TextSpan(text: chunk, style: baseStyle));
        }
        if (i < parts.length - 1) {
          if (selectedChild is Map) {
            final blueprint = QLBlueprint.fromJson(
              Map<String, dynamic>.from(selectedChild.cast<String, dynamic>()),
              path: '${ctx.node.debugPath}.decoration.selected',
            );
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: QuantumVM.instance
                  .renderWidget(ctx.flutterContext, blueprint),
            ));
          } else if (selectedChild is Widget) {
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: selectedChild,
            ));
          } else {
            spans.add(TextSpan(
              text: match,
              style: baseStyle.merge(
                _resolveDecorationTextStyle(ctx, extraStyle: selectedStyle),
              ),
            ));
          }
        }
      }
    } else {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
  }

  final TextSpan span = TextSpan(style: baseStyle, children: spans);
  if (selectable) {
    return SelectableText.rich(
      span,
      textAlign: align,
      contextMenuBuilder: (context, editableTextState) =>
          AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState),
    );
  }
  return Text.rich(span, textAlign: align);
}
