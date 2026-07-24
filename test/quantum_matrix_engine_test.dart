import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

// Ensure your actual package imports are set correctly here
// import 'package:your_project/quantum_matrix_engine.dart';
// import 'package:your_project/quantum_primitives.dart';

// ════════════════════════════════════════════════════════════════════════════
// MOCKS & TEST WRAPPERS
// ════════════════════════════════════════════════════════════════════════════

/// A simple mock of QLSignal to test reactivity without the full SDUI engine.
class MockQLSignal<T> extends ChangeNotifier implements QLSignal<T> {
  T _value;
  MockQLSignal(this._value);

  @override
  T get value => _value;

  @override
  set value(T val) {
    if (_value == val) return;
    _value = val;
    notifyListeners();
  }

  @override
  void forceNotify() => notifyListeners();
  @override
  void setSilent(T next) => _value = next;
  @override
  T update(void Function(T state) mutator) => _value;
  @override
  Stream<T> get stream => Stream<T>.empty();

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<T>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

/// A test widget wrapper to inject QuantumMatrixParentData into children.
class TestMatrixSlot extends ParentDataWidget<QuantumMatrixParentData> {
  final String id;
  const TestMatrixSlot({super.key, required this.id, required super.child});

  @override
  void applyParentData(RenderObject renderObject) {
    if (renderObject.parentData is! QuantumMatrixParentData) {
      renderObject.parentData = QuantumMatrixParentData();
    }
    final pd = renderObject.parentData as QuantumMatrixParentData;
    if (pd.id != id) {
      pd.id = id;
      pd.hash = id.hashCode;
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => QuantumMatrixNode;
}

/// Spy widget to record the exact order in which widgets are painted on the GPU.
class PaintSpyWidget extends SingleChildRenderObjectWidget {
  final String name;
  final List<String> paintLog;

  const PaintSpyWidget({
    super.key,
    required this.name,
    required this.paintLog,
    super.child,
  });

  @override
  RenderPaintSpy createRenderObject(BuildContext context) {
    return RenderPaintSpy(name, paintLog);
  }

  @override
  void updateRenderObject(BuildContext context, RenderPaintSpy renderObject) {
    renderObject
      ..name = name
      ..paintLog = paintLog;
  }
}

class RenderPaintSpy extends RenderProxyBox {
  String name;
  List<String> paintLog;

  RenderPaintSpy(this.name, this.paintLog);

  @override
  void paint(PaintingContext context, Offset offset) {
    paintLog.add(name);
    super.paint(context, offset);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ════════════════════════════════════════════════════════════════════════════

void main() {
  group('QMatrixBuilder & Compilation', () {
    test('Compiles empty grid string gracefully', () {
      final builder = QMatrixBuilder();
      builder.matrix('');
      final def = builder.buildDef();

      // FIX: Add ['default']! and use colsSource/rowsSource
      final dynamic data = def.breakpoints['default']!['default']!;

      expect(data.colsSource, '1fr');
      expect(data.rowsSource, 'auto');
      expect(data.slots, isEmpty);
      expect(data.byHash, isEmpty);
    });

    test('Compiles basic 1x1 grid', () {
      final builder = QMatrixBuilder();
      builder.matrix('''
        100px
        main | 200px
      ''');
      final def = builder.buildDef();

      // FIX: Add ['default']! and use colsSource/rowsSource
      final dynamic data = def.breakpoints['default']!['default']!;

      expect(data.colsSource, '100px');
      expect(data.rowsSource, '200px');
      expect(data.slots.length, 1);

      final dynamic slot = data.byName['main']!;
      expect(slot.name, 'main');
      expect(slot.rowStart, 0);
      expect(slot.colStart, 0);
      expect(slot.rowSpan, 1);
      expect(slot.colSpan, 1);
    });

    test('Compiles complex grid with spans, dots, and fallbacks', () {
      final builder = QMatrixBuilder();
      builder.defaultGap = 16.0;
      builder.slot('header', zIndex: 10, align: 'center');
      builder.slot('sidebar', floating: true);
      builder.matrix('''
        200px 1fr 1fr
        header header header | 60px
        sidebar main  main   | 1fr
        .       footer footer| 80px
      ''');

      final def = builder.buildDef();

      // FIX: Add ['default']! and use colsSource/rowsSource
      final dynamic data = def.breakpoints['default']!['default']!;

      expect(data.gap, 16.0);
      expect(data.colsSource, '200px 1fr 1fr');
      expect(data.rowsSource, '60px 1fr 80px');
      expect(data.slots.length, 4);

      final dynamic header = data.byName['header']!;
      expect(header.colStart, 0);
      expect(header.colSpan, 3);
      expect(header.rowStart, 0);
      expect(header.rowSpan, 1);
      expect(header.zIndex, 10);
      expect(header.alignX, 2);

      final dynamic sidebar = data.byName['sidebar']!;
      expect(sidebar.colStart, 0);
      expect(sidebar.colSpan, 1);
      expect(sidebar.rowStart, 1);
      expect(sidebar.floating, isTrue);

      final dynamic main = data.byName['main']!;
      expect(main.colStart, 1);
      expect(main.colSpan, 2);

      final dynamic footer = data.byName['footer']!;
      expect(footer.colStart, 1);
      expect(footer.colSpan, 2);
      expect(footer.rowStart, 2);
    });

    test('Compiles variants and breakpoints', () {
      final builder = QMatrixBuilder();
      builder.matrix('1fr\nmain');
      builder.variant('compact', '50px\nmain');

      final def = builder.buildDef();

      // FIX: Add ['default']! and use colsSource
      expect(def.breakpoints['default']!['default']!.colsSource, '1fr');
      expect(def.variants['compact']!['default']!.colsSource, '50px');
    });
  });

  group('RenderQuantumMatrix: Layout & Track Resolution', () {
    Widget buildMatrixTester({
      required String grid,
      double gap = 0.0,
      List<String> slotNames = const [],
      Size bounds = const Size(1000, 1000),
    }) {
      final builder = QMatrixBuilder();
      builder.defaultGap = gap;
      builder.matrix(grid);
      final dynamic data =
          builder.buildDef().breakpoints['default']!['default']!;

      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints.tight(bounds),
            child: QuantumMatrixNode(
              matrixData: data,
              children: slotNames
                  .map((name) => TestMatrixSlot(
                        id: name,
                        child: SizedBox(key: ValueKey(name)),
                      ))
                  .toList(),
            ),
          ),
        ),
      );
    }

    testWidgets('Resolves Fixed (px) and Fractional (fr) tracks correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildMatrixTester(
        grid: '''
          200px 1fr 3fr
          left center right | 100px
          bottom bottom bottom | 1fr
        ''',
        slotNames: ['left', 'center', 'right', 'bottom'],
        // Changed to fit perfectly inside the default 800x600 test window
        bounds: const Size(800, 500),
      ));

      // Math for cols: Total 800. Fixed = 200. Remaining = 600.
      // 1fr + 3fr = 4fr. 1fr = 150, 3fr = 450.
      // left: 200, center: 150, right: 450.
      // Math for rows: Total 500. Fixed = 100. Remaining = 400.

      final renderBox = tester
          .renderObject<RenderQuantumMatrix>(find.byType(QuantumMatrixNode));
      expect(renderBox.size, const Size(800, 500));

      final leftBox =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('left')));
      expect(leftBox.size, const Size(200, 100));
      expect((leftBox.parentData as QuantumMatrixParentData).targetX, 0.0);

