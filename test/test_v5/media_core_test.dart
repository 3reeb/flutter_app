import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Media Core Sub-types (T4.1)', () {
    testWidgets('media:audio', (WidgetTester tester) async {
      final node = blueprint('media:audio', props: {'src': 'https://example.com/audio.mp3'}, children: [
        blueprint('text', props: {'text': 'PlayerControls'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('PlayerControls'), findsOneWidget);
    });

    testWidgets('media:audio_visualizer', (WidgetTester tester) async {
      final node = blueprint('media:audio_visualizer', props: {
        'bind': 'waveform',
        'count': 32
      });
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(Placeholder), findsOneWidget); // Stubbed implementation in media_core.dart
    });

    testWidgets('media:stream (live_stream)', (WidgetTester tester) async {
      final node = blueprint('media:stream', props: {'url': 'rtsp://live'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Streaming: rtsp://live'), findsOneWidget);
    });

    testWidgets('media:webrtc', (WidgetTester tester) async {
      final node = blueprint('media:webrtc', props: {'roomId': '1234'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('WebRTC: 1234'), findsOneWidget);
    });

    testWidgets('media:camera', (WidgetTester tester) async {
      final node = blueprint('media:camera', props: {'mode': 'user'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('media:canvas_video', (WidgetTester tester) async {
      final node = blueprint('media:canvas_video', props: {'bind': 'myImage'});
      // It will return SizedBox.shrink() because signal doesn't contain a valid image yet
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
