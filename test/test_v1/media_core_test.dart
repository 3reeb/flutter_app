import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapQuantumTestVm();
  });

  testWidgets('media:image renders the image primitive without network dependency', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'media:image',
        props: <String, dynamic>{
          'src': 'https://example.com/image.png',
          'fit': 'contain',
          'quality': 80,
          'width': 96,
          'height': 72,
        },
      ),
    );

    expect(find.byType(QLImage), findsOneWidget);
  });

  testWidgets('media:avatar wraps the image in a circular frame', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'media:avatar',
        props: <String, dynamic>{
          'src': 'https://example.com/avatar.png',
          'size': 48,
        },
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.byType(QLImage), findsOneWidget);
  });

  testWidgets('media:icon resolves an IconData payload', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'media:icon',
        props: <String, dynamic>{
          'codePoint': Icons.star.codePoint,
          'fontFamily': 'MaterialIcons',
          'size': 24.0,
        },
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon?.codePoint, Icons.star.codePoint);
    expect(icon.icon?.fontFamily, 'MaterialIcons');
  });

  testWidgets('media:svg_path paints through CustomPaint', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'media:svg_path',
        props: <String, dynamic>{
          'path': 'M0 0L10 10',
          'width': 24,
          'height': 24,
          'strokeWidth': 2.0,
        },
      ),
    );

    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).toList();
    expect(paints, isNotEmpty);
    expect(paints.any((p) => p.size == const Size(24, 24)), isTrue);
  });

  testWidgets('media:svg_path accepts the legacy path alias', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'media:path',
        props: <String, dynamic>{
          'path': 'M1 1L8 8',
          'width': 16,
          'height': 16,
        },
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('subtitle tracks resolve active text by time range', () {
    final track = QLSubtitleTrack(
      Float64List.fromList(<double>[0, 1000, 1000, 2000]),
      <String>['one', 'two'],
    );

    expect(track.getActiveText(0), 'one');
    expect(track.getActiveText(500), 'one');
    expect(track.getActiveText(1000), 'two');
    expect(track.getActiveText(1500), 'two');
    expect(track.getActiveText(2500), isNull);
  });

  test('image pipeline resolver can rewrite and batch resolve locally', () async {
    final resolver = QuantumImagePipeline.instance.resolver;
    expect(resolver.rewrite('https://example.com/x.png', 64, 64, 90), 'https://example.com/x.png');
    final batch = await resolver.fetchBatch(<String>['a', 'b']);
    expect(batch.length, 2);
    expect(batch.values.every((bytes) => bytes.isNotEmpty), isTrue);
  });
}
