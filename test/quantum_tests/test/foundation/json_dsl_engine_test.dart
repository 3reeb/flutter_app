import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('JSON DSL and VM registration', () {
    test('defines a template and exposes describe and snapshot data', () {
      final name = uniqueName('CardTemplate');
      QJsonTemplateEngine_D.define({
        'name': name,
        'props': {'title': '', 'count': 0},
        'slots': ['header', 'body'],
        'ui': {'type': 'col', 'children': []},
        'description': 'card template',
        'tags': ['card', 'ui'],
      });
      final description = QJsonTemplateEngine_D.describe(name)!;
      expect(description['name'], name);
      expect(description['description'], 'card template');
      expect((description['slotNames'] as List).cast<String>(),
          ['header', 'body']);
      expect((description['defaultProps'] as Map)['title'], '');
      expect((QJsonTemplateEngine_D.snapshot()['count'] as int) >= 1, isTrue);
    });
    test('uses id as the template name fallback', () {
      final name = uniqueName('IdTemplate');
      QJsonTemplateEngine_D.define({
        'id': name,
        'props': {'enabled': true},
        'ui': {
          'type': 'text',
          'props': {'text': 'hello'}
        },
      });
      expect(QJsonTemplateEngine_D.describe(name)!['name'], name);
    });
    test('accepts defaultProps and slot maps', () {
      final name = uniqueName('SlotMapTemplate');
      QJsonTemplateEngine_D.define({
        'name': name,
        'defaultProps': {'label': 'A', 'enabled': true},
        'slots': {
          'header': {
            'type': 'text',
            'props': {'text': 'h'}
          },
          'body': {
            'type': 'text',
            'props': {'text': 'b'}
          },
        },
      });
      final description = QJsonTemplateEngine_D.describe(name)!;
      expect((description['slotNames'] as List).cast<String>(),
          ['header', 'body']);
      expect((description['paramSchema'] as Map)['required'],
          ['label', 'enabled']);
    });
    test('hot swaps an existing template when the fingerprint changes', () {
      final name = uniqueName('HotSwapTemplate');
      QJsonTemplateEngine_D.define({'name': name, 'description': 'v1'});
      QJsonTemplateEngine_D.define({
        'name': name,
        'description': 'v2',
        'tags': ['updated']
      });
      final description = QJsonTemplateEngine_D.describe(name)!;
      expect(description['description'], 'v2');
      expect((description['tags'] as List).cast<String>(), ['updated']);
    });
    test('keeps the registry stable for identical fingerprints', () {
      final name = uniqueName('FingerprintTemplate');
      final json = {
        'name': name,
        'props': {'value': 1}
      };
      QJsonTemplateEngine_D.define(json);
      final before = QJsonTemplateEngine_D.snapshot()['count'] as int;
      QJsonTemplateEngine_D.define(json);
      final after = QJsonTemplateEngine_D.snapshot()['count'] as int;
      expect(after, before);
    });
    test('compiles the ui tree into JSON form inside describe', () {
      final name = uniqueName('CompiledTemplate');
      QJsonTemplateEngine_D.define({
        'name': name,
        'ui': {
          'type': 'col',
          'children': [
            {
              'type': 'text',
              'props': {'text': 'inner'}
            }
          ],
        },
      });
      final description = QJsonTemplateEngine_D.describe(name)!;
      expect((description['compiledUi'] as Map)['type'], 'col');
    });
    test('defines a matrix layout from ASCII grid JSON', () {
      final name = uniqueName('LayoutA');
      QuantumVM.instance.defineMatrixLayoutJson({
        'name': name,
        'gap': 8,
        'matrix': 'nav main\nnav footer',
        'variants': {'mobile': 'nav\nmain\nfooter'},
        'slots': {
          'nav': {'scrollable': false, 'zIndex': 10},
          'main': {'scrollable': true},
          'footer': {'floating': false},
        },
      });
      final description = QMatrixLayoutRegistry.describe(name)!;
      expect(description['kind'], 'layout');
      expect(description['infoSchema']['name'], name);
      expect((description['params']['variants'] as List).cast<String>(),
          ['mobile']);
      expect((description['slotConfigs'] as Map).keys,
          containsAll(['nav', 'main', 'footer']));
    });
    test('uses id as the layout name fallback', () {
      final name = uniqueName('LayoutId');
      QuantumVM.instance.defineMatrixLayoutJson({'id': name, 'matrix': 'a'});
      expect(QMatrixLayoutRegistry.has(name), isTrue);
    });
    test('defines an alias with default props and metadata', () {
      final alias = uniqueName('AliasA');
      QuantumVM.instance.defineAliasJson({
        'alias': alias,
        'target': 'text:title',
        'defaultProps': {'text': 'Hello'},
        'metadata': {'group': 'text'},
      });
      final entry = QuantumVM.instance.getAlias(alias)!;
      expect(entry['type'], 'text:title');
      expect((entry['props'] as Map)['text'], 'Hello');
      expect(QuantumVM.instance.hasAlias(alias), isTrue);
    });
    test('defines aliases from a mixed alias map', () {
      final directAlias = uniqueName('AliasDirect');
      final mappedAlias = uniqueName('AliasMapped');
      QuantumVM.instance.defineAliasesJson({
        directAlias: 'box:row',
        mappedAlias: {
          'target': 'box:col',
          'defaultProps': {'gap': 12},
        },
      });
      expect(QuantumVM.instance.getAlias(directAlias)!['type'], 'box:row');
      expect((QuantumVM.instance.getAlias(mappedAlias)!['props'] as Map)['gap'],
          12);
    });
    test('defines a decoration alias from JSON', () {
      final alias = uniqueName('DecorationA');
      QuantumVM.instance.defineDecorationJson({
        'alias': alias,
        'target': 'decoration:merge',
        'props': {'mode': 'soft'},
      });
      expect(QuantumVM.instance.hasAlias(alias), isTrue);
      expect(QuantumVM.instance.getAlias(alias)!['type'], 'decoration:merge');
    });
    test('registers JSON DSL plugins', () {
      registerBasicJsonDslPlugins();
      expect(QuantumVM.instance.hasPlugin('define_template'), isTrue);
      expect(QuantumVM.instance.hasPlugin('define_layout'), isTrue);
      expect(QuantumVM.instance.hasPlugin('define_alias'), isTrue);
      expect(QuantumVM.instance.hasPlugin('define_decoration'), isTrue);
      expect(QuantumVM.instance.hasPlugin('define_omni'), isTrue);
      expect(QuantumVM.instance.hasPlugin('define_design_system'), isTrue);
    });
    testWidgets('define_template plugin renders its child unchanged',
        (tester) async {
      registerBasicJsonDslPlugins();
      final templateName = uniqueName('PluginTemplate');
      await pumpOverlayHarness(tester,
          child: QLDataScope(
            child: Builder(
              builder: (context) => QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: 'define_template',
                  props: {
                    'name': templateName,
                    'ui': {
                      'type': 'text',
                      'props': {'text': 'inner'}
                    }
                  },
                  children: [textBlueprint('child-output')],
                ),
              ),
            ),
          ));
      expect(find.text('child-output'), findsOneWidget);
      expect(QJsonTemplateEngine_D.describe(templateName), isNotNull);
    });
    testWidgets(
        'define_alias plugin registers the alias and returns its single child',
        (tester) async {
      registerBasicJsonDslPlugins();
      final alias = uniqueName('PluginAlias');
      await pumpOverlayHarness(tester,
          child: QLDataScope(
            child: Builder(
              builder: (context) => QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: 'define_alias',
                  props: {
                    'alias': alias,
                    'target': 'box:row',
                    'defaultProps': {'gap': 4}
                  },
                  children: [textBlueprint('alias-child')],
                ),
              ),
            ),
          ));
      expect(find.text('alias-child'), findsOneWidget);
      expect(QuantumVM.instance.hasAlias(alias), isTrue);
    });
    testWidgets(
        'define_layout plugin registers a layout and returns its single child',
        (tester) async {
      registerBasicJsonDslPlugins();
      final name = uniqueName('PluginLayout');
      await pumpOverlayHarness(tester,
          child: QLDataScope(
            child: Builder(
              builder: (context) => QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: 'define_layout',
                  props: {'name': name, 'matrix': 'a', 'slots': {}},
                  children: [textBlueprint('layout-child')],
                ),
              ),
            ),
          ));
      expect(find.text('layout-child'), findsOneWidget);
      expect(QMatrixLayoutRegistry.has(name), isTrue);
    });
    testWidgets('define_decoration plugin registers a decoration alias',
        (tester) async {
      registerBasicJsonDslPlugins();
      final alias = uniqueName('PluginDecoration');
      await pumpOverlayHarness(tester,
          child: QLDataScope(
            child: Builder(
              builder: (context) => QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: 'define_decoration',
                  props: {'alias': alias, 'target': 'decoration:merge'},
                  children: [textBlueprint('decoration-child')],
                ),
              ),
            ),
          ));
      expect(find.text('decoration-child'), findsOneWidget);
      expect(QuantumVM.instance.hasAlias(alias), isTrue);
    });
    testWidgets(
        'define_omni plugin can register multiple sections from one JSON blob',
        (tester) async {
      registerBasicJsonDslPlugins();
      final templateName = uniqueName('OmniTemplate');
      final layoutName = uniqueName('OmniLayout');
      final aliasName = uniqueName('OmniAlias');
      await pumpOverlayHarness(tester,
          child: QLDataScope(
            child: Builder(
              builder: (context) => QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: 'define_omni',
                  props: {
                    'aliases': {
                      aliasName: {'target': 'box:row'}
                    },
                    'templates': {
                      templateName: {
                        'ui': {
                          'type': 'text',
                          'props': {'text': 't'}
                        }
                      }
                    },
                    'layouts': {
                      layoutName: {'matrix': 'a'}
                    },
                  },
                  children: [textBlueprint('omni-child')],
                ),
              ),
            ),
          ));
      expect(find.text('omni-child'), findsOneWidget);
      expect(QuantumVM.instance.hasAlias(aliasName), isTrue);
      expect(QJsonTemplateEngine_D.describe(templateName), isNotNull);
      expect(QMatrixLayoutRegistry.has(layoutName), isTrue);
    });
    testWidgets(
        'define_all auto-detects templates and layouts without explicit types',
        (tester) async {
      final templateName = uniqueName('AutoTemplate');
      final layoutName = uniqueName('AutoLayout');
      QJsonDSL.defineAll([
        {
          'name': templateName,
          'ui': {
            'type': 'text',
            'props': {'text': 'auto'}
          }
        },
        {'name': layoutName, 'matrix': 'a'},
      ]);
      expect(QJsonTemplateEngine_D.describe(templateName), isNotNull);
      expect(QMatrixLayoutRegistry.has(layoutName), isTrue);
    });
    testWidgets('define_all plugin returns a column for multiple children',
        (tester) async {
      registerBasicJsonDslPlugins();
      await pumpOverlayHarness(tester,
          child: QLDataScope(
            child: Builder(
              builder: (context) => QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: 'define_all',
                  props: {'aliases': {}, 'templates': {}, 'layouts': {}},
                  children: [textBlueprint('one'), textBlueprint('two')],
                ),
              ),
            ),
          ));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });
    testWidgets('define_all plugin returns SizedBox when there are no children',
        (tester) async {
      registerBasicJsonDslPlugins();
      await pumpOverlayHarness(tester,
          child: QLDataScope(
            child: Builder(
              builder: (context) => QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                    type: 'define_all', props: const {}, children: const []),
              ),
            ),
          ));
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
