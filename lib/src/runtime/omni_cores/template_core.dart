part of '../quantum_omni_registry.dart';

void _registerRichDesignSystemTemplates(QuantumVM vm) {
  QLBlueprint bp(Map<String, dynamic> json) => QLBlueprint.fromJson(json);

  Map<String, dynamic> node(
    String type, {
    Map<String, dynamic> props = const {},
    String? style,
    List<Map<String, dynamic>> children = const [],
    Map<String, dynamic>? slots,
  }) =>
      {
        'type': type,
        if (props.isNotEmpty) 'props': props,
        if (style != null) 'style': style,
        if (children.isNotEmpty) 'children': children,
        if (slots != null && slots.isNotEmpty) 'slots': slots,
      };

  QLBlueprint cloneNode(
    QLBlueprint template, {
    Map<String, dynamic> props = const {},
    List<QLBlueprint>? children,
    Map<String, QLBlueprint>? slots,
    String? path,
  }) {
    final Map<String, dynamic> json = template.toJson();
    final Map<String, dynamic> mergedProps =
        Map<String, dynamic>.from(json['props'] as Map? ?? const {});
    mergedProps.addAll(props);
    json['props'] = mergedProps;
    if (children != null) {
      json['children'] =
          children.map((c) => c.toJson()).toList(growable: false);
    }
    if (slots != null) {
      json['slots'] = slots.map((k, v) => MapEntry(k, v.toJson()));
    }
    if (path != null) json['debugPath'] = path;
    return QLBlueprint.fromJson(json, path: path ?? template.debugPath);
  }

  List<QLBlueprint> buildRecursiveMenuItems(
    QTemplateContext ctx,
    List<dynamic> items,
    int level,
  ) {
    final QLBlueprint menuItemTemplate =
        ctx.node.slots['item'] ?? bp(node('template:menu_item'));
    return List<QLBlueprint>.generate(items.length, (int index) {
      final dynamic raw = items[index];
      final Map<String, dynamic> item = raw is Map
          ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
          : <String, dynamic>{'label': raw?.toString() ?? 'Item ${index + 1}'};
      final List<dynamic> children = item['children'] is List
          ? List<dynamic>.from(item['children'] as List)
          : item['items'] is List
              ? List<dynamic>.from(item['items'] as List)
              : const <dynamic>[];

      final List<QLBlueprint> submenuChildren = children.isEmpty
          ? const <QLBlueprint>[]
          : buildRecursiveMenuItems(ctx, children, level + 1);

      final QLBlueprint? submenuSlot = ctx.node.slots['submenu'];
      final Map<String, QLBlueprint> slotMap = <String, QLBlueprint>{};
      if (submenuSlot != null) {
        slotMap['submenu'] = cloneNode(
          submenuSlot,
          props: <String, dynamic>{
            'items': children,
            'level': level + 1,
            'hasChildren': submenuChildren.isNotEmpty,
          },
          children: submenuChildren,
          path: '${ctx.node.debugPath}.submenu[$index]',
        );
      }

      return cloneNode(
        menuItemTemplate,
        props: <String, dynamic>{
          'item': item,
          'index': index,
          'level': level,
          'label': item['label']?.toString() ??
              item['title']?.toString() ??
              'Item ${index + 1}',
          'subtitle': item['subtitle']?.toString() ?? '',
          'value': item['value'],
          'icon': item['icon'],
          'href': item['href'],
          'selected': item['selected'] == true,
          'hasLeading': item['icon'] != null || item['image'] != null,
          'hasSubtitle': (item['subtitle']?.toString() ?? '').isNotEmpty,
          'hasActions': item['actions'] != null || item['trailing'] != null,
          'hasChildren': submenuChildren.isNotEmpty,
          'childrenCount': children.length,
        },
        children: submenuChildren.isEmpty
            ? null
            : [
                if (slotMap['submenu'] != null) slotMap['submenu']!,
              ],
        slots: slotMap.isEmpty ? null : slotMap,
        path: '${ctx.node.debugPath}.item[$index]',
      );
    }, growable: false);
  }

  List<QLBlueprint> buildRowsFromRecords(
    QTemplateContext ctx,
    List<dynamic> items,
    String slotName,
  ) {
    final QLBlueprint rowTemplate =
        ctx.node.slots[slotName] ?? bp(node('template:list_item'));
    return List<QLBlueprint>.generate(items.length, (int index) {
      final dynamic raw = items[index];
      final Map<String, dynamic> item = raw is Map
          ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
          : <String, dynamic>{'label': raw?.toString() ?? 'Item ${index + 1}'};
      final List<dynamic> children = item['children'] is List
          ? List<dynamic>.from(item['children'] as List)
          : item['items'] is List
              ? List<dynamic>.from(item['items'] as List)
              : const <dynamic>[];

      return cloneNode(
        rowTemplate,
        props: <String, dynamic>{
          'item': item,
          'index': index,
          'level': item['level'] ?? 0,
          'label': item['label']?.toString() ??
              item['title']?.toString() ??
              'Item ${index + 1}',
          'subtitle': item['subtitle']?.toString() ?? '',
          'meta': item['meta'],
          'value': item['value'],
          'selected': item['selected'] == true,
          'active': item['active'] == true,
          'disabled': item['disabled'] == true,
          'hasLeading': item['icon'] != null ||
              item['image'] != null ||
              item['leading'] != null,
          'hasSubtitle': (item['subtitle']?.toString() ?? '').isNotEmpty,
          'hasContent': children.isNotEmpty || item['content'] != null,
          'hasActions': item['actions'] != null || item['trailing'] != null,
          'childrenCount': children.length,
        },
        children: children.isEmpty
            ? null
            : [
                bp(node('template:rich_list', props: {
                  'items': children,
                  'depth': (item['level'] ?? 0) + 1
                }))
              ],
        path: '${ctx.node.debugPath}.rows[$index]',
      );
    }, growable: false);
  }

  QTemplateEngine.define('surface_shell', layout: [
    'hook header header',
    'body body body',
    'footer footer footer'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'header': {'type': 'box:row'},
    'body': {'type': 'box:col'},
    'footer': {'type': 'box:row'},
    'overlay': {'type': 'box:col'},
    'chrome': {'type': 'box:row'}
  }, guards: {
    'hook': 'showHook',
    'header': 'showHeader',
    'footer': 'showFooter',
    'overlay': 'showOverlay',
    'chrome': 'showChrome'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'header': 'row items-center justify-between w-full gap-8',
    'body': 'col w-full min-w-0 flex-1',
    'footer': 'row items-center justify-between w-full gap-8',
    'overlay': 'col w-full min-w-0',
    'chrome': 'row items-center justify-between w-full gap-8'
  }, variants: {
    'density': {
      'compact': {'header': 'gap-4', 'body': 'gap-4', 'footer': 'gap-4'},
      'comfortable': {'header': 'gap-12', 'body': 'gap-12', 'footer': 'gap-12'}
    },
    'surface': {
      'card': {'body': 'bg-white rounded-16 p-16 shadow-sm'},
      'panel': {'body': 'bg-slate-50 rounded-16 p-16'},
      'bare': {'body': 'bg-transparent p-0'}
    }
  });

  QTemplateEngine.define('rich_shell', extendsAlias: 'surface_shell', layout: [
    'hook',
    'header',
    'toolbar',
    'content',
    'footer'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'header': {'type': 'box:row'},
    'toolbar': {'type': 'box:row'},
    'content': {'type': 'box:col'},
    'footer': {'type': 'box:row'},
  }, guards: {
    'hook': 'showHook',
    'header': 'showHeader',
    'toolbar': 'showToolbar',
    'footer': 'showFooter'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'header': 'row items-center justify-between w-full gap-8',
    'toolbar': 'row items-center justify-between w-full gap-8',
    'content': 'col w-full min-w-0 flex-1',
    'footer': 'row items-center justify-between w-full gap-8'
  }, variants: {
    'density': {
      'compact': {
        'header': 'gap-4',
        'toolbar': 'gap-4',
        'content': 'gap-4',
        'footer': 'gap-4'
      },
      'comfortable': {
        'header': 'gap-12',
        'toolbar': 'gap-12',
        'content': 'gap-12',
        'footer': 'gap-12'
      }
    },
    'surface': {
      'card': {'content': 'bg-white rounded-16 p-16 shadow-sm'},
      'panel': {'content': 'bg-slate-50 rounded-16 p-16'},
      'bare': {'content': 'bg-transparent p-0'}
    }
  });

  QTemplateEngine.define('item_shell', extendsAlias: 'surface_shell', layout: [
    'hook leading title trailing',
    'hook subtitle subtitle trailing',
    'content content content',
    'actions actions actions',
    'meta meta meta'
  ], defaultSlots: {
    'leading': {'type': 'box:col'},
    'title': {'type': 'text:p', 'style': 'font-semibold text-slate-900'},
    'subtitle': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'content': {'type': 'box:col'},
    'actions': {'type': 'box:row'},
    'meta': {'type': 'box:row'},
    'trailing': {'type': 'box:row'},
    'badge': {'type': 'action:badge'}
  }, guards: {
    'leading': 'hasLeading',
    'subtitle': 'hasSubtitle',
    'content': 'hasContent',
    'actions': 'hasActions',
    'meta': 'hasMeta',
    'badge': 'showBadge'
  }, transforms: {
    'leading': 'shrink-0',
    'title': 'min-w-0',
    'subtitle': 'min-w-0',
    'content': 'col w-full min-w-0',
    'actions': 'row items-center gap-6 justify-end',
    'meta': 'row items-center gap-4 justify-end',
    'trailing': 'row items-center gap-6 justify-end',
    'badge': 'justify-end'
  }, variants: {
    'density': {
      'compact': {'content': 'gap-2', 'actions': 'gap-2', 'meta': 'gap-2'},
      'comfortable': {'content': 'gap-6', 'actions': 'gap-8', 'meta': 'gap-8'}
    }
  });

  QTemplateEngine.define('cluster_shell',
      extendsAlias: 'surface_shell',
      layout: [
        'hook items items',
        'hook footer footer'
      ],
      defaultSlots: {
        'items': {'type': 'box:row'},
        'footer': {'type': 'box:row'}
      },
      guards: {
        'items': 'hasItems',
        'footer': 'showFooter'
      },
      transforms: {
        'items': 'row flex-wrap items-center gap-8 w-full',
        'footer': 'row items-center justify-between w-full gap-8 mt-8'
      },
      variants: {
        'density': {
          'compact': {'items': 'gap-4', 'footer': 'mt-4'},
          'comfortable': {'items': 'gap-12', 'footer': 'mt-12'}
        },
        'wrap': {
          'nowrap': {'items': 'flex-nowrap overflow-x-auto'},
          'wrap': {'items': 'flex-wrap'}
        }
      });

  QTemplateEngine.define('split_shell', extendsAlias: 'surface_shell', layout: [
    'master detail'
  ], defaultSlots: {
    'master': {'type': 'box:col'},
    'detail': {'type': 'box:col'},
    'sidebar': {'type': 'box:col'},
    'inspector': {'type': 'box:col'}
  }, transforms: {
    'master': 'col w-full min-w-0',
    'detail': 'col w-full min-w-0',
    'sidebar': 'col w-full min-w-0',
    'inspector': 'col w-full min-w-0'
  }, variants: {
    'mode': {
      'sidebar': {
        'master': 'w-320 max-w-320 border-r-1 border-slate-200 pr-16',
        'detail': 'pl-16'
      },
      'stacked': {'master': 'mb-16', 'detail': 'pl-0'},
      'overlay': {'detail': 'absolute inset-0 z-10'}
    }
  });

  QTemplateEngine.define('state_shell', extendsAlias: 'surface_shell', layout: [
    'illustration',
    'title',
    'body',
    'actions',
    'retry'
  ], defaultSlots: {
    'illustration': {'type': 'box:col'},
    'title': {'type': 'text:h3'},
    'body': {'type': 'text:p', 'style': 'text-slate-500 text-center'},
    'actions': {'type': 'box:row'},
    'retry': {'type': 'action:button'},
    'content': {'type': 'box:col'}
  }, guards: {
    'illustration': 'showIllustration',
    'body': 'showBody',
    'actions': 'showActions',
    'retry': 'showRetry'
  }, transforms: {
    'illustration': 'mb-16 flex-center',
    'title': 'text-center',
    'body': 'mt-8 max-w-360',
    'actions': 'row gap-8 justify-center mt-16',
    'retry': 'mt-12 justify-center'
  }, variants: {
    'tone': {
      'error': {'title': 'text-red-700', 'body': 'text-red-600'},
      'success': {'title': 'text-emerald-700', 'body': 'text-emerald-600'},
      'warning': {'title': 'text-amber-700', 'body': 'text-amber-600'},
      'empty': {'title': 'text-slate-700', 'body': 'text-slate-500'}
    }
  });

  QTemplateEngine.define('overlay_shell',
      extendsAlias: 'surface_shell',
      layout: [
        'backdrop panel'
      ],
      defaultSlots: {
        'backdrop': {'type': 'box:col'},
        'panel': {'type': 'box:col'},
        'anchor': {'type': 'box:col'},
        'dismiss': {'type': 'action:button'}
      },
      guards: {
        'backdrop': 'showBackdrop',
        'anchor': 'showAnchor',
        'dismiss': 'showDismiss'
      },
      transforms: {
        'backdrop': 'absolute inset-0',
        'panel': 'relative z-10',
        'anchor': 'relative',
        'dismiss': 'absolute top-8 right-8 z-20'
      });

  QTemplateEngine.define('control_shell',
      extendsAlias: 'surface_shell',
      layout: [
        'label control suffix',
        'help help suffix',
        'error error error'
      ],
      defaultSlots: {
        'label': {'type': 'text:label'},
        'control': {'type': 'box:col'},
        'suffix': {'type': 'box:row'},
        'help': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
        'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'},
        'prefix': {'type': 'box:row'},
        'input': {'type': 'box:col'}
      },
      guards: {
        'label': 'showLabel',
        'help': 'showHelp',
        'suffix': 'showSuffix',
        'error': 'showError'
      },
      transforms: {
        'label': 'text-slate-700',
        'control': 'col w-full min-w-0',
        'suffix': 'row items-center gap-6 justify-end',
        'help': 'mt-4',
        'error': 'mt-4',
        'prefix': 'row items-center gap-6',
        'input': 'col w-full min-w-0'
      });

  QTemplateEngine.define('media_shell', extendsAlias: 'surface_shell', layout: [
    'media media',
    'caption meta',
    'overlay overlay'
  ], defaultSlots: {
    'media': {'type': 'media:image'},
    'caption': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'meta': {'type': 'box:row'},
    'overlay': {'type': 'box:col'},
    'badge': {'type': 'action:badge'}
  }, guards: {
    'caption': 'showCaption',
    'meta': 'showMeta',
    'overlay': 'showOverlay',
    'badge': 'showBadge'
  }, transforms: {
    'media': 'w-full min-w-0',
    'caption': 'mt-4',
    'meta': 'row items-center justify-between w-full mt-8',
    'overlay': 'absolute inset-0',
    'badge': 'absolute top-8 left-8 z-10'
  });

  QTemplateEngine.define('navigation_shell',
      extendsAlias: 'surface_shell',
      layout: [
        'hook leading items trailing',
        'content content content',
        'footer footer footer'
      ],
      defaultSlots: {
        'leading': {'type': 'box:row'},
        'items': {'type': 'box:row'},
        'trailing': {'type': 'box:row'},
        'content': {'type': 'box:col'},
        'footer': {'type': 'box:row'}
      },
      guards: {
        'leading': 'showLeading',
        'items': 'showItems',
        'trailing': 'showTrailing',
        'footer': 'showFooter'
      },
      transforms: {
        'leading': 'row items-center gap-8',
        'items': 'row items-center gap-4 min-w-0 flex-1',
        'trailing': 'row items-center gap-8 justify-end',
        'content': 'col w-full min-w-0',
        'footer': 'row items-center justify-between w-full gap-8 mt-8'
      },
      variants: {
        'density': {
          'compact': {'items': 'gap-2', 'footer': 'mt-4'},
          'comfortable': {'items': 'gap-8', 'footer': 'mt-12'}
        }
      });

  QTemplateEngine.define('menu_item', extendsAlias: 'item_shell', layout: [
    'hook trigger action',
    'hook subtitle action',
    'submenu submenu submenu'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'trigger': {
      'type': 'action:button',
      'props': {'fill': 'ghost', 'scale': 'sm'}
    },
    'action': {'type': 'box:row'},
    'subtitle': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'submenu': {'type': 'box:col'},
  }, guards: {
    'hook': 'showHook',
    'subtitle': 'hasSubtitle',
    'action': 'hasActions',
    'submenu': 'hasChildren'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'trigger': 'min-w-0',
    'action': 'justify-end',
    'subtitle': 'ml-12 -mt-2',
    'submenu': 'col gap-4 pl-16 mt-8'
  }, variants: {
    'density': {
      'compact': {'submenu': 'gap-2 pl-12 mt-4'},
      'comfortable': {'submenu': 'gap-6 pl-20 mt-10'}
    }
  }, nativeBuilder: (ctx) {
    final bool hasChildren = ctx.list('children').isNotEmpty;
    final QLBlueprint? triggerSlot = ctx.node.slots['trigger'];
    final QLBlueprint? actionSlot = ctx.node.slots['action'];
    final QLBlueprint? submenuSlot = ctx.node.slots['submenu'];
    final QLBlueprint? subtitleSlot = ctx.node.slots['subtitle'];
    final dynamic item = ctx.prop<dynamic>('item', fallback: const {});
    final Map<String, dynamic> itemMap = item is Map
        ? Map<String, dynamic>.from(item.cast<String, dynamic>())
        : <String, dynamic>{'label': ctx.string('label')};
    final List<dynamic> children = ctx.list('children',
        fallback: itemMap['children'] is List
            ? List<dynamic>.from(itemMap['children'] as List)
            : const <dynamic>[]);
    final List<QLBlueprint> submenuItems = hasChildren
        ? buildRecursiveMenuItems(
            ctx, children, (ctx.integer('level', fallback: 0)) + 1)
        : const <QLBlueprint>[];
    final Map<String, Widget> slots = <String, Widget>{};
    if (triggerSlot != null) {
      slots['trigger'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            triggerSlot,
            props: <String, dynamic>{
              'item': itemMap,
              'label': ctx.string('label',
                  fallback: itemMap['label']?.toString() ??
                      itemMap['title']?.toString() ??
                      ''),
              'subtitle': ctx.string('subtitle',
                  fallback: itemMap['subtitle']?.toString() ?? ''),
              'value': ctx.prop('value', fallback: itemMap['value']),
              'icon': ctx.prop('icon', fallback: itemMap['icon']),
              'selected': ctx.boolean('selected',
                  fallback: itemMap['selected'] == true),
              'hasLeading': itemMap['icon'] != null || itemMap['image'] != null,
              'hasSubtitle': (ctx.string('subtitle',
                      fallback: itemMap['subtitle']?.toString() ?? ''))
                  .isNotEmpty,
              'hasActions':
                  itemMap['actions'] != null || itemMap['trailing'] != null,
              'hasChildren': hasChildren,
            },
            path: '${ctx.node.debugPath}.trigger',
          ));
    }
    if (actionSlot != null) {
      slots['action'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(actionSlot,
              props: <String, dynamic>{
                'item': itemMap,
                'hasChildren': hasChildren
              },
              path: '${ctx.node.debugPath}.action'));
    }
    if (subtitleSlot != null) {
      slots['subtitle'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(subtitleSlot,
              props: <String, dynamic>{
                'item': itemMap,
                'label': ctx.string('subtitle')
              },
              path: '${ctx.node.debugPath}.subtitle'));
    }
    if (submenuSlot != null && submenuItems.isNotEmpty) {
      slots['submenu'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            submenuSlot,
            props: <String, dynamic>{
              'items': children,
              'level': ctx.integer('level', fallback: 0) + 1,
              'hasChildren': true,
            },
            children: submenuItems,
            path: '${ctx.node.debugPath}.submenu',
          ));
    }

    return ctx.buildLayout(nativeSlotOverrides: slots);
  });

  QTemplateEngine.define('nested_menu', extendsAlias: 'cluster_shell', layout: [
    'hook',
    'items'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'items': {'type': 'box:col'},
    'item': {'type': 'template:menu_item'},
    'empty': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
  }, guards: {
    'hook': 'showHook',
    'empty': 'showEmpty'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'items': 'col w-full gap-4',
    'empty': 'py-8 text-slate-500'
  }, variants: {
    'density': {
      'compact': {'items': 'gap-2'},
      'comfortable': {'items': 'gap-6'}
    },
    'surface': {
      'panel': {'items': 'bg-white rounded-16 p-8 border border-slate-200'},
      'bare': {'items': 'bg-transparent p-0'}
    }
  }, nativeBuilder: (ctx) {
    final List<dynamic> rawItems =
        ctx.list('items', fallback: ctx.list('entries'));
    if (rawItems.isEmpty) {
      return ctx.buildLayout(nativeSlotOverrides: {
        'empty': ctx.buildSlot('empty', nativeChildren: const [])
      });
    }

    final List<QLBlueprint> items = buildRecursiveMenuItems(
        ctx, rawItems, ctx.integer('level', fallback: 0));
    final QLBlueprint? itemsSlot = ctx.node.slots['items'];
    final Map<String, Widget> slotOverrides = <String, Widget>{};
    if (itemsSlot != null) {
      slotOverrides['items'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            itemsSlot,
            props: <String, dynamic>{
              'items': rawItems,
              'count': rawItems.length,
              'level': ctx.integer('level', fallback: 0),
            },
            children: items,
            path: '${ctx.node.debugPath}.items',
          ));
    }

    return ctx.buildLayout(nativeSlotOverrides: slotOverrides);
  });

  QTemplateEngine.define('list_item', extendsAlias: 'item_shell', layout: [
    'hook leading title trailing',
    'hook subtitle subtitle trailing',
    'content content content',
    'actions actions actions'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'leading': {'type': 'box:col'},
    'title': {'type': 'text:p', 'style': 'font-semibold text-slate-900'},
    'trailing': {'type': 'box:row'},
    'subtitle': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'content': {'type': 'box:col'},
    'actions': {'type': 'box:row'},
  }, guards: {
    'hook': 'showHook',
    'leading': 'hasLeading',
    'subtitle': 'hasSubtitle',
    'content': 'hasContent',
    'actions': 'hasActions'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'leading': 'shrink-0',
    'title': 'min-w-0',
    'trailing': 'justify-end',
    'subtitle': 'min-w-0',
    'content': 'col w-full min-w-0',
    'actions': 'row items-center gap-6 justify-end'
  }, variants: {
    'density': {
      'compact': {'content': 'gap-2', 'actions': 'gap-2'},
      'comfortable': {'content': 'gap-6', 'actions': 'gap-8'}
    }
  }, nativeBuilder: (ctx) {
    final dynamic item = ctx.prop<dynamic>('item', fallback: const {});
    final Map<String, dynamic> itemMap = item is Map
        ? Map<String, dynamic>.from(item.cast<String, dynamic>())
        : <String, dynamic>{'label': ctx.string('label')};
    final List<dynamic> children = ctx.list('children',
        fallback: itemMap['children'] is List
            ? List<dynamic>.from(itemMap['children'] as List)
            : const <dynamic>[]);
    final QLBlueprint? contentSlot = ctx.node.slots['content'];
    final QLBlueprint? actionsSlot = ctx.node.slots['actions'];
    final QLBlueprint? leadingSlot = ctx.node.slots['leading'];
    final QLBlueprint? trailingSlot = ctx.node.slots['trailing'];
    final QLBlueprint? subtitleSlot = ctx.node.slots['subtitle'];

    final Map<String, Widget> overrides = <String, Widget>{};
    if (leadingSlot != null) {
      overrides['leading'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(leadingSlot,
              props: <String, dynamic>{
                'item': itemMap,
                'index': ctx.integer('index')
              },
              path: '${ctx.node.debugPath}.leading'));
    }
    if (trailingSlot != null) {
      overrides['trailing'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(trailingSlot,
              props: <String, dynamic>{
                'item': itemMap,
                'index': ctx.integer('index')
              },
              path: '${ctx.node.debugPath}.trailing'));
    }
    if (subtitleSlot != null) {
      overrides['subtitle'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(subtitleSlot,
              props: <String, dynamic>{
                'item': itemMap,
                'index': ctx.integer('index')
              },
              path: '${ctx.node.debugPath}.subtitle'));
    }
    if (contentSlot != null) {
      overrides['content'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(contentSlot,
              props: <String, dynamic>{
                'item': itemMap,
                'index': ctx.integer('index')
              },
              children: children.isEmpty
                  ? null
                  : buildRowsFromRecords(ctx, children, 'item'),
              path: '${ctx.node.debugPath}.content'));
    }
    if (actionsSlot != null) {
      overrides['actions'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(actionsSlot,
              props: <String, dynamic>{
                'item': itemMap,
                'index': ctx.integer('index')
              },
              path: '${ctx.node.debugPath}.actions'));
    }

    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('rich_list',
      extendsAlias: 'collection_shell',
      layout: [
        'hook',
        'header',
        'items',
        'footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'header': {'type': 'box:row'},
        'items': {'type': 'box:col'},
        'item': {'type': 'template:list_item'},
        'empty': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
        'footer': {'type': 'box:row'},
      },
      guards: {
        'hook': 'showHook',
        'header': 'showHeader',
        'footer': 'showFooter',
        'empty': 'showEmpty'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'header': 'row items-center justify-between w-full gap-8',
        'items': 'col w-full gap-4',
        'footer': 'row items-center justify-between w-full gap-8'
      },
      variants: {
        'density': {
          'compact': {'items': 'gap-2'},
          'comfortable': {'items': 'gap-6'}
        },
        'surface': {
          'card': {'items': 'bg-white rounded-16 p-12 border border-slate-200'},
          'bare': {'items': 'bg-transparent p-0'}
        }
      }, nativeBuilder: (ctx) {
    final List<dynamic> items = ctx.list('items', fallback: ctx.list('rows'));
    if (items.isEmpty) {
      return ctx.buildLayout(nativeSlotOverrides: {
        'empty': ctx.buildSlot('empty', nativeChildren: const [])
      });
    }
    final List<QLBlueprint> rows = buildRowsFromRecords(ctx, items, 'item');
    final QLBlueprint? itemsSlot = ctx.node.slots['items'];
    final Map<String, Widget> overrides = <String, Widget>{};
    if (itemsSlot != null) {
      overrides['items'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            itemsSlot,
            props: <String, dynamic>{'items': items, 'count': items.length},
            children: rows,
            path: '${ctx.node.debugPath}.items',
          ));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('table_row', extendsAlias: 'item_shell', layout: [
    'hook cells cells trailing'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'cells': {'type': 'box:row'},
    'trailing': {'type': 'box:row'},
  }, guards: {
    'hook': 'showHook',
    'trailing': 'showTrailing'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'cells': 'row items-center gap-8 min-w-0 flex-1',
    'trailing': 'row items-center gap-6 justify-end'
  }, variants: {
    'density': {
      'compact': {'cells': 'gap-4'},
      'comfortable': {'cells': 'gap-8'}
    }
  }, nativeBuilder: (ctx) {
    final dynamic row = ctx.prop<dynamic>('item', fallback: const {});
    final Map<String, dynamic> rowMap = row is Map
        ? Map<String, dynamic>.from(row.cast<String, dynamic>())
        : <String, dynamic>{'label': ctx.string('label')};
    final List<dynamic> cells = rowMap['cells'] is List
        ? List<dynamic>.from(rowMap['cells'] as List)
        : ctx.list('cells', fallback: ctx.list('columns'));
    final QLBlueprint? cellsSlot = ctx.node.slots['cells'];
    final QLBlueprint? trailingSlot = ctx.node.slots['trailing'];
    final List<QLBlueprint> cellNodes =
        List<QLBlueprint>.generate(cells.length, (int index) {
      final dynamic raw = cells[index];
      final Map<String, dynamic> cell = raw is Map
          ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
          : <String, dynamic>{'value': raw?.toString() ?? ''};
      return bp(node('text:p',
          props: <String, dynamic>{
            'text': cell['value']?.toString() ?? cell['text']?.toString() ?? '',
            'cell': cell,
            'index': index,
            'row': rowMap,
          },
          style: cell['style']?.toString() ?? 'text-slate-700 text-sm'));
    }, growable: false);

    final Map<String, Widget> overrides = <String, Widget>{};
    if (cellsSlot != null) {
      overrides['cells'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            cellsSlot,
            props: <String, dynamic>{
              'item': rowMap,
              'index': ctx.integer('index')
            },
            children: cellNodes,
            path: '${ctx.node.debugPath}.cells',
          ));
    }
    if (trailingSlot != null) {
      overrides['trailing'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(trailingSlot,
              props: <String, dynamic>{
                'item': rowMap,
                'index': ctx.integer('index')
              },
              path: '${ctx.node.debugPath}.trailing'));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('rich_table',
      extendsAlias: 'collection_shell',
      layout: [
        'hook',
        'toolbar',
        'header',
        'rows',
        'footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'toolbar': {'type': 'box:row'},
        'header': {'type': 'box:row'},
        'rows': {'type': 'box:col'},
        'row': {'type': 'template:table_row'},
        'empty': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
        'footer': {'type': 'box:row'},
      },
      guards: {
        'hook': 'showHook',
        'toolbar': 'showToolbar',
        'header': 'showHeader',
        'footer': 'showFooter',
        'empty': 'showEmpty'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'toolbar': 'row items-center justify-between w-full gap-8 mb-8',
        'header': 'row items-center justify-between w-full gap-8 mb-8',
        'rows': 'col w-full gap-4',
        'footer': 'row items-center justify-between w-full gap-8 mt-8'
      },
      variants: {
        'density': {
          'compact': {'rows': 'gap-2'},
          'comfortable': {'rows': 'gap-6'}
        },
        'surface': {
          'card': {'rows': 'bg-white rounded-16 p-12 border border-slate-200'},
          'bare': {'rows': 'bg-transparent p-0'}
        }
      }, nativeBuilder: (ctx) {
    final List<dynamic> rows = ctx.list('rows', fallback: ctx.list('items'));
    if (rows.isEmpty) {
      return ctx.buildLayout(nativeSlotOverrides: {
        'empty': ctx.buildSlot('empty', nativeChildren: const [])
      });
    }
    final List<QLBlueprint> rowNodes = buildRowsFromRecords(ctx, rows, 'row');
    final QLBlueprint? rowsSlot = ctx.node.slots['rows'];
    final Map<String, Widget> overrides = <String, Widget>{};
    if (rowsSlot != null) {
      overrides['rows'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            rowsSlot,
            props: <String, dynamic>{'rows': rows, 'count': rows.length},
            children: rowNodes,
            path: '${ctx.node.debugPath}.rows',
          ));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('avatar_item', extendsAlias: 'item_shell', layout: [
    'hook avatar meta',
    'hook label label'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'avatar': {'type': 'media:avatar'},
    'meta': {'type': 'text:p', 'style': 'text-slate-500 text-xs'},
    'label': {'type': 'text:p', 'style': 'font-medium text-slate-900'},
  }, guards: {
    'hook': 'showHook',
    'meta': 'hasMeta'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'avatar': 'shrink-0',
    'meta': 'text-slate-500 text-xs',
    'label': 'min-w-0'
  }, nativeBuilder: (ctx) {
    final dynamic raw = ctx.prop<dynamic>('item', fallback: const {});
    final Map<String, dynamic> item = raw is Map
        ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
        : <String, dynamic>{'label': ctx.string('label')};
    final QLBlueprint? avatarSlot = ctx.node.slots['avatar'];
    final QLBlueprint? metaSlot = ctx.node.slots['meta'];
    final QLBlueprint? labelSlot = ctx.node.slots['label'];
    final Map<String, Widget> overrides = <String, Widget>{};
    if (avatarSlot != null) {
      overrides['avatar'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(avatarSlot,
              props: <String, dynamic>{
                'item': item,
                'label': ctx.string('label',
                    fallback: item['label']?.toString() ?? ''),
                'image': item['image'],
                'radius': item['radius'] ?? 999,
              },
              path: '${ctx.node.debugPath}.avatar'));
    }
    if (metaSlot != null) {
      overrides['meta'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(metaSlot,
              props: <String, dynamic>{
                'item': item,
                'index': ctx.integer('index'),
                'hasMeta': (item['meta']?.toString() ?? '').isNotEmpty,
              },
              path: '${ctx.node.debugPath}.meta'));
    }
    if (labelSlot != null) {
      overrides['label'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(labelSlot,
              props: <String, dynamic>{
                'item': item,
                'index': ctx.integer('index')
              },
              path: '${ctx.node.debugPath}.label'));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('avatar_group',
      extendsAlias: 'cluster_shell',
      layout: [
        'hook',
        'items',
        'footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'items': {'type': 'box:row'},
        'item': {'type': 'template:avatar_item'},
        'overflow': {'type': 'action:badge'},
        'footer': {'type': 'box:row'},
      },
      guards: {
        'hook': 'showHook',
        'footer': 'showFooter'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'items': 'row items-center -space-x-8',
        'footer': 'row items-center gap-8 mt-8'
      }, nativeBuilder: (ctx) {
    final List<dynamic> items =
        ctx.list('items', fallback: ctx.list('avatars'));
    final int maxVisible = ctx.integer('maxVisible', fallback: 6);
    final int visibleCount =
        items.length > maxVisible ? maxVisible : items.length;
    final List<QLBlueprint> avatarNodes =
        List<QLBlueprint>.generate(visibleCount, (int index) {
      final dynamic raw = items[index];
      final Map<String, dynamic> item = raw is Map
          ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
          : <String, dynamic>{
              'label': raw?.toString() ?? 'Avatar ${index + 1}'
            };
      return cloneNode(
        ctx.node.slots['item'] ?? bp(node('template:avatar_item')),
        props: <String, dynamic>{
          'item': item,
          'index': index,
          'hasMeta': (item['meta']?.toString() ?? '').isNotEmpty,
        },
        path: '${ctx.node.debugPath}.items[$index]',
      );
    });
    if (items.length > visibleCount && ctx.node.slots['overflow'] != null) {
      avatarNodes.add(cloneNode(
        ctx.node.slots['overflow']!,
        props: <String, dynamic>{'count': items.length - visibleCount},
        path: '${ctx.node.debugPath}.overflow',
      ));
    }
    final QLBlueprint? itemsSlot = ctx.node.slots['items'];
    final Map<String, Widget> overrides = <String, Widget>{};
    if (itemsSlot != null) {
      overrides['items'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            itemsSlot,
            props: <String, dynamic>{'items': items, 'count': items.length},
            children: avatarNodes,
            path: '${ctx.node.debugPath}.items',
          ));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('category_browser',
      extendsAlias: 'collection_shell',
      layout: [
        'hook',
        'filters',
        'items',
        'footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'filters': {'type': 'box:row'},
        'items': {'type': 'box:grid'},
        'item': {'type': 'action:chip'},
        'footer': {'type': 'box:row'},
        'empty': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
      },
      guards: {
        'hook': 'showHook',
        'filters': 'showFilters',
        'footer': 'showFooter',
        'empty': 'showEmpty'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'filters': 'row flex-wrap gap-8 w-full',
        'items': 'grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-8 w-full',
        'footer': 'row items-center justify-between w-full gap-8 mt-8'
      },
      variants: {
        'density': {
          'compact': {'items': 'gap-4'},
          'comfortable': {'items': 'gap-8'}
        }
      }, nativeBuilder: (ctx) {
    final List<dynamic> categories =
        ctx.list('items', fallback: ctx.list('categories'));
    if (categories.isEmpty) {
      return ctx.buildLayout(nativeSlotOverrides: {
        'empty': ctx.buildSlot('empty', nativeChildren: const [])
      });
    }
    final QLBlueprint? itemSlot = ctx.node.slots['item'];
    final List<QLBlueprint> chips =
        List<QLBlueprint>.generate(categories.length, (int index) {
      final dynamic raw = categories[index];
      final Map<String, dynamic> category = raw is Map
          ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
          : <String, dynamic>{
              'label': raw?.toString() ?? 'Category ${index + 1}'
            };
      return cloneNode(
        itemSlot ?? bp(node('action:chip')),
        props: <String, dynamic>{
          'item': category,
          'index': index,
          'label': category['label']?.toString() ??
              category['title']?.toString() ??
              'Category ${index + 1}',
          'count': category['count'],
          'selected': category['selected'] == true,
        },
        path: '${ctx.node.debugPath}.items[$index]',
      );
    }, growable: false);
    final QLBlueprint? itemsSlot = ctx.node.slots['items'];
    final Map<String, Widget> overrides = <String, Widget>{};
    if (itemsSlot != null) {
      overrides['items'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(itemsSlot,
              props: <String, dynamic>{
                // <--- Type fix applied here
                'items': categories,
                'count': categories.length
              },
              children: chips,
              path: '${ctx.node.debugPath}.items'));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('table_shell',
      extendsAlias: 'collection_shell',
      layout: [
        'hook hook hook',
        'toolbar toolbar toolbar',
        'filters filters filters',
        'header header header',
        'rows rows rows',
        'empty empty empty',
        'footer footer footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'toolbar': {'type': 'box:row'},
        'filters': {'type': 'box:row'},
        'header': {'type': 'box:row'},
        'rows': {'type': 'box:col'},
        'row': {'type': 'template:table_row'},
        'empty': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
        'footer': {'type': 'box:row'},
        'pagination': {'type': 'box:row'},
        'bulkActions': {'type': 'box:row'},
        'selection': {'type': 'box:row'}
      },
      guards: {
        'hook': 'showHook',
        'toolbar': 'showToolbar',
        'filters': 'showFilters',
        'header': 'showHeader',
        'footer': 'showFooter',
        'empty': 'showEmpty',
        'pagination': 'showPagination',
        'bulkActions': 'showBulkActions',
        'selection': 'showSelection'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'toolbar': 'row items-center justify-between w-full gap-8 mb-8',
        'filters': 'row flex-wrap items-center gap-8 w-full mb-8',
        'header': 'row items-center justify-between w-full gap-8 mb-8',
        'rows': 'col w-full gap-4',
        'empty': 'py-16 text-slate-500',
        'footer': 'row items-center justify-between w-full gap-8 mt-8',
        'pagination': 'row items-center gap-8 justify-end',
        'bulkActions': 'row items-center gap-8',
        'selection': 'row items-center gap-4'
      },
      variants: {
        'density': {
          'compact': {
            'rows': 'gap-2',
            'toolbar': 'mb-4',
            'header': 'mb-4',
            'footer': 'mt-4'
          },
          'comfortable': {
            'rows': 'gap-6',
            'toolbar': 'mb-12',
            'header': 'mb-12',
            'footer': 'mt-12'
          }
        },
        'surface': {
          'card': {'rows': 'bg-white rounded-16 p-12 border border-slate-200'},
          'bare': {'rows': 'bg-transparent p-0'}
        }
      }, nativeBuilder: (ctx) {
    final List<dynamic> rows = ctx.list('rows', fallback: ctx.list('items'));
    if (rows.isEmpty) {
      return ctx.buildLayout(nativeSlotOverrides: {
        'empty': ctx.buildSlot('empty', nativeChildren: const [])
      });
    }
    final List<QLBlueprint> rowNodes = buildRowsFromRecords(ctx, rows, 'row');
    final QLBlueprint? rowsSlot = ctx.node.slots['rows'];
    final Map<String, Widget> overrides = <String, Widget>{};
    if (rowsSlot != null) {
      overrides['rows'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            rowsSlot,
            props: <String, dynamic>{'rows': rows, 'count': rows.length},
            children: rowNodes,
            path: '${ctx.node.debugPath}.rows',
          ));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  QTemplateEngine.define('timeline_shell',
      extendsAlias: 'collection_shell',
      layout: [
        'hook header header',
        'rail items detail',
        'footer footer footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'header': {'type': 'box:row'},
        'rail': {'type': 'box:col'},
        'items': {'type': 'box:col'},
        'item': {'type': 'template:list_item'},
        'detail': {'type': 'box:col'},
        'footer': {'type': 'box:row'},
        'empty': {'type': 'text:p', 'style': 'text-slate-500 text-sm'}
      },
      guards: {
        'hook': 'showHook',
        'header': 'showHeader',
        'rail': 'showRail',
        'detail': 'showDetail',
        'footer': 'showFooter',
        'empty': 'showEmpty'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'header': 'row items-center justify-between w-full gap-8',
        'rail': 'col w-24 min-w-24',
        'items': 'col w-full gap-8',
        'detail': 'col w-full min-w-0 gap-8',
        'footer': 'row items-center justify-between w-full gap-8 mt-8'
      },
      variants: {
        'density': {
          'compact': {'items': 'gap-4', 'detail': 'gap-4'},
          'comfortable': {'items': 'gap-12', 'detail': 'gap-12'}
        },
        'surface': {
          'card': {'items': 'bg-white rounded-16 p-12 border border-slate-200'},
          'bare': {'items': 'bg-transparent p-0'}
        }
      }, nativeBuilder: (ctx) {
    final List<dynamic> items =
        ctx.list('items', fallback: ctx.list('entries'));
    if (items.isEmpty) {
      return ctx.buildLayout(nativeSlotOverrides: {
        'empty': ctx.buildSlot('empty', nativeChildren: const [])
      });
    }
    final List<QLBlueprint> rows = buildRowsFromRecords(ctx, items, 'item');
    final QLBlueprint? itemsSlot = ctx.node.slots['items'];
    final Map<String, Widget> overrides = <String, Widget>{};
    if (itemsSlot != null) {
      overrides['items'] = QuantumVM.instance.renderWidget(
          ctx.context,
          cloneNode(
            itemsSlot,
            props: <String, dynamic>{'items': items, 'count': items.length},
            children: rows,
            path: '${ctx.node.debugPath}.items',
          ));
    }
    return ctx.buildLayout(nativeSlotOverrides: overrides);
  });

  vm.defineAlias('menu', 'template:nested_menu');
  vm.defineAlias('menu_item', 'template:menu_item');
  vm.defineAlias('list', 'template:rich_list');
  vm.defineAlias('table', 'template:rich_table');
  vm.defineAlias('avatars', 'template:avatar_group');
  vm.defineAlias('avatar_group', 'template:avatar_group');
  vm.defineAlias('categories', 'template:category_browser');
  vm.defineAlias('category_browser', 'template:category_browser');
  vm.defineAlias('rich_shell', 'template:rich_shell');
  vm.defineAlias('rich_list', 'template:rich_list');
  vm.defineAlias('rich_table', 'template:rich_table');
}
// ---- template instance / registrations ----

Widget _buildTemplate(QLContext rawCtx) {
  final String subType = rawCtx.resolvedSubType();
  if (subType.isEmpty) return const SizedBox.shrink();

  final def = QTemplateEngine.getDef(subType);
  if (def == null) {
    return kDebugMode
        ? Text('Template [$subType] not registered',
            style: const TextStyle(color: Colors.red))
        : const SizedBox.shrink();
  }

  return _QTemplateInstanceNode(rawCtx: rawCtx, def: def);
}

class _QTemplateInstanceNode extends StatefulWidget {
  final QLContext rawCtx;
  final TemplateDef def;
  const _QTemplateInstanceNode({required this.rawCtx, required this.def});

  @override
  State<_QTemplateInstanceNode> createState() => _QTemplateInstanceNodeState();
}

class _QTemplateInstanceNodeState extends State<_QTemplateInstanceNode> {
  late final String _instanceId;

  @override
  void initState() {
    super.initState();
    _instanceId = 'tpl_${hashCode}';

    if (widget.def.initialState.isNotEmpty) {
      widget.def.initialState.forEach((key, value) {
        widget.rawCtx.store.set('${_instanceId}_$key', value);
      });
    }
  }

  @override
  void dispose() {
    widget.rawCtx.store.sweep('${_instanceId}_');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templateCtx =
        QTemplateContext(widget.rawCtx, widget.def, _instanceId);
    if (widget.def.nativeBuilder != null) {
      return widget.def.nativeBuilder!(templateCtx);
    }
    return templateCtx.buildLayout();
  }
}

class _QLTickerNode extends StatefulWidget {
  final void Function(double dt) onTick;
  final Widget child;
  const _QLTickerNode({required this.onTick, required this.child});
  @override
  State<_QLTickerNode> createState() => _QLTickerNodeState();
}

class _QLTickerNodeState extends State<_QLTickerNode>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final double dt = (elapsed - _last).inMilliseconds / 1000.0;
      _last = elapsed;
      widget.onTick(dt);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _QLFlowControllerNode extends StatefulWidget {
  final String namespace;
  final String stateKey;
  final bool disposeFlowState;
  final String routeKey;
  final String selectionKey;
  final String heroKey;
  final Widget child;

  const _QLFlowControllerNode({
    required this.namespace,
    required this.disposeFlowState,
    required this.stateKey,
    required this.routeKey,
    required this.selectionKey,
    required this.heroKey,
    required this.child,
  });

  @override
  State<_QLFlowControllerNode> createState() => _QLFlowControllerNodeState();
}

class _QLFlowControllerNodeState extends State<_QLFlowControllerNode> {
  late final QLDataStore _store;

  @override
  void initState() {
    super.initState();
    _store = QLStoreRegistry.instance.get(widget.namespace);
  }

  @override
  void dispose() {
    if (widget.disposeFlowState) {
      // Keep the namespace available by default; opt-in cleanup only.
      _store.sweep('${widget.namespace}.');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ════════════════════════════════════════════════════════════════════════════
// THE OMEGA HARDWARE HELPER CLASSES
// ════════════════════════════════════════════════════════════════════════════

// ── 1. DYNAMIC STICKY DELEGATE ──
class _QLStickyDelegate extends SliverPersistentHeaderDelegate {
  final double minH;
  final double maxH;
  final Widget child;
  _QLStickyDelegate(
      {required this.minH, required this.maxH, required this.child});

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => math.max(maxH, minH);
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;
  @override
  bool shouldRebuild(covariant _QLStickyDelegate old) =>
      minH != old.minH || maxH != old.maxH;
}

void _registerPowerFieldTemplates(QuantumVM vm) {
  QTemplateEngine.define('field_shell', extendsAlias: 'control_shell', layout: [
    'label',
    'control',
    'helper',
    'error',
    'actions'
  ], defaultSlots: {
    'label': {'type': 'text:label'},
    'control': {'type': 'box:col'},
    'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'},
    'actions': {'type': 'box:row'}
  }, guards: {
    'label': 'showLabel',
    'helper': 'showHelper',
    'error': 'showError',
    'actions': 'showActions'
  }, transforms: {
    'label': 'mb-4',
    'control': 'w-full min-w-0',
    'helper': 'mt-4',
    'error': 'mt-4',
    'actions': 'row gap-8 justify-end mt-8'
  });

  QTemplateEngine.define('popover_shell',
      extendsAlias: 'overlay_shell',
      layout: [
        'trigger',
        'panel'
      ],
      defaultSlots: {
        'trigger': {'type': 'action:button'},
        'panel': {'type': 'box:surface'}
      },
      guards: {
        'panel': 'open'
      },
      transforms: {
        'trigger': 'inline-flex',
        'panel': 'mt-8 w-full min-w-0 rounded-12 shadow-lg'
      });

  QTemplateEngine.define('field_text', extendsAlias: 'field_shell', layout: [
    'label',
    'control',
    'helper',
    'error'
  ], defaultSlots: {
    'label': {'type': 'text:label'},
    'control': {
      'type': 'field:text',
      'props': {'style': 'w-full'}
    },
    'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'}
  }, transforms: {
    'label': 'mb-4',
    'control': 'w-full min-w-0',
    'helper': 'mt-4',
    'error': 'mt-4'
  });

  QTemplateEngine.define('field_number', extendsAlias: 'field_shell', layout: [
    'label',
    'control',
    'helper',
    'error'
  ], defaultSlots: {
    'label': {'type': 'text:label'},
    'control': {
      'type': 'field:number',
      'props': {'style': 'w-full'}
    },
    'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'}
  }, transforms: {
    'label': 'mb-4',
    'control': 'w-full min-w-0',
    'helper': 'mt-4',
    'error': 'mt-4'
  });

  QTemplateEngine.define('field_toggle', extendsAlias: 'field_shell', layout: [
    'control',
    'caption',
    'helper',
    'error'
  ], defaultSlots: {
    'control': {'type': 'field:toggle'},
    'caption': {'type': 'text:p'},
    'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'}
  }, transforms: {
    'control': 'inline-flex',
    'caption': 'mt-4',
    'helper': 'mt-4',
    'error': 'mt-4'
  });

  QTemplateEngine.define('field_slider', extendsAlias: 'field_shell', layout: [
    'label',
    'slider',
    'value',
    'helper',
    'error',
    'actions'
  ], defaultSlots: {
    'label': {'type': 'text:label'},
    'slider': {'type': 'field:slider'},
    'value': {'type': 'text:p', 'style': 'text-right text-slate-500 text-sm'},
    'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'},
    'actions': {'type': 'box:row'}
  }, transforms: {
    'label': 'mb-4',
    'slider': 'w-full min-w-0',
    'value': 'mt-4',
    'helper': 'mt-4',
    'error': 'mt-4',
    'actions': 'row gap-8 justify-end mt-8'
  });

  QTemplateEngine.define('field_select', extendsAlias: 'field_shell', layout: [
    'label',
    'trigger',
    'panel',
    'helper',
    'error'
  ], defaultSlots: {
    'label': {'type': 'text:label'},
    'trigger': {'type': 'action:button'},
    'panel': {'type': 'box:surface'},
    'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'}
  }, guards: {
    'panel': 'open'
  }, transforms: {
    'label': 'mb-4',
    'trigger': 'w-full justify-between',
    'panel': 'mt-8 w-full rounded-12 shadow-lg overflow-hidden',
    'helper': 'mt-4',
    'error': 'mt-4'
  });

  QTemplateEngine.define('field_array', extendsAlias: 'field_shell', layout: [
    'header',
    'items',
    'empty',
    'footer'
  ], defaultSlots: {
    'header': {'type': 'box:row'},
    'items': {'type': 'box:col'},
    'empty': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'footer': {'type': 'box:row'}
  }, guards: {
    'empty': 'showEmpty'
  }, transforms: {
    'header': 'row items-center justify-between gap-8 mb-8',
    'items': 'col w-full gap-8',
    'empty': 'py-12',
    'footer': 'row items-center justify-between gap-8 mt-12'
  });

  QTemplateEngine.define('field_blocks', extendsAlias: 'field_shell', layout: [
    'header',
    'blocks',
    'footer'
  ], defaultSlots: {
    'header': {'type': 'box:row'},
    'blocks': {'type': 'box:col'},
    'footer': {'type': 'box:row'}
  }, transforms: {
    'header': 'row items-center justify-between gap-8 mb-8',
    'blocks': 'col w-full gap-12',
    'footer': 'row items-center justify-between gap-8 mt-12'
  });

  QTemplateEngine.define('field_data', extendsAlias: 'field_shell', layout: [
    'header',
    'body',
    'footer'
  ], defaultSlots: {
    'header': {'type': 'box:row'},
    'body': {'type': 'box:col'},
    'footer': {'type': 'box:row'}
  }, transforms: {
    'header': 'row items-center justify-between gap-8 mb-8',
    'body': 'col w-full gap-8',
    'footer': 'row items-center justify-between gap-8 mt-12'
  });

  QTemplateEngine.define('field_lookup', extendsAlias: 'field_shell', layout: [
    'label',
    'control',
    'results',
    'helper',
    'error'
  ], defaultSlots: {
    'label': {'type': 'text:label'},
    'control': {'type': 'field:text'},
    'results': {'type': 'box:col'},
    'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'}
  }, transforms: {
    'label': 'mb-4',
    'control': 'w-full min-w-0',
    'results': 'mt-8 col w-full gap-8',
    'helper': 'mt-4',
    'error': 'mt-4'
  });

  QTemplateEngine.define('field_relation',
      extendsAlias: 'field_shell',
      layout: [
        'label',
        'control',
        'summary',
        'helper',
        'error'
      ],
      defaultSlots: {
        'label': {'type': 'text:label'},
        'control': {'type': 'field:lookup'},
        'summary': {'type': 'box:col'},
        'helper': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
        'error': {'type': 'text:p', 'style': 'text-red-600 text-sm'}
      },
      transforms: {
        'label': 'mb-4',
        'control': 'w-full min-w-0',
        'summary': 'mt-8 col w-full gap-8',
        'helper': 'mt-4',
        'error': 'mt-4'
      });

  QTemplateEngine.define('field_shell_stacked',
      extendsAlias: 'field_shell',
      layout: [
        'header',
        'body',
        'footer'
      ],
      defaultSlots: {
        'header': {'type': 'box:row'},
        'body': {'type': 'box:col'},
        'footer': {'type': 'box:row'}
      },
      transforms: {
        'header': 'row items-center justify-between gap-8 mb-8',
        'body': 'col w-full gap-8',
        'footer': 'row items-center justify-between gap-8 mt-12'
      });

  QTemplateEngine.define('card_shell', extendsAlias: 'item_shell', layout: [
    'hook badge actions',
    'eyebrow title title',
    'media media media',
    'content content aside',
    'chart chart chart',
    'visual visual visual',
    'meta meta meta',
    'footer footer footer'
  ], defaultSlots: {
    'hook': {'type': 'hook:lifecycle'},
    'badge': {'type': 'action:badge'},
    'eyebrow': {'type': 'text:label'},
    'media': {'type': 'media:image'},
    'title': {'type': 'text:h3'},
    'subtitle': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'content': {'type': 'box:col'},
    'aside': {'type': 'box:col'},
    'chart': {'type': 'chart'},
    'visual': {'type': 'box:col'},
    'actions': {'type': 'box:row'},
    'meta': {'type': 'box:row'},
    'footer': {'type': 'box:row'},
    'primaryAction': {'type': 'action:button'},
    'secondaryAction': {'type': 'action:button'},
    'chrome': {'type': 'box:row'},
    'overlay': {'type': 'box:col'},
  }, guards: {
    'hook': 'showHook',
    'badge': 'showBadge',
    'eyebrow': 'showEyebrow',
    'media': 'showMedia',
    'subtitle': 'showSubtitle',
    'content': 'showContent',
    'aside': 'showAside',
    'chart': 'showChart',
    'visual': 'showVisual',
    'actions': 'showActions',
    'meta': 'showMeta',
    'footer': 'showFooter',
    'primaryAction': 'showPrimaryAction',
    'secondaryAction': 'showSecondaryAction',
    'chrome': 'showChrome',
    'overlay': 'showOverlay'
  }, transforms: {
    'hook': 'sr-only pointer-events-none absolute opacity-0',
    'badge': 'justify-end',
    'eyebrow': 'text-slate-500 uppercase tracking-wide text-xs',
    'media': 'w-full min-w-0 rounded-16 overflow-hidden',
    'title': 'min-w-0',
    'subtitle': 'min-w-0',
    'content': 'col w-full min-w-0 gap-8',
    'aside': 'col w-full min-w-0 gap-8',
    'chart': 'w-full min-w-0',
    'visual': 'w-full min-w-0',
    'actions': 'row items-center gap-8 justify-end',
    'meta': 'row items-center gap-6 justify-between',
    'footer': 'row items-center justify-between gap-8 mt-8',
    'primaryAction': 'justify-end',
    'secondaryAction': 'justify-end',
    'chrome': 'row items-center justify-between gap-8 w-full',
    'overlay': 'absolute inset-0'
  }, variants: {
    'density': {
      'compact': {
        'content': 'gap-4',
        'aside': 'gap-4',
        'actions': 'gap-4',
        'meta': 'gap-4',
        'footer': 'mt-4'
      },
      'comfortable': {
        'content': 'gap-12',
        'aside': 'gap-12',
        'actions': 'gap-12',
        'meta': 'gap-8',
        'footer': 'mt-12'
      }
    },
    'orientation': {
      'vertical': {
        'media': 'w-full',
        'content': 'col w-full min-w-0 gap-8',
        'aside': 'col w-full min-w-0 gap-8'
      },
      'horizontal': {
        'media': 'w-160 shrink-0 self-stretch',
        'content': 'row w-full min-w-0 gap-12 items-start',
        'aside': 'w-240 shrink-0'
      }
    },
    'surface': {
      'card': {
        'content': 'bg-white rounded-16 p-16 shadow-sm border border-slate-200'
      },
      'panel': {
        'content': 'bg-slate-50 rounded-16 p-16 border border-slate-200'
      },
      'bare': {'content': 'bg-transparent p-0 shadow-none border-0'}
    }
  });

  QTemplateEngine.define('workspace_shell',
      extendsAlias: 'surface_shell',
      layout: [
        'chrome chrome chrome',
        'header header header',
        'sidebar main inspector',
        'panel panel panel',
        'footer footer footer'
      ],
      defaultSlots: {
        'chrome': {'type': 'box:row'},
        'header': {'type': 'box:row'},
        'toolbar': {'type': 'box:row'},
        'breadcrumbs': {'type': 'box:row'},
        'sidebar': {'type': 'box:col'},
        'main': {'type': 'box:col'},
        'inspector': {'type': 'box:col'},
        'panel': {'type': 'box:col'},
        'footer': {'type': 'box:row'},
        'status': {'type': 'box:row'},
        'overlay': {'type': 'box:col'},
        'drawer': {'type': 'box:col'},
        'canvas': {'type': 'box:col'},
        'notes': {'type': 'box:col'}
      },
      guards: {
        'chrome': 'showChrome',
        'header': 'showHeader',
        'toolbar': 'showToolbar',
        'breadcrumbs': 'showBreadcrumbs',
        'sidebar': 'showSidebar',
        'inspector': 'showInspector',
        'panel': 'showPanel',
        'footer': 'showFooter',
        'status': 'showStatus',
        'overlay': 'showOverlay',
        'drawer': 'showDrawer',
        'canvas': 'showCanvas',
        'notes': 'showNotes'
      },
      transforms: {
        'chrome': 'row items-center justify-between w-full gap-12',
        'header': 'row items-center justify-between w-full gap-8',
        'toolbar': 'row items-center justify-between w-full gap-8',
        'breadcrumbs': 'row items-center gap-6 w-full',
        'sidebar': 'col w-full min-w-0 gap-8',
        'main': 'col w-full min-w-0 gap-12',
        'inspector': 'col w-full min-w-0 gap-8',
        'panel': 'col w-full min-w-0 gap-8',
        'footer': 'row items-center justify-between w-full gap-8',
        'status': 'row items-center justify-between w-full gap-6',
        'overlay': 'absolute inset-0 z-20',
        'drawer': 'col w-full min-w-0',
        'canvas': 'col w-full min-w-0',
        'notes': 'col w-full min-w-0 gap-8'
      },
      variants: {
        'density': {
          'compact': {
            'chrome': 'gap-6',
            'header': 'gap-4',
            'toolbar': 'gap-4',
            'main': 'gap-8',
            'footer': 'gap-4'
          },
          'comfortable': {
            'chrome': 'gap-16',
            'header': 'gap-12',
            'toolbar': 'gap-12',
            'main': 'gap-16',
            'footer': 'gap-12'
          }
        },
        'mode': {
          'app': {
            'sidebar': 'w-320 max-w-360 border-r-1 border-slate-200 pr-16',
            'inspector': 'w-360 max-w-420 border-l-1 border-slate-200 pl-16',
            'panel': 'rounded-16 border border-slate-200 p-16'
          },
          'dashboard': {
            'sidebar': 'w-280 max-w-320 border-r-1 border-slate-200 pr-16',
            'main': 'gap-16',
            'panel': 'rounded-16 border border-slate-200 p-16'
          },
          'code': {
            'sidebar': 'w-280 max-w-360 border-r-1 border-slate-200 pr-16',
            'inspector': 'w-400 max-w-480 border-l-1 border-slate-200 pl-16',
            'panel': 'border-t-1 border-slate-200 pt-12'
          },
          'studio': {
            'main': 'gap-16',
            'canvas': 'rounded-16 border border-slate-200 overflow-hidden',
            'inspector': 'w-400 max-w-480 border-l-1 border-slate-200 pl-16'
          },
          'immersive': {
            'chrome': 'hidden',
            'header': 'hidden',
            'footer': 'hidden',
            'sidebar': 'w-280 max-w-320',
            'inspector': 'w-320 max-w-400'
          }
        }
      });

  QTemplateEngine.define('inspector_shell',
      extendsAlias: 'workspace_shell',
      layout: [
        'header header inspector',
        'toolbar toolbar inspector',
        'main detail inspector',
        'footer footer inspector'
      ],
      defaultSlots: {
        'header': {'type': 'box:row'},
        'toolbar': {'type': 'box:row'},
        'main': {'type': 'box:col'},
        'detail': {'type': 'box:col'},
        'inspector': {'type': 'box:col'},
        'footer': {'type': 'box:row'},
        'overlay': {'type': 'box:col'}
      },
      guards: {
        'toolbar': 'showToolbar',
        'detail': 'showDetail',
        'inspector': 'showInspector',
        'footer': 'showFooter',
        'overlay': 'showOverlay'
      },
      transforms: {
        'header': 'row items-center justify-between w-full gap-8',
        'toolbar': 'row items-center justify-between w-full gap-8',
        'main': 'col w-full min-w-0 gap-12',
        'detail': 'col w-full min-w-0 gap-8',
        'inspector': 'col w-full min-w-0 gap-8',
        'footer': 'row items-center justify-between w-full gap-8'
      },
      variants: {
        'mode': {
          'dock': {
            'inspector': 'w-360 max-w-480 border-l-1 border-slate-200 pl-16'
          },
          'split': {
            'detail': 'col w-full min-w-0 gap-12',
            'inspector': 'w-360 max-w-420 border-l-1 border-slate-200 pl-16'
          },
          'overlay': {
            'inspector':
                'absolute right-0 top-0 h-full w-420 max-w-[90vw] z-20 bg-white shadow-xl border-l-1 border-slate-200 pl-16'
          }
        }
      });

  QTemplateEngine.define('composer_shell',
      extendsAlias: 'control_shell',
      layout: [
        'hook header actions',
        'toolbar toolbar toolbar',
        'draft draft draft',
        'attachments attachments attachments',
        'preview preview preview',
        'footer footer footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'header': {'type': 'box:row'},
        'toolbar': {'type': 'box:row'},
        'draft': {'type': 'field:text'},
        'attachments': {'type': 'box:row'},
        'preview': {'type': 'box:col'},
        'actions': {'type': 'box:row'},
        'status': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
        'counter': {'type': 'text:p', 'style': 'text-slate-500 text-xs'},
        'footer': {'type': 'box:row'},
        'submit': {'type': 'action:button'},
        'cancel': {'type': 'action:button'}
      },
      guards: {
        'hook': 'showHook',
        'header': 'showHeader',
        'toolbar': 'showToolbar',
        'attachments': 'showAttachments',
        'preview': 'showPreview',
        'actions': 'showActions',
        'status': 'showStatus',
        'counter': 'showCounter',
        'footer': 'showFooter',
        'submit': 'showSubmit',
        'cancel': 'showCancel'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'header': 'row items-center justify-between w-full gap-8',
        'toolbar': 'row items-center justify-between w-full gap-8',
        'draft': 'w-full min-w-0',
        'attachments': 'row flex-wrap gap-8 w-full',
        'preview': 'col w-full min-w-0 gap-8',
        'actions': 'row items-center gap-8 justify-end',
        'status': 'text-slate-500 text-sm',
        'counter': 'text-slate-500 text-xs',
        'footer': 'row items-center justify-between w-full gap-8 mt-8',
        'submit': 'justify-end',
        'cancel': 'justify-end'
      },
      variants: {
        'mode': {
          'chat': {'draft': 'min-h-96', 'preview': 'gap-4'},
          'document': {'draft': 'min-h-160', 'preview': 'gap-12'},
          'studio': {'toolbar': 'gap-12', 'preview': 'gap-16'}
        }
      });

  QTemplateEngine.define('stage_shell', extendsAlias: 'surface_shell', layout: [
    'hud hud hud',
    'viewport viewport viewport',
    'tools tools inspector',
    'tray tray tray',
    'footer footer footer'
  ], defaultSlots: {
    'hud': {'type': 'box:row'},
    'viewport': {'type': 'box:col'},
    'tools': {'type': 'box:row'},
    'gizmos': {'type': 'box:row'},
    'inspector': {'type': 'box:col'},
    'tray': {'type': 'box:row'},
    'footer': {'type': 'box:row'},
    'overlay': {'type': 'box:col'},
    'backdrop': {'type': 'box:col'},
    'status': {'type': 'box:row'},
    'controls': {'type': 'box:row'},
    'dpad': {'type': 'box:row'}
  }, guards: {
    'hud': 'showHud',
    'tools': 'showTools',
    'gizmos': 'showGizmos',
    'inspector': 'showInspector',
    'tray': 'showTray',
    'footer': 'showFooter',
    'overlay': 'showOverlay',
    'backdrop': 'showBackdrop',
    'status': 'showStatus',
    'controls': 'showControls',
    'dpad': 'showDpad'
  }, transforms: {
    'hud': 'row items-center justify-between w-full gap-8',
    'viewport': 'col w-full min-w-0',
    'tools': 'row items-center gap-8 w-full flex-wrap',
    'gizmos': 'row items-center gap-6 flex-wrap',
    'inspector': 'col w-full min-w-0 gap-8',
    'tray': 'row items-center justify-between w-full gap-8',
    'footer': 'row items-center justify-between w-full gap-8',
    'overlay': 'absolute inset-0 z-20',
    'backdrop': 'absolute inset-0',
    'status': 'row items-center justify-between w-full gap-6',
    'controls': 'row items-center gap-8 justify-center',
    'dpad': 'row items-center gap-4 justify-center'
  }, variants: {
    'mode': {
      'game': {
        'viewport': 'rounded-16 overflow-hidden bg-black',
        'tools': 'absolute top-8 left-8 z-20',
        'inspector': 'w-360 max-w-420 border-l-1 border-slate-200 pl-16'
      },
      '3d': {
        'viewport': 'rounded-16 overflow-hidden',
        'tools': 'row gap-12',
        'inspector': 'w-400 max-w-480 border-l-1 border-slate-200 pl-16'
      },
      'editor': {
        'viewport': 'rounded-16 border border-slate-200 overflow-hidden',
        'tools': 'row gap-8 flex-wrap',
        'tray': 'row gap-8 flex-wrap'
      }
    }
  });

  QTemplateEngine.define('wizard_shell',
      extendsAlias: 'navigation_shell',
      layout: [
        'hook progress actions',
        'steps steps steps',
        'stage stage stage',
        'aside aside aside',
        'footer footer footer'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
        'progress': {'type': 'box:row'},
        'actions': {'type': 'box:row'},
        'steps': {'type': 'box:row'},
        'stage': {'type': 'box:col'},
        'aside': {'type': 'box:col'},
        'footer': {'type': 'box:row'},
        'summary': {'type': 'box:col'},
        'controls': {'type': 'box:row'}
      },
      guards: {
        'hook': 'showHook',
        'progress': 'showProgress',
        'actions': 'showActions',
        'stage': 'showStage',
        'aside': 'showAside',
        'footer': 'showFooter',
        'summary': 'showSummary',
        'controls': 'showControls'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'progress': 'row items-center justify-between w-full gap-8',
        'actions': 'row items-center justify-end w-full gap-8',
        'steps': 'row items-center gap-8 w-full flex-wrap',
        'stage': 'col w-full min-w-0 gap-12',
        'aside': 'col w-full min-w-0 gap-8',
        'footer': 'row items-center justify-between w-full gap-8 mt-12',
        'summary': 'col w-full min-w-0 gap-8',
        'controls': 'row items-center gap-8 justify-end'
      },
      variants: {
        'mode': {
          'linear': {'steps': 'justify-between', 'stage': 'gap-12'},
          'branching': {
            'steps': 'flex-wrap gap-12',
            'aside': 'w-320 max-w-420'
          },
          'fullscreen': {'stage': 'gap-16', 'aside': 'w-420 max-w-480'}
        }
      });
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  BUILT-IN TEMPLATE REGISTRY
// ────────────────────────────────────────────────────────────────────────────
void _registerBuiltInTemplates(QuantumVM vm) {
  // ── 2. The Profile Card Template (Variants + Hero + No Native Builder) ──
  QTemplateEngine.define('profile_card', extendsAlias: 'item_shell', layout: [
    'avatar  name',
    'avatar  role',
    'stats   stats'
  ], defaultSlots: {
    'avatar': {
      'type': 'media:image',
      'props': {'radius': 999}
    },
    'name': {'type': 'text:h2'},
    'role': {'type': 'text:p', 'style': 'text-slate-500'},
  }, hero: {
    // Dynamic interpolation! If the user provides a `userId` prop, it wraps the avatar in a Hero.
    'avatar': 'profile_avatar_{{userId}}',
  }, guards: {
    // Only show the stats row if the prop `showStats` is true.
    'stats': 'showStats',
  }, variants: {
    // When the user specifies `{"size": "small"}`, it overrides the specific slot ASTs!
    'size': {
      'small': {
        'avatar': {'style': 'w-48 h-48'},
        'name': {'type': 'text:h3'},
      },
      'large': {
        'avatar': {'style': 'w-96 h-96 shadow-lg'},
        'name': {'type': 'text:h1'},
      }
    }
  });

  vm.defineAlias('tabs', 'template:tabs',
      defaultProps: {'style': 'flex-1', 'gridRows': 'auto 1fr'});
  vm.defineAlias('data_shell', 'template:collection_shell',
      defaultProps: {'style': 'flex-1'});
  vm.defineAlias('wizard', 'template:stepper');
  vm.defineAlias('empty_state', 'template:state_surface',
      defaultProps: {'tone': 'empty'});
  vm.defineAlias('error_state', 'template:state_surface',
      defaultProps: {'tone': 'error'});
  vm.defineAlias('profile_card', 'template:profile_card');
  vm.defineAlias('flow_shell', 'template:flow_shell');
  vm.defineAlias('hero_bridge', 'template:hero_bridge');
}

void _registerGeneralBuiltInTemplates(QuantumVM vm) {
  QLBlueprint bp(Map<String, dynamic> json) => QLBlueprint.fromJson(json);

  Map<String, dynamic> node(
    String type, {
    Map<String, dynamic> props = const {},
    String? style,
    List<Map<String, dynamic>> children = const [],
  }) =>
      {
        'type': type,
        if (props.isNotEmpty) 'props': props,
        if (style != null) 'style': style,
        if (children.isNotEmpty) 'children': children,
      };

  Map<String, dynamic> txt(String value,
          {String type = 'text:p', String? style}) =>
      node(type, props: {'text': value}, style: style);

  Map<String, dynamic> setState(String key, dynamic value) =>
      {'action': 'state.set', 'key': key, 'value': value};

  int clampIndex(dynamic raw, int length) {
    if (length <= 0) return 0;
    final int value = (raw as num?)?.toInt() ?? 0;
    if (value < 0) return 0;
    if (value >= length) return length - 1;
    return value;
  }

  String stateKey(QTemplateContext ctx, String localName) {
    final bind = ctx.string('bind');
    return bind.isNotEmpty ? bind : ctx.stateKey(localName);
  }

  List<QLBlueprint> navItems(
    QTemplateContext ctx,
    List<dynamic> items,
    String activeKey, {
    bool useValue = false,
    String prefix = 'Item',
  }) {
    final activeValue = ctx.store.get(activeKey);
    return List.generate(items.length, (i) {
      final item = items[i] as Map? ?? const {};
      final value = useValue ? (item['value'] ?? i) : i;
      final active = useValue
          ? activeValue?.toString() == value.toString()
          : activeValue == i;
      return bp(node('action:button',
          props: {
            'text': item['label']?.toString() ?? '$prefix ${i + 1}',
            'value': value.toString(),
            'fill': active
                ? ctx.string('activeFill', fallback: 'surface')
                : 'ghost',
            'depth': active ? 'raised' : 'flat',
            'intent': item['intent']?.toString() ??
                ctx.string('intent', fallback: 'slate-900'),
            'scale': ctx.string('itemScale', fallback: 'sm'),
            'onClick': [setState(activeKey, value), ...ctx.list('onSelect')]
          },
          style: ctx.string('itemStyle', fallback: 'flex-1')));
    });
  }

  QTemplateEngine.define('tabs',
      extendsAlias: 'navigation_shell',
      initialState: {
        'activeIndex': 0
      },
      layout: [
        'hook',
        'tab_bar',
        'content'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
      },
      guards: {
        'hook': 'showHook'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'tab_bar': 'row bg-slate-100 p-4 rounded-8 w-full gap-4',
        'content': {
          'type': 'box:col',
          'style': 'mt-16 w-full flex-1',
          'props': {'clip': true}
        }
      },
      variants: {
        'variant': {
          'underline': {
            'tab_bar':
                'bg-transparent p-0 rounded-0 border-b-1 border-slate-200',
            'content': 'mt-0 pt-16'
          },
          'pills': {'tab_bar': 'rounded-full'}
        },
        'density': {
          'compact': {'tab_bar': 'gap-2 p-2', 'content': 'mt-8'},
          'comfortable': {'tab_bar': 'gap-8 p-8', 'content': 'mt-24'}
        }
      }, nativeBuilder: (ctx) {
    final items = ctx.list('items');
    final key = stateKey(ctx, 'activeIndex');
    if (ctx.store.get(key) == null) ctx.store.set(key, 0);
    final sig = ctx.store.signal(key);
    return AnimatedBuilder(
        animation: sig,
        builder: (_, __) {
          final i = clampIndex(sig.value, items.length);
          final item = items.isEmpty ? const {} : items[i] as Map? ?? const {};
          return ctx.buildLayout(nativeSlotOverrides: {
            'tab_bar': ctx.buildSlot('tab_bar',
                nativeChildren: navItems(ctx, items, key, prefix: 'Tab')),
            'content': ctx.buildSlot('content', nativeChildren: [
              if (item['content'] is Map)
                bp(Map<String, dynamic>.from(item['content'] as Map))
            ])
          });
        });
  });

  QTemplateEngine.define('segmented_control',
      extendsAlias: 'navigation_shell',
      initialState: {'value': 0},
      layout: ['items'],
      transforms: {'items': 'row w-full gap-4 p-4 rounded-full bg-slate-100'},
      nativeBuilder: (ctx) {
    final items = ctx.list('items');
    final key = stateKey(ctx, 'value');
    if (ctx.store.get(key) == null) {
      final first = items.isNotEmpty && items.first is Map
          ? (items.first as Map)['value']
          : 0;
      ctx.store.set(key, first ?? 0);
    }
    final sig = ctx.store.signal(key);
    return AnimatedBuilder(
        animation: sig,
        builder: (_, __) => ctx.buildLayout(nativeSlotOverrides: {
              'items': ctx.buildSlot('items',
                  nativeChildren: navItems(ctx, items, key,
                      useValue: true, prefix: 'Option'))
            }));
  });

  QTemplateEngine.define('accordion',
      extendsAlias: 'navigation_shell',
      initialState: {
        'openIndex': 0
      },
      layout: [
        'hook',
        'items'
      ],
      defaultSlots: {
        'hook': {'type': 'hook:lifecycle'},
      },
      guards: {
        'hook': 'showHook'
      },
      transforms: {
        'hook': 'sr-only pointer-events-none absolute opacity-0',
        'items': 'col w-full gap-8'
      },
      variants: {
        'density': {
          'compact': {'items': 'gap-4'},
          'comfortable': {'items': 'gap-12'}
        }
      }, nativeBuilder: (ctx) {
    final items = ctx.list('items');
    final key = stateKey(ctx, 'openIndex');
    if (ctx.store.get(key) == null) {
      ctx.store.set(key, ctx.integer('initialIndex'));
    }
    final sig = ctx.store.signal(key);
    final multiple = ctx.boolean('multiple');
    return AnimatedBuilder(
        animation: sig,
        builder: (_, __) {
          final active = clampIndex(sig.value, items.length);
          final children = List.generate(items.length, (i) {
            final item = items[i] as Map? ?? const {};
            final open =
                multiple ? ctx.store.get('$key.$i') == true : i == active;
            return bp(node('box:col',
                style:
                    'w-full bg-white border-1 border-slate-200 rounded-8 overflow-hidden',
                children: [
                  node('action:button',
                      props: {
                        'text': item['label']?.toString() ?? 'Section ${i + 1}',
                        'fill': 'bare',
                        'scale': 'fluid',
                        'onClick': [
                          setState(
                              multiple ? '$key.$i' : key, multiple ? !open : i),
                          ...ctx.list('onToggle')
                        ]
                      },
                      style: 'w-full justify-between px-16 py-12'),
                  if (open)
                    node('box:col', style: 'w-full px-16 pb-16', children: [
                      if (item['content'] is Map)
                        Map<String, dynamic>.from(item['content'] as Map)
                    ])
                ]));
          });
          return ctx.buildLayout(nativeSlotOverrides: {
            'items': ctx.buildSlot('items', nativeChildren: children)
          });
        });
  });

  QTemplateEngine.define('carousel',
      extendsAlias: 'navigation_shell',
      initialState: {
        'activeIndex': 0
      },
      layout: [
        'viewport',
        'controls',
        'indicators'
      ],
      transforms: {
        'viewport': 'w-full overflow-hidden rounded-12',
        'controls': 'row items-center justify-between w-full mt-12',
        'indicators': 'row gap-6 justify-center mt-8'
      }, nativeBuilder: (ctx) {
    final items = ctx.list('items');
    final key = stateKey(ctx, 'activeIndex');
    if (ctx.store.get(key) == null) ctx.store.set(key, 0);
    final sig = ctx.store.signal(key);
    return AnimatedBuilder(
        animation: sig,
        builder: (_, __) {
          final i = clampIndex(sig.value, items.length);
          final item = items.isEmpty ? const {} : items[i] as Map? ?? const {};
          final prev =
              items.isEmpty ? 0 : (i - 1 + items.length) % items.length;
          final next = items.isEmpty ? 0 : (i + 1) % items.length;
          return ctx.buildLayout(nativeSlotOverrides: {
            'viewport': ctx.buildSlot('viewport', nativeChildren: [
              if (item['content'] is Map)
                bp(Map<String, dynamic>.from(item['content'] as Map))
            ]),
            'controls': ctx.buildSlot('controls', nativeChildren: [
              bp(node('action:button', props: {
                'text': ctx.string('prevText', fallback: 'Previous'),
                'fill': 'ghost',
                'scale': 'sm',
                'onClick': [setState(key, prev)]
              })),
              bp(node('action:button', props: {
                'text': ctx.string('nextText', fallback: 'Next'),
                'fill': 'ghost',
                'scale': 'sm',
                'onClick': [setState(key, next)]
              }))
            ]),
            'indicators': ctx.buildSlot('indicators',
                nativeChildren: List.generate(
                    items.length,
                    (n) => bp(node('action:button',
                        props: {
                          'text': '',
                          'shape': 'circle',
                          'scale': 'xs',
                          'fill': n == i ? 'solid' : 'soft',
                          'onClick': [setState(key, n)]
                        },
                        style: 'w-8 h-8 p-0'))))
          });
        });
  });

  QTemplateEngine.define('stepper',
      extendsAlias: 'navigation_shell',
      initialState: {
        'activeIndex': 0
      },
      layout: [
        'steps',
        'content',
        'footer'
      ],
      transforms: {
        'steps': 'row w-full gap-8',
        'content': 'col w-full mt-16',
        'footer': 'row items-center justify-between w-full mt-16'
      }, nativeBuilder: (ctx) {
    final steps = ctx.list('steps', fallback: ctx.list('items'));
    final key = stateKey(ctx, 'activeIndex');
    if (ctx.store.get(key) == null) ctx.store.set(key, 0);
    final sig = ctx.store.signal(key);
    return AnimatedBuilder(
        animation: sig,
        builder: (_, __) {
          final i = clampIndex(sig.value, steps.length);
          final item = steps.isEmpty ? const {} : steps[i] as Map? ?? const {};
          return ctx.buildLayout(nativeSlotOverrides: {
            'steps': ctx.buildSlot('steps',
                nativeChildren: navItems(ctx, steps, key, prefix: 'Step')),
            'content': ctx.buildSlot('content', nativeChildren: [
              if (item['content'] is Map)
                bp(Map<String, dynamic>.from(item['content'] as Map))
            ]),
            'footer': ctx.buildSlot('footer', nativeChildren: [
              bp(node('action:button', props: {
                'text': ctx.string('backText', fallback: 'Back'),
                'disabled': i == 0,
                'fill': 'ghost',
                'onClick': [setState(key, math.max(0, i - 1))]
              })),
              bp(node('action:button', props: {
                'text': i == steps.length - 1
                    ? ctx.string('doneText', fallback: 'Done')
                    : ctx.string('nextText', fallback: 'Next'),
                'fill': 'solid',
                'onClick': i == steps.length - 1
                    ? ctx.list('onDone')
                    : [setState(key, math.min(steps.length - 1, i + 1))]
              }))
            ])
          });
        });
  });

  QTemplateEngine.define('search_panel',
      extendsAlias: 'control_shell',
      layout: [
        'search filters actions',
        'body body body',
        'empty empty empty'
      ],
      defaultSlots: {
        'search': {
          'type': 'field:search',
          'props': {'placeholder': 'Search', 'bind': 'searchQuery'}
        },
        'body': {'type': 'box:col'},
        'empty': {
          'type': 'box:col',
          'children': [txt('No results', style: 'text-slate-500')]
        }
      },
      guards: {
        'filters': 'showFilters',
        'actions': 'showActions',
        'empty': 'showEmpty'
      },
      transforms: {
        'search': 'w-full',
        'filters': 'row gap-8',
        'actions': 'row gap-8 justify-end',
        'body': 'col w-full mt-16',
        'empty': 'col items-center justify-center py-32'
      });

  QTemplateEngine.define('collection_shell',
      extendsAlias: 'surface_shell',
      layout: [
        'header header',
        'toolbar toolbar',
        'content content',
        'footer footer'
      ],
      defaultSlots: {
        'content': {
          'type': 'data:list',
          'props': {'pipeline': '{{pipeline}}', 'searchBind': '{{searchBind}}'}
        }
      },
      guards: {
        'header': 'showHeader',
        'toolbar': 'showToolbar',
        'footer': 'showFooter'
      },
      transforms: {
        'header': 'row items-center justify-between w-full mb-12',
        'toolbar': 'row items-center gap-8 w-full mb-12',
        'content': 'col w-full flex-1',
        'footer': 'row items-center justify-between w-full mt-12'
      },
      variants: {
        'layout': {
          'grid': {
            'content': {
              'type': 'data:grid',
              'props': {'cols': '{{cols}}'}
            }
          },
          'masonry': {
            'content': {
              'type': 'data:masonry',
              'props': {'cols': '{{cols}}'}
            }
          },
          'table': {
            'content': {'type': 'data:table'}
          }
        }
      });

  QTemplateEngine.define('form_panel', extendsAlias: 'control_shell', layout: [
    'header',
    'fields',
    'errors',
    'actions'
  ], defaultSlots: {
    'fields': {'type': 'control:form_scope'},
    'errors': {'type': 'box:col'},
    'actions': {'type': 'box:row'}
  }, guards: {
    'header': 'showHeader',
    'errors': 'showErrors',
    'actions': 'showActions'
  }, transforms: {
    'header': 'col w-full mb-16',
    'fields': 'col w-full gap-12',
    'errors': 'col w-full gap-6 mt-8',
    'actions': 'row w-full gap-8 justify-end mt-20'
  });

  QTemplateEngine.define('master_detail', extendsAlias: 'split_shell', layout: [
    'master detail'
  ], defaultSlots: {
    'master': {'type': 'box:col'},
    'detail': {'type': 'box:col'}
  }, transforms: {
    'master': 'col w-full min-w-0',
    'detail': 'col w-full min-w-0'
  }, variants: {
    'mode': {
      'sidebar': {
        'master': 'w-320 max-w-320 border-r-1 border-slate-200 pr-16',
        'detail': 'pl-16'
      },
      'stacked': {'master': 'mb-16', 'detail': 'pl-0'}
    }
  });

  QTemplateEngine.define('command_bar',
      extendsAlias: 'navigation_shell',
      layout: [
        'leading search actions'
      ],
      defaultSlots: {
        'search': {'type': 'field:search'},
        'actions': {'type': 'box:row'}
      },
      guards: {
        'leading': 'showLeading',
        'search': 'showSearch',
        'actions': 'showActions'
      },
      transforms: {
        'leading': 'row items-center gap-8',
        'search': 'flex-1 min-w-0',
        'actions': 'row items-center gap-8 justify-end'
      });

  QTemplateEngine.define('media_card', extendsAlias: 'media_shell', layout: [
    'media media',
    'eyebrow meta',
    'title title',
    'body body',
    'actions actions'
  ], defaultSlots: {
    'media': {'type': 'media:image'},
    'eyebrow': {'type': 'text:label'},
    'title': {'type': 'text:h3'},
    'body': {'type': 'text:p', 'style': 'text-slate-600'},
    'actions': {'type': 'box:row'}
  }, guards: {
    'eyebrow': 'showEyebrow',
    'meta': 'showMeta',
    'body': 'showBody',
    'actions': 'showActions'
  }, hero: {
    'media': 'media_card_{{id}}'
  }, transforms: {
    'media': 'w-full aspect-video rounded-12 overflow-hidden mb-12',
    'eyebrow': 'text-slate-500',
    'meta': 'text-right text-slate-500',
    'title': 'mt-4',
    'body': 'mt-8',
    'actions': 'row gap-8 mt-12'
  });

  QTemplateEngine.define('profile_card', extendsAlias: 'item_shell', layout: [
    'avatar name actions',
    'avatar role actions',
    'stats stats stats'
  ], defaultSlots: {
    'avatar': {
      'type': 'media:image',
      'props': {'radius': 999}
    },
    'name': {'type': 'text:h2'},
    'role': {'type': 'text:p', 'style': 'text-slate-500'},
    'actions': {'type': 'box:row'},
    'stats': {'type': 'box:row'}
  }, hero: {
    'avatar': 'profile_avatar_{{userId}}'
  }, guards: {
    'stats': 'showStats',
    'actions': 'showActions'
  }, transforms: {
    'avatar': 'w-64 h-64',
    'name': 'min-w-0',
    'role': 'min-w-0',
    'actions': 'row gap-8 justify-end',
    'stats': 'row gap-12 mt-16'
  }, variants: {
    'size': {
      'small': {
        'avatar': {'style': 'w-48 h-48'},
        'name': {'type': 'text:h3'}
      },
      'large': {
        'avatar': {'style': 'w-96 h-96 shadow-lg'},
        'name': {'type': 'text:h1'}
      }
    }
  });

  QTemplateEngine.define('product_card', extendsAlias: 'item_shell', layout: [
    'media media',
    'badge badge',
    'title title',
    'price rating',
    'actions actions'
  ], defaultSlots: {
    'media': {'type': 'media:image'},
    'badge': {'type': 'action:badge'},
    'title': {'type': 'text:h3'},
    'price': {'type': 'text:p', 'style': 'font-bold'},
    'rating': {'type': 'text:p', 'style': 'text-right text-slate-500'},
    'actions': {'type': 'box:row'}
  }, guards: {
    'badge': 'showBadge',
    'rating': 'showRating',
    'actions': 'showActions'
  }, hero: {
    'media': 'product_media_{{productId}}'
  }, transforms: {
    'media': 'w-full aspect-square rounded-12 overflow-hidden mb-12',
    'badge': 'mt-[-36] ml-8 mb-8',
    'title': 'min-w-0',
    'price': 'mt-8',
    'rating': 'mt-8 justify-end',
    'actions': 'row gap-8 mt-12'
  });

  QTemplateEngine.define('transaction_row',
      extendsAlias: 'item_shell',
      layout: [
        'icon title amount',
        'icon subtitle status'
      ],
      defaultSlots: {
        'icon': {'type': 'box:col'},
        'title': {'type': 'text:p', 'style': 'font-semibold'},
        'subtitle': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
        'amount': {'type': 'text:p', 'style': 'font-bold text-right'},
        'status': {'type': 'action:badge'}
      },
      guards: {
        'subtitle': 'showSubtitle',
        'status': 'showStatus'
      },
      transforms: {
        'icon': 'w-40 h-40 rounded-full bg-slate-100 flex-center',
        'title': 'min-w-0',
        'subtitle': 'min-w-0',
        'amount': 'text-right',
        'status': 'justify-end'
      });

  QTemplateEngine.define('payment_method', extendsAlias: 'item_shell', layout: [
    'brand title trailing',
    'brand subtitle trailing',
    'meta meta meta'
  ], defaultSlots: {
    'brand': {'type': 'box:col'},
    'title': {'type': 'text:p', 'style': 'font-semibold'},
    'subtitle': {'type': 'text:p', 'style': 'text-slate-500 text-sm'},
    'trailing': {'type': 'box:row'},
    'meta': {'type': 'box:row'}
  }, guards: {
    'subtitle': 'showSubtitle',
    'trailing': 'showTrailing',
    'meta': 'showMeta'
  }, transforms: {
    'brand': 'w-48 h-32 rounded-6 bg-slate-100 flex-center',
    'title': 'min-w-0',
    'subtitle': 'min-w-0',
    'trailing': 'row justify-end',
    'meta': 'row gap-8 mt-12'
  });

  QTemplateEngine.define('feed_card', extendsAlias: 'item_shell', layout: [
    'author actions',
    'body body',
    'media media',
    'reactions reactions',
    'comments comments'
  ], defaultSlots: {
    'author': {'type': 'box:row'},
    'actions': {'type': 'box:row'},
    'body': {'type': 'text:p'},
    'media': {'type': 'box:col'},
    'reactions': {'type': 'box:row'},
    'comments': {'type': 'box:col'}
  }, guards: {
    'actions': 'showActions',
    'media': 'showMedia',
    'reactions': 'showReactions',
    'comments': 'showComments'
  }, transforms: {
    'author': 'row items-center gap-8',
    'actions': 'row justify-end gap-8',
    'body': 'mt-12',
    'media': 'mt-12 rounded-12 overflow-hidden',
    'reactions': 'row gap-8 mt-12',
    'comments': 'col gap-8 mt-12'
  });

  QTemplateEngine.define('state_surface', extendsAlias: 'state_shell', layout: [
    'illustration',
    'title',
    'body',
    'actions'
  ], defaultSlots: {
    'title': {'type': 'text:h3'},
    'body': {'type': 'text:p', 'style': 'text-slate-500 text-center'},
    'actions': {'type': 'box:row'}
  }, guards: {
    'illustration': 'showIllustration',
    'body': 'showBody',
    'actions': 'showActions'
  }, transforms: {
    'illustration': 'mb-16 flex-center',
    'title': 'text-center',
    'body': 'mt-8 max-w-360',
    'actions': 'row gap-8 justify-center mt-16'
  }, variants: {
    'tone': {
      'error': {'title': 'text-red-700', 'body': 'text-red-600'},
      'success': {'title': 'text-emerald-700', 'body': 'text-emerald-600'},
      'warning': {'title': 'text-amber-700', 'body': 'text-amber-600'}
    }
  });

  QTemplateEngine.define('metric_tile', extendsAlias: 'item_shell', layout: [
    'icon label trend',
    'value value trend',
    'footer footer footer'
  ], defaultSlots: {
    'icon': {'type': 'box:col'},
    'label': {'type': 'text:label'},
    'value': {'type': 'text:h2'},
    'trend': {'type': 'action:badge'},
    'footer': {'type': 'text:p', 'style': 'text-slate-500 text-sm'}
  }, guards: {
    'icon': 'showIcon',
    'trend': 'showTrend',
    'footer': 'showFooter'
  }, transforms: {
    'icon': 'w-40 h-40 rounded-8 bg-slate-100 flex-center',
    'label': 'text-slate-500',
    'value': 'mt-4',
    'trend': 'justify-end',
    'footer': 'mt-8'
  });

  QTemplateEngine.define('flow_shell', extendsAlias: 'split_shell', layout: [
    'chrome chrome',
    'sidebar content',
    'footer footer'
  ], defaultSlots: {
    'chrome': {'type': 'box:row'},
    'sidebar': {'type': 'box:col'},
    'content': {'type': 'control:flow'},
    'footer': {'type': 'box:row'}
  }, guards: {
    'chrome': 'showChrome',
    'sidebar': 'showSidebar',
    'footer': 'showFooter'
  }, hero: {
    'content': 'flow_{{namespace}}_{{heroTag}}',
    'sidebar': 'flow_sidebar_{{namespace}}'
  }, transforms: {
    'chrome': 'row items-center justify-between w-full gap-12',
    'sidebar': 'col w-full min-w-0',
    'content': 'col w-full min-w-0 flex-1',
    'footer': 'row items-center justify-between w-full mt-12'
  }, variants: {
    'density': {
      'compact': {'content': 'gap-8'},
      'immersive': {'chrome': 'px-4 py-2', 'content': 'gap-16'}
    },
    'sidebarPosition': {
      'left': {'sidebar': 'order-0'},
      'right': {'sidebar': 'order-2'}
    }
  });

  QTemplateEngine.define('hero_bridge', extendsAlias: 'split_shell', layout: [
    'source',
    'destination'
  ], defaultSlots: {
    'source': {'type': 'box:col'},
    'destination': {'type': 'box:col'}
  }, transforms: {
    'source': 'col w-full min-w-0',
    'destination': 'col w-full min-w-0'
  }, hero: {
    'source': 'bridge_{{bridgeId}}',
    'destination': 'bridge_{{bridgeId}}'
  }, variants: {
    'direction': {
      'source_to_destination': {'source': 'order-0', 'destination': 'order-1'},
      'destination_to_source': {'source': 'order-1', 'destination': 'order-0'}
    }
  });

  for (final alias in const [
    'surface_shell',
    'item_shell',
    'cluster_shell',
    'split_shell',
    'state_shell',
    'overlay_shell',
    'control_shell',
    'media_shell',
    'navigation_shell',
    'card_shell',
    'workspace_shell',
    'inspector_shell',
    'table_shell',
    'composer_shell',
    'timeline_shell',
    'stage_shell',
    'wizard_shell',
    'tabs',
    'segmented_control',
    'accordion',
    'carousel',
    'stepper',
    'search_panel',
    'collection_shell',
    'form_panel',
    'master_detail',
    'command_bar',
    'media_card',
    'profile_card',
    'product_card',
    'transaction_row',
    'payment_method',
    'feed_card',
    'state_surface',
    'metric_tile',
    'rich_shell',
    'menu_item',
    'nested_menu',
    'list_item',
    'rich_list',
    'table_row',
    'rich_table',
    'avatar_item',
    'avatar_group',
    'category_browser',
    'field_shell',
    'popover_shell',
    'field_text',
    'field_number',
    'field_toggle',
    'field_slider',
    'field_select',
    'field_array',
    'field_blocks',
    'field_data',
    'field_lookup',
    'field_relation',
    'field_shell_stacked',
    'flow_shell',
    'hero_bridge',
  ]) {
    vm.defineAlias(alias, 'template:$alias');
  }

  vm.defineAlias('tabs_shell', 'template:tabs');
  vm.defineAlias('carousel_shell', 'template:carousel');
  vm.defineAlias('canvas_shell', 'template:stage_shell');
  vm.defineAlias('search_shell', 'template:search_panel');
  vm.defineAlias('data_shell', 'template:collection_shell');
  vm.defineAlias('wizard', 'template:stepper');
  vm.defineAlias('empty_state', 'template:state_surface',
      defaultProps: {'tone': 'empty'});
  vm.defineAlias('error_state', 'template:state_surface',
      defaultProps: {'tone': 'error'});
}

void _registerTemplateAliases(QuantumVM vm) {
  vm.defineAlias('menu', 'template:nested_menu',
      description: 'Menu template alias.', tags: const ['template', 'alias']);
  vm.defineAlias('menu_item', 'template:menu_item',
      description: 'Menu item template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('list', 'template:rich_list',
      description: 'List template alias.', tags: const ['template', 'alias']);
  vm.defineAlias('table', 'template:rich_table',
      description: 'Table template alias.', tags: const ['template', 'alias']);
  vm.defineAlias('avatars', 'template:avatar_group',
      description: 'Avatars template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('avatar_group', 'template:avatar_group',
      description: 'Avatar group template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('categories', 'template:category_browser',
      description: 'Categories template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('category_browser', 'template:category_browser',
      description: 'Category browser template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('rich_shell', 'template:rich_shell',
      description: 'Rich shell template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('rich_list', 'template:rich_list',
      description: 'Rich list template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('rich_table', 'template:rich_table',
      description: 'Rich table template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('tabs', 'template:tabs',
      description: 'Template tabs alias.', tags: const ['template', 'alias']);
  vm.defineAlias('data_shell', 'template:collection_shell',
      description: 'Data shell template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('wizard', 'template:stepper',
      description: 'Wizard template alias.', tags: const ['template', 'alias']);
  vm.defineAlias('empty_state', 'template:state_surface',
      description: 'Empty state template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('error_state', 'template:state_surface',
      description: 'Error state template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('profile_card', 'template:profile_card',
      description: 'Profile card template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('flow_shell', 'template:flow_shell',
      description: 'Flow shell template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('hero_bridge', 'template:hero_bridge',
      description: 'Hero bridge template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('tabs_shell', 'template:tabs',
      description: 'Tabs shell template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('carousel_shell', 'template:carousel',
      description: 'Carousel shell template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('canvas_shell', 'template:stage_shell',
      description: 'Canvas shell template alias.',
      tags: const ['template', 'alias']);
  vm.defineAlias('search_shell', 'template:search_panel',
      description: 'Search shell template alias.',
      tags: const ['template', 'alias']);
}
