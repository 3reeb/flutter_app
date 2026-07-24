import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

Widget _wrapQuantum(
  Widget child, {
  QLDataStore? store,
  Map<String, dynamic> env = const <String, dynamic>{},
}) {
  final QLDataStore effectiveStore = store ??
      QLDataStore(namespace: 'test_${DateTime.now().microsecondsSinceEpoch}');

  return QuantumVMRoot(
    workerThreads: 1,
    child: MaterialApp(
      home: QLDataScope(
        localData: env,
        localStore: effectiveStore,
        child: child,
      ),
    ),
  );
}

Widget _renderNode(
  QLBlueprint node, {
  QLDataStore? store,
  Map<String, dynamic> env = const <String, dynamic>{},
}) {
  return _wrapQuantum(
    Builder(
      builder: (context) => QuantumVM.instance.renderWidget(context, node),
    ),
    store: store,
    env: env,
  );
}

Widget _renderTemplate(
  TemplateDef def,
  QLBlueprint node, {
  QLDataStore? store,
  Map<String, dynamic> env = const <String, dynamic>{},
  String instanceId = 'tpl_test',
}) {
  return _wrapQuantum(
    Builder(
      builder: (context) {
        final qlContext = QLContext(
          context,
          node,
          QLDataScope.of(context),
          QLDataScope.resolveStore(context),
        );
        final templateContext = QTemplateContext(qlContext, def, instanceId);
        if (def.nativeBuilder == null) {
          return const SizedBox.shrink();
        }
        return def.nativeBuilder!(templateContext);
      },
    ),
    store: store,
    env: env,
  );
}

Map<String, dynamic> _textNode(String text) => <String, dynamic>{
      'type': 'text:p',
      'props': <String, dynamic>{'text': text},
    };

Map<String, dynamic> _slotNode(String type, String text) => <String, dynamic>{
      'type': type,
      'props': <String, dynamic>{'text': text},
    };

