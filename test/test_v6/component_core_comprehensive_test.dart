import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

Widget _wrapQuantum(
  Widget child, {
  QLDataStore? store,
  Map<String, dynamic> env = const <String, dynamic>{},
}) {
  final QLDataStore effectiveStore = store ??
      QLStoreRegistry.instance
          .get('test_${DateTime.now().microsecondsSinceEpoch}');

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

Future<void> _pumpDefineAndUse(
  WidgetTester tester, {
  required Map<String, dynamic> defineJson,
  required Map<String, dynamic> useJson,
  Map<String, dynamic> env = const <String, dynamic>{},
}) async {
  await tester.pumpWidget(
    _wrapQuantum(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Builder(
            builder: (context) => QuantumVM.instance.renderWidget(
              context,
              QLBlueprint.fromJson(defineJson),
            ),
          ),
          Builder(
            builder: (context) => QuantumVM.instance.renderWidget(
              context,
              QLBlueprint.fromJson(useJson),
            ),
          ),
        ],
      ),
      env: env,
    ),
  );
}

Map<String, dynamic> _textNode(String text) => <String, dynamic>{
      'type': 'text:p',
      'props': <String, dynamic>{'text': text},
    };

void _registerCounterAction(String actionName, String counterKey) {
  QuantumVM.instance.registerAction(
    actionName,
    LambdaActionPlugin((payload, store, ctx) async {
      final QLDataStore defaultStore = QLStoreRegistry.instance.defaultStore;
      final int next = (defaultStore.get(counterKey) as int? ?? 0) + 1;
      defaultStore.set(counterKey, next);
      defaultStore.set('${counterKey}_lastPayload', payload);
      return next;
    }),
    description: 'Counter action for component_core tests',
    tags: const <String>['test', 'component'],
  );
}