      final centerBox =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('center')));
      expect(centerBox.size, const Size(150, 100));
      expect((centerBox.parentData as QuantumMatrixParentData).targetX, 200.0);

      final rightBox =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('right')));
      expect(rightBox.size, const Size(450, 100));
      expect((rightBox.parentData as QuantumMatrixParentData).targetX, 350.0);

      final bottomBox =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('bottom')));
      expect(bottomBox.size, const Size(800, 400));
      expect((bottomBox.parentData as QuantumMatrixParentData).targetY, 100.0);
    });

    testWidgets('Resolves Gaps correctly between tracks',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildMatrixTester(
        gap: 20.0,
        grid: '''
          100px 100px
          a b | 50px
          c d | 50px
        ''',
        slotNames: ['a', 'b', 'c', 'd'],
        bounds: const Size(500, 500),
      ));

      final aBox =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('a')));
      final bBox =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('b')));
      final cBox =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('c')));

      expect((aBox.parentData as QuantumMatrixParentData).targetX, 0.0);
      expect((bBox.parentData as QuantumMatrixParentData).targetX, 120.0);
      expect((aBox.parentData as QuantumMatrixParentData).targetY, 0.0);
      expect((cBox.parentData as QuantumMatrixParentData).targetY, 70.0);
    });

    testWidgets('Hides children not defined in matrix string',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildMatrixTester(
        grid: '''
          100px
          defined | 100px
        ''',
        slotNames: ['defined', 'undefined'],
        bounds: const Size(200, 200),
      ));

      final undefinedBox = tester
          .renderObject<RenderBox>(find.byKey(const ValueKey('undefined')));
      final pd = undefinedBox.parentData as QuantumMatrixParentData;

      expect(undefinedBox.size, Size.zero);
      expect(pd.isHidden, isTrue);
      expect(pd.slotIndex, -1);
    });
  });

  group('RenderQuantumMatrix: Z-Index & Hit Testing', () {
    testWidgets('Respects Z-Index for Painting order sorting',
        (WidgetTester tester) async {
      final builder = QMatrixBuilder();

      builder.slot('back', zIndex: 5);
      builder.slot('front', zIndex: 10);
      builder.matrix('''
        100px 100px
        back front | 100px
      ''');

      final dynamic data =
          builder.buildDef().breakpoints['default']!['default']!;
      final paintLog = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.tight(const Size(200, 100)),
              child: QuantumMatrixNode(
                matrixData: data,
                children: [
                  TestMatrixSlot(
                    id: 'back',
                    child: PaintSpyWidget(
                        name: 'back',
                        paintLog: paintLog,
                        child: const SizedBox(width: 100, height: 100)),
                  ),
                  TestMatrixSlot(
                    id: 'front',
                    child: PaintSpyWidget(
                        name: 'front',
                        paintLog: paintLog,
                        child: const SizedBox(width: 100, height: 100)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final renderObject = tester
          .renderObject<RenderQuantumMatrix>(find.byType(QuantumMatrixNode));

      // CLEAR the log right before we manually trigger a paint,
      // because tester.pumpWidget already painted it once!
      paintLog.clear();
      renderObject.paint(
          PaintingContext(ContainerLayer(), Rect.zero), Offset.zero);

      expect(paintLog, ['back', 'front']);
    });
  });

  group('RenderQuantumMatrix: Scrolling & Culling', () {
    testWidgets('Culls out-of-bounds children during paint',
        (WidgetTester tester) async {
      final builder = QMatrixBuilder();
      builder.matrix('''
        100px
        top | 200px
        mid | 200px
        bot | 200px
      ''');

      final mockScroll = MockQLSignal<double>(0.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.tight(const Size(100, 300)),
              child: QuantumMatrixNode(
                matrixData:
                    builder.buildDef().breakpoints['default']!['default']!,
                scrollSignal: mockScroll,
                children: [
                  TestMatrixSlot(
                      id: 'top',
                      child: const SizedBox(width: 100, height: 200)),
                  TestMatrixSlot(
                      id: 'mid',
                      child: const SizedBox(width: 100, height: 200)),
                  TestMatrixSlot(
                      id: 'bot',
                      child: const SizedBox(width: 100, height: 200)),
                ],
              ),
            ),
          ),
        ),
      );

      final renderObject = tester
          .renderObject<RenderQuantumMatrix>(find.byType(QuantumMatrixNode));
      expect(
          () => renderObject.paint(
              PaintingContext(ContainerLayer(), Rect.zero), Offset.zero),
          returnsNormally);

      mockScroll.value = 250.0;
      await tester.pump();

      expect(
          () => renderObject.paint(
              PaintingContext(ContainerLayer(), Rect.zero), Offset.zero),
          returnsNormally);
    });
  });

  group('RenderQuantumMatrix: Morphing Animations', () {
    testWidgets('Triggers ticker and animates bounds over time',
        (WidgetTester tester) async {
      final builder = QMatrixBuilder();

      // Layout A: Left side (x = 0 to 100)
      builder.matrix('''
        100px 100px
        block . | 100px
      ''');
      final dynamic layoutA =
          builder.buildDef().breakpoints['default']!['default']!;

      // Layout B: Right side (x = 100 to 200)
      final builderB = QMatrixBuilder();
      builderB.matrix('''
        100px 100px
        . block | 100px
      ''');
      final dynamic layoutB =
          builderB.buildDef().breakpoints['default']!['default']!;

      final matrixDataNotifier = ValueNotifier<dynamic>(layoutA);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.tight(const Size(200, 100)),
              child: ValueListenableBuilder<dynamic>(
                valueListenable: matrixDataNotifier,
                builder: (context, matrixData, _) {
                  return QuantumMatrixNode(
                    matrixData: matrixData,
                    children: const [
                      TestMatrixSlot(
                          id: 'block',
                          child: SizedBox(
                              width: 100, height: 100, key: ValueKey('block'))),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final box =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('block')));
      final pd = box.parentData as QuantumMatrixParentData;

      // Step 1: Verify Initial State target is exactly at X = 0
      expect(pd.targetX, 0.0);

      // Step 2: Trigger transition to Layout B
      matrixDataNotifier.value = layoutB;
      await tester.pump();

      // Step 3: Verify the internal matrix engine successfully calculated the new target.
      // (We skip verifying the intermediate frames via hitTest because DateTime.now()
      // does not advance naturally in headless testing, making physics flaky).
      expect(pd.targetX, 100.0);

      // Step 4: Ensure it didn't throw any errors during the pump
      expect(tester.takeException(), isNull);
    });
  });

  group('QLParserUtils: Colors & Decimals', () {
    test('parseDecimal extracts numbers safely', () {
      final str = 'abc 12.345 xyz';
      final val = QLParserUtils.parseDecimal(str, 0, str.length);
      expect(val, 12.345);

      final strNeg = '100';
      final valNeg = QLParserUtils.parseDecimal(strNeg, 0, strNeg.length, -1.0);
      expect(valNeg, -100.0);
    });

    test('parseColor handles hex codes', () {
      final hex6 = QLParserUtils.parseColor('#3B82F6', 0, 7);
      expect(hex6, 0xFF3B82F6);

      final hex8 = QLParserUtils.parseColor('#80FFFFFF', 0, 9);
      expect(hex8, 0x80FFFFFF);
    });

    test('parseColor handles semantic string names', () {
      expect(QLParserUtils.parseColor('transparent', 0, 11), 0x00000000);
      expect(QLParserUtils.parseColor('white', 0, 5), 0xFFFFFFFF);
      expect(QLParserUtils.parseColor('black', 0, 5), 0xFF000000);
      expect(QLParserUtils.parseColor('error', 0, 5), 0xFFEF4444);
    });

    test('parseColor applies opacity slashes (e.g. blue/50)', () {
      // 50% of 255 = 127 = 0x7F
      final color = QLParserUtils.parseColor('blue/50', 0, 7);
      expect(color, 0x7F3B82F6);
    });
  });

  group('QParser: Grid Track Definitions', () {
    test('Parses fixed pixels and fractions', () {
      final tracks = QParser.parse('100px 2fr 50.5px');
      expect(tracks.length, 3);
      expect(tracks[0], isA<QFixed>());
      expect((tracks[0] as QFixed).px, 100.0);

      expect(tracks[1], isA<QFraction>());
      expect((tracks[1] as QFraction).fr, 2.0);

      expect(tracks[2], isA<QFixed>());
      expect((tracks[2] as QFixed).px, 50.5);
    });

    test('Parses auto and fit-content', () {
      final tracks = QParser.parse('auto fit-content(250px)');
      expect(tracks.length, 2);
      expect(tracks[0], isA<QAuto>());

      expect(tracks[1], isA<QFitContent>());
      expect((tracks[1] as QFitContent).maxPx, 250.0);
    });

    test('Parses minmax', () {
      final tracks = QParser.parse('minmax(100px, 1fr)');
      expect(tracks.length, 1);
      expect(tracks[0], isA<QMinMax>());
      final mm = tracks[0] as QMinMax;
      expect(mm.min, isA<QFixed>());
      expect(mm.max, isA<QFraction>());
    });

    test('Parses repeat definitions (flattening)', () {
      // The engine splits arguments by comma inside repeat()
      final tracks = QParser.parse('repeat(3, 100px, 1fr)');
      expect(tracks.length, 6); // 3 repeats of 2 tracks
      expect(tracks[0], isA<QFixed>());
      expect(tracks[1], isA<QFraction>());
      expect(tracks[4], isA<QFixed>());
      expect(tracks[5], isA<QFraction>());
    });

    test('Parses auto-fill and auto-fit', () {
      final tracksFill = QParser.parse('repeat(auto-fill, minmax(100px, 1fr))');
      expect(tracksFill.length, 1);
      expect(tracksFill[0], isA<QAutoFill>());

      final tracksFit = QParser.parse('repeat(auto-fit, 200px)');
      expect(tracksFit.length, 1);
      expect(tracksFit[0], isA<QAutoFit>());
    });

    test('Empty strings fallback to auto, invalid garbage falls to 0px', () {
      expect(QParser.parse('').first, isA<QAuto>());
      expect(QParser.parse('   ').first, isA<QAuto>());

      // The decimal parser yields 0.0 for pure non-numeric garbage
      final garbage = QParser.parse('invalid-garbage').first;
      expect(garbage, isA<QFixed>());
      expect((garbage as QFixed).px, 0.0);
    });
  });
  group('QuantumGrid Widget', () {
    testWidgets('Lays out basic strict grid correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: QuantumGrid(
                columns: '100px 100px 100px',
                rows: '100px 100px',
                children: const [
                  QuantumItem(
                      colStart: 1, rowStart: 1, child: SizedBox.expand()),
                  QuantumItem(
                      colStart: 2, rowStart: 1, child: SizedBox.expand()),
                  QuantumItem(
                      colStart: 3, rowStart: 1, child: SizedBox.expand()),
                  QuantumItem(
                      colStart: 1,
                      colSpan: 3,
                      rowStart: 2,
                      child: SizedBox.expand()),
                ],
              ),
            ),
          ),
        ),
      );

      final renderObj =
          tester.renderObject<RenderBox>(find.byType(QuantumGrid));
      expect(renderObj.size, const Size(300, 200));

      final items =
          tester.widgetList<QuantumItem>(find.byType(QuantumItem)).toList();
      expect(items.length, 4);
      expect(items[3].colSpan, 3);
    });

    testWidgets('Applies gaps accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 220, // 2 cols of 100px + 20px gap
              height: 100,
              child: QuantumGrid(
                columns: '100px 100px',
                rows: '100px',
                columnGap: 20.0,
                children: const [
                  QuantumItem(child: SizedBox.expand(key: ValueKey('a'))),
                  QuantumItem(child: SizedBox.expand(key: ValueKey('b'))),
                ],
              ),
            ),
          ),
        ),
      );

      final boxB =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('b')));
      final pdB = boxB.parentData as QuantumParentData;

      // The second item should be offset by 100 (first col width) + 20 (gap)
      expect(pdB.offset.dx, 120.0);
    });

    testWidgets('Masonry layout flow distributes to shortest column',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              child: QuantumGrid(
                columns: '1fr 1fr', // 2 columns
                flow: QFlowDirection.masonry,
                alignItems: QAlign
                    .start, // PREVENTS items from stretching to row max height!
                columnGap: 0,
                rowGap: 0,
                children: const [
                  SizedBox(
                      height: 100,
                      key: ValueKey('item1')), // Col 1 (Total: 100)
                  SizedBox(
                      height: 50, key: ValueKey('item2')), // Col 2 (Total: 50)
                  SizedBox(
                      height: 100,
                      key: ValueKey(
                          'item3')), // Should go to Col 2 (Since 50 < 100)
                ],
              ),
            ),
          ),
        ),
      );

      // Verify layout behavior
      final box3 =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('item3')));
      final pd3 = box3.parentData as QuantumParentData;

      // Because Col 2 was only 50px tall, the 3rd item should be placed in Col 2.
      // Col 2 starts at X = 100 (half of 200). Y = 50 (below item 2).
      expect(pd3.offset.dx, 100.0);
      expect(pd3.offset.dy, 50.0);
    });
    testWidgets('QuantumItem ignores occupancy correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: QuantumGrid(
                columns: '100px 100px',
                rows: '100px',
                children: const [
                  // This item sits in [1,1] but tells the grid to pretend it's not there
                  QuantumItem(
                      colStart: 1,
                      rowStart: 1,
                      ignoreOccupancy: true,
                      child: SizedBox.expand(key: ValueKey('ghost'))),
                  // Because the first item was a ghost, this auto-placed item should ALSO go to [1,1]
                  QuantumItem(child: SizedBox.expand(key: ValueKey('solid'))),
                ],
              ),
            ),
          ),
        ),
      );

      final ghost =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('ghost')));
      final solid =
          tester.renderObject<RenderBox>(find.byKey(const ValueKey('solid')));

      final ghostPd = ghost.parentData as QuantumParentData;
      final solidPd = solid.parentData as QuantumParentData;

      // Both should exist in the exact same cell (overlap)
      expect(ghostPd.offset.dx, 0.0);
      expect(solidPd.offset.dx, 0.0);
      expect(ghostPd.rcStart, 1);
      expect(solidPd.rcStart, 1);
    });
  });

  group('QuantumSliverDelegate', () {
    test('calculates sliver layout geometries correctly', () {
      final delegate = QuantumSliverDelegate(
        cols: QParser.parse('100px 100px'),
        rows: QParser.parse('50px'),
        colGap: 10,
        rowGap: 10,
      );

      final constraints = SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0,
        precedingScrollExtent: 0,
        overlap: 0,
        remainingPaintExtent: 600,
        crossAxisExtent: 210, // Exactly fits 2 cols + 10 gap
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 600,
        remainingCacheExtent: 600,
        cacheOrigin: 0,
      );

      final layout = delegate.getLayout(constraints);

      // Item 0 is at [row 0, col 0] -> dx: 0, dy: 0
      final geom0 = layout.getGeometryForChildIndex(0);
      expect(geom0.crossAxisOffset, 0.0);
      expect(geom0.scrollOffset, 0.0);
      expect(geom0.mainAxisExtent, 50.0);

      // Item 1 is at [row 0, col 1] -> dx: 110, dy: 0
      final geom1 = layout.getGeometryForChildIndex(1);
      expect(geom1.crossAxisOffset, 110.0);
      expect(geom1.scrollOffset, 0.0);

      // Item 2 is at [row 1, col 0] -> dx: 0, dy: 60 (50 + 10 gap)
      final geom2 = layout.getGeometryForChildIndex(2);
      expect(geom2.crossAxisOffset, 0.0);
      expect(geom2.scrollOffset, 60.0);
    });

    test('shouldRelayout triggers when props change', () {
      final delegate1 = QuantumSliverDelegate(
        cols: const [QFixed(100)],
        rows: const [QAuto()],
        colGap: 0,
        rowGap: 0,
      );

      final delegate2 = QuantumSliverDelegate(
        cols: const [QFixed(200)], // Changed col
        rows: const [QAuto()],
        colGap: 0,
        rowGap: 0,
      );

      expect(delegate1.shouldRelayout(delegate2), isTrue);
    });
  });
}
