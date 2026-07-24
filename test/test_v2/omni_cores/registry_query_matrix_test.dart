import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: true);
  final aliases = <Map<String, dynamic>>[
    {"group": "box", "name": "row", "target": "box:row", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "col", "target": "box:col", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "stack", "target": "box:stack", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "wrap", "target": "box:wrap", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "grid", "target": "box:grid", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "masonry", "target": "box:masonry", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "card", "target": "box:card", "defaultProps": {"fill": "surface", "depth": "raised", "padding": [24]}, "description": "", "tags": []},
    {"group": "box", "name": "split", "target": "box:split", "defaultProps": {"style": "w-full h-full"}, "description": "", "tags": []},
    {"group": "box", "name": "morph", "target": "box:morph", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "surface", "target": "box:surface", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "shell", "target": "box:shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "viewport", "target": "box:viewport", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "responsive", "target": "box:responsive", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "measure", "target": "box:measure", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "builder", "target": "box:builder", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "layer", "target": "box:layer", "defaultProps": {}, "description": "", "tags": []},
    {"group": "box", "name": "matrix", "target": "box:matrix", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "raw_pointer", "target": "action:raw_pointer", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "pointer", "target": "action:pointer", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "focus", "target": "action:focus", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "button", "target": "action:button", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "tap", "target": "action:button", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "press", "target": "action:button", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "hover_action", "target": "action:hover", "defaultProps": {}, "description": "", "tags": []},
    {"group": "action", "name": "icon_button", "target": "action:button", "defaultProps": {"shape": "circle", "fill": "ghost"}, "description": "", "tags": []},
    {"group": "action", "name": "chip", "target": "action:chip", "defaultProps": {"shape": "pill", "scale": "sm", "edge": "hairline"}, "description": "", "tags": []},
    {"group": "action", "name": "badge", "target": "action:badge", "defaultProps": {"shape": "pill", "scale": "xs", "disabled": true}, "description": "", "tags": []},
    {"group": "field", "name": "text_field", "target": "field:text", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "textarea", "target": "field:multiline", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "email_field", "target": "field:email", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "password_field", "target": "field:password", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "number_field", "target": "field:number", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "search_field", "target": "field:search", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "date_field", "target": "field:date", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "select_field", "target": "field:select", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "toggle", "target": "field:toggle", "defaultProps": {}, "description": "", "tags": []},
    {"group": "field", "name": "slider", "target": "field:slider", "defaultProps": {}, "description": "", "tags": []},
    {"group": "media", "name": "image", "target": "media:image", "defaultProps": {}, "description": "", "tags": []},
    {"group": "media", "name": "avatar", "target": "media:avatar", "defaultProps": {}, "description": "", "tags": []},
    {"group": "media", "name": "video", "target": "media:video", "defaultProps": {}, "description": "", "tags": []},
    {"group": "media", "name": "chart", "target": "media:chart", "defaultProps": {}, "description": "", "tags": []},
    {"group": "data", "name": "sliver_plane", "target": "data:sliver_plane", "defaultProps": {}, "description": "", "tags": []},
    {"group": "data", "name": "sliver", "target": "data:sliver", "defaultProps": {}, "description": "", "tags": []},
    {"group": "portal", "name": "overlay_entry", "target": "portal:overlay_entry", "defaultProps": {}, "description": "", "tags": []},
    {"group": "portal", "name": "overlay", "target": "portal:overlay", "defaultProps": {}, "description": "", "tags": []},
    {"group": "portal", "name": "dialog", "target": "portal:dialog", "defaultProps": {}, "description": "", "tags": []},
    {"group": "portal", "name": "drawer", "target": "portal:sheet", "defaultProps": {}, "description": "", "tags": []},
    {"group": "portal", "name": "sheet", "target": "portal:sheet", "defaultProps": {}, "description": "", "tags": []},
    {"group": "portal", "name": "popover", "target": "portal:popover", "defaultProps": {}, "description": "", "tags": []},
    {"group": "control", "name": "flow", "target": "control:flow", "defaultProps": {}, "description": "", "tags": []},
    {"group": "control", "name": "workflow", "target": "control:flow", "defaultProps": {}, "description": "", "tags": []},
    {"group": "control", "name": "form_scope", "target": "control:form_scope", "defaultProps": {}, "description": "", "tags": []},
    {"group": "control", "name": "tabs", "target": "control:tabs", "defaultProps": {}, "description": "", "tags": []},
    {"group": "control", "name": "segment", "target": "control:tabs", "defaultProps": {}, "description": "", "tags": []},
    {"group": "control", "name": "stepper", "target": "control:stepper", "defaultProps": {}, "description": "", "tags": []},
    {"group": "control", "name": "accordion", "target": "control:accordion", "defaultProps": {}, "description": "", "tags": []},
    {"group": "canvas", "name": "shader", "target": "canvas:shader", "defaultProps": {}, "description": "", "tags": []},
    {"group": "system", "name": "sync_scroll", "target": "system:sync_scroll", "defaultProps": {}, "description": "", "tags": []},
    {"group": "system", "name": "worker", "target": "system:worker", "defaultProps": {}, "description": "", "tags": []},
    {"group": "system", "name": "ticker", "target": "system:ticker", "defaultProps": {}, "description": "", "tags": []},
    {"group": "system", "name": "omega_macro", "target": "system:omega_macro", "defaultProps": {}, "description": "", "tags": []},
    {"group": "decoration", "name": "decorate", "target": "decoration:merge", "defaultProps": {}, "description": "", "tags": []},
    {"group": "decoration", "name": "highlight", "target": "decoration:text", "defaultProps": {}, "description": "", "tags": []},
    {"group": "decoration", "name": "markup", "target": "decoration:text", "defaultProps": {}, "description": "", "tags": []},
    {"group": "animation", "name": "animation", "target": "animation", "defaultProps": {}, "description": "", "tags": []},
    {"group": "animation", "name": "motion", "target": "animation", "defaultProps": {}, "description": "", "tags": []},
    {"group": "animation", "name": "transition", "target": "animation", "defaultProps": {}, "description": "", "tags": []},
    {"group": "animation", "name": "animate", "target": "animation", "defaultProps": {}, "description": "", "tags": []},
    {"group": "animation", "name": "glass_motion", "target": "animation", "defaultProps": {}, "description": "", "tags": []},
    {"group": "visual", "name": "visual_surface", "target": "visual:surface", "defaultProps": {}, "description": "Visual surface alias.", "tags": ["visual", "alias"]},
    {"group": "visual", "name": "visual_shell", "target": "visual:shell", "defaultProps": {}, "description": "Visual shell alias.", "tags": ["visual", "alias"]},
    {"group": "visual", "name": "visual_scene", "target": "visual:scene", "defaultProps": {}, "description": "Visual scene alias.", "tags": ["visual", "alias"]},
    {"group": "visual", "name": "visual_overlay", "target": "visual:overlay", "defaultProps": {}, "description": "Visual overlay alias.", "tags": ["visual", "alias"]},
    {"group": "visual", "name": "visual_delegate", "target": "visual:delegate", "defaultProps": {}, "description": "Visual delegation alias.", "tags": ["visual", "alias"]},
    {"group": "hook", "name": "hook_lifecycle", "target": "hook:lifecycle", "defaultProps": {}, "description": "Lifecycle hook wrapper alias.", "tags": ["hook", "alias"]},
    {"group": "hook", "name": "hook_effect", "target": "hook:effect", "defaultProps": {}, "description": "Effect hook wrapper alias.", "tags": ["hook", "alias"]},
    {"group": "hook", "name": "hook_scope", "target": "hook:scope", "defaultProps": {}, "description": "Scoped local data hook alias.", "tags": ["hook", "alias"]},
    {"group": "hook", "name": "hook_bridge", "target": "hook:bridge", "defaultProps": {}, "description": "Bridge / data injection hook alias.", "tags": ["hook", "alias"]},
    {"group": "connect", "name": "backButton", "target": "connect:back", "defaultProps": {}, "description": "", "tags": []},
    {"group": "connect", "name": "pressGesture", "target": "connect:pressGesture", "defaultProps": {}, "description": "", "tags": []},
    {"group": "connect", "name": "connectSlot", "target": "connect:slot", "defaultProps": {}, "description": "", "tags": []},
    {"group": "connect", "name": "focusReveal", "target": "connect:focusReveal", "defaultProps": {}, "description": "", "tags": []},
    {"group": "connect", "name": "channelText", "target": "connect:channelText", "defaultProps": {}, "description": "", "tags": []},
    {"group": "connect", "name": "behavior", "target": "connect:behavior", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "menu", "target": "template:nested_menu", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "menu_item", "target": "template:menu_item", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "list", "target": "template:rich_list", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "table", "target": "template:rich_table", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "avatars", "target": "template:avatar_group", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "avatar_group", "target": "template:avatar_group", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "categories", "target": "template:category_browser", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "category_browser", "target": "template:category_browser", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "rich_shell", "target": "template:rich_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "rich_list", "target": "template:rich_list", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "rich_table", "target": "template:rich_table", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "tabs", "target": "template:tabs", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "data_shell", "target": "template:collection_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "wizard", "target": "template:stepper", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "empty_state", "target": "template:state_surface", "defaultProps": {"tone": "empty"}, "description": "", "tags": []},
    {"group": "template", "name": "error_state", "target": "template:state_surface", "defaultProps": {"tone": "error"}, "description": "", "tags": []},
    {"group": "template", "name": "profile_card", "target": "template:profile_card", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "flow_shell", "target": "template:flow_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "hero_bridge", "target": "template:hero_bridge", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "search_shell", "target": "template:search_panel", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_shell", "target": "template:field_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_text", "target": "template:field_text", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_number", "target": "template:field_number", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_toggle", "target": "template:field_toggle", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_slider", "target": "template:field_slider", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_select", "target": "template:field_select", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_array", "target": "template:field_array", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_blocks", "target": "template:field_blocks", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_data", "target": "template:field_data", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_lookup", "target": "template:field_lookup", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_relation", "target": "template:field_relation", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "field_shell_stacked", "target": "template:field_shell_stacked", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "popover_shell", "target": "template:popover_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "surface_shell", "target": "template:surface_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "item_shell", "target": "template:item_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "cluster_shell", "target": "template:cluster_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "split_shell", "target": "template:split_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "state_shell", "target": "template:state_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "overlay_shell", "target": "template:overlay_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "control_shell", "target": "template:control_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "media_shell", "target": "template:media_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "navigation_shell", "target": "template:navigation_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "segmented_control", "target": "template:segmented_control", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "accordion", "target": "template:accordion", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "carousel", "target": "template:carousel", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "stepper", "target": "template:stepper", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "search_panel", "target": "template:search_panel", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "collection_shell", "target": "template:collection_shell", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "form_panel", "target": "template:form_panel", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "master_detail", "target": "template:master_detail", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "command_bar", "target": "template:command_bar", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "media_card", "target": "template:media_card", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "product_card", "target": "template:product_card", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "transaction_row", "target": "template:transaction_row", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "payment_method", "target": "template:payment_method", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "feed_card", "target": "template:feed_card", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "state_surface", "target": "template:state_surface", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "metric_tile", "target": "template:metric_tile", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "nested_menu", "target": "template:nested_menu", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "list_item", "target": "template:list_item", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "table_row", "target": "template:table_row", "defaultProps": {}, "description": "", "tags": []},
    {"group": "template", "name": "avatar_item", "target": "template:avatar_item", "defaultProps": {}, "description": "", "tags": []},
    {"group": "chart", "name": "chart", "target": "chart", "defaultProps": {"chartType": "line"}, "description": "Base chart core.", "tags": ["chart", "core"]},
    {"group": "chart", "name": "line", "target": "chart", "defaultProps": {"chartType": "line"}, "description": "line chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_line", "target": "chart", "defaultProps": {"chartType": "line"}, "description": "chart_line alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "line_chart", "target": "chart", "defaultProps": {"chartType": "line"}, "description": "line_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_line_chart", "target": "chart", "defaultProps": {"chartType": "line"}, "description": "media_line_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "bar", "target": "chart", "defaultProps": {"chartType": "bar"}, "description": "bar chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_bar", "target": "chart", "defaultProps": {"chartType": "bar"}, "description": "chart_bar alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "bar_chart", "target": "chart", "defaultProps": {"chartType": "bar"}, "description": "bar_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_bar_chart", "target": "chart", "defaultProps": {"chartType": "bar"}, "description": "media_bar_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "area", "target": "chart", "defaultProps": {"chartType": "area"}, "description": "area chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_area", "target": "chart", "defaultProps": {"chartType": "area"}, "description": "chart_area alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "area_chart", "target": "chart", "defaultProps": {"chartType": "area"}, "description": "area_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_area_chart", "target": "chart", "defaultProps": {"chartType": "area"}, "description": "media_area_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "pie", "target": "chart", "defaultProps": {"chartType": "pie"}, "description": "pie chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_pie", "target": "chart", "defaultProps": {"chartType": "pie"}, "description": "chart_pie alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "pie_chart", "target": "chart", "defaultProps": {"chartType": "pie"}, "description": "pie_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_pie_chart", "target": "chart", "defaultProps": {"chartType": "pie"}, "description": "media_pie_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "donut", "target": "chart", "defaultProps": {"chartType": "donut"}, "description": "donut chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_donut", "target": "chart", "defaultProps": {"chartType": "donut"}, "description": "chart_donut alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "donut_chart", "target": "chart", "defaultProps": {"chartType": "donut"}, "description": "donut_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_donut_chart", "target": "chart", "defaultProps": {"chartType": "donut"}, "description": "media_donut_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "radar", "target": "chart", "defaultProps": {"chartType": "radar"}, "description": "radar chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_radar", "target": "chart", "defaultProps": {"chartType": "radar"}, "description": "chart_radar alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "radar_chart", "target": "chart", "defaultProps": {"chartType": "radar"}, "description": "radar_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_radar_chart", "target": "chart", "defaultProps": {"chartType": "radar"}, "description": "media_radar_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "scatter", "target": "chart", "defaultProps": {"chartType": "scatter"}, "description": "scatter chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_scatter", "target": "chart", "defaultProps": {"chartType": "scatter"}, "description": "chart_scatter alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "scatter_chart", "target": "chart", "defaultProps": {"chartType": "scatter"}, "description": "scatter_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_scatter_chart", "target": "chart", "defaultProps": {"chartType": "scatter"}, "description": "media_scatter_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "bubble", "target": "chart", "defaultProps": {"chartType": "bubble"}, "description": "bubble chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_bubble", "target": "chart", "defaultProps": {"chartType": "bubble"}, "description": "chart_bubble alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "bubble_chart", "target": "chart", "defaultProps": {"chartType": "bubble"}, "description": "bubble_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_bubble_chart", "target": "chart", "defaultProps": {"chartType": "bubble"}, "description": "media_bubble_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "candlestick", "target": "chart", "defaultProps": {"chartType": "candlestick"}, "description": "candlestick chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_candlestick", "target": "chart", "defaultProps": {"chartType": "candlestick"}, "description": "chart_candlestick alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "candlestick_chart", "target": "chart", "defaultProps": {"chartType": "candlestick"}, "description": "candlestick_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_candlestick_chart", "target": "chart", "defaultProps": {"chartType": "candlestick"}, "description": "media_candlestick_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "funnel", "target": "chart", "defaultProps": {"chartType": "funnel"}, "description": "funnel chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_funnel", "target": "chart", "defaultProps": {"chartType": "funnel"}, "description": "chart_funnel alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "funnel_chart", "target": "chart", "defaultProps": {"chartType": "funnel"}, "description": "funnel_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_funnel_chart", "target": "chart", "defaultProps": {"chartType": "funnel"}, "description": "media_funnel_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "waterfall", "target": "chart", "defaultProps": {"chartType": "waterfall"}, "description": "waterfall chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_waterfall", "target": "chart", "defaultProps": {"chartType": "waterfall"}, "description": "chart_waterfall alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "waterfall_chart", "target": "chart", "defaultProps": {"chartType": "waterfall"}, "description": "waterfall_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_waterfall_chart", "target": "chart", "defaultProps": {"chartType": "waterfall"}, "description": "media_waterfall_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "histogram", "target": "chart", "defaultProps": {"chartType": "histogram"}, "description": "histogram chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_histogram", "target": "chart", "defaultProps": {"chartType": "histogram"}, "description": "chart_histogram alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "histogram_chart", "target": "chart", "defaultProps": {"chartType": "histogram"}, "description": "histogram_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_histogram_chart", "target": "chart", "defaultProps": {"chartType": "histogram"}, "description": "media_histogram_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "gauge", "target": "chart", "defaultProps": {"chartType": "gauge"}, "description": "gauge chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_gauge", "target": "chart", "defaultProps": {"chartType": "gauge"}, "description": "chart_gauge alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "gauge_chart", "target": "chart", "defaultProps": {"chartType": "gauge"}, "description": "gauge_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_gauge_chart", "target": "chart", "defaultProps": {"chartType": "gauge"}, "description": "media_gauge_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "sparkline", "target": "chart", "defaultProps": {"chartType": "sparkline"}, "description": "sparkline chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_sparkline", "target": "chart", "defaultProps": {"chartType": "sparkline"}, "description": "chart_sparkline alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "sparkline_chart", "target": "chart", "defaultProps": {"chartType": "sparkline"}, "description": "sparkline_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_sparkline_chart", "target": "chart", "defaultProps": {"chartType": "sparkline"}, "description": "media_sparkline_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "treemap", "target": "chart", "defaultProps": {"chartType": "treemap"}, "description": "treemap chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_treemap", "target": "chart", "defaultProps": {"chartType": "treemap"}, "description": "chart_treemap alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "treemap_chart", "target": "chart", "defaultProps": {"chartType": "treemap"}, "description": "treemap_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_treemap_chart", "target": "chart", "defaultProps": {"chartType": "treemap"}, "description": "media_treemap_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "sankey", "target": "chart", "defaultProps": {"chartType": "sankey"}, "description": "sankey chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "chart_sankey", "target": "chart", "defaultProps": {"chartType": "sankey"}, "description": "chart_sankey alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "sankey_chart", "target": "chart", "defaultProps": {"chartType": "sankey"}, "description": "sankey_chart alias.", "tags": ["chart", "alias"]},
    {"group": "chart", "name": "media_sankey_chart", "target": "chart", "defaultProps": {"chartType": "sankey"}, "description": "media_sankey_chart compatibility alias.", "tags": ["chart", "compat"]},
    {"group": "chart", "name": "media:chart", "target": "chart", "defaultProps": {"chartType": "line"}, "description": "Backward-compatible media chart alias.", "tags": ["chart", "compat"]},
  ];
  setUpAll(() => bootstrapQuantum(includeConnect: true));

  group('alias query matrix', () {
    test('all aliases resolve after bootstrap', () {
      for (final alias in aliases) {
        expect(vm.getAlias(alias['name'] as String), isNotNull,
            reason: 'Missing ${alias['group']}:${alias['name']}');
      }
    });

    test('row query by exact name finds the alias', () {
      final entry = vm.registryEntry("row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "row");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('row query by entry id finds the alias', () {
      final entry = vm.registryEntry("row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('row query by engine finds the alias', () {
      final entry = vm.registryEntry("row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('row query by kind finds the alias', () {
      final entry = vm.registryEntry("row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('row query by params string finds the alias', () {
      final entry = vm.registryEntry("row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('row query by description finds the alias', () {
      final entry = vm.registryEntry("row", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('col query by exact name finds the alias', () {
      final entry = vm.registryEntry("col", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "col");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('col query by entry id finds the alias', () {
      final entry = vm.registryEntry("col", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('col query by engine finds the alias', () {
      final entry = vm.registryEntry("col", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('col query by kind finds the alias', () {
      final entry = vm.registryEntry("col", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('col query by params string finds the alias', () {
      final entry = vm.registryEntry("col", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('col query by description finds the alias', () {
      final entry = vm.registryEntry("col", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stack query by exact name finds the alias', () {
      final entry = vm.registryEntry("stack", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "stack");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stack query by entry id finds the alias', () {
      final entry = vm.registryEntry("stack", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stack query by engine finds the alias', () {
      final entry = vm.registryEntry("stack", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stack query by kind finds the alias', () {
      final entry = vm.registryEntry("stack", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stack query by params string finds the alias', () {
      final entry = vm.registryEntry("stack", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stack query by description finds the alias', () {
      final entry = vm.registryEntry("stack", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wrap query by exact name finds the alias', () {
      final entry = vm.registryEntry("wrap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "wrap");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wrap query by entry id finds the alias', () {
      final entry = vm.registryEntry("wrap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wrap query by engine finds the alias', () {
      final entry = vm.registryEntry("wrap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wrap query by kind finds the alias', () {
      final entry = vm.registryEntry("wrap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wrap query by params string finds the alias', () {
      final entry = vm.registryEntry("wrap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wrap query by description finds the alias', () {
      final entry = vm.registryEntry("wrap", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('grid query by exact name finds the alias', () {
      final entry = vm.registryEntry("grid", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "grid");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('grid query by entry id finds the alias', () {
      final entry = vm.registryEntry("grid", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('grid query by engine finds the alias', () {
      final entry = vm.registryEntry("grid", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('grid query by kind finds the alias', () {
      final entry = vm.registryEntry("grid", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('grid query by params string finds the alias', () {
      final entry = vm.registryEntry("grid", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('grid query by description finds the alias', () {
      final entry = vm.registryEntry("grid", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('masonry query by exact name finds the alias', () {
      final entry = vm.registryEntry("masonry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "masonry");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('masonry query by entry id finds the alias', () {
      final entry = vm.registryEntry("masonry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('masonry query by engine finds the alias', () {
      final entry = vm.registryEntry("masonry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('masonry query by kind finds the alias', () {
      final entry = vm.registryEntry("masonry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('masonry query by params string finds the alias', () {
      final entry = vm.registryEntry("masonry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('masonry query by description finds the alias', () {
      final entry = vm.registryEntry("masonry", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('card query by exact name finds the alias', () {
      final entry = vm.registryEntry("card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "card");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('card query by entry id finds the alias', () {
      final entry = vm.registryEntry("card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('card query by engine finds the alias', () {
      final entry = vm.registryEntry("card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('card query by kind finds the alias', () {
      final entry = vm.registryEntry("card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('card query by params string finds the alias', () {
      final entry = vm.registryEntry("card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('card query by description finds the alias', () {
      final entry = vm.registryEntry("card", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split query by exact name finds the alias', () {
      final entry = vm.registryEntry("split", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "split");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split query by entry id finds the alias', () {
      final entry = vm.registryEntry("split", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split query by engine finds the alias', () {
      final entry = vm.registryEntry("split", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split query by kind finds the alias', () {
      final entry = vm.registryEntry("split", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split query by params string finds the alias', () {
      final entry = vm.registryEntry("split", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split query by description finds the alias', () {
      final entry = vm.registryEntry("split", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('morph query by exact name finds the alias', () {
      final entry = vm.registryEntry("morph", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "morph");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('morph query by entry id finds the alias', () {
      final entry = vm.registryEntry("morph", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('morph query by engine finds the alias', () {
      final entry = vm.registryEntry("morph", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('morph query by kind finds the alias', () {
      final entry = vm.registryEntry("morph", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('morph query by params string finds the alias', () {
      final entry = vm.registryEntry("morph", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('morph query by description finds the alias', () {
      final entry = vm.registryEntry("morph", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface query by exact name finds the alias', () {
      final entry = vm.registryEntry("surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "surface");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface query by entry id finds the alias', () {
      final entry = vm.registryEntry("surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface query by engine finds the alias', () {
      final entry = vm.registryEntry("surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface query by kind finds the alias', () {
      final entry = vm.registryEntry("surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface query by params string finds the alias', () {
      final entry = vm.registryEntry("surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface query by description finds the alias', () {
      final entry = vm.registryEntry("surface", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shell query by engine finds the alias', () {
      final entry = vm.registryEntry("shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shell query by kind finds the alias', () {
      final entry = vm.registryEntry("shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shell query by params string finds the alias', () {
      final entry = vm.registryEntry("shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shell query by description finds the alias', () {
      final entry = vm.registryEntry("shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('viewport query by exact name finds the alias', () {
      final entry = vm.registryEntry("viewport", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "viewport");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('viewport query by entry id finds the alias', () {
      final entry = vm.registryEntry("viewport", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('viewport query by engine finds the alias', () {
      final entry = vm.registryEntry("viewport", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('viewport query by kind finds the alias', () {
      final entry = vm.registryEntry("viewport", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('viewport query by params string finds the alias', () {
      final entry = vm.registryEntry("viewport", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('viewport query by description finds the alias', () {
      final entry = vm.registryEntry("viewport", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('responsive query by exact name finds the alias', () {
      final entry = vm.registryEntry("responsive", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "responsive");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('responsive query by entry id finds the alias', () {
      final entry = vm.registryEntry("responsive", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('responsive query by engine finds the alias', () {
      final entry = vm.registryEntry("responsive", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('responsive query by kind finds the alias', () {
      final entry = vm.registryEntry("responsive", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('responsive query by params string finds the alias', () {
      final entry = vm.registryEntry("responsive", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('responsive query by description finds the alias', () {
      final entry = vm.registryEntry("responsive", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('measure query by exact name finds the alias', () {
      final entry = vm.registryEntry("measure", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "measure");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('measure query by entry id finds the alias', () {
      final entry = vm.registryEntry("measure", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('measure query by engine finds the alias', () {
      final entry = vm.registryEntry("measure", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('measure query by kind finds the alias', () {
      final entry = vm.registryEntry("measure", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('measure query by params string finds the alias', () {
      final entry = vm.registryEntry("measure", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('measure query by description finds the alias', () {
      final entry = vm.registryEntry("measure", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('builder query by exact name finds the alias', () {
      final entry = vm.registryEntry("builder", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "builder");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('builder query by entry id finds the alias', () {
      final entry = vm.registryEntry("builder", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('builder query by engine finds the alias', () {
      final entry = vm.registryEntry("builder", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('builder query by kind finds the alias', () {
      final entry = vm.registryEntry("builder", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('builder query by params string finds the alias', () {
      final entry = vm.registryEntry("builder", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('builder query by description finds the alias', () {
      final entry = vm.registryEntry("builder", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('layer query by exact name finds the alias', () {
      final entry = vm.registryEntry("layer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "layer");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('layer query by entry id finds the alias', () {
      final entry = vm.registryEntry("layer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('layer query by engine finds the alias', () {
      final entry = vm.registryEntry("layer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('layer query by kind finds the alias', () {
      final entry = vm.registryEntry("layer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('layer query by params string finds the alias', () {
      final entry = vm.registryEntry("layer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('layer query by description finds the alias', () {
      final entry = vm.registryEntry("layer", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('matrix query by exact name finds the alias', () {
      final entry = vm.registryEntry("matrix", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "matrix");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('matrix query by entry id finds the alias', () {
      final entry = vm.registryEntry("matrix", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('matrix query by engine finds the alias', () {
      final entry = vm.registryEntry("matrix", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('matrix query by kind finds the alias', () {
      final entry = vm.registryEntry("matrix", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('matrix query by params string finds the alias', () {
      final entry = vm.registryEntry("matrix", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('matrix query by description finds the alias', () {
      final entry = vm.registryEntry("matrix", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('raw_pointer query by exact name finds the alias', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "raw_pointer");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('raw_pointer query by entry id finds the alias', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('raw_pointer query by engine finds the alias', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('raw_pointer query by kind finds the alias', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('raw_pointer query by params string finds the alias', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('raw_pointer query by description finds the alias', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pointer query by exact name finds the alias', () {
      final entry = vm.registryEntry("pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "pointer");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pointer query by entry id finds the alias', () {
      final entry = vm.registryEntry("pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pointer query by engine finds the alias', () {
      final entry = vm.registryEntry("pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pointer query by kind finds the alias', () {
      final entry = vm.registryEntry("pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pointer query by params string finds the alias', () {
      final entry = vm.registryEntry("pointer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pointer query by description finds the alias', () {
      final entry = vm.registryEntry("pointer", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focus query by exact name finds the alias', () {
      final entry = vm.registryEntry("focus", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "focus");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focus query by entry id finds the alias', () {
      final entry = vm.registryEntry("focus", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focus query by engine finds the alias', () {
      final entry = vm.registryEntry("focus", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focus query by kind finds the alias', () {
      final entry = vm.registryEntry("focus", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focus query by params string finds the alias', () {
      final entry = vm.registryEntry("focus", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focus query by description finds the alias', () {
      final entry = vm.registryEntry("focus", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('button query by exact name finds the alias', () {
      final entry = vm.registryEntry("button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "button");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('button query by entry id finds the alias', () {
      final entry = vm.registryEntry("button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('button query by engine finds the alias', () {
      final entry = vm.registryEntry("button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('button query by kind finds the alias', () {
      final entry = vm.registryEntry("button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('button query by params string finds the alias', () {
      final entry = vm.registryEntry("button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('button query by description finds the alias', () {
      final entry = vm.registryEntry("button", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tap query by exact name finds the alias', () {
      final entry = vm.registryEntry("tap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "tap");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tap query by entry id finds the alias', () {
      final entry = vm.registryEntry("tap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tap query by engine finds the alias', () {
      final entry = vm.registryEntry("tap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tap query by kind finds the alias', () {
      final entry = vm.registryEntry("tap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tap query by params string finds the alias', () {
      final entry = vm.registryEntry("tap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tap query by description finds the alias', () {
      final entry = vm.registryEntry("tap", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('press query by exact name finds the alias', () {
      final entry = vm.registryEntry("press", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "press");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('press query by entry id finds the alias', () {
      final entry = vm.registryEntry("press", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('press query by engine finds the alias', () {
      final entry = vm.registryEntry("press", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('press query by kind finds the alias', () {
      final entry = vm.registryEntry("press", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('press query by params string finds the alias', () {
      final entry = vm.registryEntry("press", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('press query by description finds the alias', () {
      final entry = vm.registryEntry("press", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hover_action query by exact name finds the alias', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "hover_action");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hover_action query by entry id finds the alias', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hover_action query by engine finds the alias', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hover_action query by kind finds the alias', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hover_action query by params string finds the alias', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hover_action query by description finds the alias', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('icon_button query by exact name finds the alias', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "icon_button");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('icon_button query by entry id finds the alias', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('icon_button query by engine finds the alias', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('icon_button query by kind finds the alias', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('icon_button query by params string finds the alias', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('icon_button query by description finds the alias', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chip query by exact name finds the alias', () {
      final entry = vm.registryEntry("chip", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chip");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chip query by entry id finds the alias', () {
      final entry = vm.registryEntry("chip", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chip query by engine finds the alias', () {
      final entry = vm.registryEntry("chip", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chip query by kind finds the alias', () {
      final entry = vm.registryEntry("chip", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chip query by params string finds the alias', () {
      final entry = vm.registryEntry("chip", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chip query by description finds the alias', () {
      final entry = vm.registryEntry("chip", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('badge query by exact name finds the alias', () {
      final entry = vm.registryEntry("badge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "badge");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('badge query by entry id finds the alias', () {
      final entry = vm.registryEntry("badge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('badge query by engine finds the alias', () {
      final entry = vm.registryEntry("badge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('badge query by kind finds the alias', () {
      final entry = vm.registryEntry("badge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('badge query by params string finds the alias', () {
      final entry = vm.registryEntry("badge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('badge query by description finds the alias', () {
      final entry = vm.registryEntry("badge", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('text_field query by exact name finds the alias', () {
      final entry = vm.registryEntry("text_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "text_field");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('text_field query by entry id finds the alias', () {
      final entry = vm.registryEntry("text_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('text_field query by engine finds the alias', () {
      final entry = vm.registryEntry("text_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('text_field query by kind finds the alias', () {
      final entry = vm.registryEntry("text_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('text_field query by params string finds the alias', () {
      final entry = vm.registryEntry("text_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('text_field query by description finds the alias', () {
      final entry = vm.registryEntry("text_field", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('textarea query by exact name finds the alias', () {
      final entry = vm.registryEntry("textarea", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "textarea");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('textarea query by entry id finds the alias', () {
      final entry = vm.registryEntry("textarea", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('textarea query by engine finds the alias', () {
      final entry = vm.registryEntry("textarea", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('textarea query by kind finds the alias', () {
      final entry = vm.registryEntry("textarea", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('textarea query by params string finds the alias', () {
      final entry = vm.registryEntry("textarea", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('textarea query by description finds the alias', () {
      final entry = vm.registryEntry("textarea", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('email_field query by exact name finds the alias', () {
      final entry = vm.registryEntry("email_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "email_field");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('email_field query by entry id finds the alias', () {
      final entry = vm.registryEntry("email_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('email_field query by engine finds the alias', () {
      final entry = vm.registryEntry("email_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('email_field query by kind finds the alias', () {
      final entry = vm.registryEntry("email_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('email_field query by params string finds the alias', () {
      final entry = vm.registryEntry("email_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('email_field query by description finds the alias', () {
      final entry = vm.registryEntry("email_field", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('password_field query by exact name finds the alias', () {
      final entry = vm.registryEntry("password_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "password_field");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('password_field query by entry id finds the alias', () {
      final entry = vm.registryEntry("password_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('password_field query by engine finds the alias', () {
      final entry = vm.registryEntry("password_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('password_field query by kind finds the alias', () {
      final entry = vm.registryEntry("password_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('password_field query by params string finds the alias', () {
      final entry = vm.registryEntry("password_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('password_field query by description finds the alias', () {
      final entry = vm.registryEntry("password_field", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('number_field query by exact name finds the alias', () {
      final entry = vm.registryEntry("number_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "number_field");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('number_field query by entry id finds the alias', () {
      final entry = vm.registryEntry("number_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('number_field query by engine finds the alias', () {
      final entry = vm.registryEntry("number_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('number_field query by kind finds the alias', () {
      final entry = vm.registryEntry("number_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('number_field query by params string finds the alias', () {
      final entry = vm.registryEntry("number_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('number_field query by description finds the alias', () {
      final entry = vm.registryEntry("number_field", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_field query by exact name finds the alias', () {
      final entry = vm.registryEntry("search_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "search_field");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_field query by entry id finds the alias', () {
      final entry = vm.registryEntry("search_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_field query by engine finds the alias', () {
      final entry = vm.registryEntry("search_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_field query by kind finds the alias', () {
      final entry = vm.registryEntry("search_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_field query by params string finds the alias', () {
      final entry = vm.registryEntry("search_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_field query by description finds the alias', () {
      final entry = vm.registryEntry("search_field", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('date_field query by exact name finds the alias', () {
      final entry = vm.registryEntry("date_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "date_field");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('date_field query by entry id finds the alias', () {
      final entry = vm.registryEntry("date_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('date_field query by engine finds the alias', () {
      final entry = vm.registryEntry("date_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('date_field query by kind finds the alias', () {
      final entry = vm.registryEntry("date_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('date_field query by params string finds the alias', () {
      final entry = vm.registryEntry("date_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('date_field query by description finds the alias', () {
      final entry = vm.registryEntry("date_field", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('select_field query by exact name finds the alias', () {
      final entry = vm.registryEntry("select_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "select_field");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('select_field query by entry id finds the alias', () {
      final entry = vm.registryEntry("select_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('select_field query by engine finds the alias', () {
      final entry = vm.registryEntry("select_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('select_field query by kind finds the alias', () {
      final entry = vm.registryEntry("select_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('select_field query by params string finds the alias', () {
      final entry = vm.registryEntry("select_field", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('select_field query by description finds the alias', () {
      final entry = vm.registryEntry("select_field", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('toggle query by exact name finds the alias', () {
      final entry = vm.registryEntry("toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "toggle");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('toggle query by entry id finds the alias', () {
      final entry = vm.registryEntry("toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('toggle query by engine finds the alias', () {
      final entry = vm.registryEntry("toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('toggle query by kind finds the alias', () {
      final entry = vm.registryEntry("toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('toggle query by params string finds the alias', () {
      final entry = vm.registryEntry("toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('toggle query by description finds the alias', () {
      final entry = vm.registryEntry("toggle", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('slider query by exact name finds the alias', () {
      final entry = vm.registryEntry("slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "slider");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('slider query by entry id finds the alias', () {
      final entry = vm.registryEntry("slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('slider query by engine finds the alias', () {
      final entry = vm.registryEntry("slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('slider query by kind finds the alias', () {
      final entry = vm.registryEntry("slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('slider query by params string finds the alias', () {
      final entry = vm.registryEntry("slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('slider query by description finds the alias', () {
      final entry = vm.registryEntry("slider", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('image query by exact name finds the alias', () {
      final entry = vm.registryEntry("image", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "image");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('image query by entry id finds the alias', () {
      final entry = vm.registryEntry("image", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('image query by engine finds the alias', () {
      final entry = vm.registryEntry("image", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('image query by kind finds the alias', () {
      final entry = vm.registryEntry("image", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('image query by params string finds the alias', () {
      final entry = vm.registryEntry("image", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('image query by description finds the alias', () {
      final entry = vm.registryEntry("image", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar query by exact name finds the alias', () {
      final entry = vm.registryEntry("avatar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "avatar");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar query by entry id finds the alias', () {
      final entry = vm.registryEntry("avatar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar query by engine finds the alias', () {
      final entry = vm.registryEntry("avatar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar query by kind finds the alias', () {
      final entry = vm.registryEntry("avatar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar query by params string finds the alias', () {
      final entry = vm.registryEntry("avatar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar query by description finds the alias', () {
      final entry = vm.registryEntry("avatar", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('video query by exact name finds the alias', () {
      final entry = vm.registryEntry("video", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "video");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('video query by entry id finds the alias', () {
      final entry = vm.registryEntry("video", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('video query by engine finds the alias', () {
      final entry = vm.registryEntry("video", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('video query by kind finds the alias', () {
      final entry = vm.registryEntry("video", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('video query by params string finds the alias', () {
      final entry = vm.registryEntry("video", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('video query by description finds the alias', () {
      final entry = vm.registryEntry("video", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by engine finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by kind finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by params string finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by description finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver_plane query by exact name finds the alias', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sliver_plane");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver_plane query by entry id finds the alias', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver_plane query by engine finds the alias', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver_plane query by kind finds the alias', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver_plane query by params string finds the alias', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver_plane query by description finds the alias', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver query by exact name finds the alias', () {
      final entry = vm.registryEntry("sliver", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sliver");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver query by entry id finds the alias', () {
      final entry = vm.registryEntry("sliver", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver query by engine finds the alias', () {
      final entry = vm.registryEntry("sliver", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver query by kind finds the alias', () {
      final entry = vm.registryEntry("sliver", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver query by params string finds the alias', () {
      final entry = vm.registryEntry("sliver", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sliver query by description finds the alias', () {
      final entry = vm.registryEntry("sliver", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_entry query by exact name finds the alias', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "overlay_entry");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_entry query by entry id finds the alias', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_entry query by engine finds the alias', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_entry query by kind finds the alias', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_entry query by params string finds the alias', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_entry query by description finds the alias', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay query by exact name finds the alias', () {
      final entry = vm.registryEntry("overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "overlay");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay query by entry id finds the alias', () {
      final entry = vm.registryEntry("overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay query by engine finds the alias', () {
      final entry = vm.registryEntry("overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay query by kind finds the alias', () {
      final entry = vm.registryEntry("overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay query by params string finds the alias', () {
      final entry = vm.registryEntry("overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay query by description finds the alias', () {
      final entry = vm.registryEntry("overlay", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('dialog query by exact name finds the alias', () {
      final entry = vm.registryEntry("dialog", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "dialog");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('dialog query by entry id finds the alias', () {
      final entry = vm.registryEntry("dialog", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('dialog query by engine finds the alias', () {
      final entry = vm.registryEntry("dialog", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('dialog query by kind finds the alias', () {
      final entry = vm.registryEntry("dialog", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('dialog query by params string finds the alias', () {
      final entry = vm.registryEntry("dialog", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('dialog query by description finds the alias', () {
      final entry = vm.registryEntry("dialog", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('drawer query by exact name finds the alias', () {
      final entry = vm.registryEntry("drawer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "drawer");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('drawer query by entry id finds the alias', () {
      final entry = vm.registryEntry("drawer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('drawer query by engine finds the alias', () {
      final entry = vm.registryEntry("drawer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('drawer query by kind finds the alias', () {
      final entry = vm.registryEntry("drawer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('drawer query by params string finds the alias', () {
      final entry = vm.registryEntry("drawer", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('drawer query by description finds the alias', () {
      final entry = vm.registryEntry("drawer", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sheet query by exact name finds the alias', () {
      final entry = vm.registryEntry("sheet", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sheet");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sheet query by entry id finds the alias', () {
      final entry = vm.registryEntry("sheet", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sheet query by engine finds the alias', () {
      final entry = vm.registryEntry("sheet", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sheet query by kind finds the alias', () {
      final entry = vm.registryEntry("sheet", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sheet query by params string finds the alias', () {
      final entry = vm.registryEntry("sheet", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sheet query by description finds the alias', () {
      final entry = vm.registryEntry("sheet", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover query by exact name finds the alias', () {
      final entry = vm.registryEntry("popover", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "popover");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover query by entry id finds the alias', () {
      final entry = vm.registryEntry("popover", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover query by engine finds the alias', () {
      final entry = vm.registryEntry("popover", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover query by kind finds the alias', () {
      final entry = vm.registryEntry("popover", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover query by params string finds the alias', () {
      final entry = vm.registryEntry("popover", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover query by description finds the alias', () {
      final entry = vm.registryEntry("popover", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow query by exact name finds the alias', () {
      final entry = vm.registryEntry("flow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "flow");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow query by entry id finds the alias', () {
      final entry = vm.registryEntry("flow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow query by engine finds the alias', () {
      final entry = vm.registryEntry("flow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow query by kind finds the alias', () {
      final entry = vm.registryEntry("flow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow query by params string finds the alias', () {
      final entry = vm.registryEntry("flow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow query by description finds the alias', () {
      final entry = vm.registryEntry("flow", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('workflow query by exact name finds the alias', () {
      final entry = vm.registryEntry("workflow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "workflow");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('workflow query by entry id finds the alias', () {
      final entry = vm.registryEntry("workflow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('workflow query by engine finds the alias', () {
      final entry = vm.registryEntry("workflow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('workflow query by kind finds the alias', () {
      final entry = vm.registryEntry("workflow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('workflow query by params string finds the alias', () {
      final entry = vm.registryEntry("workflow", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('workflow query by description finds the alias', () {
      final entry = vm.registryEntry("workflow", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_scope query by exact name finds the alias', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "form_scope");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_scope query by entry id finds the alias', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_scope query by engine finds the alias', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_scope query by kind finds the alias', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_scope query by params string finds the alias', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_scope query by description finds the alias', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by exact name finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "tabs");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by entry id finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by engine finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by kind finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by params string finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by description finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segment query by exact name finds the alias', () {
      final entry = vm.registryEntry("segment", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "segment");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segment query by entry id finds the alias', () {
      final entry = vm.registryEntry("segment", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segment query by engine finds the alias', () {
      final entry = vm.registryEntry("segment", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segment query by kind finds the alias', () {
      final entry = vm.registryEntry("segment", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segment query by params string finds the alias', () {
      final entry = vm.registryEntry("segment", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segment query by description finds the alias', () {
      final entry = vm.registryEntry("segment", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by exact name finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "stepper");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by entry id finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by engine finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by kind finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by params string finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by description finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by exact name finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "accordion");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by entry id finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by engine finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by kind finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by params string finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by description finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shader query by exact name finds the alias', () {
      final entry = vm.registryEntry("shader", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "shader");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shader query by entry id finds the alias', () {
      final entry = vm.registryEntry("shader", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shader query by engine finds the alias', () {
      final entry = vm.registryEntry("shader", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shader query by kind finds the alias', () {
      final entry = vm.registryEntry("shader", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shader query by params string finds the alias', () {
      final entry = vm.registryEntry("shader", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('shader query by description finds the alias', () {
      final entry = vm.registryEntry("shader", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sync_scroll query by exact name finds the alias', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sync_scroll");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sync_scroll query by entry id finds the alias', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sync_scroll query by engine finds the alias', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sync_scroll query by kind finds the alias', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sync_scroll query by params string finds the alias', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sync_scroll query by description finds the alias', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('worker query by exact name finds the alias', () {
      final entry = vm.registryEntry("worker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "worker");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('worker query by entry id finds the alias', () {
      final entry = vm.registryEntry("worker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('worker query by engine finds the alias', () {
      final entry = vm.registryEntry("worker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('worker query by kind finds the alias', () {
      final entry = vm.registryEntry("worker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('worker query by params string finds the alias', () {
      final entry = vm.registryEntry("worker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('worker query by description finds the alias', () {
      final entry = vm.registryEntry("worker", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('ticker query by exact name finds the alias', () {
      final entry = vm.registryEntry("ticker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "ticker");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('ticker query by entry id finds the alias', () {
      final entry = vm.registryEntry("ticker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('ticker query by engine finds the alias', () {
      final entry = vm.registryEntry("ticker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('ticker query by kind finds the alias', () {
      final entry = vm.registryEntry("ticker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('ticker query by params string finds the alias', () {
      final entry = vm.registryEntry("ticker", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('ticker query by description finds the alias', () {
      final entry = vm.registryEntry("ticker", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('omega_macro query by exact name finds the alias', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "omega_macro");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('omega_macro query by entry id finds the alias', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('omega_macro query by engine finds the alias', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('omega_macro query by kind finds the alias', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('omega_macro query by params string finds the alias', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('omega_macro query by description finds the alias', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('decorate query by exact name finds the alias', () {
      final entry = vm.registryEntry("decorate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "decorate");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('decorate query by entry id finds the alias', () {
      final entry = vm.registryEntry("decorate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('decorate query by engine finds the alias', () {
      final entry = vm.registryEntry("decorate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('decorate query by kind finds the alias', () {
      final entry = vm.registryEntry("decorate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('decorate query by params string finds the alias', () {
      final entry = vm.registryEntry("decorate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('decorate query by description finds the alias', () {
      final entry = vm.registryEntry("decorate", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('highlight query by exact name finds the alias', () {
      final entry = vm.registryEntry("highlight", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "highlight");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('highlight query by entry id finds the alias', () {
      final entry = vm.registryEntry("highlight", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('highlight query by engine finds the alias', () {
      final entry = vm.registryEntry("highlight", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('highlight query by kind finds the alias', () {
      final entry = vm.registryEntry("highlight", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('highlight query by params string finds the alias', () {
      final entry = vm.registryEntry("highlight", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('highlight query by description finds the alias', () {
      final entry = vm.registryEntry("highlight", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('markup query by exact name finds the alias', () {
      final entry = vm.registryEntry("markup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "markup");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('markup query by entry id finds the alias', () {
      final entry = vm.registryEntry("markup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('markup query by engine finds the alias', () {
      final entry = vm.registryEntry("markup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('markup query by kind finds the alias', () {
      final entry = vm.registryEntry("markup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('markup query by params string finds the alias', () {
      final entry = vm.registryEntry("markup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('markup query by description finds the alias', () {
      final entry = vm.registryEntry("markup", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animation query by exact name finds the alias', () {
      final entry = vm.registryEntry("animation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "animation");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animation query by entry id finds the alias', () {
      final entry = vm.registryEntry("animation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animation query by engine finds the alias', () {
      final entry = vm.registryEntry("animation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animation query by kind finds the alias', () {
      final entry = vm.registryEntry("animation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animation query by params string finds the alias', () {
      final entry = vm.registryEntry("animation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animation query by description finds the alias', () {
      final entry = vm.registryEntry("animation", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('motion query by exact name finds the alias', () {
      final entry = vm.registryEntry("motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "motion");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('motion query by entry id finds the alias', () {
      final entry = vm.registryEntry("motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('motion query by engine finds the alias', () {
      final entry = vm.registryEntry("motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('motion query by kind finds the alias', () {
      final entry = vm.registryEntry("motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('motion query by params string finds the alias', () {
      final entry = vm.registryEntry("motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('motion query by description finds the alias', () {
      final entry = vm.registryEntry("motion", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transition query by exact name finds the alias', () {
      final entry = vm.registryEntry("transition", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "transition");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transition query by entry id finds the alias', () {
      final entry = vm.registryEntry("transition", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transition query by engine finds the alias', () {
      final entry = vm.registryEntry("transition", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transition query by kind finds the alias', () {
      final entry = vm.registryEntry("transition", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transition query by params string finds the alias', () {
      final entry = vm.registryEntry("transition", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transition query by description finds the alias', () {
      final entry = vm.registryEntry("transition", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animate query by exact name finds the alias', () {
      final entry = vm.registryEntry("animate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "animate");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animate query by entry id finds the alias', () {
      final entry = vm.registryEntry("animate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animate query by engine finds the alias', () {
      final entry = vm.registryEntry("animate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animate query by kind finds the alias', () {
      final entry = vm.registryEntry("animate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animate query by params string finds the alias', () {
      final entry = vm.registryEntry("animate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('animate query by description finds the alias', () {
      final entry = vm.registryEntry("animate", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('glass_motion query by exact name finds the alias', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "glass_motion");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('glass_motion query by entry id finds the alias', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('glass_motion query by engine finds the alias', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('glass_motion query by kind finds the alias', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('glass_motion query by params string finds the alias', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('glass_motion query by description finds the alias', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_surface query by exact name finds the alias', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "visual_surface");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_surface query by entry id finds the alias', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_surface query by engine finds the alias', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_surface query by kind finds the alias', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_surface query by params string finds the alias', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_surface query by description finds the alias', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "visual_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_shell query by description finds the alias', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_scene query by exact name finds the alias', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "visual_scene");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_scene query by entry id finds the alias', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_scene query by engine finds the alias', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_scene query by kind finds the alias', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_scene query by params string finds the alias', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_scene query by description finds the alias', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_overlay query by exact name finds the alias', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "visual_overlay");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_overlay query by entry id finds the alias', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_overlay query by engine finds the alias', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_overlay query by kind finds the alias', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_overlay query by params string finds the alias', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_overlay query by description finds the alias', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_delegate query by exact name finds the alias', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "visual_delegate");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_delegate query by entry id finds the alias', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_delegate query by engine finds the alias', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_delegate query by kind finds the alias', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_delegate query by params string finds the alias', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('visual_delegate query by description finds the alias', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_lifecycle query by exact name finds the alias', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "hook_lifecycle");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_lifecycle query by entry id finds the alias', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_lifecycle query by engine finds the alias', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_lifecycle query by kind finds the alias', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_lifecycle query by params string finds the alias', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_lifecycle query by description finds the alias', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_effect query by exact name finds the alias', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "hook_effect");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_effect query by entry id finds the alias', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_effect query by engine finds the alias', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_effect query by kind finds the alias', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_effect query by params string finds the alias', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_effect query by description finds the alias', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_scope query by exact name finds the alias', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "hook_scope");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_scope query by entry id finds the alias', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_scope query by engine finds the alias', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_scope query by kind finds the alias', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_scope query by params string finds the alias', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_scope query by description finds the alias', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_bridge query by exact name finds the alias', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "hook_bridge");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_bridge query by entry id finds the alias', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_bridge query by engine finds the alias', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_bridge query by kind finds the alias', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_bridge query by params string finds the alias', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hook_bridge query by description finds the alias', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('backButton query by exact name finds the alias', () {
      final entry = vm.registryEntry("backButton", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "backButton");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('backButton query by entry id finds the alias', () {
      final entry = vm.registryEntry("backButton", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('backButton query by engine finds the alias', () {
      final entry = vm.registryEntry("backButton", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('backButton query by kind finds the alias', () {
      final entry = vm.registryEntry("backButton", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('backButton query by params string finds the alias', () {
      final entry = vm.registryEntry("backButton", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('backButton query by description finds the alias', () {
      final entry = vm.registryEntry("backButton", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pressGesture query by exact name finds the alias', () {
      final entry = vm.registryEntry("pressGesture", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "pressGesture");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pressGesture query by entry id finds the alias', () {
      final entry = vm.registryEntry("pressGesture", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pressGesture query by engine finds the alias', () {
      final entry = vm.registryEntry("pressGesture", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pressGesture query by kind finds the alias', () {
      final entry = vm.registryEntry("pressGesture", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pressGesture query by params string finds the alias', () {
      final entry = vm.registryEntry("pressGesture", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pressGesture query by description finds the alias', () {
      final entry = vm.registryEntry("pressGesture", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('connectSlot query by exact name finds the alias', () {
      final entry = vm.registryEntry("connectSlot", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "connectSlot");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('connectSlot query by entry id finds the alias', () {
      final entry = vm.registryEntry("connectSlot", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('connectSlot query by engine finds the alias', () {
      final entry = vm.registryEntry("connectSlot", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('connectSlot query by kind finds the alias', () {
      final entry = vm.registryEntry("connectSlot", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('connectSlot query by params string finds the alias', () {
      final entry = vm.registryEntry("connectSlot", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('connectSlot query by description finds the alias', () {
      final entry = vm.registryEntry("connectSlot", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focusReveal query by exact name finds the alias', () {
      final entry = vm.registryEntry("focusReveal", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "focusReveal");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focusReveal query by entry id finds the alias', () {
      final entry = vm.registryEntry("focusReveal", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focusReveal query by engine finds the alias', () {
      final entry = vm.registryEntry("focusReveal", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focusReveal query by kind finds the alias', () {
      final entry = vm.registryEntry("focusReveal", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focusReveal query by params string finds the alias', () {
      final entry = vm.registryEntry("focusReveal", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('focusReveal query by description finds the alias', () {
      final entry = vm.registryEntry("focusReveal", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('channelText query by exact name finds the alias', () {
      final entry = vm.registryEntry("channelText", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "channelText");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('channelText query by entry id finds the alias', () {
      final entry = vm.registryEntry("channelText", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('channelText query by engine finds the alias', () {
      final entry = vm.registryEntry("channelText", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('channelText query by kind finds the alias', () {
      final entry = vm.registryEntry("channelText", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('channelText query by params string finds the alias', () {
      final entry = vm.registryEntry("channelText", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('channelText query by description finds the alias', () {
      final entry = vm.registryEntry("channelText", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('behavior query by exact name finds the alias', () {
      final entry = vm.registryEntry("behavior", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "behavior");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('behavior query by entry id finds the alias', () {
      final entry = vm.registryEntry("behavior", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('behavior query by engine finds the alias', () {
      final entry = vm.registryEntry("behavior", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('behavior query by kind finds the alias', () {
      final entry = vm.registryEntry("behavior", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('behavior query by params string finds the alias', () {
      final entry = vm.registryEntry("behavior", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('behavior query by description finds the alias', () {
      final entry = vm.registryEntry("behavior", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu query by exact name finds the alias', () {
      final entry = vm.registryEntry("menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "menu");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu query by entry id finds the alias', () {
      final entry = vm.registryEntry("menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu query by engine finds the alias', () {
      final entry = vm.registryEntry("menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu query by kind finds the alias', () {
      final entry = vm.registryEntry("menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu query by params string finds the alias', () {
      final entry = vm.registryEntry("menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu query by description finds the alias', () {
      final entry = vm.registryEntry("menu", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu_item query by exact name finds the alias', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "menu_item");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu_item query by entry id finds the alias', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu_item query by engine finds the alias', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu_item query by kind finds the alias', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu_item query by params string finds the alias', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('menu_item query by description finds the alias', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list query by exact name finds the alias', () {
      final entry = vm.registryEntry("list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "list");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list query by entry id finds the alias', () {
      final entry = vm.registryEntry("list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list query by engine finds the alias', () {
      final entry = vm.registryEntry("list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list query by kind finds the alias', () {
      final entry = vm.registryEntry("list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list query by params string finds the alias', () {
      final entry = vm.registryEntry("list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list query by description finds the alias', () {
      final entry = vm.registryEntry("list", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table query by exact name finds the alias', () {
      final entry = vm.registryEntry("table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "table");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table query by entry id finds the alias', () {
      final entry = vm.registryEntry("table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table query by engine finds the alias', () {
      final entry = vm.registryEntry("table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table query by kind finds the alias', () {
      final entry = vm.registryEntry("table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table query by params string finds the alias', () {
      final entry = vm.registryEntry("table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table query by description finds the alias', () {
      final entry = vm.registryEntry("table", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatars query by exact name finds the alias', () {
      final entry = vm.registryEntry("avatars", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "avatars");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatars query by entry id finds the alias', () {
      final entry = vm.registryEntry("avatars", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatars query by engine finds the alias', () {
      final entry = vm.registryEntry("avatars", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatars query by kind finds the alias', () {
      final entry = vm.registryEntry("avatars", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatars query by params string finds the alias', () {
      final entry = vm.registryEntry("avatars", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatars query by description finds the alias', () {
      final entry = vm.registryEntry("avatars", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_group query by exact name finds the alias', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "avatar_group");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_group query by entry id finds the alias', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_group query by engine finds the alias', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_group query by kind finds the alias', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_group query by params string finds the alias', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_group query by description finds the alias', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('categories query by exact name finds the alias', () {
      final entry = vm.registryEntry("categories", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "categories");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('categories query by entry id finds the alias', () {
      final entry = vm.registryEntry("categories", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('categories query by engine finds the alias', () {
      final entry = vm.registryEntry("categories", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('categories query by kind finds the alias', () {
      final entry = vm.registryEntry("categories", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('categories query by params string finds the alias', () {
      final entry = vm.registryEntry("categories", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('categories query by description finds the alias', () {
      final entry = vm.registryEntry("categories", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('category_browser query by exact name finds the alias', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "category_browser");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('category_browser query by entry id finds the alias', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('category_browser query by engine finds the alias', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('category_browser query by kind finds the alias', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('category_browser query by params string finds the alias', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('category_browser query by description finds the alias', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "rich_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_shell query by description finds the alias', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_list query by exact name finds the alias', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "rich_list");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_list query by entry id finds the alias', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_list query by engine finds the alias', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_list query by kind finds the alias', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_list query by params string finds the alias', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_list query by description finds the alias', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_table query by exact name finds the alias', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "rich_table");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_table query by entry id finds the alias', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_table query by engine finds the alias', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_table query by kind finds the alias', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_table query by params string finds the alias', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('rich_table query by description finds the alias', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by exact name finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "tabs");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by entry id finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by engine finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by kind finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by params string finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('tabs query by description finds the alias', () {
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('data_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "data_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('data_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('data_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('data_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('data_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('data_shell query by description finds the alias', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wizard query by exact name finds the alias', () {
      final entry = vm.registryEntry("wizard", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "wizard");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wizard query by entry id finds the alias', () {
      final entry = vm.registryEntry("wizard", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wizard query by engine finds the alias', () {
      final entry = vm.registryEntry("wizard", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wizard query by kind finds the alias', () {
      final entry = vm.registryEntry("wizard", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wizard query by params string finds the alias', () {
      final entry = vm.registryEntry("wizard", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('wizard query by description finds the alias', () {
      final entry = vm.registryEntry("wizard", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('empty_state query by exact name finds the alias', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "empty_state");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('empty_state query by entry id finds the alias', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('empty_state query by engine finds the alias', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('empty_state query by kind finds the alias', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('empty_state query by params string finds the alias', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('empty_state query by description finds the alias', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('error_state query by exact name finds the alias', () {
      final entry = vm.registryEntry("error_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "error_state");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('error_state query by entry id finds the alias', () {
      final entry = vm.registryEntry("error_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('error_state query by engine finds the alias', () {
      final entry = vm.registryEntry("error_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('error_state query by kind finds the alias', () {
      final entry = vm.registryEntry("error_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('error_state query by params string finds the alias', () {
      final entry = vm.registryEntry("error_state", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('error_state query by description finds the alias', () {
      final entry = vm.registryEntry("error_state", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('profile_card query by exact name finds the alias', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "profile_card");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('profile_card query by entry id finds the alias', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('profile_card query by engine finds the alias', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('profile_card query by kind finds the alias', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('profile_card query by params string finds the alias', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('profile_card query by description finds the alias', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "flow_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('flow_shell query by description finds the alias', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hero_bridge query by exact name finds the alias', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "hero_bridge");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hero_bridge query by entry id finds the alias', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hero_bridge query by engine finds the alias', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hero_bridge query by kind finds the alias', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hero_bridge query by params string finds the alias', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('hero_bridge query by description finds the alias', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "search_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_shell query by description finds the alias', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell query by description finds the alias', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_text query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_text", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_text");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_text query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_text", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_text query by engine finds the alias', () {
      final entry = vm.registryEntry("field_text", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_text query by kind finds the alias', () {
      final entry = vm.registryEntry("field_text", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_text query by params string finds the alias', () {
      final entry = vm.registryEntry("field_text", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_text query by description finds the alias', () {
      final entry = vm.registryEntry("field_text", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_number query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_number", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_number");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_number query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_number", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_number query by engine finds the alias', () {
      final entry = vm.registryEntry("field_number", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_number query by kind finds the alias', () {
      final entry = vm.registryEntry("field_number", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_number query by params string finds the alias', () {
      final entry = vm.registryEntry("field_number", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_number query by description finds the alias', () {
      final entry = vm.registryEntry("field_number", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_toggle query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_toggle");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_toggle query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_toggle query by engine finds the alias', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_toggle query by kind finds the alias', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_toggle query by params string finds the alias', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_toggle query by description finds the alias', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_slider query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_slider");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_slider query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_slider query by engine finds the alias', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_slider query by kind finds the alias', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_slider query by params string finds the alias', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_slider query by description finds the alias', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_select query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_select", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_select");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_select query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_select", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_select query by engine finds the alias', () {
      final entry = vm.registryEntry("field_select", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_select query by kind finds the alias', () {
      final entry = vm.registryEntry("field_select", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_select query by params string finds the alias', () {
      final entry = vm.registryEntry("field_select", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_select query by description finds the alias', () {
      final entry = vm.registryEntry("field_select", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_array query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_array", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_array");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_array query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_array", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_array query by engine finds the alias', () {
      final entry = vm.registryEntry("field_array", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_array query by kind finds the alias', () {
      final entry = vm.registryEntry("field_array", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_array query by params string finds the alias', () {
      final entry = vm.registryEntry("field_array", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_array query by description finds the alias', () {
      final entry = vm.registryEntry("field_array", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_blocks query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_blocks");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_blocks query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_blocks query by engine finds the alias', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_blocks query by kind finds the alias', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_blocks query by params string finds the alias', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_blocks query by description finds the alias', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_data query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_data", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_data");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_data query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_data", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_data query by engine finds the alias', () {
      final entry = vm.registryEntry("field_data", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_data query by kind finds the alias', () {
      final entry = vm.registryEntry("field_data", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_data query by params string finds the alias', () {
      final entry = vm.registryEntry("field_data", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_data query by description finds the alias', () {
      final entry = vm.registryEntry("field_data", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_lookup query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_lookup");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_lookup query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_lookup query by engine finds the alias', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_lookup query by kind finds the alias', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_lookup query by params string finds the alias', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_lookup query by description finds the alias', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_relation query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_relation");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_relation query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_relation query by engine finds the alias', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_relation query by kind finds the alias', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_relation query by params string finds the alias', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_relation query by description finds the alias', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell_stacked query by exact name finds the alias', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "field_shell_stacked");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell_stacked query by entry id finds the alias', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell_stacked query by engine finds the alias', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell_stacked query by kind finds the alias', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell_stacked query by params string finds the alias', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('field_shell_stacked query by description finds the alias', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "popover_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('popover_shell query by description finds the alias', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "surface_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('surface_shell query by description finds the alias', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('item_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "item_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('item_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('item_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('item_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('item_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('item_shell query by description finds the alias', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('cluster_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "cluster_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('cluster_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('cluster_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('cluster_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('cluster_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('cluster_shell query by description finds the alias', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "split_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('split_shell query by description finds the alias', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "state_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_shell query by description finds the alias', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "overlay_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('overlay_shell query by description finds the alias', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('control_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "control_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('control_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('control_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('control_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('control_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('control_shell query by description finds the alias', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_shell query by description finds the alias', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('navigation_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "navigation_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('navigation_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('navigation_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('navigation_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('navigation_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('navigation_shell query by description finds the alias', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segmented_control query by exact name finds the alias', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "segmented_control");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segmented_control query by entry id finds the alias', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segmented_control query by engine finds the alias', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segmented_control query by kind finds the alias', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segmented_control query by params string finds the alias', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('segmented_control query by description finds the alias', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by exact name finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "accordion");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by entry id finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by engine finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by kind finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by params string finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('accordion query by description finds the alias', () {
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('carousel query by exact name finds the alias', () {
      final entry = vm.registryEntry("carousel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "carousel");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('carousel query by entry id finds the alias', () {
      final entry = vm.registryEntry("carousel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('carousel query by engine finds the alias', () {
      final entry = vm.registryEntry("carousel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('carousel query by kind finds the alias', () {
      final entry = vm.registryEntry("carousel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('carousel query by params string finds the alias', () {
      final entry = vm.registryEntry("carousel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('carousel query by description finds the alias', () {
      final entry = vm.registryEntry("carousel", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by exact name finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "stepper");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by entry id finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by engine finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by kind finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by params string finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('stepper query by description finds the alias', () {
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_panel query by exact name finds the alias', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "search_panel");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_panel query by entry id finds the alias', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_panel query by engine finds the alias', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_panel query by kind finds the alias', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_panel query by params string finds the alias', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('search_panel query by description finds the alias', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('collection_shell query by exact name finds the alias', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "collection_shell");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('collection_shell query by entry id finds the alias', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('collection_shell query by engine finds the alias', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('collection_shell query by kind finds the alias', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('collection_shell query by params string finds the alias', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('collection_shell query by description finds the alias', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_panel query by exact name finds the alias', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "form_panel");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_panel query by entry id finds the alias', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_panel query by engine finds the alias', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_panel query by kind finds the alias', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_panel query by params string finds the alias', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('form_panel query by description finds the alias', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('master_detail query by exact name finds the alias', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "master_detail");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('master_detail query by entry id finds the alias', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('master_detail query by engine finds the alias', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('master_detail query by kind finds the alias', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('master_detail query by params string finds the alias', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('master_detail query by description finds the alias', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('command_bar query by exact name finds the alias', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "command_bar");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('command_bar query by entry id finds the alias', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('command_bar query by engine finds the alias', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('command_bar query by kind finds the alias', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('command_bar query by params string finds the alias', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('command_bar query by description finds the alias', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_card query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_card");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_card query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_card query by engine finds the alias', () {
      final entry = vm.registryEntry("media_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_card query by kind finds the alias', () {
      final entry = vm.registryEntry("media_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_card query by params string finds the alias', () {
      final entry = vm.registryEntry("media_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_card query by description finds the alias', () {
      final entry = vm.registryEntry("media_card", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('product_card query by exact name finds the alias', () {
      final entry = vm.registryEntry("product_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "product_card");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('product_card query by entry id finds the alias', () {
      final entry = vm.registryEntry("product_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('product_card query by engine finds the alias', () {
      final entry = vm.registryEntry("product_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('product_card query by kind finds the alias', () {
      final entry = vm.registryEntry("product_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('product_card query by params string finds the alias', () {
      final entry = vm.registryEntry("product_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('product_card query by description finds the alias', () {
      final entry = vm.registryEntry("product_card", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transaction_row query by exact name finds the alias', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "transaction_row");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transaction_row query by entry id finds the alias', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transaction_row query by engine finds the alias', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transaction_row query by kind finds the alias', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transaction_row query by params string finds the alias', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('transaction_row query by description finds the alias', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('payment_method query by exact name finds the alias', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "payment_method");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('payment_method query by entry id finds the alias', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('payment_method query by engine finds the alias', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('payment_method query by kind finds the alias', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('payment_method query by params string finds the alias', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('payment_method query by description finds the alias', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('feed_card query by exact name finds the alias', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "feed_card");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('feed_card query by entry id finds the alias', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('feed_card query by engine finds the alias', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('feed_card query by kind finds the alias', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('feed_card query by params string finds the alias', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('feed_card query by description finds the alias', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_surface query by exact name finds the alias', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "state_surface");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_surface query by entry id finds the alias', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_surface query by engine finds the alias', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_surface query by kind finds the alias', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_surface query by params string finds the alias', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('state_surface query by description finds the alias', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('metric_tile query by exact name finds the alias', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "metric_tile");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('metric_tile query by entry id finds the alias', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('metric_tile query by engine finds the alias', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('metric_tile query by kind finds the alias', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('metric_tile query by params string finds the alias', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('metric_tile query by description finds the alias', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('nested_menu query by exact name finds the alias', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "nested_menu");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('nested_menu query by entry id finds the alias', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('nested_menu query by engine finds the alias', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('nested_menu query by kind finds the alias', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('nested_menu query by params string finds the alias', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('nested_menu query by description finds the alias', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list_item query by exact name finds the alias', () {
      final entry = vm.registryEntry("list_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "list_item");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list_item query by entry id finds the alias', () {
      final entry = vm.registryEntry("list_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list_item query by engine finds the alias', () {
      final entry = vm.registryEntry("list_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list_item query by kind finds the alias', () {
      final entry = vm.registryEntry("list_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list_item query by params string finds the alias', () {
      final entry = vm.registryEntry("list_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('list_item query by description finds the alias', () {
      final entry = vm.registryEntry("list_item", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table_row query by exact name finds the alias', () {
      final entry = vm.registryEntry("table_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "table_row");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table_row query by entry id finds the alias', () {
      final entry = vm.registryEntry("table_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table_row query by engine finds the alias', () {
      final entry = vm.registryEntry("table_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table_row query by kind finds the alias', () {
      final entry = vm.registryEntry("table_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table_row query by params string finds the alias', () {
      final entry = vm.registryEntry("table_row", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('table_row query by description finds the alias', () {
      final entry = vm.registryEntry("table_row", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_item query by exact name finds the alias', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "avatar_item");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_item query by entry id finds the alias', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_item query by engine finds the alias', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_item query by kind finds the alias', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_item query by params string finds the alias', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('avatar_item query by description finds the alias', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by engine finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by kind finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by params string finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart query by description finds the alias', () {
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line query by exact name finds the alias', () {
      final entry = vm.registryEntry("line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "line");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line query by entry id finds the alias', () {
      final entry = vm.registryEntry("line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line query by engine finds the alias', () {
      final entry = vm.registryEntry("line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line query by kind finds the alias', () {
      final entry = vm.registryEntry("line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line query by params string finds the alias', () {
      final entry = vm.registryEntry("line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line query by description finds the alias', () {
      final entry = vm.registryEntry("line", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_line query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_line");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_line query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_line query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_line query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_line query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_line query by description finds the alias', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "line_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('line_chart query by description finds the alias', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_line_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_line_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_line_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_line_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_line_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_line_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_line_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar query by exact name finds the alias', () {
      final entry = vm.registryEntry("bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "bar");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar query by entry id finds the alias', () {
      final entry = vm.registryEntry("bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar query by engine finds the alias', () {
      final entry = vm.registryEntry("bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar query by kind finds the alias', () {
      final entry = vm.registryEntry("bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar query by params string finds the alias', () {
      final entry = vm.registryEntry("bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar query by description finds the alias', () {
      final entry = vm.registryEntry("bar", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bar query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_bar");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bar query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bar query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bar query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bar query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bar query by description finds the alias', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "bar_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bar_chart query by description finds the alias', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bar_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_bar_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bar_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bar_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bar_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bar_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bar_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area query by exact name finds the alias', () {
      final entry = vm.registryEntry("area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "area");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area query by entry id finds the alias', () {
      final entry = vm.registryEntry("area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area query by engine finds the alias', () {
      final entry = vm.registryEntry("area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area query by kind finds the alias', () {
      final entry = vm.registryEntry("area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area query by params string finds the alias', () {
      final entry = vm.registryEntry("area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area query by description finds the alias', () {
      final entry = vm.registryEntry("area", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_area query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_area");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_area query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_area query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_area query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_area query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_area query by description finds the alias', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "area_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('area_chart query by description finds the alias', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_area_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_area_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_area_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_area_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_area_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_area_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_area_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie query by exact name finds the alias', () {
      final entry = vm.registryEntry("pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "pie");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie query by entry id finds the alias', () {
      final entry = vm.registryEntry("pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie query by engine finds the alias', () {
      final entry = vm.registryEntry("pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie query by kind finds the alias', () {
      final entry = vm.registryEntry("pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie query by params string finds the alias', () {
      final entry = vm.registryEntry("pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie query by description finds the alias', () {
      final entry = vm.registryEntry("pie", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_pie query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_pie");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_pie query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_pie query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_pie query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_pie query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_pie query by description finds the alias', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "pie_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('pie_chart query by description finds the alias', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_pie_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_pie_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_pie_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_pie_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_pie_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_pie_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_pie_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut query by exact name finds the alias', () {
      final entry = vm.registryEntry("donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "donut");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut query by entry id finds the alias', () {
      final entry = vm.registryEntry("donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut query by engine finds the alias', () {
      final entry = vm.registryEntry("donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut query by kind finds the alias', () {
      final entry = vm.registryEntry("donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut query by params string finds the alias', () {
      final entry = vm.registryEntry("donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut query by description finds the alias', () {
      final entry = vm.registryEntry("donut", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_donut query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_donut");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_donut query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_donut query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_donut query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_donut query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_donut query by description finds the alias', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "donut_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('donut_chart query by description finds the alias', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_donut_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_donut_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_donut_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_donut_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_donut_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_donut_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_donut_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar query by exact name finds the alias', () {
      final entry = vm.registryEntry("radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "radar");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar query by entry id finds the alias', () {
      final entry = vm.registryEntry("radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar query by engine finds the alias', () {
      final entry = vm.registryEntry("radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar query by kind finds the alias', () {
      final entry = vm.registryEntry("radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar query by params string finds the alias', () {
      final entry = vm.registryEntry("radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar query by description finds the alias', () {
      final entry = vm.registryEntry("radar", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_radar query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_radar");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_radar query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_radar query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_radar query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_radar query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_radar query by description finds the alias', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "radar_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('radar_chart query by description finds the alias', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_radar_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_radar_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_radar_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_radar_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_radar_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_radar_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_radar_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter query by exact name finds the alias', () {
      final entry = vm.registryEntry("scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "scatter");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter query by entry id finds the alias', () {
      final entry = vm.registryEntry("scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter query by engine finds the alias', () {
      final entry = vm.registryEntry("scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter query by kind finds the alias', () {
      final entry = vm.registryEntry("scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter query by params string finds the alias', () {
      final entry = vm.registryEntry("scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter query by description finds the alias', () {
      final entry = vm.registryEntry("scatter", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_scatter query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_scatter");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_scatter query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_scatter query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_scatter query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_scatter query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_scatter query by description finds the alias', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "scatter_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('scatter_chart query by description finds the alias', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_scatter_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_scatter_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_scatter_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_scatter_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_scatter_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_scatter_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_scatter_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble query by exact name finds the alias', () {
      final entry = vm.registryEntry("bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "bubble");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble query by entry id finds the alias', () {
      final entry = vm.registryEntry("bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble query by engine finds the alias', () {
      final entry = vm.registryEntry("bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble query by kind finds the alias', () {
      final entry = vm.registryEntry("bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble query by params string finds the alias', () {
      final entry = vm.registryEntry("bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble query by description finds the alias', () {
      final entry = vm.registryEntry("bubble", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bubble query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_bubble");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bubble query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bubble query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bubble query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bubble query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_bubble query by description finds the alias', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "bubble_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('bubble_chart query by description finds the alias', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bubble_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_bubble_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bubble_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bubble_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bubble_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bubble_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_bubble_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick query by exact name finds the alias', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "candlestick");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick query by entry id finds the alias', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick query by engine finds the alias', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick query by kind finds the alias', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick query by params string finds the alias', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick query by description finds the alias', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_candlestick query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_candlestick");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_candlestick query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_candlestick query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_candlestick query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_candlestick query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_candlestick query by description finds the alias', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "candlestick_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('candlestick_chart query by description finds the alias', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_candlestick_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_candlestick_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_candlestick_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_candlestick_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_candlestick_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_candlestick_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_candlestick_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel query by exact name finds the alias', () {
      final entry = vm.registryEntry("funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "funnel");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel query by entry id finds the alias', () {
      final entry = vm.registryEntry("funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel query by engine finds the alias', () {
      final entry = vm.registryEntry("funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel query by kind finds the alias', () {
      final entry = vm.registryEntry("funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel query by params string finds the alias', () {
      final entry = vm.registryEntry("funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel query by description finds the alias', () {
      final entry = vm.registryEntry("funnel", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_funnel query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_funnel");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_funnel query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_funnel query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_funnel query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_funnel query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_funnel query by description finds the alias', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "funnel_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('funnel_chart query by description finds the alias', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_funnel_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_funnel_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_funnel_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_funnel_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_funnel_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_funnel_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_funnel_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall query by exact name finds the alias', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "waterfall");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall query by entry id finds the alias', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall query by engine finds the alias', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall query by kind finds the alias', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall query by params string finds the alias', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall query by description finds the alias', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_waterfall query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_waterfall");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_waterfall query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_waterfall query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_waterfall query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_waterfall query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_waterfall query by description finds the alias', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "waterfall_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('waterfall_chart query by description finds the alias', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_waterfall_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_waterfall_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_waterfall_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_waterfall_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_waterfall_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_waterfall_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_waterfall_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram query by exact name finds the alias', () {
      final entry = vm.registryEntry("histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "histogram");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram query by entry id finds the alias', () {
      final entry = vm.registryEntry("histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram query by engine finds the alias', () {
      final entry = vm.registryEntry("histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram query by kind finds the alias', () {
      final entry = vm.registryEntry("histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram query by params string finds the alias', () {
      final entry = vm.registryEntry("histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram query by description finds the alias', () {
      final entry = vm.registryEntry("histogram", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_histogram query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_histogram");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_histogram query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_histogram query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_histogram query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_histogram query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_histogram query by description finds the alias', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "histogram_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('histogram_chart query by description finds the alias', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_histogram_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_histogram_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_histogram_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_histogram_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_histogram_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_histogram_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_histogram_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge query by exact name finds the alias', () {
      final entry = vm.registryEntry("gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "gauge");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge query by entry id finds the alias', () {
      final entry = vm.registryEntry("gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge query by engine finds the alias', () {
      final entry = vm.registryEntry("gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge query by kind finds the alias', () {
      final entry = vm.registryEntry("gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge query by params string finds the alias', () {
      final entry = vm.registryEntry("gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge query by description finds the alias', () {
      final entry = vm.registryEntry("gauge", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_gauge query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_gauge");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_gauge query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_gauge query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_gauge query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_gauge query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_gauge query by description finds the alias', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "gauge_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('gauge_chart query by description finds the alias', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_gauge_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_gauge_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_gauge_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_gauge_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_gauge_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_gauge_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_gauge_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline query by exact name finds the alias', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sparkline");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline query by entry id finds the alias', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline query by engine finds the alias', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline query by kind finds the alias', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline query by params string finds the alias', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline query by description finds the alias', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sparkline query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_sparkline");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sparkline query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sparkline query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sparkline query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sparkline query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sparkline query by description finds the alias', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sparkline_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sparkline_chart query by description finds the alias', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sparkline_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_sparkline_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sparkline_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sparkline_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sparkline_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sparkline_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sparkline_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap query by exact name finds the alias', () {
      final entry = vm.registryEntry("treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "treemap");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap query by entry id finds the alias', () {
      final entry = vm.registryEntry("treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap query by engine finds the alias', () {
      final entry = vm.registryEntry("treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap query by kind finds the alias', () {
      final entry = vm.registryEntry("treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap query by params string finds the alias', () {
      final entry = vm.registryEntry("treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap query by description finds the alias', () {
      final entry = vm.registryEntry("treemap", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_treemap query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_treemap");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_treemap query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_treemap query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_treemap query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_treemap query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_treemap query by description finds the alias', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "treemap_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('treemap_chart query by description finds the alias', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_treemap_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_treemap_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_treemap_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_treemap_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_treemap_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_treemap_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_treemap_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey query by exact name finds the alias', () {
      final entry = vm.registryEntry("sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sankey");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey query by entry id finds the alias', () {
      final entry = vm.registryEntry("sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey query by engine finds the alias', () {
      final entry = vm.registryEntry("sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey query by kind finds the alias', () {
      final entry = vm.registryEntry("sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey query by params string finds the alias', () {
      final entry = vm.registryEntry("sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey query by description finds the alias', () {
      final entry = vm.registryEntry("sankey", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sankey query by exact name finds the alias', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "chart_sankey");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sankey query by entry id finds the alias', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sankey query by engine finds the alias', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sankey query by kind finds the alias', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sankey query by params string finds the alias', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('chart_sankey query by description finds the alias', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "sankey_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('sankey_chart query by description finds the alias', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sankey_chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media_sankey_chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sankey_chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sankey_chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sankey_chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sankey_chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media_sankey_chart query by description finds the alias', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media:chart query by exact name finds the alias', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: "media:chart");
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media:chart query by entry id finds the alias', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.id);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media:chart query by engine finds the alias', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.engine);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media:chart query by kind finds the alias', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.kind);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media:chart query by params string finds the alias', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias')!;
      final results = vm.registryEntries(kind: 'alias', query: entry.params.toString());
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

    test('media:chart query by description finds the alias', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias')!;
      final query = entry.description.isNotEmpty ? entry.description : entry.id;
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry.id), isTrue);
    });

  });
}

