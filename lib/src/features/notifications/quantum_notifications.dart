/*
 * ============================================================================
 * File: quantum_notifications.dart
 * 
 * Description:
 * Provides a comprehensive, Server-Driven UI (SDUI) first model for constructing 
 * rich notifications and live activities. It standardizes the data structures 
 * required to present advanced notifications across different OS platforms, 
 * including animations, interactive layouts, progress indicators, and inline replies.
 * 
 * Key Components:
 * - QuantumNotificationAnimationSpec: Defines hardware animations for notification elements.
 * - QuantumNotificationProgressSpec: Configuration for live progress bars/spinners.
 * - QuantumNotificationLayoutSpec: Advanced grid/flex layouts for custom notification UIs.
 * - QuantumNotificationTriggerSpec: Supports location/geofence-based notification triggers.
 * 
 * Dependencies/Relationships:
 * Built to be bridged natively via quantum_native_bridge.dart for rendering by 
 * OS-specific push notification extensions (APNs/FCM).
 * 
 * Notes:
 * Uses aggressive type normalization to safely parse untyped JSON maps originating 
 * from remote push payloads into strongly-typed Dart records.
 * ============================================================================
 */
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';
// ────────────────────────────────────────────────────────────────────────────
// QUANTUM NOTIFICATIONS — rich, SDUI-first, VM-friendly notification surface
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw == null) return <String, dynamic>{};
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic raw) {
  if (raw is List) return List<dynamic>.from(raw);
  return const <dynamic>[];
}

List<String> _asStringList(dynamic raw) {
  final items = _asList(raw);
  if (items.isEmpty) return const <String>[];
  return List<String>.unmodifiable(items.map((item) => item.toString()));
}

int? _asInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) {
    final d = double.tryParse(raw.trim());
    return d?.toInt();
  }
  return null;
}

double? _asDoubleNullable(dynamic raw) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  return null;
}

double _asDouble(dynamic raw, {double fallback = 0.0}) {
  return _asDoubleNullable(raw) ?? fallback;
}

bool _asBool(dynamic raw, {bool fallback = false}) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final text = raw?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes' || text == 'y') {
    return true;
  }
  if (text == 'false' || text == '0' || text == 'no' || text == 'n') {
    return false;
  }
  return fallback;
}

String _asString(dynamic raw, {String fallback = ''}) {
  final value = raw?.toString();
  return (value == null || value.isEmpty) ? fallback : value;
}

DateTime? _asDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is num) {
    return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  }
  return DateTime.tryParse(raw.toString());
}

Duration? _asDuration(dynamic raw) {
  if (raw == null) return null;
  if (raw is Duration) return raw;
  if (raw is num) return Duration(milliseconds: raw.toInt());
  if (raw is Map) {
    final map = _asMap(raw);
    final days = _asInt(map['days']) ?? 0;
    final hours = _asInt(map['hours']) ?? 0;
    final minutes = _asInt(map['minutes']) ?? 0;
    final seconds = _asInt(map['seconds']) ?? 0;
    final milliseconds = _asInt(map['milliseconds']) ?? 0;
    final microseconds = _asInt(map['microseconds']) ?? 0;
    return Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
      microseconds: microseconds,
    );
  }
  final text = raw.toString().trim().toLowerCase();
  if (text.isEmpty) return null;

  final simple = RegExp(
      r'^(\d+)\s*(ms|millisecond|milliseconds|s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hour|hours|d|day|days)$');
  final match = simple.firstMatch(text);
  if (match != null) {
    final value = int.tryParse(match.group(1) ?? '');
    if (value == null) return null;
    switch (match.group(2)) {
      case 'ms':
      case 'millisecond':
      case 'milliseconds':
        return Duration(milliseconds: value);
      case 's':
      case 'sec':
      case 'secs':
      case 'second':
      case 'seconds':
        return Duration(seconds: value);
      case 'm':
      case 'min':
      case 'mins':
      case 'minute':
      case 'minutes':
        return Duration(minutes: value);
      case 'h':
      case 'hr':
      case 'hour':
      case 'hours':
        return Duration(hours: value);
      case 'd':
      case 'day':
      case 'days':
        return Duration(days: value);
    }
  }

  return Duration(milliseconds: int.tryParse(text) ?? 0);
}

Map<String, dynamic> _mergeMaps(
  Map<String, dynamic> base,
  Map<String, dynamic> overlay,
) {
  if (base.isEmpty) return Map<String, dynamic>.from(overlay);
  if (overlay.isEmpty) return Map<String, dynamic>.from(base);

  final out = Map<String, dynamic>.from(base);
  overlay.forEach((key, value) {
    final existing = out[key];
    if (existing is Map && value is Map) {
      out[key] = _mergeMaps(
        existing.map((k, v) => MapEntry(k.toString(), v)),
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
    } else if (existing is List && value is List) {
      out[key] = <dynamic>[...existing, ...value];
    } else {
      out[key] = value;
    }
  });
  return out;
}

List<QuantumNotificationAction> _mergeActions(
  List<QuantumNotificationAction> base,
  List<QuantumNotificationAction> overlay,
) {
  if (base.isEmpty)
    return List<QuantumNotificationAction>.unmodifiable(overlay);
  if (overlay.isEmpty)
    return List<QuantumNotificationAction>.unmodifiable(base);

  final byId = <String, QuantumNotificationAction>{};
  for (final action in base) {
    byId[action.id] = action;
  }
  for (final action in overlay) {
    byId[action.id] =
        byId.containsKey(action.id) ? byId[action.id]!.merge(action) : action;
  }
  return List<QuantumNotificationAction>.unmodifiable(byId.values);
}

enum QuantumNotificationPriority { min, low, normal, high, max }

enum QuantumNotificationEventType {
  shown,
  delivered,
  tapped,
  dismissed,
  action,
  scheduled,
  cancelled,
  failed,
  unknown,
}

QuantumNotificationEventType _eventTypeFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'tap':
    case 'tapped':
      return QuantumNotificationEventType.tapped;
    case 'shown':
    case 'show':
      return QuantumNotificationEventType.shown;
    case 'delivered':
    case 'deliver':
      return QuantumNotificationEventType.delivered;
    case 'dismissed':
    case 'dismiss':
      return QuantumNotificationEventType.dismissed;
    case 'action':
      return QuantumNotificationEventType.action;
    case 'scheduled':
    case 'schedule':
      return QuantumNotificationEventType.scheduled;
    case 'cancelled':
    case 'canceled':
    case 'cancel':
      return QuantumNotificationEventType.cancelled;
    case 'failed':
    case 'fail':
      return QuantumNotificationEventType.failed;
    default:
      return QuantumNotificationEventType.unknown;
  }
}

@immutable
class QuantumNotificationAnimationSpec {
  final String id;
  final String type;
  final String target;
  final Duration? duration;
  final Duration? delay;
  final bool repeat;
  final bool infinite;
  final bool nativeOnly;
  final bool allowFallback;
  final Map<String, dynamic> parameters;

  const QuantumNotificationAnimationSpec({
    required this.id,
    required this.type,
    this.target = '',
    this.duration,
    this.delay,
    this.repeat = false,
    this.infinite = false,
    this.nativeOnly = true,
    this.allowFallback = true,
    this.parameters = const <String, dynamic>{},
  });

  factory QuantumNotificationAnimationSpec.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationAnimationSpec(
      id: _asString(map['id'] ?? map['animationId'] ?? map['key'],
          fallback: 'animation'),
      type: _asString(map['type'] ?? map['kind'] ?? map['name'],
          fallback: 'none'),
      target: _asString(map['target'] ?? map['scope'] ?? map['for']),
      duration: _asDuration(map['duration'] ?? map['durationMs']),
      delay: _asDuration(map['delay'] ?? map['delayMs']),
      repeat: _asBool(map['repeat'] ?? map['loop']),
      infinite: _asBool(map['infinite'] ?? map['forever']),
      nativeOnly: _asBool(map['nativeOnly'] ?? map['osOnly'], fallback: true),
      allowFallback:
          _asBool(map['allowFallback'] ?? map['fallback'], fallback: true),
      parameters: _asMap(map['parameters'] ?? map['props'] ?? map['data']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        if (target.isNotEmpty) 'target': target,
        if (duration != null) 'durationMs': duration!.inMilliseconds,
        if (delay != null) 'delayMs': delay!.inMilliseconds,
        'repeat': repeat,
        'infinite': infinite,
        'nativeOnly': nativeOnly,
        'allowFallback': allowFallback,
        if (parameters.isNotEmpty) 'parameters': parameters,
      };
}

@immutable
class QuantumNotificationProgressSpec {
  final String mode;
  final int? value;
  final int? max;
  final bool indeterminate;
  final bool live;
  final bool showPercent;
  final bool showTimer;
  final bool showBytes;
  final String? label;
  final String? unit;
  final DateTime? countdownTo;
  final Map<String, dynamic> metadata;

