// =============================================================================
// realtime.dart — WebSocket/realtime streaming.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'session.dart';

// ---------------------------------------------------------------------------
// RealtimeEvent
// ---------------------------------------------------------------------------

class RealtimeEvent {
  final String type;
  final dynamic data;
  final Map<String, dynamic> meta;

  const RealtimeEvent({required this.type, this.data, this.meta = const {}});

  factory RealtimeEvent.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    return RealtimeEvent(
      type: map['type']?.toString() ?? 'message',
      data: map['data'],
      meta: Map<String, dynamic>.from(map['meta'] ?? const {}),
    );
  }
}

// ---------------------------------------------------------------------------
// SocketConnection (abstract)
// ---------------------------------------------------------------------------

abstract class SocketConnection {
  Stream<dynamic> get messages;
  Future<void> send(dynamic data);
  Future<void> close([int? code, String? reason]);
}

// ---------------------------------------------------------------------------
// RealtimeClient
// ---------------------------------------------------------------------------

class RealtimeClient {
  final Uri socketUrl;
  final AuthProvider? authProvider;
  final SocketConnection Function(Uri uri)? socketTransport;

  SocketConnection? _connection;
  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  RealtimeClient({
    required this.socketUrl,
    this.authProvider,
    this.socketTransport,
  });

  Stream<RealtimeEvent> get events => _events.stream;

  Future<void> connect() async {
    final session = await authProvider?.getSession();
    final token = session?.accessToken;
    final deviceId = session?.deviceId;

    var uri = socketUrl;
    final params = <String, String>{...uri.queryParameters};
    if (token != null && token.isNotEmpty) params['token'] = token;
    if (deviceId != null && deviceId.isNotEmpty) params['deviceId'] = deviceId;
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    if (socketTransport == null) {
      throw StateError(
          'Provide socketTransport or use AppSdk.realtime() which supplies the platform socket.');
    }
    final connection = socketTransport!(uri);
    _connection = connection;

    _connection!.messages.listen(
      (msg) async {
        final decoded = msg is String ? _tryJson(msg) : msg;
        if (decoded is Map) {
          _events.add(RealtimeEvent.fromJson(decoded));
        } else {
          _events.add(RealtimeEvent(type: 'message', data: decoded));
        }
      },
      onDone: () {
        if (!_events.isClosed) _events.add(const RealtimeEvent(type: 'close'));
      },
      onError: (Object e, StackTrace s) {
        if (!_events.isClosed) {
          _events.add(RealtimeEvent(
              type: 'error',
              data: e.toString(),
              meta: {'stack': s.toString()}));
        }
      },
    );
  }

  Future<void> send(String type, dynamic data,
      {Map<String, dynamic> meta = const {}}) async {
    await _connection?.send({'type': type, 'data': data, 'meta': meta});
  }

  Future<void> close() async {
    await _connection?.close();
    if (!_events.isClosed) await _events.close();
  }

  static dynamic _tryJson(String src) {
    try {
      return jsonDecode(src);
    } catch (_) {
      return src;
    }
  }
}
