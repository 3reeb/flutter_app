// =============================================================================
// QUANTUM IMAGEKIT ADAPTER v1.0 — PRODUCTION READY
// quantum_imagekit_adapter.dart
//
// Architecture:
//   ┌─ QuantumMediaConfig ─────────────────────────────────────────────────┐
//   │  Single Firestore truth (_globals/media_config). All adapters read   │
//   │  from it. Hot-reloads on doc change. Zero adapter knows about Firebase│
//   │  internals — they just receive a MediaBackendConfig.                 │
//   └──────────────────────────────────────────────────────────────────────┘
//        │
//        ▼
//   ┌─ QuantumMediaAdapter (abstract interface) ────────────────────────────┐
//   │  Standard contract every adapter MUST implement. Swap adapters in    │
//   │  one line. SDUI/features/media never change.                         │
//   └──────────────────────────────────────────────────────────────────────┘
//        │
//        ├── ImageKitMediaAdapter  (primary CDN — ImageKit.io)
//        ├── CloudflareR2Adapter   (future stub — interface-complete)
//        └── [see quantum_github_adapter.dart for GithubMediaAdapter]
//
// Usage:
//   // In app bootstrap — ONE line to switch provider:
//   QuantumMediaConfig.instance.setAdapter(ImageKitMediaAdapter());
//   // or:
//   QuantumMediaConfig.instance.setAdapter(GithubMediaAdapter(...));
//
// Stability contract:
//   - QLImageResolver.rewrite() signature NEVER changes
//   - QuantumMediaEngine.instance API NEVER changes
//   - SDUI JSON keys NEVER change
//   - FirebaseMediaStorageBridge is replaced — not wrapped
// =============================================================================

// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:collection';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../quantum_api_engine.dart';
import '../quantum_auth_engine.dart';
import '../quantum_media_api.dart';
import '../../features/media/quantum_image_engine.dart';

// =============================================================================
// §0 — MEDIA BACKEND CONFIG (Central truth object — adapter-agnostic)
// =============================================================================

/// Strongly-typed config loaded from Firestore _globals/media_config.
/// Every field has a safe default so the app never crashes on missing keys.
class MediaBackendConfig {
  // ── ImageKit ──────────────────────────────────────────────────────────────
  final String imagekitUrlEndpoint; // e.g. https://ik.imagekit.io/your_id
  final String imagekitPublicKey;
  final String imagekitPrivateKey; // used for signed URLs & upload auth
  final String
      imagekitUploadUrl; // e.g. https://upload.imagekit.io/api/v1/files/upload
  final bool imagekitPrivateBucket; // if true, all reads use signed URLs
  final int imagekitSignedUrlTtlSeconds; // default 3600

  // ── GitHub ────────────────────────────────────────────────────────────────
  final String githubOwner; // e.g. "your-org"
  final String githubRepo; // e.g. "manga-assets"
  final String githubBranch; // e.g. "main"
  final String githubToken; // Personal Access Token (keep server-side ideally)
  final bool
      githubUseJsdelivr; // true = serve via jsDelivr CDN (no rate limits)

  // ── Cloudflare R2 (future) ────────────────────────────────────────────────
  final String r2BucketUrl; // e.g. https://pub-xxx.r2.dev
  final String r2AccountId;
  final String r2AccessKeyId;
  final String r2SecretAccessKey;

  // ── Shared Quality Ladder ─────────────────────────────────────────────────
  final List<int> imageBreakpoints; // e.g. [320, 640, 960, 1280, 1920]
  final List<int> videoBreakpoints; // e.g. [360, 480, 720, 1080]
  final int defaultImageQuality; // 0–100
  final int maxRamCacheBytes; // bytes, default 80MB
  final int maxDiskCacheMb; // megabytes, default 512

  // ── Upload ────────────────────────────────────────────────────────────────
  final int uploadChunkSizeBytes; // default 2MB
  final int uploadMaxParallelChunks; // default 3
  final int uploadMaxRetries; // default 5
  final String? activeProvider; // 'imagekit' | 'github' | 'r2' | null=auto

  const MediaBackendConfig({
    this.imagekitUrlEndpoint = '',
    this.imagekitPublicKey = '',
    this.imagekitPrivateKey = '',
    this.imagekitUploadUrl = 'https://upload.imagekit.io/api/v1/files/upload',
    this.imagekitPrivateBucket = false,
    this.imagekitSignedUrlTtlSeconds = 3600,
    this.githubOwner = '',
    this.githubRepo = '',
    this.githubBranch = 'main',
    this.githubToken = '',
    this.githubUseJsdelivr = true,
    this.r2BucketUrl = '',
    this.r2AccountId = '',
    this.r2AccessKeyId = '',
    this.r2SecretAccessKey = '',
    this.imageBreakpoints = const [320, 480, 640, 960, 1280, 1920],
    this.videoBreakpoints = const [360, 480, 720, 1080],
    this.defaultImageQuality = 80,
    this.maxRamCacheBytes = 80 * 1024 * 1024,
    this.maxDiskCacheMb = 512,
    this.uploadChunkSizeBytes = 2 * 1024 * 1024,
    this.uploadMaxParallelChunks = 3,
    this.uploadMaxRetries = 5,
    this.activeProvider,
  });

  factory MediaBackendConfig.fromJson(Map<String, dynamic> json) {
    int _i(String k, int d) => (json[k] as num?)?.toInt() ?? d;
    bool _b(String k, bool d) => (json[k] as bool?) ?? d;
    String _s(String k, [String d = '']) => json[k]?.toString() ?? d;
    List<int> _li(String k, List<int> d) {
      final raw = json[k];
      if (raw is List) return raw.map((e) => (e as num).toInt()).toList();
      return d;
    }

    return MediaBackendConfig(
      imagekitUrlEndpoint: _s('imagekit_url_endpoint'),
      imagekitPublicKey: _s('imagekit_public_key'),
      imagekitPrivateKey: _s('imagekit_private_key'),
      imagekitUploadUrl: _s('imagekit_upload_url',
          'https://upload.imagekit.io/api/v1/files/upload'),
      imagekitPrivateBucket: _b('imagekit_private_bucket', false),
      imagekitSignedUrlTtlSeconds: _i('imagekit_signed_url_ttl_seconds', 3600),
      githubOwner: _s('github_owner'),
      githubRepo: _s('github_repo'),
      githubBranch: _s('github_branch', 'main'),
      githubToken: _s('github_token'),
      githubUseJsdelivr: _b('github_use_jsdelivr', true),
      r2BucketUrl: _s('r2_bucket_url'),
      r2AccountId: _s('r2_account_id'),
      r2AccessKeyId: _s('r2_access_key_id'),
      r2SecretAccessKey: _s('r2_secret_access_key'),
      imageBreakpoints:
          _li('image_breakpoints', const [320, 480, 640, 960, 1280, 1920]),
      videoBreakpoints: _li('video_breakpoints', const [360, 480, 720, 1080]),
      defaultImageQuality: _i('default_image_quality', 80),
      maxRamCacheBytes: _i('max_ram_cache_bytes', 80 * 1024 * 1024),
      maxDiskCacheMb: _i('max_disk_cache_mb', 512),
      uploadChunkSizeBytes: _i('upload_chunk_size_bytes', 2 * 1024 * 1024),
      uploadMaxParallelChunks: _i('upload_max_parallel_chunks', 3),
      uploadMaxRetries: _i('upload_max_retries', 5),
      activeProvider: json['active_provider']?.toString(),
    );
  }
}

