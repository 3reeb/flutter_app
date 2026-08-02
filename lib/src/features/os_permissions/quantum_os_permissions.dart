/*
 * ============================================================================
 * File: quantum_os_permissions.dart
 * 
 * Description:
 * A sophisticated OS permission management engine designed for the Quantum 
 * framework. It standardizes permission capabilities, statuses, and complex 
 * request scenarios (including dependency chains) into a unified, event-driven 
 * API, decoupling the framework from direct platform plugin dependencies.
 * 
 * Key Components:
 * - PermissionResult: Immutable snapshot of a permission capability state.
 * - DefaultPermissionKernel: Core orchestrator utilizing a caching layer and audit store.
 * - DefaultPermissionPolicyEngine: Resolves dependency graphs and UI fallback strategies.
 * - PermissionDriverRegistry: Abstract driver model allowing hot-pluggable implementations.
 * 
 * Dependencies/Relationships:
 * Standalone architecture meant to be implemented per-platform via PermissionDriver 
 * interfaces.
 * 
 * Notes:
 * Enforces a strict separation of concerns, ensuring that permission checks do 
 * not accidentally trigger UI prompts without explicit orchestration.
 * ============================================================================
 */
library permission_engine;

import 'dart:async';

enum PermissionCapability {
  camera,
  microphone,
  photos,
  storage,
  contacts,
  calendar,
  locationForeground,
  locationBackground,
  bluetooth,
  notifications,
  biometrics,
  clipboard,
  sensors,
  networkState,
  overlay,
  backgroundExecution,
  fileAccess,
  mediaLibrary,
  speechRecognition,
  faceId,
  touchId,
  localNetwork,
  motion,
  tracking,
  unknown,
}

enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  limited,
  restricted,
  provisional,
  notSupported,
  unknown,
  pending,
}

enum PermissionDecisionType {
  allow,
  deny,
  defer,
  fallback,
  openSettings,
}

class PermissionResult {
  final PermissionCapability capability;
  final PermissionStatus status;
  final bool canAskAgain;
  final bool supported;
  final bool requiresSystemSettings;
  final String? reason;
  final String? platformHint;
  final DateTime timestamp;
  final Object? raw;

