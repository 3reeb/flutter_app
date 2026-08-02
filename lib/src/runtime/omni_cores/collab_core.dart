/*
 * ============================================================================
 * File: collab_core.dart
 * 
 * Description:
 * Implements real-time collaboration primitives, including live cursors, presence, 
 * awareness, and optimistic locking mechanisms, hooked into the Quantum Registry.
 * 
 * Key Components:
 * - _buildCollab: Orchestrates presence, cursor, lock, patch, and awareness types.
 * - _QLCollabRegistry: Singleton room state store backing all collaborative UI updates.
 * - _QLCursorOverlayNode / _QLCollabLockNode: Live UI overlay management nodes.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart.
 * 
 * Notes:
 * Provides state abstractions for CRDT-lite interactions across multiple users.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

// ════════════════════════════════════════════════════════════════════════════
// COLLAB CORE — Real-time collaboration primitives
// Sub-types: presence, cursor, awareness, lock, patch, crdt
// ════════════════════════════════════════════════════════════════════════════

Widget _buildCollab(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'presence');

  // collab:presence — Track connected users
  if (subType == 'presence') {
    final String roomId = ctx.string('room', fallback: 'default');
    final String as = ctx.string('as', fallback: 'presence');
    final pres = _QLCollabRegistry.instance.getPresence(roomId);
    return AnimatedBuilder(
      animation: pres,
      builder: (_, __) => QLDataScope(
        localData: {...ctx.env, as: pres.value, '${as}Count': pres.value?.length ?? 0},
        child: Q('col w-full', children: ctx.children),
      ),
    );
  }

  // collab:cursor — Multi-user cursor overlay
  if (subType == 'cursor') {
    final String roomId = ctx.string('room', fallback: 'default');
    final String userId = ctx.string('userId', fallback: 'me');
    final QLSignal<Map<String, dynamic>> cursors = _QLCollabRegistry.instance.getCursors(roomId);
    return _QLCursorOverlayNode(roomId: roomId, userId: userId, cursors: cursors, env: ctx.env, child: ctx.children.isNotEmpty ? ctx.children.first : const SizedBox.shrink());
  }

  // collab:awareness — Shared ephemeral state (CRDT-lite)
  if (subType == 'awareness') {
    final String roomId = ctx.string('room', fallback: 'default');
    final String as = ctx.string('as', fallback: 'awareness');
    final sig = _QLCollabRegistry.instance.getAwareness(roomId);
    return AnimatedBuilder(
      animation: sig,
      builder: (_, __) => QLDataScope(localData: {...ctx.env, as: sig.value}, child: Q('col w-full', children: ctx.children)),
    );
  }

  // collab:lock — Optimistic lock on a resource
  if (subType == 'lock') {
    final String resourceId = ctx.string('resource');
    final String userId = ctx.string('userId', fallback: 'me');
    return _QLCollabLockNode(resourceId: resourceId, userId: userId, env: ctx.env, children: ctx.children);
  }

  // collab:patch — Apply a JSON-patch to a store key
  if (subType == 'patch') {
    final String storeId = ctx.string('store', fallback: 'default');
    final String key = ctx.string('key');
    final Map<String, dynamic> patch = ctx.map('patch');
    if (key.isNotEmpty && patch.isNotEmpty) {
      final store = QLStoreRegistry.instance.get(storeId);
      final cur = store.get(key);
      if (cur is Map<String, dynamic>) store.set(key, {...cur, ...patch});
    }
    return Q('col w-full', children: ctx.children);
  }

  return Q('col w-full', children: ctx.children);
}

// ─────────────────────────────────────────────────────────────────────────────
// Collab Registry — Singleton room state store
// ─────────────────────────────────────────────────────────────────────────────
final class _QLCollabRegistry {
  static final _QLCollabRegistry instance = _QLCollabRegistry._();
  _QLCollabRegistry._();

  final Map<String, QLSignal<List<dynamic>?>> _presence = {};
  final Map<String, QLSignal<Map<String, dynamic>>> _cursors = {};
  final Map<String, QLSignal<Map<String, dynamic>>> _awareness = {};
  final Map<String, String?> _locks = {};

  QLSignal<List<dynamic>?> getPresence(String room) =>
      _presence.putIfAbsent(room, () => QLSignal<List<dynamic>?>(null));

  QLSignal<Map<String, dynamic>> getCursors(String room) =>
      _cursors.putIfAbsent(room, () => QLSignal<Map<String, dynamic>>({}));

  QLSignal<Map<String, dynamic>> getAwareness(String room) =>
      _awareness.putIfAbsent(room, () => QLSignal<Map<String, dynamic>>({}));

  bool tryLock(String resource, String userId) {
    if (_locks[resource] != null && _locks[resource] != userId) return false;
    _locks[resource] = userId;
    return true;
  }

  void releaseLock(String resource, String userId) {
    if (_locks[resource] == userId) _locks.remove(resource);
  }

  bool isLocked(String resource, String userId) {
    final holder = _locks[resource];
    return holder != null && holder != userId;
  }

  /// Called from platform plugin / WebSocket message handler
  void updatePresence(String room, List<dynamic> users) {
    _presence.putIfAbsent(room, () => QLSignal<List<dynamic>?>(null)).value = users;
  }

  void updateCursor(String room, String userId, double x, double y) {
    final sig = getCursors(room);
    sig.value = {...sig.value, userId: {'x': x, 'y': y}};
  }

  void updateAwareness(String room, Map<String, dynamic> data) {
    final sig = getAwareness(room);
    sig.value = {...sig.value, ...data};
  }
}

// Cursor overlay node
class _QLCursorOverlayNode extends StatefulWidget {
  final String roomId, userId;
  final QLSignal<Map<String, dynamic>> cursors;
  final Map<String, dynamic> env;
  final Widget child;
  const _QLCursorOverlayNode({required this.roomId, required this.userId, required this.cursors, required this.env, required this.child});
  @override State<_QLCursorOverlayNode> createState() => _QLCursorOverlayNodeState();
}
class _QLCursorOverlayNodeState extends State<_QLCursorOverlayNode> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cursors,
      builder: (_, __) {
        final cursors = widget.cursors.value;
        final others = cursors.entries.where((e) => e.key != widget.userId).toList();
        return Stack(
          children: [
            QLDataScope(localData: {...widget.env, 'cursors': cursors}, child: widget.child),
            ...others.map((e) {
              final x = (e.value['x'] as num?)?.toDouble() ?? 0;
              final y = (e.value['y'] as num?)?.toDouble() ?? 0;
              return Positioned(left: x, top: y, child: _CursorDot(userId: e.key));
            }),
          ],
        );
      },
    );
  }
}
class _CursorDot extends StatelessWidget {
  final String userId;
  const _CursorDot({required this.userId});
  @override Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mouse, size: 16, color: Colors.blue),
        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), color: Colors.blue, child: Text(userId, style: const TextStyle(color: Colors.white, fontSize: 10))),
      ],
    );
  }
}

// Lock node
class _QLCollabLockNode extends StatefulWidget {
  final String resourceId, userId;
  final Map<String, dynamic> env;
  final List<Widget> children;
  const _QLCollabLockNode({required this.resourceId, required this.userId, required this.env, required this.children});
  @override State<_QLCollabLockNode> createState() => _QLCollabLockNodeState();
}
class _QLCollabLockNodeState extends State<_QLCollabLockNode> {
  late bool _locked;
  @override void initState() {
    super.initState();
    _locked = _QLCollabRegistry.instance.tryLock(widget.resourceId, widget.userId);
  }
  @override void dispose() { _QLCollabRegistry.instance.releaseLock(widget.resourceId, widget.userId); super.dispose(); }
  @override Widget build(BuildContext context) {
    return QLDataScope(
      localData: {...widget.env, 'lockAcquired': _locked, 'lockHolder': _QLCollabRegistry.instance._locks[widget.resourceId]},
      child: Q('col w-full', children: widget.children),
    );
  }
}

void _registerCollabAliases(QuantumVM vm) {
  vm.defineAlias('presence', 'collab:presence', description: 'Presence alias.', tags: const ['collab', 'alias']);
  vm.defineAlias('cursor', 'collab:cursor', description: 'Cursor alias.', tags: const ['collab', 'alias']);
  vm.defineAlias('awareness', 'collab:awareness', description: 'Awareness alias.', tags: const ['collab', 'alias']);
  vm.defineAlias('lock', 'collab:lock', description: 'Lock alias.', tags: const ['collab', 'alias']);
}

class CollabCoreExporter implements QuantumCoreExporter {
  const CollabCoreExporter();
  
  @override
  void export(QuantumVM vm) {
    vm.define('collab', _buildCollab, tags: const ['core', 'collab']);
    _registerCollabAliases(vm);
  }
}
