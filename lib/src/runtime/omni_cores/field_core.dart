part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildField

Widget _buildField(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'text');
  final String id = ctx.string('id', fallback: 'fld_${ctx.node.hashCode}');
  final String bindPath = ctx.string('bind');

  final bool readOnly = ctx.boolean('readOnly');
  final bool disabled = ctx.boolean('disabled');

// 1. Add this right at the top of _buildField inside quantum_omni_registry.dart:
  if (subType == '__proxy_children') {
    return Column(
        children: ctx.children); // Renders the pre-built widgets passed down
  }
  // ─── 🚀 HEADLESS TEXT INPUTS ─────────────────────────────────────────────
  if ([
    'text',
    'email',
    'url',
    'tel',
    'password',
    'number',
    'search',
    'textarea',
    'multiline'
  ].contains(subType)) {
    final ctrl = _resolveFieldController<QLTextController>(
        ctx,
        id,
        bindPath,
        (form) => QLTextController(
            path: bindPath.isNotEmpty ? bindPath : id, form: form));

    if (disabled)
      ctrl.disable();
    else
      ctrl.enable();
    ctrl.setReadOnly(readOnly);

    // Resolve specific input configurations
    TextInputType kbType = TextInputType.text;
    bool obscure = subType == 'password';
    int minLines = 1;
    int maxLines = 1;

    if (subType == 'email')
      kbType = TextInputType.emailAddress;
    else if (subType == 'tel')
      kbType = TextInputType.phone;
    else if (subType == 'url')
      kbType = TextInputType.url;
    else if (subType == 'number')
      kbType = TextInputType.numberWithOptions(decimal: ctx.boolean('decimal'));
    else if (subType == 'textarea' || subType == 'multiline') {
      kbType = TextInputType.multiline;
      minLines = ctx.integer('minLines', fallback: 3);
      maxLines = ctx.integer('maxLines', fallback: 8);
    }

    return QLRawTextInput(
        controller: ctrl,
        keyboardType: kbType,
        obscureText: obscure,
        minLines: minLines,
        maxLines: subType == 'password' ? 1 : maxLines,
        cursorColor:
            Color(QThemeGraph().color('brand-primary', fallback: 0xFF3B82F6)),
        selectionColor:
            Color(QThemeGraph().color('brand-primary', fallback: 0xFF3B82F6))
                .withValues(alpha: 0.08),
        backgroundCursorColor: Colors.grey,
        textStyle: const TextStyle(
            fontSize: 15, color: Color(0xFF0F172A), height: 1.3),

        // 🚀 THE MAGIC: The UI Shell Builder
        shellBuilder: (context, state, rawInputWidget) {
          Color borderColor = const Color(0xFFE2E8F0); // slate-200
          Color bgColor = Colors.white;

          if (state.isDisabled) {
            bgColor = const Color(0xFFF8FAFC); // slate-50
          } else if (state.hasError) {
            borderColor = const Color(0xFFEF4444); // red-500
            bgColor = const Color(0xFFFEF2F2); // red-50
          } else if (state.isFocused) {
            borderColor = Color(
                QThemeGraph().color('brand-primary', fallback: 0xFF3B82F6));
          } else if (state.isHovered) {
            borderColor = const Color(0xFFCBD5E1); // slate-300
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating Label Animation
              if (ctx.string('label').isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: state.isEmpty && !state.isFocused ? 0 : 6,
                    left: state.isEmpty && !state.isFocused ? 12 : 2,
                  ),
                  child: Text(
                    ctx.string('label'),
                    style: TextStyle(
                      fontSize: state.isEmpty && !state.isFocused ? 15 : 12,
                      fontWeight:
                          state.isFocused ? FontWeight.w600 : FontWeight.w500,
                      color: state.hasError
                          ? const Color(0xFFEF4444)
                          : (state.isFocused
                              ? Color(QThemeGraph()
                                  .color('brand-primary', fallback: 0xFF3B82F6))
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ),

              // Container Shell
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius:
                      BorderRadius.circular(ctx.number('radius', fallback: 10)),
                  border: Border.all(
                      color: borderColor, width: state.isFocused ? 2 : 1),
                  boxShadow: state.isFocused && !state.hasError
                      ? [
                          BoxShadow(
                              color: borderColor.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 1)
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: subType == 'textarea'
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (ctx.slot('prefix') != null) ...[
                      ctx.slot('prefix')!,
                      const SizedBox(width: 8)
                    ],

                    // The actual headless text entry
                    Expanded(
                      child: (!state.isEmpty ||
                              state.isFocused ||
                              ctx.string('label').isEmpty)
                          ? rawInputWidget
                          : Text(ctx.string('placeholder'),
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 15)),
                    ),

                    if (subType == 'search' && !state.isEmpty)
                      GestureDetector(
                        onTap: () => ctrl.clear(),
                        child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.close,
                                size: 16, color: Color(0xFF94A3B8))),
                      ),
                    if (ctx.slot('suffix') != null) ...[
                      const SizedBox(width: 8),
                      ctx.slot('suffix')!
                    ],
                  ],
                ),
              ),

              // Error Text
              if (state.hasError && state.errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(state.errorText!,
                          style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          );
        });
  }

  // ─── 🚀 HEADLESS TOGGLES & CHECKBOXES ────────────────────────────────────
  if (['toggle', 'checkbox', 'radio'].contains(subType)) {
    final ctrl = _resolveFieldController<QLBoolController>(
        ctx,
        id,
        bindPath,
        (form) => QLBoolController(
            path: bindPath.isNotEmpty ? bindPath : id,
            form: form,
            initialValue: ctx.boolean('initialValue')));

    if (disabled)
      ctrl.disable();
    else
      ctrl.enable();
    ctrl.setReadOnly(readOnly);

    return QLRawToggle(
      controller: ctrl,
      builder: (context, state, value, t) {
        final Color activeColor =
            Color(QThemeGraph().color('brand-primary', fallback: 0xFF3B82F6));
        final Color inactiveColor = const Color(0xFFCBD5E1); // slate-300

        // ── APPLE-STYLE SWITCH ──
        if (subType == 'toggle') {
          final bgColor = Color.lerp(inactiveColor, activeColor, t);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: state.isFocused ? activeColor : Colors.transparent,
                      width: state.isFocused ? 2 : 0),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Align(
                      // Math translates t (0 to 1) into Alignment (-1 to 1)
                      alignment: Alignment(-1.0 + (t * 2), 0.0),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1))
                              ]),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              if (ctx.string('label').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(ctx.string('label'),
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF334155))),
                )
            ],
          );
        }

        // ── CHECKBOX / RADIO ──
        final bool isRadio = subType == 'radio';
        final Color borderColor = value ? activeColor : inactiveColor;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? activeColor : Colors.white,
                shape: isRadio ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isRadio ? null : BorderRadius.circular(6),
                border: Border.all(
                    color: state.isFocused ? activeColor : borderColor,
                    width: state.isFocused ? 2 : 1.5),
              ),
              child: Center(
                child: isRadio
                    ? Transform.scale(
                        scale: t,
                        child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle)))
                    : Transform.scale(
                        scale: t,
                        child: const Icon(Icons.check,
                            size: 14, color: Colors.white)),
              ),
            ),
            if (ctx.string('label').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(ctx.string('label'),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF334155))),
              )
          ],
        );
      },
    );
  }

  // ─── 🚀 HEADLESS SLIDER ──────────────────────────────────────────────────
  if (subType == 'slider') {
    final ctrl = _resolveFieldController<QLNumberController>(
      ctx,
      id,
      bindPath,
      (form) => QLNumberController(
        path: bindPath.isNotEmpty ? bindPath : id,
        form: form,
        initialValue: ctx.number('initialValue'),
      ),
    );

    if (disabled) {
      ctrl.disable();
    } else {
      ctrl.enable();
    }
    ctrl.setReadOnly(readOnly);

    return LayoutBuilder(builder: (context, constraints) {
      final double safeW =
          constraints.maxWidth.isFinite ? constraints.maxWidth : 150.0;

      return SizedBox(
        height: 40,
        width: safeW,
        child: QLRawSlider(
          controller: ctrl,
          min: ctx.number('min', fallback: 0.0),
          max: ctx.number('max', fallback: 100.0),
          divisions:
              ctx.integer('divisions') > 0 ? ctx.integer('divisions') : null,
          builder: (context, state) {
            final Color activeColor = Color(
                QThemeGraph().color('brand-primary', fallback: 0xFF3B82F6));

            double safePercent = 0.0;
            try {
              safePercent = state.percent;
              if (safePercent.isNaN || safePercent.isInfinite)
                safePercent = 0.0;
            } catch (e) {
              safePercent = 0.0;
            }

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: safePercent,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(-1.0 + (safePercent * 2), 0.0),
                  child: FractionalTranslation(
                    translation: const Offset(0.0, 0.0),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 100),
                      scale: state.isDragging ? 1.3 : 1.0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: state.isFocused
                                  ? activeColor
                                  : const Color(0xFFCBD5E1),
                              width: state.isFocused ? 2 : 1),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      );
    });
  }

  // ── field:cell — Notion/Excel inline cell editor ───────────────────────────
  if (subType == 'cell') {
    final String valKey = ctx.string('bind');
    final QLSignal sig = ctx.store.signal(valKey);
    return _QLInlineCellNode(signal: sig, readOnly: readOnly, env: ctx.env);
  }

  // ── field:rich_text — Rich text formatting toolbar & editor ───────────────
  if (subType == 'rich_text') {
    final String valKey = ctx.string('bind');
    final QLSignal sig = ctx.store.signal(valKey);
    return _QLRichTextNode(signal: sig, env: ctx.env);
  }

// ─── 🚀 HEADLESS MEDIA (100% JSON DRIVEN) ────────────────────────────────
  if (['media', 'file', 'image', 'upload'].contains(subType)) {
    final ctrl = _resolveFieldController<QLMediaController>(
      ctx,
      id,
      bindPath,
      (form) => QLMediaController(
          path: bindPath.isNotEmpty ? bindPath : id, form: form),
    );

    if (disabled)
      ctrl.disable();
    else
      ctrl.enable();
    ctrl.setReadOnly(readOnly);

    return QLRawMedia(
        controller: ctrl,
        builder: (context, state, api) {
          // 🚀 INJECT STATE INTO THE ENVIRONMENT SO JSON CAN READ IT
          final mediaEnv = {
            ...ctx.env,
            r'$media': {
              'hasFile': api.hasMedia,
              'src': api.src ?? '',
              'isHovered': state.isHovered,
              'isFocused': state.isFocused,
              'hasError': state.hasError,
              'errorText': state.errorText ?? '',
              'isDisabled': state.isDisabled,
            }
          };

          // Determine which slot to show based on state
          final QLBlueprint? contentSlot = api.hasMedia
              ? ctx.node.slots['preview']
              : ctx.node.slots['empty'];

          // Fallback layout if JSON is incomplete
          final QLBlueprint layout = ctx.node.slots['layout'] ??
              QLBlueprint.fromJson({
                "type": "box:col",
                "style":
                    "w-full min-h-120 rounded-12 border-2 border-slate-200 flex-center overflow-hidden relative",
                "children": []
              });

          // 🚀 WRAP IN DATASCOPE TO PASS ENV TO CHILDREN
          return QLDataScope(
              localData: mediaEnv,
              child: QuantumVM.instance.renderWidget(
                context,
                _cloneNodeWithPrefix(layout, bindPath,
                    overrideChildren: contentSlot != null ? [contentSlot] : []),
              ));
        });
  }

  // ─── 🚀 HEADLESS BLOCKS & ARRAYS (100% JSON DRIVEN) ──────────────────────
  if (['array', 'blocks', 'list'].contains(subType)) {
    final ctrl = _resolveFieldController<QLFieldController<List<dynamic>>>(
      ctx,
      id,
      bindPath,
      (form) => throw Exception(
          "Array Controllers MUST be generated by QLSchemaFormFactory."),
    );

    return QLRawArray<dynamic>(
        controller: ctrl,
        builder: (context, state, api) {
          final QLBlueprint? itemTemplate = ctx.node.slots['item'];

          // 🚀 THE MAGIC: Generate children using the JSON `item` slot, injecting exact indices!
          final List<Widget> childrenWidgets = [];
          for (int i = 0; i < api.items.length; i++) {
            if (itemTemplate != null) {
              final cloned =
                  _cloneNodeWithPrefix(itemTemplate, api.pathFor(api.items[i]));
              childrenWidgets.add(QLDataScope(localData: {
                r'$index': i,
                r'$isFirst': i == 0,
                r'$isLast': i == api.items.length - 1,
                r'$arrayPath': bindPath,
              }, child: QuantumVM.instance.renderWidget(context, cloned)));
            }
          }

          // Layout container defaults to Column, but JSON can override it to Row, Wrap, Grid, etc!
          final QLBlueprint layout = ctx.node.slots['layout'] ??
              QLBlueprint.fromJson({
                "type": "box:col",
                "style": "w-full gap-12",
                "children": []
              });

          // Wrap the layout with array state variables
          return QLDataScope(
              localData: {
                ...ctx.env,
                r'$array': {
                  'length': api.items.length,
                  'isEmpty': api.items.isEmpty,
                  'hasError': state.hasError,
                  'errorText': state.errorText ?? '',
                  'path': bindPath,
                }
              },
              // 🚀 Inject the dynamic children into the JSON layout container
              child: QuantumVM.instance.renderWidget(
                  context,
                  _cloneNodeWithPrefix(layout, bindPath, overrideChildren: [
                    ...layout.children,
                    // We inject a special proxy node that yields the generated Flutter widgets
                    QLBlueprint.fromJson({"type": "__proxy_children"})
                  ])));
        });
  }
  return Text('Unknown field subtype: $subType',
      style: const TextStyle(color: Colors.red));
}

