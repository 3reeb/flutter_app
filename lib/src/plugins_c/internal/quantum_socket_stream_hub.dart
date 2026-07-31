import 'dart:async';
import 'dart:typed_data';
/// Shared stream hub for socket drivers.
///
/// Multiple socket implementations were repeating the same broadcast
/// controllers and getters. Centralizing them here keeps the drivers smaller
/// and prevents accidental divergence in state-stream behavior.
final class QLSocketStreamHub<TState, TMessage> {
  final StreamController<TState> _stateCtrl = StreamController.broadcast();
  final StreamController<TMessage> _messageCtrl = StreamController.broadcast();
  final StreamController<Uint8List> _binaryCtrl = StreamController.broadcast();

  Stream<TState> get onStateChanged => _stateCtrl.stream;
  Stream<TMessage> get onMessage => _messageCtrl.stream;
  Stream<Uint8List> get onRawBinary => _binaryCtrl.stream;

  void emitState(TState state) => _stateCtrl.add(state);
  void emitMessage(TMessage message) => _messageCtrl.add(message);
  void emitMessageError(Object error, [StackTrace? stackTrace]) =>
      _messageCtrl.addError(error, stackTrace);
  void emitBinary(Uint8List bytes) => _binaryCtrl.add(bytes);

  Future<void> close() async {
    await _stateCtrl.close();
    await _messageCtrl.close();
    await _binaryCtrl.close();
  }
}

/// Small base class so drivers can reuse the same socket stream wiring.
abstract class QLSocketDriverBase<TState, TMessage> {
  final QLSocketStreamHub<TState, TMessage> streams =
      QLSocketStreamHub<TState, TMessage>();

  Stream<TState> get onStateChanged => streams.onStateChanged;
  Stream<TMessage> get onMessage => streams.onMessage;
  Stream<Uint8List> get onRawBinary => streams.onRawBinary;

  void emitState(TState state) => streams.emitState(state);
  void emitMessage(TMessage message) => streams.emitMessage(message);
  void emitMessageError(Object error, [StackTrace? stackTrace]) =>
      streams.emitMessageError(error, stackTrace);
  void emitBinary(Uint8List bytes) => streams.emitBinary(bytes);
}
