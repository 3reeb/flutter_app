// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI MANIFOLD v3.0 - UNCOMPROMISED SPATIAL ISOLATE CALCULATOR
// quantum_omni_manifold.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../quantum.dart';

// ── THE ISOLATE TASK (100% Unsimplified Math Projection Engine) ──
class QLManifoldSpatialTask
    extends QLWorkerTask<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  dynamic encode(Map<String, dynamic> input) => input;

  @override
  dynamic compute(dynamic encoded) {
    final Map p = encoded as Map;
    final List records = p['records'] ?? [];
    final Int32List visibleIndices = p['visibleIndices'];
    final Map proj = p['projection'];
    final Float64List? extVecX = p['vectorX'];
    final Float64List? extVecW = p['vectorW'];

    final int count = visibleIndices.length;
    final Float64List bounds = Float64List(count * 4);
    final Float64List constraints = Float64List(count * 4);
    final Int32List meta = Int32List(count * 2);

    // Trackers for stateful projections (Stacks, Grids, Groups)
    final Map<String, int> groupIndex = {};
    final Map<String, double> stackY = {};
    final Map<String, double> stackX = {};
    int nextGroup = 0;

    double resolveAxis(Map rule, dynamic record, int loopIdx, String axis) {
      final String mode = rule['mode']?.toString() ?? 'absolute';
      final String bind = rule['bind']?.toString() ?? '';
      final dynamic rawVal =
          bind.isNotEmpty && record is Map ? record[bind] : null;

      switch (mode) {
        case 'absolute':
          return (rule['value'] as num?)?.toDouble() ??
              (axis == 'w' || axis == 'h' ? -1.0 : 0.0);

        case 'linear': // Scatter plots
          final double val = (rawVal is num)
              ? rawVal.toDouble()
              : (double.tryParse(rawVal?.toString() ?? '0') ?? 0.0);
          final double scale = (rule['scale'] as num?)?.toDouble() ?? 1.0;
          return (val * scale) + ((rule['offset'] as num?)?.toDouble() ?? 0.0);

        case 'modulo': // Grids / Calendars (Columns)
          final int mod = (rule['mod'] as num?)?.toInt() ?? 1;
          return (loopIdx % mod) *
              ((rule['stride'] as num?)?.toDouble() ?? 100.0);

        case 'division': // Grids / Calendars (Rows)
          final int div = (rule['div'] as num?)?.toInt() ?? 1;
          return (loopIdx ~/ div) *
              ((rule['stride'] as num?)?.toDouble() ?? 100.0);

        case 'group': // Kanban Columns
          final String key = rawVal?.toString() ?? 'default';
          if (!groupIndex.containsKey(key)) groupIndex[key] = nextGroup++;
          return groupIndex[key]! *
              ((rule['stride'] as num?)?.toDouble() ?? 300.0);

        case 'stack': // Kanban Cards / Lists
          final String key = rule['groupBy'] != null && record is Map
              ? (record[rule['groupBy']]?.toString() ?? 'default')
              : 'global';
          final double stride = (rule['stride'] as num?)?.toDouble() ?? 50.0;

          if (axis == 'y') {
            final double current = stackY[key] ?? 0.0;
            stackY[key] = current + stride;
            return current;
          } else {
            final double current = stackX[key] ?? 0.0;
            stackX[key] = current + stride;
            return current;
          }

        case 'vector': // Hardware Tables
          final int vIdx = (rule['vectorIndex'] as num?)?.toInt() ?? loopIdx;
          if (axis == 'x' && extVecX != null && vIdx < extVecX.length)
            return extVecX[vIdx];
          if (axis == 'w' && extVecW != null && vIdx < extVecW.length)
            return extVecW[vIdx];
          return axis == 'w' || axis == 'h' ? -1.0 : 0.0;

        default:
          return axis == 'w' || axis == 'h' ? -1.0 : 0.0;
      }
    }

    // Execute Math Engine
    for (int i = 0; i < count; i++) {
      final int realIdx = visibleIndices[i];
      final record = records[realIdx];
      final int ptr = i * 4;

      bounds[ptr + 0] = resolveAxis(proj['x'] ?? {}, record, i, 'x');
      bounds[ptr + 1] = resolveAxis(proj['y'] ?? {}, record, i, 'y');
      bounds[ptr + 2] = resolveAxis(proj['w'] ?? {}, record, i, 'w');
      bounds[ptr + 3] = resolveAxis(proj['h'] ?? {}, record, i, 'h');

      constraints[ptr + 0] = 0; // minW
      constraints[ptr + 1] = double.infinity; // maxW
      constraints[ptr + 2] = 0; // minH
      constraints[ptr + 3] = double.infinity; // maxH

      meta[i * 2 + 0] = QLSpaceFlags.none;
      meta[i * 2 + 1] = i; // Default Z-Index
    }

    return {
      'bounds': QLTransferableBuffer.encodeFloat64(bounds),
      'constraints': QLTransferableBuffer.encodeFloat64(constraints),
      'meta': meta,
    };
  }

  @override
  Map<String, dynamic> decode(dynamic raw) {
    final map = raw as Map;
    return {
      'bounds': (map['bounds'] as QLTransferableBuffer).decodeFloat64(),
      'constraints':
          (map['constraints'] as QLTransferableBuffer).decodeFloat64(),
      'meta': map['meta'] as Int32List,
    };
  }
}

