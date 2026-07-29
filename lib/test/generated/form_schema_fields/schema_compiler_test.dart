import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  setUp(() => QLSchemaRegistry.instance.clear());

  group('QLSchemaCompiler: Smart Projections & Read Plans', () {
    test('mergeProjectedRecord perfectly stitches partial network responses',
        () {
      final blueprint = QLSchemaCompiler.compile('User', {
        "id": "string",
        "settings": {
          "type": "object",
          "fields": {"theme": "string", "notifs": "bool"}
        }
      });

      // FIX: Explicitly type the maps so Dart doesn't strictly infer Map<String, String>
      final cached = <String, dynamic>{
        "id": "1",
        "settings": <String, dynamic>{"theme": "dark"}
      };
      final incoming = <String, dynamic>{
        "settings": <String, dynamic>{"notifs": true}
      };

      final merged = blueprint
          .mergeProjectedRecord(cached, incoming, select: ['settings.notifs']);

      expect(merged['id'], '1');
      expect(merged['settings']['theme'], 'dark');
      expect(merged['settings']['notifs'], isTrue);
    });
  });
}
