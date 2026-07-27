import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/src/plugins/native/quantum_notifications.dart';

class _Case<T> {
  final String name;
  final T Function() build;
  final void Function(T value) verify;

  const _Case(this.name, this.build, this.verify);
}

void _runCases<T>(String name, List<_Case<T>> cases) {
  group(name, () {
    for (final c in cases) {
      test(c.name, () {
        final value = c.build();
        c.verify(value);
      });
    }
  });
}

Map<String, dynamic> _map(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

void _expectAction(
  QuantumNotificationAction value, {
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
  if (id != null) expect(value.id, id);
  if (label != null) expect(value.label, label);
  if (icon != null) expect(value.icon, icon);
  if (foreground != null) expect(value.foreground, foreground);
  if (destructive != null) expect(value.destructive, destructive);
  if (opensApp != null) expect(value.opensApp, opensApp);
  if (dismissOnTap != null) expect(value.dismissOnTap, dismissOnTap);
  if (payload != null) expect(value.payload, payload);
  if (sdui != null) expect(value.sdui, sdui);
  if (vm != null) expect(value.vm, vm);
  if (metadata != null) expect(value.metadata, metadata);
}

void _expectSchedule(
  QuantumNotificationSchedule value, {
  String? atIso,
  int? delayMs,
  int? repeatEveryMs,
  int? repeatCount,
  String? cron,
  bool? exact,
  bool? allowWhileIdle,
  Map<String, dynamic>? metadata,
}) {
  if (atIso != null) expect(value.at?.toIso8601String(), atIso);
  if (delayMs != null) expect(value.delay?.inMilliseconds, delayMs);
  if (repeatEveryMs != null)
    expect(value.repeatEvery?.inMilliseconds, repeatEveryMs);
  if (repeatCount != null) expect(value.repeatCount, repeatCount);
  if (cron != null) expect(value.cron, cron);
  if (exact != null) expect(value.exact, exact);
  if (allowWhileIdle != null) expect(value.allowWhileIdle, allowWhileIdle);
  if (metadata != null) expect(value.metadata, metadata);
}

void _expectLayout(
  QuantumNotificationLayoutSpec value, {
  String? mode,
  int? columns,
  int? rows,
  double? gap,
  int? itemsLength,
  Map<String, dynamic>? metadata,
}) {
  if (mode != null) expect(value.mode, mode);
  if (columns != null) expect(value.columns, columns);
  if (rows != null) expect(value.rows, rows);
  if (gap != null) expect(value.gap, gap);
  if (itemsLength != null) expect(value.items.length, itemsLength);
  if (metadata != null) expect(value.metadata, metadata);
}

void _expectProgress(
  QuantumNotificationProgressSpec value, {
  int? valueAmount,
  int? max,
  bool? indeterminate,
  bool? live,
  bool? showTimer,
  String? label,
  Map<String, dynamic>? metadata,
}) {
  if (valueAmount != null) expect(value.value, valueAmount);
  if (max != null) expect(value.max, max);
  if (indeterminate != null) expect(value.indeterminate, indeterminate);
  if (live != null) expect(value.live, live);
  if (showTimer != null) expect(value.showTimer, showTimer);
  if (label != null) expect(value.label, label);
  if (metadata != null) expect(value.metadata, metadata);
}

void _expectTap(
  NotificationTap value, {
  int? id,
  String? payload,
  String? actionId,
  String? type,
  String? channelId,
  Map<String, dynamic>? data,
  String? timestampIso,
}) {
  if (id != null) expect(value.id, id);
  if (payload != null) expect(value.payload, payload);
  if (actionId != null) expect(value.actionId, actionId);
  if (type != null) expect(value.type, type);
  if (channelId != null) expect(value.channelId, channelId);
  if (data != null) expect(value.data, data);
  if (timestampIso != null)
    expect(value.timestamp?.toIso8601String(), timestampIso);
}

void _expectEvent(
  QuantumNotificationEvent value, {
  QuantumNotificationEventType? type,
  int? id,
  String? payload,
  String? actionId,
  String? channelId,
  Map<String, dynamic>? data,
  String? timestampIso,
}) {
  if (type != null) expect(value.type, type);
  if (id != null) expect(value.id, id);
  if (payload != null) expect(value.payload, payload);
  if (actionId != null) expect(value.actionId, actionId);
  if (channelId != null) expect(value.channelId, channelId);
  if (data != null) expect(value.data, data);
  if (timestampIso != null)
    expect(value.timestamp?.toIso8601String(), timestampIso);
}

void _expectTemplate(
  QuantumNotificationTemplate value, {
  String? key,
  String? title,
  String? body,
  String? createdAtIso,
  String? updatedAtIso,
}) {
  if (key != null) expect(value.key, key);
  if (title != null) expect(value.request.title, title);
  if (body != null) expect(value.request.body, body);
  if (createdAtIso != null)
    expect(value.createdAt?.toIso8601String(), createdAtIso);
  if (updatedAtIso != null)
    expect(value.updatedAt?.toIso8601String(), updatedAtIso);
}

void _expectRequest(
  QuantumNotificationRequest value, {
  int? id,
  String? title,
  String? body,
  String? subtitle,
  String? payload,
  String? channelId,
  String? category,
  String? groupKey,
  String? threadId,
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
  Map<String, dynamic>? data,
  Map<String, dynamic>? style,
  Map<String, dynamic>? sdui,
  Map<String, dynamic>? vm,
  Map<String, dynamic>? metadata,
  QuantumNotificationLayoutSpec? layout,
  QuantumNotificationProgressSpec? progress,
  int? triggersLength,
  String? templateKey,
  int? actionsLength,
  int? scheduleMs,
}) {
  if (id != null) expect(value.id, id);
  if (title != null) expect(value.title, title);
  if (body != null) expect(value.body, body);
  if (subtitle != null) expect(value.subtitle, subtitle);
  if (payload != null) expect(value.payload, payload);
  if (channelId != null) expect(value.channelId, channelId);
  if (category != null) expect(value.category, category);
  if (groupKey != null) expect(value.groupKey, groupKey);
  if (threadId != null) expect(value.threadId, threadId);
  if (icon != null) expect(value.icon, icon);
  if (image != null) expect(value.image, image);
  if (largeIcon != null) expect(value.largeIcon, largeIcon);
  if (smallIcon != null) expect(value.smallIcon, smallIcon);
  if (sound != null) expect(value.sound, sound);
  if (shortcutId != null) expect(value.shortcutId, shortcutId);
  if (collapseKey != null) expect(value.collapseKey, collapseKey);
  if (priority != null) expect(value.priority, priority);
  if (persistent != null) expect(value.persistent, persistent);
  if (silent != null) expect(value.silent, silent);
  if (autoCancel != null) expect(value.autoCancel, autoCancel);
  if (localOnly != null) expect(value.localOnly, localOnly);
  if (onlyAlertOnce != null) expect(value.onlyAlertOnce, onlyAlertOnce);
  if (showWhen != null) expect(value.showWhen, showWhen);
  if (showTimestamp != null) expect(value.showTimestamp, showTimestamp);
  if (headsUp != null) expect(value.headsUp, headsUp);
  if (ongoing != null) expect(value.ongoing, ongoing);
  if (data != null) expect(value.data, data);
  if (style != null) expect(value.style, style);
  if (sdui != null) expect(value.sdui, sdui);
  if (vm != null) expect(value.vm, vm);
  if (metadata != null) expect(value.metadata, metadata);
  if (layout != null) expect(value.layout, layout);
  if (progress != null) expect(value.progress, progress);
  if (triggersLength != null) expect(value.triggers.length, triggersLength);
  if (templateKey != null) expect(value.templateKey, templateKey);
  if (actionsLength != null) expect(value.actions.length, actionsLength);
  if (scheduleMs != null)
    expect(value.schedule?.delay?.inMilliseconds, scheduleMs);
}

void main() {
  setUp(() {
    QuantumNotifications.instance.registry.clear();
    QuantumNotifications.instance.registry.attachPersistence();
  });

  _runCases<QuantumNotificationRequest>("Request identity aliases 1", [
    _Case<QuantumNotificationRequest>(
      "id from id",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"id": 1, "title": "S0 title 1", "body": "S0 body 1"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 1);
        expect(value.title, "S0 title 1");
        expect(value.body, "S0 body 1");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from notificationId",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"notificationId": 2, "headline": "S0 title 2", "message": "S0 body 2"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 2);
        expect(value.title, "S0 title 2");
        expect(value.body, "S0 body 2");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from nid",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"nid": 3, "subject": "S0 title 3", "text": "S0 body 3"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 3);
        expect(value.title, "S0 title 3");
        expect(value.body, "S0 body 3");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from title",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S0 direct", "body": "S0 body 4"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S0 direct");
        expect(value.body, "S0 body 4");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from headline",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"headline": "S0 headline", "body": "S0 body 5"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S0 headline");
        expect(value.body, "S0 body 5");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from subject",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"subject": "S0 subject", "body": "S0 body 6"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S0 subject");
        expect(value.body, "S0 body 6");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from body",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S0 title 7", "body": "S0 body 7"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S0 title 7");
        expect(value.body, "S0 body 7");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from message",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S0 title 8", "message": "S0 message 8"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S0 title 8");
        expect(value.body, "S0 message 8");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from text",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S0 title 9", "text": "S0 text 9"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S0 title 9");
        expect(value.body, "S0 text 9");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "empty fallback",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "", "body": "", "priority": "normal"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "");
        expect(value.body, "");
        expect(value.priority, QuantumNotificationPriority.normal);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request identity aliases 2", [
    _Case<QuantumNotificationRequest>(
      "id from id",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"id": 101, "title": "S1 title 1", "body": "S1 body 1"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 101);
        expect(value.title, "S1 title 1");
        expect(value.body, "S1 body 1");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from notificationId",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"notificationId": 102, "headline": "S1 title 2", "message": "S1 body 2"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 102);
        expect(value.title, "S1 title 2");
        expect(value.body, "S1 body 2");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from nid",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"nid": 103, "subject": "S1 title 3", "text": "S1 body 3"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 103);
        expect(value.title, "S1 title 3");
        expect(value.body, "S1 body 3");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from title",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S1 direct", "body": "S1 body 4"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S1 direct");
        expect(value.body, "S1 body 4");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from headline",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"headline": "S1 headline", "body": "S1 body 5"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S1 headline");
        expect(value.body, "S1 body 5");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from subject",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"subject": "S1 subject", "body": "S1 body 6"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S1 subject");
        expect(value.body, "S1 body 6");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from body",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S1 title 7", "body": "S1 body 7"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S1 title 7");
        expect(value.body, "S1 body 7");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from message",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S1 title 8", "message": "S1 message 8"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S1 title 8");
        expect(value.body, "S1 message 8");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from text",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S1 title 9", "text": "S1 text 9"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S1 title 9");
        expect(value.body, "S1 text 9");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "empty fallback",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "", "body": "", "priority": "normal"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "");
        expect(value.body, "");
        expect(value.priority, QuantumNotificationPriority.normal);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request identity aliases 3", [
    _Case<QuantumNotificationRequest>(
      "id from id",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"id": 201, "title": "S2 title 1", "body": "S2 body 1"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 201);
        expect(value.title, "S2 title 1");
        expect(value.body, "S2 body 1");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from notificationId",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"notificationId": 202, "headline": "S2 title 2", "message": "S2 body 2"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 202);
        expect(value.title, "S2 title 2");
        expect(value.body, "S2 body 2");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from nid",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"nid": 203, "subject": "S2 title 3", "text": "S2 body 3"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 203);
        expect(value.title, "S2 title 3");
        expect(value.body, "S2 body 3");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from title",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S2 direct", "body": "S2 body 4"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S2 direct");
        expect(value.body, "S2 body 4");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from headline",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"headline": "S2 headline", "body": "S2 body 5"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S2 headline");
        expect(value.body, "S2 body 5");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from subject",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"subject": "S2 subject", "body": "S2 body 6"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S2 subject");
        expect(value.body, "S2 body 6");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from body",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S2 title 7", "body": "S2 body 7"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S2 title 7");
        expect(value.body, "S2 body 7");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from message",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S2 title 8", "message": "S2 message 8"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S2 title 8");
        expect(value.body, "S2 message 8");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from text",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S2 title 9", "text": "S2 text 9"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S2 title 9");
        expect(value.body, "S2 text 9");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "empty fallback",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "", "body": "", "priority": "normal"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "");
        expect(value.body, "");
        expect(value.priority, QuantumNotificationPriority.normal);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request identity aliases 4", [
    _Case<QuantumNotificationRequest>(
      "id from id",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"id": 301, "title": "S3 title 1", "body": "S3 body 1"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 301);
        expect(value.title, "S3 title 1");
        expect(value.body, "S3 body 1");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from notificationId",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"notificationId": 302, "headline": "S3 title 2", "message": "S3 body 2"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 302);
        expect(value.title, "S3 title 2");
        expect(value.body, "S3 body 2");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from nid",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"nid": 303, "subject": "S3 title 3", "text": "S3 body 3"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 303);
        expect(value.title, "S3 title 3");
        expect(value.body, "S3 body 3");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from title",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S3 direct", "body": "S3 body 4"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S3 direct");
        expect(value.body, "S3 body 4");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from headline",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"headline": "S3 headline", "body": "S3 body 5"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S3 headline");
        expect(value.body, "S3 body 5");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from subject",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"subject": "S3 subject", "body": "S3 body 6"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S3 subject");
        expect(value.body, "S3 body 6");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from body",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S3 title 7", "body": "S3 body 7"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S3 title 7");
        expect(value.body, "S3 body 7");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from message",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S3 title 8", "message": "S3 message 8"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S3 title 8");
        expect(value.body, "S3 message 8");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from text",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S3 title 9", "text": "S3 text 9"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S3 title 9");
        expect(value.body, "S3 text 9");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "empty fallback",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "", "body": "", "priority": "normal"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "");
        expect(value.body, "");
        expect(value.priority, QuantumNotificationPriority.normal);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request identity aliases 5", [
    _Case<QuantumNotificationRequest>(
      "id from id",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"id": 401, "title": "S4 title 1", "body": "S4 body 1"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 401);
        expect(value.title, "S4 title 1");
        expect(value.body, "S4 body 1");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from notificationId",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"notificationId": 402, "headline": "S4 title 2", "message": "S4 body 2"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 402);
        expect(value.title, "S4 title 2");
        expect(value.body, "S4 body 2");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "id from nid",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"nid": 403, "subject": "S4 title 3", "text": "S4 body 3"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, 403);
        expect(value.title, "S4 title 3");
        expect(value.body, "S4 body 3");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from title",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S4 direct", "body": "S4 body 4"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S4 direct");
        expect(value.body, "S4 body 4");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from headline",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"headline": "S4 headline", "body": "S4 body 5"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S4 headline");
        expect(value.body, "S4 body 5");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "title from subject",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"subject": "S4 subject", "body": "S4 body 6"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S4 subject");
        expect(value.body, "S4 body 6");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from body",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S4 title 7", "body": "S4 body 7"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S4 title 7");
        expect(value.body, "S4 body 7");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from message",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S4 title 8", "message": "S4 message 8"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S4 title 8");
        expect(value.body, "S4 message 8");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "body from text",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "S4 title 9", "text": "S4 text 9"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "S4 title 9");
        expect(value.body, "S4 text 9");
      },
    ),
    _Case<QuantumNotificationRequest>(
      "empty fallback",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "", "body": "", "priority": "normal"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.title, "");
        expect(value.body, "");
        expect(value.priority, QuantumNotificationPriority.normal);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request flag coercion 1", [
    _Case<QuantumNotificationRequest>(
      "priority min",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "priority": "min"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.min);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority low",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "priority": "low"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.low);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority max",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "priority": "max"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.max);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "persistent from ongoing",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "ongoing": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.persistent, true);
        expect(value.ongoing, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "silent from quiet",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "quiet": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.silent, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "autoCancel explicit false",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "autoCancel": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.autoCancel, false);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "localOnly from local",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "local": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.localOnly, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "onlyAlertOnce from alertOnce",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b", "alertOnce": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.onlyAlertOnce, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showWhen stays true",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F0", "body": "b"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.showWhen, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showTimestamp from visible alias",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"title": "F0", "body": "b", "timestampVisible": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.showTimestamp, false);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request flag coercion 2", [
    _Case<QuantumNotificationRequest>(
      "priority min",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "priority": "min"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.min);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority low",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "priority": "low"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.low);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority max",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "priority": "max"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.max);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "persistent from ongoing",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "ongoing": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.persistent, true);
        expect(value.ongoing, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "silent from quiet",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "quiet": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.silent, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "autoCancel explicit false",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "autoCancel": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.autoCancel, false);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "localOnly from local",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "local": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.localOnly, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "onlyAlertOnce from alertOnce",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b", "alertOnce": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.onlyAlertOnce, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showWhen stays true",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F1", "body": "b"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.showWhen, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showTimestamp from visible alias",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"title": "F1", "body": "b", "timestampVisible": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.showTimestamp, false);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request flag coercion 3", [
    _Case<QuantumNotificationRequest>(
      "priority min",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "priority": "min"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.min);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority low",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "priority": "low"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.low);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority max",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "priority": "max"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.max);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "persistent from ongoing",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "ongoing": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.persistent, true);
        expect(value.ongoing, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "silent from quiet",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "quiet": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.silent, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "autoCancel explicit false",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "autoCancel": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.autoCancel, false);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "localOnly from local",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "local": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.localOnly, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "onlyAlertOnce from alertOnce",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b", "alertOnce": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.onlyAlertOnce, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showWhen stays true",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F2", "body": "b"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.showWhen, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showTimestamp from visible alias",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"title": "F2", "body": "b", "timestampVisible": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.showTimestamp, false);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request flag coercion 4", [
    _Case<QuantumNotificationRequest>(
      "priority min",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "priority": "min"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.min);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority low",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "priority": "low"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.low);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority max",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "priority": "max"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.max);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "persistent from ongoing",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "ongoing": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.persistent, true);
        expect(value.ongoing, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "silent from quiet",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "quiet": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.silent, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "autoCancel explicit false",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "autoCancel": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.autoCancel, false);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "localOnly from local",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "local": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.localOnly, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "onlyAlertOnce from alertOnce",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b", "alertOnce": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.onlyAlertOnce, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showWhen stays true",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F3", "body": "b"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.showWhen, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showTimestamp from visible alias",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"title": "F3", "body": "b", "timestampVisible": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.showTimestamp, false);
      },
    )
  ]);
  _runCases<QuantumNotificationRequest>("Request flag coercion 5", [
    _Case<QuantumNotificationRequest>(
      "priority min",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "priority": "min"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.min);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority low",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "priority": "low"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.low);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "priority max",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "priority": "max"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.priority, QuantumNotificationPriority.max);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "persistent from ongoing",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "ongoing": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.persistent, true);
        expect(value.ongoing, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "silent from quiet",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "quiet": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.silent, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "autoCancel explicit false",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "autoCancel": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.autoCancel, false);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "localOnly from local",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "local": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.localOnly, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "onlyAlertOnce from alertOnce",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b", "alertOnce": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.onlyAlertOnce, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showWhen stays true",
      () => QuantumNotificationRequest.fromMap(
          jsonDecode(r'''{"title": "F4", "body": "b"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.showWhen, true);
      },
    ),
    _Case<QuantumNotificationRequest>(
      "showTimestamp from visible alias",
      () => QuantumNotificationRequest.fromMap(jsonDecode(
              r'''{"title": "F4", "body": "b", "timestampVisible": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.showTimestamp, false);
      },
    )
  ]);
  _runCases<QuantumNotificationAction>("Action alias parsing 1", [
    _Case<QuantumNotificationAction>(
      "actionId alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"actionId": "A0_reply", "label": "A0 Reply"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A0_reply");
        expect(value.label, "A0 Reply");
      },
    ),
    _Case<QuantumNotificationAction>(
      "key alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"key": "A0_open", "title": "A0 Open"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A0_open");
        expect(value.label, "A0 Open");
      },
    ),
    _Case<QuantumNotificationAction>(
      "text alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"text": "A0 Text", "foreground": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.label, "A0 Text");
        expect(value.foreground, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "icon and payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A0_icon", "label": "Icon", "icon": "star", "payload": {"x": 0}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, "A0_icon");
        expect(value.icon, "star");
        expect(value.payload, {"x": 0});
      },
    ),
    _Case<QuantumNotificationAction>(
      "destructive flag",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A0_delete", "label": "Delete", "destructive": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.destructive, true);
      },
    ),
    _Case<QuantumNotificationAction>(
      "launchApp alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A0_launch", "label": "Launch", "launchApp": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.opensApp, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "closeOnTap alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A0_close", "label": "Close", "closeOnTap": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.dismissOnTap, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "ui payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A0_ui", "label": "UI", "ui": {"mode": "grid"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.sdui, {"mode": "grid"});
      },
    ),
    _Case<QuantumNotificationAction>(
      "runtime payload",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"id": "A0_vm", "label": "VM", "runtime": {"x": 1}}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.vm, {"x": 1});
      },
    ),
    _Case<QuantumNotificationAction>(
      "meta payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A0_meta", "label": "Meta", "meta": {"seed": 0}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 0});
      },
    )
  ]);
  _runCases<QuantumNotificationAction>("Action alias parsing 2", [
    _Case<QuantumNotificationAction>(
      "actionId alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"actionId": "A1_reply", "label": "A1 Reply"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A1_reply");
        expect(value.label, "A1 Reply");
      },
    ),
    _Case<QuantumNotificationAction>(
      "key alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"key": "A1_open", "title": "A1 Open"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A1_open");
        expect(value.label, "A1 Open");
      },
    ),
    _Case<QuantumNotificationAction>(
      "text alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"text": "A1 Text", "foreground": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.label, "A1 Text");
        expect(value.foreground, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "icon and payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A1_icon", "label": "Icon", "icon": "star", "payload": {"x": 1}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, "A1_icon");
        expect(value.icon, "star");
        expect(value.payload, {"x": 1});
      },
    ),
    _Case<QuantumNotificationAction>(
      "destructive flag",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A1_delete", "label": "Delete", "destructive": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.destructive, true);
      },
    ),
    _Case<QuantumNotificationAction>(
      "launchApp alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A1_launch", "label": "Launch", "launchApp": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.opensApp, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "closeOnTap alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A1_close", "label": "Close", "closeOnTap": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.dismissOnTap, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "ui payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A1_ui", "label": "UI", "ui": {"mode": "grid"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.sdui, {"mode": "grid"});
      },
    ),
    _Case<QuantumNotificationAction>(
      "runtime payload",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"id": "A1_vm", "label": "VM", "runtime": {"x": 1}}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.vm, {"x": 1});
      },
    ),
    _Case<QuantumNotificationAction>(
      "meta payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A1_meta", "label": "Meta", "meta": {"seed": 1}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 1});
      },
    )
  ]);
  _runCases<QuantumNotificationAction>("Action alias parsing 3", [
    _Case<QuantumNotificationAction>(
      "actionId alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"actionId": "A2_reply", "label": "A2 Reply"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A2_reply");
        expect(value.label, "A2 Reply");
      },
    ),
    _Case<QuantumNotificationAction>(
      "key alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"key": "A2_open", "title": "A2 Open"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A2_open");
        expect(value.label, "A2 Open");
      },
    ),
    _Case<QuantumNotificationAction>(
      "text alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"text": "A2 Text", "foreground": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.label, "A2 Text");
        expect(value.foreground, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "icon and payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A2_icon", "label": "Icon", "icon": "star", "payload": {"x": 2}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, "A2_icon");
        expect(value.icon, "star");
        expect(value.payload, {"x": 2});
      },
    ),
    _Case<QuantumNotificationAction>(
      "destructive flag",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A2_delete", "label": "Delete", "destructive": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.destructive, true);
      },
    ),
    _Case<QuantumNotificationAction>(
      "launchApp alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A2_launch", "label": "Launch", "launchApp": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.opensApp, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "closeOnTap alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A2_close", "label": "Close", "closeOnTap": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.dismissOnTap, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "ui payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A2_ui", "label": "UI", "ui": {"mode": "grid"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.sdui, {"mode": "grid"});
      },
    ),
    _Case<QuantumNotificationAction>(
      "runtime payload",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"id": "A2_vm", "label": "VM", "runtime": {"x": 1}}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.vm, {"x": 1});
      },
    ),
    _Case<QuantumNotificationAction>(
      "meta payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A2_meta", "label": "Meta", "meta": {"seed": 2}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 2});
      },
    )
  ]);
  _runCases<QuantumNotificationAction>("Action alias parsing 4", [
    _Case<QuantumNotificationAction>(
      "actionId alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"actionId": "A3_reply", "label": "A3 Reply"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A3_reply");
        expect(value.label, "A3 Reply");
      },
    ),
    _Case<QuantumNotificationAction>(
      "key alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"key": "A3_open", "title": "A3 Open"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A3_open");
        expect(value.label, "A3 Open");
      },
    ),
    _Case<QuantumNotificationAction>(
      "text alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"text": "A3 Text", "foreground": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.label, "A3 Text");
        expect(value.foreground, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "icon and payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A3_icon", "label": "Icon", "icon": "star", "payload": {"x": 3}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, "A3_icon");
        expect(value.icon, "star");
        expect(value.payload, {"x": 3});
      },
    ),
    _Case<QuantumNotificationAction>(
      "destructive flag",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A3_delete", "label": "Delete", "destructive": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.destructive, true);
      },
    ),
    _Case<QuantumNotificationAction>(
      "launchApp alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A3_launch", "label": "Launch", "launchApp": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.opensApp, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "closeOnTap alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A3_close", "label": "Close", "closeOnTap": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.dismissOnTap, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "ui payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A3_ui", "label": "UI", "ui": {"mode": "grid"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.sdui, {"mode": "grid"});
      },
    ),
    _Case<QuantumNotificationAction>(
      "runtime payload",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"id": "A3_vm", "label": "VM", "runtime": {"x": 1}}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.vm, {"x": 1});
      },
    ),
    _Case<QuantumNotificationAction>(
      "meta payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A3_meta", "label": "Meta", "meta": {"seed": 3}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 3});
      },
    )
  ]);
  _runCases<QuantumNotificationAction>("Action alias parsing 5", [
    _Case<QuantumNotificationAction>(
      "actionId alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"actionId": "A4_reply", "label": "A4 Reply"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A4_reply");
        expect(value.label, "A4 Reply");
      },
    ),
    _Case<QuantumNotificationAction>(
      "key alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"key": "A4_open", "title": "A4 Open"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.id, "A4_open");
        expect(value.label, "A4 Open");
      },
    ),
    _Case<QuantumNotificationAction>(
      "text alias",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"text": "A4 Text", "foreground": false}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.label, "A4 Text");
        expect(value.foreground, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "icon and payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A4_icon", "label": "Icon", "icon": "star", "payload": {"x": 4}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.id, "A4_icon");
        expect(value.icon, "star");
        expect(value.payload, {"x": 4});
      },
    ),
    _Case<QuantumNotificationAction>(
      "destructive flag",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A4_delete", "label": "Delete", "destructive": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.destructive, true);
      },
    ),
    _Case<QuantumNotificationAction>(
      "launchApp alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A4_launch", "label": "Launch", "launchApp": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.opensApp, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "closeOnTap alias",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A4_close", "label": "Close", "closeOnTap": false}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.dismissOnTap, false);
      },
    ),
    _Case<QuantumNotificationAction>(
      "ui payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A4_ui", "label": "UI", "ui": {"mode": "grid"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.sdui, {"mode": "grid"});
      },
    ),
    _Case<QuantumNotificationAction>(
      "runtime payload",
      () => QuantumNotificationAction.fromMap(
          jsonDecode(r'''{"id": "A4_vm", "label": "VM", "runtime": {"x": 1}}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.vm, {"x": 1});
      },
    ),
    _Case<QuantumNotificationAction>(
      "meta payload",
      () => QuantumNotificationAction.fromMap(jsonDecode(
              r'''{"id": "A4_meta", "label": "Meta", "meta": {"seed": 4}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 4});
      },
    )
  ]);
  _runCases<QuantumNotificationSchedule>("Schedule alias parsing 1", [
    _Case<QuantumNotificationSchedule>(
      "at alias when",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"when": "2026-07-26T10:00:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T10:00:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "at alias scheduleAt",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"scheduleAt": "2026-07-26T11:00:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T11:00:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay string seconds",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"after": "1s"}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 1000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay map minutes",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"delay": {"minutes": 1}}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 60000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias interval",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"interval": "2m"}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 120000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias every",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"every": {"seconds": 3}}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 3000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatCount alias count",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"count": 4}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatCount, 4);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "cron exact idle",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"cron": "0 9 * * *", "exact": true, "idle": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.cron, "0 9 * * *");
        expect(value.exact, true);
        expect(value.allowWhileIdle, true);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "metadata survives",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 0}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 0});
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "epoch millis date",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"at": 1710000000000}''') as Map<String, dynamic>),
      (value) {
        expect(value.at != null, true);
      },
    )
  ]);
  _runCases<QuantumNotificationSchedule>("Schedule alias parsing 2", [
    _Case<QuantumNotificationSchedule>(
      "at alias when",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"when": "2026-07-26T10:01:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T10:01:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "at alias scheduleAt",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"scheduleAt": "2026-07-26T11:01:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T11:01:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay string seconds",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"after": "2s"}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 2000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay map minutes",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"delay": {"minutes": 2}}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 120000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias interval",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"interval": "3m"}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 180000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias every",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"every": {"seconds": 4}}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 4000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatCount alias count",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"count": 5}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatCount, 5);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "cron exact idle",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"cron": "0 9 * * *", "exact": true, "idle": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.cron, "0 9 * * *");
        expect(value.exact, true);
        expect(value.allowWhileIdle, true);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "metadata survives",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 1}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 1});
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "epoch millis date",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"at": 1710000000001}''') as Map<String, dynamic>),
      (value) {
        expect(value.at != null, true);
      },
    )
  ]);
  _runCases<QuantumNotificationSchedule>("Schedule alias parsing 3", [
    _Case<QuantumNotificationSchedule>(
      "at alias when",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"when": "2026-07-26T10:02:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T10:02:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "at alias scheduleAt",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"scheduleAt": "2026-07-26T11:02:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T11:02:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay string seconds",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"after": "3s"}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 3000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay map minutes",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"delay": {"minutes": 3}}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 180000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias interval",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"interval": "4m"}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 240000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias every",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"every": {"seconds": 5}}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 5000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatCount alias count",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"count": 6}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatCount, 6);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "cron exact idle",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"cron": "0 9 * * *", "exact": true, "idle": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.cron, "0 9 * * *");
        expect(value.exact, true);
        expect(value.allowWhileIdle, true);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "metadata survives",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 2}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 2});
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "epoch millis date",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"at": 1710000000002}''') as Map<String, dynamic>),
      (value) {
        expect(value.at != null, true);
      },
    )
  ]);
  _runCases<QuantumNotificationSchedule>("Schedule alias parsing 4", [
    _Case<QuantumNotificationSchedule>(
      "at alias when",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"when": "2026-07-26T10:03:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T10:03:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "at alias scheduleAt",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"scheduleAt": "2026-07-26T11:03:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T11:03:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay string seconds",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"after": "4s"}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 4000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay map minutes",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"delay": {"minutes": 4}}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 240000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias interval",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"interval": "5m"}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 300000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias every",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"every": {"seconds": 6}}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 6000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatCount alias count",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"count": 7}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatCount, 7);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "cron exact idle",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"cron": "0 9 * * *", "exact": true, "idle": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.cron, "0 9 * * *");
        expect(value.exact, true);
        expect(value.allowWhileIdle, true);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "metadata survives",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 3}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 3});
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "epoch millis date",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"at": 1710000000003}''') as Map<String, dynamic>),
      (value) {
        expect(value.at != null, true);
      },
    )
  ]);
  _runCases<QuantumNotificationSchedule>("Schedule alias parsing 5", [
    _Case<QuantumNotificationSchedule>(
      "at alias when",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"when": "2026-07-26T10:04:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T10:04:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "at alias scheduleAt",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"scheduleAt": "2026-07-26T11:04:00Z"}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.at?.toIso8601String(), "2026-07-26T11:04:00.000Z");
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay string seconds",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"after": "5s"}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 5000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "delay map minutes",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"delay": {"minutes": 5}}''') as Map<String, dynamic>),
      (value) {
        expect(value.delay?.inMilliseconds, 300000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias interval",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"interval": "6m"}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 360000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatEvery alias every",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"every": {"seconds": 7}}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatEvery?.inMilliseconds, 7000);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "repeatCount alias count",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"count": 8}''') as Map<String, dynamic>),
      (value) {
        expect(value.repeatCount, 8);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "cron exact idle",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"cron": "0 9 * * *", "exact": true, "idle": true}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.cron, "0 9 * * *");
        expect(value.exact, true);
        expect(value.allowWhileIdle, true);
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "metadata survives",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 4}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 4});
      },
    ),
    _Case<QuantumNotificationSchedule>(
      "epoch millis date",
      () => QuantumNotificationSchedule.fromMap(
          jsonDecode(r'''{"at": 1710000000004}''') as Map<String, dynamic>),
      (value) {
        expect(value.at != null, true);
      },
    )
  ]);
  _runCases<QuantumNotificationLayoutSpec>("Layout alias parsing 1", [
    _Case<QuantumNotificationLayoutSpec>(
      "mode grid",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"mode": "grid", "columns": 4, "rows": 2}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 4);
        expect(value.rows, 2);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "type flex",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"type": "flex", "cols": 2, "rows": 3}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "flex");
        expect(value.columns, 2);
        expect(value.rows, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap numeric",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": 8}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 8.0);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap string",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": "12.5"}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 12.5);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "scalar item becomes value map",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [1, "two", true]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "map item survives",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [{"id": "x", "type": "text"}]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 1);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "metadata alias",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"meta": {"seed": 0}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 0});
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "roundtrip surface",
      () => QuantumNotificationLayoutSpec.fromMap(jsonDecode(
              r'''{"mode": "grid", "columns": 1, "rows": 1, "items": [{"id": "a"}]}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 1);
        expect(value.rows, 1);
        expect(value.items.length, 1);
      },
    )
  ]);
  _runCases<QuantumNotificationLayoutSpec>("Layout alias parsing 2", [
    _Case<QuantumNotificationLayoutSpec>(
      "mode grid",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"mode": "grid", "columns": 4, "rows": 2}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 4);
        expect(value.rows, 2);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "type flex",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"type": "flex", "cols": 2, "rows": 3}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "flex");
        expect(value.columns, 2);
        expect(value.rows, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap numeric",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": 8}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 8.0);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap string",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": "12.5"}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 12.5);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "scalar item becomes value map",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [1, "two", true]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "map item survives",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [{"id": "x", "type": "text"}]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 1);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "metadata alias",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"meta": {"seed": 1}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 1});
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "roundtrip surface",
      () => QuantumNotificationLayoutSpec.fromMap(jsonDecode(
              r'''{"mode": "grid", "columns": 1, "rows": 1, "items": [{"id": "a"}]}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 1);
        expect(value.rows, 1);
        expect(value.items.length, 1);
      },
    )
  ]);
  _runCases<QuantumNotificationLayoutSpec>("Layout alias parsing 3", [
    _Case<QuantumNotificationLayoutSpec>(
      "mode grid",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"mode": "grid", "columns": 4, "rows": 2}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 4);
        expect(value.rows, 2);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "type flex",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"type": "flex", "cols": 2, "rows": 3}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "flex");
        expect(value.columns, 2);
        expect(value.rows, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap numeric",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": 8}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 8.0);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap string",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": "12.5"}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 12.5);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "scalar item becomes value map",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [1, "two", true]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "map item survives",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [{"id": "x", "type": "text"}]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 1);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "metadata alias",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"meta": {"seed": 2}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 2});
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "roundtrip surface",
      () => QuantumNotificationLayoutSpec.fromMap(jsonDecode(
              r'''{"mode": "grid", "columns": 1, "rows": 1, "items": [{"id": "a"}]}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 1);
        expect(value.rows, 1);
        expect(value.items.length, 1);
      },
    )
  ]);
  _runCases<QuantumNotificationLayoutSpec>("Layout alias parsing 4", [
    _Case<QuantumNotificationLayoutSpec>(
      "mode grid",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"mode": "grid", "columns": 4, "rows": 2}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 4);
        expect(value.rows, 2);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "type flex",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"type": "flex", "cols": 2, "rows": 3}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "flex");
        expect(value.columns, 2);
        expect(value.rows, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap numeric",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": 8}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 8.0);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap string",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": "12.5"}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 12.5);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "scalar item becomes value map",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [1, "two", true]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "map item survives",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [{"id": "x", "type": "text"}]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 1);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "metadata alias",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"meta": {"seed": 3}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 3});
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "roundtrip surface",
      () => QuantumNotificationLayoutSpec.fromMap(jsonDecode(
              r'''{"mode": "grid", "columns": 1, "rows": 1, "items": [{"id": "a"}]}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 1);
        expect(value.rows, 1);
        expect(value.items.length, 1);
      },
    )
  ]);
  _runCases<QuantumNotificationLayoutSpec>("Layout alias parsing 5", [
    _Case<QuantumNotificationLayoutSpec>(
      "mode grid",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"mode": "grid", "columns": 4, "rows": 2}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 4);
        expect(value.rows, 2);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "type flex",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"type": "flex", "cols": 2, "rows": 3}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.mode, "flex");
        expect(value.columns, 2);
        expect(value.rows, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap numeric",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": 8}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 8.0);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "gap string",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"gap": "12.5"}''') as Map<String, dynamic>),
      (value) {
        expect(value.gap, 12.5);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "scalar item becomes value map",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [1, "two", true]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 3);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "map item survives",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"items": [{"id": "x", "type": "text"}]}''')
              as Map<String, dynamic>),
      (value) {
        expect(value.items.length, 1);
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "metadata alias",
      () => QuantumNotificationLayoutSpec.fromMap(
          jsonDecode(r'''{"meta": {"seed": 4}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 4});
      },
    ),
    _Case<QuantumNotificationLayoutSpec>(
      "roundtrip surface",
      () => QuantumNotificationLayoutSpec.fromMap(jsonDecode(
              r'''{"mode": "grid", "columns": 1, "rows": 1, "items": [{"id": "a"}]}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.mode, "grid");
        expect(value.columns, 1);
        expect(value.rows, 1);
        expect(value.items.length, 1);
      },
    )
  ]);
  _runCases<QuantumNotificationProgressSpec>("Progress alias parsing 1", [
    _Case<QuantumNotificationProgressSpec>(
      "value numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": 0.5}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 0);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "value string",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": "1"}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 1);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "max numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"max": 250}''') as Map<String, dynamic>),
      (value) {
        expect(value.max, 250);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "indeterminate spinner",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"spinner": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.indeterminate, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "live update",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"liveUpdate": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.live, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "show timer",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"timer": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.showTimer, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "label retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"label": "0 files"}''') as Map<String, dynamic>),
      (value) {
        expect(value.label, "0 files");
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "metadata retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 0}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 0});
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "full roundtrip",
      () => QuantumNotificationProgressSpec.fromMap(jsonDecode(
              r'''{"value": 33, "max": 55, "indeterminate": false, "live": true, "showTimer": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.value, 33);
        expect(value.max, 55);
        expect(value.live, true);
        expect(value.showTimer, true);
      },
    )
  ]);
  _runCases<QuantumNotificationProgressSpec>("Progress alias parsing 2", [
    _Case<QuantumNotificationProgressSpec>(
      "value numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": 1.5}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 1);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "value string",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": "2"}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 2);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "max numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"max": 250}''') as Map<String, dynamic>),
      (value) {
        expect(value.max, 250);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "indeterminate spinner",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"spinner": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.indeterminate, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "live update",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"liveUpdate": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.live, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "show timer",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"timer": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.showTimer, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "label retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"label": "1 files"}''') as Map<String, dynamic>),
      (value) {
        expect(value.label, "1 files");
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "metadata retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 1}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 1});
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "full roundtrip",
      () => QuantumNotificationProgressSpec.fromMap(jsonDecode(
              r'''{"value": 33, "max": 55, "indeterminate": false, "live": true, "showTimer": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.value, 33);
        expect(value.max, 55);
        expect(value.live, true);
        expect(value.showTimer, true);
      },
    )
  ]);
  _runCases<QuantumNotificationProgressSpec>("Progress alias parsing 3", [
    _Case<QuantumNotificationProgressSpec>(
      "value numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": 2.5}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 2);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "value string",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": "3"}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 3);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "max numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"max": 250}''') as Map<String, dynamic>),
      (value) {
        expect(value.max, 250);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "indeterminate spinner",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"spinner": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.indeterminate, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "live update",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"liveUpdate": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.live, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "show timer",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"timer": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.showTimer, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "label retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"label": "2 files"}''') as Map<String, dynamic>),
      (value) {
        expect(value.label, "2 files");
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "metadata retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 2}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 2});
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "full roundtrip",
      () => QuantumNotificationProgressSpec.fromMap(jsonDecode(
              r'''{"value": 33, "max": 55, "indeterminate": false, "live": true, "showTimer": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.value, 33);
        expect(value.max, 55);
        expect(value.live, true);
        expect(value.showTimer, true);
      },
    )
  ]);
  _runCases<QuantumNotificationProgressSpec>("Progress alias parsing 4", [
    _Case<QuantumNotificationProgressSpec>(
      "value numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": 3.5}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 3);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "value string",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": "4"}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 4);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "max numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"max": 250}''') as Map<String, dynamic>),
      (value) {
        expect(value.max, 250);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "indeterminate spinner",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"spinner": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.indeterminate, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "live update",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"liveUpdate": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.live, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "show timer",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"timer": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.showTimer, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "label retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"label": "3 files"}''') as Map<String, dynamic>),
      (value) {
        expect(value.label, "3 files");
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "metadata retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 3}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 3});
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "full roundtrip",
      () => QuantumNotificationProgressSpec.fromMap(jsonDecode(
              r'''{"value": 33, "max": 55, "indeterminate": false, "live": true, "showTimer": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.value, 33);
        expect(value.max, 55);
        expect(value.live, true);
        expect(value.showTimer, true);
      },
    )
  ]);
  _runCases<QuantumNotificationProgressSpec>("Progress alias parsing 5", [
    _Case<QuantumNotificationProgressSpec>(
      "value numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": 4.5}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 4);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "value string",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"value": "5"}''') as Map<String, dynamic>),
      (value) {
        expect(value.value, 5);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "max numeric",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"max": 250}''') as Map<String, dynamic>),
      (value) {
        expect(value.max, 250);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "indeterminate spinner",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"spinner": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.indeterminate, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "live update",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"liveUpdate": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.live, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "show timer",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"timer": true}''') as Map<String, dynamic>),
      (value) {
        expect(value.showTimer, true);
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "label retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"label": "4 files"}''') as Map<String, dynamic>),
      (value) {
        expect(value.label, "4 files");
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "metadata retained",
      () => QuantumNotificationProgressSpec.fromMap(
          jsonDecode(r'''{"metadata": {"seed": 4}}''') as Map<String, dynamic>),
      (value) {
        expect(value.metadata, {"seed": 4});
      },
    ),
    _Case<QuantumNotificationProgressSpec>(
      "full roundtrip",
      () => QuantumNotificationProgressSpec.fromMap(jsonDecode(
              r'''{"value": 33, "max": 55, "indeterminate": false, "live": true, "showTimer": true}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.value, 33);
        expect(value.max, 55);
        expect(value.live, true);
        expect(value.showTimer, true);
      },
    )
  ]);
  _runCases<QuantumNotificationTemplate>("Template record parsing 1", [
    _Case<QuantumNotificationTemplate>(
      "key alias name",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"name": "rec_0", "request": {"title": "T0", "body": "B0"}, "created": "2026-07-26T13:00:00Z", "updated": "2026-07-26T13:00:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "rec_0");
        expect(value.request.title, "T0");
        expect(value.request.body, "B0");
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:00:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:00:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "key alias id",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"id": "id_0", "spec": {"title": "Ti0", "body": "Bi0"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "id_0");
        expect(value.request.title, "Ti0");
        expect(value.request.body, "Bi0");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "request alias notification",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "n_0", "notification": {"title": "X0", "body": "Y0"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "n_0");
        expect(value.request.title, "X0");
        expect(value.request.body, "Y0");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "copyWith request",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "c_0", "request": {"title": "T", "body": "B"}, "createdAt": "2026-07-26T13:00:00Z", "updatedAt": "2026-07-26T13:00:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:00:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:00:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "roundtrip structure",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "r_0", "request": {"title": "R", "body": "S"}, "createdAt": "2026-07-26T13:00:00Z", "updatedAt": "2026-07-26T13:00:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "r_0");
        expect(value.request.title, "R");
        expect(value.request.body, "S");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "toMap request title",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "t_0", "request": {"title": "Z", "body": "Q"}, "createdAt": "2026-07-26T13:00:00Z", "updatedAt": "2026-07-26T13:00:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.request.title, "Z");
        expect(value.request.body, "Q");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing from created",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "d_0", "request": {"title": "A", "body": "B"}, "created": "2026-07-26T13:00:00Z", "updated": "2026-07-26T13:00:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:00:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:00:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing epoch",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "e_0", "request": {"title": "E", "body": "F"}, "created": 1710000000000, "updated": 1710000001000}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt != null, true);
        expect(value.updatedAt != null, true);
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "fallback key defaults",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"request": {"title": "D", "body": "E"}, "createdAt": "2026-07-26T13:00:00Z", "updatedAt": "2026-07-26T13:00:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "template");
      },
    )
  ]);
  _runCases<QuantumNotificationTemplate>("Template record parsing 2", [
    _Case<QuantumNotificationTemplate>(
      "key alias name",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"name": "rec_1", "request": {"title": "T1", "body": "B1"}, "created": "2026-07-26T13:01:00Z", "updated": "2026-07-26T13:01:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "rec_1");
        expect(value.request.title, "T1");
        expect(value.request.body, "B1");
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:01:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:01:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "key alias id",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"id": "id_1", "spec": {"title": "Ti1", "body": "Bi1"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "id_1");
        expect(value.request.title, "Ti1");
        expect(value.request.body, "Bi1");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "request alias notification",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "n_1", "notification": {"title": "X1", "body": "Y1"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "n_1");
        expect(value.request.title, "X1");
        expect(value.request.body, "Y1");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "copyWith request",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "c_1", "request": {"title": "T", "body": "B"}, "createdAt": "2026-07-26T13:01:00Z", "updatedAt": "2026-07-26T13:01:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:01:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:01:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "roundtrip structure",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "r_1", "request": {"title": "R", "body": "S"}, "createdAt": "2026-07-26T13:01:00Z", "updatedAt": "2026-07-26T13:01:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "r_1");
        expect(value.request.title, "R");
        expect(value.request.body, "S");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "toMap request title",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "t_1", "request": {"title": "Z", "body": "Q"}, "createdAt": "2026-07-26T13:01:00Z", "updatedAt": "2026-07-26T13:01:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.request.title, "Z");
        expect(value.request.body, "Q");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing from created",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "d_1", "request": {"title": "A", "body": "B"}, "created": "2026-07-26T13:01:00Z", "updated": "2026-07-26T13:01:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:01:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:01:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing epoch",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "e_1", "request": {"title": "E", "body": "F"}, "created": 1710000000000, "updated": 1710000001000}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt != null, true);
        expect(value.updatedAt != null, true);
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "fallback key defaults",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"request": {"title": "D", "body": "E"}, "createdAt": "2026-07-26T13:01:00Z", "updatedAt": "2026-07-26T13:01:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "template");
      },
    )
  ]);
  _runCases<QuantumNotificationTemplate>("Template record parsing 3", [
    _Case<QuantumNotificationTemplate>(
      "key alias name",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"name": "rec_2", "request": {"title": "T2", "body": "B2"}, "created": "2026-07-26T13:02:00Z", "updated": "2026-07-26T13:02:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "rec_2");
        expect(value.request.title, "T2");
        expect(value.request.body, "B2");
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:02:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:02:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "key alias id",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"id": "id_2", "spec": {"title": "Ti2", "body": "Bi2"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "id_2");
        expect(value.request.title, "Ti2");
        expect(value.request.body, "Bi2");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "request alias notification",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "n_2", "notification": {"title": "X2", "body": "Y2"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "n_2");
        expect(value.request.title, "X2");
        expect(value.request.body, "Y2");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "copyWith request",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "c_2", "request": {"title": "T", "body": "B"}, "createdAt": "2026-07-26T13:02:00Z", "updatedAt": "2026-07-26T13:02:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:02:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:02:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "roundtrip structure",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "r_2", "request": {"title": "R", "body": "S"}, "createdAt": "2026-07-26T13:02:00Z", "updatedAt": "2026-07-26T13:02:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "r_2");
        expect(value.request.title, "R");
        expect(value.request.body, "S");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "toMap request title",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "t_2", "request": {"title": "Z", "body": "Q"}, "createdAt": "2026-07-26T13:02:00Z", "updatedAt": "2026-07-26T13:02:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.request.title, "Z");
        expect(value.request.body, "Q");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing from created",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "d_2", "request": {"title": "A", "body": "B"}, "created": "2026-07-26T13:02:00Z", "updated": "2026-07-26T13:02:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:02:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:02:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing epoch",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "e_2", "request": {"title": "E", "body": "F"}, "created": 1710000000000, "updated": 1710000001000}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt != null, true);
        expect(value.updatedAt != null, true);
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "fallback key defaults",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"request": {"title": "D", "body": "E"}, "createdAt": "2026-07-26T13:02:00Z", "updatedAt": "2026-07-26T13:02:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "template");
      },
    )
  ]);
  _runCases<QuantumNotificationTemplate>("Template record parsing 4", [
    _Case<QuantumNotificationTemplate>(
      "key alias name",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"name": "rec_3", "request": {"title": "T3", "body": "B3"}, "created": "2026-07-26T13:03:00Z", "updated": "2026-07-26T13:03:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "rec_3");
        expect(value.request.title, "T3");
        expect(value.request.body, "B3");
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:03:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:03:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "key alias id",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"id": "id_3", "spec": {"title": "Ti3", "body": "Bi3"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "id_3");
        expect(value.request.title, "Ti3");
        expect(value.request.body, "Bi3");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "request alias notification",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "n_3", "notification": {"title": "X3", "body": "Y3"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "n_3");
        expect(value.request.title, "X3");
        expect(value.request.body, "Y3");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "copyWith request",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "c_3", "request": {"title": "T", "body": "B"}, "createdAt": "2026-07-26T13:03:00Z", "updatedAt": "2026-07-26T13:03:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:03:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:03:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "roundtrip structure",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "r_3", "request": {"title": "R", "body": "S"}, "createdAt": "2026-07-26T13:03:00Z", "updatedAt": "2026-07-26T13:03:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "r_3");
        expect(value.request.title, "R");
        expect(value.request.body, "S");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "toMap request title",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "t_3", "request": {"title": "Z", "body": "Q"}, "createdAt": "2026-07-26T13:03:00Z", "updatedAt": "2026-07-26T13:03:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.request.title, "Z");
        expect(value.request.body, "Q");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing from created",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "d_3", "request": {"title": "A", "body": "B"}, "created": "2026-07-26T13:03:00Z", "updated": "2026-07-26T13:03:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:03:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:03:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing epoch",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "e_3", "request": {"title": "E", "body": "F"}, "created": 1710000000000, "updated": 1710000001000}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt != null, true);
        expect(value.updatedAt != null, true);
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "fallback key defaults",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"request": {"title": "D", "body": "E"}, "createdAt": "2026-07-26T13:03:00Z", "updatedAt": "2026-07-26T13:03:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "template");
      },
    )
  ]);
  _runCases<QuantumNotificationTemplate>("Template record parsing 5", [
    _Case<QuantumNotificationTemplate>(
      "key alias name",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"name": "rec_4", "request": {"title": "T4", "body": "B4"}, "created": "2026-07-26T13:04:00Z", "updated": "2026-07-26T13:04:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "rec_4");
        expect(value.request.title, "T4");
        expect(value.request.body, "B4");
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:04:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:04:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "key alias id",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"id": "id_4", "spec": {"title": "Ti4", "body": "Bi4"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "id_4");
        expect(value.request.title, "Ti4");
        expect(value.request.body, "Bi4");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "request alias notification",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "n_4", "notification": {"title": "X4", "body": "Y4"}}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "n_4");
        expect(value.request.title, "X4");
        expect(value.request.body, "Y4");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "copyWith request",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "c_4", "request": {"title": "T", "body": "B"}, "createdAt": "2026-07-26T13:04:00Z", "updatedAt": "2026-07-26T13:04:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:04:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:04:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "roundtrip structure",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "r_4", "request": {"title": "R", "body": "S"}, "createdAt": "2026-07-26T13:04:00Z", "updatedAt": "2026-07-26T13:04:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "r_4");
        expect(value.request.title, "R");
        expect(value.request.body, "S");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "toMap request title",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "t_4", "request": {"title": "Z", "body": "Q"}, "createdAt": "2026-07-26T13:04:00Z", "updatedAt": "2026-07-26T13:04:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.request.title, "Z");
        expect(value.request.body, "Q");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing from created",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "d_4", "request": {"title": "A", "body": "B"}, "created": "2026-07-26T13:04:00Z", "updated": "2026-07-26T13:04:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt?.toIso8601String(), "2026-07-26T13:04:00.000Z");
        expect(value.updatedAt?.toIso8601String(), "2026-07-26T13:04:10.000Z");
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "date parsing epoch",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"key": "e_4", "request": {"title": "E", "body": "F"}, "created": 1710000000000, "updated": 1710000001000}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.createdAt != null, true);
        expect(value.updatedAt != null, true);
      },
    ),
    _Case<QuantumNotificationTemplate>(
      "fallback key defaults",
      () => QuantumNotificationTemplate.fromMap(jsonDecode(
              r'''{"request": {"title": "D", "body": "E"}, "createdAt": "2026-07-26T13:04:00Z", "updatedAt": "2026-07-26T13:04:10Z"}''')
          as Map<String, dynamic>),
      (value) {
        expect(value.key, "template");
      },
    )
  ]);
}