// Inline Cell Node (Excel/Notion block cell editor)
class _QLInlineCellNode extends StatefulWidget {
  final QLSignal signal;
  final bool readOnly;
  final Map<String, dynamic> env;
  const _QLInlineCellNode(
      {required this.signal, required this.readOnly, required this.env});
  @override
  State<_QLInlineCellNode> createState() => _QLInlineCellNodeState();
}

class _QLInlineCellNodeState extends State<_QLInlineCellNode> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.signal.value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing || widget.readOnly) {
      return GestureDetector(
        onDoubleTap: () => setState(() => _editing = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration:
              BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: Text(widget.signal.value?.toString() ?? '',
              style: const TextStyle(fontSize: 14)),
        ),
      );
    }
    return TextField(
      controller: _ctrl,
      autofocus: true,
      onSubmitted: (val) {
        widget.signal.value = val;
        setState(() => _editing = false);
      },
    );
  }
}

// Rich Text Node
class _QLRichTextNode extends StatefulWidget {
  final QLSignal signal;
  final Map<String, dynamic> env;
  const _QLRichTextNode({required this.signal, required this.env});
  @override
  State<_QLRichTextNode> createState() => _QLRichTextNodeState();
}

class _QLRichTextNodeState extends State<_QLRichTextNode> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.signal.value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          IconButton(
              icon: const Icon(Icons.format_bold, size: 18), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.format_italic, size: 18),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.format_underlined, size: 18),
              onPressed: () {}),
        ]),
        TextField(
            controller: _ctrl,
            maxLines: 4,
            onChanged: (v) => widget.signal.value = v),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 4: TEXT (Typography)
