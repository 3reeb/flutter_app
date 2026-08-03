import 'package:flutter/widgets.dart';
import '../reactivity/ql_data_store.dart';
import '../context/ql_data_scope.dart';
import '../context/ql_signal_builder.dart';

abstract final class QLSDUIBinder {
  static final RegExp _tokenRegex = RegExp(r'\{\{\s*([a-zA-Z0-9_\.\-]+)\s*\}\}');

  static bool containsTokens(dynamic value) {
    if (value is! String) return false;
    return _tokenRegex.hasMatch(value);
  }

  static List<String> extractDependencies(String tokenizedString) {
    final matches = _tokenRegex.allMatches(tokenizedString);
    if (matches.isEmpty) return const [];
    return matches.map((m) => m.group(1)!).toList(growable: false);
  }

  static dynamic resolveValue(dynamic rawValue, QLDataStore store) {
    if (rawValue is! String) return rawValue;

    final match = _tokenRegex.firstMatch(rawValue);
    if (match != null && match.group(0) == rawValue) {
      final path = match.group(1)!;
      return store.get(path);
    }

    return rawValue.replaceAllMapped(_tokenRegex, (m) {
      final path = m.group(1)!;
      final val = store.get(path);
      return val?.toString() ?? '';
    });
  }

  static dynamic resolveJsonTree(dynamic jsonNode, QLDataStore store) {
    if (jsonNode is Map) {
      final Map<String, dynamic> resolvedMap = {};
      jsonNode.forEach((key, value) {
        resolvedMap[key.toString()] = resolveJsonTree(value, store);
      });
      return resolvedMap;
    } else if (jsonNode is List) {
      return jsonNode.map((item) => resolveJsonTree(item, store)).toList();
    } else {
      return resolveValue(jsonNode, store);
    }
  }

  static Widget bindText({
    required BuildContext context,
    required String tokenizedTemplate,
    required Widget Function(BuildContext context, String resolvedText) builder,
  }) {
    final store = QLDataScope.of(context);
    final deps = extractDependencies(tokenizedTemplate);

    if (deps.isEmpty) {
      return builder(context, tokenizedTemplate);
    }

    return QLSelectorBuilder<dynamic>(
      path: deps.first,
      builder: (context, _) {
        final resolvedText = resolveValue(tokenizedTemplate, store).toString();
        return builder(context, resolvedText);
      },
    );
  }
}
