import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Assume these match your framework's actual import paths
import 'package:quantum_layout/quantum.dart';

// ════════════════════════════════════════════════════════════════════════════
// PART 1: REUSABLE INFRASTRUCTURE & FIXTURES
// ════════════════════════════════════════════════════════════════════════════

abstract class QuantumTestBench {
  static void boot() {
    QEngine.instance.dispose();
    QEngine.instance.initialize(initialCapacity: 1024, ecsCapacity: 1024);

    QuantumVM.instance.clearRuntimeCaches();
    QLStoreRegistry.instance.destroy('default');
    QLSchemaRegistry.instance.clear();
    QLNativeBridgeRegistry.instance.clear();
    SduiReplayGuard.instance.clear();

    initQuantumBuiltIns(QuantumVM.instance);
  }

  static Future<void> pumpNode(
      WidgetTester tester, Map<String, dynamic> ast) async {
    final blueprint = QLCompiler.compile(ast, {});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QLDataScope(
            moduleStore: QLStoreRegistry.instance.defaultStore,
            child: Builder(
              builder: (ctx) => QuantumVM.instance.renderWidget(ctx, blueprint),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Matcher emitsSignalValue(dynamic expected) => _SignalValueMatcher(expected);

class _SignalValueMatcher extends Matcher {
  final dynamic expected;
  _SignalValueMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! QLSignalBase) return false;
    return item.value == expected;
  }

  @override
  Description describe(Description description) =>
      description.add('QLSignal containing ').addDescriptionOf(expected);
}

abstract class SduiCryptoFixtures {
  static final Uint8List testAesKey = Uint8List(32)..fillRange(0, 32, 1);
  static final Uint8List testSigKey = Uint8List(32)..fillRange(0, 32, 2);
  static const String testKid = 'test-key-01';

  static void injectTestKeys() {
    SduiKeyStore.instance.registerKey(
      kid: testKid,
      aesKey: testAesKey,
      sigKey: testSigKey,
      setActive: true,
    );
  }

  static SduiEncryptedPayload generatePayload(Map<String, dynamic> manifest) {
    return QuantumSduiEngine.instance.encrypt(manifest, keyId: testKid);
  }

  static SduiEncryptedPayload tamperSignature(SduiEncryptedPayload payload) {
    return SduiEncryptedPayload(
      version: payload.version,
      keyId: payload.keyId,
      iv: payload.iv,
      ct: payload.ct,
      tag: payload.tag,
      sig: base64Encode(List.filled(32, 0)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PART 2: THE COMPREHENSIVE TEST SUITE
// ════════════════════════════════════════════════════════════════════════════

void main() {
  setUp(() => QuantumTestBench.boot());

  group('SDUI Engine: AST & Reactivity', () {
    testWidgets(
        'compiles colon-syntax (base:sub) and injects default plugin props',
        (tester) async {
      await QuantumTestBench.pumpNode(tester, {
        'type': 'action:button',
        'props': {'text': 'Click Me', 'intent': 'primary'},
      });

      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(QLSensor), findsOneWidget);
    });

    testWidgets(
        'resolves deep {{token}} paths reactively and updates UI on store mutation',
        (tester) async {
      final store = QLStoreRegistry.instance.defaultStore;
      store.set('user.profile.name', 'Alice');

      await QuantumTestBench.pumpNode(tester, {
        'type': 'text',
        'props': {'text': 'Hello, {{state.user.profile.name}}'},
      });

      expect(find.text('Hello, Alice'), findsOneWidget);

      store.set('user.profile.name', 'Bob');
      await tester.pumpAndSettle();

      expect(find.text('Hello, Bob'), findsOneWidget);
    });

    testWidgets(
        'runtime \$if directive conditionally mounts and unmounts nodes',
        (tester) async {
      final store = QLStoreRegistry.instance.defaultStore;
      store.set('showSecret', false);

      await QuantumTestBench.pumpNode(tester, {
        'type': 'box:col',
        'children': [
          {
            'type': 'text',
            'props': {'text': 'Public'}
          },
          {
            'type': 'text',
            'props': {r'$if': '{{state.showSecret}}', 'text': 'Secret'}
          }
        ]
      });

      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Secret'), findsNothing);

      store.set('showSecret', true);
      await tester.pumpAndSettle();

      expect(find.text('Secret'), findsOneWidget);
    });
  });

  group('QLDataStore & Memory Management', () {
    test('transactions batch UI notifications until commit', () async {
      final store = QLDataStore(namespace: 'd');
      final sigA = store.signal('a');
      final sigB = store.signal('b');

      int fireCountA = 0;
      int fireCountB = 0;
      sigA.addListener(() => fireCountA++);
      sigB.addListener(() => fireCountB++);

      store.transaction(() {
        store.set('a', 1);
        store.set('a', 2);
        store.set('b', 1);
      });

      expect(fireCountA, 0);
      await Future.microtask(() {});
      expect(fireCountA, 1);
      expect(fireCountB, 1);
      expect(sigA, emitsSignalValue(2));
    });
  });

  group('Quantum SDUI Encryption & Security', () {
    setUp(() => SduiCryptoFixtures.injectTestKeys());

    test('valid AES-GCM encrypted payload compiles successfully', () async {
      final manifest = {
        'type': 'text',
        'props': {'text': 'Secret Data'}
      };
      final payload = SduiCryptoFixtures.generatePayload(manifest);

      final blueprint =
          await QuantumSduiEngine.instance.decryptAndCompile(payload);
      expect(blueprint.type, 'text');
      expect(blueprint.props['text'], 'Secret Data');
    });

    test('tampered HMAC signature throws QuantumSduiException', () async {
      final manifest = {
        'type': 'text',
        'props': {'text': 'Data'}
      };
      final validPayload = SduiCryptoFixtures.generatePayload(manifest);
      final tampered = SduiCryptoFixtures.tamperSignature(validPayload);

      expect(
        () => QuantumSduiEngine.instance.decryptAndCompile(tampered),
        throwsA(isA<QuantumSduiException>()
            .having((e) => e.code, 'code', 'SIG_MISMATCH')),
      );
    });

    test('reused nonce triggers LRU replay guard exception', () async {
      final manifest = {'type': 'box'};
      final payload = SduiCryptoFixtures.generatePayload(manifest);

      // 1. Initial success caches the blueprint
      await QuantumSduiEngine.instance.decryptAndCompile(payload);

      // 🚀 FIX: Clear the AST cache so the engine is forced to re-evaluate the cipher/nonce
      QuantumSduiEngine.instance.clearCache();

      // 2. Replay attack triggers exception
      expect(
        () => QuantumSduiEngine.instance.decryptAndCompile(payload),
        throwsA(isA<QuantumSduiException>()
            .having((e) => e.code, 'code', 'REPLAY_DETECTED')),
      );
    });
  });

  group('QLErrorBoundary & Fault Isolation', () {
    testWidgets('captures synchronous builder errors and displays fallback',
        (tester) async {
      final errorSignal = QLSignal<QLErrorState?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: QLErrorBoundary(
            errorSignal: errorSignal,
            maxRetries: 2,
            fallback: (ctx, err, retry) => Text('Fallback: ${err.error}',
                textDirection: TextDirection.ltr),
            builder: (ctx) => throw StateError('Simulated Layout Crash'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fallback: Bad state: Simulated Layout Crash'),
          findsOneWidget);
      expect(errorSignal.value, isNotNull);
      expect(errorSignal.value!.canRetry, isTrue);
    });
  });

  group('QParser & CSS Grid Track Resolution', () {
    test('evaluates fixed, fractional, and minmax templates correctly', () {
      final tracks = QParser.parse('1fr 200px minmax(10px, 2fr) auto');

      expect(tracks.length, 4);
      expect(tracks[0], isA<QFraction>().having((t) => t.fr, 'fr', 1.0));
      expect(tracks[1], isA<QFixed>().having((t) => t.px, 'px', 200.0));

      final minMax = tracks[2] as QMinMax;
      expect(minMax.min, isA<QFixed>().having((t) => t.px, 'min_px', 10.0));
      expect(minMax.max, isA<QFraction>().having((t) => t.fr, 'max_fr', 2.0));

      expect(tracks[3], isA<QAuto>());
    });

    test('flattens repeat() functions automatically', () {
      // 🚀 FIX: The custom framework parser expects COMMAS to separate function arguments!
      final tracks = QParser.parse('repeat(3, 100px, 1fr)');

      expect(tracks.length, 6); // 3 repetitions * 2 tracks = 6 total tracks
      expect(tracks[0], isA<QFixed>());
      expect(tracks[1], isA<QFraction>());
      expect(tracks[4], isA<QFixed>());
      expect(tracks[5], isA<QFraction>());
    });
  });
}
