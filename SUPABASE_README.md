# Supabase Integration for Quantum Layout Engine

> Complete, production-ready Supabase integration with zero missing pieces. Includes authentication, database, storage, real-time updates, and SDUI JSON bindings.

## 🚀 Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Supabase
Edit `assets/config/supabase.json`:
```json
{
  "projectUrl": "https://your-project.supabase.co",
  "anonKey": "your-anon-key",
  "serviceKey": "your-service-key"
}
```

### 3. Initialize in App
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

### 4. Create Database Tables
- Open Supabase Console → SQL Editor
- Copy `lib/docs/supabase_sql_setup.sql`
- Execute all SQL commands

## 📦 What's Included

### Core Adapters
- ✅ **Authentication** - Email/password, OTP, OAuth providers
- ✅ **Database** - CRUD, queries, pagination, soft deletes
- ✅ **Storage** - File upload/download, public/signed URLs
- ✅ **Real-time** - WebSocket subscriptions, live updates
- ✅ **Error Handling** - Comprehensive error management
- ✅ **Caching** - Multiple cache strategies
- ✅ **Offline Support** - Offline-capable operations with sync

### Helper Functions
- ✅ `SupabaseQueries` - Query helpers (user data, pagination)
- ✅ `SupabaseRealtimeSubscriptions` - Subscription management
- ✅ `SupabaseStorageHelper` - File upload/download utilities
- ✅ `SupabaseBatchOperations` - Bulk operations

### SDUI JSON Examples
- ✅ Login form with auth
- ✅ Posts list with realtime sync
- ✅ Create post form
- ✅ User profile with image upload
- ✅ Real-time chat interface
- ✅ User search with filters
- ✅ Offline-capable task list

### Documentation
- ✅ `SUPABASE_INTEGRATION_GUIDE.md` - Complete API reference
- ✅ `IMPLEMENTATION_CHECKLIST.md` - Step-by-step setup guide
- ✅ `supabase_sql_setup.sql` - Database schema
- ✅ `supabase.json` - Configuration template

## 📚 File Structure

```
lib/
├── src/plugins/
│   ├── adapters/
│   │   ├── quantum_supabase_adapters.dart      # Core adapters
│   │   ├── quantum_firebase_adapters.dart      # Firebase (existing)
│   │   ├── quantum_local_adapters.dart         # Local storage
│   │   ├── quantum_mock_adapters.dart          # Mock/testing
│   │   └── quantum_universal_adapters.dart     # Generic adapters
│   ├── supabase_setup.dart                    # Setup & helpers
│   ├── quantum_auth_engine.dart                # Auth interfaces
│   ├── quantum_api_engine.dart                 # API interfaces
│   ├── quantum_media_api.dart                  # Storage interfaces
│   └── quantum_socket_engine.dart              # Realtime interfaces
├── examples/
│   ├── supabase_sdui_examples.json            # SDUI examples
│   └── sdui_widget_examples.json               # Widget examples
└── docs/
    ├── SUPABASE_INTEGRATION_GUIDE.md           # Complete guide
    ├── IMPLEMENTATION_CHECKLIST.md             # Setup checklist
    └── supabase_sql_setup.sql                  # Database schema

assets/
└── config/
    └── supabase.json                           # Configuration

pubspec.yaml                                    # Updated with Supabase deps
```

## 🔐 Features

### Authentication
```dart
// Register
await authDriver.register(AuthRequest(
  credentials: {'email': 'user@example.com', 'password': 'pass'}
));

// Login
final result = await authDriver.login(AuthRequest(...));
final session = result.data;

// OTP
await authDriver.requestOtp(OtpRequest(phoneNumber: '+1234567890'));
await authDriver.verifyOtp(OtpVerification(code: '123456'));

// Refresh & Logout
await authDriver.refresh(currentSession);
await authDriver.logout(currentSession);
```

