import 'dart:typed_data';

void main() {
  final buffer = Uint32List(10);
  final merge = 1 << 4; // 16
  final kindAndFlags = 3;

  buffer[1] = kindAndFlags | (merge << 8); // 3 | 4096 = 4099

  final mask = ~(merge << 8);
  print('mask = $mask');

  final val = buffer[1];
  print('val = $val');

  final result = val & mask;
  print('result = $result');

  final isSame = result == kindAndFlags;
  print('isSame = $isSame');
}
