library quantum_domain;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import '../app/quantum_app_shell.dart';
import 'package:quantum_layout/quantum.dart';
import 'quantum_api_shell.dart';
export 'quantum_api_shell.dart';
typedef QuantumPayloadBuilder = Map<String, dynamic> Function(
    Map<String, dynamic> payload);

/// Production-ready bridge between the Quantum API shell and QuantumAppShell.
///
/// Install this domain in [QuantumAppConfig.domains] to expose the complete
/// [Quantum.runAction] and [Quantum.runStreamAction] surface to the VM action
/// pipeline.
QuantumDomain quantumApiShellDomain({
  String name = 'quantum_api_shell',
  QuantumConfig? initializeWith,
  bool initializeOnBoot = false,
  Map<String, dynamic> initialStoreData = const {},
}) {
  final actions = <String, QLActionPlugin>{
    'quantum.call': _QuantumRunAction(),
    'quantum.api': _QuantumRunAction(),
    'quantum.stream.start': _QuantumStreamStartAction(),
    'quantum.stream.cancel': _QuantumStreamCancelAction(),
    'quantum.stream.cancelAll': _QuantumStreamCancelAllAction(),
    'quantum.stream.in': _QuantumStreamInAction(),
    'quantum.stream.out': _QuantumStreamOutAction(),
    'quantum.auth': _QuantumDomainAction('auth'),
    'quantum.collection': _QuantumDomainAction('api_collection'),
    'quantum.global': _QuantumDomainAction('api_global'),
    'quantum.system': _QuantumDomainAction('api_system'),
    'quantum.media': _QuantumDomainAction('media'),
    'quantum.realtime': _QuantumDomainAction('realtime'),
    'quantum.task': _QuantumDomainAction('task'),
    'quantum.cache': _QuantumDomainAction('cache'),
    'quantum.crypto': _QuantumDomainAction('crypto'),
  };

  return QuantumDomain(
    name: name,
    sduiActions: actions,
    initialStoreData: initialStoreData,
    onInitialize: initializeOnBoot && initializeWith != null
        ? (_) => Quantum.initialize(initializeWith)
        : null,
  );
}

/// Adapter for [QuantumProductionRegistry] and any code expecting the light
/// [QuantumApiClient] interface from quantum_app_shell.dart.
class QuantumShellApiClient implements QuantumApiClient {
  final QuantumConfig? config;

  const QuantumShellApiClient({this.config});

  @override
  bool get isInitialized => Quantum.isInitialized;

  @override
  Future<void> init() async {
    if (Quantum.isInitialized) return;
    final cfg = config;
    if (cfg == null) {
      throw StateError(
          'QuantumShellApiClient requires a QuantumConfig before init().');
    }
    await Quantum.initialize(cfg);
  }

  @override
  Future<dynamic> executeRead({
    required String slug,
    required Map query,
    String? id,
  }) async {
    await init();
    final args = Map<String, dynamic>.from(query.cast<String, dynamic>());
    final action = (args.remove('op') ??
            args.remove('action') ??
            (id == null ? 'readMany' : 'readById'))
        .toString();
    if (id != null) args['id'] = id;

    return _unwrap(await Quantum.runAction({
      'domain': 'api_collection',
      'resource': slug,
      'action': action,
      'args': args,
    }));
  }

  @override
  Future<dynamic> executeWrite({
    required String slug,
    required String op,
    required Map body,
    String? id,
  }) async {
    await init();
    final action = _collectionWriteAction(op, id: id);
    final args = <String, dynamic>{'data': body.cast<String, dynamic>()};
    if (id != null) args['id'] = id;

    return _unwrap(await Quantum.runAction({
      'domain': 'api_collection',
      'resource': slug,
      'action': action,
      'args': args,
    }));
  }

  @override
  QuantumAuthClient auth() => _QuantumShellAuthClient(this);

  @override
  Future<dynamic> cacheGet(String key) async {
    await init();
    return _unwrap(await Quantum.runAction({
      'domain': 'cache',
      'action': 'get',
      'args': {'key': key},
    }));
  }

  @override
  Future<void> cacheSet(String key, dynamic value) async {
    await init();
    await _unwrap(await Quantum.runAction({
      'domain': 'cache',
      'action': 'set',
      'args': {'key': key, 'value': value},
    }));
  }

  @override
  Future<void> cacheRemove(String key) async {
    await init();
    await _unwrap(await Quantum.runAction({
      'domain': 'cache',
      'action': 'remove',
      'args': {'key': key},
    }));
  }
}

