import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
export 'package:quantum_layout/quantum.dart';

class _TestImageResolver extends QLImageResolver {
  static final Uint8List _pngBytes = Uint8List.fromList(<int>[
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    12,
    73,
    68,
    65,
    84,
    8,
    153,
    99,
    248,
    15,
    4,
    0,
    9,
    251,
    3,
    253,
    167,
    184,
    173,
    244,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ]);

  @override
  String rewrite(String url, int width, int height, int quality) => url;

  @override
  Future<Map<String, Uint8List>> fetchBatch(List<String> urls) async {
    return <String, Uint8List>{for (final url in urls) url: _pngBytes};
  }
}

Future<void> bootstrapQuantumTestVm() async {
  QuantumVM.instance.dispose();
  QTemplateEngine.clear();
  QLCoreFileRegistry.instance.clear();
  initQuantumBuiltIns(QuantumVM.instance);
  QuantumImagePipeline.instance.resolver = _TestImageResolver();
}

QLBlueprint blueprint(
  String type, {
  Map<String, dynamic> props = const <String, dynamic>{},
  List<QLBlueprint> children = const <QLBlueprint>[],
  Map<String, QLBlueprint> slots = const <String, QLBlueprint>{},
  String? style,
  String path = 'root',
}) {
  return QLBlueprint(
    type: type,
    props: Map<String, dynamic>.from(props),
    style: style,
    children: List<QLBlueprint>.from(children),
    slots: Map<String, QLBlueprint>.from(slots),
    debugPath: path,
  );
}

Widget renderBlueprint(
  QLBlueprint node, {
  Map<String, dynamic> env = const <String, dynamic>{},
}) {
  return MaterialApp(
    home: QLDataScope(
      localData: Map<String, dynamic>.from(env),
      child: Builder(
        builder: (context) => QuantumVM.instance.renderWidget(context, node),
      ),
    ),
  );
}

Future<void> pumpBlueprint(
  WidgetTester tester,
  QLBlueprint node, {
  Map<String, dynamic> env = const <String, dynamic>{},
}) async {
  await tester.pumpWidget(renderBlueprint(node, env: env));
  await tester.pump();
}

Future<void> pumpBlueprintAndSettle(
  WidgetTester tester,
  QLBlueprint node, {
  Map<String, dynamic> env = const <String, dynamic>{},
}) async {
  await tester.pumpWidget(renderBlueprint(node, env: env));
  await tester.pumpAndSettle();
}

void registerSpyAction(String name, List<String> events, String label) {
  QuantumVM.instance.registerAction(
    name,
    LambdaActionPlugin((payload, store, ctx) async {
      events.add('$label:${payload['value'] ?? payload['label'] ?? ''}');
      return null;
    }),
    description: 'Spy action $name',
  );
}
