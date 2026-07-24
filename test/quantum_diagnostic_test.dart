import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Update this to match your exact package name
import 'package:quantum_layout/quantum.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 🚀 MOCK ASSET BUNDLE HELPER
/// Bypasses actual file I/O and intercepts rootBundle.loadString requests
/// ════════════════════════════════════════════════════════════════════════════
void setupMockAssets(Map<String, String> assets) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) return null;

    final String key = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );

    // Support Flutter's internal AssetManifest lookups
    if (key == 'AssetManifest.json') {
      final manifestMap = {
        for (var k in assets.keys) k: [k]
      };
      return ByteData.view(utf8.encode(jsonEncode(manifestMap)).buffer);
    }

    if (assets.containsKey(key)) {
      final Uint8List encoded = utf8.encode(assets[key]!);
      return ByteData.view(encoded.buffer);
    }

    throw FlutterError('Unable to load asset: $key');
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    QEngine.instance.initialize();
    QuantumVM.instance.initialize();
    initQuantumBuiltIns(QuantumVM.instance);

    // Register the custom math pipes used in the tests
    QLPipes.register('plus', (val, args) {
      final a = num.tryParse(val?.toString() ?? '0') ?? 0;
      final b = num.tryParse(args.firstOrNull ?? '1') ?? 1;
      return (a + b).toInt();
    });
    QLPipes.register('minus', (val, args) {
      final a = num.tryParse(val?.toString() ?? '0') ?? 0;
      final b = num.tryParse(args.firstOrNull ?? '1') ?? 1;
      return (a - b).toInt();
    });
  });

  setUp(() {
    // Reset environments and caches before every test to ensure pure state
    QLYamlEnv.seed({});
    QuantumYamlEngine.instance.clearCaches();
    QuantumFileRouter.instance.invalidateCache();
    QuantumVM.instance.clearRuntimeCaches();
  });

  tearDown(() {
    QuantumYamlEngine.instance.clearCaches();
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// PART 1: CORE YAML ENGINE & CONFIG EXTRACTORS
  /// ════════════════════════════════════════════════════════════════════════════

  group('Group 1: QLYamlEnv - Environment Variables', () {
    test('Set, Get, and Snapshot behave correctly', () {
      QLYamlEnv.seed({'API_URL': 'https://api.quantum.com', 'PORT': '8080'});
      expect(QLYamlEnv.get('API_URL'), 'https://api.quantum.com');
      expect(QLYamlEnv.get('PORT'), '8080');
      expect(QLYamlEnv.get('MISSING_KEY'), '');
      expect(QLYamlEnv.has('PORT'), true);
      QLYamlEnv.set('DEBUG_MODE', 'true');
      expect(QLYamlEnv.get('DEBUG_MODE'), 'true');
    });
  });

  group('Group 2: QLYamlConfig - Type Coercions & Dot Notation', () {
    final Map<String, dynamic> mockConfig = {
      'app': {
        'version': '2.0',
        'build': 42,
        'flags': {
          'isBeta': 'true',
          'isLegacy': 'yes',
          'isDeprecated': '0',
          'enabled': 1
        }
      },
      'metrics': {'threshold': '99.9', 'timeout': 500},
      'features': ['auth', 'billing', 100],
    };

    test('Deep nested dot notation extraction', () {
      expect(QLYamlConfig.string(mockConfig, 'app.version'), '2.0');
      expect(QLYamlConfig.integer(mockConfig, 'app.build'), 42);
      expect(QLYamlConfig.boolean(mockConfig, 'app.flags.isBeta'), true);
    });

    test('Number and Integer coercions', () {
      expect(QLYamlConfig.number(mockConfig, 'metrics.threshold'), 99.9);
      expect(QLYamlConfig.integer(mockConfig, 'metrics.timeout'), 500);
      expect(QLYamlConfig.integer(mockConfig, 'metrics.threshold'), 99);
    });
  });

  group('Group 3: QLYamlNode - Immutable Result Tree', () {
    test('Node instantiation and type checking', () {
      final node = QLYamlNode.fromRaw({
        'count': 10,
        'isValid': true,
        'nested': {'a': 'b'}
      });
      expect(node['count'].asInt, 10);
      expect(node['isValid'].asBool, true);
      expect(node.path(['nested', 'a']).asString, 'b');
      expect(node.path(['nested', 'missing']).isNull, true);
    });
  });

  group('Group 4: QuantumYamlEngine - Parsing & Interpolation', () {
    test('Environment Variables Substitution', () async {
      QLYamlEnv.seed({'HOST': 'https://api.com', 'PORT': '443'});
      final raw = 'url: "{{env.HOST}}:{{env.PORT}}"';
      final res = await QuantumYamlEngine.instance.parseString(raw);
      expect(res['url'], 'https://api.com:443');
    });
  });

  group('Group 5: QuantumYamlEngine - File Routing & Resolvers', () {
    test('\$import resolution with Relative Pathing', () async {
      setupMockAssets({
        'pages/dashboard/index.yaml':
            'components:\n  \$import: "../shared/components.yaml"',
        'pages/shared/components.yaml': 'button: "PrimaryBtn"',
      });
      final res =
          await QuantumYamlEngine.instance.load('pages/dashboard/index.yaml');
      expect(res['components']['button'], 'PrimaryBtn');
    });
  });

  group('Group 6: QuantumYamlEngine - Caching & State Management', () {
    test('Cache Hit prevents re-parsing', () async {
      setupMockAssets({'file.yaml': 'data: "Hello"'});
      final res1 = await QuantumYamlEngine.instance.load('file.yaml');
      setupMockAssets({'file.yaml': 'data: "Tampered"'});
      final res2 = await QuantumYamlEngine.instance.load('file.yaml');
      expect(res1['data'], 'Hello');
      expect(res2['data'], 'Hello'); // Cached

      QuantumYamlEngine.instance.clearCaches();
      final res3 = await QuantumYamlEngine.instance.load('file.yaml');
      expect(res3['data'], 'Tampered'); // Fresh
    });
  });

  group('Group 7: YAML Config Data Models', () {
    test('QLAppYamlConfig parsed accurately', () {
      final config = QLAppYamlConfig.fromMap({
        'app': {'name': 'TestApp'},
        'router': {'initialRoute': '/home'},
        'vm': {'workerThreads': 8}
      });
      expect(config.appName, 'TestApp');
      expect(config.initialRoute, '/home');
      expect(config.workerThreads, 8);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// PART 2: ADVANCED YAML ENGINE (DIAMONDS, ARRAYS, PATHS)
  /// ════════════════════════════════════════════════════════════════════════════

  group('Group 8: Deep Environment Interpolation', () {
    test('Partial string replacement and defaults', () async {
      QLYamlEnv.seed({'PROTOCOL': 'https', 'DOMAIN': 'api.com'});
      final res = await QuantumYamlEngine.instance.parseString(
          'endpoint: "{{env.PROTOCOL}}://{{env.DOMAIN}}/{{env.PATH | default: graphql}}"');
      expect(res['endpoint'], 'https://api.com/graphql');
    });
  });

  group('Group 9: Complex Graph Composition', () {
    test('Absolute imports via `/` jump directly to root bundle', () async {
      setupMockAssets({
        'deep/nested/folder/file.yaml':
            'config:\n  \$import: "/global_config.yaml"',
        'global_config.yaml': 'isGlobal: true',
      });
      final res =
          await QuantumYamlEngine.instance.load('deep/nested/folder/file.yaml');
      expect(res['config']['isGlobal'], true);
    });
  });

  group('Group 10: Error Guards', () {
    test('Throws QuantumYamlException on malformed YAML', () async {
      setupMockAssets({'bad.yaml': 'app:\n  name: "Broken\n  - unclosed'});
      expect(() async => await QuantumYamlEngine.instance.load('bad.yaml'),
          throwsA(isA<QuantumYamlException>()));
    });
  });

  group('Group 11: Global Modifiers', () {
    test('applyYamlState pushes directly to global store', () {
      applyYamlState({'auth.user': 'Alice'});
      expect(QuantumVM.instance.store.get('auth.user'), 'Alice');
    });
  });

  group('Group 13: Diamond Dependencies vs Circular', () {
    test('Self-referential circular import is caught immediately', () async {
      setupMockAssets({'self.yaml': 'data:\n  \$import: "self.yaml"'});
      expect(() async => await QuantumYamlEngine.instance.load('self.yaml'),
          throwsA(isA<QuantumYamlException>()));
    });
  });

  group('Group 14: Strict Merge/Override', () {
    test('\$override annihilates existing keys at top level', () async {
      setupMockAssets({
        'main.yaml':
            'ui:\n  \$import: "base.yaml"\n  \$override:\n    colors:\n      primary: "blue"',
        'base.yaml': 'colors:\n  primary: "red"\n  secondary: "green"',
      });
      final res = await QuantumYamlEngine.instance.load('main.yaml');
      expect(res['ui']['colors']['primary'], 'blue');
      expect(res['ui']['colors']['secondary'], isNull);
    });
  });

  group('Group 15: Root Value Wrapping', () {
    test('Loading a pure scalar string wraps it in {"_root": ...}', () async {
      setupMockAssets({'scalar.yaml': '"Just a random string"'});
      final res = await QuantumYamlEngine.instance.load('scalar.yaml');
      expect(res['_root'], 'Just a random string');
    });
  });

  group('Group 17: QLYamlConfig Resilience', () {
    test('Extracting Boolean from unusual truthy string works', () {
      expect(QLYamlConfig.boolean({'k': 'yes'}, 'k'), true);
      expect(QLYamlConfig.boolean({'k': '1'}, 'k'), true);
      expect(QLYamlConfig.boolean({'k': 'on'}, 'k'), true);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// PART 3: E2E DIAGNOSTICS (UI, ROUTER, VM, AST)
  /// ════════════════════════════════════════════════════════════════════════════

  group('E2E UI & Router Diagnostics', () {
    setUp(() {
      setupMockAssets({
        'assets/APP.yaml':
            'app:\n  name: QuantumApp\nrouter:\n  pagesDir: assets/pages',
        'assets/pages/_layout.yaml': '''
type: box:col
children:
  - type: text:h2
    props: { text: "Quantum SDUI" }
  - type: box:scroll
    children:
      - type: slot
        name: page
''',
        'assets/pages/index.yaml': '''
type: screen
ui:
  type: box:col
  children:
    - type: text
      props: { text: "YAML Driven" }
''',
      });
    });

    testWidgets(
        'Group 19: Does the router properly assign the layout slot name?',
        (tester) async {
      final routes =
          await QuantumFileRouter.instance.buildRoutes('assets/pages');
      final routeInfo = QLRouteInfo(path: '/');
      final widget = routes.first.builder!(
          tester.element(find.byType(Container)), routeInfo);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      expect(find.text('Quantum SDUI'), findsOneWidget); // From Layout
      expect(find.text('YAML Driven'), findsOneWidget); // From Page
    });
  });

  group('Group 20: Macro Compilation', () {
    testWidgets('Does the StatCard macro compile and render props?',
        (tester) async {
      QJsonTemplateEngine_D.define({
        'name': 'TestCard',
        'defaultProps': {'value': '0', 'label': 'Metric'},
        'ui': {
          'type': 'box:col',
          'children': [
            {
              'type': 'text',
              'props': {'text': '{{props.value}}'}
            },
            {
              'type': 'text',
              'props': {'text': '{{props.label}}'}
            }
          ]
        }
      });

      final testNode = QLBlueprint.fromJson({
        'type': 'TestCard',
        'props': {'value': '99%', 'label': 'Uptime'}
      });

      await tester.pumpWidget(MaterialApp(
        home: QLDataScope(
          moduleStore: QLDataStore(namespace: 'd'),
          child: Builder(
              builder: (ctx) => QuantumVM.instance.renderWidget(ctx, testNode)),
        ),
      ));

      expect(find.text('99%'), findsOneWidget);
      expect(find.text('Uptime'), findsOneWidget);
    });
  });

  group('Group 21: CSS Flex & Constraints Armor', () {
    testWidgets('Does "flex-wrap" safely strip Expanded children?',
        (tester) async {
      final testNode = QLBlueprint.fromJson({
        'type': 'box:row',
        'style': 'flex-wrap',
        'children': [
          {
            'type': 'box',
            'style': 'flex-1',
            'children': [
              {
                'type': 'text',
                'props': {'text': 'Safe Item'}
              }
            ]
          }
        ]
      });

      await tester.pumpWidget(MaterialApp(
        home: QLDataScope(
            moduleStore: QLDataStore(namespace: 'd'),
            child: Builder(
                builder: (ctx) =>
                    QuantumVM.instance.renderWidget(ctx, testNode))),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Safe Item'), findsOneWidget);
    });

    testWidgets(
        'Does "h-full" in an unbounded scroll parent safely resolve without OOM?',
        (tester) async {
      final testNode = QLBlueprint.fromJson({
        'type': 'box:col',
        'style': 'h-full bg-red',
        'children': [
          {
            'type': 'text',
            'props': {'text': 'Content'}
          }
        ]
      });

      await tester.pumpWidget(MaterialApp(
        home: SingleChildScrollView(
          child: QLDataScope(
              moduleStore: QLDataStore(namespace: 'd'),
              child: Builder(
                  builder: (ctx) =>
                      QuantumVM.instance.renderWidget(ctx, testNode))),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('Group 23: Action Engine & Middlewares', () {
    testWidgets('Ensures execution limits stop infinite action loops',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: Container()));
      final ctx = tester.element(find.byType(Container));

      QuantumVM.instance.registerAction('malicious.loop',
          LambdaActionPlugin((p, s, c) async {
        await QuantumVM.instance.triggerActions([
          {'action': 'malicious.loop'}
        ], c);
      }));

      expect(
        () async => await QuantumVM.instance.triggerActions([
          {'action': 'malicious.loop'}
        ], ctx),
        throwsA(isA<QuantumSecurityException>().having((e) => e.message, 'msg',
            contains('Maximum execution limits exceeded'))),
      );
    });

    testWidgets('Action Tuple Syntax correctly parses', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Container()));
      final ctx = tester.element(find.byType(Container));
      String capturedArg = '';

      QuantumVM.instance.registerAction('test.ping',
          LambdaActionPlugin((p, s, c) async {
        capturedArg = p['message'];
      }));

      await QuantumVM.instance.triggerActions([
        [
          'test.ping',
          {'message': 'Tuple Success'}
        ]
      ], ctx);

      expect(capturedArg, 'Tuple Success');
    });
  });

  group('Group 24: Advanced Data Pipes', () {
    test('The "switch" pipe resolves inline arguments correctly', () {
      final store = QLDataStore(namespace: 'd');
      store.set('status', 'active');
      final result = QLDataBinder.resolveAOT(
          {
            '_isTokenized': true,
            'tokens': [
              {
                '_bind': ['state', 'status'],
                'pipes': [
                  {
                    'name': 'switch',
                    'args': ['active:Online', 'paused:Idle']
                  }
                ]
              }
            ]
          },
          null,
          {},
          store);
      expect(result, 'Online');
    });

    test('The "multiply" pipe executes correctly with numeric fallback', () {
      final store = QLDataStore(namespace: 'd');
      store.set('price', 100);
      final result = QLDataBinder.resolveAOT(
          {
            '_isTokenized': true,
            'tokens': [
              {
                '_bind': ['state', 'price'],
                'pipes': [
                  {
                    'name': 'multiply',
                    'args': ['1.5']
                  }
                ]
              }
            ]
          },
          null,
          {},
          store);
      expect(result, 150.0);
    });
  });

  group('Group 25: Template Variant Overrides', () {
    testWidgets('Macro correctly injects Variant-specific overrides',
        (tester) async {
      QJsonTemplateEngine_D.define({
        'name': 'AlertCard',
        'defaultProps': {'type': 'info'},
        'ui': {
          'type': 'box:col',
          'children': [
            {
              'type': 'text',
              'props': {'text': 'Alert', 'slot': 'title'}
            }
          ]
        },
        'variants': {
          'type': {
            'error': {
              'title': {'style': 'color-red'}
            }
          }
        }
      });

      final testNode = QLBlueprint.fromJson({
        'type': 'AlertCard',
        'props': {'type': 'error'}
      });

      await tester.pumpWidget(MaterialApp(
        home: QLDataScope(
            moduleStore: QLDataStore(namespace: 'd'),
            child: Builder(
                builder: (ctx) =>
                    QuantumVM.instance.renderWidget(ctx, testNode))),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('Group 26: State Transactions & Rollback', () {
    test('State modifications can be snapshotted and rolled back', () {
      final store = QLDataStore(namespace: 'd');
      store.set('user.name', 'Alice');
      store.saveSnapshot();
      store.set('user.name', 'Bob');
      store.rollback();
      expect(store.get('user.name'), 'Alice');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 27: HICCUP SYNTAX PARSING
  /// ════════════════════════════════════════════════════════════════════════════
  group('Group 27: Hiccup Syntax Parsing', () {
    test('Compiles array syntax natively into QLBlueprint', () {
      // 🚀 FIX: Pass the array directly to the Compiler, not QLBlueprint.fromJson!
      final astRaw = [
        "box:col",
        'bg-red',
        ["text", "Hello World"]
      ];

      final blueprint = QLCompiler.compile(astRaw, {});

      expect(blueprint.type, 'box');
      expect(blueprint.props['__subType'], 'col'); // Mapped via colon syntax!
      expect(blueprint.style, 'bg-red');

      expect(blueprint.children.first.type, 'text');
      expect(blueprint.children.first.props['text'], 'Hello World');
    });
  });
}
