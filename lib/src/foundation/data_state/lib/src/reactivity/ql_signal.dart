import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/ql_types.dart';

abstract final class EqualityComparer {
  static bool equals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!equals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !equals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is Uint8List && b is Uint8List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }
}

class QLSignal<T> extends ChangeNotifier implements ValueListenable<T>, QLDisposable {
  T _value;
  int _epoch = 0;
  bool _isDisposed = false;
  StreamController<T>? _streamController;

  QLSignal(this._value);

  @override
  T get value => _value;

  int get epoch => _epoch;
  bool get isDisposed => _isDisposed;

  set value(T newValue) {
    if (_isDisposed) return;
    if (EqualityComparer.equals(_value, newValue)) return;
    _value = newValue;
    _epoch++;
    notifyListeners();
    _streamController?.add(_value);
  }

  void setSilent(T newValue) {
    if (_isDisposed) return;
    if (EqualityComparer.equals(_value, newValue)) return;
    _value = newValue;
    _epoch++;
  }

  void forceNotify() {
    if (_isDisposed) return;
    _epoch++;
    notifyListeners();
    _streamController?.add(_value);
  }

  Stream<T> get stream {
    _streamController ??= StreamController<T>.broadcast();
    return _streamController!.stream;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _streamController?.close();
    super.dispose();
  }
}

class QLAsyncSignal<T> implements QLDisposable {
  final QLSignal<T?> data = QLSignal<T?>(null);
  final QLSignal<bool> loading = QLSignal<bool>(false);
  final QLSignal<Object?> error = QLSignal<Object?>(null);

  Future<T?> load(Future<T> Function() loader) async {
    loading.value = true;
    error.value = null;
    try {
      final result = await loader();
      data.value = result;
      loading.value = false;
      return result;
    } catch (err) {
      error.value = err;
      loading.value = false;
      rethrow;
    }
  }

  @override
  void dispose() {
    data.dispose();
    loading.dispose();
    error.dispose();
  }
}
