// =============================================================================
// quantum_socket_engine.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../foundation/quantum_isolate_bridge.dart';
import 'internal/quantum_socket_stream_hub.dart';
import 'quantum_auth_engine.dart';

// =============================================================================
// CORE PRIMITIVES & THREADING
// =============================================================================

class VaultSocketException implements Exception {
  final String code;
  final String message;
  final Object? details;
  const VaultSocketException(this.code, this.message, {this.details});
  @override
  String toString() => 'VaultSocketException($code): $message';
}

// =============================================================================
// SOCKET MODELS & ENVELOPES
// =============================================================================

enum SocketState { disconnected, connecting, connected, reconnecting, error }

enum SocketDataType { text, json, binary }

enum SocketPattern { pubsub, rpc_request, rpc_response, stream_chunk, system }

class SocketMessage {
  final String id;
  final String channel;
  final String event;
  final dynamic payload;
  final SocketDataType dataType;
  final SocketPattern pattern;
  final int timestamp;
  final Map<String, dynamic> headers;

  const SocketMessage({
    required this.id,
    required this.channel,
    required this.event,
    this.payload,
    this.dataType = SocketDataType.json,
    this.pattern = SocketPattern.pubsub,
    required this.timestamp,
    this.headers = const {},
  });

  factory SocketMessage.create({
    required String channel,
    required String event,
    dynamic payload,
    SocketDataType dataType = SocketDataType.json,
    SocketPattern pattern = SocketPattern.pubsub,
    Map<String, dynamic> headers = const {},
  }) {
    return SocketMessage(
      id: _generateId(),
      channel: channel,
      event: event,
      payload: payload,
      dataType: dataType,
      pattern: pattern,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      headers: headers,
    );
  }