// ── THE SDUI COMPONENT (Registers the Manifold & Teleport Actions) ──

void registerOmniManifold(QuantumVM vm) {
  // 🚀 UNCOMPROMISED TRANSPORT: Seamless Overlay Teleportation
  vm.registerAction('manifold.warp_to_overlay',
      LambdaActionPlugin((payload, store, ctx) async {
    final String manifoldId = payload['manifoldId'];
    final int index = int.parse(payload['index'].toString());

    final QLWorkspaceController? wsCtrl = store.get('${manifoldId}_ws');
    final GlobalKey? transportKey = store.get('${manifoldId}_key_$index');

    if (wsCtrl != null && transportKey != null) {
      wsCtrl.hideNode(index, true); // O(1) Int32List Flag Flip

      ctx
          .mountOverlay(
            QLSpatialConfig.dialog(),
            (overlayCtx, close) => KeyedSubtree(
                key: transportKey, // Flutter Native DOM Reparenting
                child: const SizedBox.shrink()),
          )
          .then((_) => wsCtrl.hideNode(index, false));
    }
  }));

  vm.define('q_omni_manifold', (ctx) {
    final String manifoldId =
        ctx.string('id', fallback: 'mnf_${ctx.node.hashCode}');
    final String pipelineId = ctx.string('pipeline');
    final bool isCanvas = ctx.boolean('canvasMode');
    final bool transportable = ctx.boolean('transportable');

    QLWorkspaceController? wsCtrl = ctx.store.get('${manifoldId}_ws');
    if (wsCtrl == null) {
      wsCtrl = QLWorkspaceController();
      ctx.store.set('${manifoldId}_ws', wsCtrl);
    }

    final pipeline = QLPipelineRegistry.instance.get(pipelineId);
    final String ctrlId = ctx.string('tableControllerId');
    final QLTableLayoutController? tableCtrl = ctrlId.isNotEmpty
        ? ctx.store.get(ctrlId) as QLTableLayoutController?
        : null;

    final Map<String, dynamic> projRules = {
      'x': ctx.map('xAxis'),
      'y': ctx.map('yAxis'),
      'w': ctx.map('wAxis'),
      'h': ctx.map('hAxis'),
    };

    final QLBlueprint templateNode = ctx.node.children.first;

    return AnimatedBuilder(
        animation: Listenable.merge([
          pipeline.visibleIndices,
          if (tableCtrl != null) tableCtrl.version
        ]),
        builder: (context, _) {
          final int count = pipeline.visibleCount;

          // 1. Fire True Math Isolate
          final taskSig =
              QuantumVM.instance.workerPool.submit(QLManifoldSpatialTask(), {
            'records': pipeline.rawRecords,
            'visibleIndices': pipeline.visibleIndices.value,
            'projection': projRules,
            'vectorX': tableCtrl?.offsetsX,
            'vectorW': tableCtrl?.widths,
          });

          // 2. Await Math -> Inject directly into GPU Arrays
          taskSig.data.addListener(() {
            final data = taskSig.data.value;
            // 🚀 FIX 1: Use `context.mounted` instead of `mounted`
            if (data != null && context.mounted) {
              wsCtrl!.loadMemory(
                  data['bounds'], data['constraints'], data['meta']);
            }
          });

          // 3. Mount Subtrees
          final List<Widget> items = List.generate(count, (i) {
            final realIdx = pipeline.visibleIndices.value[i];
            final record = pipeline.rawRecords[realIdx];

            Key? itemKey;
            if (transportable) {
              final String keyId = '${manifoldId}_key_$i';
              itemKey = ctx.store.get(keyId);
              if (itemKey == null) {
                itemKey = GlobalKey(debugLabel: keyId);
                ctx.store.set(keyId, itemKey);
              }
            }

            return KeyedSubtree(
              key: itemKey ?? ValueKey(record[0]),
              child: QLDataScope(
                localData: {
                  'item': record,
                  'index': i,
                  'manifoldId': manifoldId
                },
                child: Builder(
                    builder: (c) =>
                        QuantumVM.instance.renderWidget(c, templateNode)),
              ),
            );
          });

          // 4. Render directly to Hardware Workspace
          return QLWorkspace(
            // 🚀 FIX 2: Add '!' to assure Dart this is absolutely not null here
            controller: wsCtrl!,
            isCanvas: isCanvas,
            children: items,
          );
        });
  });
}
