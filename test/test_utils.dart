import 'package:flutter_test/flutter_test.dart';

Matcher matchesStyle(dynamic expected) => _StyleMatcher(expected);

class _StyleMatcher extends Matcher {
  final dynamic expected;
  _StyleMatcher(this.expected);

  @override
  bool matches(item, Map matchState) {
    if (expected is! String || item is! String) {
      return equals(expected).matches(item, matchState);
    }
    final String itemStr = item as String;
    final String expectedStr = expected as String;
    final set1 = itemStr.split(RegExp(r'\s+')).where((String e) => e.isNotEmpty).toSet();
    final set2 = expectedStr.split(RegExp(r'\s+')).where((String e) => e.isNotEmpty).toSet();
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  @override
  Description describe(Description description) {
    if (expected is String) {
      return description.add('style matching "$expected" (order-independent)');
    } else {
      return equals(expected).describe(description);
    }
  }
}
