# Supabase Integration Guide

## Overview

This guide covers the complete Supabase integration for the Quantum Layout Engine, including:
- **Authentication** (Email/Password, OTP, OAuth providers)
- **Database Operations** (CRUD, queries, pagination, soft deletes)
- **Real-time Subscriptions** (WebSocket-based live updates)
- **File Storage** (Upload, download, public/signed URLs)
- **SDUI JSON Integration** (Declarative data binding)

## Quick Start

### 1. Installation

```bash
flutter pub get
```

This installs all Supabase dependencies including:
- `supabase_flutter`: Flutter SDK
- `postgrest`: PostgreSQL REST API client
- `realtime_client`: WebSocket client for real-time updates
- `storage_client`: File storage API

### 2. Configuration

Edit `assets/config/supabase.json` with your Supabase credentials:

```json
{
  "projectUrl": "https://your-project.supabase.co",
  "anonKey": "your-anon-key",
  "serviceKey": "your-service-key",
  "bucketName": "public",
  "enableRealtime": true
}
```

Get these from: https://app.supabase.com → Project Settings

### 3. Initialize in Your App

```dart
import 'package:quantum_layout/src/plugins/supabase_setup.dart';

void main() async {
  final config = SupabaseEnvironment.loadFromEnvironment(
    projectUrl: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
    serviceKey: 'your-service-key',
  );

  final registry = SupabaseEngineRegistry();
  await registry.initialize(config);

  runApp(MyApp(registry: registry));
}
```

---

## Authentication

### Email & Password Login

```dart
final authDriver = registry.getAuthDriver() as SupabaseAuthDriver;

final result = await authDriver.login(
  AuthRequest(
    credentials: {
      'email': 'user@example.com',
      'password': 'password123',
    },
  ),
);

if (result.isSuccess) {
  final session = result.data;
  print('User: ${session?.userId}');
}
```

### Register New User

```dart
final result = await authDriver.register(
  AuthRequest(
    credentials: {
      'email': 'newuser@example.com',
      'password': 'password123',
      'userData': {
        'name': 'John Doe',
        'avatar': 'https://example.com/avatar.jpg',
      },
    },
  ),
);
```

### OTP Authentication

```dart
// Request OTP
await authDriver.requestOtp(
  OtpRequest(phoneNumber: '+1234567890'),
);

// Verify OTP
final result = await authDriver.verifyOtp(
  OtpVerification(
    identifier: '+1234567890',
    code: '123456',
  ),
);
```

### Refresh Token

```dart
final refreshed = await authDriver.refresh(currentSession);
if (refreshed.isSuccess) {
  print('New access token: ${refreshed.data?.accessToken}');
}
```

### Logout

```dart
await authDriver.logout(currentSession);
```

---

## Database Operations

### Query Data

```dart
final vaultDriver = registry.getVaultDriver();
final context = DriverContext(session: session);

final filter = QueryFilter(
  where: {'status': 'published'},
  select: ['id', 'title', 'content', 'created_at'],
  limit: 20,
  offset: 0,
);

final result = await vaultDriver.query(
  'posts',
  filter,
  context,
  const QueryPolicy(
    cachePolicy: CachePolicyMode.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  ),
);

print('Posts: ${result.data}');
```

### Using Helper Functions

```dart
final queries = SupabaseQueries(driver: vaultDriver, context: context);

// Get current user's data
final userPosts = await queries.queryUserData('posts', 'user_id');

// Paginated query
final page1 = await queries.queryPaginated('posts', page: 1, pageSize: 20);
final page2 = await queries.queryPaginated('posts', page: 2, pageSize: 20);
```

### Insert Data

```dart
final insertResult = await vaultDriver.insert(
  'posts',
  {
    'title': 'My Blog Post',
    'content': 'Hello, world!',
    'status': 'published',
  },
  context,
);

if (insertResult.isSuccess) {
  print('New post ID: ${insertResult.data?['id']}');
}
```

### Insert with Metadata

```dart
final queries = SupabaseQueries(driver: vaultDriver, context: context);

// Automatically adds user_id, created_at, updated_at
final result = await queries.insertWithMetadata(
  'posts',
  {
    'title': 'Post Title',
    'content': 'Post content',
  },
  addUserId: true,
  addTimestamp: true,
);
```

### Update Data

```dart
final updateResult = await vaultDriver.update(
  'posts',
  'post-id-123',
  {
    'title': 'Updated Title',
    'updated_at': DateTime.now().toIso8601String(),
  },
  context,
);
```

