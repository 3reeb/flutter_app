// =============================================================================
// quantum_local_adapters.dart
// =============================================================================

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import your engines here
import '../quantum_api_engine.dart';
import '../quantum_auth_engine.dart';
import '../quantum_media_api.dart';

/// Highly robust SQLite implementation for heavy data caching and offline queueing.
/// Crash-proof, handles large string/binary data seamlessly.
class SqfliteLocalStore implements LocalStore {
  Database? _db;
  final String dbName;
  final int version;

  SqfliteLocalStore({this.dbName = 'quantum_vault.db', this.version = 1});

  @override
  Future<void> init() async {
    if (_db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, dbName);

    _db = await openDatabase(
      path,
      version: version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE kv_store (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('CREATE INDEX idx_key ON kv_store(key)');
      },
    );
  }

  void _ensureInitialized() {
    if (_db == null)
      throw StateError('SqfliteLocalStore not initialized. Call init() first.');
  }

  @override
  Future<String?> read(String key) async {
    _ensureInitialized();
    final result = await _db!.query(
      'kv_store',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    _ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db!.insert(
      'kv_store',
      {'key': key, 'value': value, 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();
    await _db!.delete(
      'kv_store',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> clear({String? prefix}) async {
    _ensureInitialized();
    if (prefix == null || prefix.isEmpty) {
      await _db!.delete('kv_store');
    } else {
      await _db!.delete(
        'kv_store',
        where: 'key LIKE ?',
        whereArgs: ['$prefix%'],
      );
    }
  }

  Future<List<String>> keys({String? prefix}) async {
    _ensureInitialized();
    List<Map<String, dynamic>> result;
    if (prefix == null || prefix.isEmpty) {
      result = await _db!.query('kv_store', columns: ['key']);
    } else {
      result = await _db!.query(
        'kv_store',
        columns: ['key'],
        where: 'key LIKE ?',
        whereArgs: ['$prefix%'],
      );
    }
    return result.map((e) => e['key'] as String).toList();
  }

  Future<int> size() async {
    _ensureInitialized();
    final result =
        await _db!.rawQuery('SELECT COUNT(*) as count FROM kv_store');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// Hardware-backed keychain storage for Passwords, Refresh Tokens, and Encryption Keys.
/// Implements both SecureVault (from API engine) and AuthSecretStore (from Auth Engine).
class FlutterSecureVault implements SecureVault, AuthSecretStore {
  final FlutterSecureStorage _storage;

  FlutterSecureVault({
    IOSOptions iosOptions =
        const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    AndroidOptions androidOptions =
        const AndroidOptions(encryptedSharedPreferences: true),
  }) : _storage = FlutterSecureStorage(
            iOptions: iosOptions, aOptions: androidOptions);

  @override
  Future<void> init() async {
    // FlutterSecureStorage initializes natively lazily.
  }

  // --- AuthSecretStore Interface ---

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear({String? prefix}) async {
    if (prefix == null) {
      await _storage.deleteAll();
    } else {
      final all = await _storage.readAll();
      for (var k in all.keys) {
        if (k.startsWith(prefix)) {
          await _storage.delete(key: k);
        }
      }
    }
  }

  // --- SecureVault Interface (Mapping to same backend) ---

  @override
  Future<String?> readSecret(String key) => read(key);

  @override
  Future<void> writeSecret(String key, String value) => write(key, value);

  @override
  Future<void> deleteSecret(String key) => delete(key);

  @override
  Future<void> clearSecrets() => clear();
}
