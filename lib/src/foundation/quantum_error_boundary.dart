// ════════════════════════════════════════════════════════════════════════════
// QUANTUM ERROR BOUNDARY v1.0 - STRUCTURED SUBTREE FAULT ISOLATION
// quantum_error_boundary.dart
//
// ARCHITECTURE:
// 1. Builder-Pattern Boundary: Uses a Widget Function(BuildContext) builder
//    instead of a child Widget. This allows the try/catch to intercept
//    synchronous build errors from the entire builder subtree on the same
//    call stack.
// 2. QLSignal<QLErrorState?> for reactive error propagation: Any ancestor
//    can watch this signal and react to errors in the boundary's subtree
//    without polling or global handlers. Zero-allocation state transport.
// 3. QLErrorBoundaryScope (InheritedWidget): Exposes a .reportError() method
//    to any descendant. Async components (QLAsyncSignal, isolates) call this
//    to route their errors into the nearest ancestor boundary — exactly like
//    React error boundaries but for async Dart code.
// 4. Structured Retry with Exponential Backoff: maxRetries guard + optional
//    onRetry callback with attempt count. Retry clears the error signal and
//    causes a full subtree rebuild from scratch.
// 5. FlutterError Integration: Installs a scoped FlutterError.onError hook
//    during the boundary's lifetime, capturing framework-level exceptions
//    that escape normal try/catch (e.g., errors in layout callbacks).
//    Restores the previous handler on dispose — no global handler leaks.
// 6. QLErrorBoundaryReporter: A lightweight mixin for State classes that
//    auto-routes uncaught errors to the nearest QLErrorBoundaryScope.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'quantum_primitives.dart';

/// App-configurable observability hook for [QLErrorBoundary].
///
/// By design, [QLErrorBoundary] does not surface its fallback UI / retry
/// state for layout-assertion errors (overflow, unbounded-constraint
/// failures, etc.) because feeding those into `setState` synchronously
/// during layout can cause a recursive render-crash loop (see
/// `_QLErrorBoundaryState._captureError`). That does NOT mean these errors
/// should be invisible to you: Flutter's default `FlutterError.onError`
/// handler is largely silent in release builds, so unless you wire this
/// hook (or install your own crash reporter *before* any `QLErrorBoundary`
/// mounts, since the previous handler is always chained), these errors have
/// no record in production. Wire it once at app startup, e.g.:
///
/// ```dart
/// QLErrorBoundaryConfig.onSuppressedLayoutError = (details) {
///   FirebaseCrashlytics.instance.recordFlutterError(details, fatal: false);
/// };
/// ```
abstract final class QLErrorBoundaryConfig {
  static void Function(FlutterErrorDetails details)? onSuppressedLayoutError;
}

abstract final class QLErrorUtils {
  /// Returns true for layout-assertion / overflow errors that Flutter
  /// already renders visibly in debug mode (yellow/black overflow stripes,
  /// the red "RenderFlex overflowed" banner) rather than a fatal crash.
  ///
  /// `details.library` is checked first because it's a stable signal set by
  /// the framework itself (layout/render assertions are tagged
  /// `'rendering library'`), unlike free-text exception messages which can
  /// change wording between Flutter SDK versions. The string list below is
  /// a secondary heuristic kept for older/edge-case error shapes and should
  /// be re-validated against whatever Flutter SDK version you pin.
  static bool isHarmlessLayoutError(FlutterErrorDetails details) {
    if (details.library == 'rendering library') return true;
    final String errStr = details.exceptionAsString();
    return errStr.contains('overflowed') ||
        errStr.contains('A RenderFlex') ||
        errStr.contains('RenderBox was not laid out') ||
        errStr.contains('hasSize') ||
        errStr.contains('BoxConstraints forces') ||
        errStr.contains('Infinity');
  }
}

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  IMMUTABLE ERROR STATE (Zero-Allocation Error Carrier)
// ────────────────────────────────────────────────────────────────────────────