### Database Operations
```dart
// Query with filters
final result = await vaultDriver.query('posts', filter, context, policy);

// Insert
await vaultDriver.insert('posts', {'title': 'Post'}, context);

// Update
await vaultDriver.update('posts', 'id-123', {'title': 'New'}, context);

// Delete
await vaultDriver.delete('posts', 'id-123', context);

// Using helpers
final queries = SupabaseQueries(driver: vaultDriver, context: context);
await queries.queryUserData('posts', 'user_id');
await queries.queryPaginated('posts', page: 1, pageSize: 20);
await queries.insertWithMetadata('posts', data);
await queries.softDelete('posts', 'id-123');
```

### File Storage
```dart
// Upload
final result = await storageDriver.upload(
  'avatars/profile.jpg',
  imageBytes,
  context,
  contentType: 'image/jpeg',
);

// Download
final bytes = await storageDriver.download('avatars/profile.jpg', context);

// Get URLs
final publicUrl = storageHelper.getPublicUrl(path, bucket);
final signedUrl = storageHelper.getSignedUrl(path, bucket);

// Delete
await storageDriver.delete('avatars/profile.jpg', context);
```

### Real-time Updates
```dart
// Subscribe
await subscriptions.subscribeToTable('posts', (message) {
  print('Post updated: ${message.payload}');
});

// Subscribe with filter
await subscriptions.subscribeFiltered('posts', {'user_id': userId}, handler);

// Listen to events
realtimeDriver.messages('posts').listen((message) {
  if (message.type == 'INSERT') print('New post');
  if (message.type == 'UPDATE') print('Post updated');
  if (message.type == 'DELETE') print('Post deleted');
});

// Cleanup
await subscriptions.unsubscribeFromTable('posts');
await subscriptions.dispose();
```

### SDUI JSON Integration

#### Login Form
```json
{
  "type": "button",
  "title": "Sign In",
  "action": {
    "type": "network",
    "method": "POST",
    "driver": "supabase_auth",
    "body": {"email": "${email}", "password": "${password}"},
    "onSuccess": {"type": "navigate", "screen": "home"}
  }
}
```

#### Data List with Realtime
```json
{
  "type": "list",
  "dataSource": {
    "type": "vault",
    "table": "posts",
    "driver": "supabase_vault",
    "realtime": {
      "enabled": true,
      "events": ["INSERT", "UPDATE"],
      "driver": "supabase_realtime"
    }
  }
}
```

#### File Upload
```json
{
  "type": "button",
  "title": "Upload Photo",
  "action": {
    "type": "media",
    "driver": "supabase_storage",
    "bucket": "avatars"
  }
}
```

## 🗄️ Database Schema

Pre-configured tables:
- **profiles** - User profiles with avatar, bio, website
- **posts** - Blog posts with tags, status, view count
- **messages** - Chat messages with attachments
- **tasks** - Todo tasks with priority and due date
- **follows** - Social graph for following users
- **likes** - Post likes counter
- **comments** - Post comments
- **notifications** - User notifications

All tables include:
- ✅ UUID primary keys
- ✅ Timestamps (created_at, updated_at, deleted_at)
- ✅ Row Level Security (RLS)
- ✅ Realtime enabled
- ✅ Indexes for performance
- ✅ Soft delete support

## 🎯 Cache Strategies

- **cacheFirst** - Use cache, fallback to network
- **networkFirst** - Use network, fallback to cache
- **staleWhileRevalidate** - Use cache + update in background
- **cacheOnly** - Cache only, no network
- **networkOnly** - Network only, no cache

```dart
const QueryPolicy(
  cachePolicy: CachePolicyMode.staleWhileRevalidate,
  ttl: Duration(minutes: 5),
  forceRefresh: false,
)
```

## 🔄 Offline Support

