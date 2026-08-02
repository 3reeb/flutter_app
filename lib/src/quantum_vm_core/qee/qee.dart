/*
 * ============================================================================
 * File: qee.dart
 * 
 * Description:
 * The primary barrel export file for the Quantum Execution Engine (QEE). 
 * It provides a single import endpoint for all public APIs, models, registries, 
 * and utilities required to interact with the QEE.
 * 
 * Key Components:
 * - library qee: Aggregates exports for nodes, serializers, crypto, storage, 
 *   and widgets.
 * 
 * Dependencies/Relationships:
 * Exports all underlying qee_*.dart library files. Used by external application 
 * code to instantiate and interact with the engine.
 * 
 * Notes:
 * This file should remain purely declarative. Avoid adding logic here.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE — BARREL EXPORT
// qee.dart
//
// Single import for all QEE public APIs.
// ════════════════════════════════════════════════════════════════════════════

library qee;

// ── Node types (all public types) ────────────────────────────────────────────
export 'qee_node_types.dart'
    show
        QNodeKind,
        QNodeFlags,
        QNodeRef,
        QPageContext,
        QPageContextNotifier,
        QPageBody,
        QBaseNode,
        QPageNode,
        QLayoutNode,
        QMiddlewareNode,
        QMiddlewareStep,
        QMiddlewareOutcome,
        QMiddlewareResult,
        QMetaNode,
        QErrorNode,
        QLoadingNode,
        QNotFoundNode,
        QModuleNode,
        QModuleKind,
        QModulePolicy,
        QSliceConfig,
        QSliceField,
        QDataSourceConfig,
        QAppNode,
        QAppRouterConfig,
        QNodeStore,
        QEngineSnapshot,
        QCacheStats,
        QAccessDeniedException,
        QNodeNotFoundException,
        QNodeSealedException,
        QCircularRefException;

// ── Serializer (public for testing/debugging) ─────────────────────────────
export 'qee_serializer.dart'
    show
        QNodeEncoder,
        QNodeDecoder,
        QNodeIdGen,
        QSerial;

// ── Crypto engine ─────────────────────────────────────────────────────────
export 'qee_crypto.dart'
    show
        QCryptoEngine,
        QCryptoException,
        QCryptoTamperException,
        QCryptoKeyException,
        QHKDF;

// ── Disk store ────────────────────────────────────────────────────────────
// Abstract interface + QDiskIndex (platform-agnostic)
export 'qee_disk_store_stub.dart'
    show
        QDiskStore,
        QStubDiskStore;

// Platform-specific stores re-exported via qee_disk_store.dart's
// conditional import chain — use QDiskStore.create() to get the right one.
export 'qee_disk_store.dart'
    show
        QDiskIndex,
        QIndexEntry;

// ── Memory cache ──────────────────────────────────────────────────────────
export 'qee_memory_cache.dart'
    show
        QMemoryCache,
        QL1Cache,
        QL2Cache;

// ── Resolver ──────────────────────────────────────────────────────────────
export 'qee_resolver.dart'
    show
        QNodeResolver,
        QResolutionResult;

// ── Registry (primary public API) ────────────────────────────────────────
export 'qee_registry.dart'
    show
        QNodeRegistry,
        QEE,
        // Config DTOs
        QPageConfig,
        QLayoutConfig,
        QMiddlewareConfig,
        QMetaConfig,
        QErrorConfig,
        QLoadingConfig,
        QNotFoundConfig,
        QModuleConfig,
        QAppConfig;

// ── Layout host widgets ───────────────────────────────────────────────────
export 'qee_layout_host.dart'
    show
        QContextScope,
        QPropScope,
        QLayoutChain,
        QLayoutHost,
        QPageSlot,
        QLayoutBodyRenderer,
        QSlotProvider,
        QPageBodyRenderer,
        QErrorBoundary,
        QLoadingOverlay,
        QNotFoundView,
        QMiddlewareGate,
        QMetaApplicator,
        QMetaNotifier,
        QContextConsumer,
        QParamConsumer;

// ── File router bridge ───────────────────────────────────────────────────
export 'qee_file_router_bridge.dart'
    show
        QFileRouterBridge,
        QBridgeSyncResult,
        QLFileRouteEntryLite,
        QAppNodeBuilder;
