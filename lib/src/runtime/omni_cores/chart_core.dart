/*
 * ============================================================================
 * File: chart_core.dart
 * 
 * Description:
 * Provides high-level chart builder configurations for the Quantum Omni Registry, 
 * mapping abstract chart descriptors to explicit chart implementations.
 * 
 * Key Components:
 * - _buildChart: Router to initialize concrete chart implementations.
 * - _registerChartAliases: Registers dynamic aliases to chart types.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart.
 * 
 * Notes:
 * Supports multiple aliases mapped to backend chart components.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

Widget _buildChart(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String chartTypeName = ctx.string(
    'chartType',
    fallback: ctx.resolvedSubType(fallback: 'line'),
  );
  final QLChartType chartType = QLChartType.values.firstWhere(
    (e) => e.name == chartTypeName,
    orElse: () => QLChartType.line,
  );
  return buildChart(ctx, chartType);
}

void _registerChartAliases(QuantumVM vm) {
  vm.defineAlias('chart', 'chart',
      defaultProps: const <String, dynamic>{'chartType': 'line'},
      description: 'Base chart core.',
      tags: const ['chart', 'core']);

  for (final type in QLChartType.values) {
    final props = <String, dynamic>{'chartType': type.name};
    vm.defineAlias(type.name, 'chart',
        defaultProps: props,
        description: '${type.name} chart alias.',
        tags: const ['chart', 'alias']);
    vm.defineAlias('chart_${type.name}', 'chart',
        defaultProps: props,
        description: 'chart_${type.name} alias.',
        tags: const ['chart', 'alias']);
    vm.defineAlias('${type.name}_chart', 'chart',
        defaultProps: props,
        description: '${type.name}_chart alias.',
        tags: const ['chart', 'alias']);
    vm.defineAlias('media_${type.name}_chart', 'chart',
        defaultProps: props,
        description: 'media_${type.name}_chart compatibility alias.',
        tags: const ['chart', 'compat']);
  }

  vm.defineAlias('media:chart', 'chart',
      defaultProps: const <String, dynamic>{'chartType': 'line'},
      description: 'Backward-compatible media chart alias.',
      tags: const ['chart', 'compat']);
}

