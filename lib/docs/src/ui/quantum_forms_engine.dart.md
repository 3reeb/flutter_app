# `src/ui/quantum_forms_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM FORMS ENGINE v3.0 - OMEGA PRODUCTION BUILD

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Internal framework dependency: `../foundation/quantum_core.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 14: `typedef QLDataMiddleware<T> = T Function(T incoming, T current);` — Declares the `QLDataMiddleware` type alias so callback signatures stay readable and consistent.
- Line 16: `class QLChangeEvent<T> {` — Defines the `QLChangeEvent<T>` type and its fields, methods, and lifecycle.
- Line 44: `class _QLObserver {` — Defines the `_QLObserver` type and its fields, methods, and lifecycle.
- Line 50: `abstract class QLDataNode<T> implements QLDisposable {` — Defines the abstract `QLDataNode<T>` contract used by implementations elsewhere in the framework.
- Line 393: `class QLGraphController {` — Defines the `QLGraphController` type and its fields, methods, and lifecycle.
- Line 670: `class QLFormController extends QLGraphController {` — Defines the `QLFormController` type and its fields, methods, and lifecycle.
- Line 717: `typedef QLFieldBuilder = void Function(String basePath, QLFormController form);` — Declares the `QLFieldBuilder` type alias so callback signatures stay readable and consistent.
- Line 718: `typedef QLFieldSchema = QLFieldBuilder;` — Declares the `QLFieldSchema` type alias so callback signatures stay readable and consistent.
- Line 720: `abstract final class QLValidators {` — Provides a static namespace of constants and helper methods under `QLValidators`.
- Line 736: `abstract final class QLTransforms {` — Provides a static namespace of constants and helper methods under `QLTransforms`.
- Line 741: `abstract class QLFieldController<T> extends QLDataNode<T> {` — Defines the abstract `QLFieldController<T>` contract used by implementations elsewhere in the framework.
- Line 834: `class QLTextController extends QLFieldController<String> {` — Defines the `QLTextController` type and its fields, methods, and lifecycle.
- Line 883: `class QLTextAreaController extends QLTextController {` — Defines the `QLTextAreaController` type and its fields, methods, and lifecycle.
- Line 923: `class QLNumberController extends QLFieldController<double> {` — Defines the `QLNumberController` type and its fields, methods, and lifecycle.
- Line 939: `class QLBoolController extends QLFieldController<bool> {` — Defines the `QLBoolController` type and its fields, methods, and lifecycle.
- Line 957: `class QLDateController extends QLFieldController<DateTime?> {` — Defines the `QLDateController` type and its fields, methods, and lifecycle.
- Line 977: `T _normalizeEnumInitial<T>(T initialValue, List<T> allowedValues) {` — Part of the public or internal API; it is named `_normalizeEnumInitial<T>` and contributes to this file’s behavior.
- Line 983: `List<T> _sanitizeEnumItems<T>(Iterable<T> items, List<T> allowedValues) {` — Part of the public or internal API; it is named `_sanitizeEnumItems<T>` and contributes to this file’s behavior.
- …and 14 more top-level declarations.

## Important members and helpers
- Line 29: `Map<String, dynamic> doc({bool raw = false}) => graph.extractGraph(raw: raw);` — Part of the public or internal API; it is named `doc` and contributes to this file’s behavior.
- Line 31: `dynamic sibling(String relativePath) {` — Part of the public or internal API; it is named `sibling` and contributes to this file’s behavior.
- Line 37: `void setSibling(String relativePath, dynamic value) {` — Part of the public or internal API; it is named `setSibling` and contributes to this file’s behavior.
- Line 113: `void mutate(T newValue, {bool shouldValidate = true}) {` — Part of the public or internal API; it is named `mutate` and contributes to this file’s behavior.
- Line 153: `void mutateFast(T newValue, {bool applyMiddleware = true}) {` — Part of the public or internal API; it is named `mutateFast` and contributes to this file’s behavior.
- Line 187: `void setValue(T newValue, {bool shouldValidate = true}) =>` — Part of the public or internal API; it is named `setValue` and contributes to this file’s behavior.
- Line 190: `void setSilently(T newValue, {bool keepDirty = true}) {` — Part of the public or internal API; it is named `setSilently` and contributes to this file’s behavior.
- Line 200: `void bindStream(Stream<T> stream, {bool validateOnStream = false}) {` — Binds this object to another signal, stream, or controller.
- Line 231: `void unbindStream() {` — Part of the public or internal API; it is named `unbindStream` and contributes to this file’s behavior.
- Line 237: `void sleep() {` — Part of the public or internal API; it is named `sleep` and contributes to this file’s behavior.
- Line 244: `void wake() {` — Part of the public or internal API; it is named `wake` and contributes to this file’s behavior.
- Line 251: `void addState(int flag) {` — Adds a child item, event, route, or data chunk to the current collection.
- Line 259: `void removeState(int flag) {` — Removes a previously registered item or association.
- Line 267: `bool hasState(int flag) => (stateFlags.value & flag) == flag;` — Part of the public or internal API; it is named `hasState` and contributes to this file’s behavior.
- Line 269: `void updateMeta(String key, dynamic value, {bool notify = true}) {` — Updates internal state or a derived representation.
- Line 276: `void removeMeta(String key, {bool notify = true}) {` — Removes a previously registered item or association.
- Line 284: `void hide({bool notify = true}) =>` — Part of the public or internal API; it is named `hide` and contributes to this file’s behavior.
- Line 286: `void show({bool notify = true}) => removeMeta('_ql_hidden', notify: notify);` — Part of the public or internal API; it is named `show` and contributes to this file’s behavior.
- Line 288: `void disable({bool notify = true}) {` — Part of the public or internal API; it is named `disable` and contributes to this file’s behavior.
- Line 293: `void enable({bool notify = true}) {` — Part of the public or internal API; it is named `enable` and contributes to this file’s behavior.
- Line 298: `void setReadOnly(bool value) => value` — Part of the public or internal API; it is named `setReadOnly` and contributes to this file’s behavior.
- Line 302: `Future<void> validate() async {` — Part of the public or internal API; it is named `validate` and contributes to this file’s behavior.
- Line 357: `void clearErrors() => _setErrors(const [], notifyGraph: true);` — Part of the public or internal API; it is named `clearErrors` and contributes to this file’s behavior.
- Line 359: `void refresh() {` — Part of the public or internal API; it is named `refresh` and contributes to this file’s behavior.
- …and 105 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.

## File size
- 2083 lines in the source file.
- 32 top-level declarations detected by static analysis.
- 129 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
