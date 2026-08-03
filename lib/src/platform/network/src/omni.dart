// =============================================================================
// omni.dart — OmniLogger, domain facade interfaces, OmniCloud.
// =============================================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'exceptions.dart';

// ---------------------------------------------------------------------------
// OmniLogger
// ---------------------------------------------------------------------------

/// Structured logger for the network stack. Output captured by Flutter DevTools.
class OmniLogger {
  static bool enabled = true;

  static void debug(String message, [Object? data]) {
    if (!enabled) return;
    developer.log('[DEBUG] $message${data != null ? ' :: $data' : ''}',
        name: 'OmniNet', level: 500);
  }

  static void info(String message, [Object? data]) {
    if (!enabled) return;
    developer.log('[INFO] $message${data != null ? ' :: $data' : ''}',
        name: 'OmniNet', level: 800);
  }

  static void warn(String message, [Object? data]) {
    developer.log('[WARN] $message${data != null ? ' :: $data' : ''}',
        name: 'OmniNet', level: 900);
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    developer.log(
      '[ERROR] $message${error != null ? ' :: $error' : ''}',
      name: 'OmniNet',
      level: 1000,
      error: error,
      stackTrace: stack,
    );
  }
}

// ---------------------------------------------------------------------------
// OmniDocument
// ---------------------------------------------------------------------------

class OmniDocument {
  final String id;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OmniDocument({
    required this.id,
    required this.data,
    this.createdAt,
    this.updatedAt,
  });

  factory OmniDocument.fromJson(dynamic json) {
    final m = (json as Map).cast<String, dynamic>();
    final data = Map<String, dynamic>.from(m['data'] as Map? ?? m);
    data.remove('id');
    return OmniDocument(
      id: m['id']?.toString() ?? '',
      data: data,
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString())
          : null,
      updatedAt: m['updatedAt'] != null
          ? DateTime.tryParse(m['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}

// ---------------------------------------------------------------------------
// Domain Interfaces
// ---------------------------------------------------------------------------

abstract class IOmniAuth {
  Future<dynamic> signIn(Map<String, dynamic> credentials);
  Future<void> signOut();
  Stream<dynamic> get onSessionChanged;
  Future<dynamic> currentSession();
  Future<dynamic> refreshSession();
}

abstract class IOmniDatabase {
  Future<OmniDocument> getDocument(String collection, String id);
  Future<List<OmniDocument>> listDocuments(String collection,
      {Map<String, dynamic> query});
  Future<OmniDocument> createDocument(
      String collection, Map<String, dynamic> data);
  Future<OmniDocument> updateDocument(
      String collection, String id, Map<String, dynamic> data);
  Future<void> deleteDocument(String collection, String id);
  Stream<OmniDocument> watchDocument(String collection, String id);
  Stream<List<OmniDocument>> watchCollection(String collection,
      {Map<String, dynamic> query});
}

abstract class IOmniStorage {
  Future<String> upload({
    required dynamic file, // QuantumFile
    required String path,
    String contentType,
  });
  Future<void> download({required String path, required dynamic file});
  Future<void> delete(String path);
  Future<String> getDownloadUrl(String path);
}

abstract class IOmniRTC {
  Future<dynamic> connect(String channel);
  Future<void> disconnect();
  Future<void> publish(String channel, dynamic event);
  Stream<dynamic> subscribe(String channel);
  Stream<Map<String, dynamic>> presence(String channel);
}

// ---------------------------------------------------------------------------
// OmniCloud — umbrella facade
// ---------------------------------------------------------------------------

class OmniCloud {
  final IOmniAuth auth;
  final IOmniDatabase? database;
  final IOmniStorage? storage;
  final IOmniRTC? rtc;

  OmniCloud({required this.auth, this.database, this.storage, this.rtc});

  Future<dynamic> signIn(Map<String, dynamic> credentials) =>
      auth.signIn(credentials);
  Future<void> signOut() => auth.signOut();
  Stream<dynamic> get onSessionChanged => auth.onSessionChanged;
}

// ---------------------------------------------------------------------------
// Internal engine↔auth bridge
// ---------------------------------------------------------------------------

class OmniCloudEngineAuthBridge implements IOmniAuth {
  final dynamic _engine; // AppSdk or Quantum

  OmniCloudEngineAuthBridge(this._engine);

  @override
  Future<dynamic> signIn(Map<String, dynamic> credentials) async {
    try {
      return await (_engine as dynamic).signIn(credentials);
    } catch (e) {
      throw OmniCloudException('sign_in_failed', e.toString(), e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await (_engine as dynamic).signOut();
    } catch (e) {
      throw OmniCloudException('sign_out_failed', e.toString(), e);
    }
  }

  @override
  Stream<dynamic> get onSessionChanged =>
      (_engine as dynamic).onSessionChanged as Stream<dynamic>;

  @override
  Future<dynamic> currentSession() async =>
      await (_engine as dynamic).currentSession();

  @override
  Future<dynamic> refreshSession() async =>
      await (_engine as dynamic).refreshSession();
}
