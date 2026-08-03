import 'dart:typed_data';

class QLProjection {
  final Uint32List _mask;

  QLProjection(int fieldCount) : _mask = Uint32List((fieldCount + 31) >> 5);

  @pragma('vm:prefer-inline')
  void select(int fieldIndex) {
    _mask[fieldIndex >> 5] |= (1 << (fieldIndex & 31));
  }

  @pragma('vm:prefer-inline')
  bool isSelected(int fieldIndex) {
    return (_mask[fieldIndex >> 5] & (1 << (fieldIndex & 31))) != 0;
  }

  void clear() => _mask.fillRange(0, _mask.length, 0);
}
