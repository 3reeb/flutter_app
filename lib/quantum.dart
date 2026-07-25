// ════════════════════════════════════════════════════════════════════════════
// QUANTUM FRAMEWORK — Single barrel export
// quantum.dart
//
// Import this one file to access the entire Quantum framework:
//
//   import 'quantum.dart';
//
// ════════════════════════════════════════════════════════════════════════════

library quantum;

// Foundation
export 'src/foundation/quantum_async.dart';
export 'src/foundation/quantum_core.dart';
export 'src/foundation/quantum_error_boundary.dart';
export 'src/foundation/quantum_isolate_worker.dart';
export 'src/foundation/quantum_isolate_bridge.dart';
export 'src/foundation/quantum_json_dsl.dart';
export 'src/foundation/quantum_matrix_engine.dart';
export 'src/foundation/quantum_primitives.dart';
export 'src/foundation/quantum_atoms.dart';
export 'src/foundation/quantum_reactive_graph.dart';
export 'src/foundation/quantum_render_scheduler.dart';
export 'src/foundation/quantum_schema.dart';
export 'src/foundation/quantum_yaml_engine.dart';

// UI
export 'src/ui/quantum_animation_engine.dart';
export 'src/ui/quantum_behaviors.dart';
export 'src/ui/quantum_components.dart';
export 'src/ui/quantum_field_ui_engine.dart';
export 'src/ui/quantum_forms_engine.dart';
export 'src/ui/quantum_layout_engine.dart';
export 'src/ui/quantum_navigation_engine.dart';
export 'src/ui/quantum_overlays.dart';
export 'src/ui/quantum_scene_layer.dart';
export 'src/ui/quantum_shape_engine.dart';
export 'src/ui/quantum_telemetry_engine.dart';
export 'src/ui/quantum_theme_engine.dart';

// Runtime
export 'src/runtime/quantum_data_orchestrator.dart';
export 'src/runtime/quantum_data_pipeline.dart';
export 'src/runtime/quantum_data_state.dart';
export 'src/runtime/quantum_domain_builder.dart';
export 'src/runtime/quantum_embodiment_engine.dart';
export 'src/runtime/quantum_embodiment_examples.dart';
export 'src/runtime/quantum_omni_manifold.dart';
export 'src/runtime/quantum_design_system_manifest.dart';
export 'src/runtime/quantum_omni_registry.dart';
export 'src/runtime/quantum_core_file_registry.dart';
export 'src/runtime/quantum_core_schema_registry.dart';
export 'src/runtime/quantum_sdui_engine.dart';
export 'src/runtime/quantum_sdui_type_engine.dart';
export 'src/runtime/quantum_permissions.dart';
export 'src/runtime/quantum_vm.dart';
export 'src/runtime/quantum_vm_init.dart';
export 'src/runtime/quantum_template_engine.dart';
export 'src/runtime/quantum_workspace_engine.dart';
export 'src/runtime/quantum_widget_image_exporter.dart';
export 'src/runtime/quantum_export_web_bridge.dart';

// App
export 'src/app/quantum_app_entry.dart';
export 'src/app/quantum_boot_schema.dart';
export 'src/app/quantum_app_shell.dart';
export 'src/app/quantum_file_router.dart';
export 'src/app/config.dart';

// Platform
export 'src/platform/quantum_connect_engine.dart';
export 'src/platform/quantum_native_bridge.dart';

// Features
export 'src/features/charts/quantum_charts.dart';
export 'src/features/media/quantum_image_engine.dart';
export 'src/features/media/quantum_media_engine.dart';

// Plugins
export 'src/plugins/quantum_api_engine.dart';
export 'src/plugins/quantum_api_shell.dart';
export 'src/plugins/quantum_auth_engine.dart';
export 'src/plugins/quantum_domain.dart';
export 'src/plugins/quantum_media_api.dart';
export 'src/plugins/quantum_socket_engine.dart';
export 'src/plugins/adapters/quantum_firebase_adapters.dart';
export 'src/plugins/adapters/quantum_local_adapters.dart';
export 'src/plugins/adapters/quantum_mock_adapters.dart';
export 'src/plugins/adapters/quantum_universal_adapters.dart';
export 'src/plugins/native/quantum_calendar.dart';
export 'src/plugins/native/quantum_camera.dart';
export 'src/plugins/native/quantum_contacts.dart';
export 'src/plugins/native/quantum_file_access.dart';
export 'src/plugins/native/quantum_location.dart';
export 'src/plugins/native/quantum_microphone.dart';
export 'src/plugins/native/quantum_notifications.dart';
export 'src/plugins/native/quantum_phone.dart';
export 'src/plugins/native/quantum_photos.dart';
