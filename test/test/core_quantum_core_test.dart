import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('QLPathUtils resolves canonical nested paths and prefixes', () {
    final resolved = QLPathUtils.resolve('user.items[2].name');
    expect(resolved, equals(['user', 'items', 2, 'name']));
    expect(QLPathUtils.canonicalize(resolved), 'user.items[2].name');
    expect(QLPathUtils.parentOf('user.items[2].name'), 'user.items[2]');
    expect(QLPathUtils.lastSegment('user.items[2].name'), 'name');
    expect(
        QLPathUtils.prefixes('user.items[2].name'),
        equals([
          'user',
          'user.items',
          'user.items[2]',
          'user.items[2].name',
        ]));
  });

  test('QLPathUtils join handles empty base and relative paths', () {
    expect(QLPathUtils.join('', 'child'), 'child');
    expect(QLPathUtils.join('root', ''), 'root');
    expect(QLPathUtils.join('root', 'child'), 'root.child');
  });

  test('QLFormatParser parses JSON into mutable maps', () {
    final parsed = QLFormatParser.parse('{"a":1,"b":{"c":2}}');
    expect(parsed['a'], 1);
    parsed['b']['c'] = 3;
    expect(parsed['b']['c'], 3);
  });

  test('QLFormatParser parses YAML and normalizes lists and maps', () {
    final parsed = QLFormatParser.parse('''
name: demo
items:
  - id: 1
  - id: 2
''');
    expect(parsed['name'], 'demo');
    expect(parsed['items'], isA<List>());
    expect((parsed['items'] as List).length, 2);
  });

  test('QLFormatParser returns empty map for blank input', () {
    expect(QLFormatParser.parse('   '), isEmpty);
  });

  test('QLProjection selects and preserves intended indices', () {
    final projection = QLProjection(8);
    projection.select(1);
    projection.select(7);
    expect(projection.isSelected(1), isTrue);
    expect(projection.isSelected(7), isTrue);
    expect(projection.isSelected(0), isFalse);
  });

  test('QParser expands grid-like track syntax', () {
    final result = QParser.parse('repeat(2, 1fr, 16px)');
    expect(result, hasLength(4));
    expect(result.whereType<QFraction>().length, 2);
    expect(result.whereType<QFixed>().length, 2);
  });

  test('QParser handles minmax and fit-content tokens', () {
    final result = QParser.parse('minmax(12px, 1fr), fit-content(320px)');
    expect(result.first, isA<QMinMax>());
    expect(result.last, isA<QFitContent>());
  });

  test('QParser falls back to auto for invalid tokens and empty input', () {
    expect(QParser.parse(''), hasLength(1));
    expect(QParser.parse('nonsense').single, isA<QFixed>());
  });

  test('QLNodeState flags compose without overlap', () {
    expect(QLNodeState.dirty & QLNodeState.validating, 0);
    expect(QLNodeState.disabled | QLNodeState.readOnly, isNonZero);
  });

  test('QSize value objects preserve their payloads', () {
    const repeat = QRepeat(3, [QFixed(1), QFraction(0.5)]);
    expect(repeat.count, 3);
    expect(repeat.tracks, hasLength(2));
  });
}