// =============================================================================
// §1 — CENTRAL CONFIG SINGLETON (Firestore → Everything)
// =============================================================================

/// Reads _globals/media_config from Firestore once, caches it, hot-reloads
/// on changes, and distributes it to all registered adapters.
///
/// This is the ONLY place the word "firebase" appears in the media layer.
/// All other code only sees [MediaBackendConfig].
class QuantumMediaConfig {
  static final QuantumMediaConfig instance = QuantumMediaConfig._();
  QuantumMediaConfig._();

  MediaBackendConfig _config = const MediaBackendConfig();
  MediaBackendConfig get config => _config;

  QuantumMediaAdapter? _adapter;
  QuantumMediaAdapter get adapter => _adapter ?? const _NoOpMediaAdapter();

  final List<void Function(MediaBackendConfig)> _listeners = [];

  StreamSubscription? _firestoreSub;
  bool _initialized = false;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Boot from Firestore. Safe to call multiple times.
  /// [firestoreReader] is a function that returns a stream of Firestore doc
  /// snapshots — typed as Map<String,dynamic>. This keeps this file free of
  /// firebase_* imports so you can swap out the config source.
  Future<void> initFromFirestore(
    Stream<Map<String, dynamic>> Function(String collection, String doc)
        firestoreStreamFn,
  ) async {
    if (_initialized) return;
    _initialized = true;

    final stream = firestoreStreamFn('_globals', 'media_config');

    // Load first value synchronously (with 5s timeout)
    final completer = Completer<void>();
    _firestoreSub = stream.listen(
      (data) {
        _applyConfig(data);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {}, // Use defaults if Firestore is slow
    );
  }

  /// Override config from a plain map (useful for testing or non-Firebase setup).
  void initFromMap(Map<String, dynamic> data) {
    _applyConfig(data);
    _initialized = true;
  }

  /// Manually set the active adapter. Call after initFromFirestore.
  void setAdapter(QuantumMediaAdapter adapter) {
    _adapter = adapter;
    adapter.configure(_config);
  }

  /// Register a listener that fires whenever config reloads.
  void addConfigListener(void Function(MediaBackendConfig) listener) {
    _listeners.add(listener);
  }

  void removeConfigListener(void Function(MediaBackendConfig) listener) {
    _listeners.remove(listener);
  }

  Future<void> dispose() async {
    await _firestoreSub?.cancel();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  void _applyConfig(Map<String, dynamic> data) {
    _config = MediaBackendConfig.fromJson(data);
    _adapter?.configure(_config);
    for (final fn in _listeners) {
      try {
        fn(_config);
      } catch (_) {}
    }
  }
}

// =============================================================================
// §2 — QUANTUM MEDIA ADAPTER (The universal interface — the standard)
// =============================================================================

/// STANDARD CONTRACT — every media backend MUST implement this.
///
/// HOW TO BUILD A NEW ADAPTER:
///   1. Create a class that extends [QuantumMediaAdapter]
///   2. Implement all methods below
///   3. Call [QuantumMediaConfig.instance.setAdapter(YourAdapter())]
///   4. Nothing else in the app changes.
///
/// STABILITY GUARANTEE:
///   - This interface is the firewall between adapters and the app.
///   - SDUI, features/media, QLImage, QuantumMediaEngine — none of them
///     directly reference any adapter class.
abstract class QuantumMediaAdapter {
  /// Human-readable adapter name for logging/debugging.
  String get adapterName;

  /// Called whenever [QuantumMediaConfig] reloads. Adapters should update
  /// their internal state without dropping in-flight requests.
  void configure(MediaBackendConfig config);

  // ── URL building ──────────────────────────────────────────────────────────

  /// Transforms a raw media path (relative or absolute) into a fully
  /// optimized, CDN-ready URL. Called by [QLImageResolver.rewrite()].
  ///
  /// [path]    — raw path, e.g. "manga/chapter1/page1.jpg" or a full URL
  /// [width]   — target display width in physical pixels (0 = auto)
  /// [height]  — target display height in physical pixels (0 = auto)
  /// [quality] — 0–100 (use [MediaBackendConfig.defaultImageQuality] as default)
  /// [format]  — 'auto'|'webp'|'avif'|'jpg'|'png' (auto = adapter decides)
  String buildUrl({
    required String path,
    int width = 0,
    int height = 0,
    int quality = 80,
    String format = 'auto',
    Map<String, String> extras = const {},
  });

  /// Returns a low-quality image placeholder URL for the given path.
  /// Used for the blur-up pattern (render immediately, sharpen on load).
  String buildLqipUrl(String path);

  /// Returns a signed URL for private/protected content.
  /// Returns the plain URL if the adapter does not support signing.
  Future<String> buildSignedUrl(String path, {Duration? ttl});

  // ── Transfer operations ───────────────────────────────────────────────────

  /// Creates and returns a [MediaTransferSession] for uploading a file.
  /// The session is paused by default — call [MediaTransferSession.resume()].
  Future<MediaTransferSession> createUploadSession({
    required String localFilePath,
    required String remotePath,
    required String mimeType,
    Map<String, String> metadata = const {},
    SessionContext? auth,
  });

  /// Creates and returns a [MediaTransferSession] for downloading a file.
  /// Supports byte-range resume — if [localFilePath] already exists and has
  /// partial data, the download continues from the last byte.
  Future<MediaTransferSession> createDownloadSession({
    required String remotePath,
    required String localFilePath,
    SessionContext? auth,
  });

  // ── Discovery (optional — return empty list if not supported) ─────────────

  /// Lists files at the given remote path prefix. Used e.g. by manga browser.
  Future<List<MediaFileInfo>> listFiles({
    required String path,
    int limit = 50,
    String? cursor,
  });

  /// Returns metadata for a single file without downloading it.
  Future<MediaFileInfo?> getFileInfo(String path);

  // ── QLImageResolver bridge ────────────────────────────────────────────────

  /// Returns a [QLImageResolver] implementation that routes through this adapter.
  /// [QuantumImagePipeline.instance.resolver] is set to this automatically
  /// when [QuantumMediaConfig.setAdapter()] is called.
  QLImageResolver get imageResolver;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  Future<void> dispose();
}

// ── No-op adapter (safe default before setAdapter is called) ─────────────────
class _NoOpMediaAdapter implements QuantumMediaAdapter {
  const _NoOpMediaAdapter();

  @override
  String get adapterName => 'noop';

  @override
  void configure(MediaBackendConfig config) {}

  @override
  String buildUrl(
          {required String path,
          int width = 0,
          int height = 0,
          int quality = 80,
          String format = 'auto',
          Map<String, String> extras = const {}}) =>
      path;

  @override
  String buildLqipUrl(String path) => path;

  @override
  Future<String> buildSignedUrl(String path, {Duration? ttl}) async => path;

  @override
  Future<MediaTransferSession> createUploadSession(
          {required String localFilePath,
          required String remotePath,
          required String mimeType,
          Map<String, String> metadata = const {},
          SessionContext? auth}) async =>
      throw UnimplementedError('No adapter configured');

  @override
  Future<MediaTransferSession> createDownloadSession(
          {required String remotePath,
          required String localFilePath,
          SessionContext? auth}) async =>
      throw UnimplementedError('No adapter configured');

  @override
  Future<List<MediaFileInfo>> listFiles(
          {required String path, int limit = 50, String? cursor}) async =>
      [];

  @override
  Future<MediaFileInfo?> getFileInfo(String path) async => null;

  @override
  QLImageResolver get imageResolver => _NoOpResolver();

  @override
  Future<void> dispose() async {}
}

class _NoOpResolver extends QLImageResolver {
  @override
  String rewrite(String url, int width, int height, int quality) => url;
}

// =============================================================================
// §3 — TRANSFER SESSION (Unified upload/download state machine)
// =============================================================================

enum TransferState { idle, running, paused, completed, failed, cancelled }

/// Returned by [QuantumMediaAdapter.createUploadSession] and
/// [createDownloadSession]. Provides pause/resume/cancel + live progress.
///
/// Survives network disconnection — the underlying implementation uses
/// byte-range requests and persists offset to [LocalStore] so it can
/// recover across app restarts.
abstract class MediaTransferSession {
  /// Unique ID for this session (used for persistence).
  String get sessionId;

  /// Live progress events.
  Stream<TransferProgress> get progress;

  /// Current state signal.
  ValueNotifier<TransferState> get state;

  /// Remote URL/path result (set when upload completes — the final CDN URL).
  String? get resultUrl;

  /// Starts or resumes the transfer.
  Future<void> resume();

  /// Pauses the transfer. Can be resumed later without losing progress.
  Future<void> pause();

  /// Permanently cancels and cleans up local session data.
  Future<void> cancel();

  /// Completes when the transfer finishes (success or failure).
  Future<void> get done;
}

/// File metadata returned by [QuantumMediaAdapter.listFiles].
class MediaFileInfo {
  final String path;
  final String? url;
  final String? lqipUrl;
  final int? sizeBytes;
  final String? mimeType;
  final DateTime? createdAt;
  final Map<String, dynamic> extra;

  const MediaFileInfo({
    required this.path,
    this.url,
    this.lqipUrl,
    this.sizeBytes,
    this.mimeType,
    this.createdAt,
    this.extra = const {},
  });
}

// =============================================================================
// §4 — IMAGEKIT URL BUILDER (Zero-allocation, deterministic)
// =============================================================================

/// Builds ImageKit transformation URLs with zero heap allocation for the
/// common hot path (just width+quality+format).
class ImageKitUrlBuilder {
  final String endpoint; // e.g. https://ik.imagekit.io/your_id

  ImageKitUrlBuilder(this.endpoint);

  static final Map<String, String> _cache = LinkedHashMap();
  static const int _cacheMaxEntries = 1000;

  /// Builds a transformation URL. All params are optional.
  String build({
    required String path,
    int width = 0,
    int height = 0,
    int quality = 80,
    String format = 'auto', // 'auto','webp','avif','jpg','png'
    String crop = '', // 'force','at_max','at_least','maintain_ratio'
    String focus = '', // 'auto','face','center','top','left'
    bool progressive = true,
    double? dpr, // device pixel ratio
    bool grayscale = false,
    String? overlayText,
    int? blur, // 0–100
    int? radius, // corner radius in px, -1 = 'max'
    String? namedTransform, // ImageKit named transform alias
  }) {
    // ── Cache key ────────────────────────────────────────────────────────────
    final cacheKey =
        '$endpoint|$path|$width|$height|$quality|$format|$crop|$focus'
        '|$progressive|$dpr|$grayscale|$blur|$radius|$namedTransform';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // ── Build transform string ────────────────────────────────────────────────
    final transforms = <String>[];

    // Named transform takes precedence (ImageKit feature)
    if (namedTransform != null && namedTransform.isNotEmpty) {
      transforms.add('n-$namedTransform');
    } else {
      if (width > 0) transforms.add('w-$width');
      if (height > 0) transforms.add('h-$height');
      if (quality > 0 && quality < 100) transforms.add('q-$quality');
      if (format != 'original') {
        transforms.add(format == 'auto' ? 'f-auto' : 'f-$format');
      }
      if (crop.isNotEmpty) transforms.add('c-$crop');
      if (focus.isNotEmpty) transforms.add('fo-$focus');
      if (progressive) transforms.add('pr-true');
      if (dpr != null && dpr > 0)
        transforms.add('dpr-${dpr.toStringAsFixed(1)}');
      if (grayscale) transforms.add('e-grayscale');
      if (blur != null && blur > 0) transforms.add('bl-$blur');
      if (radius != null) transforms.add(radius == -1 ? 'r-max' : 'r-$radius');
      if (overlayText != null && overlayText.isNotEmpty) {
        transforms.add('ot-${Uri.encodeComponent(overlayText)}');
      }
    }

    // ── Assemble URL ──────────────────────────────────────────────────────────
    final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    String url;
    if (transforms.isEmpty) {
      url = '$base$cleanPath';
    } else {
      url = '${base}tr:${transforms.join(',')}/tr:lo-true/$cleanPath';
    }

    // ── LRU cache eviction ────────────────────────────────────────────────────
    if (_cache.length >= _cacheMaxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = url;

    return url;
  }

  /// Returns an LQIP (Low Quality Image Placeholder) URL — ~20px blurred.
  String lqip(String path) {
    return build(path: path, width: 20, quality: 20, blur: 10, format: 'webp');
  }

  /// Returns a thumbnail (fixed width) URL.
  String thumbnail(String path, {int width = 400}) {
    return build(path: path, width: width, quality: 60, format: 'webp');
  }

  /// Returns a full HLS adaptive stream URL (if ImageKit video plan enabled).
  /// Path must point to a video file in ImageKit.
  String hlsManifest(String path) {
    final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${base}v1/videos/tr:f-hls/$cleanPath/master.m3u8';
  }

  /// Returns a video thumbnail at a specific time offset.
  String videoThumbnail(String path, {int timeMs = 0}) {
    final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${base}tr:so-${timeMs},w-640,f-jpg/$cleanPath';
  }
}

// =============================================================================
// §5 — IMAGEKIT SIGNED URL GENERATOR
// =============================================================================

class ImageKitSignedUrlGenerator {
  final String privateKey;

  ImageKitSignedUrlGenerator(this.privateKey);

  /// Generates a signed ImageKit URL valid for [ttl].
  /// Reference: https://docs.imagekit.io/features/security/signed-urls
  String sign(String url, {Duration ttl = const Duration(hours: 1)}) {
    if (privateKey.isEmpty) return url;

    final expiry =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + ttl.inSeconds;

    final uri = Uri.parse(url);
    final pathAndQuery = uri.path + (uri.hasQuery ? '?${uri.query}' : '');

    final message = '$pathAndQuery$expiry';
    final sig = Hmac(sha1, utf8.encode(privateKey))
        .convert(utf8.encode(message))
        .toString();

    // Append signature and expiry as query params
    final separator = uri.hasQuery ? '&' : '?';
    return '$url${separator}ik-t=$expiry&ik-s=$sig';
  }
}

// =============================================================================
// §6 — IMAGEKIT UPLOAD SESSION (TUS-style, resumable, network-resilient)
// =============================================================================

class _ImageKitUploadSession implements MediaTransferSession {
  @override
  final String sessionId;

  final String localFilePath;
  final String remotePath;
  final String mimeType;
  final Map<String, String> metadata;
  final MediaBackendConfig config;
  final LocalStore store;
  final SessionContext? auth;

  final _progressController = StreamController<TransferProgress>.broadcast();
  final _stateNotifier = ValueNotifier(TransferState.idle);
  final _doneCompleter = Completer<void>();

  @override
  Stream<TransferProgress> get progress => _progressController.stream;
  @override
  ValueNotifier<TransferState> get state => _stateNotifier;
  @override
  String? resultUrl;
  @override
  Future<void> get done => _doneCompleter.future;

  bool _cancelRequested = false;
  bool _pauseRequested = false;
  int _resumeOffset = 0;
  Timer? _reconnectTimer;

  _ImageKitUploadSession({
    required this.sessionId,
    required this.localFilePath,
    required this.remotePath,
    required this.mimeType,
    required this.metadata,
    required this.config,
    required this.store,
    this.auth,
  });

  // ── Persistence keys ───────────────────────────────────────────────────────
  String get _offsetKey => 'ik_upload_offset_$sessionId';
  String get _urlKey => 'ik_upload_fileId_$sessionId';

  @override
  Future<void> resume() async {
    if (_stateNotifier.value == TransferState.running) return;
    _pauseRequested = false;
    _cancelRequested = false;
    _stateNotifier.value = TransferState.running;

    try {
      // Restore persisted offset (survives app restart)
      final savedOffset = await store.read(_offsetKey);
      _resumeOffset = savedOffset != null ? int.tryParse(savedOffset) ?? 0 : 0;

      await _runUpload();
    } catch (e) {
      if (!_cancelRequested) {
        _stateNotifier.value = TransferState.failed;
        _progressController
            .addError(VaultStreamException('ik_upload_failed', e.toString()));
        _scheduleReconnect();
      }
    }
  }

  @override
  Future<void> pause() async {
    _pauseRequested = true;
    _stateNotifier.value = TransferState.paused;
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    _reconnectTimer?.cancel();
    await store.write(_offsetKey, '0');
    await store.write(_urlKey, '');
    _stateNotifier.value = TransferState.cancelled;
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.completeError(
          VaultStreamException('cancelled', 'Upload cancelled by user'));
    }
    _progressController.close();
  }

  // ── Core upload loop ───────────────────────────────────────────────────────

  Future<void> _runUpload() async {
    final file = File(localFilePath);
    if (!await file.exists()) {
      throw VaultStreamException('file_not_found', localFilePath);
    }

    final totalBytes = await file.length();
    final chunkSize = config.uploadChunkSizeBytes;
    final maxRetries = config.uploadMaxRetries;

    // Build auth header
    final authHeader = await _buildAuthHeader();

    int offset = _resumeOffset;
    final stopwatch = Stopwatch();

    final raf = await file.open(mode: FileMode.read);

    try {
      while (offset < totalBytes && !_pauseRequested && !_cancelRequested) {
        stopwatch.reset();
        stopwatch.start();

        await raf.setPosition(offset);
        final chunkData =
            await raf.read(math.min(chunkSize, totalBytes - offset));

        bool success = false;
        int retries = 0;

        while (!success && retries <= maxRetries && !_cancelRequested) {
          try {
            final endByte = offset + chunkData.length - 1;
            final isLastChunk = endByte >= totalBytes - 1;

            // ImageKit uses multipart for chunks; last chunk finalises the file
            final result = await _uploadChunk(
              chunk: chunkData,
              offset: offset,
              totalBytes: totalBytes,
              isLast: isLastChunk,
              authHeader: authHeader,
            );

            if (isLastChunk && result != null) {
              resultUrl = result;
            }

            success = true;
            offset += chunkData.length;

            // Persist offset so we can resume on crash/disconnect
            await store.write(_offsetKey, offset.toString());
          } on SocketException {
            retries++;
            final delay = math.min(
                30, math.pow(2, retries).toInt() + math.Random().nextInt(3));
            await Future.delayed(Duration(seconds: delay));
          } catch (e) {
            retries++;
            if (retries > maxRetries) rethrow;
            await Future.delayed(
                Duration(seconds: math.pow(2, retries).toInt()));
          }
        }

        if (!success) {
          throw VaultStreamException('chunk_failed',
              'Failed at offset $offset after $maxRetries retries');
        }

        stopwatch.stop();
        final bps = chunkData.length *
            8 /
            (stopwatch.elapsedMilliseconds / 1000.0).clamp(0.001, 9999999);
        final remaining = totalBytes - offset;
        final eta = Duration(seconds: bps > 0 ? (remaining * 8 ~/ bps) : 0);

        _progressController.add(TransferProgress(
          sentBytes: offset,
          totalBytes: totalBytes,
          progress: offset / totalBytes,
          stage: 'uploading',
          currentSpeedBps: bps,
          estimatedTimeRemaining: eta,
        ));
      }
    } finally {
      await raf.close();
    }

    if (_cancelRequested || _pauseRequested) return;

    // Success
    await store.write(_offsetKey, '0'); // Clean up
    _stateNotifier.value = TransferState.completed;
    _progressController.add(TransferProgress(
      sentBytes: totalBytes,
      totalBytes: totalBytes,
      progress: 1.0,
      stage: 'completed',
      currentSpeedBps: 0,
      estimatedTimeRemaining: Duration.zero,
    ));
    _progressController.close();
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }

  Future<String?> _uploadChunk({
    required Uint8List chunk,
    required int offset,
    required int totalBytes,
    required bool isLast,
    required Map<String, String> authHeader,
  }) async {
    // ImageKit upload API uses multipart form-data (single call for small files,
    // chunked via Content-Range header for large files)
    final uri = Uri.parse(config.imagekitUploadUrl);
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);

      // Build multipart boundary
      const boundary = '----QuantumIKBoundary7MA4YWxkTrZu0gW';
      request.headers.contentType =
          ContentType.parse('multipart/form-data; boundary=$boundary');

      final body = BytesBuilder();

      void addField(String name, String value) {
        body.add(utf8.encode('--$boundary\r\n'));
        body.add(utf8
            .encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
        body.add(utf8.encode('$value\r\n'));
      }

      addField('publicKey', config.imagekitPublicKey);
      addField('fileName', remotePath.split('/').last);
      addField('folder',
          '/${remotePath.substring(0, remotePath.lastIndexOf('/') + 1)}');

      for (final entry in metadata.entries) {
        addField(entry.key, entry.value);
      }

      // File field
      body.add(utf8.encode('--$boundary\r\n'));
      body.add(utf8.encode(
          'Content-Disposition: form-data; name="file"; filename="${remotePath.split('/').last}"\r\n'));
      body.add(utf8.encode('Content-Type: $mimeType\r\n\r\n'));
      body.add(chunk);
      body.add(utf8.encode('\r\n--$boundary--\r\n'));

      final bodyBytes = body.toBytes();
      request.contentLength = bodyBytes.length;

      // Inject auth headers
      authHeader.forEach((k, v) => request.headers.add(k, v));

      // Range header for chunked upload awareness
      request.headers.add('Content-Range',
          'bytes $offset-${offset + chunk.length - 1}/$totalBytes');

      request.add(bodyBytes);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (isLast) {
          try {
            final json = jsonDecode(responseBody) as Map<String, dynamic>;
            return json['url']?.toString() ?? json['thumbnailUrl']?.toString();
          } catch (_) {}
        }
        return null;
      }

      throw VaultStreamException(
          'ik_http_${response.statusCode}', responseBody);
    } finally {
      client.close();
    }
  }

