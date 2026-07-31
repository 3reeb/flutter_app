# docs_tests index

## Cross-cutting docs

- [`README.md`](README.md)
- [`cross-cutting/test_matrix.md`](cross-cutting/test_matrix.md)
- [`cross-cutting/update_detection.md`](cross-cutting/update_detection.md)
- [`cross-cutting/schema_for_test_docs.md`](cross-cutting/schema_for_test_docs.md)
- [`cross-cutting/shared_runtime_contracts.md`](cross-cutting/shared_runtime_contracts.md)
- [`cross-cutting/sdui_json_contract.md`](cross-cutting/sdui_json_contract.md)
- [`yaml/README.md`](yaml/README.md)
- [`yaml/INDEX.yaml`](yaml/INDEX.yaml)
- [`yaml/shared/case_template.yaml`](yaml/shared/case_template.yaml)
- [`yaml/shared/group_catalog.yaml`](yaml/shared/group_catalog.yaml)
- [`yaml/shared/axis_catalog.yaml`](yaml/shared/axis_catalog.yaml)

## File-level specs

The full file map is generated automatically from the source tree. Every Dart file under `lib/src/` and the root entry files get a mirrored Markdown and YAML specification.

## File map

### App

- [`lib/src/app/config.dart`](by-file/lib/src/app/config.dart.md)
- [`lib/src/app/quantum_app_entry.dart`](by-file/lib/src/app/quantum_app_entry.dart.md)
- [`lib/src/app/quantum_app_shell.dart`](by-file/lib/src/app/quantum_app_shell.dart.md)
- [`lib/src/app/quantum_boot_schema.dart`](by-file/lib/src/app/quantum_boot_schema.dart.md)
- [`lib/src/app/quantum_file_router.dart`](by-file/lib/src/app/quantum_file_router.dart.md)
- [`lib/src/app/quantum_http_transport.dart`](by-file/lib/src/app/quantum_http_transport.dart.md)
- [`lib/src/app/quantum_http_transport_io.dart`](by-file/lib/src/app/quantum_http_transport_io.dart.md)
- [`lib/src/app/quantum_http_transport_web.dart`](by-file/lib/src/app/quantum_http_transport_web.dart.md)

### Features

- [`lib/src/features/charts/quantum_charts.dart`](by-file/lib/src/features/charts/quantum_charts.dart.md)
- [`lib/src/features/media/quantum_image_engine.dart`](by-file/lib/src/features/media/quantum_image_engine.dart.md)
- [`lib/src/features/media/quantum_media_engine.dart`](by-file/lib/src/features/media/quantum_media_engine.dart.md)

### Foundation

- [`lib/src/foundation/quantum_async.dart`](by-file/lib/src/foundation/quantum_async.dart.md)
- [`lib/src/foundation/quantum_atoms.dart`](by-file/lib/src/foundation/quantum_atoms.dart.md)
- [`lib/src/foundation/quantum_core.dart`](by-file/lib/src/foundation/quantum_core.dart.md)
- [`lib/src/foundation/quantum_error_boundary.dart`](by-file/lib/src/foundation/quantum_error_boundary.dart.md)
- [`lib/src/foundation/quantum_isolate_bridge.dart`](by-file/lib/src/foundation/quantum_isolate_bridge.dart.md)
- [`lib/src/foundation/quantum_isolate_worker.dart`](by-file/lib/src/foundation/quantum_isolate_worker.dart.md)
- [`lib/src/foundation/quantum_json_dsl.dart`](by-file/lib/src/foundation/quantum_json_dsl.dart.md)
- [`lib/src/foundation/quantum_matrix_engine.dart`](by-file/lib/src/foundation/quantum_matrix_engine.dart.md)
- [`lib/src/foundation/quantum_primitives.dart`](by-file/lib/src/foundation/quantum_primitives.dart.md)
- [`lib/src/foundation/quantum_reactive_graph.dart`](by-file/lib/src/foundation/quantum_reactive_graph.dart.md)
- [`lib/src/foundation/quantum_render_scheduler.dart`](by-file/lib/src/foundation/quantum_render_scheduler.dart.md)
- [`lib/src/foundation/quantum_schema.dart`](by-file/lib/src/foundation/quantum_schema.dart.md)
- [`lib/src/foundation/quantum_yaml_engine.dart`](by-file/lib/src/foundation/quantum_yaml_engine.dart.md)

