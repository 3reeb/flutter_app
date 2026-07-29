// =============================================================================
// supabase_setup.dart
// Initialization & Configuration for Supabase Integration
// =============================================================================

import 'dart:async';
import 'package:quantum_layout/src/plugins/adapters/quantum_supabase_adapters.dart';
import 'package:quantum_layout/src/plugins/quantum_auth_engine.dart';
import 'package:quantum_layout/src/plugins/quantum_api_engine.dart';
import 'package:quantum_layout/src/plugins/quantum_media_api.dart';
import 'package:quantum_layout/src/plugins/quantum_socket_engine.dart';

// =============================================================================
// ENVIRONMENT CONFIGURATION
// =============================================================================

class SupabaseEnvironment {
  static const String projectUrlKey = 'SUPABASE_PROJECT_URL';
  static const String anonKeyKey = 'SUPABASE_ANON_KEY';
  static const String serviceKeyKey = 'SUPABASE_SERVICE_KEY';
  static const String bucketNameKey = 'SUPABASE_BUCKET_NAME';
  static const String enableRealtimeKey = 'SUPABASE_ENABLE_REALTIME';

  /// Load configuration from environment variables or config file
  static SupabaseConfig loadFromEnvironment({
    required String projectUrl,
    required String anonKey,
    required String serviceKey,
    String bucketName = 'public',
    bool enableRealtime = true,
  }) {
    return SupabaseConfig(
      projectUrl: projectUrl,
      anonKey: anonKey,
      serviceKey: serviceKey,
      bucketName: bucketName,
      enableRealtimeSync: enableRealtime,
    );
  }

  /// Load from a JSON config file (e.g., assets/config/supabase.json)
  static SupabaseConfig loadFromJson(Map<String, dynamic> json) {
    return SupabaseConfig(
      projectUrl: json['projectUrl'] as String,
      anonKey: json['anonKey'] as String,
      serviceKey: json['serviceKey'] as String,
      bucketName: json['bucketName'] as String? ?? 'public',
      enableRealtimeSync: json['enableRealtime'] as bool? ?? true,
    );
  }
}

// =============================================================================
// ENGINE REGISTRATION
// =============================================================================

class SupabaseEngineRegistry {
  late final SupabaseConfig config;
  late final SupabaseAuthDriver authDriver;
  late final SupabaseVaultDriver vaultDriver;
  late final SupabaseStorageDriver storageDriver;
  late final SupabaseRealtimeDriver realtimeDriver;

  Future<void> initialize(SupabaseConfig cfg) async {
    config = cfg;

    // Initialize all drivers
    authDriver = SupabaseAuthDriver(config: config);
    await authDriver.initialize({});

    vaultDriver = SupabaseVaultDriver(config: config);
    await vaultDriver.initialize({});

    storageDriver = SupabaseStorageDriver(config: config);
    await storageDriver.initialize({});

    realtimeDriver = SupabaseRealtimeDriver(config: config);
    await realtimeDriver.initialize({});
  }

  /// Get a specific driver by type
  AuthDriver getAuthDriver() => authDriver;
  VaultDriver getVaultDriver() => vaultDriver;
  MediaDriver getStorageDriver() => storageDriver;
  SocketDriver getRealtimeDriver() => realtimeDriver;
}

// =============================================================================
// COMMON PATTERNS & UTILITIES
// =============================================================================

class SupabaseQueries {
  final SupabaseVaultDriver driver;
  final DriverContext context;

  SupabaseQueries({required this.driver, required this.context});

  /// Query with authentication filter (only user's own data)
  Future<ApiResult<List<dynamic>>> queryUserData(
    String table,
    String userIdField,
  ) async {
    final filter = QueryFilter(
      where: {userIdField: context.session.userId ?? ''},
      select: ['*'],
    );

    return driver.query(
      table,
      filter,
      context,
      const QueryPolicy(isolateByUser: true),
    );
  }

  /// Query with pagination
  Future<ApiResult<List<dynamic>>> queryPaginated(
    String table, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final filter = QueryFilter(
      where: {},
      limit: pageSize,
      offset: (page - 1) * pageSize,
      select: ['*'],
    );

    return driver.query(
      table,
      filter,
      context,
      const QueryPolicy(cachePolicy: CachePolicyMode.staleWhileRevalidate),
    );
  }

  /// Insert with automatic timestamp and user ID
  Future<ApiResult<Map<String, dynamic>>> insertWithMetadata(
    String table,
    Map<String, dynamic> data, {
    bool addUserId = true,
    bool addTimestamp = true,
  }) async {
    final payload = {...data};

    if (addUserId && context.session.userId != null) {
      payload['user_id'] = context.session.userId;
    }

    if (addTimestamp) {
      payload['created_at'] = DateTime.now().toIso8601String();
      payload['updated_at'] = DateTime.now().toIso8601String();
    }

    return driver.insert(table, payload, context);
  }

  /// Soft delete (mark as deleted instead of removing)
  Future<ApiResult<Map<String, dynamic>>> softDelete(
    String table,
    String id,
  ) async {
    return driver.update(
      table,
      id,
      {
        'deleted_at': DateTime.now().toIso8601String(),
      },
      context,
    );
  }
}

// =============================================================================
// REALTIME SUBSCRIPTIONS
// =============================================================================

class SupabaseRealtimeSubscriptions {
  final SupabaseRealtimeDriver driver;
  final DriverContext context;
  final Map<String, StreamSubscription> _subscriptions = {};

  SupabaseRealtimeSubscriptions({
    required this.driver,
    required this.context,
  });