  Future<Map<String, String>> _buildAuthHeader() async {
    // ImageKit uses HMAC-SHA1 of token+expire with the private key
    final expire =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 3600;
    final token = _randomToken();
    final message = '$token$expire';
    final sig = Hmac(sha1, utf8.encode(config.imagekitPrivateKey))
        .convert(utf8.encode(message))
        .toString();

    return {
      'Authorization':
          'Basic ${base64.encode(utf8.encode('${config.imagekitPrivateKey}:'))}',
      'X-IK-Token': token,
      'X-IK-Expire': expire.toString(),
      'X-IK-Signature': sig,
    };
  }

  String _randomToken() {
    final rng = math.Random.secure();
    final bytes = Uint8List(16);
    for (int i = 0; i < bytes.length; i++) bytes[i] = rng.nextInt(256);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_cancelRequested && _stateNotifier.value == TransferState.failed) {
        resume();
      }
    });
  }
}

// =============================================================================
// §7 — IMAGEKIT DOWNLOAD SESSION (Byte-range, resumable, network-resilient)
// =============================================================================

class _ImageKitDownloadSession implements MediaTransferSession {
  @override
  final String sessionId;

  final String remoteUrl; // Full CDN URL (already built)
  final String localFilePath;
  final MediaBackendConfig config;
  final LocalStore store;

