/*
 * ============================================================================
 * File: quantum_omni_registry.dart
 * 
 * Description:
 * The grand central component registry for the Quantum framework. It defines 
 * all structural "cores" (box, text, action, fields, layouts, etc.) and routes 
 * every SDUI element through these optimized builders. It also manages the 
 * dynamic CSS-like QDesignMatrix styling engine and huge sets of component aliases.
 * 
 * Key Components:
 * - registerOmniComponents: The massive bootstrap function defining all core types.
 * - QDesignMatrix: Procedural generator for Tailwind-like utility classes based on intent/scale/shape.
 * - _resolveFieldController: High-performance resolver for form field states.
 * 
 * Dependencies/Relationships:
 * Highly coupled to all Quantum core libraries and features (charts, layout, 
 * matrix engines, rendering).
 * 
 * Notes:
 * This is an immense, performance-critical file utilizing LRU flyweight caches 
 * for design tokens and aggressive optimization techniques to eliminate AST depth.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI REGISTRY v17.0 — 20-CORE OMEGA+ BUILD (SPATIAL/GPU/DECORATION/CHART/ANIMATION EXTENDED)
// quantum_omni_registry.dart
//
// BREAKTHROUGHS & REFACTORING:
// 1. The 20 Omniversal Cores: Every UI element routes through 16 root builders.
// 2. Colon Syntax (Base:Sub): `box:row`, `field:email`, `portal:dialog`.
// 3. Implicit Behaviors: Eliminates AST depth. Draggable, DropZone, Magneto
//    are applied natively if props exist.
// 4. Int32 AOT Template Engine: Guards, Match, and Transforms compiled into
//    zero-allocation integer blocks.
// 5. [NEW] True Spatial/GPU Primitives: box:measure, box:matrix, canvas:shader.
// 6. [NEW] Hardware Kinematics: action:raw_pointer, action:focus, system:ticker.
// 7. [NEW] Isolate/Scroll Telemetry: system:worker, system:sync_scroll.
// 8. [NEW] The Omega Macro: A god-tier context builder for complex UI patterns.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:collection';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'quantum_preset_engine.dart';
import 'package:quantum_layout/quantum.dart';
import '../foundation/quantum_json_dsl.dart';
import '../features/charts/quantum_charts.dart';
import '../foundation/quantum_matrix_engine.dart';
import '../platform/quantum_connect_engine.dart';
import 'package:quantum_layout/src/features/media/quantum_media_engine.dart';
part 'omni_cores/box_core.dart';
part 'omni_cores/action_core.dart';
part 'omni_cores/field_core.dart';
part 'omni_cores/text_core.dart';
part 'omni_cores/media_core.dart';
part 'omni_cores/visual_core.dart';
part 'omni_cores/hook_core.dart';
part 'omni_cores/data_core.dart';
part 'omni_cores/portal_core.dart';
part 'omni_cores/control_core.dart';
part 'omni_cores/canvas_core.dart';
part 'omni_cores/system_core.dart';
part 'omni_cores/decoration_core.dart';
part 'omni_cores/preset_core.dart';
part 'omni_cores/connect_core.dart';
part 'omni_cores/chart_core.dart';
part 'omni_cores/animation_core.dart';
part 'omni_cores/stream_core.dart';
part 'omni_cores/collab_core.dart';

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  LRU FLYWEIGHT CACHES & STANDALONE CONTROLLERS
// ────────────────────────────────────────────────────────────────────────────

class _AliasContext extends QLContext {
  _AliasContext(QLContext base)
      : super(base.flutterContext, base.node, base.env, base.store);

  String get intent =>
      string('intent', fallback: string('tone', fallback: 'slate-900'));
  String get fill =>
      string('fill', fallback: string('variant', fallback: 'surface'));
  String get depth => string('depth', fallback: 'flat');
  String get edge => string('edge', fallback: 'none');
  String get shape => string('shape', fallback: 'rounded');
  String get scale => string('scale', fallback: string('size', fallback: 'md'));
}

const int _kCacheMax = 512;
final LinkedHashMap<int, String> _designCache = LinkedHashMap<int, String>();

// 🚀 STANDALONE FIELD REGISTRY
// Holds controllers for fields that are NOT inside a `control:form_scope`.
// If they are in a form scope, the QLFormController manages their memory.
final Map<String, QLFieldController> _standaloneFieldRegistry = {};
final Map<String, QLFormController> _dummyForms = {};

void clearQuantumInputRegistry() {
  for (final ctrl in _standaloneFieldRegistry.values) {
    ctrl.dispose();
  }
  for (final form in _dummyForms.values) {
    form.dispose();
  }
  _standaloneFieldRegistry.clear();
  _dummyForms.clear();
  _designCache.clear();
}
// ════════════════════════════════════════════════════════════════════════════
// THE HIGH-PERFORMANCE CONTROLLER RESOLVER (quantum_omni_registry.dart)
// ════════════════════════════════════════════════════════════════════════════

// 🚀 HELPER: Dynamically Extracts or Creates the Form Controller directly from Env
QLFormController _getFormController(Map<String, dynamic> env) {
  // Check if a parent Form/Control shell injected a controller into the env
  if (env['__formController'] is QLFormController) {
    return env['__formController'] as QLFormController;
  }

  // 🚀 FALLBACK: If no form scope exists, create an ephemeral one attached to the UI context
  // This guarantees every field has a math engine even if the developer forgot to wrap it in a form!
  final form = QLFormController();
  env['__formController'] = form;
  return form;
}

T _resolveFieldController<T extends QLFieldController>(
  dynamic ctx, // Works with both QLContext and _AliasContext
  String id,
  String bindPath,
  T Function(QLFormController) creator,
) {
  final String actualPath = bindPath.isNotEmpty ? bindPath : id;

  // 🚀 FIX: Pass ctx.env directly, bypassing the 'rawCtx' error completely
  final form = _getFormController(ctx.env);

  T ctrl;
  if (form.hasNode(actualPath)) {
    ctrl = form.getNode(actualPath) as T;
  } else {
    ctrl = creator(form);
  }

  // 🚀 FIX: Use public getter isStoreBound
  if (!ctrl.isStoreBound) {
    ctrl.bindStore(ctx.store, actualPath);
  }

  return ctrl;
}
// ─────────────────────────────────────────────────────────────────────── §2 ─
//  QUANTUM OMNI-MATRIX (9-Dimensional Procedural CSS Generator)
// ────────────────────────────────────────────────────────────────────────────

abstract final class QDesignMatrix {
  static const int _kCacheMax = 512;
  static final LinkedHashMap<String, String> _cache =
      LinkedHashMap<String, String>();

  static String _key({
    required String family,
    required String intent,
    required String fill,
    required String depth,
    required String edge,
    required String shape,
    required String scale,
    required bool disabled,
  }) =>
      '$family|$intent|$fill|$depth|$edge|$shape|$scale|${disabled ? 1 : 0}';

  @pragma('vm:prefer-inline')
  static String resolve({
    required String family,
    required String intent,
    required String fill,
    required String depth,
    required String edge,
    required String shape,
    required String scale,
    required bool disabled,
  }) {
    final String key = _key(
      family: family,
      intent: intent,
      fill: fill,
      depth: depth,
      edge: edge,
      shape: shape,
      scale: scale,
      disabled: disabled,
    );

    final cached = _cache[key];
    if (cached != null) {
      _cache.remove(key);
      _cache[key] = cached;
      return cached;
    }

    if (_cache.length >= _kCacheMax) {
      _cache.remove(_cache.keys.first);
    }

    final computed = _compute(
      family,
      intent,
      fill,
      depth,
      edge,
      shape,
      scale,
      disabled,
    );
    _cache[key] = computed;
    return computed;
  }

  static String _compute(String family, String intent, String fill,
      String depth, String edge, String shape, String scale, bool disabled) {
    final StringBuffer css = StringBuffer();

    if (scale == 'fluid' || scale == 'expanded') css.write('w-full ');
    if (family == 'input') css.write('min-w-0 ');
    if (family == 'action' && scale == 'compact') {
      css.write('px-10 py-6 text-sm ');
    }

    if (disabled) {
      css.write(
          'bg-slate-100 text-slate-400 border border-slate-200 cursor-not-allowed ');
    } else {
      switch (fill) {
        case 'solid':
          css.write('bg-$intent text-white ');
          break;
        case 'soft':
          css.write('bg-$intent-100 text-$intent-800 ');
          break;
        case 'ghost':
          css.write('bg-transparent text-$intent hover:bg-$intent-50 ');
          break;
        case 'bare':
          css.write('bg-transparent text-$intent ');
          break;
        case 'glass':
          css.write('bg-white/20 backdrop-blur-xl text-$intent ');
          break;
        case 'gradient':
          css.write(
              'bg-gradient-to-br from-$intent-400 to-$intent-700 text-white ');
          break;
        case 'surface':
        default:
          css.write('bg-white text-$intent ');
          break;
      }

      switch (depth) {
        case 'raised':
          css.write('shadow-sm ');
          break;
        case 'floating':
          css.write('shadow-lg ');
          break;
        case 'glow':
          css.write('shadow-lg shadow-$intent/30 ');
          break;
        case 'neon':
          css.write('shadow-lg shadow-$intent-400 border border-$intent-300 ');
          break;
        case 'neobrutal':
          css.write('border-2 border-black shadow-[4px_4px_0px_#000000] ');
          break;
      }

      if (depth != 'neobrutal' && depth != 'neon') {
        switch (edge) {
          case 'hairline':
            css.write('border border-$intent-200 ');
            break;
          case 'thick':
            css.write('border-2 border-$intent ');
            break;
          case 'dashed':
            css.write('border border-dashed border-$intent ');
            break;
        }
      }
    }

    switch (shape) {
      case 'sharp':
        css.write('rounded-none ');
        break;
      case 'pill':
        css.write('rounded-full ');
        break;
      case 'circle':
        css.write('rounded-full aspect-square flex-center p-0 ');
        break;
      case 'soft':
        css.write('rounded-3xl ');
        break;
      default:
        css.write('rounded-xl ');
        break;
    }

    if (family == 'action') {
      switch (scale) {
        case 'xs':
          css.write('px-8 py-4 text-xs ');
          break;
        case 'sm':
          css.write('px-12 py-6 text-sm ');
          break;
        case 'lg':
          css.write('px-24 py-16 text-lg font-bold ');
          break;
        case 'xl':
          css.write('px-32 py-20 text-xl font-bold tracking-wide ');
          break;
        case 'square':
          css.write('p-12 aspect-square flex-center ');
          break;
        default:
          if (scale != 'fluid') css.write('px-16 py-10 text-md ');
          break;
      }
    } else if (family != 'input') {
      switch (scale) {
        case 'xs':
          css.write('p-8 ');
          break;
        case 'sm':
          css.write('p-12 ');
          break;
        case 'lg':
          css.write('p-32 ');
          break;
        case 'bare':
          css.write('p-0 ');
          break;
        default:
          css.write('p-24 ');
          break;
      }
    }
    return css.toString().trim();
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  REGISTRATION & TOP-LEVEL CORE BUILDERS
// ────────────────────────────────────────────────────────────────────────────

abstract class QuantumCoreExporter {
  void export(QuantumVM vm);
}

const List<QuantumCoreExporter> _omniCoreExporters = [
  ActionCoreExporter(),
  AnimationCoreExporter(),
  BoxCoreExporter(),
  CanvasCoreExporter(),
  ChartCoreExporter(),
  CollabCoreExporter(),
  ConnectCoreExporter(),
  ControlCoreExporter(),
  DataCoreExporter(),
  DecorationCoreExporter(),
  FieldCoreExporter(),
  HookCoreExporter(),
  MediaCoreExporter(),
  PortalCoreExporter(),
  PresetCoreExporter(),
  StreamCoreExporter(),
  SystemCoreExporter(),
  TextCoreExporter(),
  VisualCoreExporter(),
];

void registerOmniComponents(QuantumVM vm) {
  // Execute all Core Exporters to define components and aliases.
  for (final exporter in _omniCoreExporters) {
    exporter.export(vm);
  }

  vm.registerJsonDslPlugins();

  // Core-folder defaults for file-based YAML/JSON registration.
  QLCoreFileRegistry.instance
    ..registerFolder('macros', 'macro')
    ..registerFolder('presets', 'preset')
    ..registerFolder('layouts', 'layout')
    ..registerFolder('actions', 'action')
    ..registerFolder('fields', 'field')
    ..registerFolder('text', 'text')
    ..registerFolder('media', 'media')
    ..registerFolder('visual', 'visual')
    ..registerFolder('hook', 'hook')
    ..registerFolder('data', 'data')
    ..registerFolder('portal', 'portal')
    ..registerFolder('control', 'control')
    ..registerFolder('canvas', 'canvas')
    ..registerFolder('system', 'system')
    ..registerFolder('decoration', 'decoration')
    ..registerFolder('chart', 'chart')
    ..registerFolder('animation', 'animation')
    ..registerFolder('stream', 'stream')
    ..registerFolder('collab', 'collab')
    ..registerFolder('box', 'box');

  _registerPowerFieldPresets(vm);
  _registerGeneralBuiltInPresets(vm);
  _registerRichDesignSystemPresets(vm);
  // NOTE: _registerRichSpatialLayouts was moved to QuantumVM.initialize().
  // All 8 matrix layout shells (workspace, page, app_shell, split_shell,
  // feed_shell, form_shell, modal_shell, timeline_shell) and all layout aliases
  // are now registered natively in quantum_vm_core/quantum_vm_layout.dart
  // before any external plugin runs. No action needed here.
}
