import 'package:flutter/widgets.dart';
import '../reactivity/ql_signal.dart';
import '../reactivity/ql_data_store.dart';
import 'ql_data_scope.dart';

class QLSignalBuilder<T> extends StatelessWidget {
  final QLSignal<T> signal;
  final Widget Function(BuildContext context, T value) builder;

  const QLSignalBuilder({
    super.key,
    required this.signal,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: signal,
      builder: (context, value, _) => builder(context, value),
    );
  }
}

class QLSelectorBuilder<T> extends StatefulWidget {
  final String path;
  final Widget Function(BuildContext context, T value) builder;

  const QLSelectorBuilder({
    super.key,
    required this.path,
    required this.builder,
  });

  @override
  State<QLSelectorBuilder<T>> createState() => _QLSelectorBuilderState<T>();
}

class _QLSelectorBuilderState<T> extends State<QLSelectorBuilder<T>> {
  QLSignal<dynamic>? _signal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = QLDataScope.of(context);
    _signal = store.signal(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final sig = _signal;
    if (sig == null) return const SizedBox.shrink();

    return ValueListenableBuilder<dynamic>(
      valueListenable: sig,
      builder: (context, value, _) => widget.builder(context, value as T),
    );
  }
}
