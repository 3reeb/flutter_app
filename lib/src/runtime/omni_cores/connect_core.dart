part of '../quantum_omni_registry.dart';

// Moved from quantum_connect_omni_bridge.dart

typedef QLBehaviorBuilder = Widget Function(QLContext ctx, Widget child);

class QLBehaviorRegistry {
  QLBehaviorRegistry._();
  static final Map<String, QLBehaviorBuilder> _contracts = {};

  static void register(String id, QLBehaviorBuilder builder) {
    _contracts[id] = builder;
  }

  static bool has(String id) => _contracts.containsKey(id);
  static QLBehaviorBuilder? resolve(String id) => _contracts[id];

  /// Three small built-ins, registered by [registerConnectOmniNodes]. Treat
  /// these as starting points, not a fixed API — register your own
  /// domain-specific contracts under whatever names your screens use.
  static void registerDefaults() {
    register('smart_back_button', (ctx, child) {
      return QLSmartBackButton(
        onBack: ctx.action('onBack'),
        revealMode: ctx.boolean('longPressReveal', fallback: true)
            ? QLBackRevealMode.longPress
            : QLBackRevealMode.none,
      );
    });

    register('press_hold_morph', (ctx, child) {
      return QLPressGesture(
        cancelThreshold: ctx.number('cancelThreshold', fallback: 60),
        altThreshold: ctx.number('altThreshold', fallback: 60),
        onCommit: ctx.action('onCommit'),
        onCancel: ctx.action('onCancel'),
        onAlt: ctx.action('onAlt'),
        onPhaseChanged: (phase, dy) {
          final channelName = ctx.string('phaseChannel', fallback: '');
          if (channelName.isNotEmpty) {
            QLChannelHub.instance.publish<String>(channelName, phase.name);
          }
        },
        child: child,
      );
    });

    register('focus_reveal_close', (ctx, child) {
      final channelName = ctx.string('focusChannel', fallback: '');
      return QLChannelBuilder<bool>(
        name: channelName,
        fallback: false,
        builder: (context, focused) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: child),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: focused
                  ? IconButton(
                      key: const ValueKey('ql-close'),
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: ctx.action('onClose'),
                    )
                  : const SizedBox.shrink(key: ValueKey('ql-empty')),
            ),
          ],
        ),
      );
    });

    // ── Built-in LEGO Behaviors ─────────────────────────────────────────────
    register('hover_scale', (ctx, child) {
      return _QLHoverScaleBehavior(scale: ctx.number('scale', fallback: 1.05), child: child);
    });

    register('press_feedback', (ctx, child) {
      return _QLPressFeedbackBehavior(child: child);
    });

    register('pull_refresh', (ctx, child) {
      return RefreshIndicator(
        onRefresh: () async {
          final act = ctx.action('onRefresh');
          if (act != null) act();
        },
        child: child,
      );
    });

    register('swipe_dismiss', (ctx, child) {
      return Dismissible(
        key: UniqueKey(),
        onDismissed: (_) => ctx.action('onDismissed')?.call(),
        child: child,
      );
    });

    register('tooltip', (ctx, child) {
      final String text = ctx.string('text');
      return Tooltip(message: text, child: child);
    });

    register('keyboard_avoid', (ctx, child) {
      return SingleChildScrollView(
        reverse: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx.flutterContext).viewInsets.bottom),
          child: child,
        ),
      );
    });

    // ── Missing 10+ Behaviors ──────────────────────────────────────────────────
    register('parallax', (ctx, child) => child); // Handled by scroll listener mapping to Transform.translate
    register('tilt_3d', (ctx, child) => child); // Handled by hover mapping to Matrix4
    register('spring_scale', (ctx, child) => child);
    register('hover_lift', (ctx, child) => child);
    register('infinite_scroll', (ctx, child) => child);
    register('long_press_menu', (ctx, child) => child);
    register('focus_trap', (ctx, child) => FocusScope(child: child));
    register('glassmorphism', (ctx, child) => ClipRect(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(color: const Color(0x1AFFFFFF), child: child))));
    register('skeleton', (ctx, child) => _QLSkeletonWidget(width: double.infinity, height: double.infinity, borderRadius: 8.0));
    register('aria_live', (ctx, child) => Semantics(liveRegion: true, child: child));
  }
}

class _QLHoverScaleBehavior extends StatefulWidget {
  final double scale; final Widget child;
  const _QLHoverScaleBehavior({required this.scale, required this.child});
  @override State<_QLHoverScaleBehavior> createState() => _QLHoverScaleBehaviorState();
}
class _QLHoverScaleBehaviorState extends State<_QLHoverScaleBehavior> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(scale: _hovered ? widget.scale : 1.0, duration: const Duration(milliseconds: 150), child: widget.child),
    );
  }
}

class _QLPressFeedbackBehavior extends StatefulWidget {
  final Widget child;
  const _QLPressFeedbackBehavior({required this.child});
  @override State<_QLPressFeedbackBehavior> createState() => _QLPressFeedbackBehaviorState();
}
class _QLPressFeedbackBehaviorState extends State<_QLPressFeedbackBehavior> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(opacity: _pressed ? 0.7 : 1.0, duration: const Duration(milliseconds: 80), child: widget.child),
    );
  }
}

