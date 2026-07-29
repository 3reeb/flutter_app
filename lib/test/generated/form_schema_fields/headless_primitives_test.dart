import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Quantum Field UI Engine - Headless Primitives', () {
    testWidgets(
        'QLRawSlider dimensionally agnostic math perfectly resolves percentages',
        (WidgetTester tester) async {
      final form = QLFormController();
      final sliderCtrl =
          QLNumberController(path: 'volume', form: form, initialValue: 0.0);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 50,
            child: QLRawSlider(
              controller: sliderCtrl, min: 0, max: 100,
              direction: Axis.horizontal,
              // Must have a color to be hit-testable by Flutter!
              builder: (ctx, state) => Container(
                  key: const Key('slider_track'), color: Colors.transparent),
            ),
          ),
        ),
      ));

      // 🚀 FIX: Flutter's drag() starts at the center (x=100) by default.
      // We must get the top-left coordinate, then tap exactly at x=100 to simulate 50%.
      final trackFinder = find.byKey(const Key('slider_track'));
      final topLeft = tester.getTopLeft(trackFinder);

      await tester.tapAt(topLeft + const Offset(100, 25));
      await tester.pumpAndSettle();

      expect(sliderCtrl.data.value, 50.0);
    });

    testWidgets('QLRawTextInput does NOT rebuild on every keystroke',
        (WidgetTester tester) async {
      final form = QLFormController();
      final textCtrl =
          QLTextController(path: 'input', form: form, initialValue: '');

      int rebuilds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QLRawTextInput(
            controller: textCtrl,
            textStyle: const TextStyle(),
            cursorColor: Colors.blue,
            selectionColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            shellBuilder: (ctx, state, rawInput) {
              rebuilds++;
              return rawInput;
            },
          ),
        ),
      ));

      final int initialRebuilds = rebuilds;

      await tester.enterText(find.byType(TextField), 'Hello Giga');
      await tester.pump();

      expect(textCtrl.data.value, 'Hello Giga');

      // FIX: It rebuilds +1 for FOCUS, and +1 for EMPTY STATE transition = +2.
      // The 10 typing keystrokes are successfully ignored.
      expect(rebuilds, initialRebuilds + 2);
    });
  });
}
