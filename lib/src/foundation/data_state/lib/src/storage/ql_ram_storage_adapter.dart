import 'dart:async';
import 'ql_storage_adapter.dart';

class QLRAMStorageAdapter implements QLStorageAdapter {
  final Map<String, dynamic> _memory = <String, dynamic>{};
  final StreamController<MapEntry<String, dynamic>> _controller =
      StreamController.broadcast();

  @override
  dynamic read(String path) => _memory[path];

  @override
  void write(String path, dynamic value) {
    _memory[path] = value;
    _controller.add(MapEntry(path, value));
  }

  @override
  void delete(String path) {
    _memory.remove(path);
    _controller.add(MapEntry(path, null));
  }

  @override
  Stream<dynamic> watch(String path) {
    return _controller.stream
        .where((entry) => entry.key == path || entry.key.startsWith('$path.'))
        .map((entry) => entry.value);
  }

  @override
  void flush() {}

  @override
  void clear() {
    _memory.clear();
  }
}