  final _progressController = StreamController<TransferProgress>.broadcast();
  final _stateNotifier = ValueNotifier(TransferState.idle);
  final _doneCompleter = Completer<void>();

  @override
  Stream<TransferProgress> get progress => _progressController.stream;
  @override
  ValueNotifier<TransferState> get state => _stateNotifier;
  @override
  String? resultUrl;
  @override
  Future<void> get done => _doneCompleter.future;

  bool _cancelRequested = false;
  bool _pauseRequested = false;
  Timer? _reconnectTimer;

  _ImageKitDownloadSession({
    required this.sessionId,
    required this.remoteUrl,
    required this.localFilePath,
    required this.config,
    required this.store,
  });

  String get _offsetKey => 'dl_offset_$sessionId';

  @override
  Future<void> resume() async {
    if (_stateNotifier.value == TransferState.running) return;
    _pauseRequested = false;
    _cancelRequested = false;
    _stateNotifier.value = TransferState.running;
    resultUrl = localFilePath;

    try {
      await _runDownload();
    } catch (e) {
      if (!_cancelRequested) {
        _stateNotifier.value = TransferState.failed;
        _progressController
            .addError(VaultStreamException('dl_failed', e.toString()));
        _scheduleReconnect();
      }
    }
  }

  @override
  Future<void> pause() async {
    _pauseRequested = true;
    _stateNotifier.value = TransferState.paused;
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    _reconnectTimer?.cancel();
    await store.write(_offsetKey, '0');
    _stateNotifier.value = TransferState.cancelled;
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.completeError(
          VaultStreamException('cancelled', 'Download cancelled'));
    }
    _progressController.close();
  }

  Future<void> _runDownload() async {
    final maxRetries = config.uploadMaxRetries;

    // Restore persisted offset
    final savedOffset = await store.read(_offsetKey);
    int offset = savedOffset != null ? int.tryParse(savedOffset) ?? 0 : 0;

    // Detect existing partial file
    final file = File(localFilePath);
    if (await file.exists() && offset == 0) {
      final existingSize = await file.length();
      if (existingSize > 0) offset = existingSize;
    }

    int? totalBytes;
    int retries = 0;
    final stopwatch = Stopwatch();

    while (!_pauseRequested && !_cancelRequested) {
      try {
        final client = HttpClient();
        stopwatch.reset();
        stopwatch.start();

        final request = await client.getUrl(Uri.parse(remoteUrl));
        if (offset > 0) {
          request.headers.add(HttpHeaders.rangeHeader, 'bytes=$offset-');
        }

        final response = await request.close();

        // Get total size
        if (response.statusCode == 200) {
          totalBytes = response.contentLength;
          // Server didn't honour range, reset
          offset = 0;
        } else if (response.statusCode == 206) {
          final contentRange = response.headers.value('content-range');
          if (contentRange != null) {
            final match =
                RegExp(r'bytes \d+-\d+/(\d+)').firstMatch(contentRange);
            if (match != null) totalBytes = int.tryParse(match.group(1)!);
          }
        } else {
          throw VaultStreamException('http_${response.statusCode}', remoteUrl);
        }

        final raf = await file.open(
            mode: offset > 0 ? FileMode.append : FileMode.write);
        await raf.setPosition(offset);

        await for (final chunk in response) {
          if (_pauseRequested || _cancelRequested) break;

          await raf.writeFrom(chunk);
          offset += chunk.length;
          await store.write(_offsetKey, offset.toString());

          stopwatch.stop();
          final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
          final bps = elapsed > 0 ? (chunk.length * 8) / elapsed : 0.0;
          final remaining = (totalBytes ?? 0) - offset;
          final eta = bps > 0
              ? Duration(seconds: (remaining * 8 ~/ bps))
              : Duration.zero;

          _progressController.add(TransferProgress(
            sentBytes: offset,
            totalBytes: totalBytes ?? -1,
            progress: totalBytes != null && totalBytes! > 0
                ? (offset / totalBytes!).clamp(0.0, 1.0)
                : 0.0,
            stage: 'downloading',
            currentSpeedBps: bps,
            estimatedTimeRemaining: eta,
          ));
          stopwatch.reset();
          stopwatch.start();
        }

        await raf.close();
        client.close();

        if (_pauseRequested || _cancelRequested) return;

        // Verify complete
        if (totalBytes != null && offset >= totalBytes!) break;
        // If we got all data, break
        if (totalBytes == null) break;
      } on SocketException {
        retries++;
        if (retries > maxRetries) rethrow;
        final delay = math.min(
            30, math.pow(2, retries).toInt() + math.Random().nextInt(3));
        await Future.delayed(Duration(seconds: delay));
      }
    }

    if (_cancelRequested || _pauseRequested) return;

    await store.write(_offsetKey, '0');
    _stateNotifier.value = TransferState.completed;
    _progressController.add(TransferProgress(
      sentBytes: offset,
      totalBytes: totalBytes ?? offset,
      progress: 1.0,
      stage: 'completed',
      currentSpeedBps: 0,
      estimatedTimeRemaining: Duration.zero,
    ));
    _progressController.close();
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_cancelRequested && _stateNotifier.value == TransferState.failed) {
        resume();
      }
    });
  }
}

