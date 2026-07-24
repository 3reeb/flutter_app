import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapQuantumTestVm();
  });

  test('template shells now use hook:lifecycle for their hook slot', () {
    final aliases = <String>['rich_shell', 'surface_shell', 'item_shell'];
    for (final alias in aliases) {
      final def = QTemplateEngine.getDef(alias);
      expect(def, isNotNull, reason: 'missing template def for $alias');
      expect(def!.defaultSlots['hook']['type'], 'hook:lifecycle');
      expect(def.guards['hook'], isNotNull);
    }
  });

  test('template shell transforms keep hook slots inert in layout', () {
    final def = QTemplateEngine.getDef('rich_shell');
    expect(def, isNotNull);
    expect(def!.guards['hook'], 'showHook');
    expect(def.transforms['hook'], 'sr-only pointer-events-none absolute opacity-0');
  });

  test('no registered shell keeps the old system:lifecycle default', () {
    for (final alias in <String>['rich_shell', 'surface_shell', 'item_shell']) {
      final def = QTemplateEngine.getDef(alias);
      expect(def, isNotNull);
      final hook = def!.defaultSlots['hook'] as Map<String, dynamic>;
      expect(hook['type'], isNot('system:lifecycle'));
    }
  });
}
