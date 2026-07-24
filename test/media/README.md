# Quantum media production tests

Run from the Flutter project root:

```bash
flutter test test/media/quantum_media_production_test.dart
```

What this suite checks:

- range tracking and partial-content cache bookkeeping
- RAM and disk caching, including encrypted-at-rest media chunks
- prefetch behavior for feed-like scrolling patterns
- loopback proxy auth and cache reuse
- in-flight deduplication so the same image/video is not downloaded twice at once
- adaptive quality switching under slow and fast network conditions
- resumable chunked uploads
- VoIP / real-time packet serialization
- live media pipeline transmit / receive flow

These are production-oriented tests: they include negative cases, cache reuse, auth failures, slow-network simulation, and repeated fetch checks.