void main() {
  setUp(() {
    QuantumComponentRegistry.instance.clear();
    QTemplateEngine.clear();
    clearQuantumInputRegistry();
    QuantumVM.instance.clearRuntimeCaches();
    registerOmniComponents(QuantumVM.instance);
  });

  group('template_core', () {
    test('registerOmniComponents exposes the expected template aliases', () {
      final aliasNames = QuantumVM.instance
          .registryEntries(kind: 'alias', query: 'template')
          .map((e) => e.name)
          .toSet();

      expect(
          aliasNames,
          containsAll(<String>{
            'menu',
            'menu_item',
            'list',
            'table',
            'surface_shell',
            'rich_shell',
            'item_shell',
            'cluster_shell',
            'tabs_shell',
            'carousel_shell',
            'canvas_shell',
            'search_shell',
            'data_shell',
            'wizard',
            'empty_state',
          }));

      expect(QTemplateEngine.getDef('surface_shell'), isNotNull);
      expect(QTemplateEngine.getDef('rich_shell'), isNotNull);
      expect(QTemplateEngine.getDef('item_shell'), isNotNull);
      expect(QTemplateEngine.getDef('cluster_shell'), isNotNull);
    });

    test('define rejects empty aliases and frozen mutations are blocked', () {
      expect(
        () => QTemplateEngine.define(''),
        throwsA(isA<ArgumentError>()),
      );

      try {
        QTemplateEngine.freeze();
        expect(
          () => QTemplateEngine.define(
            'freeze_guard',
            defaultSlots: <String, dynamic>{'body': _textNode('blocked')},
          ),
          throwsA(isA<StateError>()),
        );
      } finally {
        QTemplateEngine.unfreeze();
      }

      QTemplateEngine.define(
        'freeze_guard',
        defaultSlots: <String, dynamic>{'body': _textNode('allowed')},
      );
      expect(QTemplateEngine.getDef('freeze_guard'), isNotNull);
    });

    test('resolves inheritance and honors mergeWithBase=false replacement', () {
      QTemplateEngine.define(
        'template_parent_unit',
        defaultSlots: <String, dynamic>{
          'header': _textNode('parent header'),
          'body': _textNode('parent body'),
        },
        variants: <String, Map<String, dynamic>>{
          'density': <String, dynamic>{
            'compact': <String, dynamic>{'body': 'gap-2'},
          },
        },
        nativeBuilder: (ctx) => ctx.buildLayout(),
      );

      QTemplateEngine.define(
        'template_child_unit',
        extendsAlias: 'template_parent_unit',
        defaultSlots: <String, dynamic>{
          'footer': _textNode('child footer'),
        },
        transforms: <String, dynamic>{'body': 'bg-red-100'},
        nativeBuilder: (ctx) => ctx.buildLayout(),
      );

      final TemplateDef? child = QTemplateEngine.getDef('template_child_unit');
      expect(child, isNotNull);
      expect(
          child!.defaultSlots.keys,
          containsAll(<String>[
            'header',
            'body',
            'footer',
          ]));
      expect(child.transforms['body'], 'bg-red-100');
      expect(child.variants['density'], isNotNull);
      expect(child.variants['density']!['compact'], isNotNull);

      QTemplateEngine.define(
        'template_replacement_unit',
        extendsAlias: 'template_parent_unit',
        mergeWithBase: false,
        defaultSlots: <String, dynamic>{
          'only': _textNode('replacement only'),
        },
        nativeBuilder: (ctx) => ctx.buildLayout(),
      );

      final TemplateDef? replacement =
          QTemplateEngine.getDef('template_replacement_unit');
      expect(replacement, isNotNull);
      expect(replacement!.defaultSlots.keys, contains('only'));
      expect(replacement.defaultSlots.keys, isNot(contains('header')));
      expect(replacement.defaultSlots.keys, isNot(contains('body')));
    });

    test('circular inheritance resolves safely without infinite recursion', () {
      QTemplateEngine.define(
        'template_cycle_a',
        extendsAlias: 'template_cycle_b',
        defaultSlots: <String, dynamic>{'a': _textNode('A')},
        nativeBuilder: (ctx) => ctx.buildLayout(),
      );
      QTemplateEngine.define(
        'template_cycle_b',
        extendsAlias: 'template_cycle_a',
        defaultSlots: <String, dynamic>{'b': _textNode('B')},
        nativeBuilder: (ctx) => ctx.buildLayout(),
      );

      final TemplateDef? a = QTemplateEngine.getDef('template_cycle_a');
      final TemplateDef? b = QTemplateEngine.getDef('template_cycle_b');

      expect(a, isNotNull);
      expect(b, isNotNull);
      final TemplateDef aDef = a!;
      final TemplateDef bDef = b!;
      expect(aDef.defaultSlots.keys, containsAll(<String>['a', 'b']));
      expect(bDef.defaultSlots.keys, contains('b'));
      expect(bDef.defaultSlots.keys, isNot(contains('a')));
    });

    testWidgets(
        'nativeBuilder renders default slots when no overrides are supplied',
        (tester) async {
      QTemplateEngine.define(
        'template_render_defaults',
        defaultSlots: <String, dynamic>{
          'header': _textNode('default header'),
          'body': _textNode('default body'),
          'footer': _textNode('default footer'),
        },
        nativeBuilder: (ctx) => ctx.buildLayout(),
      );

      final def = QTemplateEngine.getDef('template_render_defaults');
      expect(def, isNotNull);

      await tester.pumpWidget(
        _renderTemplate(
          def!,
          QLBlueprint.fromJson(
            <String, dynamic>{
              'type': 'template:template_render_defaults',
              'props': <String, dynamic>{'name': 'template_render_defaults'},
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('default header'), findsOneWidget);
      expect(find.text('default body'), findsOneWidget);
      expect(find.text('default footer'), findsOneWidget);
    });

    testWidgets('explicit slot overrides replace only the targeted slot',
        (tester) async {
      QTemplateEngine.define(
        'template_render_override',
        defaultSlots: <String, dynamic>{
          'header': _textNode('header one'),
          'body': _textNode('body one'),
          'footer': _textNode('footer one'),
        },
        nativeBuilder: (ctx) => ctx.buildLayout(),
      );

      final def = QTemplateEngine.getDef('template_render_override');
      expect(def, isNotNull);

      final node = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'template:template_render_override',
        'props': <String, dynamic>{'name': 'template_render_override'},
        'slots': <String, dynamic>{
          'body': _slotNode('text:p', 'body override'),
        },
      });

      await tester.pumpWidget(_renderTemplate(def!, node));
      await tester.pumpAndSettle();

      expect(find.text('header one'), findsOneWidget);
      expect(find.text('body override'), findsOneWidget);
      expect(find.text('footer one'), findsOneWidget);
      expect(find.text('body one'), findsNothing);
    });
  });

  group('component_core', () {
    test('registerOmniComponents exposes the component aliases', () {
      final aliasNames = QuantumVM.instance
          .registryEntries(kind: 'alias', query: 'component')
          .map((e) => e.name)
          .toSet();

      expect(
          aliasNames,
          containsAll(<String>{
            'component_use',
            'component_define',
            'component_scope',
            'component_link',
          }));
      expect(
          QuantumVM.instance
              .describeRegistryItem('component_use', kind: 'alias'),
          isNotNull);
      expect(
          QuantumVM.instance
              .describeRegistryItem('component_define', kind: 'alias'),
          isNotNull);
    });

    testWidgets(
        'component:define registers a definition and component:use renders it',
        (tester) async {
      final defineNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'profile_card',
          'description': 'Profile card for testing',
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'Defined content'},
          },
        },
      });
      final useNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'profile_card'},
      });

      await tester.pumpWidget(
        _wrapQuantum(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, defineNode),
              ),
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, useNode),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Defined content'), findsOneWidget);

      final description =
          QuantumComponentRegistry.instance.describe('profile_card');
      expect(description, isNotNull);
      expect(description!['kind'], 'component');
      expect(description['metadata'], isA<Map<String, dynamic>>());
      expect(
        (description['metadata'] as Map<String, dynamic>)['infoSchema']['name'],
        'profile_card',
      );
      expect(
        (description['metadata'] as Map<String, dynamic>)['componentSpec']
            ['name'],
        'profile_card',
      );
    });

    testWidgets('component:define with preview=true renders immediately',
        (tester) async {
      final previewNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'preview_card',
          'preview': true,
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'Preview content'},
          },
        },
      });

      await tester.pumpWidget(_renderNode(previewNode));
      await tester.pumpAndSettle();

      expect(find.text('Preview content'), findsOneWidget);
      expect(QuantumComponentRegistry.instance.describe('preview_card'),
          isNotNull);
    });

    testWidgets(
        'component:scoped and component:link both register reusable definitions',
        (tester) async {
      final scopedNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:scoped',
        'props': <String, dynamic>{
          'name': 'scoped_card',
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'Scoped content'},
          },
        },
      });
      final linkedNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:link',
        'props': <String, dynamic>{
          'name': 'linked_card',
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'Linked content'},
          },
        },
      });
      final scopedUse = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'scoped_card'},
      });
      final linkedUse = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'linked_card'},
      });

      await tester.pumpWidget(
        _wrapQuantum(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, scopedNode),
              ),
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, linkedNode),
              ),
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, scopedUse),
              ),
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, linkedUse),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scoped content'), findsOneWidget);
      expect(find.text('Linked content'), findsOneWidget);
      expect(
          QuantumComponentRegistry.instance.describe('scoped_card'), isNotNull);
      expect(
          QuantumComponentRegistry.instance.describe('linked_card'), isNotNull);
    });

    testWidgets(
        'component:use safely returns an empty widget for missing definitions',
        (tester) async {
      final missingNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'missing_component_404'},
      });

      await tester.pumpWidget(_renderNode(missingNode));
      await tester.pumpAndSettle();

      expect(find.text('missing_component_404'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets(
        'redefining the same component name replaces the active implementation',
        (tester) async {
      final firstDefine = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'swap_card',
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'First version'},
          },
        },
      });
      final secondDefine = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'swap_card',
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'Second version'},
          },
        },
      });
      final useNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'swap_card'},
      });

      await tester.pumpWidget(
        _wrapQuantum(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, firstDefine),
              ),
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, secondDefine),
              ),
              Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, useNode),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Second version'), findsOneWidget);
      expect(find.text('First version'), findsNothing);

      final description =
          QuantumComponentRegistry.instance.describe('swap_card');
      expect(description, isNotNull);
      expect(
        (description!['metadata'] as Map<String, dynamic>)['componentSpec']
            ['ui']['props']['text'],
        'Second version',
      );
    });
  });
}
