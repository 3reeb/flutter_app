import 'package:flutter/material.dart';

class DummyContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  BuildContext ctx = DummyContext();
  print(ctx);
}
