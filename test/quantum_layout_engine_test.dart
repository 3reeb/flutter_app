import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

void main() {
  group('1. QParser - CSS Track Tokenization & Resolution', () {
    test('Parses basic explicit tracks', () {
      final tracks = QParser.parse('100px 1fr auto');
      expect(tracks.length, 3);
      expect((tracks[0] as QFixed).px, 100.0);
      expect((tracks[1] as QFraction).fr, 1.0);
      expect(tracks[2], isA<QAuto>());
    });

    test('Parses percentages as fractions', () {
      final tracks = QParser.parse('50% 100%');
      expect(tracks.length, 2);
      expect((tracks[0] as QFraction).fr, 50.0);
      expect((tracks[1] as QFraction).fr, 100.0);
    });

    test('Parses minmax functions', () {
      final tracks = QParser.parse('minmax(10px, 1fr) minmax(auto, 200px)');
      expect(tracks.length, 2);

      final t1 = tracks[0] as QMinMax;
      expect((t1.min as QFixed).px, 10.0);
      expect((t1.max as QFraction).fr, 1.0);

      final t2 = tracks[1] as QMinMax;
      expect(t2.min, isA<QAuto>());
      expect((t2.max as QFixed).px, 200.0);
    });

    test('Parses fit-content', () {
      final tracks = QParser.parse('fit-content(250px)');
      expect(tracks.length, 1);
      expect((tracks[0] as QFitContent).maxPx, 250.0);
    });

    test('Flattens static repeat() functions immediately', () {
      // The Engine splits function args by commas.
      final tracks = QParser.parse('repeat(3, 100px, 1fr)');
      expect(tracks.length, 6);
      expect((tracks[0] as QFixed).px, 100.0);
      expect((tracks[1] as QFraction).fr, 1.0);
      expect((tracks[4] as QFixed).px, 100.0);
      expect((tracks[5] as QFraction).fr, 1.0);
    });

    test('Preserves dynamic repeat(auto-fill / auto-fit) for layout phase', () {
      final tracks = QParser.parse(
          'repeat(auto-fill, 100px) repeat(auto-fit, minmax(50px, 1fr))');
      expect(tracks.length, 2);

      expect(tracks[0], isA<QAutoFill>());
      expect((tracks[0] as QAutoFill).tracks[0], isA<QFixed>());

      expect(tracks[1], isA<QAutoFit>());
      expect((tracks[1] as QAutoFit).tracks[0], isA<QMinMax>());
    });

    test('Handles malformed garbage gracefully without crashing', () {
      final tracks = QParser.parse('gibberish 100px   ,,, repeat(foo) ');

      // Commas and extra spaces are cleanly stripped out, resulting in 3 tracks
      expect(tracks.length, 3);

      // Un-parseable garbage securely falls back to 0.0px to prevent UI panics
      expect((tracks[0] as QFixed).px, 0.0); // 'gibberish' -> 0.0
      expect((tracks[1] as QFixed).px, 100.0); // '100px'
      expect((tracks[2] as QFixed).px, 0.0); // 'repeat(foo)' -> 0.0
    });
  });

  group('2. QuantumGrid - Basic Box Model & Spanning', () {
    testWidgets('Calculates strict px and fr widths correctly with gaps',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 420, // 420 total space available
              height: 100,
              child: QuantumGrid(
                columns: '100px 1fr 2fr',
                rows: '100px', // Explicit row height for stable calculation
                columnGap: 10.0, // 2 gaps * 10 = 20px (400px remaining)
                children: [
                  Container(
                      key: const Key('1')), // 100px fixed. (300px fr space)
                  Container(key: const Key('2')), // 1/3 of 300px = 100px
                  Container(key: const Key('3')), // 2/3 of 300px = 200px
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getRect(find.byKey(const Key('1'))),
          const Rect.fromLTWH(0, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('2'))),
          const Rect.fromLTWH(110, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('3'))),
          const Rect.fromLTWH(220, 0, 200, 100));
    });

    testWidgets('Explicit CSS span placement overrides automatic flow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 300,
              child: QuantumGrid(
                columns: '100px 100px 100px',
                rows: '100px 100px 100px',
                children: [
                  QuantumItem(
                    colStart: 2,
                    colSpan: 2,
                    rowStart: 2,
                    rowSpan: 2,
                    child: Container(key: const Key('target')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Col 2 starts at 100. Row 2 starts at 100. Spans 2 tracks (100 * 2 = 200).
      expect(tester.getRect(find.byKey(const Key('target'))),
          const Rect.fromLTWH(100, 100, 200, 200));
    });
  });

  group('3. QuantumGrid - Flow Algorithms & Dense Bitmasks', () {
    testWidgets('Auto-placement Row Flow (Left-to-Right, Top-to-Bottom)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: QuantumGrid(
                columns: '100px 100px',
                rows: '10px 10px',
                flow: QFlowDirection.row,
                children: List.generate(4, (i) => Container(key: Key('box$i'))),
              ),
            ),
          ),
        ),
      );

      expect(
          tester.getTopLeft(find.byKey(const Key('box0'))), const Offset(0, 0));
      expect(tester.getTopLeft(find.byKey(const Key('box1'))),
          const Offset(100, 0));
      expect(tester.getTopLeft(find.byKey(const Key('box2'))),
          const Offset(0, 10));
      expect(tester.getTopLeft(find.byKey(const Key('box3'))),
          const Offset(100, 10));
    });

    testWidgets('Row Dense automatically back-fills empty grid bitmask slots',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: QuantumGrid(
                columns: '100px 100px 100px',
                rows: '50px 50px',
                flow: QFlowDirection.rowDense,
                children: [
                  QuantumItem(
                      colSpan: 2, child: Container(key: const Key('wide'))),
                  QuantumItem(
                      colSpan: 2, child: Container(key: const Key('wide2'))),
                  QuantumItem(
                      colSpan: 1, child: Container(key: const Key('small'))),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getRect(find.byKey(const Key('wide'))),
          const Rect.fromLTWH(0, 0, 200, 50));
      expect(tester.getRect(find.byKey(const Key('wide2'))),
          const Rect.fromLTWH(0, 50, 200, 50));
      // Proves the dense packing algorithm successfully found the hole in the previous row
      expect(tester.getRect(find.byKey(const Key('small'))),
          const Rect.fromLTWH(200, 0, 100, 50));
    });

    testWidgets(
        'Ignore Occupancy allows multi-item stacking in the same grid cell',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: QuantumGrid(
                columns: '100px',
                rows: '100px',
                children: [
                  QuantumItem(
                      ignoreOccupancy: true,
                      child: Container(key: const Key('ghost'))),
                  QuantumItem(child: Container(key: const Key('solid'))),
                ],
              ),
            ),
          ),
        ),
      );

      // Both items occupy (0,0) because the first one told the bitmask to ignore it.
      expect(tester.getRect(find.byKey(const Key('ghost'))),
          const Rect.fromLTWH(0, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('solid'))),
          const Rect.fromLTWH(0, 0, 100, 100));
    });
  });

  group('4. QuantumGrid - Masonry & 2D Virtualization', () {
    testWidgets('Masonry Waterfall Algorithm picks shortest column',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: QuantumGrid(
                columns: '100px 100px 100px', // 3 Columns
                flow: QFlowDirection.masonry,
                children: [
                  SizedBox(height: 50, key: const Key('c1')),
                  SizedBox(height: 100, key: const Key('c2')),
                  SizedBox(height: 80, key: const Key('c3')),
                  SizedBox(height: 60, key: const Key('c4')),
                  SizedBox(height: 20, key: const Key('c5')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
          tester.getTopLeft(find.byKey(const Key('c1'))), const Offset(0, 0));
      expect(
          tester.getTopLeft(find.byKey(const Key('c2'))), const Offset(100, 0));
      expect(
          tester.getTopLeft(find.byKey(const Key('c3'))), const Offset(200, 0));

      // Waterfall routing checks (Should stack under shortest col)
      expect(tester.getTopLeft(find.byKey(const Key('c4'))),
          const Offset(0, 50)); // Col 1
      expect(tester.getTopLeft(find.byKey(const Key('c5'))),
          const Offset(200, 80)); // Col 3
    });
  });

  group('5. QuantumGrid - Alignments, Justifications & RTL', () {
    testWidgets('Item-level alignment overrides grid-level alignment',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: QuantumGrid(
                columns: '100px',
                rows: '100px',
                alignItems: QAlign.stretch,
                justifyItems: QAlign.stretch,
                children: [
                  QuantumItem(
                    alignSelf: QAlign.center,
                    justifySelf: QAlign.center,
                    child:
                        const SizedBox(width: 40, height: 40, key: Key('box')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // The track is 100x100. Item is 40x40. Centered perfectly inside.
      expect(tester.getRect(find.byKey(const Key('box'))),
          const Rect.fromLTWH(30, 30, 40, 40));
    });

    testWidgets('RTL TextDirection flips X coordinates globally',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl, // 🚀 RTL FLIP
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 100,
              child: QuantumGrid(
                columns: '100px 100px 100px',
                rows: '100px',
                children: [
                  Container(key: const Key('c1')),
                  Container(key: const Key('c2')),
                  Container(key: const Key('c3')),
                ],
              ),
            ),
          ),
        ),
      );

      // In RTL, the FIRST auto-placed element goes to the FAR RIGHT
      expect(tester.getRect(find.byKey(const Key('c1'))),
          const Rect.fromLTWH(200, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('c2'))),
          const Rect.fromLTWH(100, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('c3'))),
          const Rect.fromLTWH(0, 0, 100, 100));
    });
  });

  group('6. QuantumGrid - Z-Index Painting & Hit Testing', () {
    testWidgets('Higher Z-Index paints on top and intercepts gestures',
        (WidgetTester tester) async {
      bool tappedBottom = false;
      bool tappedTop = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: QuantumGrid(
                columns: '100px',
                rows: '100px',
                children: [
                  QuantumItem(
                    zIndex: 0,
                    ignoreOccupancy: true,
                    child: GestureDetector(
                      onTap: () => tappedBottom = true,
                      child: Container(
                          color: Colors.red, key: const Key('bottom')),
                    ),
                  ),
                  QuantumItem(
                    zIndex: 99, // 🚀 Boosted Z-Index
                    ignoreOccupancy: true,
                    child: GestureDetector(
                      onTap: () => tappedTop = true,
                      child:
                          Container(color: Colors.blue, key: const Key('top')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify bounds are identical
      expect(tester.getRect(find.byKey(const Key('bottom'))),
          const Rect.fromLTWH(0, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('top'))),
          const Rect.fromLTWH(0, 0, 100, 100));

      // Tap exact center
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      expect(tappedTop, isTrue,
          reason: 'High z-index item should intercept hit tests');
      expect(tappedBottom, isFalse,
          reason: 'Low z-index item should be blocked by upper layer');
    });
  });

  group('7. QuantumSliverDelegate - Advanced Viewport Integration', () {
    testWidgets(
        'auto-fill generates exact dynamic tracks relative to crossAxisExtent',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 350, // 🚀 Dynamic Constraint Width (Must be respected)
              height: 500,
              child: CustomScrollView(
                slivers: [
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Container(key: Key('s_$i')),
                      childCount: 4,
                    ),
                    gridDelegate: QuantumSliverDelegate(
                      cols: QParser.parse('repeat(auto-fill, 100px)'),
                      rows: QParser.parse('100px'),
                      colGap: 10.0,
                      rowGap: 10.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Math verification: width 350. Gap 10.
      // (100 + 10) * X <= 360 -> X = 3 columns.
      // Child 0: Col 1, Child 1: Col 2, Child 2: Col 3, Child 3: Wrapped to Row 2!

      expect(tester.getRect(find.byKey(const Key('s_0'))),
          const Rect.fromLTWH(0, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('s_1'))),
          const Rect.fromLTWH(110, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('s_2'))),
          const Rect.fromLTWH(220, 0, 100, 100));
      expect(tester.getRect(find.byKey(const Key('s_3'))),
          const Rect.fromLTWH(0, 110, 100, 100));
    });
  });
  group('8. QuantumGrid - Intrinsic Sizing (auto, fit-content, minmax)', () {
    testWidgets('auto tracks wrap exactly to the child\'s intrinsic size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: QuantumGrid(
              columns: 'auto auto',
              rows: 'auto',
              children: [
                SizedBox(width: 50, height: 75, key: const Key('box1')),
                SizedBox(width: 120, height: 40, key: const Key('box2')),
              ],
            ),
          ),
        ),
      );

      // Box 1 defines Col 1 (50px). Box 2 defines Col 2 (120px).
      // The tallest child (75px) defines the auto row height.
      expect(tester.getSize(find.byType(QuantumGrid)), const Size(170, 75));
      expect(tester.getRect(find.byKey(const Key('box1'))),
          const Rect.fromLTWH(0, 0, 50, 75));
      expect(tester.getRect(find.byKey(const Key('box2'))),
          const Rect.fromLTWH(50, 0, 120, 75));
    });

    testWidgets('fit-content clamps large children but wraps small children',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: QuantumGrid(
              columns: 'fit-content(100px) fit-content(100px)',
              rows: '50px',
              children: [
                SizedBox(width: 50, key: const Key('small')), // Wraps to 50px
                SizedBox(
                    width: 200,
                    key: const Key('large')), // Clamps to 100px limit
              ],
            ),
          ),
        ),
      );

      expect(tester.getRect(find.byKey(const Key('small'))),
          const Rect.fromLTWH(0, 0, 50, 50));
      expect(tester.getRect(find.byKey(const Key('large'))),
          const Rect.fromLTWH(50, 0, 100, 50));
    });

    testWidgets('minmax(min, max) enforces hard boundaries on flexible content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 500, // Provides 1fr space
              child: QuantumGrid(
                columns: 'minmax(100px, auto) minmax(auto, 150px) 1fr',
                rows: '50px',
                children: [
                  SizedBox(width: 50, key: const Key('b1')), // Forces min 100px
                  SizedBox(
                      width: 300, key: const Key('b2')), // Clamps max to 150px
                  Container(
                      key: const Key(
                          'b3')), // Takes remaining 250px (500 - 100 - 150)
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getRect(find.byKey(const Key('b1'))),
          const Rect.fromLTWH(0, 0, 100, 50));
      expect(tester.getRect(find.byKey(const Key('b2'))),
          const Rect.fromLTWH(100, 0, 150, 50));
      expect(tester.getRect(find.byKey(const Key('b3'))),
          const Rect.fromLTWH(250, 0, 250, 50));
    });
  });

  group('9. QuantumGrid - Column Flow & Advanced Placement', () {
    testWidgets('Column flow routes items Top-to-Bottom, Left-to-Right',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 200,
              child: QuantumGrid(
                columns: '100px 100px',
                rows: '100px 100px',
                flow: QFlowDirection.column, // 🚀 Vertical Flow
                children: List.generate(4, (i) => Container(key: Key('c$i'))),
              ),
            ),
          ),
        ),
      );

      expect(
          tester.getTopLeft(find.byKey(const Key('c0'))), const Offset(0, 0));
      expect(tester.getTopLeft(find.byKey(const Key('c1'))),
          const Offset(0, 100)); // Goes DOWN first
      expect(tester.getTopLeft(find.byKey(const Key('c2'))),
          const Offset(100, 0)); // Then RIGHT
      expect(tester.getTopLeft(find.byKey(const Key('c3'))),
          const Offset(100, 100));
    });

    testWidgets('ColSpan clamps safely if it exceeds available grid bounds',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: QuantumGrid(
                columns: '100px 100px 100px',
                rows: '50px',
                children: [
                  QuantumItem(
                    colSpan: 10, // Exceeds grid! Engine should clamp to 3
                    child: Container(key: const Key('huge')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Safely clamped to max columns (300px) instead of crashing or expanding into infinity
      expect(tester.getRect(find.byKey(const Key('huge'))),
          const Rect.fromLTWH(0, 0, 300, 50));
    });
  });

  group('10. QuantumGrid - Edge Cases & Layout Armor', () {
    testWidgets('Zero children renders a 0x0 empty box without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: QuantumGrid(
              columns: '1fr 1fr',
              rows: '100px',
              children: const [], // Empty
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(QuantumGrid)), Size.zero);
    });

    testWidgets(
        'Infinite constraints do not crash the engine (Scroll View Simulator)',
        (WidgetTester tester) async {
      // Placing QuantumGrid inside a Row without constraints simulates infinite width
      // Placing it inside SingleChildScrollView simulates infinite height
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              // Infinite Height
              child: Row(
                // Infinite Width
                children: [
                  QuantumGrid(
                    columns: '100px 100px',
                    rows: '50px 50px',
                    children: [
                      Container(key: const Key('box')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // The layout engine should have treated infinite constraints as 0.0 for fractions
      // but correctly honored fixed track sizes.
      expect(tester.getRect(find.byKey(const Key('box'))),
          const Rect.fromLTWH(0, 0, 100, 50));
      expect(tester.getSize(find.byType(QuantumGrid)),
          const Size(200, 100)); // 2x100w, 2x50h
    });
  });

  group('11. QuantumGrid - Alignments & Justifications Details', () {
    testWidgets('Resolves start, center, and end Alignments exactly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 300,
              child: QuantumGrid(
                columns: '100px',
                rows: '100px 100px 100px',
                children: [
                  QuantumItem(
                    alignSelf: QAlign.start,
                    justifySelf: QAlign.start,
                    child: const SizedBox(
                        width: 40, height: 40, key: Key('start')),
                  ),
                  QuantumItem(
                    alignSelf: QAlign.center,
                    justifySelf: QAlign.center,
                    child: const SizedBox(
                        width: 40, height: 40, key: Key('center')),
                  ),
                  QuantumItem(
                    alignSelf: QAlign.end,
                    justifySelf: QAlign.end,
                    child:
                        const SizedBox(width: 40, height: 40, key: Key('end')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Cell 1: 0 to 100 -> start = 0,0
      expect(tester.getRect(find.byKey(const Key('start'))),
          const Rect.fromLTWH(0, 0, 40, 40));
      // Cell 2: 100 to 200 -> center = (100-40)/2 = 30
      expect(tester.getRect(find.byKey(const Key('center'))),
          const Rect.fromLTWH(30, 130, 40, 40));
      // Cell 3: 200 to 300 -> end = 100-40 = 60
      expect(tester.getRect(find.byKey(const Key('end'))),
          const Rect.fromLTWH(60, 260, 40, 40));
    });
  });

  group('12. QuantumSliverDelegate - Native Engine Math Checks', () {
    // We can unit-test the delegate directly without inflating a widget tree
    // to prove its scroll offset predictions are mathematically sound.
    test('Calculates geometry and scroll offsets for uniform grids', () {
      final delegate = QuantumSliverDelegate(
        cols: QParser.parse('100px 100px'), // 2 cols
        rows: QParser.parse('50px'), // Uniform 50px rows
        colGap: 10,
        rowGap: 10,
      );

      final layout = delegate.getLayout(const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 1000.0,
        crossAxisExtent: 210.0,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 1000.0,
        remainingCacheExtent: 1000.0,
        cacheOrigin: 0.0,
      ));

      // Row height = 50. Row gap = 10. Pattern = 60.

      // Index 0 (Row 1, Col 1) -> Scroll offset should be 0
      var geom = layout.getGeometryForChildIndex(0);
      expect(geom.scrollOffset, 0.0);
      expect(geom.crossAxisOffset, 0.0);

      // Index 3 (Row 2, Col 2) -> Scroll offset should be 1 row + gap (60.0)
      geom = layout.getGeometryForChildIndex(3);
      expect(geom.scrollOffset, 60.0);
      expect(geom.crossAxisOffset, 110.0);

      // Scroll Offset Check
      // If we scroll down 65 pixels, we are in Row 2. The first index of Row 2 is 2.
      expect(layout.getMinChildIndexForScrollOffset(65.0), 2);

      // Total Scroll Extent for 5 items (Requires 3 rows)
      // 3 rows = 50 + 10 + 50 + 10 + 50 = 170. Gap removed at end = 170 - 10 = 170
      // Wait, 3 complete rows = 3 * 60 = 180. Minus tailing gap = 170.
      expect(layout.computeMaxScrollOffset(5), 170.0);
    });
  });
}
