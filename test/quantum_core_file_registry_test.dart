import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

void main() {
  late QLCoreFileLoader originalLoader;
  late int loadCount;
  late Map<String, Map<String, dynamic>> fakeFiles;

  setUp(() {
    originalLoader = (path) => QuantumYamlEngine.instance.load(path);
    loadCount = 0;
    fakeFiles = {
      'macros/fade_in.yaml': {'name': 'fade_in', 'body': 'macro-body'},
      'templates/card.json': {'name': 'card', 'kind': 'template'},
      'layouts/app.yaml': {'name': 'app', 'kind': 'layout'},
      'layouts/app_override.yaml': {
        'name': 'app',
        'kind': 'layout',
        'server': true
      },
      'controls/badge.yaml': {'name': 'badge', 'kind': 'control'},
      'fields/text.yaml': {'name': 'text', 'kind': 'field'},
      'macros/nested/scale_up.yaml': {'name': 'scale_up', 'kind': 'macro'},
    };

    QLCoreFileRegistry.instance.clear();
    QLCoreFileRegistry.setLoader((assetPath) async {
      loadCount += 1;
      final resolved = fakeFiles[assetPath];
      if (resolved == null) {
        throw StateError('Missing fake asset: $assetPath');
      }
      return Map<String, dynamic>.from(resolved);
    });
  });

  tearDown(() {
    QLCoreFileRegistry.setLoader(originalLoader);
    QLCoreFileRegistry.instance.clear();
  });

  test('built-in resolution stays available unless an override exists', () {
    QLCoreFileRegistry.instance.registerBuiltIn(
      'layouts/app.yaml',
      core: 'layouts',
      typeName: 'app',
      metadata: {'origin': 'builtin'},
    );
    QLCoreFileRegistry.instance.registerOverride(
      'layouts/app_override.yaml',
      core: 'layouts',
      typeName: 'app',
      metadata: {'origin': 'server'},
    );

    final descriptor = QLCoreFileRegistry.instance.descriptor('layouts', 'app');
    expect(descriptor, isNotNull);
    expect(descriptor!.assetPath, 'layouts/app_override.yaml');
    expect(descriptor.builtIn, isFalse);
    expect(descriptor.metadata['origin'], 'server');

    final builtIns = QLCoreFileRegistry.instance.snapshot()['counts'] as Map;
    expect(builtIns['builtIns'], 1);
    expect(builtIns['overrides'], 1);
  });

  test('folder registration routes nested files to the chosen core', () {
    QLCoreFileRegistry.instance.registerFolder('macros', 'macro');
    QLCoreFileRegistry.instance.registerOverride('macros/nested/scale_up.yaml');

    final desc = QLCoreFileRegistry.instance.descriptorForPath(
      'macros/nested/scale_up.yaml',
    );
    expect(desc, isNotNull);
    expect(desc!.core, 'macro');
    expect(desc.typeName, 'scale_up');
  });

  test('descriptorByKey understands folder and core-key notation', () {
    QLCoreFileRegistry.instance.registerBuiltIn('templates/card.json');

    final byPath =
        QLCoreFileRegistry.instance.descriptorByKey('templates/card.json');
    expect(byPath, isNotNull);
    expect(byPath!.core, 'templates');
    expect(byPath.typeName, 'card');

    final byColon =
        QLCoreFileRegistry.instance.descriptorByKey('templates:card');
    expect(byColon, isNotNull);
    expect(byColon!.assetPath, 'templates/card.json');
  });

  test('resolve loads lazily and decorates the returned payload', () async {
    QLCoreFileRegistry.instance.registerBuiltIn('macros/fade_in.yaml');

    final resolved =
        await QLCoreFileRegistry.instance.resolve('macros', 'fade_in');
    expect(resolved, isNotNull);
    expect(resolved!['_core'], 'macros');
    expect(resolved['_type'], 'fade_in');
    expect(resolved['_assetPath'], 'macros/fade_in.yaml');
    expect(resolved['name'], 'fade_in');
    expect(loadCount, 1);
  });

  test('resolve reuses the cached payload on the second lookup', () async {
    QLCoreFileRegistry.instance.registerBuiltIn('templates/card.json');

    final first =
        await QLCoreFileRegistry.instance.resolve('templates', 'card');
    final second =
        await QLCoreFileRegistry.instance.resolve('templates', 'card');

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(loadCount, 1);
    expect(identical(first, second), isTrue);
  });

  test('resolve shares a single in-flight load for parallel callers', () async {
    QLCoreFileRegistry.instance.registerBuiltIn('fields/text.yaml');

    final futures = [
      QLCoreFileRegistry.instance.resolve('fields', 'text'),
      QLCoreFileRegistry.instance.resolve('fields', 'text'),
      QLCoreFileRegistry.instance.resolve('fields', 'text'),
    ];
    final results = await Future.wait(futures);

    expect(results.every((item) => item != null), isTrue);
    expect(loadCount, 1);
  });

  test('resolvePath honors nested folder assets', () async {
    QLCoreFileRegistry.instance.registerBuiltIn('macros/nested/scale_up.yaml');

    final resolved = await QLCoreFileRegistry.instance.resolvePath(
      'macros/nested/scale_up.yaml',
    );

    expect(resolved, isNotNull);
    expect(resolved!['name'], 'scale_up');
  });

  test('snapshot reports the current registry surface', () {
    QLCoreFileRegistry.instance.registerBuiltIn('macros/fade_in.yaml');
    QLCoreFileRegistry.instance.registerOverride('layouts/app_override.yaml');

    final snapshot = QLCoreFileRegistry.instance.snapshot();
    final counts = snapshot['counts'] as Map;
    expect(counts['builtIns'], 1);
    expect(counts['overrides'], 1);
    expect(snapshot['items'], isA<List>());
  });
}
