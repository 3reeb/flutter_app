import 'dart:collection';

abstract final class QLPathUtils {
  static final LinkedHashMap<String, List<dynamic>> _cache =
      LinkedHashMap<String, List<dynamic>>();
  static const int _maxCache = 4096;

  @pragma('vm:prefer-inline')
  static List<dynamic> resolve(String path) {
    final cached = _cache.remove(path);
    if (cached != null) {
      _cache[path] = cached;
      return cached;
    }

    if (path.isEmpty) return const <dynamic>[];

    final List<dynamic> strides = <dynamic>[];
    int segmentStart = 0;
    final int len = path.length;

    for (int i = 0; i <= len; i++) {
      final bool isBreak = i == len ||
          path.codeUnitAt(i) == 46 ||
          path.codeUnitAt(i) == 91 ||
          path.codeUnitAt(i) == 93;
      if (!isBreak) continue;
      if (i > segmentStart) {
        final String token = path.substring(segmentStart, i);
        final int? numIdx = int.tryParse(token);
        strides.add(numIdx ?? token);
      }
      segmentStart = i + 1;
    }

    final List<dynamic> immutableStrides = List<dynamic>.unmodifiable(strides);
    _cache[path] = immutableStrides;
    if (_cache.length > _maxCache) {
      _cache.remove(_cache.keys.first);
    }
    return immutableStrides;
  }

  @pragma('vm:prefer-inline')
  static String canonicalize(Iterable<dynamic> strides) {
    final iterator = strides.iterator;
    if (!iterator.moveNext()) return '';
    final StringBuffer sb = StringBuffer(iterator.current.toString());
    while (iterator.moveNext()) {
      final dynamic s = iterator.current;
      if (s is int) {
        sb.write('[$s]');
      } else {
        sb.write('.');
        sb.write(s.toString());
      }
    }
    return sb.toString();
  }

  static List<String> prefixes(String path) {
    final strides = resolve(path);
    if (strides.isEmpty) return const [];
    final List<String> out = <String>[];
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < strides.length; i++) {
      final dynamic s = strides[i];
      if (i == 0) {
        buffer.write(s.toString());
      } else if (s is int) {
        buffer.write('[$s]');
      } else {
        buffer.write('.');
        buffer.write(s.toString());
      }
      out.add(buffer.toString());
    }
    return out;
  }

  static String join(String base, String relative) {
    if (base.isEmpty) return relative;
    if (relative.isEmpty) return base;
    return '$base.$relative';
  }

  static String parentOf(String path) {
    final segs = resolve(path);
    if (segs.length <= 1) return '';
    return canonicalize(segs.sublist(0, segs.length - 1));
  }

  static void clearCache() => _cache.clear();
}