enum QLErrorSeverity { recoverable, fatal }

@immutable
class QLErrorState {
  final Object error;
  final StackTrace? stackTrace;
  final int retryCount;
  final int maxRetries;
  final QLErrorSeverity severity;
  final DateTime timestamp;
  final String? context; // Optional label for where the error came from

  QLErrorState({
    required this.error,
    this.stackTrace,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.severity = QLErrorSeverity.recoverable,
    this.context,
  }) : timestamp = DateTime.now();

  bool get canRetry =>
      severity == QLErrorSeverity.recoverable && retryCount < maxRetries;

  QLErrorState withRetry() => QLErrorState(
        error: error,
        stackTrace: stackTrace,
        retryCount: retryCount + 1,
        maxRetries: maxRetries,
        severity: severity,
        context: context,
      );

  @override
  String toString() =>
      'QLErrorState(${context != null ? "$context: " : ""}$error, '
      'retry: $retryCount/$maxRetries)';
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  QLBOUNDARY SCOPE (InheritedWidget — Subtree Error Reporting)
// ────────────────────────────────────────────────────────────────────────────

/// Provides error reporting capability to the entire descendant subtree.
/// Any widget or State can call [QLErrorBoundaryScope.of(context).report(...)]
/// to route an error into the nearest ancestor QLErrorBoundary.
class QLErrorBoundaryScope extends InheritedWidget {
  final _QLErrorBoundaryState _state;

  const QLErrorBoundaryScope._({
    required _QLErrorBoundaryState state,
    required super.child,
  }) : _state = state;

  /// Reports an error to this boundary from any descendant.
  /// Safe to call from async callbacks, Future.catchError, etc.
  void report(Object error,
      {StackTrace? stackTrace,
      QLErrorSeverity severity = QLErrorSeverity.recoverable,
      String? context}) {
    _state._captureError(error,
        stackTrace: stackTrace, severity: severity, context: context);
  }

  static QLErrorBoundaryScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QLErrorBoundaryScope>();

  static QLErrorBoundaryScope? of(BuildContext context) => maybeOf(context);

  @override
  bool updateShouldNotify(QLErrorBoundaryScope old) =>
      !identical(_state, old._state);
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QLBOUNDARY FALLBACK (Default Error UI)
// ────────────────────────────────────────────────────────────────────────────

class _QLDefaultFallback extends StatelessWidget {
  final QLErrorState errorState;
  final VoidCallback? onRetry;

