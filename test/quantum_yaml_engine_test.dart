import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:quantum_layout/quantum.dart'; // Update to your exact import path

/// ════════════════════════════════════════════════════════════════════════════
/// 🚀 MOCK ASSET BUNDLE HELPER
/// Bypasses actual file I/O and intercepts rootBundle.loadString requests
/// ════════════════════════════════════════════════════════════════════════════
void setupMockAssets(Map<String, String> assets) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) return null;

    // Decode the asset key requested by rootBundle
    final String key = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );

    if (assets.containsKey(key)) {
      final Uint8List encoded = utf8.encode(assets[key]!);
      return ByteData.view(encoded.buffer);
    }

    throw FlutterError('Unable to load asset: $key');
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset environments and caches before every test to ensure pure state
    QLYamlEnv.seed({});
    QuantumYamlEngine.instance.clearCaches();
  });

  tearDown(() {
    QuantumYamlEngine.instance.clearCaches();
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 1: ENVIRONMENT REGISTRY (QLYamlEnv)
  /// ════════════════════════════════════════════════════════════════════════════
  group('QLYamlEnv - Environment Variables', () {
    test('Set, Get, and Snapshot behave correctly', () {
      QLYamlEnv.seed({'API_URL': 'https://api.quantum.com', 'PORT': '8080'});

      expect(QLYamlEnv.get('API_URL'), 'https://api.quantum.com');
      expect(QLYamlEnv.get('PORT'), '8080');
      expect(QLYamlEnv.get('MISSING_KEY'), '');
      expect(QLYamlEnv.has('PORT'), true);
      expect(QLYamlEnv.has('UNKNOWN'), false);

      QLYamlEnv.set('DEBUG_MODE', 'true');
      expect(QLYamlEnv.get('DEBUG_MODE'), 'true');

      final snapshot = QLYamlEnv.snapshot;
      expect(snapshot['API_URL'], 'https://api.quantum.com');
      expect(() => snapshot['NEW'] = 'fail', throwsUnsupportedError,
          reason: 'Snapshot must be immutable');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 2: TYPE-SAFE CONFIG EXTRACTORS (QLYamlConfig)
  /// ════════════════════════════════════════════════════════════════════════════
  group('QLYamlConfig - Type Coercions & Dot Notation', () {
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

    test('Deep nested dot notation extraction (_dig)', () {
      expect(QLYamlConfig.string(mockConfig, 'app.version'), '2.0');
      expect(QLYamlConfig.integer(mockConfig, 'app.build'), 42);
      expect(QLYamlConfig.boolean(mockConfig, 'app.flags.isBeta'), true);
      expect(QLYamlConfig.string(mockConfig, 'missing.path', fallback: 'fb'),
          'fb');
    });

    test('Boolean coercion matrix', () {
      expect(
          QLYamlConfig.boolean(mockConfig, 'app.flags.isBeta'), true); // "true"
      expect(QLYamlConfig.boolean(mockConfig, 'app.flags.isLegacy'),
          true); // "yes"
      expect(QLYamlConfig.boolean(mockConfig, 'app.flags.enabled'), true); // 1
      expect(QLYamlConfig.boolean(mockConfig, 'app.flags.isDeprecated'),
          false); // "0"
      expect(QLYamlConfig.boolean(mockConfig, 'metrics.timeout'), false,
          reason: 'Non-bool strings default to false');
    });

    test('Number and Integer coercions', () {
      expect(QLYamlConfig.number(mockConfig, 'metrics.threshold'), 99.9);
      expect(QLYamlConfig.number(mockConfig, 'app.build'), 42.0);
      expect(QLYamlConfig.integer(mockConfig, 'metrics.timeout'), 500);
      expect(QLYamlConfig.integer(mockConfig, 'metrics.threshold'),
          99); // 99.9 parsed as int is 99
    });

    test('List and Map coercions', () {
      final list = QLYamlConfig.list(mockConfig, 'features');
      expect(list, ['auth', 'billing', 100]);

      final strList = QLYamlConfig.stringList(mockConfig, 'features');
      expect(strList, ['auth', 'billing', '100']); // Auto-coerced to string

      final map = QLYamlConfig.map(mockConfig, 'app.flags');
      expect(map.containsKey('isBeta'), true);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 3: YAML NODE WRAPPERS (QLYamlNode)
  /// ════════════════════════════════════════════════════════════════════════════
  group('QLYamlNode - Immutable Result Tree', () {
    test('Node instantiation and type checking', () {
      final node = QLYamlNode.fromRaw({
        'title': 'Test',
        'count': 10,
        'isValid': true,
        'items': [1, 2],
        'nested': {'a': 'b'}
      });

      expect(node.isMap, true);
      expect(node['title'].isString, true);
      expect(node['title'].asString, 'Test');

      expect(node['count'].isNumber, true);
      expect(node['count'].asInt, 10);
      expect(node['count'].asDouble, 10.0);

      expect(node['isValid'].isBool, true);
      expect(node['isValid'].asBool, true);

      expect(node['items'].isList, true);
      expect(node['items'].asList, [1, 2]);

      expect(node['nested']['a'].asString, 'b');
      expect(node.path(['nested', 'a']).asString, 'b');
      expect(node.path(['nested', 'missing']).isNull, true);
    });

    test('Missing keys gracefully fallback to empty nodes', () {
      final node = QLYamlNode.fromRaw({});
      expect(node['missing'].isNull, true);
      expect(node['missing']['deeper'].isNull, true);
      expect(node['missing'].asString, '');
      expect(node['missing'].asBool, false);
      expect(node['missing'].asList, []);
      expect(node['missing'].asMap, {});
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 4: INTERPOLATION & PARSING
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Parsing & Interpolation', () {
    test('JSON/YAML Format Auto-Detection (QLFormatParser)', () async {
      final jsonStr = '{"format": "json", "value": 1}';
      final yamlStr = 'format: yaml\nvalue: 2';

      final jsonRes = await QuantumYamlEngine.instance.parseString(jsonStr);
      expect(jsonRes['format'], 'json');
      expect(jsonRes['value'], 1);

      final yamlRes = await QuantumYamlEngine.instance.parseString(yamlStr);
      expect(yamlRes['format'], 'yaml');
      expect(yamlRes['value'], 2);
    });

    test('Environment Variables Substitution', () async {
      QLYamlEnv.seed({'HOST': 'https://api.com', 'PORT': '443'});

      final raw = '''
      config:
        url: "{{env.HOST}}:{{env.PORT}}"
        timeout: "{{env.TIMEOUT | default: 5000}}"
        path: "{{env.PATH | default: /v1/graphql}}"
      ''';

      final res = await QuantumYamlEngine.instance.parseString(raw);
      expect(res['config']['url'], 'https://api.com:443');
      expect(res['config']['timeout'], '5000'); // Triggers default fallback
      expect(res['config']['path'], '/v1/graphql'); // Triggers default fallback
    });

    test('Environment Substitution inside Arrays', () async {
      QLYamlEnv.seed({'ITEM1': 'Apple', 'ITEM2': 'Banana'});

      final raw = '''
      cart:
        - "{{env.ITEM1}}"
        - "{{env.ITEM2}}"
        - "{{env.ITEM3 | default: Cherry}}"
      ''';

      final res = await QuantumYamlEngine.instance.parseString(raw);
      expect(res['cart'], ['Apple', 'Banana', 'Cherry']);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 5: ASSET LOADING, $IMPORT, $MERGE, $OVERRIDE
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - File Routing & Import Resolvers', () {
    test('Basic Asset Load with Normalization', () async {
      setupMockAssets({
        'pages/index.yaml': 'title: "Home"',
      });

      // Engine should auto-append .yaml to paths without extension
      final res = await QuantumYamlEngine.instance.load('pages/index');
      expect(res['title'], 'Home');
    });

    test('\$import resolution with Relative Pathing', () async {
      setupMockAssets({
        'pages/dashboard/index.yaml': '''
          header: "Dashboard"
          components:
            \$import: "../shared/components.yaml"
        ''',
        'pages/shared/components.yaml': '''
          button: "PrimaryBtn"
          card: "ElevatedCard"
        ''',
      });

      final res =
          await QuantumYamlEngine.instance.load('pages/dashboard/index.yaml');
      expect(res['header'], 'Dashboard');
      expect(res['components']['button'], 'PrimaryBtn');
      expect(res['components']['card'], 'ElevatedCard');
    });

    test('\$import with \$override and \$merge', () async {
      setupMockAssets({
        'theme/main.yaml': '''
          colors:
            \$import: "base_colors.yaml"
            \$override:
              primary: "#FF0000"
          typography:
            \$import: "base_type.yaml"
            \$merge:
              h1: "32px"
              h2: "24px"
        ''',
        'theme/base_colors.yaml': '''
          primary: "#000000"
          secondary: "#FFFFFF"
        ''',
        'theme/base_type.yaml': '''
          h1: "24px"
          body: "14px"
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('theme/main.yaml');

      // Override replaces specific keys
      expect(res['colors']['primary'], '#FF0000');
      expect(res['colors']['secondary'], '#FFFFFF'); // Kept intact

      // Merge deep merges keys
      expect(res['typography']['h1'], '32px'); // Merged/Overwritten
      expect(res['typography']['h2'], '24px'); // Added
      expect(res['typography']['body'], '14px'); // Kept intact
    });

    test('Circular Dependency Detection', () async {
      setupMockAssets({
        'a.yaml': '''
          loop:
            \$import: "b.yaml"
        ''',
        'b.yaml': '''
          loop:
            \$import: "c.yaml"
        ''',
        'c.yaml': '''
          loop:
            \$import: "a.yaml"
        ''',
      });

      expect(
        () async => await QuantumYamlEngine.instance.load('a.yaml'),
        throwsA(isA<QuantumYamlException>().having(
            (e) => e.message, 'message', contains('Circular import detected'))),
      );
    });

    test('\$import resolving a list inside an array flattens it', () async {
      setupMockAssets({
        'list_host.yaml': '''
          items:
            - "first"
            - \$import: "list_items.yaml"
            - "last"
        ''',
        'list_items.yaml': '''
          - "imported_1"
          - "imported_2"
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('list_host.yaml');
      expect(res['items'], ['first', 'imported_1', 'imported_2', 'last']);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 6: CONCURRENCY, LRU CACHING & MEMORY
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Caching & State Management', () {
    test('Duplicate concurrent loads share same Future (In-Flight prevention)',
        () async {
      int fetchCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        fetchCount++;
        // Artificial delay to force concurrency overlap
        await Future.delayed(const Duration(milliseconds: 50));
        return ByteData.view(utf8.encode('title: "Cached"').buffer);
      });

      // Fire 5 identical requests simultaneously
      final futures = List.generate(
          5, (_) => QuantumYamlEngine.instance.load('pages/cached.yaml'));
      final results = await Future.wait(futures);

      expect(fetchCount, 1, reason: 'Root bundle should only be hit once');
      expect(results.length, 5);
      expect(results[0]['title'], 'Cached');
      expect(results[4]['title'], 'Cached');
    });

    test('Cache Hit prevents re-parsing', () async {
      int parseCount = 0;
      setupMockAssets({'pages/file.yaml': 'data: "Hello"'});

      final res1 = await QuantumYamlEngine.instance.load('pages/file.yaml');

      // Override mock to prove cache intercepts it before network
      setupMockAssets({'pages/file.yaml': 'data: "Tampered"'});

      final res2 = await QuantumYamlEngine.instance.load('pages/file.yaml');

      expect(res1['data'], 'Hello');
      expect(res2['data'], 'Hello', reason: 'Should return cached result');

      // Now clear cache and fetch again
      QuantumYamlEngine.instance.clearCaches();
      final res3 = await QuantumYamlEngine.instance.load('pages/file.yaml');
      expect(res3['data'], 'Tampered',
          reason: 'Should fetch fresh data after cache clear');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 7: DATA MODELS (App, Page, Theme)
  /// ════════════════════════════════════════════════════════════════════════════
  group('YAML Config Data Models', () {
    test('QLAppYamlConfig parsed accurately', () {
      final rawAppConfig = {
        'app': {
          'name': 'TestApp',
          'title': 'The Test App',
          'version': '1.0.1',
        },
        'router': {
          'initialRoute': '/home',
          'pagesDir': 'screens',
          'notFound': 'screens/404.yaml',
          'globalGuards': [
            {'type': 'auth_check'}
          ]
        },
        'vm': {'workerThreads': 8, 'simdArenaCapacity': 8192},
        'telemetry': {'enabled': false, 'frameMonitor': false},
        'state': {'isLoggedIn': false},
      };

      final config = QLAppYamlConfig.fromMap(rawAppConfig);

      expect(config.appName, 'TestApp');
      expect(config.title, 'The Test App');
      expect(config.version, '1.0.1');
      expect(config.initialRoute, '/home');
      expect(config.pagesDir, 'screens');
      expect(config.notFoundPage, 'screens/404.yaml');
      expect(config.globalGuards.length, 1);
      expect(config.workerThreads, 8);
      expect(config.simdArenaCapacity, 8192);
      expect(config.telemetryEnabled, false);
      expect(config.frameMonitor, false);
      expect(config.state['isLoggedIn'], false);
    });

    test('QLPageYamlConfig parsed accurately', () {
      final rawPageConfig = {
        'type': 'modal',
        'meta': {
          'title': 'SEO Title',
          'description': 'SEO Desc',
          'custom': {'robots': 'noindex'}
        },
        'route': {
          'urlPattern': r'^/item/(?<id>\d+)$',
          'captureGroups': ['id'],
          'transition': 'fade',
          'transitionMs': 500
        },
        'serverProps': {'action': 'api.fetchData'},
        'ui': {'type': 'box', 'children': []}
      };

      final config = QLPageYamlConfig.fromMap(rawPageConfig);

      expect(config.semanticType, QLYamlSemanticType.modal);
      expect(config.metaTitle, 'SEO Title');
      expect(config.metaDescription, 'SEO Desc');
      expect(config.customMeta['robots'], 'noindex');
      expect(config.urlPattern, r'^/item/(?<id>\d+)$');
      expect(config.captureGroups, ['id']);
      expect(config.transition, 'fade');
      expect(config.transitionDurationMs, 500);
      expect(config.serverProps!['action'], 'api.fetchData');
      expect(config.ui['type'], 'box');
    });

    test('QLYamlThemeConfig parsed accurately', () {
      final rawThemeConfig = {
        'mode': 'dark',
        'colors': {'primary': '#FF0000'},
        'typography': {'h1': '24px'},
        'spacing': {'sm': '8px'},
        'breakpoints': {'md': '768px'},
        'radii': {'card': '12px'}
      };

      final config = QLYamlThemeConfig.fromMap(rawThemeConfig);

      expect(config.mode, 'dark');
      expect(config.colors['primary'], '#FF0000');
      expect(config.typography['h1'], '24px');
      expect(config.spacing['sm'], '8px');
      expect(config.breakpoints['md'], '768px');
      expect(config.radii['card'], '12px');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 8: COMPLEX ENVIRONMENT INTERPOLATION & PIPING
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Deep Environment Interpolation', () {
    test('Partial string replacement and multi-variable lines', () async {
      QLYamlEnv.seed(
          {'PROTOCOL': 'https', 'DOMAIN': 'api.quantum.com', 'PORT': '443'});

      final raw = '''
      endpoint: "{{env.PROTOCOL}}://{{env.DOMAIN}}:{{env.PORT}}/graphql"
      welcomeMessage: "Hello {{env.USER | default: Guest User}}, welcome back to {{env.ORG | default: The Matrix}}."
      ''';

      final res = await QuantumYamlEngine.instance.parseString(raw);

      // Multiple env vars in one string
      expect(res['endpoint'], 'https://api.quantum.com:443/graphql');

      // Partial strings with defaults mixed in
      expect(res['welcomeMessage'],
          'Hello Guest User, welcome back to The Matrix.');
    });

    test('Deeply nested interpolation across Maps and Lists', () async {
      QLYamlEnv.set('THEME_COLOR', '#FF00FF');
      QLYamlEnv.set('ENABLE_BETA', 'true');

      final raw = '''
      app:
        settings:
          flags:
            - "{{env.ENABLE_BETA}}"
            - "{{env.ENABLE_ALPHA | default: false}}"
        ui:
          primary: "{{env.THEME_COLOR}}"
          secondary: "{{env.SECONDARY_COLOR | default: #000000}}"
      ''';

      final res = await QuantumYamlEngine.instance.parseString(raw);

      // Deep Lists
      expect(res['app']['settings']['flags'][0], 'true');
      expect(res['app']['settings']['flags'][1], 'false');

      // Deep Maps
      expect(res['app']['ui']['primary'], '#FF00FF');
      expect(res['app']['ui']['secondary'], '#000000');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 9: THE OMEGA GRAPH (Deeply Nested Imports, Overrides, & Arrays)
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Complex Graph Composition', () {
    test('Absolute vs Relative Pathing in deep nested imports', () async {
      setupMockAssets({
        'pages/dashboard/main.yaml': '''
          layout:
            \$import: "/layouts/base.yaml"
            \$override:
              title: "Dashboard Overridden"
          widgets:
            \$import: "./widgets/list.yaml"
        ''',
        'layouts/base.yaml': '''
          type: "scaffold"
          title: "Base Title"
          footer:
            \$import: "footer.yaml"
        ''',
        'layouts/footer.yaml': '''
          text: "Copyright 2025"
        ''',
        'pages/dashboard/widgets/list.yaml': '''
          - "Widget A"
          - "Widget B"
        ''',
      });

      // Load from deep inside the tree
      final res =
          await QuantumYamlEngine.instance.load('pages/dashboard/main.yaml');

      // 1. Absolute import `/layouts/base.yaml` resolved correctly from root
      expect(res['layout']['type'], 'scaffold');

      // 2. $override successfully overwrote the title
      expect(res['layout']['title'], 'Dashboard Overridden');

      // 3. Relative import `footer.yaml` resolved relative to `/layouts/`
      expect(res['layout']['footer']['text'], 'Copyright 2025');

      // 4. Relative import `./widgets/list.yaml` resolved to array properly
      expect(res['widgets'], isA<List>());
      expect(res['widgets'], ['Widget A', 'Widget B']);
    });

    test('Deeply nested \$merge combined with \$import', () async {
      setupMockAssets({
        'root.yaml': '''
          config:
            \$import: "base.yaml"
            \$merge:
              security:
                ssl: true
              database:
                port: 5432
        ''',
        'base.yaml': '''
          security:
            cors: "*"
            ssl: false
          database:
            host: "localhost"
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('root.yaml');

      // Base values preserved
      expect(res['config']['security']['cors'], '*');
      expect(res['config']['database']['host'], 'localhost');

      // Overwritten by $merge
      expect(res['config']['security']['ssl'], true);

      // Added by $merge
      expect(res['config']['database']['port'], 5432);
    });

    test('Complex array flattening logic with multiple sibling imports',
        () async {
      setupMockAssets({
        'composite_list.yaml': '''
          pipeline:
            - { action: "init" }
            - \$import: "middlewares.yaml"
            - { action: "process" }
            - \$import: "validators.yaml"
            - { action: "finish" }
        ''',
        'middlewares.yaml': '''
          - { action: "auth" }
          - { action: "log" }
        ''',
        'validators.yaml': '''
          - { action: "check_schema" }
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('composite_list.yaml');
      final pipeline = res['pipeline'] as List;

      expect(pipeline.length, 6);
      expect(pipeline[0]['action'], 'init');
      expect(pipeline[1]['action'], 'auth'); // Flattened from middlewares
      expect(pipeline[2]['action'], 'log'); // Flattened from middlewares
      expect(pipeline[3]['action'], 'process');
      expect(
          pipeline[4]['action'], 'check_schema'); // Flattened from validators
      expect(pipeline[5]['action'], 'finish');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 10: ERROR HANDLING & MALFORMED DATA
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Error Guards', () {
    test('Throws QuantumYamlException on malformed YAML', () async {
      setupMockAssets({
        'bad.yaml': '''
          app:
            name: "Broken
            - unclosed array
        ''' // Invalid syntax
      });

      expect(
        () async => await QuantumYamlEngine.instance.load('bad.yaml'),
        throwsA(isA<QuantumYamlException>()
            .having((e) => e.message, 'message', contains('Parse error in'))),
      );
    });

    test('Throws QuantumYamlException on missing files', () async {
      setupMockAssets({}); // Empty bundle

      expect(
        () async =>
            await QuantumYamlEngine.instance.load('does_not_exist.yaml'),
        throwsA(isA<QuantumYamlException>().having(
            (e) => e.message, 'message', contains('Failed to load asset'))),
      );
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 11: GLOBAL MODIFIERS (Apply Hooks)
  /// ════════════════════════════════════════════════════════════════════════════
  group('Global Modifiers - applyYaml*', () {
    setUp(() {
      QuantumVM.instance.store.clearCache();
      QuantumVM.instance.store.sweep('');
      QLSchemaRegistry.instance.clear();
      QJsonTemplateEngine_D.clear(); // Ensure clean slate
    });

    test('applyYamlState pushes directly to global QuantumVM.instance.store',
        () {
      final Map<String, dynamic> state = {
        'auth.user': 'Alice',
        'theme.darkMode': true,
      };

      applyYamlState(state);

      expect(QuantumVM.instance.store.get('auth.user'), 'Alice');
      expect(QuantumVM.instance.store.get('theme.darkMode'), true);
    });

    test('applyYamlSchemas registers to QLSchemaRegistry', () {
      final Map<String, dynamic> schemas = {
        'User': {
          'id': {'type': 'string'},
          'age': {'type': 'number'}
        }
      };

      applyYamlSchemas(schemas);

      final blueprint = QLSchemaRegistry.instance.getSchema('User');
      expect(blueprint, isNotNull);
      expect(blueprint!.name, 'User');
      expect(blueprint.fields.any((f) => f.name == 'id'), true);
    });

    test('applyYamlMacros registers to QJsonTemplateEngine_D', () {
      final Map<String, dynamic> macros = {
        'CustomCard': {
          'props': {'title': 'Default'},
          'ui': {'type': 'box'}
        }
      };

      applyYamlMacros(macros);

      final template = QJsonTemplateEngine_D.lookup('CustomCard');
      expect(template, isNotNull);
      expect(template!.defaultProps['title'], 'Default');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 12: CONCURRENCY, LIFECYCLE & CACHE SWEEPING
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Warm-up & Cache Lifecycle', () {
    test('warmAll processes parallel requests smoothly', () async {
      setupMockAssets({
        'a.yaml': 'id: "A"',
        'b.yaml': 'id: "B"',
        'c.yaml': 'id: "C"',
        'd.yaml': 'id: "D"',
      });

      await QuantumYamlEngine.instance
          .warmAll(['a.yaml', 'b.yaml', 'c.yaml', 'd.yaml']);

      // Because they are warmed, subsequent loads should be instant cache hits
      final resA = await QuantumYamlEngine.instance.load('a.yaml');
      final resD = await QuantumYamlEngine.instance.load('d.yaml');

      expect(resA['id'], 'A');
      expect(resD['id'], 'D');
    });

    test('Clear caches actually frees memory', () async {
      setupMockAssets(
          {'heavy.yaml': 'data: "${List.filled(1000, 'X').join()}"'});

      await QuantumYamlEngine.instance.load('heavy.yaml');

      // We don't test exact private weight properties directly, but we can
      // observe the behavior of clearCaches making subsequent loads fetch anew.
      QuantumYamlEngine.instance.clearCaches();

      setupMockAssets({'heavy.yaml': 'data: "Light"'});

      // Must be 'Light', proving the cache was genuinely swept
      final res = await QuantumYamlEngine.instance.load('heavy.yaml');
      expect(res['data'], 'Light');
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 13: DIAMOND DEPENDENCIES VS. CIRCULAR DEPENDENCIES
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Diamond Dependency Graphing', () {
    test(
        'Diamond dependencies are perfectly valid and do not trigger circular errors',
        () async {
      // Graph: A imports B and C. Both B and C import D.
      // This is a diamond shape, NOT a circle. It must succeed.
      setupMockAssets({
        'a.yaml': '''
          left: 
            \$import: "b.yaml"
          right: 
            \$import: "c.yaml"
        ''',
        'b.yaml': '''
          b_val: 1
          shared: 
            \$import: "d.yaml"
        ''',
        'c.yaml': '''
          c_val: 2
          shared: 
            \$import: "d.yaml"
        ''',
        'd.yaml': '''
          core: "engine"
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('a.yaml');

      expect(res['left']['b_val'], 1);
      expect(res['left']['shared']['core'], 'engine');
      expect(res['right']['c_val'], 2);
      expect(res['right']['shared']['core'], 'engine');
    });

    test('Self-referential circular import is caught immediately', () async {
      setupMockAssets({
        'self.yaml': '''
          data:
            \$import: "self.yaml"
        ''',
      });

      expect(
        () async => await QuantumYamlEngine.instance.load('self.yaml'),
        throwsA(isA<QuantumYamlException>().having(
            (e) => e.message, 'msg', contains('Circular import detected'))),
      );
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 14: STRICT OVERRIDE VS MERGE SEMANTICS
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Strict Merge/Override Logic', () {
    test(
        '\$merge does NOT concatenate arrays, it replaces them, but deep-merges Maps',
        () async {
      setupMockAssets({
        'main.yaml': '''
          ui:
            \$import: "base.yaml"
            \$merge:
              colors:
                primary: "blue"  # Merges into colors map
              padding: [16, 16]  # Replaces padding list entirely
              new_key: "added"   # Adds new key
        ''',
        'base.yaml': '''
          colors:
            primary: "red"
            secondary: "green"
          padding: [8, 8, 8, 8]
          margin: 0
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('main.yaml');
      final ui = res['ui'];

      // Deep map merged
      expect(ui['colors']['primary'], 'blue');
      expect(ui['colors']['secondary'], 'green');

      // List replaced (Dart Map.addAll semantics)
      expect(ui['padding'], [16, 16]);

      // Untouched base primitives
      expect(ui['margin'], 0);

      // Newly added keys
      expect(ui['new_key'], 'added');
    });

    test('\$override annihilates existing keys at the top level', () async {
      setupMockAssets({
        'main.yaml': '''
          ui:
            \$import: "base.yaml"
            \$override:
              colors:
                primary: "blue"
        ''',
        'base.yaml': '''
          colors:
            primary: "red"
            secondary: "green"
          margin: 0
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('main.yaml');
      final ui = res['ui'];

      // $override replaces the ENTIRE 'colors' map, wiping out 'secondary'
      expect(ui['colors']['primary'], 'blue');
      expect(ui['colors']['secondary'], isNull);

      // It does NOT touch keys outside the override block
      expect(ui['margin'], 0);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 15: TYPE CONVERSIONS AND _ROOT WRAPPERS
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Root Value Wrapping', () {
    test('Loading a pure scalar string wraps it in {"_root": ...}', () async {
      setupMockAssets({
        'scalar.yaml': '''
          "Just a random string"
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('scalar.yaml');
      expect(res.containsKey('_root'), true);
      expect(res['_root'], 'Just a random string');
    });

    test('Loading a pure array wraps it in {"_root": ...}', () async {
      setupMockAssets({
        'array.yaml': '''
          - 1
          - 2
          - 3
        ''',
      });

      final res = await QuantumYamlEngine.instance.load('array.yaml');
      expect(res.containsKey('_root'), true);
      expect(res['_root'], [1, 2, 3]);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 16: PATH RESOLUTION & NORMALIZATION TRAVERSAL
  /// ════════════════════════════════════════════════════════════════════════════
  group('QuantumYamlEngine - Path Normalization Engine', () {
    test('Traversing up directories using `..` resolves correctly', () async {
      setupMockAssets({
        'modules/admin/views/dashboard.yaml': '''
          settings:
            \$import: "../../shared/settings.yaml"
        ''',
        'modules/shared/settings.yaml': '''
          theme: "dark"
        ''',
      });

      final res = await QuantumYamlEngine.instance
          .load('modules/admin/views/dashboard.yaml');
      expect(res['settings']['theme'], 'dark');
    });

    test('Absolute imports via `/` jump directly to root bundle', () async {
      setupMockAssets({
        'deep/nested/folder/file.yaml': '''
          config:
            \$import: "/global_config.yaml"
        ''',
        'global_config.yaml': '''
          isGlobal: true
        ''',
      });

      final res =
          await QuantumYamlEngine.instance.load('deep/nested/folder/file.yaml');
      expect(res['config']['isGlobal'], true);
    });

    test(
        'Missing extensions automatically append .yaml but prefer exact matches',
        () async {
      setupMockAssets({
        'data.json': '{"key": "json"}',
        'config':
            'key: "raw"', // Even without extension, it shouldn't crash if it tries to load
      });

      final resJson = await QuantumYamlEngine.instance.load('data.json');
      expect(resJson['key'], 'json');

      // Tests the `_normalise()` appending `.yaml`
      expect(
        () async => await QuantumYamlEngine.instance.load('missing_file'),
        throwsA(isA<QuantumYamlException>()
            .having((e) => e.sourcePath, 'path', 'missing_file.yaml')),
      );
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 17: EXTREME RESILIENCE IN QLYamlConfig EXTRACTORS
  /// ════════════════════════════════════════════════════════════════════════════
  group('QLYamlConfig - Failsafe Type Cast Resilience', () {
    final Map<String, dynamic> chaosMap = {
      'bad_list': 'this is a string, not a list',
      'bad_map': ['this', 'is', 'an', 'array'],
      'bad_int': {'obj': true},
      'bad_bool': 99.9,
      'weird_bool_string': '  oN ', // Custom truthy value
    };

    test('Extracting List from a String safely wraps it in a single-item array',
        () {
      final res = QLYamlConfig.list(chaosMap, 'bad_list');
      expect(res, ['this is a string, not a list']);
    });

    test('Extracting Map from an Array safely triggers the fallback', () {
      final res =
          QLYamlConfig.map(chaosMap, 'bad_map', fallback: {'safe': true});
      expect(res['safe'], true);
    });

    test('Extracting Int from an Object safely triggers the fallback', () {
      final res = QLYamlConfig.integer(chaosMap, 'bad_int', fallback: -1);
      expect(res, -1);
    });

    test('Extracting Boolean from a Double safely triggers the fallback', () {
      final res = QLYamlConfig.boolean(chaosMap, 'bad_bool', fallback: true);
      expect(res,
          true); // double doesn't match 'true', '1', 'yes', so it falls back
    });

    test(
        'Extracting Boolean from unusual truthy string works (on/off, yes/no, 1/0)',
        () {
      expect(QLYamlConfig.boolean({'k': 'yes'}, 'k'), true);
      expect(QLYamlConfig.boolean({'k': '1'}, 'k'), true);
      expect(QLYamlConfig.boolean({'k': 'on'}, 'k'), true);
      expect(QLYamlConfig.boolean({'k': 'no'}, 'k'), false);
      expect(QLYamlConfig.boolean({'k': '0'}, 'k'), false);
      expect(QLYamlConfig.boolean({'k': 'off'}, 'k'), false);
    });
  });

  /// ════════════════════════════════════════════════════════════════════════════
  /// GROUP 18: FULL END-TO-END PRODUCTION APP.YAML SIMULATION
  /// ════════════════════════════════════════════════════════════════════════════
  group('Full E2E Config Parsing', () {
    test(
        'Parses a massive, enterprise-grade APP.yaml accurately into QLAppYamlConfig',
        () async {
      final String enterpriseAppYaml = '''
      app:
        name: "EnterpriseApp"
        title: "Global Dashboard"
        locale: "fr-FR"
        version: "3.14.15"

      theme:
        mode: "dark"
        colors:
          primary: "#FF5500"

      router:
        initialRoute: "/auth/login"
        pagesDir: "src/views"
        notFound: "src/views/errors/404.yaml"
        transition: "fade"
        transitionMs: 250
        globalGuards:
          - type: "redirect"
            condition: "state.isAuthenticated"
            to: "/dashboard"

      vm:
        workerThreads: 16
        simdArenaCapacity: 16384

      telemetry:
        enabled: true
        frameMonitor: false

      sdui:
        replayGuardMaxAgeSeconds: 3600
        keys:
          - kid: "prod-key-1"
            aesKey: "base64aes=="
            sigKey: "base64sig=="
            active: true

      domains:
        - name: "payments"
          state:
            currency: "EUR"
        - name: "catalog"

      state:
        globalConfigLoaded: true

      macros:
        Button:
          type: "action:button"

      schemas:
        User:
          id: string
      ''';

      final parsedRaw =
          await QuantumYamlEngine.instance.parseString(enterpriseAppYaml);
      final config = QLAppYamlConfig.fromMap(parsedRaw);

      // Verify App Block
      expect(config.appName, 'EnterpriseApp');
      expect(config.title, 'Global Dashboard');
      expect(config.locale, 'fr-FR');
      expect(config.version, '3.14.15');

      // Verify Router Block
      expect(config.initialRoute, '/auth/login');
      expect(config.pagesDir, 'src/views');
      expect(config.notFoundPage, 'src/views/errors/404.yaml');
      expect(config.globalGuards.length, 1);
      expect(config.globalGuards[0]['type'], 'redirect');

      // Verify VM Block
      expect(config.workerThreads, 16);
      expect(config.simdArenaCapacity, 16384);

      // Verify Telemetry Block
      expect(config.telemetryEnabled, true);
      expect(config.frameMonitor, false);

      // Verify Domains & SDUI
      expect(config.domains.length, 2);
      expect(config.domains[0]['name'], 'payments');
      expect(config.domains[0]['state']['currency'], 'EUR');

      expect(config.sdui['replayGuardMaxAgeSeconds'], 3600);
      expect((config.sdui['keys'] as List).length, 1);
      expect(config.sdui['keys'][0]['kid'], 'prod-key-1');

      // Verify Globals
      expect(config.state['globalConfigLoaded'], true);
      expect(config.macros['Button']['type'], 'action:button');
      expect(config.schemas['User']['id'], 'string');
    });

    test(
        'Parses a massive, enterprise-grade PAGE.yaml accurately into QLPageYamlConfig',
        () async {
      final String pageYaml = '''
      type: "modal"
      
      meta:
        title: "Checkout - {{env.BRAND}}"
        description: "Secure payment gateway"
        keywords: "checkout, pay"
        ogImage: "https://cdn.example.com/og.png"
        custom:
          robots: "noindex, nofollow"

      route:
        urlPattern: "^/checkout/(?<cartId>[a-zA-Z0-9]+)\$"
        captureGroups: ["cartId"]
        transition: "slideUp"
        transitionMs: 400

      serverProps:
        action: "api.checkout.init"
        
      staticPaths:
        - "/checkout/demo1"
        - "/checkout/demo2"

      state:
        paymentMethod: "card"

      ui:
        type: "box:col"
        children:
          - type: "text:h1"
            props: { text: "Complete Payment" }
      ''';

      QLYamlEnv.set('BRAND', 'Quantum Corp');
      final parsedRaw = await QuantumYamlEngine.instance.parseString(pageYaml);
      final config = QLPageYamlConfig.fromMap(parsedRaw);

      // Semantic Types
      expect(config.semanticType, QLYamlSemanticType.modal);

      // Meta Data (with Interpolation!)
      expect(config.metaTitle, 'Checkout - Quantum Corp');
      expect(config.metaDescription, 'Secure payment gateway');
      expect(config.metaKeywords, 'checkout, pay');
      expect(config.metaOgImage, 'https://cdn.example.com/og.png');
      expect(config.customMeta['robots'], 'noindex, nofollow');

      // Routing
      expect(config.urlPattern, r'^/checkout/(?<cartId>[a-zA-Z0-9]+)$');
      expect(config.captureGroups, ['cartId']);
      expect(config.transition, 'slideUp');
      expect(config.transitionDurationMs, 400);

      // Next.js style props
      expect(config.serverProps!['action'], 'api.checkout.init');
      expect(config.staticPaths, ['/checkout/demo1', '/checkout/demo2']);

      // Internal State
      expect(config.state['paymentMethod'], 'card');

      // AST mapping
      expect(config.ui['type'], 'box:col');
      expect(config.ui['children'][0]['type'], 'text:h1');
    });
  });
}