class _QuantumShellAuthClient implements QuantumAuthClient {
  final QuantumShellApiClient client;

  const _QuantumShellAuthClient(this.client);

  @override
  Future<dynamic> login(Map body) => _auth('login', body);

  @override
  Future<dynamic> register(Map body) => _auth('register', body);

  @override
  Future<dynamic> logout() => _auth('logout', const {});

  @override
  Future<dynamic> me() => _auth('me', const {});

  Future<dynamic> _auth(String action, Map body) async {
    await client.init();
    return _unwrap(await Quantum.runAction({
      'domain': 'auth',
      'action': action,
      'args': body.cast<String, dynamic>(),
    }));
  }
}

class QuantumStreamRegistry {
  static final Map<String, StreamSubscription<Map<String, dynamic>>>
      _subscriptions = {};

  const QuantumStreamRegistry._();

  static bool get hasActiveStreams => _subscriptions.isNotEmpty;
  static Iterable<String> get activeStreamIds => _subscriptions.keys;

  static Future<void> cancel(String streamId) async {
    await _subscriptions.remove(streamId)?.cancel();
  }

  static Future<void> cancelAll() async {
    final subs = _subscriptions.values.toList(growable: false);
    _subscriptions.clear();
    await Future.wait(subs.map((sub) => sub.cancel()));
  }

  static Future<void> replace(
    String streamId,
    Stream<Map<String, dynamic>> stream, {
    required QLDataStore store,
    required String eventKey,
    String? statusKey,
    String? errorKey,
    String? historyKey,
    int maxHistory = 100,
  }) async {
    await cancel(streamId);

    if (statusKey != null && statusKey.isNotEmpty) {
      store.set(statusKey, 'active');
    }

    _subscriptions[streamId] = stream.listen(
      (event) {
        store.set(eventKey, event);
        if (historyKey != null && historyKey.isNotEmpty) {
          final current = store.get(historyKey);
          final history =
              current is List ? List<dynamic>.from(current) : <dynamic>[];
          history.add(event);
          if (maxHistory > 0 && history.length > maxHistory) {
            history.removeRange(0, history.length - maxHistory);
          }
          store.set(historyKey, history);
        }
      },
      onError: (Object error, StackTrace stack) {
        final value = {'success': false, 'error': error.toString()};
        store.set(errorKey?.isNotEmpty == true ? errorKey! : eventKey, value);
        if (statusKey != null && statusKey.isNotEmpty) {
          store.set(statusKey, 'error');
        }
      },
      onDone: () {
        _subscriptions.remove(streamId);
        if (statusKey != null && statusKey.isNotEmpty) {
          store.set(statusKey, 'done');
        }
      },
      cancelOnError: false,
    );
  }
}

class _QuantumRunAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final request = _requestFromPayload(payload);
    final result = await Quantum.runAction(request);
    _storeResult(payload, store, result);
    if (payload['throwOnError'] == true && result['success'] != true) {
      throw StateError(result['error']?.toString() ?? 'Quantum action failed.');
    }
    return result;
  }
}

class _QuantumDomainAction extends QLActionPlugin {
  final String domain;
  _QuantumDomainAction(this.domain);

  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final request = _requestFromPayload(payload, defaultDomain: domain);
    final result = await Quantum.runAction(request);
    _storeResult(payload, store, result);
    if (payload['throwOnError'] == true && result['success'] != true) {
      throw StateError(result['error']?.toString() ?? 'Quantum action failed.');
    }
    return result;
  }
}

class _QuantumStreamStartAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final request = _requestFromPayload(payload);
    final streamId = (payload['streamId'] ??
            payload['taskId'] ??
            '${request['domain']}:${request['resource'] ?? ''}:${request['action']}')
        .toString();
    final eventKey = (payload['eventKey'] ??
            payload['resultKey'] ??
            'quantum.streams.$streamId.latest')
        .toString();

    await QuantumStreamRegistry.replace(
      streamId,
      Quantum.runStreamAction(request),
      store: store,
      eventKey: eventKey,
      statusKey: payload['statusKey']?.toString(),
      errorKey: payload['errorKey']?.toString(),
      historyKey: payload['historyKey']?.toString(),
      maxHistory: payload['maxHistory'] is int ? payload['maxHistory'] : 100,
    );

    final result = {
      'success': true,
      'streamId': streamId,
      'eventKey': eventKey
    };
    _storeResult(payload, store, result);
    return result;
  }
}

