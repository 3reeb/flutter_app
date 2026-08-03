import 'dart:async';
import '../core/ql_path_utils.dart';
import '../core/ql_types.dart';
import 'ql_data_store.dart';
import 'ql_signal.dart';

typedef QLSliceReducer<T> = T Function(T currentSliceState, dynamic payload);

class QLSliceSpec<T> {
  final String name;
  final T initialState;
  final Map<String, dynamic Function(T sliceState, QLDataStore globalStore)> computed;
  final Map<String, QLSliceReducer<T>> reducers;
  final List<String> persistencePaths;

  const QLSliceSpec({
    required this.name,
    required this.initialState,
    this.computed = const {},
    this.reducers = const {},
    this.persistencePaths = const [],
  });
}

class QLSlice<T> implements QLDisposable {
  final String name;
  final QLDataStore store;
  final QLSliceSpec<T> spec;
  final StreamController<T> _sliceStreamController = StreamController<T>.broadcast();

  bool _isMounted = false;
  bool get isMounted => _isMounted;

  QLSlice._({
    required this.name,
    required this.store,
    required this.spec,
  });

  QLSignal<dynamic> get rootSignal => store.signal(name);

  T get value {
    final raw = store.get(name);
    if (raw == null) return spec.initialState;
    return raw as T;
  }

  void set(String subPath, dynamic value) {
    if (!_isMounted) {
      throw StateError('Cannot set value on unmounted slice: $name');
    }
    final fullPath = subPath.isEmpty ? name : QLPathUtils.join(name, subPath);
    store.set(fullPath, value);
  }

  dynamic get(String subPath) {
    final fullPath = subPath.isEmpty ? name : QLPathUtils.join(name, subPath);
    return store.get(fullPath);
  }

  void dispatch(String reducerName, [dynamic payload]) {
    final reducer = spec.reducers[reducerName];
    if (reducer == null) {
      throw ArgumentError('Reducer "$reducerName" not found in slice "$name"');
    }
    store.transaction(() {
      final current = value;
      final next = reducer(current, payload);
      store.set(name, next);
    });
  }

  void _mount() {
    if (_isMounted) return;
    _isMounted = true;

    store.transaction(() {
      if (store.get(name) == null) {
        store.set(name, spec.initialState);
      }

      spec.computed.forEach((computedKey, calculator) {
        final fullComputedKey = QLPathUtils.join(name, computedKey);
        store.registerComputed(
          fullComputedKey,
          [name],
          (values) {
            final sliceVal = values.isNotEmpty ? values.first : spec.initialState;
            return calculator(sliceVal as T, store);
          },
        );
      });
    });

    rootSignal.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!_sliceStreamController.isClosed) {
      _sliceStreamController.add(value);
    }
  }

  Stream<T> get stream => _sliceStreamController.stream;

  void unmount() {
    if (!_isMounted) return;
    _isMounted = false;

    rootSignal.removeListener(_onStateChange);

    store.transaction(() {
      store.sweep(name);
    });

    _sliceStreamController.close();
  }

  @override
  void dispose() {
    unmount();
  }
}

class QLSliceRegistry implements QLDisposable {
  final QLDataStore store;
  final Map<String, QLSlice<dynamic>> _activeSlices = <String, QLSlice<dynamic>>{};

  QLSliceRegistry(this.store);

  QLSlice<T> mount<T>(QLSliceSpec<T> spec) {
    if (_activeSlices.containsKey(spec.name)) {
      return _activeSlices[spec.name] as QLSlice<T>;
    }

    final slice = QLSlice<T>._(
      name: spec.name,
      store: store,
      spec: spec,
    );

    slice._mount();
    _activeSlices[spec.name] = slice;
    return slice;
  }

  QLSlice<T>? get<T>(String sliceName) {
    return _activeSlices[sliceName] as QLSlice<T>?;
  }

  bool isMounted(String sliceName) => _activeSlices.containsKey(sliceName);

  void unmount(String sliceName) {
    final slice = _activeSlices.remove(sliceName);
    slice?.unmount();
  }

  List<String> get mountedSliceNames => List.unmodifiable(_activeSlices.keys);

  @override
  void dispose() {
    for (final slice in _activeSlices.values) {
      slice.unmount();
    }
    _activeSlices.clear();
  }
}