### Platform

- [`lib/src/platform/quantum_connect_engine.dart`](by-file/lib/src/platform/quantum_connect_engine.dart.md)
- [`lib/src/platform/quantum_native_bridge.dart`](by-file/lib/src/platform/quantum_native_bridge.dart.md)

### Plugins

- [`lib/src/plugins/adapters/quantum_firebase_adapters.dart`](by-file/lib/src/plugins/adapters/quantum_firebase_adapters.dart.md)
- [`lib/src/plugins/adapters/quantum_local_adapters.dart`](by-file/lib/src/plugins/adapters/quantum_local_adapters.dart.md)
- [`lib/src/plugins/adapters/quantum_mock_adapters.dart`](by-file/lib/src/plugins/adapters/quantum_mock_adapters.dart.md)
- [`lib/src/plugins/adapters/quantum_universal_adapters.dart`](by-file/lib/src/plugins/adapters/quantum_universal_adapters.dart.md)
- [`lib/src/plugins/internal/quantum_socket_stream_hub.dart`](by-file/lib/src/plugins/internal/quantum_socket_stream_hub.dart.md)
- [`lib/src/plugins/native/quantum_calendar.dart`](by-file/lib/src/plugins/native/quantum_calendar.dart.md)
- [`lib/src/plugins/native/quantum_camera.dart`](by-file/lib/src/plugins/native/quantum_camera.dart.md)
- [`lib/src/plugins/native/quantum_contacts.dart`](by-file/lib/src/plugins/native/quantum_contacts.dart.md)
- [`lib/src/plugins/native/quantum_file_access.dart`](by-file/lib/src/plugins/native/quantum_file_access.dart.md)
- [`lib/src/plugins/native/quantum_location.dart`](by-file/lib/src/plugins/native/quantum_location.dart.md)
- [`lib/src/plugins/native/quantum_microphone.dart`](by-file/lib/src/plugins/native/quantum_microphone.dart.md)
- [`lib/src/plugins/native/quantum_notifications.dart`](by-file/lib/src/plugins/native/quantum_notifications.dart.md)
- [`lib/src/plugins/native/quantum_phone.dart`](by-file/lib/src/plugins/native/quantum_phone.dart.md)
- [`lib/src/plugins/native/quantum_photos.dart`](by-file/lib/src/plugins/native/quantum_photos.dart.md)
- [`lib/src/plugins/quantum_api_engine.dart`](by-file/lib/src/plugins/quantum_api_engine.dart.md)
- [`lib/src/plugins/quantum_api_shell.dart`](by-file/lib/src/plugins/quantum_api_shell.dart.md)
- [`lib/src/plugins/quantum_auth_engine.dart`](by-file/lib/src/plugins/quantum_auth_engine.dart.md)
- [`lib/src/plugins/quantum_domain.dart`](by-file/lib/src/plugins/quantum_domain.dart.md)
- [`lib/src/plugins/quantum_media_api.dart`](by-file/lib/src/plugins/quantum_media_api.dart.md)
- [`lib/src/plugins/quantum_socket_engine.dart`](by-file/lib/src/plugins/quantum_socket_engine.dart.md)

### Root

- [`main.dart`](by-file/main.dart.md)
- [`quantum.config.dart`](by-file/quantum.config.dart.md)
- [`quantum.dart`](by-file/quantum.dart.md)

### Runtime