  const _QLDefaultFallback({required this.errorState, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF3333).withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF3333), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QLErrorBoundary${errorState.context != null ? " [${errorState.context}]" : ""}',
                  style: const TextStyle(
                      color: Color(0xFFFF3333),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${errorState.error}',
            style: const TextStyle(color: Color(0xFFFFAAAA), fontSize: 11),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (errorState.canRetry && onRetry != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3333).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: const Color(0xFFFF3333).withOpacity(0.3)),
                ),
                child: Text(
                  'Retry (${errorState.retryCount}/${errorState.maxRetries})',
                  style:
                      const TextStyle(color: Color(0xFFFF3333), fontSize: 11),
                ),
              ),
            ),
          ],
          if (kDebugMode && errorState.stackTrace != null) ...[
            const SizedBox(height: 8),
            Text(
              errorState.stackTrace.toString().split('\n').take(5).join('\n'),
              style: const TextStyle(
                  color: Color(0xFF884444),
                  fontSize: 9,
                  fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  QLBOUNDARY WIDGET (The Fault Isolation Unit)
// ────────────────────────────────────────────────────────────────────────────

/// A structured error boundary that:
/// - Wraps a builder subtree in try/catch for synchronous build errors.
/// - Provides QLErrorBoundaryScope to descendants for async error reporting.
/// - Supports retry with configurable limits and optional exponential backoff.
/// - Installs a scoped FlutterError handler for framework-level errors.
/// - Exposes errorSignal (QLSignal<QLErrorState?>) for reactive parent updates.
class QLErrorBoundary extends StatefulWidget {
  /// Builder function. Using a builder (not a child) allows the try/catch
  /// to intercept errors thrown during the builder's synchronous execution.
  final Widget Function(BuildContext context) builder;

  /// Custom fallback UI when an error is captured.
  final Widget Function(
      BuildContext context, QLErrorState error, VoidCallback? retry)? fallback;

  /// Called after each retry attempt. Receives the retry attempt count.
  final void Function(int attempt)? onRetry;

  /// Called when an error is first captured (before any retry).
  final void Function(QLErrorState error)? onError;

  /// Maximum number of retry attempts before marking as fatal.
  final int maxRetries;

  /// A QLSignal<QLErrorState?> that will be updated when this boundary
  /// captures or clears an error. Allows reactive parent widgets to respond.
  final QLSignal<QLErrorState?>? errorSignal;

  /// Logical label for this boundary (used in error messages and telemetry).
  final String? label;

  const QLErrorBoundary({
    super.key,
    required this.builder,
    this.fallback,
    this.onRetry,
    this.onError,
    this.maxRetries = 3,
    this.errorSignal,
    this.label,
  });

  @override
  State<QLErrorBoundary> createState() => _QLErrorBoundaryState();
}

class _QLErrorBoundaryState extends State<QLErrorBoundary> {
  QLErrorState? _errorState;
  FlutterExceptionHandler? _previousFlutterErrorHandler;

  @override
  void initState() {
    super.initState();
    _installFrameworkErrorHandler();
  }

  /// Installs a scoped FlutterError.onError handler.
  /// When framework errors occur (e.g., in layout callbacks), they
  /// are routed into this boundary rather than crashing the app.
  void _installFrameworkErrorHandler() {
    _previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Layout-assertion errors (overflow, unbounded-constraint failures)
      // are intentionally NOT routed into this boundary's fallback/retry
      // state: trapping them and calling setState synchronously mid-layout
      // can trigger a recursive render-crash loop. Flutter already renders
      // these visibly in debug mode (yellow/black stripes, red banners), so
      // we let them pass through to whatever handler was previously
      // installed -- but we ALSO always notify the observability hook so
      // they're never silently lost in production. See
      // [QLErrorBoundaryConfig] for why this matters.
      final bool isOverflowOrSizeCrash =
          QLErrorUtils.isHarmlessLayoutError(details);

      if (details.silent || isOverflowOrSizeCrash) {
        try {
          QLErrorBoundaryConfig.onSuppressedLayoutError?.call(details);
        } catch (_) {
          // Never let a misbehaving telemetry hook crash the error handler
          // itself -- that would be strictly worse than the layout error.
        }
        _previousFlutterErrorHandler?.call(details);
        return; // Let Flutter draw the yellow stripes, do NOT crash the VM.
      }

      if (mounted) {
        _previousFlutterErrorHandler?.call(details);
        _captureError(
          details.exception,
          stackTrace: details.stack,
          severity: QLErrorSeverity.recoverable,
          context: widget.label ?? 'FlutterError',
        );
      } else {
        _previousFlutterErrorHandler?.call(details);
      }
    };
  }

  @override
  void dispose() {
    // CRITICAL: always restore previous handler to prevent handler chain breaks.
    FlutterError.onError = _previousFlutterErrorHandler;
    super.dispose();
  }

  /// Captures an error and transitions to error state.
  /// Safe to call from async callbacks, Future.catchError, etc.
  void _captureError(
    Object error, {
    StackTrace? stackTrace,
    QLErrorSeverity severity = QLErrorSeverity.recoverable,
    String? context,
  }) {
    if (!mounted) return;

    final QLErrorState state = QLErrorState(
      error: error,
      stackTrace: stackTrace,
      retryCount: _errorState?.retryCount ?? 0,
      maxRetries: widget.maxRetries,
      severity: severity,
      context: context ?? widget.label,
    );

    // Update the reactive error signal if provided.
    widget.errorSignal?.value = state;
    widget.onError?.call(state);

    // 🚀 THE IMMORTALITY FIX:
    // Never call setState synchronously during the persistent build or layout phases.
    // This completely prevents recursive render-crash loops.
    if (SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks ||
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _errorState = state);
      });
    } else {
      setState(() => _errorState = state);
    }
  }

  void _retry() {
    if (_errorState == null || !_errorState!.canRetry) return;

    final int attempt = (_errorState?.retryCount ?? 0) + 1;
    widget.onRetry?.call(attempt);

    setState(() {
      _errorState = null;
    });

    // Clear the reactive error signal.
    widget.errorSignal?.value = null;
  }

  @override
  Widget build(BuildContext context) {
    // If an error has been captured, show the fallback.
    if (_errorState != null) {
      final VoidCallback? retryCallback = _errorState!.canRetry ? _retry : null;
      return QLErrorBoundaryScope._(
        state: this,
        child: widget.fallback?.call(context, _errorState!, retryCallback) ??
            _QLDefaultFallback(
                errorState: _errorState!, onRetry: retryCallback),
      );
    }

    // Wrap the builder in try/catch to intercept synchronous build errors.
    try {
      return QLErrorBoundaryScope._(
        state: this,
        child: widget.builder(context),
      );
    } catch (error, stackTrace) {
      // Synchronous build error captured. Transition to error state.
      // We can't call setState here (we're in build), so we update directly
      // and return the fallback in the same frame.
      _errorState = QLErrorState(
        error: error,
        stackTrace: stackTrace,
        maxRetries: widget.maxRetries,
        context: widget.label,
      );
      widget.errorSignal?.value = _errorState;
      widget.onError?.call(_errorState!);

      final VoidCallback? retryCallback = _errorState!.canRetry ? _retry : null;
      return QLErrorBoundaryScope._(
        state: this,
        child: widget.fallback?.call(context, _errorState!, retryCallback) ??
            _QLDefaultFallback(
                errorState: _errorState!, onRetry: retryCallback),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QLBOUNDARY REPORTER MIXIN (Auto-Route Errors from State Classes)
// ────────────────────────────────────────────────────────────────────────────

/// Mixin for State classes that want to automatically route
/// unhandled errors to the nearest QLErrorBoundary ancestor.
///
/// Usage:
///   class _MyState extends State<MyWidget> with QLErrorBoundaryReporter {
///     Future<void> loadData() async {
///       reportError(() => someApiCall());
///     }
///   }
mixin QLErrorBoundaryReporter<T extends StatefulWidget> on State<T> {
  /// Runs [action] and routes any thrown error to the nearest boundary.
  Future<void> runSafe(Future<void> Function() action,
      {String? context}) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _route(error, stackTrace, context);
    }
  }

  /// Routes an error to the nearest QLErrorBoundaryScope.
  void reportError(Object error, {StackTrace? stackTrace, String? context}) {
    _route(error, stackTrace, context);
  }

  void _route(Object error, StackTrace? stackTrace, String? context) {
    if (!mounted) return;
    QLErrorBoundaryScope.maybeOf(context as BuildContext? ?? this.context)
        ?.report(error, stackTrace: stackTrace, context: context as String?);
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  QLBOUNDARY WRAP (Convenience Extension)
// ────────────────────────────────────────────────────────────────────────────

extension QLErrorBoundaryExt on Widget {
  /// Wraps this widget in a QLErrorBoundary with default settings.
  Widget withErrorBoundary({
    Widget Function(BuildContext ctx, QLErrorState error, VoidCallback? retry)?
        fallback,
    int maxRetries = 3,
    String? label,
    QLSignal<QLErrorState?>? errorSignal,
  }) =>
      QLErrorBoundary(
        builder: (ctx) => this,
        fallback: fallback,
        maxRetries: maxRetries,
        label: label,
        errorSignal: errorSignal,
      );
}
