// =============================================================================
// quantum_sdui_engine.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import '../foundation/quantum_isolate_bridge.dart';
import '../foundation/quantum_core.dart';

// Imports from the Quantum Ecosystem
import 'quantum_api_engine.dart';
import 'quantum_auth_engine.dart';

// -----------------------------------------------------------------------------
// SECTION 1 — SECURE SDUI VAULT (Long-Term Encrypted Local JSON Storage)
// -----------------------------------------------------------------------------

class _SduiMeta {
  final String key;
  final String versionHash;
  final DateTime storedAt;
  final int sizeBytes;
  final bool requireAuth;

  const _SduiMeta({
    required this.key,
    required this.versionHash,
    required this.storedAt,
    required this.sizeBytes,
    this.requireAuth = false,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'versionHash': versionHash,
        'storedAt': storedAt.toIso8601String(),
        'sizeBytes': sizeBytes,
        'requireAuth': requireAuth
      };

  factory _SduiMeta.fromJson(Map<String, dynamic> j) => _SduiMeta(
        key: j['key'] as String,
        versionHash: j['versionHash'] as String,
        storedAt: DateTime.parse(j['storedAt'] as String),
        sizeBytes: j['sizeBytes'] as int,
        requireAuth: j['requireAuth'] as bool? ?? false,
      );
}

class SecureSduiVault {
  final LocalStore _store;
  final String _secret;
  final QuantumAuthEngine _authEngine;

  static const _prefix = 'sdui_vault:';
  static const _metaKey = 'sdui_vault_meta';

  SecureSduiVault({
    required LocalStore store,
    required String secret,
    required QuantumAuthEngine authEngine,
  })  : _store = store,
        _secret = secret,
        _authEngine = authEngine;

  String _vaultKey(String key) => '$_prefix$key';

  /// Encrypts and persists SDUI JSON for long-term secure storage.
  Future<void> store(String key, Map<String, dynamic> json,
      {String? version, bool requireAuth = false}) async {
    final serialized = jsonEncode(json);
    final versionHash = version ?? QuantumCipher.hash(serialized);

    // Encrypt off the main thread to prevent UI stutter for massive SDUI payloads
    final envelope = await QLIsolateBridge.safeRun(
        () => QuantumCipher.encrypt(serialized, _secret));

    final integrityTag =
        QuantumCipher.sign('$key:$versionHash:$envelope', _secret);

    final record = jsonEncode({
      'envelope': envelope,
      'version': versionHash,
      'integrity': integrityTag,
      'storedAt': DateTime.now().toIso8601String()
    });

    await _store.write(_vaultKey(key), record);
    await _updateMeta(key, versionHash, serialized.length, requireAuth);
  }

  /// Loads and decrypts SDUI JSON.
  /// Returns null if not found, tampered, or if auth is missing.
  Future<Map<String, dynamic>?> load(String key) async {
    _SduiMeta? meta;
    for (final m in await _loadMetaEntries()) {
      if (m.key == key) {
        meta = m;
        break;
      }
    }

    // Strictly blocks decryption if authentication is required but missing.
    // Rejects without ever running the AES cipher.
    if (meta != null && meta.requireAuth && !_authEngine.isAuthenticated) {
      return null;
    }

    final raw = await _store.read(_vaultKey(key));
    if (raw == null) return null;

    try {
      final record = jsonDecode(raw) as Map<String, dynamic>;
      final envelope = record['envelope'] as String;
      final version = record['version'] as String;
      final integrity = record['integrity'] as String;

      // Zero-Trust HMAC verification before touching the ciphertext
      if (!QuantumCipher.verify(
          '$key:$version:$envelope', integrity, _secret)) {
        await invalidate(key); // Auto-purge tampered data
        return null;
      }

      // Decrypt off the main thread
      final decrypted = await QLIsolateBridge.safeRun(
          () => QuantumCipher.decrypt(envelope, _secret));

      // Returns an unmodifiable map to prevent runtime memory tampering by rogue code
      return Map.unmodifiable(jsonDecode(decrypted) as Map<String, dynamic>);
    } catch (_) {
      await invalidate(key);
      return null;
    }
  }

  /// Checks if the stored version differs from [serverVersion].
  Future<bool> needsUpdate(String key, String serverVersion) async {
    final raw = await _store.read(_vaultKey(key));
    if (raw == null) return true;
    try {
      final record = jsonDecode(raw) as Map<String, dynamic>;
      return record['version'] != serverVersion;
    } catch (_) {
      return true; // Corrupted, force an update
    }
  }

