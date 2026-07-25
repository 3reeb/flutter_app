# `quantum.dart`

## What this file is
A single barrel export for the framework. It does not add runtime logic; it only re-exports the major foundation, UI, runtime, app, feature, plugin, and platform modules so other files can import one entry point instead of many.

Author-intent note: Import this one file to access the entire Quantum framework:

## Dependencies
- Exports `src/foundation/quantum_async.dart`.
- Exports `src/foundation/quantum_core.dart`.
- Exports `src/foundation/quantum_error_boundary.dart`.
- Exports `src/foundation/quantum_isolate_worker.dart`.
- Exports `src/foundation/quantum_isolate_bridge.dart`.
- Exports `src/foundation/quantum_json_dsl.dart`.
- Exports `src/foundation/quantum_matrix_engine.dart`.
- Exports `src/foundation/quantum_primitives.dart`.
- Exports `src/foundation/quantum_atoms.dart`.
- Exports `src/foundation/quantum_reactive_graph.dart`.
- Exports `src/foundation/quantum_render_scheduler.dart`.
- Exports `src/foundation/quantum_schema.dart`.
- Exports `src/foundation/quantum_yaml_engine.dart`.
- Exports `src/ui/quantum_animation_engine.dart`.
- Exports `src/ui/quantum_behaviors.dart`.
- Exports `src/ui/quantum_components.dart`.
- Exports `src/ui/quantum_field_ui_engine.dart`.
- Exports `src/ui/quantum_forms_engine.dart`.
- Exports `src/ui/quantum_layout_engine.dart`.
- Exports `src/ui/quantum_navigation_engine.dart`.
- Exports `src/ui/quantum_overlays.dart`.
- Exports `src/ui/quantum_scene_layer.dart`.
- Exports `src/ui/quantum_shape_engine.dart`.
- Exports `src/ui/quantum_telemetry_engine.dart`.
- Exports `src/ui/quantum_theme_engine.dart`.
- Exports `src/runtime/quantum_data_orchestrator.dart`.
- Exports `src/runtime/quantum_data_pipeline.dart`.
- Exports `src/runtime/quantum_data_state.dart`.
- Exports `src/runtime/quantum_domain_builder.dart`.
- Exports `src/runtime/quantum_embodiment_engine.dart`.
- Exports `src/runtime/quantum_embodiment_examples.dart`.
- Exports `src/runtime/quantum_omni_manifold.dart`.
- Exports `src/runtime/quantum_design_system_manifest.dart`.
- Exports `src/runtime/quantum_omni_registry.dart`.
- Exports `src/runtime/quantum_core_file_registry.dart`.
- Exports `src/runtime/quantum_core_schema_registry.dart`.
- Exports `src/runtime/quantum_sdui_engine.dart`.
- Exports `src/runtime/quantum_sdui_type_engine.dart`.
- Exports `src/runtime/quantum_permissions.dart`.
- Exports `src/runtime/quantum_vm.dart`.
- Exports `src/runtime/quantum_vm_init.dart`.
- Exports `src/runtime/quantum_template_engine.dart`.
- Exports `src/runtime/quantum_workspace_engine.dart`.
- Exports `src/runtime/quantum_widget_image_exporter.dart`.
- Exports `src/runtime/quantum_export_web_bridge.dart`.
- Exports `src/app/quantum_app_entry.dart`.
- Exports `src/app/quantum_boot_schema.dart`.
- Exports `src/app/quantum_app_shell.dart`.
- Exports `src/app/quantum_file_router.dart`.
- Exports `src/app/config.dart`.
- Exports `src/platform/quantum_connect_engine.dart`.
- Exports `src/platform/quantum_native_bridge.dart`.
- Exports `src/features/charts/quantum_charts.dart`.
- Exports `src/features/media/quantum_image_engine.dart`.
- Exports `src/features/media/quantum_media_engine.dart`.
- Exports `src/plugins/quantum_api_engine.dart`.
- Exports `src/plugins/quantum_api_shell.dart`.
- Exports `src/plugins/quantum_auth_engine.dart`.
- Exports `src/plugins/quantum_domain.dart`.
- Exports `src/plugins/quantum_media_api.dart`.
- Exports `src/plugins/quantum_socket_engine.dart`.
- Exports `src/plugins/adapters/quantum_firebase_adapters.dart`.
- Exports `src/plugins/adapters/quantum_local_adapters.dart`.
- Exports `src/plugins/adapters/quantum_mock_adapters.dart`.
- Exports `src/plugins/adapters/quantum_universal_adapters.dart`.
- Exports `src/plugins/native/quantum_calendar.dart`.
- Exports `src/plugins/native/quantum_camera.dart`.
- Exports `src/plugins/native/quantum_contacts.dart`.
- Exports `src/plugins/native/quantum_file_access.dart`.
- Exports `src/plugins/native/quantum_location.dart`.
- Exports `src/plugins/native/quantum_microphone.dart`.
- Exports `src/plugins/native/quantum_notifications.dart`.
- Exports `src/plugins/native/quantum_phone.dart`.
- Exports `src/plugins/native/quantum_photos.dart`.

## Top-level declarations
- No top-level type or function declarations were detected.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
This file is intentionally thin. The exported module list is organized so consumers can import a single path and still get the complete foundation/UI/runtime surface.
The main job here is dependency curation: it defines the public package boundary and keeps the rest of the codebase from depending on many individual paths directly.

## Dependency and design notes
- This file is the package boundary; adding or removing exports changes what downstream code can import from the framework root.

## File size
- 99 lines in the source file.
- 0 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