### Delete Data

```dart
// Hard delete
await vaultDriver.delete('posts', 'post-id-123', context);

// Soft delete (recommended)
await queries.softDelete('posts', 'post-id-123');
```

### Batch Operations

```dart
final batch = SupabaseBatchOperations(driver: vaultDriver, context: context);

// Insert multiple records
final newPosts = [
  {'title': 'Post 1', 'content': 'Content 1'},
  {'title': 'Post 2', 'content': 'Content 2'},
];
await batch.insertBatch('posts', newPosts);

// Update multiple records
await batch.updateBatch(
  'posts',
  ['id-1', 'id-2', 'id-3'],
  {'status': 'archived'},
);

// Delete multiple records
await batch.deleteBatch('posts', ['id-1', 'id-2']);
```

---

## Real-time Updates

### Subscribe to Table Changes

```dart
final realtimeDriver = registry.getRealtimeDriver();
final subscriptions = SupabaseRealtimeSubscriptions(
  driver: realtimeDriver,
  context: context,
);

// Subscribe to all changes
await subscriptions.subscribeToTable('posts', (message) {
  print('Post updated: ${message.payload}');
});
```

### Subscribe with Filter

```dart
// Subscribe only to current user's posts
await subscriptions.subscribeFiltered(
  'posts',
  {'user_id': context.session.userId ?? ''},
  (message) {
    print('Your post: ${message.payload}');
  },
);
```

### Listen to Specific Events

```dart
final realtimeDriver = registry.getRealtimeDriver();

realtimeDriver.messages('posts').listen((message) {
  if (message.type == 'INSERT') {
    print('New post created');
  } else if (message.type == 'UPDATE') {
    print('Post updated');
  } else if (message.type == 'DELETE') {
    print('Post deleted');
  }
});
```

### Cleanup

```dart
// Unsubscribe from table
await subscriptions.unsubscribeFromTable('posts');

// Unsubscribe from all
await subscriptions.unsubscribeAll();

// Close connection
await subscriptions.dispose();
```

---

## File Storage

### Upload Files

```dart
final storageDriver = registry.getStorageDriver();
final storageHelper = SupabaseStorageHelper(
  driver: storageDriver,
  context: context,
);

// Upload with automatic path organization
final result = await storageHelper.uploadWithPath(
  'profile-pic.jpg',
  imageBytes,
  folder: 'avatars',
  contentType: 'image/jpeg',
);

print('Public URL: ${result.url}');
```

### Get Public URL

```dart
final publicUrl = storageHelper.getPublicUrl(
  'avatars/user-123/profile-pic.jpg',
  'avatars',
);
print(publicUrl);
```

### Get Signed URL (Private Files)

```dart
final signedUrl = storageHelper.getSignedUrl(
  'private/document.pdf',
  'private',
);
// URL expires after a certain time
```

### Download Files

```dart
final fileBytes = await storageDriver.download(
  'avatars/user-123/profile-pic.jpg',
  context,
);
```

### Delete Files

```dart
await storageDriver.delete(
  'avatars/user-123/profile-pic.jpg',
  context,
);
```

---

## SDUI JSON Integration

### Authentication Flow

```json
{
  "type": "button",
  "title": "Sign In",
  "action": {
    "type": "network",
    "method": "POST",
    "endpoint": "/api/auth/login",
    "driver": "supabase_auth",
    "body": {
      "email": "${email}",
      "password": "${password}"
    },
    "onSuccess": {
      "type": "navigate",
      "screen": "home"
    }
  }
}
```

### Data List with Real-time Sync

```json
{
  "type": "list",
  "dataSource": {
    "type": "vault",
    "table": "posts",
    "query": {
      "select": ["id", "title", "content"],
      "limit": 20
    },
    "driver": "supabase_vault",
    "cache": {
      "policy": "staleWhileRevalidate",
      "ttl": 300000
    },
    "realtime": {
      "enabled": true,
      "events": ["INSERT", "UPDATE", "DELETE"],
      "driver": "supabase_realtime"
    }
  },
  "itemBuilder": {
    "type": "card",
    "children": [
      {"type": "text", "value": "${title}"}
    ]
  }
}
```

### Form with Insert

```json
{
  "type": "button",
  "title": "Create Post",
  "action": {
    "type": "network",
    "method": "POST",
    "endpoint": "/api/posts",
    "driver": "supabase_vault",
    "table": "posts",
    "body": {
      "title": "${title}",
      "content": "${content}"
    },
    "onSuccess": {
      "type": "toast",
      "message": "Post created!"
    }
  }
}
```