  /// Subscribe to table changes
  Future<void> subscribeToTable(
    String table,
    Future<void> Function(SocketMessage) onMessage,
  ) async {
    final filter = SocketFilter(where: {});
    await driver.subscribe(table, filter, context);

    final sub = driver.messages(table).listen((message) {
      onMessage(message);
    });

    _subscriptions[table] = sub;
  }

  /// Subscribe with filter
  Future<void> subscribeFiltered(
    String table,
    Map<String, String> filter,
    Future<void> Function(SocketMessage) onMessage,
  ) async {
    final socketFilter = SocketFilter(where: filter);
    await driver.subscribe(table, socketFilter, context);

    final sub = driver.messages(table).listen((message) {
      onMessage(message);
    });

    _subscriptions[table] = sub;
  }

  /// Unsubscribe from a table
  Future<void> unsubscribeFromTable(String table) async {
    await driver.unsubscribe(table);
    await _subscriptions[table]?.cancel();
    _subscriptions.remove(table);
  }

  /// Unsubscribe from all
  Future<void> unsubscribeAll() async {
    for (final table in _subscriptions.keys.toList()) {
      await unsubscribeFromTable(table);
    }
  }

  /// Cleanup
  Future<void> dispose() async {
    await unsubscribeAll();
    await driver.close();
  }
}

// =============================================================================
// STORAGE HELPERS
// =============================================================================

class SupabaseStorageHelper {
  final SupabaseStorageDriver driver;
  final DriverContext context;

  SupabaseStorageHelper({required this.driver, required this.context});

  /// Upload with automatic folder organization
  Future<MediaUploadResult> uploadWithPath(
    String fileName,
    Uint8List data, {
    String folder = 'uploads',
    String? contentType,
  }) async {
    final path = '$folder/${context.session.userId}';
    return driver.upload(
      path,
      data,
      context,
      contentType: contentType,
    );
  }

  /// Generate a public URL
  String getPublicUrl(String path, String bucketName) {
    return '${driver.config.storageUrl}/object/public/$bucketName/$path';
  }

  /// Generate a signed URL (for private files)
  String getSignedUrl(String path, String bucketName) {
    return '${driver.config.storageUrl}/object/sign/$bucketName/$path';
  }
}

// =============================================================================
// BATCH OPERATIONS
// =============================================================================

class SupabaseBatchOperations {
  final SupabaseVaultDriver driver;
  final DriverContext context;

  SupabaseBatchOperations({required this.driver, required this.context});

  /// Insert multiple records
  Future<ApiResult<List<Map<String, dynamic>>>> insertBatch(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    final results = <Map<String, dynamic>>[];

    for (final record in records) {
      final result = await driver.insert(table, record, context);
      if (result.isSuccess && result.data != null) {
        results.add(result.data!);
      }
    }

    return ApiResult.success(results, driverUsed: driver.driverId);
  }

  /// Update multiple records (by ID list)
  Future<ApiResult<void>> updateBatch(
    String table,
    List<String> ids,
    Map<String, dynamic> updateData,
  ) async {
    for (final id in ids) {
      await driver.update(table, id, updateData, context);
    }

    return const ApiResult.success(null);
  }

  /// Delete multiple records
  Future<ApiResult<void>> deleteBatch(String table, List<String> ids) async {
    for (final id in ids) {
      await driver.delete(table, id, context);
    }

    return const ApiResult.success(null);
  }
}

// =============================================================================
// EXAMPLE USAGE
// =============================================================================

class SupabaseExample {
  static Future<void> example() async {
    // 1. Initialize Supabase
    final config = SupabaseEnvironment.loadFromEnvironment(
      projectUrl: 'https://your-project.supabase.co',
      anonKey: 'your-anon-key',
      serviceKey: 'your-service-key',
    );

    final registry = SupabaseEngineRegistry();
    await registry.initialize(config);

    // 2. Authenticate user
    final authDriver = registry.getAuthDriver() as SupabaseAuthDriver;
    final loginResult = await authDriver.login(
      AuthRequest(
        credentials: {
          'email': 'user@example.com',
          'password': 'password123',
        },
      ),
    );

    if (!loginResult.isSuccess) {
      print('Login failed: ${loginResult.error}');
      return;
    }

    final session = loginResult.data!;
    final context = DriverContext(session: session);

    // 3. Query data
    final vaultDriver = registry.getVaultDriver();
    final queries = SupabaseQueries(driver: vaultDriver, context: context);

    final userDataResult = await queries.queryUserData('profiles', 'user_id');
    print('User data: ${userDataResult.data}');

    // 4. Insert data
    final insertResult = await queries.insertWithMetadata(
      'posts',
      {
        'title': 'My First Post',
        'content': 'Hello, Supabase!',
      },
    );

    // 5. Subscribe to realtime changes
    final realtimeDriver = registry.getRealtimeDriver();
    final subscriptions = SupabaseRealtimeSubscriptions(
      driver: realtimeDriver,
      context: context,
    );

    await subscriptions.subscribeToTable('posts', (message) {
      print('Post updated: ${message.payload}');
    });

    // 6. Upload media
    final storageDriver = registry.getStorageDriver();
    final storageHelper = SupabaseStorageHelper(
      driver: storageDriver,
      context: context,
    );

    // Simulate file upload
    // final uploadResult = await storageHelper.uploadWithPath(
    //   'profile-pic.jpg',
    //   imageBytes,
    //   folder: 'avatars',
    //   contentType: 'image/jpeg',
    // );

    print('Setup complete!');
  }
}
