/*
 * ============================================================================
 * File: qte_schema.dart
 * 
 * Description:
 * Defines the complete, strongly-typed data transfer object (DTO) schema for the
 * Quantum Test Engine. This file maps the external JSON test definitions into Dart
 * objects, ensuring type safety across the testing framework. It contains all enums,
 * primitive structures, and hierarchical definitions needed to describe a test suite.
 * 
 * Key Components:
 * - QTETestFile: The root DTO representing an entire test definition.
 * - QTEStepDef: Represents an individual sequence of an interaction and subsequent assertions.
 * - QTEInteraction & QTEAssertion: Definitions for user actions and verification checks.
 * - QTEViewport, QTETargetSpec, QTEMockDataSource: Supporting definitions for the test environment.
 * 
 * Dependencies/Relationships:
 * Acts as the foundational data layer. Relied upon by qte_validator, qte_runner,
 * and all execution engine modules.
 * 
 * Notes:
 * This layer does strict type parsing from JSON maps but leaves broader structural
 * validation (like required combinations of fields) to qte_validator.dart.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE SCHEMA — qte_schema.dart
// Complete strongly-typed DTO layer for the Quantum Test Engine JSON format.
// Every field, every enum — no dynamic fallbacks on the schema layer.
// ══════════════════════════════════════════════════════════════════════════════
library qte_schema;

// ─────────────────────────────────────────────────────────────────────────────
// §1 ERRORS
// ─────────────────────────────────────────────────────────────────────────────

class QTESchemaError implements Exception {
  final String message;
  final String path;
  const QTESchemaError(this.message, {this.path = ''});
  @override
  String toString() =>
      path.isNotEmpty ? 'QTESchemaError at "$path": $message' : 'QTESchemaError: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum QTEInteractionType {
  tap, doubleTap, longPress, hover, unhover,
  drag, scroll, type, clearText, focus, blur,
  resize, keyPress, rightClick, zoom, pinch,
  triggerAction, setState, mergeState, toggleState,
  dispatchSignal, wait, navigate, waitForSignal;

  static QTEInteractionType fromJson(String raw) {
    const map = <String, QTEInteractionType>{
      'tap': tap, 'double_tap': doubleTap, 'long_press': longPress,
      'hover': hover, 'unhover': unhover, 'drag': drag, 'scroll': scroll,
      'type': type, 'clear_text': clearText, 'focus': focus, 'blur': blur,
      'resize': resize, 'key_press': keyPress, 'right_click': rightClick,
      'zoom': zoom, 'pinch': pinch, 'trigger_action': triggerAction,
      'set_state': setState, 'merge_state': mergeState, 'toggle_state': toggleState,
      'dispatch_signal': dispatchSignal, 'wait': wait, 'navigate': navigate,
      'wait_for_signal': waitForSignal,
    };
    final v = map[raw];
    if (v == null) throw QTESchemaError('Unknown interaction type: "$raw"', path: 'interaction.type');
    return v;
  }

  String toJson() {
    switch (this) {
      case tap: return 'tap'; case doubleTap: return 'double_tap';
      case longPress: return 'long_press'; case hover: return 'hover';
      case unhover: return 'unhover'; case drag: return 'drag';
      case scroll: return 'scroll'; case type: return 'type';
      case clearText: return 'clear_text'; case focus: return 'focus';
      case blur: return 'blur'; case resize: return 'resize';
      case keyPress: return 'key_press'; case rightClick: return 'right_click';
      case zoom: return 'zoom'; case pinch: return 'pinch';
      case triggerAction: return 'trigger_action'; case setState: return 'set_state';
      case mergeState: return 'merge_state'; case toggleState: return 'toggle_state';
      case dispatchSignal: return 'dispatch_signal'; case wait: return 'wait';
      case navigate: return 'navigate'; case waitForSignal: return 'wait_for_signal';
    }
  }
}

enum QTEAssertionType {
  // UI Geometry
  widgetExists, widgetNotExists, widgetWidth, widgetHeight, widgetSize,
  widgetOffset, widgetVisible, widgetNotVisible, widgetColor,
  widgetBackgroundColor, widgetBorderRadius, widgetOpacity,
  widgetText, widgetTextContains, widgetTextStyle, widgetCount,
  widgetOrder, widgetEnabled, widgetDisabled, widgetFocused,
  widgetScrollable, widgetScrollOffset, widgetConstrained,
  // State
  stateEquals, stateNotEquals, stateContains, stateType, stateNull,
  stateNotNull, stateListLength, stateGreaterThan, stateLessThan, stateMatchesRegex,
  // Reactive / Signals
  signalEmitted, signalValue, reactiveRebuilt, storeKeyChanged, actionCalled, actionResult,
  // Style / Design Tokens
  styleClassPresent, styleTokenValue, computedStyle, themeToken,
  // Performance
  firstFrameUnderMs, rerenderUnderMs, noFrameDrops, memoryUnderMb,
  memoryDeltaUnderMb, rasterizeUnderMs, noJank,
  // Interaction Behaviors
  hoverTriggered, dragCompleted, scrollReachedEnd, animationCompleted,
  portalOpened, portalClosed;

  static QTEAssertionType fromJson(String raw) {
    const map = <String, QTEAssertionType>{
      'widget_exists': widgetExists, 'widget_not_exists': widgetNotExists,
      'widget_width': widgetWidth, 'widget_height': widgetHeight,
      'widget_size': widgetSize, 'widget_offset': widgetOffset,
      'widget_visible': widgetVisible, 'widget_not_visible': widgetNotVisible,
      'widget_color': widgetColor, 'widget_background_color': widgetBackgroundColor,
      'widget_border_radius': widgetBorderRadius, 'widget_opacity': widgetOpacity,
      'widget_text': widgetText, 'widget_text_contains': widgetTextContains,
      'widget_text_style': widgetTextStyle, 'widget_count': widgetCount,
      'widget_order': widgetOrder, 'widget_enabled': widgetEnabled,
      'widget_disabled': widgetDisabled, 'widget_focused': widgetFocused,
      'widget_scrollable': widgetScrollable, 'widget_scroll_offset': widgetScrollOffset,
      'widget_constrained': widgetConstrained,
      'state_equals': stateEquals, 'state_not_equals': stateNotEquals,
      'state_contains': stateContains, 'state_type': stateType,
      'state_null': stateNull, 'state_not_null': stateNotNull,
      'state_list_length': stateListLength, 'state_greater_than': stateGreaterThan,
      'state_less_than': stateLessThan, 'state_matches_regex': stateMatchesRegex,
      'signal_emitted': signalEmitted, 'signal_value': signalValue,
      'reactive_rebuilt': reactiveRebuilt, 'store_key_changed': storeKeyChanged,
      'action_called': actionCalled, 'action_result': actionResult,
      'style_class_present': styleClassPresent, 'style_token_value': styleTokenValue,
      'computed_style': computedStyle, 'theme_token': themeToken,
      'first_frame_under_ms': firstFrameUnderMs, 'rerender_under_ms': rerenderUnderMs,
      'no_frame_drops': noFrameDrops, 'memory_under_mb': memoryUnderMb,
      'memory_delta_under_mb': memoryDeltaUnderMb, 'rasterize_under_ms': rasterizeUnderMs,
      'no_jank': noJank, 'hover_triggered': hoverTriggered,
      'drag_completed': dragCompleted, 'scroll_reached_end': scrollReachedEnd,
      'animation_completed': animationCompleted, 'portal_opened': portalOpened,
      'portal_closed': portalClosed,
    };
    final v = map[raw];
    if (v == null) throw QTESchemaError('Unknown assertion type: "$raw"', path: 'assertion.type');
    return v;
  }
}

enum QTETargetBy { key, text, type, semanticLabel, testId, path;
  static QTETargetBy fromJson(String raw) {
    switch (raw) {
      case 'key': return key; case 'text': return text; case 'type': return type;
      case 'semanticLabel': return semanticLabel; case 'testId': return testId;
      case 'path': return path;
      default: throw QTESchemaError('Unknown target by: "$raw"', path: 'target.by');
    }
  }
}

enum QTEMatcher {
  equals, notEquals, gt, gte, lt, lte, between, contains,
  startsWith, endsWith, matchesRegex, isNull, isNotNull, isTrue, isFalse;

  static QTEMatcher fromJson(String raw) {
    const map = <String, QTEMatcher>{
      'equals': equals, 'not_equals': notEquals, 'gt': gt, 'gte': gte,
      'lt': lt, 'lte': lte, 'between': between, 'contains': contains,
      'starts_with': startsWith, 'ends_with': endsWith,
      'matches_regex': matchesRegex, 'is_null': isNull,
      'is_not_null': isNotNull, 'is_true': isTrue, 'is_false': isFalse,
    };
    final v = map[raw];
    if (v == null) throw QTESchemaError('Unknown matcher: "$raw"', path: 'matcher');
    return v;
  }
}

enum QTEOrientation { portrait, landscape }
enum QTESeverity { error, warning, info }
enum QTEResizeHandle { bottomRight, right, bottom, topRight, topLeft, bottomLeft, top, left }

// ─────────────────────────────────────────────────────────────────────────────
// §3 PRIMITIVE DTOs
// ─────────────────────────────────────────────────────────────────────────────

class QTEVec2 {
  final double dx, dy;
  const QTEVec2({this.dx = 0.0, this.dy = 0.0});
  factory QTEVec2.fromJson(Map<String, dynamic> j) =>
      QTEVec2(dx: (j['dx'] as num? ?? 0.0).toDouble(), dy: (j['dy'] as num? ?? 0.0).toDouble());
  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};
}

class QTETextStyleSpec {
  final double? fontSize;
  final String? fontWeight;
  final String? color;
  final double? letterSpacing;
  final String? fontFamily;
  final String? decoration;
  const QTETextStyleSpec({this.fontSize, this.fontWeight, this.color,
      this.letterSpacing, this.fontFamily, this.decoration});
  factory QTETextStyleSpec.fromJson(Map<String, dynamic> j) => QTETextStyleSpec(
    fontSize: (j['fontSize'] as num?)?.toDouble(),
    fontWeight: j['fontWeight']?.toString(),
    color: j['color']?.toString(),
    letterSpacing: (j['letterSpacing'] as num?)?.toDouble(),
    fontFamily: j['fontFamily']?.toString(),
    decoration: j['decoration']?.toString(),
  );
  Map<String, dynamic> toJson() => {
    if (fontSize != null) 'fontSize': fontSize,
    if (fontWeight != null) 'fontWeight': fontWeight,
    if (color != null) 'color': color,
    if (letterSpacing != null) 'letterSpacing': letterSpacing,
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (decoration != null) 'decoration': decoration,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 TARGET SPEC
// ─────────────────────────────────────────────────────────────────────────────

class QTETargetSpec {
  final QTETargetBy by;
  final String value;
  const QTETargetSpec({required this.by, required this.value});

  factory QTETargetSpec.fromJson(dynamic raw, {String path = 'target'}) {
    if (raw is! Map) throw QTESchemaError('Expected object', path: path);
    final j = Map<String, dynamic>.from(raw);
    if (!j.containsKey('by')) throw QTESchemaError('Missing "by"', path: '$path.by');
    if (!j.containsKey('value')) throw QTESchemaError('Missing "value"', path: '$path.value');
    return QTETargetSpec(by: QTETargetBy.fromJson(j['by'].toString()), value: j['value'].toString());
  }

  Map<String, dynamic> toJson() => {'by': by.name, 'value': value};
}

// ─────────────────────────────────────────────────────────────────────────────
// §5 VIEWPORT
// ─────────────────────────────────────────────────────────────────────────────

class QTEViewport {
  final double width, height, pixelRatio;
  final QTEOrientation orientation;
  const QTEViewport({required this.width, required this.height,
      this.pixelRatio = 1.0, this.orientation = QTEOrientation.portrait});

  factory QTEViewport.fromJson(dynamic raw) {
    if (raw is! Map) return const QTEViewport(width: 390, height: 844);
    final j = Map<String, dynamic>.from(raw);
    return QTEViewport(
      width: (j['width'] as num? ?? 390).toDouble(),
      height: (j['height'] as num? ?? 844).toDouble(),
      pixelRatio: (j['pixelRatio'] as num? ?? 1.0).toDouble(),
      orientation: j['orientation'] == 'landscape' ? QTEOrientation.landscape : QTEOrientation.portrait,
    );
  }
  Map<String, dynamic> toJson() => {'width': width, 'height': height,
      'pixelRatio': pixelRatio, 'orientation': orientation.name};
}

// ─────────────────────────────────────────────────────────────────────────────
// §6 PERFORMANCE BUDGET
// ─────────────────────────────────────────────────────────────────────────────

class QTEPerformanceBudget {
  final double? maxFirstFrameMs, maxReRenderMs, maxMemoryMb;
  final int maxFrameDrops;
  final bool trackFrames, trackMemory, trackRasterize;
  const QTEPerformanceBudget({this.maxFirstFrameMs, this.maxReRenderMs,
      this.maxMemoryMb, this.maxFrameDrops = 0,
      this.trackFrames = false, this.trackMemory = false, this.trackRasterize = false});

  factory QTEPerformanceBudget.fromJson(dynamic raw) {
    if (raw is! Map) return const QTEPerformanceBudget();
    final j = Map<String, dynamic>.from(raw);
    return QTEPerformanceBudget(
      maxFirstFrameMs: (j['maxFirstFrameMs'] as num?)?.toDouble(),
      maxReRenderMs: (j['maxReRenderMs'] as num?)?.toDouble(),
      maxMemoryMb: (j['maxMemoryMb'] as num?)?.toDouble(),
      maxFrameDrops: j['maxFrameDrops'] as int? ?? 0,
      trackFrames: j['trackFrames'] == true,
      trackMemory: j['trackMemory'] == true,
      trackRasterize: j['trackRasterize'] == true,
    );
  }
  Map<String, dynamic> toJson() => {
    if (maxFirstFrameMs != null) 'maxFirstFrameMs': maxFirstFrameMs,
    if (maxReRenderMs != null) 'maxReRenderMs': maxReRenderMs,
    if (maxMemoryMb != null) 'maxMemoryMb': maxMemoryMb,
    'maxFrameDrops': maxFrameDrops, 'trackFrames': trackFrames,
    'trackMemory': trackMemory, 'trackRasterize': trackRasterize,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// §7 SNAPSHOT CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class QTESnapshotConfig {
  final bool captureMemory, captureFrame, captureState, captureWidgetTree;
  const QTESnapshotConfig({this.captureMemory = false, this.captureFrame = false,
      this.captureState = false, this.captureWidgetTree = false});
  factory QTESnapshotConfig.fromJson(dynamic raw) {
    if (raw is! Map) return const QTESnapshotConfig();
    final j = Map<String, dynamic>.from(raw);
    return QTESnapshotConfig(
      captureMemory: j['captureMemory'] == true, captureFrame: j['captureFrame'] == true,
      captureState: j['captureState'] == true, captureWidgetTree: j['captureWidgetTree'] == true,
    );
  }
  Map<String, dynamic> toJson() => {'captureMemory': captureMemory,
      'captureFrame': captureFrame, 'captureState': captureState,
      'captureWidgetTree': captureWidgetTree};
}

// ─────────────────────────────────────────────────────────────────────────────
// §8 INTERACTION DTO
// ─────────────────────────────────────────────────────────────────────────────

class QTEInteraction {
  final QTEInteractionType type;
  final QTETargetSpec? target;
  final QTEVec2? offset, from, to, delta;
  final int durationMs, waitMs, timeoutMs;
  final String? text, key, action, stateKey, storeKey, route;
  final double? newWidth, newHeight, scale;
  final QTEResizeHandle resizeHandle;
  final List<String> modifiers;
  final Map<String, dynamic> params, data;
  final Map<String, String> queryParams;
  final dynamic expectedValue;

  const QTEInteraction({
    required this.type, this.target,
    this.offset, this.from, this.to, this.delta,
    this.durationMs = 300, this.waitMs = 0, this.timeoutMs = 3000,
    this.text, this.key, this.action, this.stateKey, this.storeKey, this.route,
    this.newWidth, this.newHeight, this.scale = 1.0,
    this.resizeHandle = QTEResizeHandle.bottomRight,
    this.modifiers = const [], this.params = const {},
    this.data = const {}, this.queryParams = const {},
    this.expectedValue,
  });

  static QTEResizeHandle _parseHandle(dynamic r) {
    switch (r?.toString()) {
      case 'right': return QTEResizeHandle.right;
      case 'bottom': return QTEResizeHandle.bottom;
      case 'top_right': return QTEResizeHandle.topRight;
      case 'top_left': return QTEResizeHandle.topLeft;
      case 'bottom_left': return QTEResizeHandle.bottomLeft;
      case 'top': return QTEResizeHandle.top;
      case 'left': return QTEResizeHandle.left;
      default: return QTEResizeHandle.bottomRight;
    }
  }

  static List<String> _strList(dynamic r) =>
      r is List ? r.map((e) => e.toString()).toList() : const [];

  factory QTEInteraction.fromJson(dynamic raw, {String path = 'interaction'}) {
    if (raw is! Map) throw QTESchemaError('Expected object', path: path);
    final j = Map<String, dynamic>.from(raw);
    if (!j.containsKey('type')) throw QTESchemaError('Missing "type"', path: '$path.type');
    QTEVec2? vec(String k) => j[k] is Map
        ? QTEVec2.fromJson(Map<String, dynamic>.from(j[k])) : null;
    return QTEInteraction(
      type: QTEInteractionType.fromJson(j['type'].toString()),
      target: j['target'] != null ? QTETargetSpec.fromJson(j['target'], path: '$path.target') : null,
      offset: vec('offset'), from: vec('from'), to: vec('to'), delta: vec('delta'),
      durationMs: j['durationMs'] as int? ?? 300,
      waitMs: j['ms'] as int? ?? 0,
      timeoutMs: j['timeoutMs'] as int? ?? 3000,
      text: j['text']?.toString(), key: j['key']?.toString(),
      action: j['action']?.toString(), stateKey: j['stateKey']?.toString(),
      storeKey: j['storeKey']?.toString(), route: j['route']?.toString(),
      newWidth: (j['newWidth'] as num?)?.toDouble(),
      newHeight: (j['newHeight'] as num?)?.toDouble(),
      scale: (j['scale'] as num? ?? 1.0).toDouble(),
      resizeHandle: _parseHandle(j['handle']),
      modifiers: _strList(j['modifiers']),
      params: j['params'] is Map ? Map<String, dynamic>.from(j['params']) : const {},
      data: j['data'] is Map ? Map<String, dynamic>.from(j['data']) : const {},
      queryParams: j['queryParams'] is Map
          ? Map<String, String>.from((j['queryParams'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString())))
          : const {},
      expectedValue: j['expectedValue'],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §9 ASSERTION DTO
// ─────────────────────────────────────────────────────────────────────────────

class QTEAssertion {
  final String id, label;
  final bool disabled;
  final QTEAssertionType type;
  final QTETargetSpec? target;
  final dynamic expected;
  final QTEMatcher matcher;
  final double? min, max, tolerance;
  final String? storeKey, action, token, color, deltaFromStep, message;
  final QTETextStyleSpec? textStyle;
  final double? width, height;
  final int? count;
  final QTEVec2? scrollOffset;
  final QTESeverity severity;

  const QTEAssertion({
    required this.id, this.label = '', this.disabled = false,
    required this.type, this.target, this.expected,
    this.matcher = QTEMatcher.equals, this.min, this.max, this.tolerance = 1.0,
    this.storeKey, this.action, this.token, this.color, this.deltaFromStep, this.message,
    this.textStyle, this.width, this.height, this.count, this.scrollOffset,
    this.severity = QTESeverity.error,
  });

  factory QTEAssertion.fromJson(dynamic raw, {String path = 'assertion'}) {
    if (raw is! Map) throw QTESchemaError('Expected object', path: path);
    final j = Map<String, dynamic>.from(raw);
    if (!j.containsKey('id')) throw QTESchemaError('Missing "id"', path: '$path.id');
    if (!j.containsKey('type')) throw QTESchemaError('Missing "type"', path: '$path.type');
    return QTEAssertion(
      id: j['id'].toString(), label: j['label']?.toString() ?? '',
      disabled: j['disabled'] == true,
      type: QTEAssertionType.fromJson(j['type'].toString()),
      target: j['target'] != null ? QTETargetSpec.fromJson(j['target'], path: '$path.target') : null,
      expected: j['expected'],
      matcher: j.containsKey('matcher') ? QTEMatcher.fromJson(j['matcher'].toString()) : QTEMatcher.equals,
      min: (j['min'] as num?)?.toDouble(), max: (j['max'] as num?)?.toDouble(),
      tolerance: (j['tolerance'] as num? ?? 1.0).toDouble(),
      storeKey: j['storeKey']?.toString(), action: j['action']?.toString(),
      token: j['token']?.toString(), color: j['color']?.toString(),
      deltaFromStep: j['deltaFromStep']?.toString(), message: j['message']?.toString(),
      textStyle: j['textStyle'] is Map
          ? QTETextStyleSpec.fromJson(Map<String, dynamic>.from(j['textStyle'])) : null,
      width: (j['width'] as num?)?.toDouble(), height: (j['height'] as num?)?.toDouble(),
      count: j['count'] as int?,
      scrollOffset: j['scrollOffset'] is Map
          ? QTEVec2.fromJson(Map<String, dynamic>.from(j['scrollOffset'])) : null,
      severity: j['severity'] == 'warning' ? QTESeverity.warning
          : j['severity'] == 'info' ? QTESeverity.info : QTESeverity.error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §10 STEP DTO
// ─────────────────────────────────────────────────────────────────────────────

class QTEStepDef {
  final String id, label;
  final bool disabled;
  final QTEInteraction? interaction;
  final List<QTEAssertion> assertions;
  final QTESnapshotConfig? snapshot;

  const QTEStepDef({required this.id, required this.label, this.disabled = false,
      this.interaction, this.assertions = const [], this.snapshot});

  factory QTEStepDef.fromJson(dynamic raw, {int index = 0}) {
    if (raw is! Map) throw QTESchemaError('Expected object', path: 'steps[$index]');
    final j = Map<String, dynamic>.from(raw);
    final p = 'steps[$index]';
    if (!j.containsKey('id')) throw QTESchemaError('Missing "id"', path: '$p.id');
    if (!j.containsKey('label')) throw QTESchemaError('Missing "label"', path: '$p.label');
    final raw2 = j['assertions'];
    final assertions = <QTEAssertion>[];
    if (raw2 is List) {
      for (var i = 0; i < raw2.length; i++) {
        assertions.add(QTEAssertion.fromJson(raw2[i], path: '$p.assertions[$i]'));
      }
    }
    return QTEStepDef(
      id: j['id'].toString(), label: j['label'].toString(),
      disabled: j['disabled'] == true,
      interaction: j['interaction'] != null
          ? QTEInteraction.fromJson(j['interaction'], path: '$p.interaction') : null,
      assertions: assertions,
      snapshot: j['snapshot'] != null ? QTESnapshotConfig.fromJson(j['snapshot']) : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §11 MOCK DATA SOURCE
// ─────────────────────────────────────────────────────────────────────────────

class QTEMockDataSource {
  final String sourceId, operation;
  final dynamic response;
  final int delayMs;
  final bool shouldFail;
  final String? errorMessage;
  const QTEMockDataSource({required this.sourceId, this.operation = '*',
      this.response, this.delayMs = 0, this.shouldFail = false, this.errorMessage});
  factory QTEMockDataSource.fromJson(dynamic raw, {String path = ''}) {
    if (raw is! Map) throw QTESchemaError('Expected object', path: path);
    final j = Map<String, dynamic>.from(raw);
    if (!j.containsKey('sourceId')) throw QTESchemaError('Missing "sourceId"', path: '$path.sourceId');
    return QTEMockDataSource(
      sourceId: j['sourceId'].toString(), operation: j['operation']?.toString() ?? '*',
      response: j['response'], delayMs: j['delayMs'] as int? ?? 0,
      shouldFail: j['shouldFail'] == true, errorMessage: j['errorMessage']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §12 ROOT TEST FILE
// ─────────────────────────────────────────────────────────────────────────────

class QTETestFile {
  static const String schemaId = 'quantum://test-engine/v1';
  final String id, title, description, version;
  final List<String> tags;
  final bool disabled;
  final QTEViewport viewport;
  final Map<String, dynamic> sdui, initialState, env;
  final QTEPerformanceBudget performance;
  final List<QTEStepDef> steps;
  final bool teardownClearState, teardownClearCache;
  final List<QTEMockDataSource> mocks;

  const QTETestFile({
    required this.id, required this.title, this.description = '',
    this.tags = const [], this.version = '1.0', this.disabled = false,
    required this.viewport, required this.sdui,
    this.initialState = const {}, this.env = const {},
    this.performance = const QTEPerformanceBudget(),
    required this.steps,
    this.teardownClearState = true, this.teardownClearCache = false,
    this.mocks = const [],
  });

  factory QTETestFile.fromJson(Map<String, dynamic> j) {
    if (!j.containsKey('id')) throw const QTESchemaError('Missing "id"', path: 'id');
    if (!j.containsKey('title')) throw const QTESchemaError('Missing "title"', path: 'title');
    if (!j.containsKey('sdui')) throw const QTESchemaError('Missing "sdui"', path: 'sdui');
    if (!j.containsKey('steps')) throw const QTESchemaError('Missing "steps"', path: 'steps');
    final rawSteps = j['steps'];
    if (rawSteps is! List) throw const QTESchemaError('"steps" must be array', path: 'steps');
    final steps = <QTEStepDef>[];
    for (var i = 0; i < rawSteps.length; i++) {
      steps.add(QTEStepDef.fromJson(rawSteps[i], index: i));
    }
    final rawMocks = j['mocks'];
    final mocks = <QTEMockDataSource>[];
    if (rawMocks is List) {
      for (var i = 0; i < rawMocks.length; i++) {
        mocks.add(QTEMockDataSource.fromJson(rawMocks[i], path: 'mocks[$i]'));
      }
    }
    final td = j['teardown'] is Map ? Map<String, dynamic>.from(j['teardown']) : const <String, dynamic>{};
    return QTETestFile(
      id: j['id'].toString(), title: j['title'].toString(),
      description: j['description']?.toString() ?? '',
      tags: j['tags'] is List ? (j['tags'] as List).map((e) => e.toString()).toList() : const [],
      version: j['version']?.toString() ?? '1.0', disabled: j['disabled'] == true,
      viewport: QTEViewport.fromJson(j['viewport']),
      sdui: j['sdui'] is Map ? Map<String, dynamic>.from(j['sdui']) : const {},
      initialState: j['initialState'] is Map ? Map<String, dynamic>.from(j['initialState']) : const {},
      env: j['env'] is Map ? Map<String, dynamic>.from(j['env']) : const {},
      performance: QTEPerformanceBudget.fromJson(j['performance']),
      steps: steps,
      teardownClearState: td['clearState'] != false,
      teardownClearCache: td['clearCache'] == true,
      mocks: mocks,
    );
  }
}
