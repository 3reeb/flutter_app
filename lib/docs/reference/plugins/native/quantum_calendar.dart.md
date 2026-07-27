# `src/plugins/native/quantum_calendar.dart`

## What this file is
A native capability plugin wrapper. Each file exposes one device-level capability such as camera, calendar, location, microphone, phone, contacts, files, notifications, or photos.

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../platform/quantum_native_bridge.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.

## Top-level declarations
- Line 9: `class CalendarEvent {` — Defines the `CalendarEvent` type and its fields, methods, and lifecycle.
- Line 43: `class DateRange {` — Defines the `DateRange` type and its fields, methods, and lifecycle.
- Line 59: `class _DateRangeEventListCodec extends QLChannelCodec<DateRange, List<CalendarEvent>> {` — Defines the `_DateRangeEventListCodec` type and its fields, methods, and lifecycle.
- Line 68: `class _GetEventsBridge extends QLMethodBridge<DateRange, List<CalendarEvent>> {` — Defines the `_GetEventsBridge` type and its fields, methods, and lifecycle.
- Line 73: `class _AddEventCodec extends QLChannelCodec<CalendarEvent, bool> {` — Defines the `_AddEventCodec` type and its fields, methods, and lifecycle.
- Line 79: `class _AddEventBridge extends QLMethodBridge<CalendarEvent, bool> {` — Defines the `_AddEventBridge` type and its fields, methods, and lifecycle.
- Line 88: `class QuantumCalendar {` — Defines the `QuantumCalendar` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 34: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.
- Line 49: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.

## How it works
Each native plugin wrapper isolates one device capability behind a small Dart-facing API, typically by forwarding requests to a platform channel or native bridge.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 108 lines in the source file.
- 7 top-level declarations detected by static analysis.
- 2 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
