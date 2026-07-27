# Plugin-layer unified data routing

This project’s plugin layer is the bridge between slice/datasource intent and the backend or device capabilities that actually fulfill it.

## Why this matters
The new local-first data path relies on plugin actions already present in the runtime to carry reads, writes, realtime streams, media streams, and cache-aware projections through a single execution surface. That means slices can stay declarative while the runtime decides whether a request is served locally, hydrated partially, streamed, or forwarded to a remote API.

## Relevant plugin modules
- `src/plugins/quantum_api_shell.dart`
- `src/plugins/quantum_api_engine.dart`
- `src/plugins/quantum_media_api.dart`
- `src/plugins/quantum_socket_engine.dart`
- `src/plugins/quantum_auth_engine.dart`
- `src/plugins/adapters/quantum_local_adapters.dart`
- `src/plugins/adapters/quantum_universal_adapters.dart`
- `src/plugins/adapters/quantum_mock_adapters.dart`
- `src/plugins/adapters/quantum_firebase_adapters.dart`

## Runtime responsibilities documented here
- Action routing through the central shell/engine pair.
- Selective reads using projections rather than full-document fetches.
- Realtime and media stream delivery.
- Cache-backed reads where partial state can be merged into existing local records.
- Write pathways that can be paired with optimistic local updates and later reconciliation.

## Traceability note
The plugin code itself remains the actual execution layer. This document exists so future diffs can be understood from the slice/data-source side without losing sight of where remote, realtime, and media behaviors are implemented.