  const QuantumNotificationProgressSpec({
    this.mode = 'linear',
    this.value,
    this.max,
    this.indeterminate = false,
    this.live = false,
    this.showPercent = true,
    this.showTimer = false,
    this.showBytes = false,
    this.label,
    this.unit,
    this.countdownTo,
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationProgressSpec.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationProgressSpec(
      mode: _asString(map['mode'] ?? map['type'] ?? map['style'],
          fallback: 'linear'),
      value: _asInt(map['value'] ?? map['current']),
      max: _asInt(map['max'] ?? map['total']),
      indeterminate: _asBool(map['indeterminate'] ??
          map['busy'] ??
          map['spinning'] ??
          map['spinner']),
      live: _asBool(map['live'] ?? map['liveUpdate'], fallback: false),
      showPercent:
          _asBool(map['showPercent'] ?? map['percentVisible'], fallback: true),
      showTimer: _asBool(map['showTimer'] ?? map['countdown'] ?? map['timer']),
      showBytes: _asBool(map['showBytes'] ?? map['downloadBytes']),
      label: map['label']?.toString(),
      unit: map['unit']?.toString(),
      countdownTo: _asDateTime(map['countdownTo'] ?? map['until']),
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  QuantumNotificationProgressSpec copyWith({
    String? mode,
    int? value,
    int? max,
    bool? indeterminate,
    bool? live,
    bool? showPercent,
    bool? showTimer,
    bool? showBytes,
    String? label,
    String? unit,
    DateTime? countdownTo,
    Map<String, dynamic>? metadata,
  }) {
    return QuantumNotificationProgressSpec(
      mode: mode ?? this.mode,
      value: value ?? this.value,
      max: max ?? this.max,
      indeterminate: indeterminate ?? this.indeterminate,
      live: live ?? this.live,
      showPercent: showPercent ?? this.showPercent,
      showTimer: showTimer ?? this.showTimer,
      showBytes: showBytes ?? this.showBytes,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      countdownTo: countdownTo ?? this.countdownTo,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'mode': mode,
        if (value != null) 'value': value,
        if (max != null) 'max': max,
        'indeterminate': indeterminate,
        'live': live,
        'showPercent': showPercent,
        'showTimer': showTimer,
        'showBytes': showBytes,
        if (countdownTo != null) 'countdownTo': countdownTo!.toIso8601String(),
        if (label != null && label!.isNotEmpty) 'label': label,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationMediaSpec {
  final String kind;
  final String? uri;
  final String? mimeType;
  final String? poster;
  final bool autoplay;
  final bool muted;
  final bool loop;
  final bool controls;
  final bool nativeOnly;
  final Map<String, dynamic> metadata;

  const QuantumNotificationMediaSpec({
    required this.kind,
    this.uri,
    this.mimeType,
    this.poster,
    this.autoplay = false,
    this.muted = true,
    this.loop = false,
    this.controls = true,
    this.nativeOnly = true,
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationMediaSpec.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationMediaSpec(
      kind: _asString(map['kind'] ?? map['type'] ?? map['mediaType'],
          fallback: 'image'),
      uri: map['uri']?.toString() ?? map['url']?.toString(),
      mimeType: map['mimeType']?.toString() ?? map['mime']?.toString(),
      poster: map['poster']?.toString(),
      autoplay: _asBool(map['autoplay']),
      muted: _asBool(map['muted'], fallback: true),
      loop: _asBool(map['loop']),
      controls: _asBool(map['controls'], fallback: true),
      nativeOnly: _asBool(map['nativeOnly'] ?? map['osOnly'], fallback: true),
      metadata: _asMap(map['metadata'] ?? map['meta'] ?? map['data']),
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind,
        if (uri != null && uri!.isNotEmpty) 'uri': uri,
        if (mimeType != null && mimeType!.isNotEmpty) 'mimeType': mimeType,
        if (poster != null && poster!.isNotEmpty) 'poster': poster,
        'autoplay': autoplay,
        'muted': muted,
        'loop': loop,
        'controls': controls,
        'nativeOnly': nativeOnly,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationLayoutItem {
  final String id;
  final String type;
  final int x;
  final int y;
  final int w;
  final int h;
  final int order;
  final int flex;
  final double? weight;
  final String? text;
  final String? actionId;
  final Map<String, dynamic> props;
  final Map<String, dynamic> style;
  final Map<String, dynamic> animation;
  final Map<String, dynamic> media;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> metadata;

  const QuantumNotificationLayoutItem({
    required this.id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.w = 1,
    this.h = 1,
    this.order = 0,
    this.flex = 0,
    this.weight,
    this.text,
    this.actionId,
    this.props = const <String, dynamic>{},
    this.style = const <String, dynamic>{},
    this.animation = const <String, dynamic>{},
    this.media = const <String, dynamic>{},
    this.progress = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationLayoutItem.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationLayoutItem(
      id: _asString(map['id'] ?? map['key'] ?? map['name'], fallback: 'item'),
      type: _asString(map['type'] ?? map['kind'], fallback: 'text'),
      x: _asInt(map['x'] ?? map['col'] ?? map['column']) ?? 0,
      y: _asInt(map['y'] ?? map['row']) ?? 0,
      w: _asInt(map['w'] ?? map['width'] ?? map['span']) ?? 1,
      h: _asInt(map['h'] ?? map['height'] ?? map['rows']) ?? 1,
      order: _asInt(map['order'] ?? map['zIndex']) ?? 0,
      flex: _asInt(map['flex']) ?? 0,
      weight: _asDoubleNullable(map['weight']),
      text: map['text']?.toString() ?? map['value']?.toString(),
      actionId: map['actionId']?.toString() ?? map['action']?.toString(),
      props: _asMap(map['props'] ?? map['data']),
      style: _asMap(map['style'] ?? map['visual']),
      animation: _asMap(map['animation'] ?? map['anim']),
      media: _asMap(map['media'] ?? map['asset']),
      progress: _asMap(map['progress'] ?? map['meter']),
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'order': order,
        'flex': flex,
        if (weight != null) 'weight': weight,
        if (text != null) 'text': text,
        if (actionId != null) 'actionId': actionId,
        if (props.isNotEmpty) 'props': props,
        if (style.isNotEmpty) 'style': style,
        if (animation.isNotEmpty) 'animation': animation,
        if (media.isNotEmpty) 'media': media,
        if (progress.isNotEmpty) 'progress': progress,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationLayoutSpec {
  final String mode;
  final int columns;
  final int rows;
  final String direction;
  final double gap;
  final Map<String, dynamic> padding;
  final Map<String, dynamic> grid;
  final Map<String, dynamic> flex;
  final List<QuantumNotificationLayoutItem> items;
  final Map<String, dynamic> metadata;

  const QuantumNotificationLayoutSpec({
    this.mode = 'grid',
    this.columns = 1,
    this.rows = 1,
    this.direction = 'row',
    this.gap = 0.0,
    this.padding = const <String, dynamic>{},
    this.grid = const <String, dynamic>{},
    this.flex = const <String, dynamic>{},
    this.items = const <QuantumNotificationLayoutItem>[],
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationLayoutSpec.fromMap(Map<String, dynamic> map) {
    final items = _asList(map['items'] ?? map['children'] ?? map['cells'])
        .map((item) => item is Map
            ? QuantumNotificationLayoutItem.fromMap(
                item.map((k, v) => MapEntry(k.toString(), v)),
              )
            : QuantumNotificationLayoutItem.fromMap(
                {
                  'id': item.toString(),
                  'type': 'text',
                  'text': item.toString()
                },
              ))
        .toList(growable: false);

    return QuantumNotificationLayoutSpec(
      mode: _asString(map['mode'] ?? map['type'], fallback: 'grid'),
      columns: _asInt(map['columns'] ?? map['cols']) ?? 1,
      rows: _asInt(map['rows']) ?? 1,
      direction: _asString(map['direction'] ?? map['axis'], fallback: 'row'),
      gap: _asDouble(map['gap']),
      padding: _asMap(map['padding'] ?? map['insets']),
      grid: _asMap(map['grid']),
      flex: _asMap(map['flex']),
      items: List<QuantumNotificationLayoutItem>.unmodifiable(items),
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  Map<String, dynamic> toMap() => {
        'mode': mode,
        'columns': columns,
        'rows': rows,
        'direction': direction,
        'gap': gap,
        if (padding.isNotEmpty) 'padding': padding,
        if (grid.isNotEmpty) 'grid': grid,
        if (flex.isNotEmpty) 'flex': flex,
        if (items.isNotEmpty)
          'items': items.map((e) => e.toMap()).toList(growable: false),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationInlineReplySpec {
  final String actionId;
  final String? placeholder;
  final String? label;
  final bool multiline;
  final bool sendOnEnter;
  final bool keepOpen;
  final int? maxLength;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> sdui;
  final Map<String, dynamic> vm;
  final Map<String, dynamic> metadata;

  const QuantumNotificationInlineReplySpec({
    required this.actionId,
    this.placeholder,
    this.label,
    this.multiline = false,
    this.sendOnEnter = true,
    this.keepOpen = false,
    this.maxLength,
    this.payload = const <String, dynamic>{},
    this.sdui = const <String, dynamic>{},
    this.vm = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationInlineReplySpec.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationInlineReplySpec(
      actionId: _asString(map['actionId'] ?? map['id']),
      placeholder: _asString(map['placeholder'] ?? map['hint'], fallback: ''),
      label: _asString(map['label'] ?? map['buttonLabel'] ?? map['sendLabel'],
          fallback: ''),
      multiline: _asBool(map['multiline']),
      sendOnEnter:
          _asBool(map['sendOnEnter'] ?? map['enterToSend'], fallback: true),
      keepOpen: _asBool(map['keepOpen']),
      maxLength: _asInt(map['maxLength'] ?? map['limit']),
      payload: _asMap(map['payload']),
      sdui: _asMap(map['sdui']),
      vm: _asMap(map['vm']),
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  Map<String, dynamic> toMap() => {
        'actionId': actionId,
        if (placeholder != null && placeholder!.isNotEmpty)
          'placeholder': placeholder,
        if (label != null && label!.isNotEmpty) 'label': label,
        'multiline': multiline,
        'sendOnEnter': sendOnEnter,
        'keepOpen': keepOpen,
        if (maxLength != null) 'maxLength': maxLength,
        if (payload.isNotEmpty) 'payload': payload,
        if (sdui.isNotEmpty) 'sdui': sdui,
        if (vm.isNotEmpty) 'vm': vm,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationLiveActivitySpec {
  final String id;
  final String kind;
  final Map<String, dynamic> state;
  final QuantumNotificationProgressSpec? progress;
  final QuantumNotificationLayoutSpec? layout;
  final Map<String, dynamic> metadata;

  const QuantumNotificationLiveActivitySpec({
    required this.id,
    this.kind = 'live_activity',
    this.state = const <String, dynamic>{},
    this.progress,
    this.layout,
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationLiveActivitySpec.fromMap(
      Map<String, dynamic> map) {
    return QuantumNotificationLiveActivitySpec(
      id: _asString(map['id'] ?? map['activityId'], fallback: 'live_activity'),
      kind: _asString(map['kind'] ?? map['type'], fallback: 'live_activity'),
      state: _asMap(map['state'] ?? map['data'] ?? map['payload']),
      progress: map['progress'] is Map
          ? QuantumNotificationProgressSpec.fromMap(_asMap(map['progress']))
          : null,
      layout: map['layout'] is Map
          ? QuantumNotificationLayoutSpec.fromMap(_asMap(map['layout']))
          : null,
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind,
        if (state.isNotEmpty) 'state': state,
        if (progress != null) 'progress': progress!.toMap(),
        if (layout != null) 'layout': layout!.toMap(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationTriggerSpec {
  final String type;
  final Map<String, dynamic> config;

  const QuantumNotificationTriggerSpec({
    required this.type,
    this.config = const <String, dynamic>{},
  });

  factory QuantumNotificationTriggerSpec.fromMap(Map<String, dynamic> map) {
    final type = _asString(map['type'] ?? map['kind'] ?? map['event'],
        fallback: 'trigger');
    if (type == 'location' ||
        map.containsKey('latitude') ||
        map.containsKey('lat') ||
        map.containsKey('geofenceId') ||
        map.containsKey('regionId')) {
      return QuantumNotificationLocationTriggerSpec.fromMap(map);
    }
    return QuantumNotificationTriggerSpec(
      type: type,
      config: _asMap(map['config'] ?? map['data'] ?? map['payload']),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        if (config.isNotEmpty) 'config': config,
      };
}

@immutable
class QuantumNotificationLocationTriggerSpec
    extends QuantumNotificationTriggerSpec {
  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool onEnter;
  final bool onExit;
  final bool onDwell;
  final int? dwellSeconds;
  final bool repeat;
  final Map<String, dynamic> metadata;

  const QuantumNotificationLocationTriggerSpec({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.onEnter = true,
    this.onExit = false,
    this.onDwell = false,
    this.dwellSeconds,
    this.repeat = true,
    this.metadata = const <String, dynamic>{},
  }) : super(type: 'location', config: const {});

  factory QuantumNotificationLocationTriggerSpec.fromMap(
      Map<String, dynamic> map) {
    return QuantumNotificationLocationTriggerSpec(
      id: _asString(
          map['id'] ?? map['geofenceId'] ?? map['regionId'] ?? map['key'],
          fallback: 'location'),
      latitude: _asDouble(map['latitude'] ?? map['lat'] ?? map['x']),
      longitude: _asDouble(map['longitude'] ?? map['lng'] ?? map['y']),
      radiusMeters:
          _asDouble(map['radiusMeters'] ?? map['radius'] ?? map['distance']),
      onEnter: _asBool(map['onEnter'] ?? map['enter'], fallback: true),
      onExit: _asBool(map['onExit'] ?? map['exit'], fallback: false),
      onDwell: _asBool(map['onDwell']) ||
          map['dwell'] != null ||
          map['dwellSeconds'] != null,
      dwellSeconds: _asInt(map['dwellSeconds'] ?? map['dwell']),
      repeat: _asBool(map['repeat'] ?? map['repeatable'], fallback: true),
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'type': 'location',
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'onEnter': onEnter,
        'onExit': onExit,
        'onDwell': onDwell,
        if (dwellSeconds != null) 'dwellSeconds': dwellSeconds,
        'repeat': repeat,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationTemplateRecord {
  final String key;
  final QuantumNotificationRequest request;
  final String? description;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuantumNotificationTemplateRecord({
    required this.key,
    required this.request,
    this.description,
    this.tags = const <String>[],
    required this.createdAt,
    required this.updatedAt,
  });

  QuantumNotificationTemplateRecord copyWith({
    String? key,
    QuantumNotificationRequest? request,
    String? description,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuantumNotificationTemplateRecord(
      key: key ?? this.key,
      request: request ?? this.request,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'key': key,
        'request': request.toMap(),
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (tags.isNotEmpty) 'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory QuantumNotificationTemplateRecord.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationTemplateRecord(
      key: _asString(map['key'] ?? map['name'] ?? map['id'],
          fallback: 'template'),
      request: QuantumNotificationRequest.fromMap(
          _asMap(map['request'] ?? map['notification'] ?? map['spec'])),
      description: map['description']?.toString(),
      tags: _asStringList(map['tags']),
      createdAt:
          _asDateTime(map['createdAt'] ?? map['created']) ?? DateTime.now(),
      updatedAt:
          _asDateTime(map['updatedAt'] ?? map['updated']) ?? DateTime.now(),
    );
  }
}

typedef QuantumNotificationTemplate = QuantumNotificationTemplateRecord;

class QuantumNotificationRegistry {
  final Map<String, QuantumNotificationTemplateRecord> _templates = {};
  FutureOr<void> Function(Map<String, dynamic> snapshot)? _writeSnapshot;
  FutureOr<Map<String, dynamic>?> Function()? _readSnapshot;

  List<String> get keys => List<String>.unmodifiable(_templates.keys);

  int get length => _templates.length;

  void attachPersistence({
    FutureOr<void> Function(Map<String, dynamic> snapshot)? write,
    FutureOr<Map<String, dynamic>?> Function()? read,
  }) {
    _writeSnapshot = write;
    _readSnapshot = read;
  }

  QuantumNotificationTemplateRecord registerTemplate(
    String key,
    QuantumNotificationRequest request, {
    String? description,
    List<String> tags = const <String>[],
    bool overwrite = true,
  }) {
    final now = DateTime.now();
    final existing = _templates[key];
    final template = QuantumNotificationTemplateRecord(
      key: key,
      request: request.copyWith(
        metadata:
            _mergeMaps(request.metadata, <String, dynamic>{'templateKey': key}),
      ),
      description: description ?? existing?.description,
      tags: tags.isNotEmpty ? tags : existing?.tags ?? const <String>[],
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (overwrite || !_templates.containsKey(key)) {
      _templates[key] = template;
    }
    return _templates[key] ?? template;
  }

  QuantumNotificationTemplateRecord registerJson(
    String key,
    Map<String, dynamic> json, {
    String? description,
    List<String> tags = const <String>[],
  }) {
    return registerTemplate(
      key,
      QuantumNotificationRequest.fromMap(
          _mergeMaps(json, <String, dynamic>{'templateKey': key})),
      description: description,
      tags: tags,
    );
  }

  QuantumNotificationTemplateRecord? read(String key) => _templates[key];

  QuantumNotificationRequest? readRequest(String key) =>
      _templates[key]?.request;

  bool contains(String key) => _templates.containsKey(key);

  QuantumNotificationTemplateRecord? remove(String key) =>
      _templates.remove(key);

  QuantumNotificationTemplateRecord update(
    String key, {
    QuantumNotificationRequest? request,
    Map<String, dynamic>? patch,
    String? description,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    final existing = _templates[key];
    final mergedRequest = request ??
        (patch != null
            ? (existing?.request ??
                    const QuantumNotificationRequest(title: '', body: ''))
                .merge(QuantumNotificationRequest.fromMap(patch))
            : existing?.request);
    if (mergedRequest == null) {
      throw StateError('Template not found: $key');
    }
    final template = QuantumNotificationTemplateRecord(
      key: key,
      request: mergedRequest.copyWith(
        metadata: _mergeMaps(
            mergedRequest.metadata, <String, dynamic>{'templateKey': key}),
      ),
      description: description ?? existing?.description,
      tags: tags ?? existing?.tags ?? const <String>[],
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    _templates[key] = template;
    return template;
  }

  Map<String, dynamic> snapshot() {
    return <String, dynamic>{
      'version': 1,
      'templates': {
        for (final entry in _templates.entries) entry.key: entry.value.toMap(),
      },
    };
  }

  void importSnapshot(Map<String, dynamic> snapshot, {bool clear = true}) {
    if (clear) {
      _templates.clear();
    }
    final templates = _asMap(snapshot['templates']);
    templates.forEach((key, value) {
      if (value is Map) {
        final map = value.map((k, v) => MapEntry(k.toString(), v));
        _templates[key.toString()] =
            QuantumNotificationTemplateRecord.fromMap(map);
      }
    });
  }

  Future<void> persist() async {
    final writer = _writeSnapshot;
    if (writer != null) {
      await Future<void>.value(writer(snapshot()));
    }
  }

  Future<void> restore() async {
    final reader = _readSnapshot;
    if (reader == null) return;
    final result = await Future<dynamic>.value(reader());
    if (result is Map) {
      importSnapshot(result.map((k, v) => MapEntry(k.toString(), v)));
    }
  }

  void clear() => _templates.clear();
}

// ────────────────────────────────────────────────────────────────────────────
// LEGACY SURFACE
// ────────────────────────────────────────────────────────────────────────────

class SimpleNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  const SimpleNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
      };

  QuantumNotificationRequest toRequest() {
    return QuantumNotificationRequest(
      id: id,
      title: title,
      body: body,
      payload: payload.isEmpty ? null : payload,
    );
  }
}

class NotificationTap {
  final int id;
  final String payload;
  final String actionId;
  final String type;
  final String channelId;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  const NotificationTap({
    required this.id,
    required this.payload,
    this.actionId = '',
    this.type = 'tap',
    this.channelId = '',
    this.data = const <String, dynamic>{},
    this.timestamp,
  });

  factory NotificationTap.fromMap(Map<String, dynamic> map) {
    return NotificationTap(
      id: _asInt(map['id'] ?? map['notificationId']) ?? 0,
      payload: _asString(map['payload'] ?? _asMap(map['data'])['payload']),
      actionId: _asString(map['actionId'] ?? map['action'] ?? map['buttonId']),
      type: _asString(map['type'] ?? map['eventType'] ?? map['kind'],
          fallback: 'tapped'),
      channelId: _asString(map['channelId'] ?? map['channel']),
      data: _asMap(map['data'] ?? map['meta'] ?? map['metadata']),
      timestamp: _asDateTime(map['timestamp'] ?? map['ts'] ?? map['at']),
    );
  }

  QuantumNotificationEvent toEvent() {
    return QuantumNotificationEvent(
      type: _eventTypeFromString(type),
      id: id,
      payload: payload,
      actionId: actionId,
      channelId: channelId,
      data: data,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'payload': payload,
        if (actionId.isNotEmpty) 'actionId': actionId,
        if (type.isNotEmpty) 'type': type,
        if (channelId.isNotEmpty) 'channelId': channelId,
        if (data.isNotEmpty) 'data': data,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };
}

// ────────────────────────────────────────────────────────────────────────────
// RICH NOTIFICATION MODEL
// ────────────────────────────────────────────────────────────────────────────

@immutable
class QuantumNotificationAction {
  final String id;
  final String label;
  final String? icon;
  final bool foreground;
  final bool destructive;
  final bool opensApp;
  final bool dismissOnTap;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> sdui;
  final Map<String, dynamic> vm;
  final Map<String, dynamic> metadata;

  const QuantumNotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.foreground = true,
    this.destructive = false,
    this.opensApp = true,
    this.dismissOnTap = true,
    this.payload = const <String, dynamic>{},
    this.sdui = const <String, dynamic>{},
    this.vm = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationAction.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationAction(
      id: _asString(map['id'] ?? map['actionId'] ?? map['key'],
          fallback: 'action'),
      label: _asString(map['label'] ?? map['title'] ?? map['text'],
          fallback: 'Action'),
      icon: map['icon']?.toString(),
      foreground: _asBool(map['foreground'], fallback: true),
      destructive: _asBool(map['destructive']),
      opensApp: _asBool(map['opensApp'] ?? map['launchApp'], fallback: true),
      dismissOnTap:
          _asBool(map['dismissOnTap'] ?? map['closeOnTap'], fallback: true),
      payload: _asMap(map['payload']),
      sdui: _asMap(map['sdui'] ?? map['ui'] ?? map['view']),
      vm: _asMap(map['vm'] ?? map['quantumVm'] ?? map['runtime']),
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  QuantumNotificationAction copyWith({
    String? id,
    String? label,
    String? icon,
    bool? foreground,
    bool? destructive,
    bool? opensApp,
    bool? dismissOnTap,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? sdui,
    Map<String, dynamic>? vm,
    Map<String, dynamic>? metadata,
  }) {
    return QuantumNotificationAction(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      foreground: foreground ?? this.foreground,
      destructive: destructive ?? this.destructive,
      opensApp: opensApp ?? this.opensApp,
      dismissOnTap: dismissOnTap ?? this.dismissOnTap,
      payload: payload ?? this.payload,
      sdui: sdui ?? this.sdui,
      vm: vm ?? this.vm,
      metadata: metadata ?? this.metadata,
    );
  }

  QuantumNotificationAction merge(QuantumNotificationAction overlay) {
    return copyWith(
      id: overlay.id.isEmpty ? id : overlay.id,
      label: overlay.label.isEmpty ? label : overlay.label,
      icon: overlay.icon ?? icon,
      foreground: overlay.foreground,
      destructive: overlay.destructive,
      opensApp: overlay.opensApp,
      dismissOnTap: overlay.dismissOnTap,
      payload: _mergeMaps(payload, overlay.payload),
      sdui: _mergeMaps(sdui, overlay.sdui),
      vm: _mergeMaps(vm, overlay.vm),
      metadata: _mergeMaps(metadata, overlay.metadata),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        if (icon != null) 'icon': icon,
        'foreground': foreground,
        'destructive': destructive,
        'opensApp': opensApp,
        'dismissOnTap': dismissOnTap,
        if (payload.isNotEmpty) 'payload': payload,
        if (sdui.isNotEmpty) 'sdui': sdui,
        if (vm.isNotEmpty) 'vm': vm,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationSchedule {
  final DateTime? at;
  final Duration? delay;
  final Duration? repeatEvery;
  final int? repeatCount;
  final String? cron;
  final bool exact;
  final bool allowWhileIdle;
  final Map<String, dynamic> metadata;

  const QuantumNotificationSchedule({
    this.at,
    this.delay,
    this.repeatEvery,
    this.repeatCount,
    this.cron,
    this.exact = false,
    this.allowWhileIdle = false,
    this.metadata = const <String, dynamic>{},
  });

  factory QuantumNotificationSchedule.fromMap(Map<String, dynamic> map) {
    return QuantumNotificationSchedule(
      at: _asDateTime(map['at'] ?? map['when'] ?? map['scheduleAt']),
      delay: _asDuration(map['delay'] ?? map['after'] ?? map['in']),
      repeatEvery:
          _asDuration(map['repeatEvery'] ?? map['every'] ?? map['interval']),
      repeatCount: _asInt(map['repeatCount'] ?? map['count']),
      cron: map['cron']?.toString(),
      exact: _asBool(map['exact']),
      allowWhileIdle: _asBool(map['allowWhileIdle'] ?? map['idle']),
      metadata: _asMap(map['metadata'] ?? map['meta']),
    );
  }

  QuantumNotificationSchedule copyWith({
    DateTime? at,
    Duration? delay,
    Duration? repeatEvery,
    int? repeatCount,
    String? cron,
    bool? exact,
    bool? allowWhileIdle,
    Map<String, dynamic>? metadata,
  }) {
    return QuantumNotificationSchedule(
      at: at ?? this.at,
      delay: delay ?? this.delay,
      repeatEvery: repeatEvery ?? this.repeatEvery,
      repeatCount: repeatCount ?? this.repeatCount,
      cron: cron ?? this.cron,
      exact: exact ?? this.exact,
      allowWhileIdle: allowWhileIdle ?? this.allowWhileIdle,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        if (at != null) 'at': at!.toIso8601String(),
        if (delay != null) 'delayMs': delay!.inMilliseconds,
        if (repeatEvery != null) 'repeatEveryMs': repeatEvery!.inMilliseconds,
        if (repeatCount != null) 'repeatCount': repeatCount,
        if (cron != null && cron!.isNotEmpty) 'cron': cron,
        'exact': exact,
        'allowWhileIdle': allowWhileIdle,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QuantumNotificationEvent {
  final QuantumNotificationEventType type;
  final int? id;
  final String payload;
  final String actionId;
  final String channelId;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  const QuantumNotificationEvent({
    required this.type,
    this.id,
    this.payload = '',
    this.actionId = '',
    this.channelId = '',
    this.data = const <String, dynamic>{},
    this.timestamp,
  });

  factory QuantumNotificationEvent.fromMap(Map<String, dynamic> map) {
    final typeText = _asString(map['type'] ?? map['eventType'] ?? map['kind'],
        fallback: 'unknown');
    return QuantumNotificationEvent(
      type: _eventTypeFromString(typeText),
      id: _asInt(map['id'] ?? map['notificationId']),
      payload: _asString(map['payload'] ?? _asMap(map['data'])['payload']),
      actionId: _asString(map['actionId'] ?? map['action'] ?? map['buttonId']),
      channelId: _asString(map['channelId'] ?? map['channel']),
      data: _asMap(map['data'] ?? map['meta'] ?? map['metadata']),
      timestamp: _asDateTime(map['timestamp'] ?? map['ts'] ?? map['at']),
    );
  }

  NotificationTap toTap() => NotificationTap(
        id: id ?? 0,
        payload: payload,
        actionId: actionId,
        type: type.name,
        channelId: channelId,
        data: data,
        timestamp: timestamp,
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        if (id != null) 'id': id,
        if (payload.isNotEmpty) 'payload': payload,
        if (actionId.isNotEmpty) 'actionId': actionId,
        if (channelId.isNotEmpty) 'channelId': channelId,
        if (data.isNotEmpty) 'data': data,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };
}

@immutable
class QuantumNotificationRequest {
  final int? id;
  final String title;
  final String body;
  final String? subtitle;
  final String? payload;
  final String? channelId;
  final String? category;
  final String? groupKey;
  final String? threadId;
  final String? templateKey;
  final String? icon;
  final String? image;
  final String? largeIcon;
  final String? smallIcon;
  final String? sound;
  final String? shortcutId;
  final String? collapseKey;
  final QuantumNotificationPriority priority;
  final bool persistent;
  final bool silent;
  final bool autoCancel;
  final bool localOnly;
  final bool onlyAlertOnce;
  final bool showWhen;
  final bool showTimestamp;
  final bool headsUp;
  final bool ongoing;
  final bool nativeOnly;
  final bool fallbackToSystem;
  final String renderPolicy;
  final Map<String, dynamic> data;
  final Map<String, dynamic> style;
  final Map<String, dynamic> sdui;
  final Map<String, dynamic> vm;
  final Map<String, dynamic> metadata;
  final QuantumNotificationSchedule? schedule;
  final QuantumNotificationLayoutSpec? layout;
  final QuantumNotificationInlineReplySpec? inlineReply;
  final QuantumNotificationProgressSpec? progress;
  final QuantumNotificationLiveActivitySpec? liveActivity;
  final List<QuantumNotificationAnimationSpec> animations;
  final List<QuantumNotificationMediaSpec> media;
  final List<QuantumNotificationTriggerSpec> triggers;
  final List<QuantumNotificationAction> actions;

  const QuantumNotificationRequest({
    this.id,
    required this.title,
    required this.body,
    this.subtitle,
    this.payload,
    this.channelId,
    this.category,
    this.groupKey,
    this.threadId,
    this.templateKey,
    this.icon,
    this.image,
    this.largeIcon,
    this.smallIcon,
    this.sound,
    this.shortcutId,
    this.collapseKey,
    this.priority = QuantumNotificationPriority.normal,
    this.persistent = false,
    this.silent = false,
    this.autoCancel = true,
    this.localOnly = false,
    this.onlyAlertOnce = false,
    this.showWhen = true,
    this.showTimestamp = true,
    this.headsUp = false,
    this.ongoing = false,
    this.nativeOnly = true,
    this.fallbackToSystem = true,
    this.renderPolicy = 'nativeOnly',
    this.data = const <String, dynamic>{},
    this.style = const <String, dynamic>{},
    this.sdui = const <String, dynamic>{},
    this.vm = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
    this.schedule,
    this.layout,
    this.inlineReply,
    this.progress,
    this.liveActivity,
    this.animations = const <QuantumNotificationAnimationSpec>[],
    this.media = const <QuantumNotificationMediaSpec>[],
    this.triggers = const <QuantumNotificationTriggerSpec>[],
    this.actions = const <QuantumNotificationAction>[],
  });

  factory QuantumNotificationRequest.fromValue(Object? raw) {
    if (raw is QuantumNotificationRequest) return raw;
    if (raw is SimpleNotification) return raw.toRequest();
    if (raw is String && raw.trim().isNotEmpty) {
      return QuantumNotificationRequest.fromMap(_asMap(raw));
    }
    if (raw is Map) {
      return QuantumNotificationRequest.fromMap(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return const QuantumNotificationRequest(
      title: '',
      body: '',
    );
  }

  factory QuantumNotificationRequest.fromMap(Map<String, dynamic> map) {
    final data = _asMap(map['data'] ?? map['payloadData'] ?? map['context']);
    final style = _asMap(map['style'] ?? map['visual'] ?? map['presentation']);
    final sdui =
        _asMap(map['sdui'] ?? map['ui'] ?? map['view'] ?? map['block']);
    final vm = _asMap(map['vm'] ?? map['quantumVm'] ?? map['runtime']);
    final metadata = _asMap(map['metadata'] ?? map['meta']);

    final actions = _asList(map['actions'] ?? map['buttons'])
        .map((item) => item is Map
            ? QuantumNotificationAction.fromMap(
                item.map((k, v) => MapEntry(k.toString(), v)),
              )
            : QuantumNotificationAction.fromMap(
                {'id': item.toString(), 'label': item.toString()},
              ))
        .toList(growable: false);

    final animations = _asList(map['animations'] ?? map['effects'])
        .map((item) => item is Map
            ? QuantumNotificationAnimationSpec.fromMap(
                item.map((k, v) => MapEntry(k.toString(), v)),
              )
            : QuantumNotificationAnimationSpec.fromMap(
                {'id': item.toString(), 'type': item.toString()},
              ))
        .toList(growable: false);

    final media = _asList(map['media'] ?? map['attachments'] ?? map['assets'])
        .map((item) => item is Map
            ? QuantumNotificationMediaSpec.fromMap(
                item.map((k, v) => MapEntry(k.toString(), v)),
              )
            : QuantumNotificationMediaSpec.fromMap(
                {'kind': 'image', 'uri': item.toString()},
              ))
        .toList(growable: false);

    final triggers = _asList(map['triggers'] ?? map['conditions'])
        .map((item) => item is Map
            ? QuantumNotificationTriggerSpec.fromMap(
                item.map((k, v) => MapEntry(k.toString(), v)),
              )
            : QuantumNotificationTriggerSpec.fromMap(
                {'type': item.toString()},
              ))
        .toList(growable: false);

    final rawPriority = _asString(map['priority'], fallback: 'normal');

    return QuantumNotificationRequest(
      id: _asInt(map['id'] ?? map['notificationId'] ?? map['nid']),
      title: _asString(map['title'] ?? map['headline'] ?? map['subject'],
          fallback: ''),
      body:
          _asString(map['body'] ?? map['message'] ?? map['text'], fallback: ''),
      subtitle: map['subtitle']?.toString(),
      payload: map['payload']?.toString(),
      channelId: map['channelId']?.toString(),
      category: map['category']?.toString(),
      groupKey: map['groupKey']?.toString(),
      threadId: map['threadId']?.toString(),
      templateKey: map['templateKey']?.toString(),
      icon: map['icon']?.toString(),
      image: map['image']?.toString(),
      largeIcon: map['largeIcon']?.toString(),
      smallIcon: map['smallIcon']?.toString(),
      sound: map['sound']?.toString(),
      shortcutId: map['shortcutId']?.toString(),
      collapseKey: map['collapseKey']?.toString(),
      priority: QuantumNotificationPriority.values.firstWhere(
        (value) => value.name == rawPriority,
        orElse: () => QuantumNotificationPriority.normal,
      ),
      persistent: _asBool(map['persistent'] ?? map['ongoing']),
      silent: _asBool(map['silent'] ?? map['quiet']),
      autoCancel: _asBool(map['autoCancel'], fallback: true),
      localOnly: _asBool(map['localOnly'] ?? map['local']),
      onlyAlertOnce: _asBool(map['onlyAlertOnce'] ?? map['alertOnce']),
      showWhen: _asBool(map['showWhen'], fallback: true),
      showTimestamp: _asBool(map['showTimestamp'] ?? map['timestampVisible'],
          fallback: true),
      headsUp: _asBool(map['headsUp'] ?? map['popup']),
      ongoing: _asBool(map['ongoing']),
      nativeOnly: _asBool(map['nativeOnly'] ?? map['osOnly'], fallback: true),
      fallbackToSystem:
          _asBool(map['fallbackToSystem'] ?? map['fallback'], fallback: true),
      renderPolicy: _asString(map['renderPolicy'] ?? map['policy'],
          fallback: 'nativeOnly'),
      data: data,
      style: style,
      sdui: sdui,
      vm: vm,
      metadata: metadata,
      schedule: map['schedule'] is Map
          ? QuantumNotificationSchedule.fromMap(_asMap(map['schedule']))
          : null,
      layout: map['layout'] is Map
          ? QuantumNotificationLayoutSpec.fromMap(_asMap(map['layout']))
          : null,
      inlineReply: map['inlineReply'] is Map
          ? QuantumNotificationInlineReplySpec.fromMap(
              _asMap(map['inlineReply']))
          : null,
      progress: map['progress'] is Map
          ? QuantumNotificationProgressSpec.fromMap(_asMap(map['progress']))
          : null,
      liveActivity: map['liveActivity'] is Map
          ? QuantumNotificationLiveActivitySpec.fromMap(
              _asMap(map['liveActivity']))
          : null,
      animations:
          List<QuantumNotificationAnimationSpec>.unmodifiable(animations),
      media: List<QuantumNotificationMediaSpec>.unmodifiable(media),
      triggers: List<QuantumNotificationTriggerSpec>.unmodifiable(triggers),
      actions: List<QuantumNotificationAction>.unmodifiable(actions),
    );
  }

  static QuantumNotificationRequest compose(
      Iterable<QuantumNotificationRequest> parts) {
    QuantumNotificationRequest? result;
    for (final part in parts) {
      result = result == null ? part : result.merge(part);
    }
    return result ?? const QuantumNotificationRequest(title: '', body: '');
  }

  QuantumNotificationRequest copyWith({
    int? id,
    String? title,
    String? body,
    String? subtitle,
    String? payload,
    String? channelId,
    String? category,
    String? groupKey,
    String? threadId,
    String? templateKey,
    String? icon,
    String? image,
    String? largeIcon,
    String? smallIcon,
    String? sound,
    String? shortcutId,
    String? collapseKey,
    QuantumNotificationPriority? priority,
    bool? persistent,
    bool? silent,
    bool? autoCancel,
    bool? localOnly,
    bool? onlyAlertOnce,
    bool? showWhen,
    bool? showTimestamp,
    bool? headsUp,
    bool? ongoing,
    bool? nativeOnly,
    bool? fallbackToSystem,
    String? renderPolicy,
    Map<String, dynamic>? data,
    Map<String, dynamic>? style,
    Map<String, dynamic>? sdui,
    Map<String, dynamic>? vm,
    Map<String, dynamic>? metadata,
    QuantumNotificationSchedule? schedule,
    QuantumNotificationLayoutSpec? layout,
    QuantumNotificationInlineReplySpec? inlineReply,
    QuantumNotificationProgressSpec? progress,
    QuantumNotificationLiveActivitySpec? liveActivity,
    List<QuantumNotificationAnimationSpec>? animations,
    List<QuantumNotificationMediaSpec>? media,
    List<QuantumNotificationTriggerSpec>? triggers,
    List<QuantumNotificationAction>? actions,
  }) {
    return QuantumNotificationRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      subtitle: subtitle ?? this.subtitle,
      payload: payload ?? this.payload,
      channelId: channelId ?? this.channelId,
      category: category ?? this.category,
      groupKey: groupKey ?? this.groupKey,
      threadId: threadId ?? this.threadId,
      templateKey: templateKey ?? this.templateKey,
      icon: icon ?? this.icon,
      image: image ?? this.image,
      largeIcon: largeIcon ?? this.largeIcon,
      smallIcon: smallIcon ?? this.smallIcon,
      sound: sound ?? this.sound,
      shortcutId: shortcutId ?? this.shortcutId,
      collapseKey: collapseKey ?? this.collapseKey,
      priority: priority ?? this.priority,
      persistent: persistent ?? this.persistent,
      silent: silent ?? this.silent,
      autoCancel: autoCancel ?? this.autoCancel,
      localOnly: localOnly ?? this.localOnly,
      onlyAlertOnce: onlyAlertOnce ?? this.onlyAlertOnce,
      showWhen: showWhen ?? this.showWhen,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      headsUp: headsUp ?? this.headsUp,
      ongoing: ongoing ?? this.ongoing,
      nativeOnly: nativeOnly ?? this.nativeOnly,
      fallbackToSystem: fallbackToSystem ?? this.fallbackToSystem,
      renderPolicy: renderPolicy ?? this.renderPolicy,
      data: data ?? this.data,
      style: style ?? this.style,
      sdui: sdui ?? this.sdui,
      vm: vm ?? this.vm,
      metadata: metadata ?? this.metadata,
      schedule: schedule ?? this.schedule,
      layout: layout ?? this.layout,
      inlineReply: inlineReply ?? this.inlineReply,
      progress: progress ?? this.progress,
      liveActivity: liveActivity ?? this.liveActivity,
      animations: animations ?? this.animations,
      media: media ?? this.media,
      triggers: triggers ?? this.triggers,
      actions: actions ?? this.actions,
    );
  }

  QuantumNotificationRequest merge(QuantumNotificationRequest overlay) {
    return copyWith(
      id: overlay.id ?? id,
      title: overlay.title.isEmpty ? title : overlay.title,
      body: overlay.body.isEmpty ? body : overlay.body,
      subtitle: overlay.subtitle ?? subtitle,
      payload: overlay.payload ?? payload,
      channelId: overlay.channelId ?? channelId,
      category: overlay.category ?? category,
      groupKey: overlay.groupKey ?? groupKey,
      threadId: overlay.threadId ?? threadId,
      templateKey: overlay.templateKey ?? templateKey,
      icon: overlay.icon ?? icon,
      image: overlay.image ?? image,
      largeIcon: overlay.largeIcon ?? largeIcon,
      smallIcon: overlay.smallIcon ?? smallIcon,
      sound: overlay.sound ?? sound,
      shortcutId: overlay.shortcutId ?? shortcutId,
      collapseKey: overlay.collapseKey ?? collapseKey,
      priority: overlay.priority,
      persistent: overlay.persistent,
      silent: overlay.silent,
      autoCancel: overlay.autoCancel,
      localOnly: overlay.localOnly,
      onlyAlertOnce: overlay.onlyAlertOnce,
      showWhen: overlay.showWhen,
      showTimestamp: overlay.showTimestamp,
      headsUp: overlay.headsUp,
      ongoing: overlay.ongoing,
      nativeOnly: overlay.nativeOnly,
      fallbackToSystem: overlay.fallbackToSystem,
      renderPolicy:
          overlay.renderPolicy.isEmpty ? renderPolicy : overlay.renderPolicy,
      data: _mergeMaps(data, overlay.data),
      style: _mergeMaps(style, overlay.style),
      sdui: _mergeMaps(sdui, overlay.sdui),
      vm: _mergeMaps(vm, overlay.vm),
      metadata: _mergeMaps(metadata, overlay.metadata),
      schedule: overlay.schedule ?? schedule,
      layout: overlay.layout ?? layout,
      inlineReply: overlay.inlineReply ?? inlineReply,
      progress: overlay.progress ?? progress,
      liveActivity: overlay.liveActivity ?? liveActivity,
      animations: List<QuantumNotificationAnimationSpec>.unmodifiable([
        ...animations,
        ...overlay.animations,
      ]),
      media: List<QuantumNotificationMediaSpec>.unmodifiable([
        ...media,
        ...overlay.media,
      ]),
      triggers: List<QuantumNotificationTriggerSpec>.unmodifiable([
        ...triggers,
        ...overlay.triggers,
      ]),
      actions: _mergeActions(actions, overlay.actions),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (id != null) 'id': id,
        'title': title,
        'body': body,
        if (subtitle != null && subtitle!.isNotEmpty) 'subtitle': subtitle,
        if (payload != null && payload!.isNotEmpty) 'payload': payload,
        if (channelId != null && channelId!.isNotEmpty) 'channelId': channelId,
        if (category != null && category!.isNotEmpty) 'category': category,
        if (groupKey != null && groupKey!.isNotEmpty) 'groupKey': groupKey,
        if (threadId != null && threadId!.isNotEmpty) 'threadId': threadId,
        if (templateKey != null && templateKey!.isNotEmpty)
          'templateKey': templateKey,
        if (icon != null && icon!.isNotEmpty) 'icon': icon,
        if (image != null && image!.isNotEmpty) 'image': image,
        if (largeIcon != null && largeIcon!.isNotEmpty) 'largeIcon': largeIcon,
        if (smallIcon != null && smallIcon!.isNotEmpty) 'smallIcon': smallIcon,
        if (sound != null && sound!.isNotEmpty) 'sound': sound,
        if (shortcutId != null && shortcutId!.isNotEmpty)
          'shortcutId': shortcutId,
        if (collapseKey != null && collapseKey!.isNotEmpty)
          'collapseKey': collapseKey,
        'priority': priority.name,
        'persistent': persistent,
        'silent': silent,
        'autoCancel': autoCancel,
        'localOnly': localOnly,
        'onlyAlertOnce': onlyAlertOnce,
        'showWhen': showWhen,
        'showTimestamp': showTimestamp,
        'headsUp': headsUp,
        'ongoing': ongoing,
        'nativeOnly': nativeOnly,
        'fallbackToSystem': fallbackToSystem,
        'renderPolicy': renderPolicy,
        if (data.isNotEmpty) 'data': data,
        if (style.isNotEmpty) 'style': style,
        if (sdui.isNotEmpty) 'sdui': sdui,
        if (vm.isNotEmpty) 'vm': vm,
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (schedule != null) 'schedule': schedule!.toMap(),
        if (layout != null) 'layout': layout!.toMap(),
        if (inlineReply != null) 'inlineReply': inlineReply!.toMap(),
        if (progress != null) 'progress': progress!.toMap(),
        if (liveActivity != null) 'liveActivity': liveActivity!.toMap(),
        if (animations.isNotEmpty)
          'animations': animations
              .map((animation) => animation.toMap())
              .toList(growable: false),
        if (media.isNotEmpty)
          'media': media.map((item) => item.toMap()).toList(growable: false),
        if (triggers.isNotEmpty)
          'triggers': triggers
              .map((trigger) => trigger.toMap())
              .toList(growable: false),
        if (actions.isNotEmpty)
          'actions':
              actions.map((action) => action.toMap()).toList(growable: false),
      };

  SimpleNotification toLegacy() {
    return SimpleNotification(
      id: id ?? 0,
      title: title,
      body: body,
      payload: payload ?? '',
    );
  }
}

class QuantumNotificationDraft {
  QuantumNotificationRequest _spec;

  QuantumNotificationDraft([QuantumNotificationRequest? seed])
      : _spec = seed ?? const QuantumNotificationRequest(title: '', body: '');

  QuantumNotificationDraft fromMap(Map<String, dynamic> map) {
    _spec = QuantumNotificationRequest.fromMap(map);
    return this;
  }

  QuantumNotificationDraft merge(QuantumNotificationRequest other) {
    _spec = _spec.merge(other);
    return this;
  }

  QuantumNotificationDraft title(String value) {
    _spec = _spec.copyWith(title: value);
    return this;
  }

  QuantumNotificationDraft body(String value) {
    _spec = _spec.copyWith(body: value);
    return this;
  }

  QuantumNotificationDraft subtitle(String? value) {
    _spec = _spec.copyWith(subtitle: value);
    return this;
  }

  QuantumNotificationDraft payload(String? value) {
    _spec = _spec.copyWith(payload: value);
    return this;
  }

  QuantumNotificationDraft channel(String? value) {
    _spec = _spec.copyWith(channelId: value);
    return this;
  }

  QuantumNotificationDraft templateKey(String? value) {
    _spec = _spec.copyWith(templateKey: value);
    return this;
  }

  QuantumNotificationDraft renderPolicy(String value) {
    _spec = _spec.copyWith(renderPolicy: value);
    return this;
  }

  QuantumNotificationDraft action(QuantumNotificationAction action) {
    _spec = _spec.copyWith(actions: <QuantumNotificationAction>[
      ..._spec.actions,
      action,
    ]);
    return this;
  }

  QuantumNotificationDraft layout(QuantumNotificationLayoutSpec value) {
    _spec = _spec.copyWith(layout: value);
    return this;
  }

  QuantumNotificationDraft progress(QuantumNotificationProgressSpec value) {
    _spec = _spec.copyWith(progress: value);
    return this;
  }

  QuantumNotificationDraft animation(QuantumNotificationAnimationSpec value) {
    _spec = _spec.copyWith(animations: <QuantumNotificationAnimationSpec>[
      ..._spec.animations,
      value,
    ]);
    return this;
  }

  QuantumNotificationDraft media(QuantumNotificationMediaSpec value) {
    _spec = _spec.copyWith(media: <QuantumNotificationMediaSpec>[
      ..._spec.media,
      value,
    ]);
    return this;
  }

  QuantumNotificationDraft trigger(QuantumNotificationTriggerSpec value) {
    _spec = _spec.copyWith(triggers: <QuantumNotificationTriggerSpec>[
      ..._spec.triggers,
      value,
    ]);
    return this;
  }

  QuantumNotificationDraft sdui(Map<String, dynamic> value) {
    _spec = _spec.copyWith(sdui: value);
    return this;
  }

  QuantumNotificationDraft vm(Map<String, dynamic> value) {
    _spec = _spec.copyWith(vm: value);
    return this;
  }

  QuantumNotificationDraft data(Map<String, dynamic> value) {
    _spec = _spec.copyWith(data: value);
    return this;
  }

  QuantumNotificationDraft style(Map<String, dynamic> value) {
    _spec = _spec.copyWith(style: value);
    return this;
  }

  QuantumNotificationDraft schedule(QuantumNotificationSchedule value) {
    _spec = _spec.copyWith(schedule: value);
    return this;
  }

  QuantumNotificationRequest build() => _spec;
}

class _ShowCodec extends QLChannelCodec<QuantumNotificationRequest, bool> {
  const _ShowCodec();
  @override
  dynamic encode(QuantumNotificationRequest args) => args.toMap();
  @override
  bool decode(dynamic data) => data == true;
}

class _ShowBridge extends QLMethodBridge<QuantumNotificationRequest, bool> {
  @override
  String get channelName => 'quantum_notifications/show';

  @override
  QLChannelCodec<QuantumNotificationRequest, bool> get codec =>
      const _ShowCodec();
}

class _CancelBridge extends QLMethodBridge<int, bool> {
  @override
  String get channelName => 'quantum_notifications/cancel';

  @override
  QLChannelCodec<int, bool> get codec => const _IntBoolCodec();
}

class _IntBoolCodec extends QLChannelCodec<int, bool> {
  const _IntBoolCodec();
  @override
  dynamic encode(int args) => args;
  @override
  bool decode(dynamic data) => data == true;
}

class _TapStreamBridge extends QLEventBridge<NotificationTap> {
  @override
  String get channelName => 'quantum_notifications/taps';

  @override
  QLChannelCodec<void, NotificationTap> get codec =>
      QLMapCodec<NotificationTap>((map) => NotificationTap.fromMap(map));
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumNotifications {
  static final QuantumNotifications instance = QuantumNotifications._();

  QuantumNotifications._() {
    QLNativeBridgeRegistry.instance
        .register('quantum_notifications/show', _show);
    QLNativeBridgeRegistry.instance
        .register('quantum_notifications/cancel', _cancel);
    QLNativeBridgeRegistry.instance
        .register('quantum_notifications/taps', _taps);
  }

  final _show = _ShowBridge();
  final _cancel = _CancelBridge();
  final _taps = _TapStreamBridge();
  final QuantumNotificationRegistry _registry = QuantumNotificationRegistry();

  QuantumNotificationRegistry get registry => _registry;

  void attachRegistryPersistence({
    FutureOr<void> Function(Map<String, dynamic> snapshot)? write,
    FutureOr<Map<String, dynamic>?> Function()? read,
  }) {
    _registry.attachPersistence(write: write, read: read);
  }

  Future<void> persistRegistry() => _registry.persist();

  Future<void> restoreRegistry() => _registry.restore();

  QuantumNotificationTemplateRecord registerTemplate(
    String key,
    QuantumNotificationRequest request, {
    String? description,
    List<String> tags = const <String>[],
  }) {
    return _registry.registerTemplate(
      key,
      request,
      description: description,
      tags: tags,
    );
  }

  QuantumNotificationTemplateRecord registerTemplateJson(
    String key,
    Map<String, dynamic> json, {
    String? description,
    List<String> tags = const <String>[],
  }) {
    return _registry.registerJson(
      key,
      json,
      description: description,
      tags: tags,
    );
  }

  QuantumNotificationTemplateRecord? readTemplate(String key) =>
      _registry.read(key);

  QuantumNotificationRequest? readTemplateRequest(String key) =>
      _registry.readRequest(key);

  List<String> listTemplates() => _registry.keys;

  bool removeTemplate(String key) => _registry.remove(key) != null;

  QuantumNotificationTemplateRecord updateTemplate(
    String key, {
    QuantumNotificationRequest? request,
    Map<String, dynamic>? patch,
    String? description,
    List<String>? tags,
  }) {
    return _registry.update(
      key,
      request: request,
      patch: patch,
      description: description,
      tags: tags,
    );
  }

  Map<String, dynamic> exportRegistry() => _registry.snapshot();

  void importRegistry(Map<String, dynamic> snapshot) =>
      _registry.importSnapshot(snapshot);

  /// Shows a standard local notification.
  QLAsyncSignal<bool> show(SimpleNotification notification) {
    return _show(notification.toRequest());
  }

  /// Shows the rich notification spec directly.
  QLAsyncSignal<bool> showRich(QuantumNotificationRequest request) {
    return _show(request);
  }

  /// Shows a notification from a registered template key, optionally merged
  /// with overrides.
  QLAsyncSignal<bool> showTemplate(
    String key, {
    Map<String, dynamic>? overrides,
  }) {
    final template = _registry.readRequest(key);
    if (template == null) {
      return _show(
        QuantumNotificationRequest.fromMap(<String, dynamic>{
          'title': '',
          'body': '',
          'metadata': {'templateKey': key},
        }),
      );
    }

    final request = overrides == null
        ? template
        : template.merge(QuantumNotificationRequest.fromMap(
            <String, dynamic>{
              ...overrides,
              'templateKey': key,
            },
          ));

    return _show(request);
  }

  /// Accepts SDUI JSON, VM output, or a plain map and shows it as a rich
  /// notification without forcing callers to manually instantiate model types.
  QLAsyncSignal<bool> showJson(Object notification) {
    return _show(QuantumNotificationRequest.fromValue(notification));
  }

  /// Composes several fragments into one flat request, then shows it.
  QLAsyncSignal<bool> showComposite(Iterable<Object?> parts) {
    return _show(
      QuantumNotificationRequest.compose(
        parts.map(QuantumNotificationRequest.fromValue),
      ),
    );
  }

  /// Convenience builder for fluent composition.
  QuantumNotificationDraft draft([QuantumNotificationRequest? seed]) {
    return QuantumNotificationDraft(seed);
  }

  /// Cancels an active notification by ID.
  QLAsyncSignal<bool> cancel(int id) {
    return _cancel(id);
  }

  /// Stream of user taps on notifications so the app can route to the correct
  /// screen via payload / action / metadata.
  QLAsyncSignal<NotificationTap> listenForTaps() {
    return _taps.stream();
  }

  /// Helper for merging multiple notification fragments into one final spec.
  QuantumNotificationRequest compose(
      Iterable<QuantumNotificationRequest> parts) {
    return QuantumNotificationRequest.compose(parts);
  }
}
