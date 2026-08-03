import 'dart:async';

class QLWriteOp {
  final String path;
  final dynamic value;
  final bool isDelete;
  final DateTime timestamp;

  QLWriteOp({
    required this.path,
    this.value,
    this.isDelete = false,
  }) : timestamp = DateTime.now();
}

abstract class QLStorageAdapter {
  FutureOr<dynamic> read(String path);
  FutureOr<void> write(String path, dynamic value);
  FutureOr<void> delete(String path);
  Stream<dynamic>? watch(String path);
  FutureOr<void> flush();
  FutureOr<void> clear();
}