- [`lib/src/runtime/omni_cores/action_core.dart`](by-file/lib/src/runtime/omni_cores/action_core.dart.md)
- [`lib/src/runtime/omni_cores/animation_core.dart`](by-file/lib/src/runtime/omni_cores/animation_core.dart.md)
- [`lib/src/runtime/omni_cores/box_core.dart`](by-file/lib/src/runtime/omni_cores/box_core.dart.md)
- [`lib/src/runtime/omni_cores/canvas_core.dart`](by-file/lib/src/runtime/omni_cores/canvas_core.dart.md)
- [`lib/src/runtime/omni_cores/chart_core.dart`](by-file/lib/src/runtime/omni_cores/chart_core.dart.md)
- [`lib/src/runtime/omni_cores/collab_core.dart`](by-file/lib/src/runtime/omni_cores/collab_core.dart.md)
- [`lib/src/runtime/omni_cores/connect_core.dart`](by-file/lib/src/runtime/omni_cores/connect_core.dart.md)
- [`lib/src/runtime/omni_cores/control_core.dart`](by-file/lib/src/runtime/omni_cores/control_core.dart.md)
- [`lib/src/runtime/omni_cores/data_core.dart`](by-file/lib/src/runtime/omni_cores/data_core.dart.md)
- [`lib/src/runtime/omni_cores/decoration_core.dart`](by-file/lib/src/runtime/omni_cores/decoration_core.dart.md)
- [`lib/src/runtime/omni_cores/field_core.dart`](by-file/lib/src/runtime/omni_cores/field_core.dart.md)
- [`lib/src/runtime/omni_cores/hook_core.dart`](by-file/lib/src/runtime/omni_cores/hook_core.dart.md)
- [`lib/src/runtime/omni_cores/layout_core.dart`](by-file/lib/src/runtime/omni_cores/layout_core.dart.md)
- [`lib/src/runtime/omni_cores/media_core.dart`](by-file/lib/src/runtime/omni_cores/media_core.dart.md)
- [`lib/src/runtime/omni_cores/portal_core.dart`](by-file/lib/src/runtime/omni_cores/portal_core.dart.md)
- [`lib/src/runtime/omni_cores/stream_core.dart`](by-file/lib/src/runtime/omni_cores/stream_core.dart.md)
- [`lib/src/runtime/omni_cores/system_core.dart`](by-file/lib/src/runtime/omni_cores/system_core.dart.md)
- [`lib/src/runtime/omni_cores/template_core.dart`](by-file/lib/src/runtime/omni_cores/template_core.dart.md)
- [`lib/src/runtime/omni_cores/text_core.dart`](by-file/lib/src/runtime/omni_cores/text_core.dart.md)
- [`lib/src/runtime/omni_cores/visual_core.dart`](by-file/lib/src/runtime/omni_cores/visual_core.dart.md)
- [`lib/src/runtime/quantum_core_file_registry.dart`](by-file/lib/src/runtime/quantum_core_file_registry.dart.md)
- [`lib/src/runtime/quantum_core_schema_registry.dart`](by-file/lib/src/runtime/quantum_core_schema_registry.dart.md)
- [`lib/src/runtime/quantum_data_orchestrator.dart`](by-file/lib/src/runtime/quantum_data_orchestrator.dart.md)
- [`lib/src/runtime/quantum_data_pipeline.dart`](by-file/lib/src/runtime/quantum_data_pipeline.dart.md)
- [`lib/src/runtime/quantum_data_state.dart`](by-file/lib/src/runtime/quantum_data_state.dart.md)
- [`lib/src/runtime/quantum_design_system_manifest.dart`](by-file/lib/src/runtime/quantum_design_system_manifest.dart.md)
- [`lib/src/runtime/quantum_domain_builder.dart`](by-file/lib/src/runtime/quantum_domain_builder.dart.md)
- [`lib/src/runtime/quantum_embodiment_examples.dart`](by-file/lib/src/runtime/quantum_embodiment_examples.dart.md)
- [`lib/src/runtime/quantum_export_dom_stub.dart`](by-file/lib/src/runtime/quantum_export_dom_stub.dart.md)
- [`lib/src/runtime/quantum_export_dom_web.dart`](by-file/lib/src/runtime/quantum_export_dom_web.dart.md)
- [`lib/src/runtime/quantum_export_web_bridge.dart`](by-file/lib/src/runtime/quantum_export_web_bridge.dart.md)
- [`lib/src/runtime/quantum_omni_manifold.dart`](by-file/lib/src/runtime/quantum_omni_manifold.dart.md)
- [`lib/src/runtime/quantum_omni_registry.dart`](by-file/lib/src/runtime/quantum_omni_registry.dart.md)
- [`lib/src/runtime/quantum_permissions.dart`](by-file/lib/src/runtime/quantum_permissions.dart.md)
- [`lib/src/runtime/quantum_sdui_engine.dart`](by-file/lib/src/runtime/quantum_sdui_engine.dart.md)
- [`lib/src/runtime/quantum_sdui_test_engine.dart`](by-file/lib/src/runtime/quantum_sdui_test_engine.dart.md)
- [`lib/src/runtime/quantum_sdui_test_engine_io.dart`](by-file/lib/src/runtime/quantum_sdui_test_engine_io.dart.md)
- [`lib/src/runtime/quantum_sdui_test_engine_shared.dart`](by-file/lib/src/runtime/quantum_sdui_test_engine_shared.dart.md)
- [`lib/src/runtime/quantum_sdui_test_engine_stub.dart`](by-file/lib/src/runtime/quantum_sdui_test_engine_stub.dart.md)
- [`lib/src/runtime/quantum_sdui_type_engine.dart`](by-file/lib/src/runtime/quantum_sdui_type_engine.dart.md)
- [`lib/src/runtime/quantum_template_engine.dart`](by-file/lib/src/runtime/quantum_template_engine.dart.md)
- [`lib/src/runtime/quantum_vm.dart`](by-file/lib/src/runtime/quantum_vm.dart.md)
- [`lib/src/runtime/quantum_vm_components.dart`](by-file/lib/src/runtime/quantum_vm_components.dart.md)
- [`lib/src/runtime/quantum_vm_init.dart`](by-file/lib/src/runtime/quantum_vm_init.dart.md)
- [`lib/src/runtime/quantum_widget_image_exporter.dart`](by-file/lib/src/runtime/quantum_widget_image_exporter.dart.md)
- [`lib/src/runtime/quantum_workspace_engine.dart`](by-file/lib/src/runtime/quantum_workspace_engine.dart.md)
- [`lib/src/runtime/quantum_test_engine.dart`](by-file/lib/src/runtime/quantum_test_engine.dart.md)
- [`lib/src/runtime/quantum_test_engine_shared.dart`](by-file/lib/src/runtime/quantum_test_engine_shared.dart.md)
- [`lib/src/runtime/quantum_test_engine_io.dart`](by-file/lib/src/runtime/quantum_test_engine_io.dart.md)
- [`lib/src/runtime/quantum_test_engine_stub.dart`](by-file/lib/src/runtime/quantum_test_engine_stub.dart.md)

