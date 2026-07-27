import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

int _uniqueCounter = 0;

String uniqueName(String prefix) {
  _uniqueCounter += 1;
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_uniqueCounter';
}

void resetQuantumState() {
  try {
    QuantumOverlay.instance.resetForTesting();
  } catch (_) {}
  try {
    QJsonTemplateEngine_D.clear();
  } catch (_) {}
  try {
    QLCompiler.clearCaches();
  } catch (_) {}
  try {
    QuantumVM.instance.dispose();
  } catch (_) {}
}

Future<void> pumpOverlayHarness(
  WidgetTester tester, {
  Widget child = const SizedBox.shrink(),
}) async {
  await tester.pumpWidget(
    QLOverlayRoot(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void registerBasicJsonDslPlugins() {
  try {
    QuantumVM.instance.registerJsonDslPlugins();
  } catch (_) {}
}

Future<void> openOverlay(
  WidgetTester tester, {
  required QLSpatialConfig config,
  required String label,
  VoidCallback? onButtonTap,
}) async {
  // ignore: unawaited_futures
  QuantumOverlay.instance.mount(
    null,
    config,
    (context, close) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: TextButton(
            onPressed: onButtonTap ?? close,
            child: Text(label),
          ),
        ),
      );
    },
  );
  await tester.pump();
}

QLBlueprint textBlueprint(String text, {String debugPath = 'root'}) {
  return QLBlueprint(
    type: 'text',
    props: <String, dynamic>{'text': text},
    children: const <QLBlueprint>[],
    debugPath: debugPath,
  );
}

QLBlueprint colBlueprint(List<QLBlueprint> children,
    {String debugPath = 'root'}) {
  return QLBlueprint(
    type: 'col',
    props: const <String, dynamic>{},
    children: children,
    debugPath: debugPath,
  );
}