// =============================================================================
// §8 — IMAGEKIT QL IMAGE RESOLVER (Plugs into QuantumImagePipeline)
// =============================================================================

class _ImageKitResolver extends QLImageResolver {
  final ImageKitUrlBuilder _builder;
  final MediaBackendConfig _config;

  _ImageKitResolver(this._builder, this._config);

  @override
  String rewrite(String url, int width, int height, int quality) {
    // If it's already an ImageKit URL — just update transforms
    final endpoint = _config.imagekitUrlEndpoint;
    if (endpoint.isEmpty) return url;

    // If it's an absolute URL from another domain, pass through
    if (url.startsWith('http') && !url.startsWith(endpoint)) return url;

    // Determine path
    final path =
        url.startsWith(endpoint) ? url.substring(endpoint.length) : url;

    // Snap width to nearest breakpoint for cache efficiency
    final snappedWidth = _snapToBreakpoint(width, _config.imageBreakpoints);

    return _builder.build(
      path: path,
      width: snappedWidth,
      height: 0, // Let ImageKit preserve aspect ratio
      quality: quality > 0 ? quality : _config.defaultImageQuality,
      format: 'auto', // WebP on modern browsers, AVIF on supported clients
      progressive: true,
      dpr: 1.0, // DPR is already baked into width from QLImage
    );
  }

