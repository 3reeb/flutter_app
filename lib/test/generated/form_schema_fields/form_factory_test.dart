// test/engine/form_factory_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('QLSchemaFormFactory: Advanced Field Types', () {
    test('QLSecureController supports obscure toggling and secure wiping', () {
      final blueprint = QLSchemaCompiler.compile('Auth', {
        "password": {"type": "secure"}
      });
      final form = QLFormController();
      QLSchemaFormFactory.build(blueprint, form);

      final pass = form.getNode('password') as QLSecureController;

      expect(pass.isObscured.value, isTrue); // Default true
      pass.toggleObscure();
      expect(pass.isObscured.value, isFalse);

      pass.mutate('my_secret_key');
      expect(pass.data.value, 'my_secret_key');

      pass.secureWipe(); // Overwrites memory with 0s before clearing
      expect(pass.data.value, '');
    });

    test('QLEnumController strictly bounds input to allowed options', () {
      final blueprint = QLSchemaCompiler.compile('Status', {
        "state": {
          "type": "enum",
          "options": ["active", "pending"]
        }
      });
      final form = QLFormController();
      QLSchemaFormFactory.build(blueprint, form);

      final state = form.getNode('state') as QLEnumController;

      state.mutate('active');
      expect(state.data.value, 'active');

      state.mutate('hacked_state'); // Should be rejected instantly
      expect(state.data.value, 'active');
    });

    test('QLFlagsController accurately executes bitwise operations', () {
      final blueprint = QLSchemaCompiler.compile('Settings', {
        "permissions": {"type": "flags"}
      });
      final form = QLFormController();
      QLSchemaFormFactory.build(blueprint, form);

      final flags = form.getNode('permissions') as QLFlagsController;

      flags.enableFlag(1 << 0); // 1
      flags.enableFlag(1 << 2); // 4
      expect(flags.data.value, 5);

      flags.disableFlag(1 << 0);
      expect(flags.data.value, 4);

      flags.toggleFlag(1 << 1); // 2
      expect(flags.data.value, 6);
    });
  });
}
