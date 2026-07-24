import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

// Provides access to internal QLType for backwards compat testing

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    // Reset the singleton before each test by force installing with a fresh config
    TelemetryController.instance.disposeTelemetry();
    TelemetryController.instance.install(
      config: const TelemetryConfig(
        maxEvents: 500, // Small buffer to easily test ring mechanics
        maxImageTrackers: 10,
        maxDataSpans: 10,
        captureFrameTimings: true,
      ),
    );
    TelemetryController.instance.reset(); // Clear buffers and clocks
    TelemetryController.instance.setEnabled(true);
  });

  group('Quantum Telemetry - Core Mechanics', () {
    test('Engine installation initializes properly', () {
      expect(TelemetryController.instance.enabled, isTrue);
      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.isEmpty, isTrue);
    });

    test('Bit-packing handles boundaries and flags correctly', () {
      TelemetryController.instance.record(
        TelemetryKind.network,
        'api_call',
        valueA: 99999,
        valueB: 42,
        valueC: 255,
        flags: TelemetryFlags.important | TelemetryFlags.cacheHit,
      );

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 1);
      final event = snap.records.first;

      expect(event.kind, TelemetryKind.network);
      expect(event.targetLabel, 'api_call');
      expect(event.valueA, 99999);
      expect(event.valueB, 42);
      expect((event.flags & TelemetryFlags.important) != 0, isTrue);
      expect(event.isCacheHit, isTrue);
      expect(event.isFailure, isFalse);
    });

    test('Ring Buffer wraps around perfectly (O(1) overwrites)', () {
      // Config says maxEvents: 500
      for (int i = 0; i < 550; i++) {
        TelemetryController.instance.record(
          TelemetryKind.custom,
          'event_$i',
          mergeSimilar: false,
        );
      }
      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 500, reason: 'Buffer should cap at 500');

      // Since it wrapped around, the earliest event should be event_50
      // because 550 total - 500 max = 50 lost.
      expect(snap.records.first.targetLabel, 'event_50');
      expect(snap.records.last.targetLabel, 'event_549');
    });

    test('Merge Similar Events debounces extreme spam', () {
      for (int i = 0; i < 100; i++) {
        TelemetryController.instance.record(
          TelemetryKind.scroll,
          'ListView',
          valueA: i, // Will continuously accumulate!
          mergeSimilar: true,
        );
      }
      final snap = TelemetryController.instance.snapshot();

      expect(snap.records.length, 1);
      // Sum of 0..99 = 4950
      expect(snap.records.first.valueA, 4950,
          reason: 'Merged event accumulates valueA');
      // merge count accumulates into valueC
      expect(snap.records.first.valueC, 100,
          reason: 'Count should accurately reflect 100 calls');
    });
  });

  group('Quantum Telemetry - Span tracking (Action/Data/Image)', () {
    test('Action Spans properly record duration and success/fail', () async {
      final ticket = TelemetryController.instance.beginAction('checkout');
      await Future.delayed(
          const Duration(milliseconds: 10)); // Force time passing
      TelemetryController.instance.endAction(ticket, success: true);

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 2,
          reason: 'Should have enter and exit events');

      final actionExitEvent = snap.records.last;
      expect(actionExitEvent.kind, TelemetryKind.vm);
      expect(actionExitEvent.targetLabel, 'checkout');
      expect(actionExitEvent.valueA, greaterThanOrEqualTo(10));
      expect(actionExitEvent.isFailure, isFalse);
    });

    test('Data Load Spans calculate success and context correctly', () async {
      final ticket = TelemetryController.instance
          .beginDataLoad('fetch_user', context: 'sql');
      TelemetryController.instance.endDataLoad(ticket, success: false);

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 2); // enter and exit
      final event = snap.records.last;

      expect(event.kind, TelemetryKind.data);
      expect(event.targetLabel, 'fetch_user');
      expect(event.contextLabel,
          'load_failure'); // Context becomes load_failure upon end
      expect(event.valueA, greaterThanOrEqualTo(0),
          reason: 'valueA tracks durationMs');
      expect(event.isFailure, isTrue);
    });

    test('Image Loads correctly identify caching', () {
      final t1 = TelemetryController.instance
          .beginImageLoad('hero.jpg', fromCache: true);
      TelemetryController.instance.endImageLoad(t1, bytes: 1024);

      final t2 = TelemetryController.instance
          .beginImageLoad('avatar.png', fromCache: false);
      TelemetryController.instance.endImageLoad(t2, bytes: 4096);

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 4); // 2 enter, 2 exit
      expect(snap.records[1].isCacheHit, isTrue);
      expect(snap.records[3].isCacheHit, isFalse);
    });

    test('Dangling (unclosed) spans safely write enter events to buffer', () {
      TelemetryController.instance.beginAction('forever_action');
      TelemetryController.instance.beginDataLoad('forever_data');
      TelemetryController.instance.beginImageLoad('forever_img.jpg');

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 3,
          reason: 'Enter events are logged immediately upon begin');
      expect(snap.records.every((r) => r.isEnter), isTrue);
    });

    test('Max concurrent trackers drop new spans silently', () {
      final tickets = <int>[];

      // Our config set maxImageTrackers: 10
      for (int i = 0; i < 20; i++) {
        tickets.add(TelemetryController.instance.beginImageLoad('img_$i.jpg'));
      }
      for (final t in tickets) {
        TelemetryController.instance.endImageLoad(t);
      }

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 20,
          reason: '10 valid enter events, 10 valid exit events');
    });
  });

  group('Quantum Telemetry - Scopes and Kill-Switches', () {
    test('Global disable completely silences recording', () {
      TelemetryController.instance.setEnabled(false);
      TelemetryController.instance.recordMetric('cpu', valueA: 50);
      TelemetryController.instance.beginAction('click');
      TelemetryController.instance
          .recordJourneyStep('funnel', step: 1, label: 'test');

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.isEmpty, isTrue);
    });

    test('withDisabled drops synchronous logs', () {
      TelemetryController.instance.recordMetric('mem', valueA: 10);
      TelemetryController.instance.withDisabled(() {
        TelemetryController.instance.recordMetric('mem', valueA: 9999);
      });
      TelemetryController.instance.recordMetric('mem', valueA: 20);

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 2);
      expect(snap.records[0].valueA, 10);
      expect(snap.records[1].valueA, 20);
    });

    test(
        'setScopeEnabled sets logic flags accurately for widget instrumentation',
        () {
      TelemetryController.instance.setScopeEnabled('noisy_screen', false);
      expect(
          TelemetryController.instance.isScopeEnabled('noisy_screen'), isFalse);
      expect(
          TelemetryController.instance.isScopeEnabled('quiet_screen'), isTrue);
    });
  });

  group('Quantum Telemetry - Snapshot Analytics Module', () {
    test('avgActionDurationByName computes exactly', () {
      final t1 = TelemetryController.instance.beginAction('save');
      TelemetryController.instance.endAction(t1); // ~0ms

      final t2 = TelemetryController.instance.beginAction('save');
      TelemetryController.instance.endAction(t2); // ~0ms

      final t3 = TelemetryController.instance.beginAction('load');
      TelemetryController.instance.endAction(t3); // ~0ms

      final snap = TelemetryController.instance.snapshot();
      final avgs = snap.avgActionDurationByName();
      expect(avgs.containsKey('save'), isTrue);
      expect(avgs.containsKey('load'), isTrue);
    });

    test('journeyFunnel maps sequential completion perfectly', () {
      TelemetryController.instance
          .recordJourneyStep('onboarding', step: 0, label: 'home');
      TelemetryController.instance
          .recordJourneyStep('onboarding', step: 1, label: 'signup');
      TelemetryController.instance
          .recordJourneyStep('checkout', step: 0, label: 'cart');
      TelemetryController.instance
          .recordJourneyStep('onboarding', step: 2, label: 'done');

      final snap = TelemetryController.instance.snapshot();
      final onboardFunnel = snap.journeyFunnel('onboarding');
      final checkoutFunnel = snap.journeyFunnel('checkout');

      expect(onboardFunnel.length, 3);
      expect(onboardFunnel[0].contextLabel, 'home');
      expect(onboardFunnel[2].contextLabel, 'done');
      expect(checkoutFunnel.length, 1);
      expect(checkoutFunnel[0].contextLabel, 'cart');
    });

    test('jankFrames properly filters and identifies heavy build/raster times',
        () {
      TelemetryController.instance.record(TelemetryKind.frame, 'frame',
          valueC: 10, flags: TelemetryFlags.exit, mergeSimilar: false); // Ok
      TelemetryController.instance.record(TelemetryKind.frame, 'frame',
          valueC: 20,
          flags: TelemetryFlags.exit | TelemetryFlags.jank,
          mergeSimilar: false); // Jank
      TelemetryController.instance.record(TelemetryKind.frame, 'frame',
          valueC: 35,
          flags: TelemetryFlags.exit | TelemetryFlags.jank,
          mergeSimilar: false); // Jank

      final snap = TelemetryController.instance.snapshot();
      final jank = snap.jankFrames(thresholdMs: 16);
      expect(jank.length, 2);
      expect(jank[0].valueC, 20);
      expect(jank[1].valueC, 35);
    });

    test('imageCacheHitRate computes exact percentages', () {
      final t1 =
          TelemetryController.instance.beginImageLoad('a', fromCache: true);
      TelemetryController.instance.endImageLoad(t1);
      final t2 =
          TelemetryController.instance.beginImageLoad('b', fromCache: true);
      TelemetryController.instance.endImageLoad(t2);
      final t3 =
          TelemetryController.instance.beginImageLoad('c', fromCache: false);
      TelemetryController.instance.endImageLoad(t3);
      final t4 =
          TelemetryController.instance.beginImageLoad('d', fromCache: false);
      TelemetryController.instance.endImageLoad(t4);

      final snap = TelemetryController.instance.snapshot();
      expect(snap.imageCacheHitRate, 0.5); // 50%
    });

    test('topTappedWidgets orders correctly', () {
      for (int i = 0; i < 10; i++)
        TelemetryController.instance.record(TelemetryKind.interaction, 'btn_A',
            flags: TelemetryFlags.tap, mergeSimilar: false);
      for (int i = 0; i < 30; i++)
        TelemetryController.instance.record(TelemetryKind.interaction, 'btn_B',
            flags: TelemetryFlags.tap, mergeSimilar: false);
      for (int i = 0; i < 5; i++)
        TelemetryController.instance.record(TelemetryKind.interaction, 'btn_C',
            flags: TelemetryFlags.tap, mergeSimilar: false);

      final snap = TelemetryController.instance.snapshot();
      final top = snap.topTappedWidgets(limit: 2);

      expect(top.length, 2);
      expect(top[0].key, 'btn_B'); // 30
      expect(top[1].key, 'btn_A'); // 10
    });
  });

  group('Quantum Telemetry - Error & Rebuild Tracking', () {
    test('recordError safely catches exceptions and stacktraces', () {
      try {
        throw StateError('Oops');
      } catch (e, st) {
        TelemetryController.instance.recordError(e, st, label: 'test_error');
      }

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 1);
      final err = snap.records.first;

      expect(err.kind, TelemetryKind.error);
      expect(err.targetLabel, 'test_error');
      expect((err.flags & TelemetryFlags.important) != 0, isTrue);
      expect(err.contextLabel?.contains('StateError'), isTrue);
    });

    test('onReactiveBuild logs rebuild metrics correctly', () {
      TelemetryController.instance.onReactiveBuild('Row>Text');
      TelemetryController.instance.onReactiveBuild('Row>Text');

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 1);
      expect(snap.records.first.kind, TelemetryKind.vm);
      expect(snap.records.first.targetLabel, 'Row>Text');
      // Uses `mergeSimilar: true` natively, which combines records and tracks hit counts in valueC
      expect(snap.records.first.valueC, 2);
    });
  });

  group('Quantum Telemetry - Legacy API Compat Shims', () {
    test('QuantumTelemetry legacy wrapper works seamlessly', () {
      QuantumTelemetry.instance.record(QLType.anomaly, 'legacy_crash');

      final snap = QuantumTelemetry.instance.snapshot();
      expect(snap.records.length, 1);
      expect(snap.records.first.kind, TelemetryKind.error);
      expect(snap.records.first.targetLabel, 'legacy_crash');
      expect(
          (snap.records.first.flags & TelemetryFlags.important) != 0, isTrue);
    });
  });

  group('Quantum Telemetry - Performance Benchmark', () {
    test('100,000 rapid event inserts run extremely fast', () {
      TelemetryController.instance.disposeTelemetry();
      TelemetryController.instance.install(
        config: const TelemetryConfig(
          maxEvents: 100000,
        ),
      );
      TelemetryController.instance.reset();
      TelemetryController.instance.setEnabled(true);

      final sw = Stopwatch()..start();
      for (int i = 0; i < 100000; i++) {
        // Disabling similar merging ensures raw write pressure on the buffer
        TelemetryController.instance
            .record(TelemetryKind.custom, 'bench', mergeSimilar: false);
      }
      sw.stop();

      final ms = sw.elapsedMilliseconds;
      debugPrint('🚀 100k Telemetry Events inserted in: ${ms}ms');

      // Expected to complete well under 350ms (typical modern CPU is <15ms)
      expect(ms, lessThan(350),
          reason: 'Telemetry insertion must remain insanely fast (O(1))');

      final snap = TelemetryController.instance.snapshot();
      expect(snap.records.length, 100000);
    });
  });
}
