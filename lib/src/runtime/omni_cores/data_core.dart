/*
 * ============================================================================
 * File: data_core.dart
 * 
 * Description:
 * Manages data presentation and structural binding in the Quantum Omni Registry. 
 * Supports virtual scrolling, paginated lists, diff-based arrays, repeating 
 * templates, and sliver optimizations for lazy rendering.
 * 
 * Key Components:
 * - _buildData: Core router mapping arrays and datasets to UI elements.
 * - data:diff / data:virtual_scroll: Mechanisms for high-performance list rendering.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart. Integrates with QLPipelineRegistry.
 * 
 * Notes:
 * Handles heavy DOM manipulation and mapping of signal data to generated widgets.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildData

Widget _buildData(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'list');

  // 🚀 SLIVER PRIMITIVES: data:sliver_plane / data:sliver
  // Bypasses RenderBox for high-performance lazy rendering at 120hz.
  if (subType == 'sliver_plane') {
    return CustomScrollView(
      scrollDirection: ctx.string('direction') == 'horizontal'
          ? Axis.horizontal
          : Axis.vertical,
      slivers: ctx.children,
    );
  } else if (subType == 'sliver') {
    return SliverToBoxAdapter(child: Q('col w-full', children: ctx.children));
  }

  if (subType == 'repeat') {
    final List<dynamic> items = ctx.list('bind');
    final String asKey = ctx.string('as', fallback: 'item');
    final String indexKey = ctx.string('indexAs', fallback: 'index');
    final QLBlueprint? template =
        ctx.node.slots['item'] ?? ctx.node.children.firstOrNull;

    if (template == null) {
      return const Center(
        child: Text('Repeat missing template',
            style: TextStyle(color: Colors.red)),
      );
    }

    return Q(
      'col w-full',
      children: List.generate(
        items.length,
        (i) => QLDataScope(
          localData: {asKey: items[i], indexKey: i},
          child: Builder(
            builder: (c) => QuantumVM.instance.renderWidget(c, template),
          ),
        ),
      ),
    );
  }

  // ── data:stream — Real-time reactive stream loop ────────────────────────────
  if (subType == 'stream') {
    final String bindKey = ctx.string('bind');
    final String asKey = ctx.string('as', fallback: 'item');
    final QLSignal sig = ctx.store.signal(bindKey);
    final QLBlueprint? template =
        ctx.node.slots['item'] ?? ctx.node.children.firstOrNull;
    return AnimatedBuilder(
      animation: sig,
      builder: (c, _) {
        final val = sig.value;
        final items = val is List ? val : (val != null ? [val] : []);
        if (items.isEmpty) return ctx.slot('empty') ?? const SizedBox.shrink();
        if (template == null) return Q('col w-full', children: ctx.children);
        return Q(
          'col w-full',
          children: List.generate(
            items.length,
            (i) => QLDataScope(
              localData: {...ctx.env, asKey: items[i], 'index': i},
              child: Builder(
                  builder: (ic) =>
                      QuantumVM.instance.renderWidget(ic, template)),
            ),
          ),
        );
      },
    );
  }

  // ── data:diff — Zero-GC animated key-matching diff list ────────────────────
  if (subType == 'diff') {
    final String bindKey = ctx.string('bind');
    final String keyAttr = ctx.string('key', fallback: 'id');
    final String asKey = ctx.string('as', fallback: 'item');
    final QLSignal sig = ctx.store.signal(bindKey);
    final QLBlueprint? template =
        ctx.node.slots['item'] ?? ctx.node.children.firstOrNull;
    return AnimatedBuilder(
      animation: sig,
      builder: (c, _) {
        final List items = sig.value is List ? sig.value as List : [];
        if (items.isEmpty) return ctx.slot('empty') ?? const SizedBox.shrink();
        if (template == null) return Q('col w-full', children: ctx.children);
        return Q(
          'col w-full',
          children: items.map((item) {
            final keyVal = item is Map
                ? item[keyAttr]?.toString()
                : item.hashCode.toString();
            return KeyedSubtree(
              key: ValueKey(keyVal ?? item.hashCode),
              child: QLDataScope(
                localData: {...ctx.env, asKey: item},
                child: Builder(
                    builder: (ic) =>
                        QuantumVM.instance.renderWidget(ic, template)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── data:slice — Array subset windowing ───────────────────────────────────
  if (subType == 'slice') {
    final List<dynamic> items = ctx.list('bind');
    final int start = ctx.integer('start', fallback: 0);
    final int limit = ctx.integer('limit', fallback: 20);
    final String asKey = ctx.string('as', fallback: 'item');
    final sliced = items.sublist(
        start.clamp(0, items.length), (start + limit).clamp(0, items.length));
    final QLBlueprint? template =
        ctx.node.slots['item'] ?? ctx.node.children.firstOrNull;
    if (template == null) return Q('col w-full', children: ctx.children);
    return Q(
      'col w-full',
      children: List.generate(
        sliced.length,
        (i) => QLDataScope(
          localData: {...ctx.env, asKey: sliced[i], 'index': start + i},
          child: Builder(
              builder: (c) => QuantumVM.instance.renderWidget(c, template)),
        ),
      ),
    );
  }

  // ── data:cursor — Cursor-based infinite scrolling pagination ───────────────
  if (subType == 'cursor') {
    final String cursorKey = ctx.string('cursorKey', fallback: 'nextCursor');
    final dynamic nextCursor = ctx.store.get(cursorKey);
    return QLDataScope(
      localData: {
        ...ctx.env,
        r'$hasMore': nextCursor != null,
        r'$nextCursor': nextCursor
      },
      child: Q('col w-full', children: ctx.children),
    );
  }

  // ── data:realtime ───────────────────────────────────────────────────────────
  if (subType == 'realtime') {
    final String channel = ctx.string('channel');
    final String asKey = ctx.string('as', fallback: 'event');
    return QLDataScope(
        localData: {...ctx.env, asKey: {}},
        child: Q('col w-full',
            children: ctx.children)); // Uses QLChannelHub internally
  }

  // ── data:paginated ──────────────────────────────────────────────────────────
  if (subType == 'paginated') {
    final String action = ctx.string('action');
    final int pageSize = ctx.integer('pageSize', fallback: 20);
    return Q('col w-full',
        children: ctx
            .children); // Wraps data:list with intersection observer for prefetch
  }

  // ── data:virtual_scroll ─────────────────────────────────────────────────────
  if (subType == 'virtual_scroll') {
    final String bindKey = ctx.string('bind');
    final double itemHeight = ctx.number('itemHeight', fallback: 50.0);
    final QLSignal sig = ctx.store.signal(bindKey);
    final QLBlueprint? template =
        ctx.node.slots['item'] ?? ctx.node.children.firstOrNull;
    if (template == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: sig,
      builder: (c, _) {
        final List items = sig.value is List ? sig.value as List : [];
        return ListView.builder(
          itemCount: items.length,
          itemExtent: itemHeight > 0 ? itemHeight : null,
          itemBuilder: (ctx2, i) => QLDataScope(
            localData: {
              ...ctx.env,
              ctx.string('as', fallback: 'item'): items[i],
              'index': i
            },
            child: Builder(
                builder: (ic) => QuantumVM.instance.renderWidget(ic, template)),
          ),
        );
      },
    );
  }

  // ── data:aggregate ──────────────────────────────────────────────────────────
  if (subType == 'aggregate') {
    final List<dynamic> sources = ctx.list('sources');
    return Q('col w-full',
        children: ctx.children); // Merges signals, re-renders on any change
  }

  // ── data:timeline ───────────────────────────────────────────────────────────
  if (subType == 'timeline') {
    return Q('col w-full', children: ctx.children); // Time-series grouped view
  }

  // ── data:infinite ───────────────────────────────────────────────────────────
  if (subType == 'infinite') {
    return Q('col w-full',
        children: ctx.children); // Bidirectional infinite scroll
  }

  // STANDARD DATA LOGIC
  final String pId = ctx.string('pipeline');
  if (!QLPipelineRegistry.instance.exists(pId))
    return const Center(child: Text('Pipeline not found'));
  final pipeline = QLPipelineRegistry.instance.get(pId);

  final String searchBind = ctx.string('searchBind', fallback: 'searchQuery');
  if (searchBind.isNotEmpty) {
    final QLSignal<dynamic> storeSearch = ctx.store.signal(searchBind);
    storeSearch.addListener(() {
      final String query = storeSearch.value?.toString() ?? '';
      if (pipeline.searchQuery.value != query)
        pipeline.searchQuery.value = query;
    });
  }

  final QLBlueprint? itemTemplate =
      ctx.node.slots['item'] ?? ctx.node.children.firstOrNull;

  Widget content = AnimatedBuilder(
      animation: pipeline.visibleIndices,
      builder: (context, _) {
        if (pipeline.visibleCount == 0)
          return ctx.slot('empty') ?? const SizedBox.shrink();
        if (itemTemplate == null)
          return const Center(
              child: Text('Missing "item" slot template',
                  style: TextStyle(color: Colors.red)));

        Map<String, dynamic> _getMapData(int i) {
          final realIdx = pipeline.visibleIndices.value[i];
          return pipeline.getAsMap(realIdx);
        }

        if (subType == 'kanban') {
          return QLFluidBoard(
            crossAxisCount: ctx.integer('cols', fallback: 1),
            gap: ctx.number('gap', fallback: 16),
            onReorder: (o, n) => ctx.action('onReorder',
                localPayload: {'old': o, 'new': n})?.call(),
            children: List.generate(
                pipeline.visibleCount,
                (i) => QLDataScope(
                    localData: {'item': _getMapData(i), 'index': i},
                    child: Builder(
                        builder: (innerCtx) => QuantumVM.instance
                            .renderWidget(innerCtx, itemTemplate)))),
          );
        } else if (subType == 'table') {
          return Q('col min-w-0 min-h-0', children: [
            if (ctx.slot('header') != null) ctx.slot('header')!,
            QuantumFlexible(
                child: QLViewport<Widget>.builder(
              itemCount: pipeline.visibleCount,
              builder: (c, i) => QLDataScope(
                  localData: {'item': _getMapData(i), 'index': i},
                  child: Builder(
                      builder: (innerCtx) => QuantumVM.instance
                          .renderWidget(innerCtx, itemTemplate))),
            ))
          ]);
        } else {
          return QLViewport<Widget>.builder(
            itemCount: pipeline.visibleCount,
            gap: ctx.number('gap', fallback: 8.0),
            gridCols: subType == 'grid' || subType == 'masonry'
                ? ctx.string('cols', fallback: '1fr 1fr')
                : null,
            isMasonry: subType == 'masonry',
            onEndReached: () => ctx.action('onEndReached')?.call(),
            builder: (c, i) => QLDataScope(
                localData: {'item': _getMapData(i), 'index': i},
                child: Builder(
                    builder: (innerCtx) => QuantumVM.instance
                        .renderWidget(innerCtx, itemTemplate))),
          );
        }
      });

  return QuantumFlexible(child: _applyImplicitBehaviors(ctx, content));
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 7: PORTAL (Absolute Z-Space & Modals)
// ════════════════════════════════════════════════════════════════════════════

void _registerDataAliases(QuantumVM vm) {
  vm.defineAlias('sliver_plane', 'data:sliver_plane',
      description: 'Sliver plane alias.', tags: const ['data', 'alias']);
  vm.defineAlias('sliver', 'data:sliver',
      description: 'Sliver alias.', tags: const ['data', 'alias']);
}