void main() {
  setUp(() {
    QLStoreRegistry.instance.clearAll();
    QuantumComponentRegistry.instance.clear();
    QuantumVM.instance.clearRuntimeCaches();
    registerOmniComponents(QuantumVM.instance);
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
        }),
      );
      expect(
        QuantumVM.instance.describeRegistryItem('component_use', kind: 'alias'),
        isNotNull,
      );
      expect(
        QuantumVM.instance
            .describeRegistryItem('component_define', kind: 'alias'),
        isNotNull,
      );
    });

    testWidgets(
        'component:define renders immediately when render=true and publishes schema metadata',
        (tester) async {
      final defineNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_render_now',
          'render': true,
          'description': 'Immediate render smoke',
          'props': <String, dynamic>{
            'title': 'base-title',
            'count': 0,
            'enabled': false,
          },
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{
              'text':
                  'title={{props.title}}|count={{props.count}}|enabled={{props.enabled}}',
            },
          },
          'slots': <String, dynamic>{
            'header': _textNode('header slot'),
            'body': _textNode('body slot'),
          },
        },
      });

      await tester.pumpWidget(_renderNode(defineNode));
      await tester.pumpAndSettle();

      expect(
        find.text('title=base-title|count=0|enabled=false'),
        findsOneWidget,
      );

      final Map<String, dynamic>? described =
          QuantumComponentRegistry.instance.describe('component_render_now');
      expect(described, isNotNull);
      expect(described!['kind'], 'component');
      expect(described['name'], 'component_render_now');

      final Map<String, dynamic> params =
          Map<String, dynamic>.from(described['params'] as Map);
      final Map<String, dynamic> properties =
          Map<String, dynamic>.from(params['properties'] as Map);

      expect(params['type'], 'object');
      expect(params['required'],
          containsAll(<String>['title', 'count', 'enabled']));
      expect(properties['title']['type'], 'String');
      expect(properties['count']['type'], 'int');
      expect(properties['enabled']['type'], 'bool');

      final Map<String, dynamic> metadata =
          Map<String, dynamic>.from(described['metadata'] as Map);
      final Map<String, dynamic> infoSchema =
          Map<String, dynamic>.from(metadata['infoSchema'] as Map);
      expect(infoSchema['name'], 'component_render_now');
      expect(infoSchema['kind'], 'component');
      expect(infoSchema['slotNames'], containsAll(<String>['header', 'body']));

      final Map<String, dynamic> componentSpec =
          Map<String, dynamic>.from(metadata['componentSpec'] as Map);
      expect(componentSpec['name'], 'component_render_now');
      expect(componentSpec['description'], 'Immediate render smoke');
    });

    testWidgets(
        'component:define stays hidden without preview/render but remains reusable',
        (tester) async {
      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_hidden_definition',
          'props': <String, dynamic>{'label': 'base-label'},
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'label={{props.label}}'},
          },
        },
      };
      final useJson = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'component_hidden_definition'},
      };

      await _pumpDefineAndUse(tester, defineJson: defineJson, useJson: useJson);
      await tester.pumpAndSettle();

      expect(find.text('label=base-label'), findsOneWidget);
      expect(
          QuantumComponentRegistry.instance
              .describe('component_hidden_definition'),
          isNotNull);
    });

    testWidgets('component:use resolves name and component shorthand equally',
        (tester) async {
      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_shorthand_target',
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'Reusable target'},
          },
        },
      };
      final useByName = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'component_shorthand_target'},
      };
      final useByComponent = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'component': 'component_shorthand_target'},
      };

      await tester.pumpWidget(
        _wrapQuantum(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(defineJson),
                ),
              ),
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(useByName),
                ),
              ),
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(useByComponent),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reusable target'), findsNWidgets(2));
    });

    testWidgets(
        'anonymous inline component:use renders without registering a reusable component',
        (tester) async {
      final int registryCountBefore = QuantumComponentRegistry.instance.count;
      final inlineNode = QLBlueprint.fromJson(<String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'Anonymous inline content'},
          },
        },
      });

      await tester.pumpWidget(_renderNode(inlineNode));
      await tester.pumpAndSettle();

      expect(find.text('Anonymous inline content'), findsOneWidget);
      expect(QuantumComponentRegistry.instance.count, registryCountBefore);
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

      expect(tester.takeException(), isNull);
      expect(find.text('missing_component_404'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets(
        'component definitions fall back to children when ui is omitted',
        (tester) async {
      final singleDefine = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_single_child_fallback',
        },
        'children': <Map<String, dynamic>>[
          _textNode('single child fallback'),
        ],
      };
      final singleUse = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'component_single_child_fallback'},
      };

      final multiDefine = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_multi_child_fallback',
        },
        'children': <Map<String, dynamic>>[
          _textNode('multi child one'),
          _textNode('multi child two'),
        ],
      };
      final multiUse = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'component_multi_child_fallback'},
      };

      await tester.pumpWidget(
        _wrapQuantum(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(singleDefine),
                ),
              ),
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(singleUse),
                ),
              ),
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(multiDefine),
                ),
              ),
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(multiUse),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('single child fallback'), findsOneWidget);
      expect(find.text('multi child one'), findsOneWidget);
      expect(find.text('multi child two'), findsOneWidget);
    });

    testWidgets(
        'variant precedence is deterministic across base props, node props, node variants, and definition variants',
        (tester) async {
      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_variant_matrix',
          'props': <String, dynamic>{
            'title': 'base-title',
            'tone': 'base-tone',
            'config': <String, dynamic>{
              'mode': 'base-mode',
              'nested': 'base-nested',
            },
          },
          'variants': <String, dynamic>{
            'primary': <String, dynamic>{
              'title': 'definition-primary-title',
              'tone': 'definition-primary-tone',
              'config': <String, dynamic>{
                'mode': 'definition-primary-mode',
              },
            },
          },
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{
              'text':
                  'title={{props.title}}|tone={{props.tone}}|mode={{props.config.mode}}|nested={{props.config.nested}}',
            },
          },
        },
      };

      final cases = <Map<String, dynamic>>[
        <String, dynamic>{
          'label': 'no variant uses direct props',
          'variant': null,
          'variants': <String, dynamic>{
            'primary': <String, dynamic>{
              'title': 'source-primary-title',
              'tone': 'source-primary-tone',
              'config': <String, dynamic>{
                'mode': 'source-primary-mode',
              },
            },
            'secondary': <String, dynamic>{
              'title': 'source-secondary-title',
              'tone': 'source-secondary-tone',
              'config': <String, dynamic>{
                'mode': 'source-secondary-mode',
              },
            },
            'broken': 'not-a-map',
          },
          'useProps': <String, dynamic>{
            'props': <String, dynamic>{
              'title': 'props-title',
              'tone': 'props-tone',
              'config': <String, dynamic>{
                'mode': 'props-mode',
                'nested': 'props-nested',
              },
            },
            'title': 'direct-title',
            'tone': 'direct-tone',
            'config': <String, dynamic>{
              'mode': 'direct-mode',
              'nested': 'direct-nested',
            },
          },
          'expected':
              'title=direct-title|tone=direct-tone|mode=direct-mode|nested=direct-nested',
        },
        <String, dynamic>{
          'label': 'source variants override direct props',
          'variant': 'secondary',
          'variants': <String, dynamic>{
            'primary': <String, dynamic>{
              'title': 'source-primary-title',
              'tone': 'source-primary-tone',
              'config': <String, dynamic>{
                'mode': 'source-primary-mode',
              },
            },
            'secondary': <String, dynamic>{
              'title': 'source-secondary-title',
              'tone': 'source-secondary-tone',
              'config': <String, dynamic>{
                'mode': 'source-secondary-mode',
              },
            },
            'broken': 'not-a-map',
          },
          'useProps': <String, dynamic>{
            'props': <String, dynamic>{
              'title': 'props-title',
              'tone': 'props-tone',
              'config': <String, dynamic>{
                'mode': 'props-mode',
                'nested': 'props-nested',
              },
            },
            'title': 'direct-title',
            'tone': 'direct-tone',
            'config': <String, dynamic>{
              'mode': 'direct-mode',
              'nested': 'direct-nested',
            },
          },
          'expected':
              'title=source-secondary-title|tone=source-secondary-tone|mode=source-secondary-mode|nested=',
        },
        <String, dynamic>{
          'label': 'definition variants override source variants',
          'variant': 'primary',
          'variants': <String, dynamic>{
            'primary': <String, dynamic>{
              'title': 'source-primary-title',
              'tone': 'source-primary-tone',
              'config': <String, dynamic>{
                'mode': 'source-primary-mode',
              },
            },
            'secondary': <String, dynamic>{
              'title': 'source-secondary-title',
              'tone': 'source-secondary-tone',
              'config': <String, dynamic>{
                'mode': 'source-secondary-mode',
              },
            },
            'broken': 'not-a-map',
          },
          'useProps': <String, dynamic>{
            'props': <String, dynamic>{
              'title': 'props-title',
              'tone': 'props-tone',
              'config': <String, dynamic>{
                'mode': 'props-mode',
                'nested': 'props-nested',
              },
            },
            'title': 'direct-title',
            'tone': 'direct-tone',
            'config': <String, dynamic>{
              'mode': 'direct-mode',
              'nested': 'direct-nested',
            },
          },
          'expected':
              'title=definition-primary-title|tone=definition-primary-tone|mode=definition-primary-mode|nested=',
        },
        <String, dynamic>{
          'label': 'trimmed variant strings are normalized',
          'variant': ' primary ',
          'variants': <String, dynamic>{
            'primary': <String, dynamic>{
              'title': 'source-primary-title',
              'tone': 'source-primary-tone',
              'config': <String, dynamic>{
                'mode': 'source-primary-mode',
              },
            },
            'secondary': <String, dynamic>{
              'title': 'source-secondary-title',
              'tone': 'source-secondary-tone',
              'config': <String, dynamic>{
                'mode': 'source-secondary-mode',
              },
            },
            'broken': 'not-a-map',
          },
          'useProps': <String, dynamic>{
            'props': <String, dynamic>{
              'title': 'props-title',
              'tone': 'props-tone',
              'config': <String, dynamic>{
                'mode': 'props-mode',
                'nested': 'props-nested',
              },
            },
            'title': 'direct-title',
            'tone': 'direct-tone',
            'config': <String, dynamic>{
              'mode': 'direct-mode',
              'nested': 'direct-nested',
            },
          },
          'expected':
              'title=definition-primary-title|tone=definition-primary-tone|mode=definition-primary-mode|nested=',
        },
        <String, dynamic>{
          'label': 'malformed variants are ignored safely',
          'variant': 'broken',
          'variants': <String, dynamic>{
            'primary': <String, dynamic>{
              'title': 'source-primary-title',
              'tone': 'source-primary-tone',
              'config': <String, dynamic>{
                'mode': 'source-primary-mode',
              },
            },
            'secondary': <String, dynamic>{
              'title': 'source-secondary-title',
              'tone': 'source-secondary-tone',
              'config': <String, dynamic>{
                'mode': 'source-secondary-mode',
              },
            },
            'broken': 'not-a-map',
          },
          'useProps': <String, dynamic>{
            'props': <String, dynamic>{
              'title': 'props-title',
              'tone': 'props-tone',
              'config': <String, dynamic>{
                'mode': 'props-mode',
                'nested': 'props-nested',
              },
            },
            'title': 'direct-title',
            'tone': 'direct-tone',
            'config': <String, dynamic>{
              'mode': 'direct-mode',
              'nested': 'direct-nested',
            },
          },
          'expected':
              'title=direct-title|tone=direct-tone|mode=direct-mode|nested=direct-nested',
        },
      ];

      for (final caseData in cases) {
        QLStoreRegistry.instance.clearAll();
        QuantumComponentRegistry.instance.clear();
        QuantumVM.instance.clearRuntimeCaches();
        registerOmniComponents(QuantumVM.instance);

        final Map<String, dynamic> useProps =
            Map<String, dynamic>.from(caseData['useProps'] as Map);
        final String? variant = caseData['variant'] as String?;
        if (variant != null) {
          useProps['variant'] = variant;
        }
        useProps['variants'] =
            Map<String, dynamic>.from(caseData['variants'] as Map);

        await _pumpDefineAndUse(
          tester,
          defineJson: defineJson,
          useJson: <String, dynamic>{
            'type': 'component:use',
            'props': <String, dynamic>{
              'name': 'component_variant_matrix',
              ...useProps,
            },
          },
        );
        await tester.pumpAndSettle();

        expect(
          find.text(caseData['expected'] as String),
          findsOneWidget,
          reason: caseData['label'] as String,
        );
      }
    });

    testWidgets(
        'resetState controls whether component state is preserved across rebuilds',
        (tester) async {
      _registerCounterAction(
          'component_test_state_init', 'component.test.state.init');

      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_state_reset',
          'state': <String, dynamic>{'count': 1},
          'hooks': <String, dynamic>{
            'mount': <dynamic>[
              <String, dynamic>{
                'action': 'component_test_state_init',
              },
              <String, dynamic>{
                'action': 'state.set',
                'key': 'count',
                'value': 7,
              },
            ],
          },
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'count={{state.count}}'},
          },
        },
      };

      Future<void> pumpUse(
          {required int count, required bool resetState}) async {
        await _pumpDefineAndUse(
          tester,
          defineJson: defineJson,
          useJson: <String, dynamic>{
            'type': 'component:use',
            'props': <String, dynamic>{
              'name': 'component_state_reset',
              'state': <String, dynamic>{'count': count},
              if (resetState) 'resetState': true,
            },
          },
        );
      }

      await pumpUse(count: 1, resetState: false);
      await tester.pumpAndSettle();
      expect(find.text('count=7'), findsOneWidget);
      expect(
          QLStoreRegistry.instance.defaultStore
              .get('component.test.state.init'),
          1);

      await pumpUse(count: 2, resetState: false);
      await tester.pumpAndSettle();
      expect(find.text('count=7'), findsOneWidget);

      await pumpUse(count: 3, resetState: true);
      await tester.pumpAndSettle();
      expect(find.text('count=3'), findsOneWidget);
    });

    testWidgets(
        'computed operations resolve correctly across numeric, boolean, and collection branches',
        (tester) async {
      final cases = <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'component_computed_constant',
          'state': <String, dynamic>{},
          'spec': <String, dynamic>{
            'op': 'constant',
            'args': <dynamic>['fixed'],
          },
          'expected': 'fixed',
        },
        <String, dynamic>{
          'name': 'component_computed_copy',
          'state': <String, dynamic>{'a': null, 'b': 'copied'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'copy',
            'fallback': 'fallback',
          },
          'expected': 'copied',
        },
        <String, dynamic>{
          'name': 'component_computed_concat',
          'state': <String, dynamic>{'a': 'A', 'b': 'B'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'concat',
            'args': <dynamic>['x'],
          },
          'expected': 'ABx',
        },
        <String, dynamic>{
          'name': 'component_computed_sum',
          'state': <String, dynamic>{'a': 2, 'b': 3},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'sum',
          },
          'expected': '5.0',
        },
        <String, dynamic>{
          'name': 'component_computed_product',
          'state': <String, dynamic>{'a': 2, 'b': 3},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'product',
          },
          'expected': '6.0',
        },
        <String, dynamic>{
          'name': 'component_computed_min',
          'state': <String, dynamic>{'a': 5, 'b': 1},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'min',
          },
          'expected': '1.0',
        },
        <String, dynamic>{
          'name': 'component_computed_max',
          'state': <String, dynamic>{'a': 5, 'b': 1},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'max',
          },
          'expected': '5.0',
        },
        <String, dynamic>{
          'name': 'component_computed_and',
          'state': <String, dynamic>{'a': true, 'b': false},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'and',
          },
          'expected': 'false',
        },
        <String, dynamic>{
          'name': 'component_computed_or',
          'state': <String, dynamic>{'a': false, 'b': true},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'or',
          },
          'expected': 'true',
        },
        <String, dynamic>{
          'name': 'component_computed_not',
          'state': <String, dynamic>{'a': true},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a'],
            'op': 'not',
          },
          'expected': 'false',
        },
        <String, dynamic>{
          'name': 'component_computed_eq',
          'state': <String, dynamic>{'a': 'same', 'b': 'same'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'eq',
          },
          'expected': 'true',
        },
        <String, dynamic>{
          'name': 'component_computed_neq',
          'state': <String, dynamic>{'a': 1, 'b': 2},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'neq',
          },
          'expected': 'true',
        },
        <String, dynamic>{
          'name': 'component_computed_gt',
          'state': <String, dynamic>{'a': 4, 'b': 3},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'gt',
          },
          'expected': 'true',
        },
        <String, dynamic>{
          'name': 'component_computed_gte',
          'state': <String, dynamic>{'a': 4, 'b': 4},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'gte',
          },
          'expected': 'true',
        },
        <String, dynamic>{
          'name': 'component_computed_lt',
          'state': <String, dynamic>{'a': 1, 'b': 2},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'lt',
          },
          'expected': 'true',
        },
        <String, dynamic>{
          'name': 'component_computed_lte',
          'state': <String, dynamic>{'a': 2, 'b': 2},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'lte',
          },
          'expected': 'true',
        },
        <String, dynamic>{
          'name': 'component_computed_first',
          'state': <String, dynamic>{'a': 'first', 'b': 'second'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'first',
          },
          'expected': 'first',
        },
        <String, dynamic>{
          'name': 'component_computed_last',
          'state': <String, dynamic>{'a': 'first', 'b': 'second'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'last',
          },
          'expected': 'second',
        },
        <String, dynamic>{
          'name': 'component_computed_list',
          'state': <String, dynamic>{'a': 1, 'b': 2},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'list',
          },
          'expected': '[1, 2]',
        },
        <String, dynamic>{
          'name': 'component_computed_pick',
          'state': <String, dynamic>{'a': 'zero', 'b': 'one'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'pick',
            'args': <dynamic>[1],
          },
          'expected': 'one',
        },
        <String, dynamic>{
          'name': 'component_computed_coalesce',
          'state': <String, dynamic>{'a': null, 'b': 'fallback'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'coalesce',
          },
          'expected': 'fallback',
        },
        <String, dynamic>{
          'name': 'component_computed_unknown',
          'state': <String, dynamic>{'a': 'preferred', 'b': 'ignored'},
          'spec': <String, dynamic>{
            'deps': <dynamic>['a', 'b'],
            'op': 'mystery',
          },
          'expected': 'preferred',
        },
      ];

      for (final caseData in cases) {
        QLStoreRegistry.instance.clearAll();
        QuantumComponentRegistry.instance.clear();
        QuantumVM.instance.clearRuntimeCaches();
        registerOmniComponents(QuantumVM.instance);

        await _pumpDefineAndUse(
          tester,
          defineJson: <String, dynamic>{
            'type': 'component:define',
            'props': <String, dynamic>{
              'name': caseData['name'],
              'state': caseData['state'],
              'computed': <String, dynamic>{
                'result': caseData['spec'],
              },
              'ui': <String, dynamic>{
                'type': 'text:p',
                'props': <String, dynamic>{'text': '{{result}}'},
              },
            },
          },
          useJson: <String, dynamic>{
            'type': 'component:use',
            'props': <String, dynamic>{'name': caseData['name']},
          },
        );
        await tester.pumpAndSettle();

        expect(
          find.text(caseData['expected'] as String),
          findsOneWidget,
          reason: caseData['name'] as String,
        );
      }
    });

    testWidgets(
        'mount and unmount hooks execute once and write through the action layer',
        (tester) async {
      const String mountAction = 'component_test_mount_action';
      const String unmountAction = 'component_test_unmount_action';
      _registerCounterAction(mountAction, 'component.test.lifecycle.mount');
      _registerCounterAction(unmountAction, 'component.test.lifecycle.unmount');

      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_hook_lifecycle',
          'hooks': <String, dynamic>{
            'mount': <dynamic>[
              <String, dynamic>{'action': mountAction},
            ],
            'unmount': <dynamic>[
              <String, dynamic>{'action': unmountAction},
            ],
          },
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'hooked component'},
          },
        },
      };

      await _pumpDefineAndUse(
        tester,
        defineJson: defineJson,
        useJson: <String, dynamic>{
          'type': 'component:use',
          'props': <String, dynamic>{'name': 'component_hook_lifecycle'},
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('hooked component'), findsOneWidget);
      expect(
        QLStoreRegistry.instance.defaultStore
            .get('component.test.lifecycle.mount'),
        1,
      );
      expect(
        QLStoreRegistry.instance.defaultStore
            .get('component.test.lifecycle.unmount'),
        isNull,
      );

      await tester.pumpWidget(_wrapQuantum(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(
        QLStoreRegistry.instance.defaultStore
            .get('component.test.lifecycle.unmount'),
        1,
      );
    });

    testWidgets(
        'effect hooks debounce rapid invalidations instead of double-firing stale work',
        (tester) async {
      const String effectAction = 'component_test_effect_action';
      _registerCounterAction(effectAction, 'component.test.effect.hits');

      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_hook_debounce',
          'state': <String, dynamic>{'tick': 0},
          'hooks': <String, dynamic>{
            'mount': <dynamic>[
              <String, dynamic>{
                'action': 'state.set',
                'key': 'tick',
                'value': 1,
              },
            ],
            'effect': <dynamic>[
              <String, dynamic>{
                'deps': <dynamic>['tick'],
                'actions': <dynamic>[
                  <String, dynamic>{'action': effectAction},
                ],
                'debounceMs': 50,
              },
            ],
          },
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'tick={{state.tick}}'},
          },
        },
      };

      await tester.pumpWidget(
        _wrapQuantum(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(defineJson),
                ),
              ),
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(<String, dynamic>{
                    'type': 'component:use',
                    'props': <String, dynamic>{
                      'name': 'component_hook_debounce',
                      'state': <String, dynamic>{'tick': 1},
                    },
                  }),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 10));

      await tester.pumpWidget(
        _wrapQuantum(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(defineJson),
                ),
              ),
              Builder(
                builder: (context) => QuantumVM.instance.renderWidget(
                  context,
                  QLBlueprint.fromJson(<String, dynamic>{
                    'type': 'component:use',
                    'props': <String, dynamic>{
                      'name': 'component_hook_debounce',
                      'state': <String, dynamic>{'tick': 2},
                      'resetState': true,
                    },
                  }),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('tick=2'), findsOneWidget);
      expect(
        QLStoreRegistry.instance.defaultStore.get('component.test.effect.hits'),
        1,
      );
    });

    testWidgets(
        'permission rules can deny rendering and then allow it with the right session claims',
        (tester) async {
      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_permission_gate',
          'metadata': <String, dynamic>{
            'permission': <String, dynamic>{'role': 'admin'},
          },
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'secret component'},
          },
        },
      };
      final useJson = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'component_permission_gate'},
      };

      await _pumpDefineAndUse(
        tester,
        defineJson: defineJson,
        useJson: useJson,
        env: <String, dynamic>{
          'session': <String, dynamic>{
            'claims': <String, dynamic>{
              'roles': <dynamic>['user'],
            },
          },
        },
      );
      await tester.pumpAndSettle();
      expect(find.text('secret component'), findsNothing);

      await _pumpDefineAndUse(
        tester,
        defineJson: defineJson,
        useJson: useJson,
        env: <String, dynamic>{
          'session': <String, dynamic>{
            'claims': <String, dynamic>{
              'roles': <dynamic>['admin'],
            },
          },
        },
      );
      await tester.pumpAndSettle();
      print('--- PERMISSION GATE TEST ---');
      debugDumpApp();
      expect(find.text('secret component'), findsOneWidget);
    });

    testWidgets(
        'runtime field selection projects visible props and state into the component env',
        (tester) async {
      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_projection_view',
          'props': <String, dynamic>{
            'title': 'hidden-title',
          },
          'runtime': <String, dynamic>{
            'fields': <dynamic>['props.title', 'state.count'],
          },
          'state': <String, dynamic>{'count': 7},
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{
              'text':
                  'paths={{componentSelectPaths}}|mode={{componentProjection.coverage.projectionMode}}|title={{componentVisible.props.title}}|count={{componentVisible.state.count}}',
            },
          },
        },
      };
      final useJson = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{
          'name': 'component_projection_view',
          'title': 'visible-title',
          'state': <String, dynamic>{'count': 7},
        },
      };

      await _pumpDefineAndUse(tester, defineJson: defineJson, useJson: useJson);
      await tester.pumpAndSettle();

      print('--- PROJECTION TEST ---');
      print(tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList());

      expect(
        find.text(
          'paths=[props.title, state.count]|mode=true|title=visible-title|count=7',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'self-referential components stop at the runtime depth guard instead of hanging',
        (tester) async {
      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_recursive_guard',
          'ui': <String, dynamic>{
            'type': 'component:use',
            'props': <String, dynamic>{'name': 'component_recursive_guard'},
          },
        },
      };
      final useJson = <String, dynamic>{
        'type': 'component:use',
        'props': <String, dynamic>{'name': 'component_recursive_guard'},
      };

      await _pumpDefineAndUse(tester, defineJson: defineJson, useJson: useJson);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets(
        'compiled component metadata merges capability signals and exposes schema details',
        (tester) async {
      final defineJson = <String, dynamic>{
        'type': 'component:define',
        'props': <String, dynamic>{
          'name': 'component_metadata_surface',
          'description': 'Metadata surface test',
          'props': <String, dynamic>{
            'title': '',
            'count': 0,
            'enabled': false,
            'tags': <dynamic>['alpha', 'beta'],
            'config': <String, dynamic>{'mode': 'base'},
          },
          'runtime': <String, dynamic>{
            'capabilities': <dynamic>['runtime-cap'],
            'features': <dynamic>['runtime-feature'],
            'batch': <String, dynamic>{'size': 8},
            'stream': <String, dynamic>{'enabled': true},
          },
          'policy': <String, dynamic>{
            'features': <dynamic>['policy-feature'],
          },
          'metadata': <String, dynamic>{
            'capabilities': <dynamic>['meta-cap'],
            'features': <dynamic>['meta-feature'],
            'media': <String, dynamic>{'kind': 'image'},
          },
          'capabilities': <dynamic>['direct-cap'],
          'slots': <String, dynamic>{
            'header': _textNode('header slot'),
            'footer': _textNode('footer slot'),
          },
          'ui': <String, dynamic>{
            'type': 'text:p',
            'props': <String, dynamic>{'text': 'metadata surface'},
          },
        },
      };

      await tester.pumpWidget(_renderNode(QLBlueprint.fromJson(defineJson)));
      await tester.pumpAndSettle();
      print('Names: ${QuantumComponentRegistry.instance.names}');

      final Map<String, dynamic>? described = QuantumComponentRegistry.instance
          .describe('component_metadata_surface');
      print('--- METADATA TEST ---');
      print('described: $described');
      expect(described, isNotNull);

      final Map<String, dynamic> metadata =
          Map<String, dynamic>.from(described!['metadata'] as Map);
      final Map<String, dynamic> infoSchema =
          Map<String, dynamic>.from(metadata['infoSchema'] as Map);
      final Map<String, dynamic> componentSpec =
          Map<String, dynamic>.from(metadata['componentSpec'] as Map);

      expect(
          infoSchema['slotNames'], containsAll(<String>['header', 'footer']));
      expect(infoSchema['kind'], 'component');

      final List<dynamic> capabilities =
          List<dynamic>.from(componentSpec['capabilities'] as List);
      expect(
          capabilities,
          containsAll(<String>[
            'direct-cap',
            'runtime-cap',
            'runtime-feature',
            'policy-feature',
            'meta-cap',
            'meta-feature',
            'media',
            'stream',
            'batch',
          ]));
      expect(capabilities.toSet().length, capabilities.length);

      final Map<String, dynamic> params =
          Map<String, dynamic>.from(described['params'] as Map);
      final Map<String, dynamic> properties =
          Map<String, dynamic>.from(params['properties'] as Map);

      expect(params['type'], 'object');
      expect(
          params['required'],
          containsAll(<String>[
            'title',
            'count',
            'enabled',
            'tags',
            'config',
          ]));
      expect(properties['title']['type'], 'String');
      expect(properties['count']['type'], 'int');
      expect(properties['enabled']['type'], 'bool');
      expect(properties['tags']['type'], 'List<dynamic>');
      expect(properties['config']['type'], 'Map<String, dynamic>');
    });
  });
}