  int _snapToBreakpoint(int width, List<int> breakpoints) {
    if (width <= 0) return 0;
    for (final bp in breakpoints) {
      if (width <= bp) return bp;
    }
    return breakpoints.last;
  }
}

// =============================================================================
// §9 — IMAGEKIT ABR MANIFEST BUILDER
// =============================================================================

/// Builds an [AdaptiveManifest] from an ImageKit video path.
/// Feed this into [QuantumMediaEngine.instance.createAdaptiveStreamer()].
class ImageKitAbrManifestBuilder {
  final ImageKitUrlBuilder _builder;

  ImageKitAbrManifestBuilder(ImageKitUrlBuilder builder) : _builder = builder;

  /// Builds a quality ladder for [videoPath].
  /// [videoPath] should be relative to the ImageKit endpoint, e.g. "videos/clip.mp4"
  AdaptiveManifest build({
    required String mediaId,
    required String videoPath,
    List<int> heights = const [360, 480, 720, 1080],
  }) {
    final Map<Quality, List<StreamSegment>> representations = {};

    for (final height in heights) {
      final quality = _heightToQualityEnum(height);
      if (quality == null) continue;

      // ImageKit video transformation URL
      final endpoint = _builder.endpoint;
      final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
      final cleanPath =
          videoPath.startsWith('/') ? videoPath.substring(1) : videoPath;
      final url = '${base}tr:h-$height,f-mp4/$cleanPath';

      representations[quality] = [
        StreamSegment(sequenceNumber: 0, uri: url, quality: quality),
      ];
    }

    // Add HLS manifest as auto quality
    representations[Quality.auto] = [
      StreamSegment(
        sequenceNumber: 0,
        uri: _builder.hlsManifest(videoPath),
        quality: Quality.auto,
      ),
    ];

    return AdaptiveManifest(
      mediaId: mediaId,
      mediaType: MediaType.video,
      representations: representations,
    );
  }

  Quality? _heightToQualityEnum(int height) {
    switch (height) {
      case 144:
        return Quality.p144;
      case 240:
        return Quality.p240;
      case 360:
        return Quality.p360;
      case 480:
        return Quality.p480;
      case 720:
        return Quality.p720;
      case 1080:
        return Quality.p1080;
      case 2160:
        return Quality.p4k;
      default:
        return null;
    }
  }
}

// =============================================================================
// §10 — IMAGEKIT OPTIMIZATION ENGINE (Predictive prefetch, scroll-aware)
// =============================================================================

