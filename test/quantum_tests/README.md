# Quantum Tests Bundle

This folder contains a real Dart/Flutter test suite for the Quantum overlay and JSON DSL layers.

The suite is organized into:
- foundation tests for runtime spec, motion spec, spatial config, and JSON DSL registration
- UI tests for the overlay root, mounting, dismissal, and nesting behavior

Several tests are intentionally strict regression tests so they surface production gaps rather than only verifying happy paths.
