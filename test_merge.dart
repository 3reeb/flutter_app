import 'package:quantum_layout/quantum_telemetry_engine.dart';

void main() {
  TelemetryController.instance.install(
    config: const TelemetryConfig(
      maxEvents: 500,
      mergeRapidDuplicates: true,
      mergeWindowMs: 8,
    ),
  );
  TelemetryController.instance.setEnabled(true);

  for (int i = 0; i < 100; i++) {
    TelemetryController.instance.record(
      TelemetryKind.scroll,
      'ListView',
      valueA: i,
      mergeSimilar: true,
    );
  }

  final snap = TelemetryController.instance.snapshot();
  print('Snapshot length: ${snap.records.length}');
  if (snap.records.length > 0) {
    print('Event 0: ${snap.records[0].valueA}, count: ${snap.records[0].count}');
  }
  if (snap.records.length > 1) {
    print('Event 1: ${snap.records[1].valueA}, count: ${snap.records[1].count}');
  }
  if (snap.records.length > 2) {
    print('Event 2: ${snap.records[2].valueA}, count: ${snap.records[2].count}');
  }
}
