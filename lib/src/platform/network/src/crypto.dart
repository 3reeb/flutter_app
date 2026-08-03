// =============================================================================
// crypto.dart — CryptoPolicy and NativeSystemDelegate.
// Imports types.dart for EncryptionMode and TransferDirection.
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'types.dart';

// ---------------------------------------------------------------------------
// NativeSystemDelegate
// ---------------------------------------------------------------------------

/// Platform hooks for hardware-accelerated encryption and OS background transfers.
abstract class NativeSystemDelegate {
  /// Hand a download/upload to the OS task manager (iOS URLSession / Android WorkManager).
  Future<void> handoffTransferToOS({
    required String taskId,
    required Uri uri,
    required TransferDirection direction,
    required String filePath,
    required Map<String, String> headers,
  });

  void registerBackgroundWakeup(
      Future<void> Function(Map<String, dynamic> payload) onWakeup);

  /// Encrypt [data] using the platform secure enclave / hardware keystore.
  Future<Uint8List> hardwareEncrypt(Uint8List data, String keyId,
      {Map<String, dynamic> meta = const {}});

  /// Decrypt [data] using the platform secure enclave / hardware keystore.
  Future<Uint8List> hardwareDecrypt(Uint8List data, String keyId,
      {Map<String, dynamic> meta = const {}});
}

// ---------------------------------------------------------------------------
// CryptoPolicy
// ---------------------------------------------------------------------------

/// Pluggable encryption applied to request/response byte streams.
abstract class CryptoPolicy {
  EncryptionMode get mode;

  Uint8List encryptBytes(Uint8List input,
      {Map<String, dynamic> meta = const {}});
  Uint8List decryptBytes(Uint8List input,
      {Map<String, dynamic> meta = const {}});
  Stream<List<int>> encryptStream(Stream<List<int>> input,
      {Map<String, dynamic> meta = const {}});
  Stream<List<int>> decryptStream(Stream<List<int>> input,
      {Map<String, dynamic> meta = const {}});
}

/// No-op — passes bytes through unchanged.
class PassThroughCryptoPolicy implements CryptoPolicy {
  const PassThroughCryptoPolicy();

  @override
  EncryptionMode get mode => EncryptionMode.none;

  @override
  Uint8List encryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      input;

  @override
  Uint8List decryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      input;

  @override
  Stream<List<int>> encryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      input;

  @override
  Stream<List<int>> decryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      input;
}

/// Delegates to caller-supplied function objects — integrates any external lib.
class ExternalCryptoPolicy implements CryptoPolicy {
  final Uint8List Function(Uint8List, Map<String, dynamic>) encryptFn;
  final Uint8List Function(Uint8List, Map<String, dynamic>) decryptFn;
  final Stream<List<int>> Function(Stream<List<int>>, Map<String, dynamic>)
      encryptStreamFn;
  final Stream<List<int>> Function(Stream<List<int>>, Map<String, dynamic>)
      decryptStreamFn;

  const ExternalCryptoPolicy({
    required this.encryptFn,
    required this.decryptFn,
    required this.encryptStreamFn,
    required this.decryptStreamFn,
  });

  @override
  EncryptionMode get mode => EncryptionMode.external;

  @override
  Uint8List encryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      encryptFn(input, meta);

  @override
  Uint8List decryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      decryptFn(input, meta);

  @override
  Stream<List<int>> encryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      encryptStreamFn(input, meta);

  @override
  Stream<List<int>> decryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      decryptStreamFn(input, meta);
}
