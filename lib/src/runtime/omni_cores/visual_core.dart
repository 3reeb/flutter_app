/*
 * ============================================================================
 * File: visual_core.dart
 * 
 * Description:
 * Aggregates top-level visual composition layers for the Quantum Omni Registry. 
 * Handles structural repainting boundaries, scene routing, and high-level 
 * structural aggregations like abstract 'surface' and 'shell' delegates.
 * 
 * Key Components:
 * - _buildVisual: Central dispatcher for abstract node types (scene, canvas, surface).
 * - RepaintBoundary wrappers: Manages explicit Flutter layout boundaries.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart.
 * 
 * Notes:
 * Used heavily by the QPresetEngine to resolve semantic layout slots into Flutter trees.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

QLBlueprint _visualCloneAs(
  QLBlueprint source,
  String type, {
  Map<String, dynamic>? props,
  String? path,
}) {
  final Map<String, dynamic> json = source.toJson();
  json['type'] = type;
  final Map<String, dynamic> merged =
      Map<String, dynamic>.from(json['props'] as Map? ?? const {});
  if (props != null && props.isNotEmpty) merged.addAll(props);
  if (props == null || !props.containsKey('__subType')) {
    merged.remove('__subType');
  }
  json['props'] = merged;
  if (path != null) json['debugPath'] = path;
  return QLBlueprint.fromJson(json, path: path ?? source.debugPath);
}

Widget _buildVisual(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'surface');

  final Widget content = ctx.slot('content') ??
      ctx.slot('child') ??
      (ctx.children.isEmpty
          ? const SizedBox.shrink()
          : Q('col min-w-0 min-h-0', children: ctx.children));

  if (subType == 'chart') {
    final String chartTypeName = ctx.string('chartType', fallback: 'line');
    final QLContext chartCtx = QLContext(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'chart',
        props: <String, dynamic>{
          'chartType': chartTypeName,
          '__subType': chartTypeName,
        },
      ),
      ctx.env,
      ctx.store,
    );
    final QLChartType chartType = QLChartType.values.firstWhere(
      (e) => e.name == chartTypeName,
      orElse: () => QLChartType.line,
    );
    return buildChart(chartCtx, chartType);
  }

  if (subType == 'animation') {
    final String animationType =
        ctx.string('animationType', fallback: 'signal');
    final QLContext animationCtx = QLContext(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'animation',
        props: <String, dynamic>{
          'animationType': animationType,
          '__subType': animationType,
        },
      ),
      ctx.env,
      ctx.store,
    );
    return _buildAnimation(animationCtx);
  }

  if (subType == 'canvas') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'canvas',
        props: <String, dynamic>{
          if (ctx.node.props['canvasType'] != null)
            'canvasType': ctx.node.props['canvasType'],
        },
      ),
    );
  }

  if (subType == 'portal') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'portal',
        props: <String, dynamic>{
          if (ctx.node.props['portalType'] != null)
            'portalType': ctx.node.props['portalType'],
        },
      ),
    );
  }

  if (subType == 'connect') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'connect',
        props: <String, dynamic>{
          if (ctx.node.props['connectType'] != null)
            'connectType': ctx.node.props['connectType'],
        },
      ),
    );
  }

  if (subType == 'field') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'field',
        props: <String, dynamic>{
          '__subType': ctx.string('fieldType', fallback: 'text'),
        },
      ),
    );
  }

  if (subType == 'box') {
    final String boxType = ctx.string('boxType', fallback: 'col');
    final QLContext boxCtx = QLContext(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'box',
        props: <String, dynamic>{
          '__subType': boxType,
        },
      ),
      ctx.env,
      ctx.store,
    );
    return _buildBox(boxCtx);
  }

  if (subType == 'media') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'media',
        props: <String, dynamic>{
          '__subType': ctx.string('mediaType', fallback: 'image'),
        },
      ),
    );
  }

  if (subType == 'system') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'system',
        props: <String, dynamic>{
          '__subType': ctx.string('systemType', fallback: 'scope'),
        },
      ),
    );
  }

  if (subType == 'template') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(
        ctx.node,
        'template',
        props: <String, dynamic>{
          if (ctx.node.props['templateName'] != null)
            '__subType': ctx.node.props['templateName'],
        },
      ),
    );
  }

  if (subType == 'action' ||
      subType == 'control' ||
      subType == 'data' ||
      subType == 'layout' ||
      subType == 'decoration' ||
      subType == 'text') {
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(ctx.node, subType),
    );
  }

  if (subType == 'delegate') {
    final String target = ctx.string('target');
    if (target.isEmpty) return content;
    final Map<String, dynamic> delegateProps =
        Map<String, dynamic>.from(ctx.map('delegateProps'));
    return QuantumVM.instance.renderWidget(
      ctx.flutterContext,
      _visualCloneAs(ctx.node, target, props: delegateProps),
    );
  }

  if (subType == 'scene') {
    return RepaintBoundary(
      child: QLSceneLayerWidget(
        isComplex: ctx.boolean('isComplex', fallback: true),
        willChange: ctx.boolean('willChange', fallback: true),
        builder: (context, layer) => Stack(
          fit: StackFit.expand,
          children: ctx.children.isEmpty ? <Widget>[content] : ctx.children,
        ),
      ),
    );
  }

  if (subType == 'stack') {
    return Stack(
      fit: StackFit.expand,
      clipBehavior:
          ctx.boolean('clip', fallback: false) ? Clip.hardEdge : Clip.none,
      children: ctx.children.isEmpty ? <Widget>[content] : ctx.children,
    );
  }

  if (subType == 'overlay') {
    final Widget? overlay = ctx.slot('overlay');
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(child: content),
        if (overlay != null) Positioned.fill(child: overlay),
      ],
    );
  }

  if (subType == 'shell' || subType == 'surface') {
    final Widget? header = ctx.slot('header');
    final Widget? body = ctx.slot('body');
    final Widget? footer = ctx.slot('footer');
    final Widget? chrome = ctx.slot('chrome');
    final Widget? overlay = ctx.slot('overlay');

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (header != null) header,
          Expanded(child: body ?? content),
          if (footer != null) footer,
          if (chrome != null) chrome,
          if (overlay != null) overlay,
        ],
      ),
    );
  }

  if (subType == 'layer') {
    return RepaintBoundary(child: content);
  }

  if (subType == 'compose') {
    return Q(
      ctx.string('layout', fallback: 'col min-w-0 min-h-0'),
      children: ctx.children.isEmpty ? <Widget>[content] : ctx.children,
    );
  }

  return RepaintBoundary(child: content);
}

final QuantumDomain visualDomain = quantumDomain('visual')
    .surface('visual', _buildVisual, defaultSurface: true)
    .install((vm) {
      vm.defineAlias(
        'visual_surface',
        'visual:surface',
        description: 'Visual surface alias.',
        tags: const ['visual', 'alias'],
      );
      vm.defineAlias(
        'visual_shell',
        'visual:shell',
        description: 'Visual shell alias.',
        tags: const ['visual', 'alias'],
      );
      vm.defineAlias(
        'visual_scene',
        'visual:scene',
        description: 'Visual scene alias.',
        tags: const ['visual', 'alias'],
      );
      vm.defineAlias(
        'visual_overlay',
        'visual:overlay',
        description: 'Visual overlay alias.',
        tags: const ['visual', 'alias'],
      );
      vm.defineAlias(
        'visual_delegate',
        'visual:delegate',
        description: 'Visual delegation alias.',
        tags: const ['visual', 'alias'],
      );
    })
    .build();

class VisualCoreExporter implements QuantumCoreExporter {
  const VisualCoreExporter();

  @override
  void export(QuantumVM vm) {
    vm.installDomain(visualDomain);
  }
}