  /// Atomic update: re-encrypt with new JSON and version.
  Future<void> applyUpdate(
          String key, Map<String, dynamic> newJson, String newVersion) =>
      store(key, newJson, version: newVersion);

  /// Removes a stored SDUI entry.
  Future<void> invalidate(String key) async {
    await _store.delete(_vaultKey(key));
    await _removeMeta(key);
  }

  /// Removes all stored SDUI entries (Useful on Logout).
  Future<void> invalidateAll() async {
    final keys = await _store.keys(prefix: _prefix);
    for (final k in keys) {
      await _store.delete(k);
    }
    await _store.delete(_metaKey);
  }

  /// Lists metadata of all stored entries without decrypting payloads.
  Future<List<Map<String, dynamic>>> listStored() async {
    final raw = await _store.read(_metaKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _updateMeta(
      String key, String versionHash, int sizeBytes, bool requireAuth) async {
    final entries = await _loadMetaEntries();
    entries.removeWhere((m) => m.key == key);
    entries.add(_SduiMeta(
        key: key,
        versionHash: versionHash,
        storedAt: DateTime.now(),
        sizeBytes: sizeBytes,
        requireAuth: requireAuth));
    await _store.write(
        _metaKey, jsonEncode(entries.map((m) => m.toJson()).toList()));
  }

  Future<void> _removeMeta(String key) async {
    final entries = await _loadMetaEntries();
    entries.removeWhere((m) => m.key == key);
    await _store.write(
        _metaKey, jsonEncode(entries.map((m) => m.toJson()).toList()));
  }

  Future<List<_SduiMeta>> _loadMetaEntries() async {
    final raw = await _store.read(_metaKey);
    if (raw == null) return <_SduiMeta>[];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => _SduiMeta.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <_SduiMeta>[];
    }
  }
}

// -----------------------------------------------------------------------------
// SECTION 2 — SECURE DISPLAY PAYLOAD (Tamper-Proof Server→Client Display)
// -----------------------------------------------------------------------------

class SecureDisplayResult {
  final Map<String, dynamic>? data;
  final String? rejectionReason;

  bool get isVerified => data != null && rejectionReason == null;

  const SecureDisplayResult.verified(this.data) : rejectionReason = null;
  const SecureDisplayResult.rejected(this.rejectionReason) : data = null;
}

class SecureDisplayEngine {
  final String _secret;
  final Duration _maxAge;
  final Set<String> _consumedNonces = {};

  static const int _maxNonceBufferSize = 10000;

  SecureDisplayEngine({required String secret, Duration? maxAge})
      : _secret = secret,
        _maxAge = maxAge ?? const Duration(minutes: 5);

  /// Verifies a server-signed secure display payload.
  /// Enforces Nonce consumption, Signature validation, and strict Timestamps.
  SecureDisplayResult verify(Map<String, dynamic> payload) {
    final data = payload['data'];
    final signature = payload['signature'] as String?;
    final timestamp = payload['timestamp'] as int?;
    final nonce = payload['nonce'] as String?;

    if (signature == null ||
        timestamp == null ||
        nonce == null ||
        data == null) {
      return const SecureDisplayResult.rejected(
          'Missing required cryptographic fields');
    }

    // Anti-replay mechanism: Ensure this exact payload hasn't been rendered before
    if (_consumedNonces.contains(nonce)) {
      return const SecureDisplayResult.rejected(
          'Replay detected: Nonce already consumed');
    }

    // Timestamp validation: Prevent serving stale sensitive data
    final payloadTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(payloadTime).abs() > _maxAge) {
      return const SecureDisplayResult.rejected(
          'Payload expired or system clock skew is too large');
    }

    // Signature verification (HMAC-SHA256)
    final signatureInput = '$nonce:$timestamp:${jsonEncode(data)}';
    if (!QuantumCipher.verify(signatureInput, signature, _secret)) {
      return const SecureDisplayResult.rejected(
          'Invalid signature — data payload was tampered in transit');
    }

    // Rotate nonce buffer to prevent memory leaks over time
    if (_consumedNonces.length >= _maxNonceBufferSize) {
      _consumedNonces.clear();
    }
    _consumedNonces.add(nonce);

    return SecureDisplayResult.verified(
        data is Map<String, dynamic> ? data : {'value': data});
  }

  /// Verifies and consumes a one-time display token for ultimate restriction.
  SecureDisplayResult verifyAndConsume(Map<String, dynamic> payload) {
    final result = verify(payload);
    if (result.isVerified) {
      final token = payload['displayToken'] as String?;
      if (token != null) _consumedNonces.add('token:$token');
    }
    return result;
  }
}

// -----------------------------------------------------------------------------
// SECTION 3 — SDUI API ADAPTER (Orchestrator between API and Security Engines)
// -----------------------------------------------------------------------------

class QuantumSduiAdapter {
  final VaultStreamClient _apiClient;
  final SecureSduiVault _sduiVault;
  final SecureDisplayEngine _displayEngine;