### Ui

- [`lib/src/ui/internal/quantum_focus_sync.dart`](by-file/lib/src/ui/internal/quantum_focus_sync.dart.md)
- [`lib/src/ui/quantum_animation_engine.dart`](by-file/lib/src/ui/quantum_animation_engine.dart.md)
- [`lib/src/ui/quantum_behaviors.dart`](by-file/lib/src/ui/quantum_behaviors.dart.md)
- [`lib/src/ui/quantum_components.dart`](by-file/lib/src/ui/quantum_components.dart.md)
- [`lib/src/ui/quantum_field_ui_engine.dart`](by-file/lib/src/ui/quantum_field_ui_engine.dart.md)
- [`lib/src/ui/quantum_forms_engine.dart`](by-file/lib/src/ui/quantum_forms_engine.dart.md)
- [`lib/src/ui/quantum_hydration_reader.dart`](by-file/lib/src/ui/quantum_hydration_reader.dart.md)
- [`lib/src/ui/quantum_hydration_reader_html.dart`](by-file/lib/src/ui/quantum_hydration_reader_html.dart.md)
- [`lib/src/ui/quantum_hydration_reader_stub.dart`](by-file/lib/src/ui/quantum_hydration_reader_stub.dart.md)
- [`lib/src/ui/quantum_layout_engine.dart`](by-file/lib/src/ui/quantum_layout_engine.dart.md)
- [`lib/src/ui/quantum_navigation_engine.dart`](by-file/lib/src/ui/quantum_navigation_engine.dart.md)
- [`lib/src/ui/quantum_overlays.dart`](by-file/lib/src/ui/quantum_overlays.dart.md)
- [`lib/src/ui/quantum_scene_layer.dart`](by-file/lib/src/ui/quantum_scene_layer.dart.md)
- [`lib/src/ui/quantum_shape_engine.dart`](by-file/lib/src/ui/quantum_shape_engine.dart.md)
- [`lib/src/ui/quantum_telemetry_engine.dart`](by-file/lib/src/ui/quantum_telemetry_engine.dart.md)
- [`lib/src/ui/quantum_theme_engine.dart`](by-file/lib/src/ui/quantum_theme_engine.dart.md)
