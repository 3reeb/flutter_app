import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('QLYamlEnv seeds and resolves values with defaults', () {
    QLYamlEnv.seed({'APP_NAME': 'Quantum'});
    expect(QLYamlEnv.has('APP_NAME'), isTrue);
    expect(QLYamlEnv.get('APP_NAME'), 'Quantum');
  });

  test('QuantumYamlEngine parseString resolves env interpolation', () async {
    QLYamlEnv.set('APP_NAME', 'Quantum');
    final map = await QuantumYamlEngine.instance.parseString('''
name: "{{env.APP_NAME}}"
version: "{{env.VERSION | default: 1.0.0}}"
''');
    expect(map['name'], 'Quantum');
    expect(map['version'], '1.0.0');
  });

  test('QuantumYamlEngine loadNode wrapper exposes typed accessors', () async {
    final node = QLYamlNode.fromRaw({
      'user': {
        'name': 'Ada',
        'items': [1, 2, 3],
      },
    });

    expect(node['user']['name'].asString, 'Ada');
    expect(node['user']['items'].children, hasLength(3));
    expect(node.path(['user', 'name']).asString, 'Ada');
  });

  test('QuantumYamlException formats contextual information', () {
    final exception = QuantumYamlException('boom',
        sourcePath: 'a.yaml', importChain: 'a → b');
    expect(exception.toString(), contains('boom'));
    expect(exception.toString(), contains('a.yaml'));
  });

  test('QuantumYamlEngine clearCache is safe after repeated parses', () async {
    await QuantumYamlEngine.instance.parseString('{"a":1}');
    QuantumYamlEngine.instance.clearCaches();
    await QuantumYamlEngine.instance.parseString('{"a":1}');
  });
}
