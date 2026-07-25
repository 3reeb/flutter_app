import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_v1/test_support.dart';

import 'package:quantum_layout/quantum.dart';

Future<void> _pumpBoxCase(
  WidgetTester tester,
  Map<String, dynamic> json, {
  required Size size,
}) async {
  final QLBlueprint blueprint = QLBlueprint.fromJson(
    json,
    path: json['debugPath']?.toString() ?? 'case',
  );

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, devicePixelRatio: 1.0),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: Builder(
                builder: (context) =>
                    QuantumVM.instance.renderWidget(context, blueprint),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _qWithTokens(List<String> tokens) {
  return find.byWidgetPredicate(
    (Widget widget) {
      if (widget is! Q) return false;
      bool match = tokens.every(widget.style.contains);
      if (!match && widget.style.contains('row')) {
        print('EXPECTED: $tokens');
        print('ACTUAL: ${widget.style}');
      }
      return match;
    },
    skipOffstage: false,
  );
}

void main() {
  setUpAll(() async {
    await bootstrapQuantumTestVm();
  });

  // setUpAll(() {
  //   // 1. Total System Purge
  //   QLModuleRegistry.instance.clear();
  //   QLSchemaRegistry.instance.clear();
  //   QLPipelineRegistry.instance.destroy('default');
  //   QLStoreRegistry.instance.destroy('default');
  //   QuantumVM.instance.clearRuntimeCaches();
  //   clearQuantumInputRegistry();

  //   // 2. Hardware Engine Initialization
  //   QEngine.instance.initialize(initialCapacity: 4096);
  //   QuantumVM.instance.initialize(workerThreads: 1);

  //   // 3. Mount the Omni Registry
  //   registerOmniComponents(QuantumVM.instance);

  //   // Error-throwing plugin
  //   QuantumVM.instance.registerAction(
  //     'mock.error_thrower',
  //     LambdaActionPlugin((p, s, c) async {
  //       throw Exception("Intended hostile exception from mock.error_thrower");
  //     }),
  //   );
  // });
  // setUp(() {
  //   // 1. Total System Purge
  //   QLModuleRegistry.instance.clear();
  //   QLSchemaRegistry.instance.clear();
  //   QLPipelineRegistry.instance.destroy('default');
  //   QLStoreRegistry.instance.destroy('default');
  //   QuantumVM.instance.clearRuntimeCaches();
  //   clearQuantumInputRegistry();

  //   // 2. Hardware Engine Initialization
  //   QEngine.instance.initialize(initialCapacity: 4096);
  //   QuantumVM.instance.initialize(workerThreads: 1);

  //   // 3. Mount the Omni Registry
  //   registerOmniComponents(QuantumVM.instance);

  //   // Error-throwing plugin
  //   QuantumVM.instance.registerAction(
  //     'mock.error_thrower',
  //     LambdaActionPlugin((p, s, c) async {
  //       throw Exception("Intended hostile exception from mock.error_thrower");
  //     }),
  //   );
  // });
  testWidgets('box:measure - captures dimensions without layout effect',
      (WidgetTester tester) async {
    final node = blueprint('box:measure', props: {
      'bind': 'mySize'
    }, children: [
      blueprint('text', props: {'text': 'Measured'})
    ]);
    await pumpBlueprintAndSettle(tester, node);
    expect(find.text('Measured'), findsOneWidget);
  });

  testWidgets('box_core_0001_row_fixed_size_compact',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "items": "start",
        "justify": "center",
        "gap": 2.0,
        "debugSeed": 1,
        "width": 180.0,
        "height": 64.0
      },
      "style": "items-center justify-between gap-2 px-3 py-2 min-w-0 min-h-0",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0001"}
        }
      ],
      "debugPath": "box_core_cases.case_0001"
    };
    await _pumpBoxCase(tester, node, size: const Size(320.0, 568.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-center",
          "gap-2",
          "items-center",
          "justify-between",
          "px-3",
          "py-2",
          "min-w-0",
          "min-h-0"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == node['props']['width'] &&
            widget.height == node['props']['height'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0002_row_fixed_size_phone',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {"__subType": "row", "width": 180.0, "height": 64.0},
      "style": "items-center justify-between gap-2 px-3 py-2 min-w-0 min-h-0",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0002"}
        }
      ],
      "debugPath": "box_core_cases.case_0002"
    };
    await _pumpBoxCase(tester, node, size: const Size(390.0, 844.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-start",
          "gap-3",
          "items-center",
          "justify-between",
          "gap-2",
          "px-3",
          "py-2",
          "min-w-0",
          "min-h-0"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == node['props']['width'] &&
            widget.height == node['props']['height'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0003_row_fixed_size_tablet',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "end",
        "gap": 4.0,
        "debugSeed": 3,
        "width": 180.0,
        "height": 64.0
      },
      "style": "items-center justify-between gap-2 px-3 py-2 min-w-0 min-h-0",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0003"}
        }
      ],
      "debugPath": "box_core_cases.case_0003"
    };
    await _pumpBoxCase(tester, node, size: const Size(768.0, 1024.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-end",
          "gap-4",
          "justify-between",
          "gap-2",
          "px-3",
          "py-2",
          "min-w-0",
          "min-h-0"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == node['props']['width'] &&
            widget.height == node['props']['height'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0004_row_fixed_size_laptop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "between",
        "gap": 5.0,
        "debugSeed": 4,
        "width": 180.0,
        "height": 64.0
      },
      "style": "items-center justify-between gap-2 px-3 py-2 min-w-0 min-h-0",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0004"}
        }
      ],
      "debugPath": "box_core_cases.case_0004"
    };
    await _pumpBoxCase(tester, node, size: const Size(1366.0, 900.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-between",
          "gap-5",
          "items-center",
          "gap-2",
          "px-3",
          "py-2",
          "min-w-0",
          "min-h-0"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == node['props']['width'] &&
            widget.height == node['props']['height'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0005_row_fixed_size_desktop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "center",
        "gap": 6.0,
        "debugSeed": 5,
        "width": 180.0,
        "height": 64.0
      },
      "style": "items-center justify-between gap-2 px-3 py-2 min-w-0 min-h-0",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0005"}
        }
      ],
      "debugPath": "box_core_cases.case_0005"
    };
    await _pumpBoxCase(tester, node, size: const Size(1920.0, 1080.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-center",
          "gap-6",
          "items-center",
          "justify-between",
          "gap-2",
          "px-3",
          "py-2",
          "min-w-0",
          "min-h-0"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == node['props']['width'] &&
            widget.height == node['props']['height'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0006_row_fractional_box_compact',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "start",
        "gap": 7.0,
        "debugSeed": 6,
        "fractional": true,
        "widthFactor": 0.55,
        "heightFactor": 0.35
      },
      "style": "items-start justify-around gap-4 px-4 py-1 w-full h-auto",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0006"}
        }
      ],
      "debugPath": "box_core_cases.case_0006"
    };
    await _pumpBoxCase(tester, node, size: const Size(320.0, 568.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-start",
          "gap-7",
          "items-start",
          "justify-around",
          "gap-4",
          "px-4",
          "py-1",
          "w-full",
          "h-auto"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FractionallySizedBox &&
            widget.widthFactor == node['props']['widthFactor'] &&
            widget.heightFactor == node['props']['heightFactor'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0007_row_fractional_box_phone',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "end",
        "gap": 1.0,
        "debugSeed": 7,
        "fractional": true,
        "widthFactor": 0.55,
        "heightFactor": 0.35
      },
      "style": "items-start justify-around gap-4 px-4 py-1 w-full h-auto",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0007"}
        }
      ],
      "debugPath": "box_core_cases.case_0007"
    };
    await _pumpBoxCase(tester, node, size: const Size(390.0, 844.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-end",
          "gap-1",
          "justify-around",
          "gap-4",
          "px-4",
          "py-1",
          "w-full",
          "h-auto"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FractionallySizedBox &&
            widget.widthFactor == node['props']['widthFactor'] &&
            widget.heightFactor == node['props']['heightFactor'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0008_row_fractional_box_tablet',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "between",
        "gap": 2.0,
        "debugSeed": 8,
        "fractional": true,
        "widthFactor": 0.55,
        "heightFactor": 0.35
      },
      "style": "items-start justify-around gap-4 px-4 py-1 w-full h-auto",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0008"}
        }
      ],
      "debugPath": "box_core_cases.case_0008"
    };
    await _pumpBoxCase(tester, node, size: const Size(768.0, 1024.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-between",
          "gap-2",
          "items-start",
          "justify-around",
          "gap-4",
          "px-4",
          "py-1",
          "w-full",
          "h-auto"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FractionallySizedBox &&
            widget.widthFactor == node['props']['widthFactor'] &&
            widget.heightFactor == node['props']['heightFactor'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0009_row_fractional_box_laptop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "center",
        "gap": 3.0,
        "debugSeed": 9,
        "fractional": true,
        "widthFactor": 0.55,
        "heightFactor": 0.35
      },
      "style": "items-start justify-around gap-4 px-4 py-1 w-full h-auto",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0009"}
        }
      ],
      "debugPath": "box_core_cases.case_0009"
    };
    await _pumpBoxCase(tester, node, size: const Size(1366.0, 900.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-center",
          "gap-3",
          "items-start",
          "justify-around",
          "gap-4",
          "px-4",
          "py-1",
          "w-full",
          "h-auto"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FractionallySizedBox &&
            widget.widthFactor == node['props']['widthFactor'] &&
            widget.heightFactor == node['props']['heightFactor'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0010_row_fractional_box_desktop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "start",
        "gap": 4.0,
        "debugSeed": 10,
        "fractional": true,
        "widthFactor": 0.55,
        "heightFactor": 0.35
      },
      "style": "items-start justify-around gap-4 px-4 py-1 w-full h-auto",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0010"}
        }
      ],
      "debugPath": "box_core_cases.case_0010"
    };
    await _pumpBoxCase(tester, node, size: const Size(1920.0, 1080.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-start",
          "gap-4",
          "justify-around",
          "px-4",
          "py-1",
          "w-full",
          "h-auto"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FractionallySizedBox &&
            widget.widthFactor == node['props']['widthFactor'] &&
            widget.heightFactor == node['props']['heightFactor'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0011_row_aspect_box_compact',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "end",
        "gap": 5.0,
        "debugSeed": 11,
        "aspectBox": true,
        "ratio": 1.25
      },
      "style": "items-end justify-center gap-3 mx-2 my-2 max-w-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0011"}
        }
      ],
      "debugPath": "box_core_cases.case_0011"
    };
    await _pumpBoxCase(tester, node, size: const Size(320.0, 568.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-end",
          "gap-5",
          "items-end",
          "justify-center",
          "gap-3",
          "mx-2",
          "my-2",
          "max-w-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is AspectRatio &&
            widget.aspectRatio == node['props']['ratio'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0012_row_aspect_box_phone',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "between",
        "gap": 6.0,
        "debugSeed": 12,
        "aspectBox": true,
        "ratio": 1.25
      },
      "style": "items-end justify-center gap-3 mx-2 my-2 max-w-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0012"}
        }
      ],
      "debugPath": "box_core_cases.case_0012"
    };
    await _pumpBoxCase(tester, node, size: const Size(390.0, 844.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-between",
          "gap-6",
          "items-end",
          "justify-center",
          "gap-3",
          "mx-2",
          "my-2",
          "max-w-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is AspectRatio &&
            widget.aspectRatio == node['props']['ratio'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0013_row_aspect_box_tablet',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "center",
        "gap": 7.0,
        "debugSeed": 13,
        "aspectBox": true,
        "ratio": 1.25
      },
      "style": "items-end justify-center gap-3 mx-2 my-2 max-w-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0013"}
        }
      ],
      "debugPath": "box_core_cases.case_0013"
    };
    await _pumpBoxCase(tester, node, size: const Size(768.0, 1024.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-center",
          "gap-7",
          "items-end",
          "gap-3",
          "mx-2",
          "my-2",
          "max-w-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is AspectRatio &&
            widget.aspectRatio == node['props']['ratio'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0014_row_aspect_box_laptop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "start",
        "gap": 1.0,
        "debugSeed": 14,
        "aspectBox": true,
        "ratio": 1.25
      },
      "style": "items-end justify-center gap-3 mx-2 my-2 max-w-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0014"}
        }
      ],
      "debugPath": "box_core_cases.case_0014"
    };
    await _pumpBoxCase(tester, node, size: const Size(1366.0, 900.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-start",
          "gap-1",
          "items-end",
          "justify-center",
          "gap-3",
          "mx-2",
          "my-2",
          "max-w-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is AspectRatio &&
            widget.aspectRatio == node['props']['ratio'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0015_row_aspect_box_desktop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "end",
        "gap": 2.0,
        "debugSeed": 15,
        "aspectBox": true,
        "ratio": 1.25
      },
      "style": "items-end justify-center gap-3 mx-2 my-2 max-w-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0015"}
        }
      ],
      "debugPath": "box_core_cases.case_0015"
    };
    await _pumpBoxCase(tester, node, size: const Size(1920.0, 1080.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-end",
          "gap-2",
          "items-end",
          "justify-center",
          "gap-3",
          "mx-2",
          "my-2",
          "max-w-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is AspectRatio &&
            widget.aspectRatio == node['props']['ratio'],
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0016_row_expand_box_compact',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "between",
        "gap": 3.0,
        "debugSeed": 16,
        "expand": true
      },
      "style": "items-stretch justify-evenly gap-1 w-full h-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0016"}
        }
      ],
      "debugPath": "box_core_cases.case_0016"
    };
    await _pumpBoxCase(tester, node, size: const Size(320.0, 568.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-between",
          "gap-3",
          "items-stretch",
          "justify-evenly",
          "gap-1",
          "w-full",
          "h-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == double.infinity &&
            widget.height == double.infinity,
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0017_row_expand_box_phone',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "center",
        "gap": 4.0,
        "debugSeed": 17,
        "expand": true
      },
      "style": "items-stretch justify-evenly gap-1 w-full h-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0017"}
        }
      ],
      "debugPath": "box_core_cases.case_0017"
    };
    await _pumpBoxCase(tester, node, size: const Size(390.0, 844.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-center",
          "gap-4",
          "justify-evenly",
          "gap-1",
          "w-full",
          "h-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == double.infinity &&
            widget.height == double.infinity,
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0018_row_expand_box_tablet',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "start",
        "gap": 5.0,
        "debugSeed": 18,
        "expand": true
      },
      "style": "items-stretch justify-evenly gap-1 w-full h-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0018"}
        }
      ],
      "debugPath": "box_core_cases.case_0018"
    };
    await _pumpBoxCase(tester, node, size: const Size(768.0, 1024.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-start",
          "gap-5",
          "items-stretch",
          "justify-evenly",
          "gap-1",
          "w-full",
          "h-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == double.infinity &&
            widget.height == double.infinity,
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0019_row_expand_box_laptop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "end",
        "gap": 6.0,
        "debugSeed": 19,
        "expand": true
      },
      "style": "items-stretch justify-evenly gap-1 w-full h-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0019"}
        }
      ],
      "debugPath": "box_core_cases.case_0019"
    };
    await _pumpBoxCase(tester, node, size: const Size(1366.0, 900.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-end",
          "gap-6",
          "items-stretch",
          "justify-evenly",
          "gap-1",
          "w-full",
          "h-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == double.infinity &&
            widget.height == double.infinity,
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0020_row_expand_box_desktop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "between",
        "gap": 7.0,
        "debugSeed": 20,
        "expand": true
      },
      "style": "items-stretch justify-evenly gap-1 w-full h-full",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0020"}
        }
      ],
      "debugPath": "box_core_cases.case_0020"
    };
    await _pumpBoxCase(tester, node, size: const Size(1920.0, 1080.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-between",
          "gap-7",
          "justify-evenly",
          "gap-1",
          "w-full",
          "h-full"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == double.infinity &&
            widget.height == double.infinity,
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0021_row_constrained_box_compact',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "center",
        "gap": 1.0,
        "debugSeed": 21,
        "constrained": true,
        "minWidth": 48.0,
        "minHeight": 32.0,
        "maxWidth": 420.0,
        "maxHeight": 240.0
      },
      "style": "items-center justify-start gap-6 p-4 overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0021"}
        }
      ],
      "debugPath": "box_core_cases.case_0021"
    };
    await _pumpBoxCase(tester, node, size: const Size(320.0, 568.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-center",
          "gap-1",
          "justify-start",
          "gap-6",
          "p-4",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) {
          if (widget is! ConstrainedBox) return false;
          final BoxConstraints c = widget.constraints;
          return c.minWidth == 48.0 &&
              c.minHeight == 32.0 &&
              c.maxWidth == 420.0 &&
              c.maxHeight == 240.0;
        },
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0022_row_constrained_box_phone',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "start",
        "gap": 2.0,
        "debugSeed": 22,
        "constrained": true,
        "minWidth": 48.0,
        "minHeight": 32.0,
        "maxWidth": 420.0,
        "maxHeight": 240.0
      },
      "style": "items-center justify-start gap-6 p-4 overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0022"}
        }
      ],
      "debugPath": "box_core_cases.case_0022"
    };
    await _pumpBoxCase(tester, node, size: const Size(390.0, 844.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-start",
          "gap-2",
          "items-center",
          "gap-6",
          "p-4",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) {
          if (widget is! ConstrainedBox) return false;
          final BoxConstraints c = widget.constraints;
          return c.minWidth == 48.0 &&
              c.minHeight == 32.0 &&
              c.maxWidth == 420.0 &&
              c.maxHeight == 240.0;
        },
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0023_row_constrained_box_tablet',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "end",
        "gap": 3.0,
        "debugSeed": 23,
        "constrained": true,
        "minWidth": 48.0,
        "minHeight": 32.0,
        "maxWidth": 420.0,
        "maxHeight": 240.0
      },
      "style": "items-center justify-start gap-6 p-4 overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0023"}
        }
      ],
      "debugPath": "box_core_cases.case_0023"
    };
    await _pumpBoxCase(tester, node, size: const Size(768.0, 1024.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-end",
          "gap-3",
          "items-center",
          "justify-start",
          "gap-6",
          "p-4",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) {
          if (widget is! ConstrainedBox) return false;
          final BoxConstraints c = widget.constraints;
          return c.minWidth == 48.0 &&
              c.minHeight == 32.0 &&
              c.maxWidth == 420.0 &&
              c.maxHeight == 240.0;
        },
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0024_row_constrained_box_laptop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "between",
        "gap": 4.0,
        "debugSeed": 24,
        "constrained": true,
        "minWidth": 48.0,
        "minHeight": 32.0,
        "maxWidth": 420.0,
        "maxHeight": 240.0
      },
      "style": "items-center justify-start gap-6 p-4 overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0024"}
        }
      ],
      "debugPath": "box_core_cases.case_0024"
    };
    await _pumpBoxCase(tester, node, size: const Size(1366.0, 900.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-between",
          "gap-4",
          "justify-start",
          "gap-6",
          "p-4",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) {
          if (widget is! ConstrainedBox) return false;
          final BoxConstraints c = widget.constraints;
          return c.minWidth == 48.0 &&
              c.minHeight == 32.0 &&
              c.maxWidth == 420.0 &&
              c.maxHeight == 240.0;
        },
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0025_row_constrained_box_desktop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "center",
        "gap": 5.0,
        "debugSeed": 25,
        "constrained": true,
        "minWidth": 48.0,
        "minHeight": 32.0,
        "maxWidth": 420.0,
        "maxHeight": 240.0
      },
      "style": "items-center justify-start gap-6 p-4 overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0025"}
        }
      ],
      "debugPath": "box_core_cases.case_0025"
    };
    await _pumpBoxCase(tester, node, size: const Size(1920.0, 1080.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-center",
          "gap-5",
          "items-center",
          "justify-start",
          "gap-6",
          "p-4",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) {
          if (widget is! ConstrainedBox) return false;
          final BoxConstraints c = widget.constraints;
          return c.minWidth == 48.0 &&
              c.minHeight == 32.0 &&
              c.maxWidth == 420.0 &&
              c.maxHeight == 240.0;
        },
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
  testWidgets('box_core_0026_row_clip_box_compact',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "start",
        "gap": 6.0,
        "debugSeed": 26,
        "clip": true,
        "clipKind": "hardEdge"
      },
      "style":
          "items-center justify-between gap-2 rounded border shadow overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0026"}
        }
      ],
      "debugPath": "box_core_cases.case_0026"
    };
    await _pumpBoxCase(tester, node, size: const Size(320.0, 568.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-start",
          "gap-6",
          "items-center",
          "justify-between",
          "gap-2",
          "rounded",
          "border",
          "shadow",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(find.byType(ClipRect, skipOffstage: false), findsWidgets);
  });
  testWidgets('box_core_0027_row_clip_box_phone', (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "end",
        "gap": 7.0,
        "debugSeed": 27,
        "clip": true,
        "clipKind": "hardEdge"
      },
      "style":
          "items-center justify-between gap-2 rounded border shadow overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0027"}
        }
      ],
      "debugPath": "box_core_cases.case_0027"
    };
    await _pumpBoxCase(tester, node, size: const Size(390.0, 844.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-end",
          "gap-7",
          "justify-between",
          "gap-2",
          "rounded",
          "border",
          "shadow",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(find.byType(ClipRect, skipOffstage: false), findsWidgets);
  });
  testWidgets('box_core_0028_row_clip_box_tablet', (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "start",
        "justify": "between",
        "gap": 1.0,
        "debugSeed": 28,
        "clip": true,
        "clipKind": "hardEdge"
      },
      "style":
          "items-center justify-between gap-2 rounded border shadow overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0028"}
        }
      ],
      "debugPath": "box_core_cases.case_0028"
    };
    await _pumpBoxCase(tester, node, size: const Size(768.0, 1024.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-start",
          "justify-between",
          "gap-1",
          "items-center",
          "gap-2",
          "rounded",
          "border",
          "shadow",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(find.byType(ClipRect, skipOffstage: false), findsWidgets);
  });
  testWidgets('box_core_0029_row_clip_box_laptop', (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "stretch",
        "justify": "center",
        "gap": 2.0,
        "debugSeed": 29,
        "clip": true,
        "clipKind": "hardEdge"
      },
      "style":
          "items-center justify-between gap-2 rounded border shadow overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0029"}
        }
      ],
      "debugPath": "box_core_cases.case_0029"
    };
    await _pumpBoxCase(tester, node, size: const Size(1366.0, 900.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-stretch",
          "justify-center",
          "gap-2",
          "items-center",
          "justify-between",
          "rounded",
          "border",
          "shadow",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(find.byType(ClipRect, skipOffstage: false), findsWidgets);
  });
  testWidgets('box_core_0030_row_clip_box_desktop',
      (WidgetTester tester) async {
    final Map<String, dynamic> node = {
      "type": "box:row",
      "props": {
        "__subType": "row",
        "items": "center",
        "justify": "start",
        "gap": 3.0,
        "debugSeed": 30,
        "clip": true,
        "clipKind": "hardEdge"
      },
      "style":
          "items-center justify-between gap-2 rounded border shadow overflow-hidden",
      "children": [
        {
          "type": "text",
          "props": {"text": "box-core-case-0030"}
        }
      ],
      "debugPath": "box_core_cases.case_0030"
    };
    await _pumpBoxCase(tester, node, size: const Size(1920.0, 1080.0));
    expect(tester.takeException(), isNull);
    expect(
        _qWithTokens([
          "items-center",
          "justify-start",
          "gap-3",
          "justify-between",
          "gap-2",
          "rounded",
          "border",
          "shadow",
          "overflow-hidden"
        ]),
        findsWidgets);
    expect(find.byType(ClipRect, skipOffstage: false), findsWidgets);
  });
}