### File Upload

```json
{
  "type": "button",
  "title": "Upload Photo",
  "action": {
    "type": "media",
    "mediaType": "image",
    "driver": "supabase_storage",
    "bucket": "avatars",
    "path": "${currentUserId}/profile"
  }
}
```

### Offline-Capable Lists

```json
{
  "type": "list",
  "dataSource": {
    "type": "vault",
    "table": "tasks",
    "driver": "supabase_vault",
    "cache": {
      "policy": "cacheFirst",
      "ttl": 600000
    },
    "offlineMode": {
      "enabled": true,
      "syncStrategy": "writeQueue"
    }
  }
}
```

---

## Advanced Topics

### Row Level Security (RLS)

Enable RLS in Supabase Console. Example policy:

```sql
-- Users can only see their own data
CREATE POLICY "Users can see their own posts"
ON posts FOR SELECT
USING (auth.uid() = user_id);

-- Users can only create posts as themselves
CREATE POLICY "Users can create their own posts"
ON posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can only update their own posts
CREATE POLICY "Users can update their own posts"
ON posts FOR UPDATE
USING (auth.uid() = user_id);
```

### Offline Sync Strategy

- **readThrough**: Read from cache, sync on writes
- **writeQueue**: Queue writes, sync when online
- **fullOffline**: Full offline capability with conflict resolution

### Cache Policies

- **cacheFirst**: Use cache, fallback to network
- **networkFirst**: Use network, fallback to cache
- **staleWhileRevalidate**: Use cache + update in background
- **cacheOnly**: Cache only, no network
- **networkOnly**: Network only, no cache

### Performance Tips

1. Use pagination for large datasets
2. Select only needed columns
3. Enable realtime only for essential tables
4. Use appropriate cache policies
5. Implement soft deletes for audit trails
6. Add indexes on frequently queried fields

---

## Error Handling

```dart
final result = await vaultDriver.query(table, filter, context, policy);

if (!result.isSuccess) {
  final error = result.error;
  print('Error: ${error?.code} - ${error?.message}');
  
  // Handle specific errors
  if (error?.code == 'query_error') {
    // Handle query errors
  }
}
```

---

## Troubleshooting

### Connection Issues
- Check your project URL and API keys
- Verify CORS settings in Supabase console
- Ensure firewall allows WebSocket connections

### Authentication Fails
- Verify email/password are correct
- Check email verification status
- Ensure user account exists

### Realtime Not Working
- Enable realtime in Supabase console
- Check WebSocket connection
- Verify table has realtime enabled

### Storage Upload Fails
- Check bucket policies
- Verify file permissions
- Ensure bucket exists

---

## Complete Example App

See `lib/examples/supabase_sdui_examples.json` for full working examples:

1. **Login Flow** - Email/password authentication
2. **Post List** - Paginated list with realtime sync
3. **Create Post** - Form submission to database
4. **User Profile** - Profile updates and image upload
5. **Real-time Chat** - WebSocket-based messaging
6. **Search** - Full-text search with filtering
7. **Offline Tasks** - Sync to database when online

---

## API Reference

### SupabaseConfig
- `projectUrl`: Supabase project URL
- `anonKey`: Anonymous API key
- `serviceKey`: Service role key
- `bucketName`: Default storage bucket
- `enableRealtimeSync`: Enable WebSocket connections

### SupabaseAuthDriver
- `register()`: Create new user account
- `login()`: Authenticate user
- `refresh()`: Refresh access token
- `logout()`: Sign out user
- `requestOtp()`: Request OTP code
- `verifyOtp()`: Verify OTP code

### SupabaseVaultDriver
- `query()`: Fetch records
- `insert()`: Create record
- `update()`: Update record
- `delete()`: Delete record

### SupabaseStorageDriver
- `upload()`: Upload file
- `download()`: Download file
- `delete()`: Delete file

### SupabaseRealtimeDriver
- `subscribe()`: Subscribe to changes
- `unsubscribe()`: Unsubscribe
- `messages()`: Listen to events
- `send()`: Send message
- `close()`: Close connection

---

## Next Steps

1. ✅ Set up Supabase project
2. ✅ Configure authentication
3. ✅ Create database tables
4. ✅ Enable realtime
5. ✅ Set up storage buckets
6. ✅ Implement app features

For more info: https://supabase.com/docs
