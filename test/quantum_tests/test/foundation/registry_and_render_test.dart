import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('Registry inspection and template rendering', () {
    test('tracks alias names after defineAliasJson', () {
      final alias = uniqueName('RegistryAlias');
      QuantumVM.instance.defineAliasJson({
        'alias': alias,
        'target': 'box:row',
        'defaultProps': {'gap': 6},
      });
      expect(QuantumVM.instance.registeredAliasNames, contains(alias));
      expect(QuantumVM.instance.hasAlias(alias), isTrue);
      expect(QuantumVM.instance.getAlias(alias)!['type'], 'box:row');
    });

    test('tracks plugin names after registerJsonDslPlugins', () {
      registerBasicJsonDslPlugins();
      expect(QuantumVM.instance.registeredPluginNames,
          contains('define_template'));
      expect(
          QuantumVM.instance.registeredPluginNames, contains('define_layout'));
      expect(QuantumVM.instance.registeredPluginNames, contains('define_omni'));
    });

    test('tracks template names after define', () {
      final name = uniqueName('RegistryTemplate');
      QJsonTemplateEngine_D.define({
        'name': name,
        'props': {'title': 'x'},
      });
      expect(QJsonTemplateEngine_D.registryNames, contains(name));
      expect(QJsonTemplateEngine_D.lookup(name), isNotNull);
    });

    test('tracks layout names after defineMatrixLayoutJson', () {
      final name = uniqueName('RegistryLayout');
      QuantumVM.instance.defineMatrixLayoutJson({
        'name': name,
        'matrix': 'a',
      });
      expect(QMatrixLayoutRegistry.registryNames, contains(name));
      expect(QMatrixLayoutRegistry.describe(name), isNotNull);
    });

    test('registryEntry returns alias entries by kind', () {
      final alias = uniqueName('RegistryEntryAlias');
      QuantumVM.instance.defineAliasJson({
        'alias': alias,
        'target': 'text:title',
      });
      final entry = QuantumVM.instance.registryEntry(alias, kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, alias);
    });

    test('registryEntries can filter by alias kind', () {
      final alias = uniqueName('RegistryEntriesAlias');
      QuantumVM.instance.defineAliasJson({
        'alias': alias,
        'target': 'box:col',
      });
      final entries =
          QuantumVM.instance.registryEntries(kind: 'alias', query: alias);
      expect(entries.any((e) => e.name == alias), isTrue);
    });

    testWidgets(
        'renders a template with compiled ui through QuantumVM.renderWidget',
        (tester) async {
      final name = uniqueName('RenderableTemplate');
      QJsonTemplateEngine_D.define({
        'name': name,
        'ui': {
          'type': 'col',
          'children': [
            {
              'type': 'text',
              'props': {'text': 'Rendered inner text'}
            },
          ],
        },
      });

      await pumpOverlayHarness(
        tester,
        child: QLDataScope(
          child: Builder(
            builder: (context) {
              return QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(type: name, props: const {}, children: const []),
              );
            },
          ),
        ),
      );

      expect(find.text('Rendered inner text'), findsOneWidget);
    });

    testWidgets(
        'renders a slot passthrough template when no compiled ui is present',
        (tester) async {
      final name = uniqueName('SlotTemplate');
      QJsonTemplateEngine_D.define({
        'name': name,
        'slots': ['body'],
      });

      await pumpOverlayHarness(
        tester,
        child: QLDataScope(
          child: Builder(
            builder: (context) {
              return QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: name,
                  props: const {},
                  children: [textBlueprint('slot-body')],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('slot-body'), findsOneWidget);
    });

    testWidgets(
        'registerJsonDslPlugins can define a template and then render it',
        (tester) async {
      registerBasicJsonDslPlugins();
      final name = uniqueName('PluginDefinedTemplate');

      await pumpOverlayHarness(
        tester,
        child: QLDataScope(
          child: Builder(
            builder: (context) {
              return QuantumVM.instance.renderWidget(
                context,
                QLBlueprint(
                  type: 'define_template',
                  props: {
                    'name': name,
                    'ui': {
                      'type': 'text',
                      'props': {'text': 'templated'},
                    },
                  },
                  children: const [],
                ),
              );
            },
          ),
        ),
      );

      expect(QJsonTemplateEngine_D.describe(name), isNotNull);

      await tester.pumpWidget(
        QLOverlayRoot(
          child: MaterialApp(
            home: Scaffold(
              body: QLDataScope(
                child: Builder(
                  builder: (context) {
                    return QuantumVM.instance.renderWidget(
                      context,
                      QLBlueprint(
                          type: name, props: const {}, children: const []),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('templated'), findsOneWidget);
    });
  });
}