// ════════════════════════════════════════════════════════════════════════════

void _registerFieldAliases(QuantumVM vm) {
  vm.defineAlias('text_field', 'field:text',
      description: 'Text field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('textarea', 'field:multiline',
      description: 'Multiline field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('email_field', 'field:email',
      description: 'Email field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('password_field', 'field:password',
      description: 'Password field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('number_field', 'field:number',
      description: 'Number field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('search_field', 'field:search',
      description: 'Search field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('date_field', 'field:date',
      description: 'Date field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('select_field', 'field:select',
      description: 'Select field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('toggle', 'field:toggle',
      description: 'Toggle field alias.', tags: const ['field', 'alias']);
  vm.defineAlias('slider', 'field:slider',
      description: 'Slider field alias.', tags: const ['field', 'alias']);
}

// 2. Update the helper at the bottom:
QLBlueprint _cloneNodeWithPrefix(QLBlueprint node, String pathPrefix,
    {List<QLBlueprint>? overrideChildren}) {
  final Map<String, dynamic> json = node.toJson();

  void updateBinds(Map<String, dynamic> map) {
    if (map['props'] is Map && map['props']['bind'] != null) {
      final currentBind = map['props']['bind'].toString();
      if (!currentBind.startsWith(pathPrefix)) {
        map['props']['bind'] = '$pathPrefix.$currentBind';
      }
    }
    if (map['children'] is List) {
      for (final child in map['children'])
        if (child is Map) updateBinds(child as Map<String, dynamic>);
    }
    if (map['slots'] is Map) {
      for (final child in (map['slots'] as Map).values)
        if (child is Map) updateBinds(child as Map<String, dynamic>);
    }
  }

  updateBinds(json);
  final bp = QLBlueprint.fromJson(json);

  return overrideChildren != null
      ? QLBlueprint(
          type: bp.type,
          props: bp.props,
          style: bp.style,
          slots: bp.slots,
          children: overrideChildren)
      : bp;
}