  static String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = math.Random.secure().nextInt(1000000);
    return '${now.toRadixString(36)}-$rnd';
  }

  Map<String, dynamic> toMap() => {
        'i': id,
        'c': channel,
        'e': event,
        'p': payload,
        'dt': dataType.index,
        'pt': pattern.index,
        'ts': timestamp,
        'h': headers,
      };

  factory SocketMessage.fromMap(Map<String, dynamic> map) {
    return SocketMessage(
      id: map['i'] as String,
      channel: map['c'] as String,
      event: map['e'] as String,
      payload: map['p'],
      dataType: SocketDataType.values[map['dt'] as int? ?? 1],
      pattern: SocketPattern.values[map['pt'] as int? ?? 0],
      timestamp: map['ts'] as int,
      headers: (map['h'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

// =============================================================================
// DRIVER ADAPTER PATTERN (Allows plugging in Native, Socket.IO, MQTT, etc.)
// =============================================================================

abstract class SocketDriver {
  String get driverId;
  Stream<SocketState> get onStateChanged;
  Stream<SocketMessage> get onMessage;
  Stream<Uint8List> get onRawBinary;

  Future<void> connect(String url, Map<String, dynamic> options);
  Future<void> disconnect();
  Future<void> send(SocketMessage message);
  Future<void> sendRawBinary(Uint8List data);
}

// =============================================================================
// NATIVE WEBSOCKET DRIVER IMPLEMENTATION
// =============================================================================

class NativeWebSocketDriver
    extends QLSocketDriverBase<SocketState, SocketMessage>
    implements SocketDriver {
  @override
  final String driverId = 'native_ws';

  WebSocket? _socket;

  @override
  Future<void> connect(String url, Map<String, dynamic> options) async {
    try {
      emitState(SocketState.connecting);

      final headers =
          (options['headers'] as Map?)?.cast<String, dynamic>() ?? {};
      _socket = await WebSocket.connect(url, headers: headers)
          .timeout(Duration(milliseconds: options['timeoutMs'] ?? 10000));

      emitState(SocketState.connected);

      _socket!.listen(
        (data) async {
          if (data is String) {
            try {
              final map = await QLIsolateBridge.safeRun(() => jsonDecode(data));
              emitMessage(SocketMessage.fromMap(map));
            } catch (_) {
              // Ignore malformed JSON envelopes
            }
          } else if (data is List<int>) {
            emitBinary(data is Uint8List ? data : Uint8List.fromList(data));
          }
        },
        onError: (err) {
          emitState(SocketState.error);
          disconnect();
        },
        onDone: () {
          emitState(SocketState.disconnected);
          disconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      emitState(SocketState.error);
      rethrow;
    }
  }

  @override
  Future<void> send(SocketMessage message) async {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      throw const VaultSocketException(
          'not_connected', 'Cannot send, socket is closed.');
    }
    final encoded =
        await QLIsolateBridge.safeRun(() => jsonEncode(message.toMap()));
    _socket!.add(encoded);
  }

  @override
  Future<void> sendRawBinary(Uint8List data) async {
    if (_socket == null || _socket!.readyState != WebSocket.open) return;
    _socket!.add(data);
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    emitState(SocketState.disconnected);
  }
}

// =============================================================================
// QUANTUM SOCKET ENGINE (THE SMART ORCHESTRATOR)
// =============================================================================

class QuantumSocketConfig {
  final String url;
  final Map<String, dynamic> headers;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final Duration pingInterval;
  final Duration rpcTimeout;
  final String? clientSecret; // Added for encryption

  const QuantumSocketConfig({
    required this.url,
    this.headers = const {},
    this.autoReconnect = true,
    this.maxReconnectAttempts = 50,
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.pingInterval = const Duration(seconds: 25),
    this.rpcTimeout = const Duration(seconds: 15),
    this.clientSecret,
  });
}

class QuantumSocketEngine {
  final SocketDriver _driver;
  QuantumSocketConfig _config;

  SocketState _currentState = SocketState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Handlers & Memory Maps
  final Map<String, Completer<SocketMessage>> _pendingRpc = {};
  final Map<String, Timer> _rpcTimeouts = {};
  final Map<String, StreamController<SocketMessage>> _channels = {};
  final StreamController<SocketState> _engineStateCtrl =
      StreamController.broadcast();
  final StreamController<SocketMessage> _firehoseCtrl =
      StreamController.broadcast();

  // Middleware Pipeline
  final List<FutureOr<SocketMessage> Function(SocketMessage)>
      _outboundMiddleware = [];
  final List<FutureOr<SocketMessage> Function(SocketMessage)>
      _inboundMiddleware = [];

  QuantumSocketEngine({
    SocketDriver? driver,
    required QuantumSocketConfig config,
  })  : _driver = driver ?? NativeWebSocketDriver(),
        _config = config {
    _initDriverListeners();
    _setupEncryption();
  }

  void _setupEncryption() {
    // FIX: Extract secret to a local variable to prevent Isolate from capturing `this`
    // and crashing on unsendable properties like _pingTimer
    final secret = _config.clientSecret;

    if (secret != null) {
      useOutbound((msg) async {
        if (msg.pattern == SocketPattern.system)
          return msg; // Don't encrypt ping/pong
        if (msg.payload == null) return msg;

        // Isolate local variables
        final rawPayload = msg.payload;

        final serialized =
            await QLIsolateBridge.safeRun(() => jsonEncode(rawPayload));
        final encrypted = await QLIsolateBridge.safeRun(() =>
            QuantumCipher.encryptInIsolate(
                {'plaintext': serialized, 'secret': secret}));

        return SocketMessage(
          id: msg.id,
          channel: msg.channel,
          event: msg.event,
          payload: {'_enc': true, 'data': encrypted},
          dataType: msg.dataType,
          pattern: msg.pattern,
          timestamp: msg.timestamp,
          headers: msg.headers,
        );
      });

      useInbound((msg) async {
        if (msg.pattern == SocketPattern.system) return msg;
        if (msg.payload is! Map || msg.payload['_enc'] != true) return msg;

        // Isolate local variables
        final rawEnvelope = msg.payload['data'] as String;

        try {
          final decryptedStr = await QLIsolateBridge.safeRun(() =>
              QuantumCipher.decryptInIsolate(
                  {'envelope': rawEnvelope, 'secret': secret}));
          final payload =
              await QLIsolateBridge.safeRun(() => jsonDecode(decryptedStr));

          return SocketMessage(
            id: msg.id,
            channel: msg.channel,
            event: msg.event,
            payload: payload,
            dataType: msg.dataType,
            pattern: msg.pattern,
            timestamp: msg.timestamp,
            headers: msg.headers,
          );
        } catch (e) {
          // If decryption fails, likely a tamper attempt or wrong key.
          throw const VaultSocketException(
              'cipher_tampered', 'Inbound message authentication failed.');
        }
      });
    }
  }

  SocketState get state => _currentState;
  Stream<SocketState> get onStateChanged => _engineStateCtrl.stream;
  Stream<SocketMessage> get onAnyMessage => _firehoseCtrl.stream;
  Stream<Uint8List> get onRawBinary => _driver.onRawBinary;

  // ─── PIPELINE HOOKS ────────────────────────────────────────────────────────

  void useOutbound(FutureOr<SocketMessage> Function(SocketMessage) middleware) {
    _outboundMiddleware.add(middleware);
  }

  void useInbound(FutureOr<SocketMessage> Function(SocketMessage) middleware) {
    _inboundMiddleware.add(middleware);
  }

  // ─── CONNECTION LIFECYCLE ──────────────────────────────────────────────────

  Future<void> connect() async {
    if (_currentState == SocketState.connected ||
        _currentState == SocketState.connecting) return;
    _reconnectAttempts = 0;
    await _attemptConnection();
  }

  Future<void> disconnect() async {
    _config = QuantumSocketConfig(
        url: _config.url, autoReconnect: false); // Disable auto-reconnect
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _clearPendingRpc();
    await _driver.disconnect();
    _updateState(SocketState.disconnected);
  }

  Future<void> updateConfig(QuantumSocketConfig newConfig) async {
    _config = newConfig;
    if (_currentState == SocketState.connected) {
      await disconnect();
      await connect();
    }
  }

  // ─── AUTO-RECOVERY & HEARTBEAT ─────────────────────────────────────────────

  Future<void> _attemptConnection() async {
    try {
      _updateState(SocketState.connecting);
      await _driver.connect(_config.url, {
        'headers': _config.headers,
        'timeoutMs': 10000,
      });
      _reconnectAttempts = 0;
      _updateState(SocketState.connected);
      _startHeartbeat();
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _updateState(SocketState.disconnected);
    _pingTimer?.cancel();
    _clearPendingRpc();

    if (_config.autoReconnect &&
        _reconnectAttempts < _config.maxReconnectAttempts) {
      _reconnectAttempts++;
      _updateState(SocketState.reconnecting);

      // Exponential backoff with Full Jitter (to prevent server stampedes)
      final exponentialDelay = math.pow(2, _reconnectAttempts) *
          _config.initialBackoff.inMilliseconds;
      final maxDelay = _config.maxBackoff.inMilliseconds;
      final delay = math.min(exponentialDelay, maxDelay).toInt();
      final jitter = math.Random().nextInt(delay ~/ 2 + 1);

      _reconnectTimer?.cancel();
      _reconnectTimer =
          Timer(Duration(milliseconds: delay + jitter), _attemptConnection);
    }
  }

  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_config.pingInterval, (timer) {
      if (_currentState == SocketState.connected) {
        // Fire-and-forget ping
        _sendProcessed(SocketMessage.create(
          channel: 'system',
          event: 'ping',
          pattern: SocketPattern.system,
        ));
      } else {
        timer.cancel();
      }
    });
  }

  void _initDriverListeners() {
    _driver.onStateChanged.listen((state) {
      if (state == SocketState.disconnected || state == SocketState.error) {
        _handleDisconnect();
      }
    });

    _driver.onMessage.listen((msg) async {
      // 1. Run Inbound Middleware (e.g., Decryption, validation)
      SocketMessage processed = msg;
      for (final mw in _inboundMiddleware) {
        processed = await mw(processed);
      }

      _firehoseCtrl.add(processed);

      // 2. Handle System Messages
      if (processed.pattern == SocketPattern.system) {
        if (processed.event == 'ping') {
          _sendProcessed(SocketMessage.create(
            channel: 'system',
            event: 'pong',
            pattern: SocketPattern.system,
          ));
        }
        return; // Consume system messages
      }

      // 3. Handle RPC Responses
      if (processed.pattern == SocketPattern.rpc_response) {
        final completer = _pendingRpc.remove(processed.id);
        final timer = _rpcTimeouts.remove(processed.id);
        timer?.cancel();
        if (completer != null && !completer.isCompleted) {
          completer.complete(processed);
        }
        return; // RPCs are uniquely consumed by their caller
      }

      // 4. Handle Pub/Sub & Channel Routing
      final chanCtrl = _channels[processed.channel];
      if (chanCtrl != null && chanCtrl.hasListener) {
        chanCtrl.add(processed);
      }
    });
  }

  // ─── PATTERN 1: PUB/SUB (FIRE & FORGET) ────────────────────────────────────

  /// Emits an event without waiting for a response. Ultra-fast.
  Future<void> emit(String channel, String event, dynamic payload) async {
    final msg = SocketMessage.create(
      channel: channel,
      event: event,
      payload: payload,
      pattern: SocketPattern.pubsub,
    );
    await _sendProcessed(msg);
  }

  // ─── PATTERN 2: RPC (REQUEST / RESPONSE) ───────────────────────────────────

  /// Sends a request and waits for exactly one response matched by ID.
  /// Throws if timeout occurs. No memory leaks.
  Future<SocketMessage> request(String channel, String event, dynamic payload,
      {Duration? timeout}) async {
    if (_currentState != SocketState.connected) {
      throw const VaultSocketException(
          'not_connected', 'Cannot execute RPC while disconnected.');
    }

    final msg = SocketMessage.create(
      channel: channel,
      event: event,
      payload: payload,
      pattern: SocketPattern.rpc_request,
    );

    final completer = Completer<SocketMessage>();
    _pendingRpc[msg.id] = completer;

    final actualTimeout = timeout ?? _config.rpcTimeout;

    _rpcTimeouts[msg.id] = Timer(actualTimeout, () {
      _pendingRpc.remove(msg.id);
      _rpcTimeouts.remove(msg.id);
      if (!completer.isCompleted) {
        completer.completeError(VaultSocketException(
            'rpc_timeout', 'RPC request ${msg.id} timed out.'));
      }
    });

    await _sendProcessed(msg);
    return completer.future;
  }

  // ─── PATTERN 3: CHANNEL STREAMING ──────────────────────────────────────────

  /// Subscribes to a specific topic/channel.
  /// Auto-cleans up the stream controller when the user stops listening to prevent leaks.
  Stream<SocketMessage> subscribe(String channel) {
    if (!_channels.containsKey(channel)) {
      // Create a broadcast controller with an onCancel hook to clean up memory
      late StreamController<SocketMessage> ctrl;
      ctrl = StreamController<SocketMessage>.broadcast(
        onListen: () {
          // Tell the server we want to join this room
          emit('system', 'subscribe', {'channel': channel});
        },
        onCancel: () {
          if (!ctrl.hasListener) {
            _channels.remove(channel);
            ctrl.close();
            // Tell the server we are leaving
            if (_currentState == SocketState.connected) {
              emit('system', 'unsubscribe', {'channel': channel});
            }
          }
        },
      );
      _channels[channel] = ctrl;
    }
    return _channels[channel]!.stream;
  }

  // ─── PATTERN 4: HIGH-THROUGHPUT RAW BINARY ─────────────────────────────────

  /// Bypasses all JSON serialization and middleware.
  /// Use this for Live Video/Audio byte arrays.
  Future<void> sendBinary(Uint8List data) async {
    await _driver.sendRawBinary(data);
  }

  // ─── INTERNAL HELPERS ──────────────────────────────────────────────────────

  Future<void> _sendProcessed(SocketMessage message) async {
    if (_currentState != SocketState.connected) {
      throw const VaultSocketException(
          'not_connected', 'Cannot send, socket offline.');
    }
    SocketMessage processed = message;
    for (final mw in _outboundMiddleware) {
      processed = await mw(processed);
    }
    await _driver.send(processed);
  }

  void _clearPendingRpc() {
    for (final timer in _rpcTimeouts.values) {
      timer.cancel();
    }
    _rpcTimeouts.clear();

    for (final completer in _pendingRpc.values) {
      if (!completer.isCompleted) {
        completer.completeError(const VaultSocketException(
            'socket_disconnected', 'RPC aborted due to disconnect.'));
      }
    }
    _pendingRpc.clear();
  }

  void _updateState(SocketState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _engineStateCtrl.add(newState);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _engineStateCtrl.close();
    await _firehoseCtrl.close();
    for (var ctrl in _channels.values) {
      await ctrl.close();
    }
    _channels.clear();
  }
}
