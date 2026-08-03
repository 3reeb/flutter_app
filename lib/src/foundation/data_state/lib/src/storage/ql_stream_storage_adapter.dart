import 'dart:async';
import 'ql_storage_adapter.dart';

class QLStreamStorageAdapter implements QLStorageAdapter {
  final QLStorageAdapter delegate;
  final List<QLWriteOp> _writeQueue = <QLWriteOp>[];
  final StreamController<QLWriteOp> _queueController =
      StreamController<QLWriteOp>.broadcast();

  QLStreamStorageAdapter({required this.delegate});

  List<QLWriteOp> get pendingWrites => List.unmodifiable(_writeQueue);

  @override
  FutureOr<dynamic> read(String path) => delegate.read(path);

  @override
  FutureOr<void> write(String path, dynamic value) async {
    final op = QLWriteOp(path: path, value: value);
    _writeQueue.add(op);
    _queueController.add(op);
    await delegate.write(path, value);
  }

  @override
  FutureOr<void> delete(String path) async {
    final op = QLWriteOp(path: path, isDelete: true);
    _writeQueue.add(op);
    _queueController.add(op);
    await delegate.delete(path);
  }

  @override
  Stream<dynamic>? watch(String path) => delegate.watch(path);

  @override
  Future<void> flush() async {
    await delegate.flush();
    _writeQueue.clear();
  }

  @override
  Future<void> clear() async {
    _writeQueue.clear();
    await delegate.clear();
  }
}
