part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildText

Widget _buildText(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'p');

  // 🚀 FIX: Removed hardcoded light-mode slate colors so text inherits parent cascading colors in Dark Mode
  String styleStr = '';
  if (subType == 'h1')
    styleStr = 'text-3xl font-bold';
  else if (subType == 'h2')
    styleStr = 'text-2xl font-bold';
  else if (subType == 'h3')
    styleStr = 'text-xl font-bold';
  else if (subType == 'label')
    styleStr = 'text-xs font-semibold uppercase tracking-wide';
  else
    styleStr = 'text-md';

  // 🚀 FIX: Merge both Hiccup node styles and Map style properties to resolve custom text colors
  final String nodeStyle = ctx.node.style ?? '';
  final String propStyle = ctx.string('style');
  final String combinedStyle = '$nodeStyle $propStyle'.trim();
  if (combinedStyle.isNotEmpty) styleStr += ' $combinedStyle';

  if (subType == 'code') styleStr = '$styleStr font-mono text-sm';
  if (subType == 'rich') styleStr = '$styleStr leading-relaxed';

  final QToken ptr = QEngine.instance.compiler.compile(styleStr);
  final QSimdArena mem = QEngine.instance.mem;

  // 🚀 FIX: Use 4x32 textFlags instead of deprecated single flags array
  final int tFlags = mem.textFlags[ptr.id];
  final int fPtr = ptr.fPtr;
  final int cPtr = ptr.cPtr;

  final TextStyle ts = TextStyle(
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

  final align = (tFlags & QTextFlags.textCenter) != 0
      ? TextAlign.center
      : ((tFlags & QTextFlags.textRight) != 0
          ? TextAlign.right
          : ((tFlags & QTextFlags.textJustify) != 0
              ? TextAlign.justify
              : TextAlign.start));

  final bool isSelectable = ctx.boolean('selectable', fallback: false);
  final bool softWrap = ctx.boolean('softWrap', fallback: true);
  final int? maxLines =
      ctx.node.props.containsKey('maxLines') ? ctx.integer('maxLines') : null;
  final String overflowMode = ctx.string('overflow', fallback: '');
  final TextOverflow? explicitOverflow = switch (overflowMode) {
    'clip' => TextOverflow.clip,
    'fade' => TextOverflow.fade,
    'visible' => TextOverflow.visible,
    'ellipsis' => TextOverflow.ellipsis,
    _ => null,
  };

  if (ctx.children.isNotEmpty) {
    final span = TextSpan(
      style: ts,
      children: ctx.children
          .map((c) =>
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: c))
          .toList(),
    );
    if (isSelectable) {
      return SelectableText.rich(
        span,
        textAlign: align,
        maxLines: maxLines,
        textWidthBasis: TextWidthBasis.parent,
        // 🚀 FIX: Ensures OS copy/paste menus appear natively
        contextMenuBuilder: (context, editableTextState) =>
            AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState),
      );
    }
    return Text.rich(
      span,
      textAlign: align,
      softWrap: softWrap,
      maxLines: maxLines,
      overflow: explicitOverflow ??
          ((tFlags & QTextFlags.textEllipsis) != 0
              ? TextOverflow.ellipsis
              : (softWrap ? null : TextOverflow.clip)),
    );
  }

  final String content = ctx.string('text', fallback: ctx.string('value'));
  if (isSelectable) {
    return SelectableText(
      content,
      style: ts,
      textAlign: align,
      maxLines: maxLines,
      textWidthBasis: TextWidthBasis.parent,
      contextMenuBuilder: (context, editableTextState) =>
          AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState),
    );
  }

  return Text(
    content,
    style: ts,
    textAlign: align,
    softWrap: softWrap,
    maxLines: maxLines,
    overflow: explicitOverflow ??
        ((tFlags & QTextFlags.textEllipsis) != 0
            ? TextOverflow.ellipsis
            : null),
  );
}

void _registerTextAliases(QuantumVM vm) {
  vm.defineAlias('text', 'text', description: 'Base text alias.', tags: const ['text']);
  vm.defineAlias('p', 'text:p', description: 'Paragraph alias.', tags: const ['text']);
  vm.defineAlias('h1', 'text:h1', description: 'Heading 1 alias.', tags: const ['text']);
  vm.defineAlias('h2', 'text:h2', description: 'Heading 2 alias.', tags: const ['text']);
  vm.defineAlias('h3', 'text:h3', description: 'Heading 3 alias.', tags: const ['text']);
  vm.defineAlias('label', 'text:label', description: 'Label alias.', tags: const ['text']);
  vm.defineAlias('code', 'text:code', description: 'Code alias.', tags: const ['text']);
  vm.defineAlias('rich', 'text:rich', description: 'Rich text alias.', tags: const ['text']);
}