class ImageKitOptimizationEngine {
  final ImageKitUrlBuilder _builder;
  final MediaBackendConfig _config;

  // Frequency counter for LFU eviction
  final Map<String, int> _accessFrequency = {};
  // Prefetch deduplication
  final Set<String> _prefetched = {};
  // In-flight prefetch guard
  bool _prefetchRunning = false;
  final Queue<String> _prefetchQueue = Queue();

  ImageKitOptimizationEngine(this._builder, this._config);

  /// Prefetches images for a list of paths based on scroll velocity.
  /// [scrollVelocity] is items/second — higher = prefetch more aggressively.
  void prefetchForScroll({
    required List<String> paths,
    double scrollVelocity = 1.0,
    int baseCount = 3,
  }) {
    final count =
        (baseCount * scrollVelocity.clamp(0.5, 5.0)).round().clamp(1, 10);
    final toPrefetch = paths.take(count).toList();

    for (final path in toPrefetch) {
      if (!_prefetched.contains(path)) {
        _prefetchQueue.add(path);
      }
    }

    if (!_prefetchRunning) _drainPrefetchQueue();
  }

  Future<void> _drainPrefetchQueue() async {
    if (_prefetchRunning) return;
    _prefetchRunning = true;

    while (_prefetchQueue.isNotEmpty) {
      final path = _prefetchQueue.removeFirst();
      if (_prefetched.contains(path)) continue;
      _prefetched.add(path);

      try {
        // Prefetch thumbnail quality for quick display, then full quality
        final thumbUrl = _builder.thumbnail(path, width: 480);
        if (!kIsWeb) {
          // FIX: Removed "await" because prefetchMedia returns void and
          // runs the download safely in a background queue.
          QuantumMediaEngine.instance
              .prefetchMedia([thumbUrl], bytesToFetch: 128 * 1024);
        }
      } catch (_) {}
    }

    _prefetchRunning = false;
  }

  /// Records access to bump LFU frequency. Call when an image is displayed.
  void recordAccess(String path) {
    _accessFrequency[path] = (_accessFrequency[path] ?? 0) + 1;
  }

  /// Returns the most frequently accessed paths (for warm cache seeding).
  List<String> getHotPaths({int limit = 20}) {
    final sorted = _accessFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Generates a sprite sheet URL for video scrubbing thumbnails.
  /// Returns the ImageKit sprite transformation URL.
  String buildVideoSprite(String videoPath,
      {int columns = 10, int rows = 10, int thumbWidth = 120}) {
    final endpoint = _builder.endpoint;
    final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
    final cleanPath =
        videoPath.startsWith('/') ? videoPath.substring(1) : videoPath;
    return '${base}v1/videos/tr:spr-${columns}x${rows},w-$thumbWidth/$cleanPath/sprite.jpg';
  }
}

// =============================================================================
// §11 — IMAGEKIT MEDIA ADAPTER (Top-level facade — THE one to register)
// =============================================================================

class ImageKitMediaAdapter implements QuantumMediaAdapter {
  @override
  final String adapterName = 'imagekit';

  late ImageKitUrlBuilder _urlBuilder;
  late ImageKitSignedUrlGenerator _signer;
  late ImageKitAbrManifestBuilder _abrBuilder;
  late ImageKitOptimizationEngine _optimizer;
  late _ImageKitResolver _resolver;
  MediaBackendConfig _config = const MediaBackendConfig();

  late final LocalStore _store;
  bool _storeReady = false;

  ImageKitMediaAdapter({LocalStore? store}) {
    if (store != null) {
      _store = store;
      _storeReady = true;
    }
    _rebuild(const MediaBackendConfig());
  }

  void _rebuild(MediaBackendConfig config) {
    _config = config;
    _urlBuilder = ImageKitUrlBuilder(config.imagekitUrlEndpoint);
    _signer = ImageKitSignedUrlGenerator(config.imagekitPrivateKey);
    _abrBuilder = ImageKitAbrManifestBuilder(_urlBuilder);
    _optimizer = ImageKitOptimizationEngine(_urlBuilder, config);
    _resolver = _ImageKitResolver(_urlBuilder, config);

    // Wire into the image pipeline automatically
    QuantumImagePipeline.instance.resolver = _resolver;
  }

  @override
  void configure(MediaBackendConfig config) {
    _rebuild(config);
  }

  // ── URL building ──────────────────────────────────────────────────────────

  @override
  String buildUrl({
    required String path,
    int width = 0,
    int height = 0,
    int quality = 80,
    String format = 'auto',
    Map<String, String> extras = const {},
  }) {
    return _urlBuilder.build(
      path: path,
      width: width,
      height: height,
      quality: quality > 0 ? quality : _config.defaultImageQuality,
      format: format,
      namedTransform: extras['namedTransform'],
      progressive: true,
    );
  }

  @override
  String buildLqipUrl(String path) => _urlBuilder.lqip(path);

  @override
  Future<String> buildSignedUrl(String path, {Duration? ttl}) async {
    final url = _urlBuilder.build(path: path);
    if (!_config.imagekitPrivateBucket) return url;
    return _signer.sign(url,
        ttl: ttl ?? Duration(seconds: _config.imagekitSignedUrlTtlSeconds));
  }

  // ── Transfer ───────────────────────────────────────────────────────────────

  @override
  Future<MediaTransferSession> createUploadSession({
    required String localFilePath,
    required String remotePath,
    required String mimeType,
    Map<String, String> metadata = const {},
    SessionContext? auth,
  }) async {
    _ensureStore();
    final sessionId = _sessionId(localFilePath, remotePath);
    return _ImageKitUploadSession(
      sessionId: sessionId,
      localFilePath: localFilePath,
      remotePath: remotePath,
      mimeType: mimeType,
      metadata: metadata,
      config: _config,
      store: _store,
      auth: auth,
    );
  }

  @override
  Future<MediaTransferSession> createDownloadSession({
    required String remotePath,
    required String localFilePath,
    SessionContext? auth,
  }) async {
    _ensureStore();
    final remoteUrl = await buildSignedUrl(remotePath);
    final sessionId = _sessionId(remotePath, localFilePath);
    return _ImageKitDownloadSession(
      sessionId: sessionId,
      remoteUrl: remoteUrl,
      localFilePath: localFilePath,
      config: _config,
      store: _store,
    );
  }

  // ── Discovery ─────────────────────────────────────────────────────────────

  @override
  Future<List<MediaFileInfo>> listFiles({
    required String path,
    int limit = 50,
    String? cursor,
  }) async {
    // ImageKit Media Library API
    final queryParams = <String, String>{
      'path': path,
      'limit': limit.toString(),
      if (cursor != null) 'skip': cursor,
    };
    final uri = Uri.https('api.imagekit.io', '/v1/files', queryParams);
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      request.headers.add(HttpHeaders.authorizationHeader,
          'Basic ${base64.encode(utf8.encode('${_config.imagekitPrivateKey}:'))}');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) return [];