  final String _defaultSduiSlug;
  final StreamController<String> _pageUpdateController =
      StreamController<String>.broadcast();

  QuantumSduiAdapter({
    required VaultStreamClient apiClient,
    required SecureSduiVault sduiVault,
    required SecureDisplayEngine displayEngine,
    String defaultSduiSlug = 'sdui_layouts',
  })  : _apiClient = apiClient,
        _sduiVault = sduiVault,
        _displayEngine = displayEngine,
        _defaultSduiSlug = defaultSduiSlug;

  /// A stream that emits the `pageKey` whenever a page layout is updated from the server.
  /// Listen to this in your UI to trigger automatic re-renders of SDUI elements.
  Stream<String> get onPageUpdated => _pageUpdateController.stream;

  /// Fetches an SDUI page layout.
  /// Implements a robust Offline-First / Cache-First strategy backed by AES-256 local storage.
  Future<Map<String, dynamic>?> getPage(String pageKey,
      {bool forceRefresh = false}) async {
    // 1. Check Offline State First
    if (!forceRefresh && _apiClient.isOffline) {
      return await _sduiVault.load(pageKey);
    }

    try {
      // 2. Execute a Network Request bypassing the default memory cache (handled by SDUI Vault)
      final result = await _apiClient.executeRead(
        slug: _defaultSduiSlug,
        query: {'pageKey': pageKey, 'op': 'readOne'},
        policy: QueryPolicy(
          forceRefresh: forceRefresh,
          cachePolicy: CachePolicyMode.networkFirst,
        ),
      );

      if (result.isSuccess && result.data != null) {
        final data = result.data as Map<String, dynamic>;

        // Extract SDUI specific metadata (adjust these keys to match your backend exactly)
        final serverVersion = data['version']?.toString();
        final payload = data['layout'] as Map<String, dynamic>? ?? data;
        final requireAuth = data['requireAuth'] == true;

        // 3. Compare Version Hashes. Only decrypt/encrypt disk if necessary.
        final needsUpdate = forceRefresh ||
            await _sduiVault.needsUpdate(pageKey, serverVersion ?? '');

        if (needsUpdate) {
          await _sduiVault.store(
            pageKey,
            payload,
            version: serverVersion,
            requireAuth: requireAuth,
          );

          // Notify listeners that this specific page layout has updated
          if (_pageUpdateController.hasListener) {
            _pageUpdateController.add(pageKey);
          }
        }

        return payload;
      }
    } catch (e) {
      // Silent catch: We fall back to the secure vault in case of total network failure
    }

    // 4. Fallback: Load securely from the vault
    return await _sduiVault.load(pageKey);
  }

  /// Forces an update for a specific page in the background and notifies listeners.
  Future<void> prefetchPage(String pageKey) async {
    await getPage(pageKey, forceRefresh: true);
  }

  /// Fetches a one-time tamper-proof secure display payload (e.g., Bank Balance, OTP screen).
  /// Enforces Network-Only fetching to ensure critical data is never served stale.
  Future<SecureDisplayResult> getSecureDisplay(
      String slug, Map<String, dynamic> query) async {
    try {
      final result = await _apiClient.executeRead(
        slug: slug,
        query: query,
        policy: const QueryPolicy(
          cachePolicy: CachePolicyMode.networkOnly,
          priority: RequestPriority.high,
        ),
      );

      if (result.isSuccess && result.data != null) {
        // Feed the raw payload into the Display Engine to verify signatures, nonces, and timestamps
        return _displayEngine
            .verifyAndConsume(result.data as Map<String, dynamic>);
      }

      return SecureDisplayResult.rejected(result.error?.message ??
          'Network request failed or returned empty payload');
    } catch (e) {
      return SecureDisplayResult.rejected(
          'Secure display fetch encountered an exception: $e');
    }
  }

  /// Clears a specific stored SDUI file.
  Future<void> invalidatePage(String pageKey) async {
    await _sduiVault.invalidate(pageKey);
  }

  /// Clears all stored SDUI files.
  /// Highly recommended to call this during User Logout to wipe cached sensitive UI layouts.
  Future<void> clearAll() async {
    await _sduiVault.invalidateAll();
  }

  /// Closes internal stream controllers to prevent memory leaks.
  void dispose() {
    _pageUpdateController.close();
  }
}
