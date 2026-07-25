import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  testWidgets('Run their app and tap button', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    print('App loaded. Checking for "nav.push" action buttons...');

    final button = find.text('Flex Engine'); // from main.dart
    expect(button, findsOneWidget);

    print('Tapping Flex Engine...');
    await tester.tap(button);
    await tester.pumpAndSettle();
    print('Tapped. Wait...');
    
    // Check if new route appeared
    final settingsText = find.text('Flex Engine Playground'); // wait, flex pushes /flex
    
    print('Done.');
  });
}
