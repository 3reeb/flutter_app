import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('test', (tester) async {
    final vsync = const TestVSync();
    final ctrl = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));
    ctrl.addListener(() => print(ctrl.value));
    ctrl.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  });
}
