import 'package:quantum_layout/quantum.dart';

void main() {
  QTemplateEngine.unfreeze();
  initQuantumBuiltIns(QuantumVM.instance);
  print('rich_shell slots: ' + QTemplateEngine.getDef('rich_shell')!.defaultSlots.keys.toString());
  print('item_shell slots: ' + QTemplateEngine.getDef('item_shell')!.defaultSlots.keys.toString());
}