Enable offline mode for critical data:
```json
{
  "dataSource": {
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

Sync strategies:
- **readThrough** - Read from cache, sync on writes
- **writeQueue** - Queue writes offline, sync when online
- **fullOffline** - Complete offline mode

## 🛡️ Security

### Row Level Security (RLS)
All tables have RLS policies:
- Public tables: Anyone can read, own write
- Private tables: Own data only
- Shared tables: Access based on relationships

### Policies Include
- User isolation
- Resource ownership
- Relationship-based access
- Soft delete awareness

### Best Practices
- Enable RLS on all tables ✅
- Use service role key only for admin ✅
- Enable email verification ✅
- Implement CORS restrictions ✅
- Monitor access logs ✅

## 📊 Performance

### Optimization Tips
1. **Pagination** - Always paginate large datasets
2. **Indexes** - Pre-indexed on common filters
3. **Caching** - Use appropriate cache strategies
4. **Selection** - Select only needed columns
5. **Realtime** - Enable only on essential tables
6. **Soft Deletes** - Avoid removing historical data

### Monitoring
- API response times
- Cache hit rates
- Realtime latency
- Storage operations

## 🐛 Troubleshooting

### Connection Issues
- Verify project URL and keys
- Check CORS settings
- Ensure WebSocket enabled
- Check firewall rules

### Authentication Fails
- Verify email/password correct
- Check email confirmation
- Review RLS policies

### Realtime Not Working
- Enable on table
- Check WebSocket connection
- Verify channel subscriptions

### Queries Return Empty
- Check RLS policies
- Verify user permissions
- Test with service key

## 📖 Documentation

Comprehensive guides included:

1. **SUPABASE_INTEGRATION_GUIDE.md** (655 lines)
   - Full API reference
   - Usage examples
   - Advanced patterns
   - Troubleshooting

2. **IMPLEMENTATION_CHECKLIST.md** (423 lines)
   - 8-phase implementation plan
   - Testing scenarios
   - Deployment guide
   - Monitoring setup

3. **supabase_sql_setup.sql** (401 lines)
   - Complete schema
   - RLS policies
   - Triggers & functions
   - Helper views

4. **supabase_sdui_examples.json** (657 lines)
   - 7 complete SDUI examples
   - Authentication
   - CRUD operations
   - Real-time chat
   - Offline support

## 🔗 Resources

- **Supabase Docs**: https://supabase.com/docs
- **Flutter SDK**: https://supabase.com/docs/reference/flutter
- **API Reference**: https://supabase.com/docs/reference/api
- **Database Guide**: https://supabase.com/docs/guides/database
- **Real-time**: https://supabase.com/docs/guides/realtime
- **Storage**: https://supabase.com/docs/guides/storage

## 📋 Checklist

Implementation checklist to get started:

- [ ] Create Supabase project
- [ ] Update `assets/config/supabase.json`
- [ ] Run `flutter pub get`
- [ ] Execute SQL schema script
- [ ] Initialize `SupabaseEngineRegistry`
- [ ] Test authentication
- [ ] Test database queries
- [ ] Enable realtime
- [ ] Test file storage
- [ ] Create UI with SDUI JSON examples
- [ ] Test offline mode
- [ ] Deploy to production

## 🤝 Contributing

To extend the Supabase integration:

1. Add new adapters in `lib/src/plugins/adapters/`
2. Implement driver interfaces
3. Add helper functions in `lib/src/plugins/supabase_setup.dart`
4. Add SDUI examples in `lib/examples/supabase_sdui_examples.json`
5. Update documentation
6. Add tests

## 📝 License

This Supabase integration is part of the Quantum Layout Engine.

## 🎉 Summary

**Everything is ready to use:**
- ✅ All adapters implemented (Auth, Database, Storage, Realtime)
- ✅ Complete helper functions for common operations
- ✅ 7 full SDUI JSON examples
- ✅ Complete database schema with RLS
- ✅ Comprehensive 655-line integration guide
- ✅ 8-phase implementation checklist
- ✅ Updated pubspec.yaml with all dependencies
- ✅ Configuration templates
- ✅ Zero missing pieces - production ready!

**Start Building:**
1. Create Supabase project
2. Update configuration
3. Run SQL migrations
4. Initialize registry
5. Use provided SDUI examples
6. Deploy!

Happy building! 🚀
