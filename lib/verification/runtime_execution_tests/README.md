# Runtime execution test tree

This tree mirrors `src/` and gives every Dart source file its own runtime-execution test plan.

The files under `docs/by-file/` explain the launch-time failure behavior in plain language.
The files under `yaml/by-file/` define the same runtime cases in machine-readable form.

These plans are execution-based only:
- they run the code at runtime during app launch or launch-like harness execution
- they use invalid and edge-case inputs
- they cover null access, malformed payloads, boundary values, and resource pressure
- they do not perform static verification of whether code exists


The markdown files under `docs/by-file/` are intentionally dense and file-specific:
- each one maps to a single Dart source file under `src/`
- each one names the actual executable surface found in that file
- each one expands launch-time runtime scenarios using the file's real symbols, imports, and platform branches
- each one stays focused on execution-based failure behavior, not static existence checks