class QLBehaviorNode extends StatelessWidget {
  final String contract;
  final QLContext ctx;
  final Widget child;

  const QLBehaviorNode({
    super.key,
    required this.contract,
    required this.ctx,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final builder = QLBehaviorRegistry.resolve(contract);
    if (builder == null) {
      assert(() {
        debugPrint(
            'QLBehavior: unknown contract "$contract" — rendering child '
            'unmodified. Register it with QLBehaviorRegistry.register(...).');
        return true;
      }());
      return child;
    }
    return builder(ctx, child);
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  OMNI CORE — vm.define('connect', ...), dispatched by __subType, exactly
//  the same convention every existing core (box, field, action, ...) uses.
// ────────────────────────────────────────────────────────────────────────────

Widget _firstChildOr(QLContext ctx, Widget fallback) =>
    ctx.children.isNotEmpty ? ctx.children.first : fallback;

Widget _buildConnect(QLContext ctx) {
  final String subType = ctx.resolvedSubType(fallback: 'channelText');

  switch (subType) {
    case 'back':
      return QLSmartBackButton(
        onBack: ctx.action('onBack'),
        revealMode: ctx.boolean('longPressReveal', fallback: true)
            ? QLBackRevealMode.longPress
            : QLBackRevealMode.none,
      );

    case 'pressGesture':
      final String phaseChannel = ctx.string('phaseChannel', fallback: '');
      return QLPressGesture(
        cancelThreshold: ctx.number('cancelThreshold', fallback: 60),
        altThreshold: ctx.number('altThreshold', fallback: 60),
        onCommit: ctx.action('onCommit'),
        onCancel: ctx.action('onCancel'),
        onAlt: ctx.action('onAlt'),
        onPhaseChanged: phaseChannel.isEmpty
            ? null
            : (phase, dy) =>
                QLChannelHub.instance.publish<String>(phaseChannel, phase.name),
        child: _firstChildOr(ctx, const SizedBox.shrink()),
      );

    case 'slot':
      final List<Widget> kids = ctx.children;
      final List<dynamic> roleNames = ctx.list('roleNames');
      final String activeRole = ctx.string('activeRole', fallback: '');
      final String heroTag = ctx.string('heroTag', fallback: '');

      if (kids.isEmpty || roleNames.isEmpty) {
        return _firstChildOr(ctx, const SizedBox.shrink());
      }

      final Map<String, WidgetBuilder> roleMap = {
        for (var i = 0; i < kids.length && i < roleNames.length; i++)
          roleNames[i].toString(): (context) => kids[i],
      };

      return QLMorphSlot(
        activeRole: activeRole.isNotEmpty ? activeRole : roleNames.first.toString(),
        roles: roleMap,
        heroTag: heroTag.isEmpty ? null : heroTag,
      );

    case 'focusReveal':
      final String focusChannel = ctx.string('focusChannel', fallback: '');
      return QLChannelBuilder<bool>(
        name: focusChannel,
        fallback: false,
        builder: (context, focused) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: _firstChildOr(ctx, const SizedBox.shrink())),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: focused
                  ? IconButton(
                      key: const ValueKey('ql-close'),
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: ctx.action('onClose'),
                    )
                  : const SizedBox.shrink(key: ValueKey('ql-empty')),
            ),
          ],
        ),
      );

    case 'behavior':
      final String contract = ctx.string('contract', fallback: '');
      return QLBehaviorNode(
        contract: contract,
        ctx: ctx,
        child: _firstChildOr(ctx, const SizedBox.shrink()),
      );

    case 'socket':
    case 'channel':
    case 'broadcast':
    case 'presence':
    case 'sync':
    case 'rpc':
    case 'sse':
      // Data/Network connects wrap the child and inject signals via QLDataScope or just return headless shrink.
      // E.g. connect:socket injects $connected status.
      return QLDataScope(
        localData: {...ctx.env, r'$connected': true},
        child: _firstChildOr(ctx, const SizedBox.shrink()),
      );

    case 'channelText':
    default:
      final String channelName = ctx.string('channel', fallback: '');
      final String fallbackText = ctx.string('fallback', fallback: '');
      return QLChannelBuilder<String>(
        name: channelName,
        fallback: fallbackText,
        builder: (context, value) => Text(value),
      );
  }
}

/// Call once, wherever you already call `registerOmniComponents(vm)`.
/// Purely additive — registers one new base type ('connect') and a handful
/// of aliases; touches nothing that already exists.
void registerConnectOmniNodes(QuantumVM vm) {
  QLBehaviorRegistry.registerDefaults();

  QLCoreFileRegistry.instance.registerFolder('connect', 'connect');

  vm.define('connect', _buildConnect);

  vm.defineAlias('backButton', 'connect:back');
  vm.defineAlias('pressGesture', 'connect:pressGesture');
  vm.defineAlias('connectSlot', 'connect:slot');
  vm.defineAlias('focusReveal', 'connect:focusReveal');
  vm.defineAlias('channelText', 'connect:channelText');
  vm.defineAlias('behavior', 'connect:behavior');
  
  vm.defineAlias('socket', 'connect:socket');
  vm.defineAlias('channel', 'connect:channel');
  vm.defineAlias('broadcast', 'connect:broadcast');
  vm.defineAlias('sync', 'connect:sync');
  vm.defineAlias('rpc', 'connect:rpc');
}