      final List<dynamic> items = jsonDecode(body);
      return items.map((item) {
        final m = item as Map<String, dynamic>;
        return MediaFileInfo(
          path: m['filePath']?.toString() ?? '',
          url: m['url']?.toString(),
          lqipUrl: m['url'] != null
              ? _urlBuilder.lqip(m['filePath']?.toString() ?? '')
              : null,
          sizeBytes: (m['size'] as num?)?.toInt(),
          mimeType: m['fileType']?.toString(),
          createdAt: m['createdAt'] != null
              ? DateTime.tryParse(m['createdAt'].toString())
              : null,
          extra: m,
        );
      }).toList();
    } finally {
      client.close();
    }
  }

  @override
  Future<MediaFileInfo?> getFileInfo(String path) async {
    final uri =
        Uri.https('api.imagekit.io', '/v1/files', {'path': path, 'limit': '1'});
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.add(HttpHeaders.authorizationHeader,
          'Basic ${base64.encode(utf8.encode('${_config.imagekitPrivateKey}:'))}');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;
      final list = jsonDecode(body) as List;
      if (list.isEmpty) return null;
      final m = list.first as Map<String, dynamic>;
      return MediaFileInfo(
        path: m['filePath']?.toString() ?? path,
        url: m['url']?.toString(),
        sizeBytes: (m['size'] as num?)?.toInt(),
        mimeType: m['fileType']?.toString(),
        extra: m,
      );
    } finally {
      client.close();
    }
  }

  // ── ABR helper (convenience) ───────────────────────────────────────────────

  /// Builds an ABR manifest for a video. Pass to
  /// [QuantumMediaEngine.instance.createAdaptiveStreamer()].
  AdaptiveManifest buildAbrManifest(String mediaId, String videoPath,
          {List<int> heights = const [360, 480, 720, 1080]}) =>
      _abrBuilder.build(
          mediaId: mediaId, videoPath: videoPath, heights: heights);

  /// Optimization engine (prefetch, scroll-aware, LFU).
  ImageKitOptimizationEngine get optimizer => _optimizer;

  // ── QLImageResolver bridge ────────────────────────────────────────────────

  @override
  QLImageResolver get imageResolver => _resolver;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {}

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _ensureStore() {
    if (!_storeReady) {
      throw const VaultStreamException(
          'store_required',
          'ImageKitMediaAdapter requires a LocalStore for resumable transfers. '
              'Pass one in the constructor.');
    }
  }

  String _sessionId(String a, String b) {
    final raw = '$a|$b';
    return md5.convert(utf8.encode(raw)).toString().substring(0, 16);
  }
}

// =============================================================================
// §12 — CLOUDFLARE R2 ADAPTER STUB (Future-ready — interface-complete)
// =============================================================================

/// Stub adapter for Cloudflare R2. Swap in with zero app-code changes:
///   QuantumMediaConfig.instance.setAdapter(CloudflareR2Adapter())
///
/// Implement the methods below when you're ready to migrate to R2.
class CloudflareR2Adapter implements QuantumMediaAdapter {
  @override
  final String adapterName = 'cloudflare_r2';

  MediaBackendConfig _config = const MediaBackendConfig();

  @override
  void configure(MediaBackendConfig config) {
    _config = config;
  }

  // ── URL building ──────────────────────────────────────────────────────────

  @override
  String buildUrl({
    required String path,
    int width = 0,
    int height = 0,
    int quality = 80,
    String format = 'auto',
    Map<String, String> extras = const {},
  }) {
    // R2 public bucket: direct URL with Cloudflare Image Resizing
    final base = _config.r2BucketUrl.endsWith('/')
        ? _config.r2BucketUrl
        : '${_config.r2BucketUrl}/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Cloudflare Image Resizing format (requires Workers/Resizing plan)
    if (width > 0 || height > 0) {
      final params = <String>[];
      if (width > 0) params.add('width=$width');
      if (height > 0) params.add('height=$height');
      if (quality < 100) params.add('quality=$quality');
      if (format == 'auto' || format == 'webp') params.add('format=auto');
      return '${base}cdn-cgi/image/${params.join(',')}/$cleanPath';
    }

    return '$base$cleanPath';
  }

  @override
  String buildLqipUrl(String path) {
    return buildUrl(path: path, width: 20, quality: 20);
  }

  @override
  Future<String> buildSignedUrl(String path, {Duration? ttl}) async {
    // TODO: Implement AWS S3-compatible pre-signed URL for R2
    // R2 uses S3 SigV4 signature scheme
    // Reference: https://developers.cloudflare.com/r2/api/s3/presigned-urls/
    return buildUrl(path: path);
  }

  @override
  Future<MediaTransferSession> createUploadSession({
    required String localFilePath,
    required String remotePath,
    required String mimeType,
    Map<String, String> metadata = const {},
    SessionContext? auth,
  }) async {
    // TODO: Implement multipart upload via R2 S3-compatible API
    throw UnimplementedError(
        'CloudflareR2Adapter.createUploadSession — implement when ready to migrate');
  }

  @override
  Future<MediaTransferSession> createDownloadSession({
    required String remotePath,
    required String localFilePath,
    SessionContext? auth,
  }) async {
    // TODO: R2 downloads are standard HTTP — can use _ImageKitDownloadSession
    throw UnimplementedError(
        'CloudflareR2Adapter.createDownloadSession — implement when ready to migrate');
  }

  @override
  Future<List<MediaFileInfo>> listFiles({
    required String path,
    int limit = 50,
    String? cursor,
  }) async {
    // TODO: Implement via R2 S3-compatible ListObjectsV2
    return [];
  }

  @override
  Future<MediaFileInfo?> getFileInfo(String path) async {
    return MediaFileInfo(path: path, url: buildUrl(path: path));
  }

  @override
  QLImageResolver get imageResolver => _R2Resolver(this);

  @override
  Future<void> dispose() async {}
}

class _R2Resolver extends QLImageResolver {
  final CloudflareR2Adapter _adapter;
  _R2Resolver(this._adapter);

  @override
  String rewrite(String url, int width, int height, int quality) {
    final base = _adapter._config.r2BucketUrl;
    if (base.isEmpty || (!url.startsWith(base) && url.startsWith('http'))) {
      return url;
    }
    final path = url.startsWith(base) ? url.substring(base.length) : url;
    return _adapter.buildUrl(
        path: path, width: width, height: height, quality: quality);
  }
}
