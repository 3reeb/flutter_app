import 'dart:convert';
import 'dart:typed_data';

/// Zero-Copy View over raw contiguous memory buffers.
class QLBufferView {
  final ByteData _bytes;
  final int offset;
  final int length;

  QLBufferView(Uint8List buffer, [this.offset = 0, int? length])
      : _bytes = ByteData.sublistView(
            buffer, offset, offset + (length ?? buffer.lengthInBytes - offset)),
        length = length ?? (buffer.lengthInBytes - offset);

  @pragma('vm:prefer-inline')
  int readUint8(int byteOffset) => _bytes.getUint8(byteOffset);

  @pragma('vm:prefer-inline')
  int readInt16(int byteOffset, {Endian endian = Endian.host}) =>
      _bytes.getInt16(byteOffset, endian);

  @pragma('vm:prefer-inline')
  int readInt32(int byteOffset, {Endian endian = Endian.host}) =>
      _bytes.getInt32(byteOffset, endian);

  @pragma('vm:prefer-inline')
  int readInt64(int byteOffset, {Endian endian = Endian.host}) =>
      _bytes.getInt64(byteOffset, endian);

  @pragma('vm:prefer-inline')
  double readFloat32(int byteOffset, {Endian endian = Endian.host}) =>
      _bytes.getFloat32(byteOffset, endian);

  @pragma('vm:prefer-inline')
  double readFloat64(int byteOffset, {Endian endian = Endian.host}) =>
      _bytes.getFloat64(byteOffset, endian);

  @pragma('vm:prefer-inline')
  void writeUint8(int byteOffset, int value) =>
      _bytes.setUint8(byteOffset, value);

  @pragma('vm:prefer-inline')
  void writeInt16(int byteOffset, int value, {Endian endian = Endian.host}) =>
      _bytes.setInt16(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  void writeInt32(int byteOffset, int value, {Endian endian = Endian.host}) =>
      _bytes.setInt32(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  void writeInt64(int byteOffset, int value, {Endian endian = Endian.host}) =>
      _bytes.setInt64(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  void writeFloat32(int byteOffset, double value,
          {Endian endian = Endian.host}) =>
      _bytes.setFloat32(byteOffset, value, endian);

  @pragma('vm:prefer-inline')
  void writeFloat64(int byteOffset, double value,
          {Endian endian = Endian.host}) =>
      _bytes.setFloat64(byteOffset, value, endian);

  Uint8List slice(int start, int byteCount) {
    return _bytes.buffer.asUint8List(_bytes.offsetInBytes + start, byteCount);
  }

  String readUtf8String(int start, int byteCount) {
    return utf8.decode(
        _bytes.buffer.asUint8List(_bytes.offsetInBytes + start, byteCount));
  }

  int writeUtf8String(int start, String text) {
    final encoded = utf8.encode(text);
    final target = _bytes.buffer.asUint8List(_bytes.offsetInBytes + start);
    target.setAll(0, encoded);
    return encoded.length;
  }
}
