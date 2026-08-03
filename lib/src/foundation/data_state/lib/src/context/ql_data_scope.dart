import 'package:flutter/widgets.dart';
import '../reactivity/ql_data_store.dart';

class QLDataScope extends InheritedWidget {
  final QLDataStore store;

  const QLDataScope({
    super.key,
    required this.store,
    required super.child,
  });

  static QLDataStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<QLDataScope>();
    assert(scope != null, 'No QLDataScope found in BuildContext context.');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(QLDataScope oldWidget) => store != oldWidget.store;
}

class QLStoreProvider extends StatefulWidget {
  final QLDataStore store;
  final Widget child;

  const QLStoreProvider({
    super.key,
    required this.store,
    required this.child,
  });

  @override
  State<QLStoreProvider> createState() => _QLStoreProviderState();
}

class _QLStoreProviderState extends State<QLStoreProvider> {
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QLDataScope(
      store: widget.store,
      child: widget.child,
    );
  }
}
