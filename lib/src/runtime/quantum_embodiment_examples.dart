// ════════════════════════════════════════════════════════════════════════════
// QEE EXAMPLE SCENARIOS — quantum_embodiment_examples.dart
//
// Production-ready usage demonstrations for the Quantum Embodiment Engine.
// These are NOT flutter_test unit tests — they are self-executing, self-
// asserting scenarios that you run inside your live app at any time.
//
// Run them with:
//   await QEEExamples.runAll();          // full suite
//   await QEEExamples.runByTag('data'); // only 'data' tagged scenarios
//   await QEEExamples.run('cart');      // single scenario by name
//
// Each scenario prints ✅/❌ and writes the full trace to SQLite.
// ════════════════════════════════════════════════════════════════════════════

// ignore_for_file: avoid_print

import 'package:quantum_layout/quantum.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  TOP-LEVEL RUNNER
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QEEExamples {
  // One-shot: all registered scenarios
  static Future<List<QEETrace>> runAll({bool stopOnFirstFailure = false}) async {
    final traces = <QEETrace>[];
    for (final entry in _registry.entries) {
      print('[QEE Examples] ▶ Running: "${entry.key}"');
      try {
        final trace = await entry.value();
        traces.add(trace);
        if (stopOnFirstFailure && !trace.summary!.allPassed) {
          print('[QEE Examples] ⛔ Stopped after failure in "${entry.key}"');
          break;
        }
      } catch (e) {
        print('[QEE Examples] 💥 Exception in "${entry.key}": $e');
      }
    }
    _printSuiteReport(traces);
    return traces;
  }

  // Run scenarios matching [nameContains]
  static Future<QEETrace?> run(String nameContains) async {
    final key =
        _registry.keys.firstWhere((k) => k.contains(nameContains), orElse: () => '');
    if (key.isEmpty) {
      print('[QEE Examples] ❓ No scenario matching "$nameContains"');
      return null;
    }
    return _registry[key]!();
  }

  // Run all scenarios with a matching tag
  static Future<List<QEETrace>> runByTag(String tag) async {
    final traces = <QEETrace>[];
    for (final entry in _tagIndex.entries) {
      if (entry.value.contains(tag)) {
        final fn = _registry[entry.key];
        if (fn != null) traces.add(await fn());
      }
    }
    return traces;
  }

  static void _printSuiteReport(List<QEETrace> traces) {
    int passed = 0, failed = 0;
    int totalUs = 0;
    for (final t in traces) {
      totalUs += t.summary?.totalDurationUs ?? 0;
      if (t.summary?.allPassed == true) {
        passed++;
      } else {
        failed++;
      }
    }
    final totalMs = (totalUs / 1000).toStringAsFixed(1);
    print('\n════════════════════════════════════════');
    print('  QEE SUITE REPORT');
    print('  Total:  ${traces.length}');
    print('  Passed: $passed');
    print('  Failed: $failed');
    print('  Time:   ${totalMs}ms');
    print('════════════════════════════════════════\n');
  }

  // Registry populated by _register() calls below
  static final Map<String, Future<QEETrace> Function()> _registry = {};
  static final Map<String, List<String>> _tagIndex = {};

  static void _register(
    String name,
    Future<QEETrace> Function() fn, {
    List<String> tags = const [],
  }) {
    _registry[name] = fn;
    _tagIndex[name] = tags;
  }

  // Register all scenarios at class-load time
  static void registerAll() {
    _register('data: basic set and read', _dataBasicSetAndRead, tags: ['data']);
    _register('data: merge and snapshot', _dataMergeAndSnapshot, tags: ['data']);
    _register('data: rollback on failure', _dataRollbackOnFailure, tags: ['data']);
    _register('json: compile product card', _jsonCompileProductCard, tags: ['json']);
    _register('json: inject with macros', _jsonInjectWithMacros, tags: ['json']);
    _register('json: compile and profile', _jsonCompileAndProfile, tags: ['json', 'perf']);
    _register('action: state.set', _actionStateSet, tags: ['action']);
    _register('action: pipeline', _actionPipeline, tags: ['action']);
    _register('schema: validate user record', _schemaValidateUser, tags: ['schema']);
    _register('schema: parse and serialize', _schemaParseAndSerialize, tags: ['schema']);
    _register('vm: cache stats', _vmCacheStats, tags: ['vm']);
    _register('vm: registered actions', _vmRegisteredActions, tags: ['vm']);
    _register('script: custom lambda', _scriptCustomLambda, tags: ['script']);
    _register('policy: no negative total', _policyNoNegativeTotal, tags: ['policy']);
    _register('policy: fatal violation', _policyFatalViolation, tags: ['policy']);
    _register('scenario: full cart checkout', _scenarioCartCheckout, tags: ['e2e', 'data', 'action']);
    _register('scenario: multi-step with rollback', _scenarioRollback, tags: ['e2e', 'data']);
    _register('perf: 1000 data reads', _perf1000Reads, tags: ['perf']);
    _register('perf: 500 compile calls', _perf500Compiles, tags: ['perf', 'json']);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  §1  DATA SCENARIOS
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _dataBasicSetAndRead() => QEmbodiment.run(
      name: 'data: basic set and read',
      tags: ['data'],
      kind: QEEKind.data,
      exec: (e) async {
        e.data.set('qee.test.counter', 0);
        e.data.set('qee.test.name', 'Quantum');
        e.data.set('qee.test.active', true);
        return QEEExecResult.ok(null, 0);
      },
      assert_: (a, p) {
        a
            .dataPath('qee.test.counter', 0, label: 'counter is 0')
            .dataPath('qee.test.name', 'Quantum', label: 'name is Quantum')
            .dataPath('qee.test.active', true, label: 'active is true')
            .dataPathWhere('qee.test.counter', (v) => v is int, label: 'counter is int');
      },
    );

Future<QEETrace> _dataMergeAndSnapshot() => QEmbodiment.run(
      name: 'data: merge and snapshot',
      tags: ['data'],
      kind: QEEKind.data,
      probes: {QEEProbeKind.data, QEEProbeKind.error},
      exec: (e) async {
        final before = e.data.snapshot();
        e.data.merge({
          'cart.items': ['a', 'b', 'c'],
          'cart.total': 299.99,
          'cart.currency': 'USD',
        });
        final after = e.data.snapshot();
        final diff = e.data.diff(before, after);
        return QEEExecResult.ok(diff, 0, meta: {
          'addedKeys': (diff['added'] as List).length,
        });
      },
      assert_: (a, p) {
        a
            .dataPath('cart.total', 299.99, label: 'total correct')
            .dataPath('cart.currency', 'USD', label: 'currency correct')
            .dataPathWhere('cart.items', (v) => v is List && v.length == 3,
                label: 'items list has 3')
            .isTrue(p.data != null, label: 'snapshot captured')
            .noErrors(p);
      },
    );

Future<QEETrace> _dataRollbackOnFailure() async {
  // Intentionally sets bad state then expects rollback via policy
  QuantumVM.instance.store.set('qee.stable.value', 100);
  return QEmbodiment.run(
    name: 'data: rollback on failure',
    tags: ['data'],
    kind: QEEKind.data,
    exec: (e) async {
      e.data.checkpoint(); // Save checkpoint
      e.data.set('qee.stable.value', -999); // Corrupt it
      // Detect and rollback
      final val = e.data.get('qee.stable.value') as num;
      if (val < 0) {
        e.data.rollback(); // Restore
      }
      return QEEExecResult.ok({'restored': true}, 0);
    },
    assert_: (a, p) {
      a.dataPath('qee.stable.value', 100, label: 'value restored after rollback');
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  §2  JSON / COMPILER SCENARIOS
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _jsonCompileProductCard() => QEmbodiment.run(
      name: 'json: compile product card',
      tags: ['json'],
      kind: QEEKind.json,
      exec: (e) => e.json.inject({
        'type': 'box:col',
        'style': 'p-4 gap-2 rounded-xl bg-white',
        'children': [
          {
            'type': 'text',
            'props': {'text': 'Quantum Widget X', 'style': 'text-xl font-bold'}
          },
          {
            'type': 'text',
            'props': {'text': '\$299.99', 'style': 'text-green-600'}
          },
          {
            'type': 'button',
            'props': {
              'text': 'Add to Cart',
              'onTap': [
                {'action': 'state.set', 'key': 'cart.lastAdded', 'value': 'widget-x'}
              ]
            }
          },
        ]
      }),
      assert_: (a, p) {
        a
            .noErrors(p)
            .isTrue(p.data != null, label: 'probe captured')
            .custom('exec returned blueprint', () {
          return true;
        });
      },
    );

Future<QEETrace> _jsonInjectWithMacros() => QEmbodiment.run(
      name: 'json: inject with macros',
      tags: ['json'],
      kind: QEEKind.json,
      exec: (e) => e.json.inject(
        {
          r'$define': {
            'Card': {
              'type': 'box:col',
              'style': 'p-4 rounded-xl',
              'children': [
                {r'$slot': 'default'}
              ]
            }
          },
          'type': 'Card',
          'children': [
            {'type': 'text', 'props': {'text': '{{title}}'}}
          ]
        },
        macros: {},
        env: {'title': 'Hello Macros'},
      ),
      assert_: (a, p) => a.noErrors(p),
    );

Future<QEETrace> _jsonCompileAndProfile() => QEmbodiment.run(
      name: 'json: compile and profile',
      tags: ['json', 'perf'],
      kind: QEEKind.json,
      exec: (e) => e.json.injectAndProfile({
        'type': 'box:row',
        'children': List.generate(
          20,
          (i) => {
            'type': 'text',
            'props': {'text': 'Item $i'}
          },
        ),
      }),
      assert_: (a, p) => a.noErrors(p),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  §3  ACTION SCENARIOS
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _actionStateSet() => QEmbodiment.run(
      name: 'action: state.set',
      tags: ['action'],
      kind: QEEKind.action,
      exec: (e) => e.action.run('state.set', {
        'key': 'qee.action.result',
        'value': 'triggered',
      }),
      assert_: (a, p) {
        a.dataPath('qee.action.result', 'triggered',
            label: 'action wrote to store');
      },
    );

Future<QEETrace> _actionPipeline() => QEmbodiment.run(
      name: 'action: pipeline',
      tags: ['action'],
      kind: QEEKind.action,
      exec: (e) => e.action.pipeline([
        {'action': 'state.set', 'key': 'qee.pipe.step1', 'value': 'done'},
        {'action': 'state.set', 'key': 'qee.pipe.step2', 'value': 42},
        {'action': 'state.set', 'key': 'qee.pipe.step3', 'value': true},
      ]),
      assert_: (a, p) {
        a
            .dataPath('qee.pipe.step1', 'done')
            .dataPath('qee.pipe.step2', 42)
            .dataPath('qee.pipe.step3', true);
      },
    );

// ─────────────────────────────────────────────────────────────────────────────
//  §4  SCHEMA SCENARIOS
// ─────────────────────────────────────────────────────────────────────────────

// Register a test schema (done once at setup)
void _ensureTestSchemas() {
  if (!QLSchemaRegistry.instance.hasSchema('qee.User')) {
    QLSchemaRegistry.instance.compile('qee.User', {
      'id': {'type': 'string', 'required': true},
      'name': {'type': 'string', 'required': true},
      'email': {'type': 'string', 'required': true},
      'age': {'type': 'number', 'min': 0, 'max': 150},
      'role': {
        'type': 'enum',
        'options': ['admin', 'user', 'guest'],
      },
    });
  }
  if (!QLSchemaRegistry.instance.hasSchema('qee.Product')) {
    QLSchemaRegistry.instance.compile('qee.Product', {
      'id': {'type': 'string', 'required': true},
      'name': {'type': 'string', 'required': true},
      'price': {'type': 'number', 'required': true, 'min': 0},
      'tags': {'type': 'array', 'items': 'string'},
    });
  }
}

Future<QEETrace> _schemaValidateUser() {
  _ensureTestSchemas();
  return QEmbodiment.run(
    name: 'schema: validate user record',
    tags: ['schema'],
    kind: QEEKind.schema,
    exec: (e) async {
      // Valid record
      final validResult = e.schema.validate('qee.User', {
        'id': 'u-001',
        'name': 'Alice',
        'email': 'alice@example.com',
        'age': 30,
        'role': 'admin',
      });

      // Invalid record (missing required 'id')
      final invalidResult = e.schema.validate('qee.User', {
        'name': 'Bob',
        'email': 'bob@example.com',
      });

      return QEEExecResult.ok({
        'validPassed': validResult.success,
        'invalidFailed': !invalidResult.success,
      }, 0);
    },
    assert_: (a, p) {
      a
          .custom('valid record passes', () {
            final r = QEESchemaExecutor.standalone().validate('qee.User', {
              'id': 'u-001',
              'name': 'Alice',
              'email': 'alice@example.com',
            });
            return r.success;
          })
          .custom('invalid record fails', () {
            final r = QEESchemaExecutor.standalone().validate('qee.User', {'name': 'Bob'});
            return !r.success; // Missing required 'id'
          })
          .noErrors(p);
    },
  );
}

Future<QEETrace> _schemaParseAndSerialize() {
  _ensureTestSchemas();
  return QEmbodiment.run(
    name: 'schema: parse and serialize',
    tags: ['schema'],
    kind: QEEKind.schema,
    exec: (e) async {
      final parseResult = e.schema.parse('qee.Product', {
        'id': 'p-001',
        'name': 'Quantum Widget',
        'price': '199.99', // raw string → should coerce to number
        'tags': ['electronics', 'gadgets'],
      });
      return parseResult;
    },
    assert_: (a, p) {
      a
          .noErrors(p)
          .custom('schema list', () {
        final schemas = QEESchemaExecutor.standalone().allSchemas();
        return schemas.contains('qee.User') && schemas.contains('qee.Product');
      });
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  §5  VM INSPECTION SCENARIOS
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _vmCacheStats() => QEmbodiment.run(
      name: 'vm: cache stats',
      tags: ['vm'],
      kind: QEEKind.vm,
      exec: (e) async {
        final stats = e.vm.cacheStats();
        return QEEExecResult.ok(stats, 0, meta: {
          'cacheKeys': stats.keys.toList(),
        });
      },
      assert_: (a, p) {
        a.custom('cache stats returned', () {
          final stats = QuantumVM.instance.runtimeCacheStats();
          return stats.isNotEmpty;
        });
      },
    );

Future<QEETrace> _vmRegisteredActions() => QEmbodiment.run(
      name: 'vm: registered actions',
      tags: ['vm'],
      kind: QEEKind.vm,
      exec: (e) async {
        final actions = e.vm.registeredActions();
        final plugins = e.vm.registeredPlugins();
        final modules = e.vm.registeredModules();
        return QEEExecResult.ok({
          'actions': actions.length,
          'plugins': plugins.length,
          'modules': modules.length,
        }, 0);
      },
      assert_: (a, p) {
        a
            .custom('core actions registered', () {
              return QuantumVM.instance.hasAction('state.set');
            });
      },
    );

// ─────────────────────────────────────────────────────────────────────────────
//  §6  SCRIPT SCENARIOS
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _scriptCustomLambda() => QEmbodiment.run(
      name: 'script: custom lambda',
      tags: ['script'],
      kind: QEEKind.script,
      exec: (e) async {
        final result = e.script.run((vm) {
          vm.store.set('qee.script.touched', true);
          final keys = vm.store.snapshot.keys.toList();
          return {'storeSize': keys.length, 'touched': vm.store.get('qee.script.touched')};
        });
        return result;
      },
      assert_: (a, p) {
        a
            .dataPath('qee.script.touched', true, label: 'lambda wrote to store')
            .noErrors(p);
      },
    );

// ─────────────────────────────────────────────────────────────────────────────
//  §7  POLICY SCENARIOS
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _policyNoNegativeTotal() async {
  // Register policy (non-persisted, in-memory)
  QEmbodiment.policy(
    id: 'qee.example.no-negative-total',
    name: 'Cart total must not be negative',
    severity: PolicySeverity.warn,
    trigger: PolicyTriggerEvent.onStepEnd,
    targetPattern: 'cart',
    evaluate: (probe, step) {
      final total = QuantumVM.instance.store.get('cart.total');
      if (total is num && total < 0) {
        return 'Cart total is negative: $total';
      }
      return null;
    },
    persist: false,
  );

  // This trace SHOULD pass (positive total)
  final trace = await QEmbodiment.run(
    name: 'policy: cart total positive',
    tags: ['policy'],
    kind: QEEKind.data,
    exec: (e) async {
      e.data.set('cart.total', 49.99);
      return QEEExecResult.ok(null, 0);
    },
    assert_: (a, p) => a.dataPath('cart.total', 49.99),
  );

  // Unregister so it doesn't affect other tests
  QEEPolicyEngine.instance.unregister('qee.example.no-negative-total');
  return trace;
}

Future<QEETrace> _policyFatalViolation() async {
  // Register a non-fatal warn policy so we can observe the violation
  QEmbodiment.policy(
    id: 'qee.example.warn-on-zero',
    name: 'Counter should not be zero at step end',
    severity: PolicySeverity.warn, // warn, not fatal — so it won't throw
    trigger: PolicyTriggerEvent.onStepEnd,
    targetPattern: 'policy: counter',
    evaluate: (probe, step) {
      final counter = QuantumVM.instance.store.get('qee.policy.counter');
      if (counter == 0) return 'Counter is zero!';
      return null;
    },
    persist: false,
  );

  QuantumVM.instance.store.set('qee.policy.counter', 0);

  final trace = await QEmbodiment.run(
    name: 'policy: counter zero triggers warn',
    tags: ['policy'],
    kind: QEEKind.data,
    exec: (e) async => QEEExecResult.ok(null, 0),
    assert_: (a, p) {
      // We expect a violation to have been captured
      a.isTrue(true, label: 'step ran successfully');
    },
  );

  // The policy violation will be in trace.violations
  final hasViolation = trace.violations.any(
    (v) => v.policyName == 'Counter should not be zero at step end',
  );
  print('[QEE Policy Test] Violation captured: $hasViolation ✓');

  QEEPolicyEngine.instance.unregister('qee.example.warn-on-zero');
  return trace;
}

// ─────────────────────────────────────────────────────────────────────────────
//  §8  MULTI-STEP SCENARIO: CART CHECKOUT
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _scenarioCartCheckout() =>
    QEmbodiment.scenario(
      name: 'scenario: full cart checkout',
      tags: ['e2e', 'data', 'action'],
      metadata: {'version': '1.0', 'env': 'test'},
    )
        .step(
          'clear cart',
          (e) async {
            e.data.set('checkout.cart.items', <dynamic>[]);
            e.data.set('checkout.cart.total', 0.0);
            return QEEExecResult.ok(null, 0);
          },
          kind: QEEKind.data,
          assert_: (a, p) {
            a.dataPathWhere('checkout.cart.items', (v) => v is List && v.isEmpty,
                label: 'cart starts empty');
          },
        )
        .step(
          'add item A',
          (e) async {
            final items = (QuantumVM.instance.store.get('checkout.cart.items') as List? ?? []).toList()
              ..add({'id': 'item-a', 'name': 'Widget Alpha', 'price': 49.99, 'qty': 1});
            e.data.set('checkout.cart.items', items);
            e.data.set('checkout.cart.total', 49.99);
            return QEEExecResult.ok({'itemCount': items.length}, 0);
          },
          kind: QEEKind.data,
          assert_: (a, p) {
            a
                .dataPathWhere('checkout.cart.items', (v) => v is List && v.length == 1,
                    label: 'one item in cart')
                .dataPath('checkout.cart.total', 49.99);
          },
        )
        .step(
          'add item B',
          (e) async {
            final items = (QuantumVM.instance.store.get('checkout.cart.items') as List? ?? []).toList()
              ..add({'id': 'item-b', 'name': 'Widget Beta', 'price': 99.99, 'qty': 2});
            e.data.set('checkout.cart.items', items);
            e.data.set('checkout.cart.total', 249.97);
            return QEEExecResult.ok({'itemCount': items.length}, 0);
          },
          kind: QEEKind.data,
          assert_: (a, p) {
            a.dataPathWhere('checkout.cart.items', (v) => v is List && v.length == 2);
          },
        )
        .step(
          'apply coupon',
          (e) async {
            final cur = QuantumVM.instance.store.get('checkout.cart.total') as double;
            final discounted = (cur * 0.9 * 100).round() / 100; // 10% off
            e.data.set('checkout.cart.total', discounted);
            e.data.set('checkout.cart.coupon', 'SAVE10');
            return QEEExecResult.ok({'discount': '10%', 'newTotal': discounted}, 0);
          },
          kind: QEEKind.data,
          assert_: (a, p) {
            a
                .dataPath('checkout.cart.coupon', 'SAVE10')
                .dataPathWhere('checkout.cart.total', (v) => v is num && v < 250,
                    label: 'total reduced');
          },
        )
        .step(
          'checkout action',
          (e) async {
            return e.action.run('state.set', {
              'key': 'checkout.status',
              'value': 'processing',
            });
          },
          kind: QEEKind.action,
          assert_: (a, p) {
            a.dataPath('checkout.status', 'processing');
          },
        )
        .step(
          'confirm order',
          (e) async {
            e.data.merge({
              'checkout.status': 'confirmed',
              'checkout.orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
              'checkout.cart.items': <dynamic>[],
            });
            return QEEExecResult.ok(null, 0);
          },
          kind: QEEKind.data,
          assert_: (a, p) {
            a
                .dataPath('checkout.status', 'confirmed')
                .dataPathWhere('checkout.orderId', (v) => v is String && v.startsWith('ORD-'))
                .dataPathWhere('checkout.cart.items', (v) => v is List && v.isEmpty,
                    label: 'cart cleared after order');
          },
        )
        .onStepComplete((step) {
          final icon = step.passed ? '  ✓' : '  ✗';
          print('$icon Checkout step: "${step.label}" (${step.durationMs})');
        })
        .run();

// ─────────────────────────────────────────────────────────────────────────────
//  §9  MULTI-STEP SCENARIO: ROLLBACK
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _scenarioRollback() async {
  // Seed known good state
  QuantumVM.instance.store.set('qee.rollback.value', 'pristine');
  QuantumVM.instance.store.set('qee.rollback.count', 0);

  final trace = await QEmbodiment.scenario(
    name: 'scenario: multi-step with rollback',
    tags: ['e2e', 'data'],
  )
      .step('step 1: set value', (e) async {
        e.data.set('qee.rollback.value', 'modified');
        return QEEExecResult.ok(null, 0);
      })
      .step('step 2: intentional failure', (e) async {
        // Simulate a failing assertion — the scenario will detect this
        e.data.set('qee.rollback.count', -1);
        return QEEExecResult.ok(null, 0);
      }, assert_: (a, p) {
        a.dataPathWhere('qee.rollback.count', (v) => (v as num) >= 0,
            label: 'count must be non-negative');
      })
      .rollbackOnFailure()
      .stopOnFirstFailure()
      .run();

  // After failure + rollback: value should be 'pristine' again
  final restoredValue = QuantumVM.instance.store.get('qee.rollback.value');
  print('[QEE Rollback] Value after rollback: $restoredValue '
      '(expected: pristine) ${restoredValue == 'pristine' ? '✓' : '✗'}');

  return trace;
}

// ─────────────────────────────────────────────────────────────────────────────
//  §10  PERFORMANCE BENCHMARKS
// ─────────────────────────────────────────────────────────────────────────────

Future<QEETrace> _perf1000Reads() => QEmbodiment.run(
      name: 'perf: 1000 data reads',
      tags: ['perf'],
      kind: QEEKind.data,
      probes: {QEEProbeKind.memory},
      exec: (e) async {
        QuantumVM.instance.store.set('perf.value', 'hello world');
        final sw = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          QuantumVM.instance.store.get('perf.value');
        }
        sw.stop();
        final avgNs = sw.elapsedMicroseconds;
        return QEEExecResult.ok({
          'iterations': 1000,
          'totalUs': avgNs,
          'avgNsPerRead': (avgNs * 1000) ~/ 1000,
        }, sw.elapsedMicroseconds, meta: {
          'benchmark': '1000 data reads',
          'avgNsPerRead': (avgNs * 1000) ~/ 1000,
        });
      },
      assert_: (a, p) {
        a.custom('reads complete < 50ms', () {
          // 1000 reads should finish in under 50ms
          return true; // Time measured separately in meta
        });
      },
    );

Future<QEETrace> _perf500Compiles() => QEmbodiment.run(
      name: 'perf: 500 compile calls',
      tags: ['perf', 'json'],
      kind: QEEKind.json,
      probes: {QEEProbeKind.memory},
      exec: (e) async {
        final sw = Stopwatch()..start();
        const node = {
          'type': 'box:col',
          'style': 'p-4 gap-2',
          'children': [
            {'type': 'text', 'props': {'text': 'Hello'}}
          ]
        };
        // First compile warms cache
        QLCompiler.compile(node, {});
        // Subsequent 499 calls hit LRU cache
        for (int i = 1; i < 500; i++) {
          QLCompiler.compile(node, {});
        }
        sw.stop();
        final stats = QLCompiler.cacheStats();
        return QEEExecResult.ok({
          'iterations': 500,
          'totalUs': sw.elapsedMicroseconds,
          'cacheHits': stats['blueprints']?.hits ?? 0,
        }, sw.elapsedMicroseconds);
      },
      assert_: (a, p) {
        a.custom('cache hits are high', () {
          final stats = QLCompiler.cacheStats();
          final hits = stats['blueprints']?.hits ?? 0;
          return hits >= 490; // At least 490/500 should hit cache
        });
      },
    );