class _QuantumStreamCancelAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final streamId = (payload['streamId'] ?? payload['taskId'])?.toString();
    if (streamId == null || streamId.isEmpty) return false;
    await QuantumStreamRegistry.cancel(streamId);
    final result = {'success': true, 'streamId': streamId};
    _storeResult(payload, store, result);
    return result;
  }
}

class _QuantumStreamCancelAllAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    await QuantumStreamRegistry.cancelAll();
    const result = {'success': true};
    _storeResult(payload, store, result);
    return result;
  }
}

class _QuantumStreamInAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final request = _requestFromPayload(
      payload,
      defaultDomain: payload['domain']?.toString() ?? 'task',
      defaultAction: payload['action']?.toString() ?? 'live_pipeline_feed_mic',
    );
    _normalizeBinaryArgs(request);
    final result = await Quantum.runAction(request);
    _storeResult(payload, store, result);
    return result;
  }
}

class _QuantumStreamOutAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final action = payload['action']?.toString();
    final request = _requestFromPayload(
      payload,
      defaultDomain: payload['domain']?.toString() ?? 'realtime',
      defaultAction:
          action == null || action == 'stream_out' ? 'binary_out' : action,
    );
    _normalizeBinaryArgs(request);
    final result = await Quantum.runAction(request);
    _storeResult(payload, store, result);
    return result;
  }
}

Map<String, dynamic> _requestFromPayload(
  Map<String, dynamic> payload, {
  String? defaultDomain,
  String? defaultAction,
}) {
  final rawRequest = payload['request'];
  final request = rawRequest is Map
      ? Map<String, dynamic>.from(rawRequest)
      : Map<String, dynamic>.from(payload);

  request.remove('request');
  request.remove('resultKey');
  request.remove('eventKey');
  request.remove('historyKey');
  request.remove('statusKey');
  request.remove('errorKey');
  request.remove('streamId');
  request.remove('maxHistory');
  request.remove('throwOnError');

  final args = request['args'] is Map
      ? Map<String, dynamic>.from(request['args'] as Map)
      : <String, dynamic>{};

  for (final entry in payload.entries) {
    if (_reservedPayloadKeys.contains(entry.key)) continue;
    if (request.containsKey(entry.key)) continue;
    args[entry.key] = entry.value;
  }

  request['domain'] = (request['domain'] ?? defaultDomain)?.toString();
  request['action'] = (request['action'] ?? defaultAction)?.toString();
  if (request['domain'] == null || request['domain'].toString().isEmpty) {
    throw ArgumentError('Quantum action payload is missing "domain".');
  }
  if (request['action'] == null || request['action'].toString().isEmpty) {
    throw ArgumentError('Quantum action payload is missing "action".');
  }
  request['args'] = args;

  return request;
}

void _normalizeBinaryArgs(Map<String, dynamic> request) {
  final args = request['args'];
  if (args is! Map<String, dynamic>) return;
  for (final key in const ['bytes', 'data', 'payload']) {
    final value = args[key];
    if (value is Uint8List) continue;
    if (value is List<int>) args[key] = Uint8List.fromList(value);
    if (value is List) {
      args[key] = Uint8List.fromList(value.cast<int>());
    }
  }
}

void _storeResult(
    Map<String, dynamic> payload, QLDataStore store, dynamic result) {
  final resultKey = payload['resultKey']?.toString();
  if (resultKey != null && resultKey.isNotEmpty) {
    store.set(resultKey, result);
  }
}

dynamic _unwrap(Map<String, dynamic> result) {
  if (result['success'] == true) return result['data'];
  throw StateError(result['error']?.toString() ?? 'Quantum API call failed.');
}

String _collectionWriteAction(String op, {String? id}) {
  switch (op) {
    case 'create':
      return 'create';
    case 'createMany':
      return 'createMany';
    case 'update':
      return id == null ? 'updateMany' : 'updateById';
    case 'upsert':
      return id == null ? 'updateMany' : 'upsertById';
    case 'patch':
      return 'patchById';
    case 'delete':
      return id == null ? 'deleteMany' : 'deleteById';
    default:
      return op;
  }
}

const Set<String> _reservedPayloadKeys = {
  'request',
  'domain',
  'resource',
  'action',
  'args',
  'resultKey',
  'eventKey',
  'historyKey',
  'statusKey',
  'errorKey',
  'streamId',
  'maxHistory',
  'throwOnError',
};
