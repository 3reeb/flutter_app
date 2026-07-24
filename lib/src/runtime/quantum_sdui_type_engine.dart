// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SDUI TYPE ENGINE — schema export + TypeScript bundle generator
// quantum_sdui_type_engine.dart
//
// Exports a live, strongly typed SDUI snapshot from the runtime registry.
// The TS consumer can turn the exported bundle into an end-to-end typed engine.
//
// Exported sections:
//   • registry       — all registered items (actions, aliases, pipes, macros…)
//   • coreSchemas    — schema descriptors + alias/file maps
//   • coreFiles      — file-backed core file descriptors
//   • designSystems  — installed QuantumDesignSystemBundle entries
//   • themeConfig    — merged token table + design-system IDs
//   • omniCores      — DYNAMIC: all VM-registered cores + q_omni_manifold etc.
//   • dslOperators   — all $-prefixed compile-time DSL operators
//   • aliasRegistry  — raw alias → targetType/defaultProps map
//   • summary        — live counts of every section
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'quantum_core_schema_registry.dart';
import '../../quantum.dart';

@immutable
class QuantumSduiTypeBundle {
  final Map<String, dynamic> snapshot;
  final String json;
  final String typescript;

  const QuantumSduiTypeBundle({
    required this.snapshot,
    required this.json,
    required this.typescript,
  });
}

final class QuantumSduiTypeEngine {
  QuantumSduiTypeEngine._();

  // ─── Core snapshot builder ───────────────────────────────────────────────

  static Map<String, dynamic> exportSnapshot({
    String? kind,
    String? query,
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
    bool includeOrchestrator = true,
  }) {
    final vm = QuantumVM.instance;

    // ── 1. Registry (actions, aliases, pipes, macros, templates, …) ─────────
    final registry = includeRegistry
        ? vm.registrySnapshot(kind: kind, query: query)
        : const <String, dynamic>{};

    // ── 2. Core schema descriptors (yaml/json file-backed + inline) ──────────
    final core = includeCoreSchemas
        ? QuantumCoreSchemaRegistry.instance.snapshot()
        : const <String, dynamic>{
            'schemas': <String, dynamic>{},
            'aliases': <String, String>{},
            'schemaFiles': <String, String>{},
            'aliasFiles': <String, String>{},
          };

    // ── 3. File registry (built-in YAML/JSON definitions) ───────────────────
    final files = QLCoreFileRegistry.instance.snapshot();

    // ── 4. Design Systems ────────────────────────────────────────────────────
    final designSystems = includeDesignSystems
        ? vm.designSystemsExportSnapshot()
        : const <String, dynamic>{};

    // ── 5. Theme Config (merged tokens from all design systems) ──────────────
    final themeConfig = includeDesignSystems
        ? vm.themeConfigSnapshot()
        : const <String, dynamic>{};

    // ── 6. OmniCores (dynamic — includes q_omni_manifold + any future cores) ─
    final omniCores = includeOmniCores
        ? vm.omniCoresSnapshot()
        : const <String, dynamic>{};

    // ── 7. DSL Operators ($let, $define, $if, …) ────────────────────────────
    final dslOperators = includeDslOperators
        ? vm.dslOperatorsSnapshot()
        : const <List<Map<String, String>>>[];

    // ── 8. Alias Registry (raw alias → targetType/defaultProps) ─────────────
    final aliasRegistry = includeAliasRegistry
        ? vm.aliasRegistrySnapshot()
        : const <String, dynamic>{};

    // ── 9. Orchestrator usage (modules, pipelines, stores, slices) ──────────
    final orchestrator = includeOrchestrator
        ? QuantumDataOrchestrator.snapshot()
        : const <String, dynamic>{};

    return <String, dynamic>{
      'registry': registry,
      'coreSchemas': <String, dynamic>{
        'schemas': core['schemas'],
        'aliases': core['aliases'],
        'schemaFiles': core['schemaFiles'],
        'aliasFiles': core['aliasFiles'],
      },
      'coreFiles': <String, dynamic>{
        'items': files['items'],
      },
      'designSystems': designSystems,
      'themeConfig': themeConfig,
      'omniCores': omniCores,
      'dslOperators': dslOperators,
      'aliasRegistry': aliasRegistry,
      'orchestrator': orchestrator,
    };
  }

  // ─── JSON exporter ────────────────────────────────────────────────────────

  static String exportJson({
    String? kind,
    String? query,
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
    bool includeOrchestrator = true,
  }) =>
      const JsonEncoder.withIndent('  ').convert(exportSnapshot(
        kind: kind,
        query: query,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
        includeOrchestrator: includeOrchestrator,
      ));

  // ─── TypeScript bundle generator ─────────────────────────────────────────

  /// Generate a TS bundle file that imports the shared type engine and embeds
  /// the current snapshot `as const`. The bundle also exports a typed DSL
  /// helpers object via `createQuantumDslHelpers`.
  static String exportTypeScriptBundle({
    String? kind,
    String? query,
    String bundleName = 'quantumSduiBundle',
    String engineImportPath = './quantum_sdui_type_engine',
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
    bool includeOrchestrator = true,
  }) {
    final snapshot = exportSnapshot(
      kind: kind,
      query: query,
      includeRegistry: includeRegistry,
      includeCoreSchemas: includeCoreSchemas,
      includeDesignSystems: includeDesignSystems,
      includeOmniCores: includeOmniCores,
      includeDslOperators: includeDslOperators,
      includeAliasRegistry: includeAliasRegistry,
      includeOrchestrator: includeOrchestrator,
    );
    final json = const JsonEncoder.withIndent('  ').convert(snapshot);
    return '''
// AUTO-GENERATED BY QuantumSduiTypeEngine v2.0
// Re-export this file whenever schema, registry, or design-system metadata changes.

import {
  createQuantumSduiTypeEngine,
  defineQuantumSduiBundle,
  createQuantumDslHelpers,
} from '$engineImportPath';

export const $bundleName = defineQuantumSduiBundle($json as const);
export const quantumSdui = createQuantumSduiTypeEngine($bundleName);
export const q = createQuantumDslHelpers($bundleName);

export type QuantumSduiBundle = typeof $bundleName;
export type QuantumSduiEngine = typeof quantumSdui;
export type QuantumDslHelpers = typeof q;
''';
  }

  // ─── Bundle package (JSON + TS) ───────────────────────────────────────────

  static QuantumSduiTypeBundle exportBundle({
    String? kind,
    String? query,
    String bundleName = 'quantumSduiBundle',
    String engineImportPath = './quantum_sdui_type_engine',
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
    bool includeOrchestrator = true,
  }) {
    final snapshot = exportSnapshot(
      kind: kind,
      query: query,
      includeRegistry: includeRegistry,
      includeCoreSchemas: includeCoreSchemas,
      includeDesignSystems: includeDesignSystems,
      includeOmniCores: includeOmniCores,
      includeDslOperators: includeDslOperators,
      includeAliasRegistry: includeAliasRegistry,
      includeOrchestrator: includeOrchestrator,
    );
    return QuantumSduiTypeBundle(
      snapshot: snapshot,
      json: const JsonEncoder.withIndent('  ').convert(snapshot),
      typescript: exportTypeScriptBundle(
        kind: kind,
        query: query,
        bundleName: bundleName,
        engineImportPath: engineImportPath,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
        includeOrchestrator: includeOrchestrator,
      ),
    );
  }
}
