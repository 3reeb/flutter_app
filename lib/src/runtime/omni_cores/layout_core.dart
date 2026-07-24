part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildLayout

Widget _buildLayout(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String layoutId = ctx.resolvedSubType(
      fallback: ctx.string('layoutId', fallback: ctx.string('id')));

  if (layoutId.isEmpty) {
    return Q('col w-full h-full', children: ctx.children);
  }

  final layoutDef = QMatrixLayoutRegistry.get(layoutId);
  if (layoutDef == null) {
    if (kDebugMode) {
      return ErrorWidget('''Unknown Layout: $layoutId
Path: ${ctx.node.debugPath}''');
    }
    return const SizedBox.shrink();
  }

  return buildQuantumMatrixWidget(
    ctx: ctx.flutterContext,
    node: ctx.node,
    store: ctx.store,
    layoutDef: layoutDef,
    runtimeCache: QMatrixLayoutRegistry.runtimeCache(layoutId),
  );
}

void _registerRichSpatialLayouts(QuantumVM vm) {
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
      'chrome': {
        'padding': 12,
        'zIndex': 20,
      },
      'header': {
        'padding': 12,
        'zIndex': 18,
      },
      'toolbar': {
        'padding': 12,
      },
      'sidebar': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'right',
      },
      'main': {
        'scrollable': true,
        'padding': 16,
      },
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left',
      },
      'panel': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'bottom',
      },
      'status': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 30,
        'padding': 8,
      },
      'overlay': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 100,
      },
      'canvas': {
        'scrollable': true,
        'preserveOverlap': true,
        'padding': 0,
      },
      'notes': {
        'scrollable': true,
        'padding': 12,
      },
      'footer': {
        'padding': 12,
        'zIndex': 18,
      },
      'drawer': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 90,
        'padding': 12,
      },
    },
  });

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
      'chrome': {
        'padding': 12,
        'zIndex': 20,
      },
      'header': {
        'padding': 12,
        'zIndex': 18,
      },
      'sheet': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': false,
        'padding': 24,
        'resizeHandle': 'right',
      },
      'stage': {
        'scrollable': true,
        'padding': 20,
        'preserveOverlap': true,
      },
      'notes': {
        'scrollable': true,
        'padding': 12,
      },
      'inspector': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'reorderable': true,
        'padding': 12,
        'resizeHandle': 'left',
      },
      'thumbnails': {
        'scrollable': true,
        'draggable': true,
        'resizable': true,
        'padding': 10,
        'resizeHandle': 'left',
      },
      'ruler': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 16,
        'padding': 6,
      },
      'guides': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 15,
      },
      'controls': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 50,
        'padding': 10,
      },
      'overlay': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 100,
      },
      'status': {
        'floating': true,
        'preserveOverlap': true,
        'zIndex': 30,
        'padding': 8,
      },
      'footer': {
        'padding': 12,
        'zIndex': 18,
      },
    },
  });

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

  vm.defineAlias('workspace_layout', 'layout:workspace');
  vm.defineAlias('page_layout', 'layout:page');
  vm.defineAlias('app_layout', 'layout:app_shell');
  vm.defineAlias('shell_layout', 'layout:app_shell');
  vm.defineAlias('split_layout', 'layout:split_shell');
  vm.defineAlias('feed_layout', 'layout:feed_shell');
  vm.defineAlias('form_layout', 'layout:form_shell');
  vm.defineAlias('modal_layout', 'layout:modal_shell');
  vm.defineAlias('timeline_layout', 'layout:timeline_shell');
  vm.defineAlias('dashboard_layout', 'layout:workspace',
      defaultProps: {'variant': 'dashboard'});
  vm.defineAlias('document_layout', 'layout:page',
      defaultProps: {'variant': 'document'});
  vm.defineAlias('presentation_layout', 'layout:page',
      defaultProps: {'variant': 'presentation'});
  vm.defineAlias('vscode_layout', 'layout:workspace',
      defaultProps: {'variant': 'code'});
  vm.defineAlias('studio_layout', 'layout:workspace',
      defaultProps: {'variant': 'studio'});
  vm.defineAlias('kanban_layout', 'layout:workspace',
      defaultProps: {'variant': 'board'});
  vm.defineAlias('social_layout', 'layout:feed_shell',
      defaultProps: {'variant': 'social'});
  vm.defineAlias('commerce_layout', 'layout:workspace',
      defaultProps: {'variant': 'dashboard'});
  vm.defineAlias('erp_layout', 'layout:workspace',
      defaultProps: {'variant': 'dashboard'});
  vm.defineAlias('ai_layout', 'layout:workspace',
      defaultProps: {'variant': 'studio'});
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
        if (chunk.isNotEmpty)
          spans.add(TextSpan(text: chunk, style: baseStyle));
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

void _registerLayoutAliases(QuantumVM vm) {
  vm.defineAlias('workspace_layout', 'layout:workspace', description: 'Workspace layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('page_layout', 'layout:page', description: 'Page layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('app_layout', 'layout:app_shell', description: 'App layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('shell_layout', 'layout:app_shell', description: 'Shell layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('split_layout', 'layout:split_shell', description: 'Split layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('feed_layout', 'layout:feed_shell', description: 'Feed layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('form_layout', 'layout:form_shell', description: 'Form layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('modal_layout', 'layout:modal_shell', description: 'Modal layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('timeline_layout', 'layout:timeline_shell', description: 'Timeline layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('dashboard_layout', 'layout:workspace', description: 'Dashboard layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('document_layout', 'layout:page', description: 'Document layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('presentation_layout', 'layout:page', description: 'Presentation layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('vscode_layout', 'layout:workspace', description: 'VS Code style layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('studio_layout', 'layout:workspace', description: 'Studio layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('kanban_layout', 'layout:workspace', description: 'Kanban layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('social_layout', 'layout:feed_shell', description: 'Social layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('commerce_layout', 'layout:workspace', description: 'Commerce layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('erp_layout', 'layout:workspace', description: 'ERP layout alias.', tags: const ['layout', 'alias']);
  vm.defineAlias('ai_layout', 'layout:workspace', description: 'AI layout alias.', tags: const ['layout', 'alias']);
}
