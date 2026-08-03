/*
 * ============================================================================
 * File: text_core.dart
 * 
 * Description:
 * Core typography engine for the Quantum Omni Registry. Maps declarative text 
 * styles into fast, memory-optimized TextSpans driven directly by QEngine's 
 * SIMD Arena.
 * 
 * Key Components:
 * - _buildText: Constructs text nodes, mapping format flags from memory pointers.
 * - QToken mappings: Reads precompiled O(1) bitmasks for font configurations.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart. Relies on QEngine.instance.mem.
 * 
 * Notes:
 * Designed to completely bypass standard Flutter styling overhead by utilizing bitwise flags.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI REGISTRY — TEXT ENGINE
// Part of quantum_omni_registry.dart
// ════════════════════════════════════════════════════════════════════════════

part of '../quantum_omni_registry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — CORE TEXT BUILDER
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildText(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'p');

  String styleStr = '';
  if (subType == 'h1') {
    styleStr = 'text-3xl font-bold';
  } else if (subType == 'h2')
    styleStr = 'text-2xl font-bold';
  else if (subType == 'h3')
    styleStr = 'text-xl font-bold';
  else if (subType == 'label')
    styleStr = 'text-xs font-semibold uppercase tracking-wide';
  else
    styleStr = 'text-md';

  final String nodeStyle = ctx.node.style ?? '';
  final String propStyle = ctx.string('style');
  final String combinedStyle = '$nodeStyle $propStyle'.trim();
  if (combinedStyle.isNotEmpty) styleStr += ' $combinedStyle';

  if (subType == 'code') styleStr = '$styleStr font-mono text-sm';
  if (subType == 'rich') styleStr = '$styleStr leading-relaxed';

  final QToken ptr = QEngine.instance.compiler.compile(styleStr);
  final QSimdArena mem = QEngine.instance.mem;

  final int tFlags = mem.textFlags[ptr.id];
  final int fPtr = ptr.fPtr;
  final int cPtr = ptr.cPtr;

  // 🚀 FIX: Removed hardcoded 0xFF0F172A.
  // If memory is 0, it falls back to null, allowing native Dark Mode & DefaultTextStyle inheritance to work flawlessly!
  final int rawColor = mem.c32[cPtr + QC32.text];
  final Color? textColor = rawColor != 0 ? Color(rawColor) : null;

  final TextStyle ts = TextStyle(
    color: textColor,
    fontSize: mem.f32[fPtr + QF32.fontSize] > 0
        ? mem.f32[fPtr + QF32.fontSize]
        : 14.0,
    fontWeight: (tFlags & QTextFlags.fontBold) != 0
        ? FontWeight.bold
        : FontWeight.normal,
    fontStyle: (tFlags & QTextFlags.fontItalic) != 0
        ? FontStyle.italic
        : FontStyle.normal,
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

  // 🚀 THE FIX FOR TEXT CLICKS: Ensure text elements correctly capture taps if placed on them!
  final VoidCallback? tapAction =
      ctx.action('onClick') ?? ctx.action('onTap') ?? ctx.action('action');

  Widget textWidget;

  if (ctx.children.isNotEmpty) {
    final span = TextSpan(
      style: ts,
      children: ctx.children
          .map((c) =>
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: c))
          .toList(),
    );
    if (isSelectable) {
      textWidget = SelectableText.rich(
        span,
        textAlign: align,
        maxLines: maxLines,
        textWidthBasis: TextWidthBasis.parent,
        contextMenuBuilder: (context, editableTextState) =>
            AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState),
      );
    } else {
      textWidget = Text.rich(
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
  } else {
    final String content = ctx.string('text', fallback: ctx.string('value'));
    if (isSelectable) {
      textWidget = SelectableText(
        content,
        style: ts,
        textAlign: align,
        maxLines: maxLines,
        textWidthBasis: TextWidthBasis.parent,
        contextMenuBuilder: (context, editableTextState) =>
            AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState),
      );
    } else {
      textWidget = Text(
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
  }

  // Inject gesture detector ONLY if action exists, flattening the tree.
  if (tapAction != null) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tapAction,
      child: textWidget,
    );
  }

  return textWidget;
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — ALIAS REGISTRATION
// ─────────────────────────────────────────────────────────────────────────────

final QuantumDomain textDomain = quantumDomain('text')
    .surface('text', _buildText, defaultSurface: true)
    .install((vm) {
      vm.defineAlias('text', 'text',
          description: 'Base text alias.', tags: const ['text']);
      vm.defineAlias('p', 'text:p',
          description: 'Paragraph alias.', tags: const ['text']);
      vm.defineAlias('h1', 'text:h1',
          description: 'Heading 1 alias.', tags: const ['text']);
      vm.defineAlias('h2', 'text:h2',
          description: 'Heading 2 alias.', tags: const ['text']);
      vm.defineAlias('h3', 'text:h3',
          description: 'Heading 3 alias.', tags: const ['text']);
      vm.defineAlias('label', 'text:label',
          description: 'Label alias.', tags: const ['text']);
      vm.defineAlias('code', 'text:code',
          description: 'Code alias.', tags: const ['text']);
      vm.defineAlias('rich', 'text:rich',
          description: 'Rich text alias.', tags: const ['text']);
    })
    .build();

class TextCoreExporter implements QuantumCoreExporter {
  const TextCoreExporter();

  @override
  void export(QuantumVM vm) {
    vm.installDomain(textDomain);
  }
}

