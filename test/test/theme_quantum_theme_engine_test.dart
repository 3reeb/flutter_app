import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('QThemeDictionary resolves colors, numbers, text and aliases', () {
    final dictionary = QThemeDictionary.fromJson({
      'colors': {
        'primary': '#3366ff',
        'accent': {'color': '#ff00ff'},
      },
      'spacing': {
        'sm': 4,
        'lg': 16,
      },
      'labels': {
        'title': 'Dashboard',
      },
      'aliases': {
        'brand': '#112233',
      },
    });

    expect(dictionary.values.containsKey('colors.primary'), isTrue);
    expect(dictionary.values.containsKey('spacing.sm'), isTrue);
    expect(dictionary.values.containsKey('labels.title'), isTrue);
    expect(dictionary.aliases.containsKey('aliases.brand'), isTrue);
    expect(dictionary.aliases['aliases.brand'], '#112233');
  });

  test('QThemeGraph loads dictionaries and resolves tokens', () {
    final graph = QThemeGraph();
    graph.load(QThemeDictionary.fromJson({
      'colors': {'primary': '#3366ff'},
      'spacing': {'sm': 4},
      'labels': {'title': 'Hello'},
    }));

    expect(graph.color('colors.primary'), isNotNull);
    expect(graph.number('spacing.sm'), closeTo(4.0, 0.001));
    expect(graph.text('labels.title'), 'Hello');
    expect(graph.color('aliases.brand'), isNotNull);
  });

  test('QEngine lazily initializes and compiles styles after a cold dispose',
      () {
    QEngine.instance.dispose();
    final token1 = QEngine.instance.compileStyle('text-center   font-bold');
    final token2 = QEngine.instance.compileStyle('text-center font-bold');
    expect(token1.id, token2.id);
  });

  test(
      'QEngine loads a theme dictionary and exposes the compiler and memory arenas',
      () {
    QEngine.instance.dispose();
    QEngine.instance.initialize(initialCapacity: 64, ecsCapacity: 64);
    QEngine.instance.loadThemeDictionary(QThemeDictionary.fromJson({
      'colors': {'primary': '#112233'},
    }));

    expect(QEngine.instance.mem, isNotNull);
    expect(QEngine.instance.targetMem, isNotNull);
    expect(QEngine.instance.compiler, isNotNull);
  });
}