  PermissionResult({
    required this.capability,
    required this.status,
    required this.canAskAgain,
    required this.supported,
    required this.requiresSystemSettings,
    this.reason,
    this.platformHint,
    DateTime? timestamp,
    this.raw,
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool get isGranted => status == PermissionStatus.granted;
  bool get isDenied =>
      status == PermissionStatus.denied ||
      status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted;
  bool get isPermanentlyBlocked => status == PermissionStatus.permanentlyDenied;
  bool get isTerminal =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.notSupported ||
      status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted;

  PermissionResult copyWith({
    PermissionCapability? capability,
    PermissionStatus? status,
    bool? canAskAgain,
    bool? supported,
    bool? requiresSystemSettings,
    String? reason,
    String? platformHint,
    DateTime? timestamp,
    Object? raw,
  }) {
    return PermissionResult(
      capability: capability ?? this.capability,
      status: status ?? this.status,
      canAskAgain: canAskAgain ?? this.canAskAgain,
      supported: supported ?? this.supported,
      requiresSystemSettings:
          requiresSystemSettings ?? this.requiresSystemSettings,
      reason: reason ?? this.reason,
      platformHint: platformHint ?? this.platformHint,
      timestamp: timestamp ?? this.timestamp,
      raw: raw ?? this.raw,
    );
  }

  static PermissionResult granted(
    PermissionCapability capability, {
    String? reason,
    Object? raw,
  }) {
    return PermissionResult(
      capability: capability,
      status: PermissionStatus.granted,
      canAskAgain: false,
      supported: true,
      requiresSystemSettings: false,
      reason: reason,
      raw: raw,
      timestamp: DateTime.now().toUtc(),
    );
  }

  static PermissionResult denied(
    PermissionCapability capability, {
    bool canAskAgain = true,
    bool requiresSystemSettings = false,
    String? reason,
    Object? raw,
  }) {
    return PermissionResult(
      capability: capability,
      status: canAskAgain
          ? PermissionStatus.denied
          : PermissionStatus.permanentlyDenied,
      canAskAgain: canAskAgain,
      supported: true,
      requiresSystemSettings: requiresSystemSettings,
      reason: reason,
      raw: raw,
      timestamp: DateTime.now().toUtc(),
    );
  }

  static PermissionResult unsupported(
    PermissionCapability capability, {
    String? reason,
    Object? raw,
  }) {
    return PermissionResult(
      capability: capability,
      status: PermissionStatus.notSupported,
      canAskAgain: false,
      supported: false,
      requiresSystemSettings: false,
      reason: reason,
      raw: raw,
      timestamp: DateTime.now().toUtc(),
    );
  }

  static PermissionResult pending(
    PermissionCapability capability, {
    String? reason,
    Object? raw,
  }) {
    return PermissionResult(
      capability: capability,
      status: PermissionStatus.pending,
      canAskAgain: true,
      supported: true,
      requiresSystemSettings: false,
      reason: reason,
      raw: raw,
      timestamp: DateTime.now().toUtc(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'capability': capability.name,
      'status': status.name,
      'canAskAgain': canAskAgain,
      'supported': supported,
      'requiresSystemSettings': requiresSystemSettings,
      'reason': reason,
      'platformHint': platformHint,
      'timestamp': timestamp.toIso8601String(),
      'raw': raw,
    };
  }

  @override
  String toString() => toJson().toString();
}

enum PermissionEventType {
  check,
  request,
  result,
  revoked,
  changed,
  rationaleShown,
  settingsOpened,
  driverResolved,
  driverMissing,
  policyDenied,
  policyAllowed,
  cacheHit,
  cacheMiss,
  audit,
}

class PermissionEvent {
  final PermissionEventType type;
  final PermissionCapability capability;
  final PermissionStatus? status;
  final String message;
  final DateTime timestamp;
  final Map<String, Object?> details;

  PermissionEvent({
    required this.type,
    required this.capability,
    required this.message,
    DateTime? timestamp,
    this.status,
    this.details = const <String, Object?>{},
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory PermissionEvent.now({
    required PermissionEventType type,
    required PermissionCapability capability,
    required String message,
    PermissionStatus? status,
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    return PermissionEvent(
      type: type,
      capability: capability,
      message: message,
      status: status,
      details: details,
      timestamp: DateTime.now().toUtc(),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type.name,
        'capability': capability.name,
        'status': status?.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'details': details,
      };

  @override
  String toString() => toJson().toString();
}

class PermissionRequirement {
  final PermissionCapability capability;
  final bool required;
  final List<PermissionCapability> dependsOn;
  final String? rationale;
  final String? fallbackMessage;
  final bool openSettingsOnPermanentDenial;
  final bool retryable;

  const PermissionRequirement({
    required this.capability,
    this.required = true,
    this.dependsOn = const <PermissionCapability>[],
    this.rationale,
    this.fallbackMessage,
    this.openSettingsOnPermanentDenial = true,
    this.retryable = true,
  });
}

class PermissionScenario {
  final String id;
  final List<PermissionRequirement> requirements;
  final bool allowPartialSuccess;
  final bool strictOrdering;
  final Map<PermissionCapability, PermissionStatus>? expected;
  final Map<String, Object?> metadata;

  const PermissionScenario({
    required this.id,
    required this.requirements,
    this.allowPartialSuccess = false,
    this.strictOrdering = false,
    this.expected,
    this.metadata = const <String, Object?>{},
  });
}

class PermissionCheckRequest {
  final PermissionCapability capability;
  final bool includeDependencies;
  final bool forceRefresh;
  final String? rationale;
  final Map<String, Object?> metadata;

  const PermissionCheckRequest({
    required this.capability,
    this.includeDependencies = true,
    this.forceRefresh = false,
    this.rationale,
    this.metadata = const <String, Object?>{},
  });
}

class PermissionRequestRequest {
  final PermissionCapability capability;
  final bool includeDependencies;
  final bool forceRefresh;
  final bool showRationale;
  final String? rationale;
  final Map<String, Object?> metadata;

  const PermissionRequestRequest({
    required this.capability,
    this.includeDependencies = true,
    this.forceRefresh = false,
    this.showRationale = true,
    this.rationale,
    this.metadata = const <String, Object?>{},
  });
}

class PermissionPolicyDecision {
  final PermissionDecisionType type;
  final String reason;
  final bool shouldContinue;
  final bool requiresUserExplanation;

  const PermissionPolicyDecision({
    required this.type,
    required this.reason,
    required this.shouldContinue,
    required this.requiresUserExplanation,
  });

  factory PermissionPolicyDecision.allow([String reason = 'allowed']) {
    return PermissionPolicyDecision(
      type: PermissionDecisionType.allow,
      reason: reason,
      shouldContinue: true,
      requiresUserExplanation: false,
    );
  }

  factory PermissionPolicyDecision.deny([String reason = 'denied']) {
    return PermissionPolicyDecision(
      type: PermissionDecisionType.deny,
      reason: reason,
      shouldContinue: false,
      requiresUserExplanation: false,
    );
  }

  factory PermissionPolicyDecision.defer([String reason = 'deferred']) {
    return PermissionPolicyDecision(
      type: PermissionDecisionType.defer,
      reason: reason,
      shouldContinue: false,
      requiresUserExplanation: true,
    );
  }

  factory PermissionPolicyDecision.fallback([String reason = 'fallback']) {
    return PermissionPolicyDecision(
      type: PermissionDecisionType.fallback,
      reason: reason,
      shouldContinue: true,
      requiresUserExplanation: false,
    );
  }

  factory PermissionPolicyDecision.openSettings([
    String reason = 'open settings',
  ]) {
    return PermissionPolicyDecision(
      type: PermissionDecisionType.openSettings,
      reason: reason,
      shouldContinue: false,
      requiresUserExplanation: true,
    );
  }
}

class PermissionAuditEntry {
  final String id;
  final PermissionCapability capability;
  final PermissionEventType eventType;
  final PermissionStatus? status;
  final String message;
  final DateTime timestamp;
  final Map<String, Object?> details;

  const PermissionAuditEntry({
    required this.id,
    required this.capability,
    required this.eventType,
    required this.message,
    required this.timestamp,
    this.status,
    this.details = const <String, Object?>{},
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'capability': capability.name,
        'eventType': eventType.name,
        'status': status?.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'details': details,
      };
}

abstract class PermissionAuditStore {
  Future<void> write(PermissionAuditEntry entry);
  Future<List<PermissionAuditEntry>> readAll();
  Future<List<PermissionAuditEntry>> readForCapability(
    PermissionCapability capability,
  );
  Future<void> clear();
}

class InMemoryPermissionAuditStore implements PermissionAuditStore {
  final List<PermissionAuditEntry> _entries = <PermissionAuditEntry>[];

  @override
  Future<void> write(PermissionAuditEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<PermissionAuditEntry>> readAll() async {
    return List<PermissionAuditEntry>.unmodifiable(_entries);
  }

  @override
  Future<List<PermissionAuditEntry>> readForCapability(
    PermissionCapability capability,
  ) async {
    return List<PermissionAuditEntry>.unmodifiable(
      _entries.where((PermissionAuditEntry e) => e.capability == capability),
    );
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}

class PermissionCacheEntry {
  final PermissionResult result;
  final DateTime savedAt;
  final Duration ttl;

  const PermissionCacheEntry({
    required this.result,
    required this.savedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().toUtc().difference(savedAt) > ttl;
}

class PermissionCache {
  final Map<PermissionCapability, PermissionCacheEntry> _cache =
      <PermissionCapability, PermissionCacheEntry>{};

  void set(
    PermissionCapability capability,
    PermissionResult result, {
    Duration ttl = const Duration(seconds: 30),
  }) {
    _cache[capability] = PermissionCacheEntry(
      result: result,
      savedAt: DateTime.now().toUtc(),
      ttl: ttl,
    );
  }

  PermissionResult? get(PermissionCapability capability) {
    final PermissionCacheEntry? entry = _cache[capability];
    if (entry == null) {
      return null;
    }
    if (entry.isExpired) {
      _cache.remove(capability);
      return null;
    }
    return entry.result;
  }

  void invalidate(PermissionCapability capability) {
    _cache.remove(capability);
  }

  void clear() {
    _cache.clear();
  }

  Map<PermissionCapability, PermissionResult> snapshot() {
    final Map<PermissionCapability, PermissionResult> out =
        <PermissionCapability, PermissionResult>{};
    for (final MapEntry<PermissionCapability, PermissionCacheEntry> entry
        in _cache.entries) {
      if (!entry.value.isExpired) {
        out[entry.key] = entry.value.result;
      }
    }
    return out;
  }
}

abstract class PermissionDriver {
  String get id;
  int get priority => 0;

  bool supports(PermissionCapability capability);

  Future<PermissionResult> check(PermissionCheckRequest request);

  Future<PermissionResult> request(PermissionRequestRequest request);

  Future<bool> openSettings(PermissionCapability capability);

  Stream<PermissionEvent> watch(PermissionCapability capability);
}

class PermissionDriverRegistry {
  final List<PermissionDriver> _drivers = <PermissionDriver>[];

  void register(PermissionDriver driver) {
    _drivers.add(driver);
    _drivers.sort((PermissionDriver a, PermissionDriver b) {
      final int p = b.priority.compareTo(a.priority);
      if (p != 0) {
        return p;
      }
      return a.id.compareTo(b.id);
    });
  }

  void unregisterById(String id) {
    _drivers.removeWhere((PermissionDriver driver) => driver.id == id);
  }

  PermissionDriver? resolve(PermissionCapability capability) {
    for (final PermissionDriver driver in _drivers) {
      if (driver.supports(capability)) {
        return driver;
      }
    }
    return null;
  }

  List<PermissionDriver> get drivers =>
      List<PermissionDriver>.unmodifiable(_drivers);
}

typedef PermissionRationaleHandler = FutureOr<bool> Function(
  PermissionCapability capability,
  String? rationale,
);

typedef PermissionSettingsHandler = FutureOr<bool> Function(
  PermissionCapability capability,
);

typedef PermissionPolicyEvaluator = FutureOr<PermissionPolicyDecision> Function(
  PermissionCapability capability,
  PermissionStatus current,
  PermissionRequestRequest request,
);

class DefaultPermissionPolicyEngine {
  final Map<PermissionCapability, List<PermissionCapability>> dependencies;
  final PermissionRationaleHandler? rationaleHandler;
  final PermissionSettingsHandler? settingsHandler;
  final PermissionPolicyEvaluator? evaluator;

  const DefaultPermissionPolicyEngine({
    this.dependencies =
        const <PermissionCapability, List<PermissionCapability>>{},
    this.rationaleHandler,
    this.settingsHandler,
    this.evaluator,
  });

  List<PermissionCapability> expandDependencies(
    PermissionCapability capability,
  ) {
    final List<PermissionCapability> out = <PermissionCapability>[];
    final Set<PermissionCapability> visited = <PermissionCapability>{};

    void walk(PermissionCapability current) {
      final List<PermissionCapability>? deps = dependencies[current];
      if (deps == null) {
        return;
      }
      for (final PermissionCapability dep in deps) {
        if (visited.add(dep)) {
          out.add(dep);
          walk(dep);
        }
      }
    }

    walk(capability);
    return out;
  }

  Future<PermissionPolicyDecision> decide(
    PermissionCapability capability,
    PermissionStatus current,
    PermissionRequestRequest request,
  ) async {
    if (evaluator != null) {
      return await evaluator!(capability, current, request);
    }
    if (current == PermissionStatus.granted) {
      return PermissionPolicyDecision.allow('already granted');
    }
    if (current == PermissionStatus.notSupported) {
      return PermissionPolicyDecision.fallback('capability not supported');
    }
    if (current == PermissionStatus.permanentlyDenied) {
      return PermissionPolicyDecision.openSettings('permanently denied');
    }
    if (!request.showRationale) {
      return PermissionPolicyDecision.allow('skip rationale');
    }
    return PermissionPolicyDecision.defer('show rationale first');
  }

  Future<bool> showRationale(
    PermissionCapability capability,
    String? rationale,
  ) async {
    if (rationaleHandler == null) {
      return true;
    }
    return await rationaleHandler!(capability, rationale);
  }

  Future<bool> openSettings(PermissionCapability capability) async {
    if (settingsHandler == null) {
      return false;
    }
    return await settingsHandler!(capability);
  }
}

class PermissionRequestReport {
  final String requestId;
  final PermissionCapability capability;
  final PermissionResult result;
  final List<PermissionResult> dependencyResults;
  final List<PermissionAuditEntry> auditTrail;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration duration;

  const PermissionRequestReport({
    required this.requestId,
    required this.capability,
    required this.result,
    required this.dependencyResults,
    required this.auditTrail,
    required this.startedAt,
    required this.completedAt,
    required this.duration,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'requestId': requestId,
        'capability': capability.name,
        'result': result.toJson(),
        'dependencyResults':
            dependencyResults.map((PermissionResult e) => e.toJson()).toList(),
        'auditTrail':
            auditTrail.map((PermissionAuditEntry e) => e.toJson()).toList(),
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
      };
}

class PermissionEngineConfig {
  final Duration cacheTtl;
  final bool enableCache;
  final bool enableAudit;
  final bool enableEvents;
  final bool failFastOnMissingDriver;
  final Map<PermissionCapability, List<PermissionCapability>> dependencies;
  final Map<String, Object?> metadata;

  const PermissionEngineConfig({
    this.cacheTtl = const Duration(seconds: 30),
    this.enableCache = true,
    this.enableAudit = true,
    this.enableEvents = true,
    this.failFastOnMissingDriver = false,
    this.dependencies =
        const <PermissionCapability, List<PermissionCapability>>{},
    this.metadata = const <String, Object?>{},
  });
}

abstract class PermissionKernel {
  Stream<PermissionEvent> get events;

  Future<PermissionResult> check(PermissionCapability capability);
  Future<PermissionResult> request(PermissionCapability capability);
  Future<Map<PermissionCapability, PermissionResult>> checkMany(
    Iterable<PermissionCapability> capabilities,
  );
  Future<Map<PermissionCapability, PermissionResult>> requestMany(
    Iterable<PermissionCapability> capabilities,
  );
  Future<bool> openSystemSettings(PermissionCapability capability);
  Future<PermissionRequestReport> executeScenario(PermissionScenario scenario);
  bool supports(PermissionCapability capability);
  void invalidate(PermissionCapability capability);
  void clearCache();
  Future<List<PermissionAuditEntry>> auditTrailFor(
      PermissionCapability capability);
  Future<List<PermissionAuditEntry>> auditTrailAll();
}

class DefaultPermissionKernel implements PermissionKernel {
  final PermissionDriverRegistry registry;
  final DefaultPermissionPolicyEngine policy;
  final PermissionAuditStore auditStore;
  final PermissionEngineConfig config;
  final PermissionCache _cache = PermissionCache();
  final StreamController<PermissionEvent> _events =
      StreamController<PermissionEvent>.broadcast();
  final Map<PermissionCapability, Future<PermissionResult>> _inFlight =
      <PermissionCapability, Future<PermissionResult>>{};

  DefaultPermissionKernel({
    required this.registry,
    required this.policy,
    required this.auditStore,
    this.config = const PermissionEngineConfig(),
  });

  @override
  Stream<PermissionEvent> get events => _events.stream;

  void _emit(PermissionEvent event) {
    if (config.enableEvents && !_events.isClosed) {
      _events.add(event);
    }
    if (config.enableAudit) {
      auditStore.write(
        PermissionAuditEntry(
          id: _uuid(),
          capability: event.capability,
          eventType: event.type,
          status: event.status,
          message: event.message,
          timestamp: event.timestamp,
          details: event.details,
        ),
      );
    }
  }

  @override
  bool supports(PermissionCapability capability) {
    return registry.resolve(capability) != null;
  }

  @override
  Future<PermissionResult> check(PermissionCapability capability) async {
    final PermissionResult? cached =
        config.enableCache ? _cache.get(capability) : null;
    if (cached != null) {
      _emit(PermissionEvent.now(
        type: PermissionEventType.cacheHit,
        capability: capability,
        status: cached.status,
        message: 'cache hit',
      ));
      return cached;
    }

    _emit(PermissionEvent.now(
      type: PermissionEventType.check,
      capability: capability,
      message: 'checking permission',
    ));

    final PermissionDriver? driver = registry.resolve(capability);
    if (driver == null) {
      final PermissionResult result = PermissionResult.unsupported(
        capability,
        reason: 'no driver registered',
      );
      _emit(PermissionEvent.now(
        type: PermissionEventType.driverMissing,
        capability: capability,
        status: result.status,
        message: 'driver missing',
      ));
      if (config.failFastOnMissingDriver) {
        throw StateError(
            'No permission driver registered for ${capability.name}');
      }
      return result;
    }

    _emit(PermissionEvent.now(
      type: PermissionEventType.driverResolved,
      capability: capability,
      message: 'driver resolved: ${driver.id}',
    ));

    final PermissionCheckRequest request = PermissionCheckRequest(
      capability: capability,
      includeDependencies: true,
      forceRefresh: true,
    );
    final PermissionResult result = await driver.check(request);
    if (config.enableCache) {
      _cache.set(capability, result, ttl: config.cacheTtl);
    }
    _emit(PermissionEvent.now(
      type: PermissionEventType.result,
      capability: capability,
      status: result.status,
      message: 'check completed',
      details: <String, Object?>{'driver': driver.id, 'cached': false},
    ));
    return result;
  }

  @override
  Future<PermissionResult> request(PermissionCapability capability) async {
    final Future<PermissionResult>? existing = _inFlight[capability];
    if (existing != null) {
      return existing;
    }

    final Completer<PermissionResult> completer = Completer<PermissionResult>();
    _inFlight[capability] = completer.future;
    try {
      final PermissionResult result = await _requestInternal(
        capability,
        PermissionRequestRequest(capability: capability),
      );
      completer.complete(result);
      return result;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlight.remove(capability);
    }
  }

  Future<PermissionResult> _requestInternal(
    PermissionCapability capability,
    PermissionRequestRequest request,
  ) async {
    final PermissionDriver? driver = registry.resolve(capability);
    if (driver == null) {
      final PermissionResult result = PermissionResult.unsupported(
        capability,
        reason: 'no driver registered',
      );
      _emit(PermissionEvent.now(
        type: PermissionEventType.driverMissing,
        capability: capability,
        status: result.status,
        message: 'driver missing',
      ));
      if (config.failFastOnMissingDriver) {
        throw StateError(
            'No permission driver registered for ${capability.name}');
      }
      return result;
    }

    _emit(PermissionEvent.now(
      type: PermissionEventType.request,
      capability: capability,
      message: 'request started',
      details: <String, Object?>{'driver': driver.id},
    ));

    final List<PermissionResult> dependencyResults = <PermissionResult>[];
    final List<PermissionCapability> dependencies = request.includeDependencies
        ? policy.expandDependencies(capability)
        : const <PermissionCapability>[];
    for (final PermissionCapability dep in dependencies) {
      final PermissionResult depResult = await _requestInternal(
        dep,
        PermissionRequestRequest(
          capability: dep,
          includeDependencies: false,
          forceRefresh: request.forceRefresh,
          showRationale: request.showRationale,
          rationale: request.rationale,
          metadata: request.metadata,
        ),
      );
      dependencyResults.add(depResult);
      if (!depResult.isGranted && depResult.isTerminal) {
        final PermissionResult blocked = PermissionResult.denied(
          capability,
          canAskAgain: depResult.canAskAgain,
          requiresSystemSettings: depResult.requiresSystemSettings,
          reason: 'dependency ${dep.name} blocked request',
        );
        _emit(PermissionEvent.now(
          type: PermissionEventType.policyDenied,
          capability: capability,
          status: blocked.status,
          message: blocked.reason ?? 'dependency blocked',
        ));
        if (!request.forceRefresh) {
          if (config.enableCache) {
            _cache.set(capability, blocked, ttl: config.cacheTtl);
          }
          return blocked;
        }
      }
    }

    final PermissionResult current = await check(capability);
    final PermissionPolicyDecision decision =
        await policy.decide(capability, current.status, request);

    if (decision.type == PermissionDecisionType.openSettings) {
      _emit(PermissionEvent.now(
        type: PermissionEventType.policyDenied,
        capability: capability,
        status: current.status,
        message: decision.reason,
      ));
      if (request.rationale != null) {
        final bool rationaleOk =
            await policy.showRationale(capability, request.rationale);
        _emit(PermissionEvent.now(
          type: PermissionEventType.rationaleShown,
          capability: capability,
          status: current.status,
          message: rationaleOk ? 'rationale accepted' : 'rationale dismissed',
        ));
        if (!rationaleOk) {
          return current;
        }
      }
      final bool settingsOk = await driver.openSettings(capability);
      if (settingsOk) {
        _emit(PermissionEvent.now(
          type: PermissionEventType.settingsOpened,
          capability: capability,
          status: current.status,
          message: 'settings opened',
        ));
      }
      return current.copyWith(
        requiresSystemSettings: true,
        reason: decision.reason,
      );
    }

    if (decision.type == PermissionDecisionType.defer) {
      if (request.showRationale) {
        final bool rationaleOk =
            await policy.showRationale(capability, request.rationale);
        _emit(PermissionEvent.now(
          type: PermissionEventType.rationaleShown,
          capability: capability,
          status: current.status,
          message: rationaleOk ? 'rationale accepted' : 'rationale dismissed',
        ));
        if (!rationaleOk) {
          return current.copyWith(reason: 'user dismissed rationale');
        }
      }
    }

    if (current.isGranted && !request.forceRefresh) {
      if (config.enableCache) {
        _cache.set(capability, current, ttl: config.cacheTtl);
      }
      return current;
    }

    final PermissionRequestRequest actualRequest = PermissionRequestRequest(
      capability: capability,
      includeDependencies: false,
      forceRefresh: request.forceRefresh,
      showRationale: request.showRationale,
      rationale: request.rationale,
      metadata: request.metadata,
    );

    final PermissionResult result = await driver.request(actualRequest);
    if (config.enableCache) {
      _cache.set(capability, result, ttl: config.cacheTtl);
    }

    _emit(PermissionEvent.now(
      type: PermissionEventType.result,
      capability: capability,
      status: result.status,
      message: 'request completed',
      details: <String, Object?>{'driver': driver.id},
    ));

    return result;
  }

  @override
  Future<Map<PermissionCapability, PermissionResult>> checkMany(
    Iterable<PermissionCapability> capabilities,
  ) async {
    final Map<PermissionCapability, PermissionResult> out =
        <PermissionCapability, PermissionResult>{};
    for (final PermissionCapability capability in capabilities) {
      out[capability] = await check(capability);
    }
    return out;
  }

  @override
  Future<Map<PermissionCapability, PermissionResult>> requestMany(
    Iterable<PermissionCapability> capabilities,
  ) async {
    final Map<PermissionCapability, PermissionResult> out =
        <PermissionCapability, PermissionResult>{};
    for (final PermissionCapability capability in capabilities) {
      out[capability] = await request(capability);
    }
    return out;
  }

  @override
  Future<bool> openSystemSettings(PermissionCapability capability) async {
    final PermissionDriver? driver = registry.resolve(capability);
    if (driver == null) {
      return false;
    }
    final bool ok = await driver.openSettings(capability);
    if (ok) {
      _emit(PermissionEvent.now(
        type: PermissionEventType.settingsOpened,
        capability: capability,
        message: 'system settings opened',
      ));
    }
    return ok;
  }

  @override
  Future<PermissionRequestReport> executeScenario(
    PermissionScenario scenario,
  ) async {
    final DateTime started = DateTime.now().toUtc();
    final List<PermissionResult> dependencyResults = <PermissionResult>[];
    final List<PermissionAuditEntry> entries = <PermissionAuditEntry>[];

    PermissionResult lastResult = PermissionResult.unsupported(
      PermissionCapability.unknown,
      reason: 'scenario not started',
    );

    for (final PermissionRequirement requirement in scenario.requirements) {
      for (final PermissionCapability dep in requirement.dependsOn) {
        final PermissionResult depResult = await request(dep);
        dependencyResults.add(depResult);
      }

      final PermissionRequestRequest requestModel = PermissionRequestRequest(
        capability: requirement.capability,
        includeDependencies: false,
        showRationale: requirement.rationale != null,
        rationale: requirement.rationale,
        metadata: <String, Object?>{
          ...scenario.metadata,
          'scenarioId': scenario.id,
          'required': requirement.required,
        },
      );

      lastResult = await _requestInternal(requirement.capability, requestModel);

      if (config.enableAudit) {
        final List<PermissionAuditEntry> captured =
            await auditStore.readForCapability(requirement.capability);
        entries.addAll(captured);
      }

      if (requirement.required &&
          !lastResult.isGranted &&
          !scenario.allowPartialSuccess) {
        break;
      }
    }

    final DateTime completed = DateTime.now().toUtc();
    return PermissionRequestReport(
      requestId: _uuid(),
      capability: scenario.requirements.isEmpty
          ? PermissionCapability.unknown
          : scenario.requirements.last.capability,
      result: lastResult,
      dependencyResults: dependencyResults,
      auditTrail: entries,
      startedAt: started,
      completedAt: completed,
      duration: completed.difference(started),
    );
  }

  @override
  void invalidate(PermissionCapability capability) {
    _cache.invalidate(capability);
    _emit(PermissionEvent.now(
      type: PermissionEventType.changed,
      capability: capability,
      message: 'cache invalidated',
    ));
  }

  @override
  void clearCache() {
    _cache.clear();
  }

  @override
  Future<List<PermissionAuditEntry>> auditTrailFor(
    PermissionCapability capability,
  ) async {
    return await auditStore.readForCapability(capability);
  }

  @override
  Future<List<PermissionAuditEntry>> auditTrailAll() async {
    return await auditStore.readAll();
  }

  Future<void> dispose() async {
    await _events.close();
  }

  String _uuid() {
    final int t = DateTime.now().microsecondsSinceEpoch;
    final int r = Object.hashAll(
        <Object?>[t, _cache.snapshot().length, _inFlight.length]);
    return '$t-${r.abs()}';
  }
}

class StubPermissionDriver implements PermissionDriver {
  final String _id;
  final Set<PermissionCapability> supported;
  final Map<PermissionCapability, PermissionResult> states;
  final bool functionallyOpenSettings;

  StubPermissionDriver({
    required String id,
    required this.supported,
    Map<PermissionCapability, PermissionResult>? initialStates,
    this.functionallyOpenSettings = true,
  })  : _id = id,
        states = <PermissionCapability, PermissionResult>{
          if (initialStates != null) ...initialStates,
        };

  @override
  String get id => _id;

  @override
  int get priority => 0;
  @override
  bool supports(PermissionCapability capability) =>
      supported.contains(capability);

  @override
  Future<PermissionResult> check(PermissionCheckRequest request) async {
    final PermissionResult? result = states[request.capability];
    if (result != null) {
      return result;
    }
    return PermissionResult.denied(request.capability, canAskAgain: true);
  }

  @override
  Future<PermissionResult> request(PermissionRequestRequest request) async {
    final PermissionResult? current = states[request.capability];
    if (current != null && current.isGranted && !request.forceRefresh) {
      return current;
    }
    final PermissionResult result =
        PermissionResult.granted(request.capability);
    states[request.capability] = result;
    return result;
  }

  @override
  Future<bool> openSettings(PermissionCapability capability) async {
    return functionallyOpenSettings && supports(capability);
  }

  @override
  Stream<PermissionEvent> watch(PermissionCapability capability) async* {
    final PermissionResult? current = states[capability];
    yield PermissionEvent.now(
      type: PermissionEventType.changed,
      capability: capability,
      status: current?.status,
      message: 'watch snapshot',
    );
  }
}

class CompositePermissionDriver implements PermissionDriver {
  final String _id;
  final List<PermissionDriver> drivers;

  CompositePermissionDriver({
    required String id,
    required this.drivers,
  }) : _id = id;

  @override
  String get id => _id;

  @override
  int get priority => 1000;

  @override
  bool supports(PermissionCapability capability) {
    return drivers
        .any((PermissionDriver driver) => driver.supports(capability));
  }

  PermissionDriver? _resolve(PermissionCapability capability) {
    for (final PermissionDriver driver in drivers) {
      if (driver.supports(capability)) {
        return driver;
      }
    }
    return null;
  }

  @override
  Future<PermissionResult> check(PermissionCheckRequest request) async {
    final PermissionDriver? driver = _resolve(request.capability);
    if (driver == null) {
      return PermissionResult.unsupported(request.capability);
    }
    return driver.check(request);
  }

  @override
  Future<PermissionResult> request(PermissionRequestRequest request) async {
    final PermissionDriver? driver = _resolve(request.capability);
    if (driver == null) {
      return PermissionResult.unsupported(request.capability);
    }
    return driver.request(request);
  }

  @override
  Future<bool> openSettings(PermissionCapability capability) async {
    final PermissionDriver? driver = _resolve(capability);
    if (driver == null) {
      return false;
    }
    return driver.openSettings(capability);
  }

  @override
  Stream<PermissionEvent> watch(PermissionCapability capability) async* {
    final PermissionDriver? driver = _resolve(capability);
    if (driver == null) {
      yield PermissionEvent.now(
        type: PermissionEventType.driverMissing,
        capability: capability,
        message: 'no driver for watch',
      );
      return;
    }
    yield* driver.watch(capability);
  }
}

class PermissionSnapshot {
  final DateTime timestamp;
  final Map<PermissionCapability, PermissionResult> states;

  const PermissionSnapshot({
    required this.timestamp,
    required this.states,
  });

  PermissionResult? operator [](PermissionCapability capability) =>
      states[capability];

  Map<String, Object?> toJson() => <String, Object?>{
        'timestamp': timestamp.toIso8601String(),
        'states': states.map(
          (PermissionCapability key, PermissionResult value) =>
              MapEntry<String, Object?>(key.name, value.toJson()),
        ),
      };
}

class PermissionStateStore {
  final Map<PermissionCapability, PermissionResult> _states =
      <PermissionCapability, PermissionResult>{};

  PermissionResult? read(PermissionCapability capability) =>
      _states[capability];

  void write(PermissionCapability capability, PermissionResult result) {
    _states[capability] = result;
  }

  void writeMany(Map<PermissionCapability, PermissionResult> states) {
    _states.addAll(states);
  }

  PermissionSnapshot snapshot() {
    return PermissionSnapshot(
      timestamp: DateTime.now().toUtc(),
      states: Map<PermissionCapability, PermissionResult>.unmodifiable(_states),
    );
  }

  void clear() => _states.clear();
}

class PermissionDriverAdapter implements PermissionDriver {
  final String _id;
  final PermissionStateStore store;
  final Set<PermissionCapability> supported;
  final FutureOr<PermissionResult> Function(
      PermissionCapability capability, bool request)? requestHandler;
  final FutureOr<PermissionResult> Function(PermissionCapability capability)?
      checkHandler;
  final FutureOr<bool> Function(PermissionCapability capability)?
      settingsHandler;
  final Stream<PermissionEvent> Function(PermissionCapability capability)?
      watchHandler;

  PermissionDriverAdapter({
    required String id,
    required this.store,
    required this.supported,
    this.requestHandler,
    this.checkHandler,
    this.settingsHandler,
    this.watchHandler,
  }) : _id = id;

  @override
  String get id => _id;

  @override
  int get priority => 0;

  @override
  bool supports(PermissionCapability capability) =>
      supported.contains(capability);

  @override
  Future<PermissionResult> check(PermissionCheckRequest request) async {
    if (checkHandler != null) {
      final PermissionResult result = await checkHandler!(request.capability);
      store.write(request.capability, result);
      return result;
    }
    final PermissionResult? result = store.read(request.capability);
    return result ??
        PermissionResult.denied(request.capability, canAskAgain: true);
  }

  @override
  Future<PermissionResult> request(PermissionRequestRequest request) async {
    if (requestHandler != null) {
      final PermissionResult result =
          await requestHandler!(request.capability, true);
      store.write(request.capability, result);
      return result;
    }
    final PermissionResult granted =
        PermissionResult.granted(request.capability);
    store.write(request.capability, granted);
    return granted;
  }

  @override
  Future<bool> openSettings(PermissionCapability capability) async {
    if (settingsHandler != null) {
      return await settingsHandler!(capability);
    }
    return supports(capability);
  }

  @override
  Stream<PermissionEvent> watch(PermissionCapability capability) {
    if (watchHandler != null) {
      return watchHandler!(capability);
    }
    return Stream<PermissionEvent>.value(
      PermissionEvent.now(
        type: PermissionEventType.changed,
        capability: capability,
        message: 'adapter watch snapshot',
      ),
    );
  }
}

class PermissionEngineBuilder {
  final PermissionDriverRegistry registry = PermissionDriverRegistry();
  final Map<PermissionCapability, List<PermissionCapability>> dependencies =
      <PermissionCapability, List<PermissionCapability>>{};
  PermissionAuditStore auditStore = InMemoryPermissionAuditStore();
  PermissionCache cache = PermissionCache();
  Duration cacheTtl = const Duration(seconds: 30);
  bool enableCache = true;
  bool enableAudit = true;
  bool enableEvents = true;
  bool failFastOnMissingDriver = false;
  PermissionRationaleHandler? rationaleHandler;
  PermissionSettingsHandler? settingsHandler;
  PermissionPolicyEvaluator? evaluator;

  PermissionEngineBuilder registerDriver(PermissionDriver driver) {
    registry.register(driver);
    return this;
  }

  PermissionEngineBuilder addDependency(
    PermissionCapability capability,
    PermissionCapability dependsOn,
  ) {
    dependencies
        .putIfAbsent(capability, () => <PermissionCapability>[])
        .add(dependsOn);
    return this;
  }

  PermissionEngineBuilder setDependencies(
    Map<PermissionCapability, List<PermissionCapability>> map,
  ) {
    dependencies
      ..clear()
      ..addAll(map);
    return this;
  }

  PermissionEngineBuilder setAuditStore(PermissionAuditStore store) {
    auditStore = store;
    return this;
  }

  PermissionEngineBuilder setCacheTtl(Duration ttl) {
    cacheTtl = ttl;
    return this;
  }

  PermissionEngineBuilder setRationaleHandler(
      PermissionRationaleHandler handler) {
    rationaleHandler = handler;
    return this;
  }

  PermissionEngineBuilder setSettingsHandler(
      PermissionSettingsHandler handler) {
    settingsHandler = handler;
    return this;
  }

  PermissionEngineBuilder setEvaluator(PermissionPolicyEvaluator handler) {
    evaluator = handler;
    return this;
  }

  PermissionEngineBuilder withCache(bool value) {
    enableCache = value;
    return this;
  }

  PermissionEngineBuilder withAudit(bool value) {
    enableAudit = value;
    return this;
  }

  PermissionEngineBuilder withEvents(bool value) {
    enableEvents = value;
    return this;
  }

  PermissionEngineBuilder withFailFastOnMissingDriver(bool value) {
    failFastOnMissingDriver = value;
    return this;
  }

  DefaultPermissionKernel build() {
    final DefaultPermissionPolicyEngine policy = DefaultPermissionPolicyEngine(
      dependencies:
          Map<PermissionCapability, List<PermissionCapability>>.unmodifiable(
        dependencies.map(
          (PermissionCapability key, List<PermissionCapability> value) =>
              MapEntry<PermissionCapability, List<PermissionCapability>>(
            key,
            List<PermissionCapability>.unmodifiable(value),
          ),
        ),
      ),
      rationaleHandler: rationaleHandler,
      settingsHandler: settingsHandler,
      evaluator: evaluator,
    );

    return DefaultPermissionKernel(
      registry: registry,
      policy: policy,
      auditStore: auditStore,
      config: PermissionEngineConfig(
        cacheTtl: cacheTtl,
        enableCache: enableCache,
        enableAudit: enableAudit,
        enableEvents: enableEvents,
        failFastOnMissingDriver: failFastOnMissingDriver,
        dependencies:
            Map<PermissionCapability, List<PermissionCapability>>.unmodifiable(
          dependencies.map(
            (PermissionCapability key, List<PermissionCapability> value) =>
                MapEntry<PermissionCapability, List<PermissionCapability>>(
              key,
              List<PermissionCapability>.unmodifiable(value),
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionCliPrinter {
  static String formatResult(PermissionResult result) {
    return [
      'capability=${result.capability.name}',
      'status=${result.status.name}',
      'canAskAgain=${result.canAskAgain}',
      'supported=${result.supported}',
      'requiresSystemSettings=${result.requiresSystemSettings}',
      if (result.reason != null) 'reason=${result.reason}',
      if (result.platformHint != null) 'hint=${result.platformHint}',
      'timestamp=${result.timestamp.toIso8601String()}',
    ].join(' | ');
  }

  static String formatReport(PermissionRequestReport report) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('requestId=${report.requestId}')
      ..writeln('capability=${report.capability.name}')
      ..writeln('result=${formatResult(report.result)}')
      ..writeln('durationMs=${report.duration.inMilliseconds}');
    for (final PermissionResult dep in report.dependencyResults) {
      buffer.writeln('dependency=${formatResult(dep)}');
    }
    return buffer.toString();
  }
}

class PermissionEngineBootstrap {
  static DefaultPermissionKernel create({
    List<PermissionDriver> drivers = const <PermissionDriver>[],
    Map<PermissionCapability, List<PermissionCapability>> dependencies =
        const <PermissionCapability, List<PermissionCapability>>{},
    PermissionAuditStore? auditStore,
    PermissionRationaleHandler? rationaleHandler,
    PermissionSettingsHandler? settingsHandler,
    PermissionPolicyEvaluator? evaluator,
    bool enableCache = true,
    bool enableAudit = true,
    bool enableEvents = true,
    bool failFastOnMissingDriver = false,
    Duration cacheTtl = const Duration(seconds: 30),
  }) {
    final PermissionEngineBuilder builder = PermissionEngineBuilder()
        .withCache(enableCache)
        .withAudit(enableAudit)
        .withEvents(enableEvents)
        .withFailFastOnMissingDriver(failFastOnMissingDriver)
        .setCacheTtl(cacheTtl)
        .setDependencies(dependencies);

    if (auditStore != null) {
      builder.setAuditStore(auditStore);
    }
    if (rationaleHandler != null) {
      builder.setRationaleHandler(rationaleHandler);
    }
    if (settingsHandler != null) {
      builder.setSettingsHandler(settingsHandler);
    }
    if (evaluator != null) {
      builder.setEvaluator(evaluator);
    }

    for (final PermissionDriver driver in drivers) {
      builder.registerDriver(driver);
    }

    return builder.build();
  }
}
