import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  testWidgets('QuantumLayout selects the correct child engine for each mode',
      (tester) async {
    Widget build(QLayoutType type) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: QuantumLayout(
            layoutType: type,
            children: const [Text('one'), Text('two')],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(QLayoutType.row));
    expect(find.byType(Flex), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.col));
    expect(find.byType(Flex), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.wrap));
    expect(find.byType(Wrap), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.stack));
    expect(find.byType(Stack), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.grid));
    expect(find.byType(QuantumGrid), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.split));
    expect(find.byType(QuantumSplitPane), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.none));
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('QuantumLayoutScope is available to descendants', (tester) async {
    String? layoutType;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: QuantumLayout(
            layoutType: QLayoutType.row,
            children: [
              Builder(
                builder: (context) {
                  layoutType = QuantumLayoutScope.of(context)?.layoutType;
                  return const SizedBox(width: 1, height: 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
    expect(layoutType, 'row');
  });

  testWidgets('QuantumFlex inserts spacing widgets only when gap is positive',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: QuantumFlex(
          direction: Axis.horizontal,
          gap: 12,
          children: [Text('a'), Text('b')],
        ),
      ),
    );
    final flex = tester.widget<Flex>(find.byType(Flex));
    expect(flex.children.length, 3);
  });

  testWidgets(
      'QuantumVirtualGridView and QuantumGrid build without layout exceptions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: QuantumVirtualGridView(
                  itemCount: 4,
                  itemBuilder: _itemBuilder,
                ),
              ),
              Expanded(
                child: QuantumGrid(
                  columns: '1fr 1fr',
                  rows: 'auto',
                  children: const [
                    Text('grid-a'),
                    Text('grid-b'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('grid-a'), findsOneWidget);
  });
}

Widget _itemBuilder(BuildContext context, int index) {
  return Text('item-$index');
}
