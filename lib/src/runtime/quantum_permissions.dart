// ════════════════════════════════════════════════════════════════════════════
// quantum_permissions.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:collection';
import 'dart:convert';

import '../plugins/quantum_auth_engine.dart';

class QuantumPermissionException implements Exception {
  final String code;
  final String message;
  final Object? details;

  const QuantumPermissionException(this.code, this.message, {this.details});

  @override
  String toString() => 'QuantumPermissionException($code): $message';
}

class QuantumPermissionDecision {
  final bool allowed;
  final String reason;
  final List<String> matched;
  final Map<String, dynamic> meta;

  const QuantumPermissionDecision({
    required this.allowed,
    required this.reason,
    this.matched = const <String>[],
    this.meta = const <String, dynamic>{},
  });

  const QuantumPermissionDecision.allow([
    this.reason = 'allowed',
    this.matched = const <String>[],
    this.meta = const <String, dynamic>{},
  ]) : allowed = true;

  const QuantumPermissionDecision.deny([
    this.reason = 'denied',
    this.matched = const <String>[],
    this.meta = const <String, dynamic>{},
  ]) : allowed = false;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'allowed': allowed,
        'reason': reason,
        'matched': matched,
        'meta': meta,
      };
}

class QuantumPermissionContext {
  final SessionContext? session;
  final Map<String, dynamic> env;
  final Map<String, dynamic> data;
  final String? scope;
  final String? resource;
  final String? operation;
  final String? feature;
  final String? schema;
  final DateTime now;
  final Map<String, dynamic> meta;

  const QuantumPermissionContext({
    required this.session,
    required this.env,
    required this.data,
    required this.scope,
    required this.resource,
    required this.operation,
    required this.feature,
    required this.schema,
    required this.now,
    required this.meta,
  });

  factory QuantumPermissionContext.fromSession(
    SessionContext? session, {
    Map<String, dynamic> env = const <String, dynamic>{},
    Map<String, dynamic> data = const <String, dynamic>{},
    String? scope,
    String? resource,
    String? operation,
    String? feature,
    String? schema,
    DateTime? now,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumPermissionContext(
      session: session,
      env: Map<String, dynamic>.from(env),
      data: Map<String, dynamic>.from(data),
      scope: scope,
      resource: resource,
      operation: operation,
      feature: feature,
      schema: schema,
      now: now ?? DateTime.now(),
      meta: Map<String, dynamic>.from(meta),
    );
  }

  bool get isAuthenticated => session?.isAuthenticated == true;
  String? get userId => session?.userId;
  Map<String, dynamic> get claims =>
      session?.claims ?? const <String, dynamic>{};

  Set<String> get roles => _mergeStringSets([
        claims['roles'],
        claims['role'],
        env['roles'],
        env['role'],
        data['roles'],
        data['role'],
        meta['roles'],
      ]);

  Set<String> get permissions => _mergeStringSets([
        claims['permissions'],
        claims['permission'],
        env['permissions'],
        env['permission'],
        data['permissions'],
        data['permission'],
        meta['permissions'],
      ]);

  Set<String> get features => _mergeStringSets([
        claims['features'],
        claims['featureFlags'],
        env['features'],
        env['featureFlags'],
        data['features'],
        meta['features'],
      ]);

  Set<String> get subscriptions => _mergeStringSets([
        claims['subscriptions'],
        claims['subscription'],
        claims['plan'],
        env['subscriptions'],
        env['subscription'],
        data['subscriptions'],
        data['subscription'],
        meta['subscriptions'],
      ]);

  dynamic claim(String key) {
    final resolved = _lookupAny([
      claims,
      meta,
      env,
      data,
    ], key);
    return resolved;
  }

  bool hasRole(String role) => roles.contains(role);
  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasFeature(String featureName) => features.contains(featureName);
  bool hasSubscription(String value) => subscriptions.contains(value);

  bool opIs(String value) => operation == value;
  bool scopeIs(String value) =>
      scope == value || resource == value || schema == value;
}

class QuantumPermissionRegistry {
  static final QuantumPermissionRegistry instance =
      QuantumPermissionRegistry._();
  QuantumPermissionRegistry._();

  final Map<String, dynamic> _rules = <String, dynamic>{};

  void register(String name, dynamic rule) {
    _rules[name] = rule;
  }

  dynamic resolve(String name) => _rules[name];
  bool contains(String name) => _rules.containsKey(name);
  void clear() => _rules.clear();
}

class QuantumPermissionEngine {
  static final QuantumPermissionEngine instance = QuantumPermissionEngine._();
  QuantumPermissionEngine._();

  static const int _cacheLimit = 512;
  final LinkedHashMap<String, QuantumPermissionDecision> _cache =
      LinkedHashMap<String, QuantumPermissionDecision>();

  QuantumPermissionDecision evaluate(
    dynamic rule,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    final dynamic resolvedRule = _resolveRule(rule);
    final String cacheKey = _cacheKey(resolvedRule, context, meta);
    final cached = _cache.remove(cacheKey);
    if (cached != null) {
      _cache[cacheKey] = cached;
      return cached;
    }

    final decision = _evaluateRule(resolvedRule, context, meta: meta);
    if (_cache.length >= _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = decision;
    return decision;
  }

  bool allows(
    dynamic rule,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) =>
      evaluate(rule, context, meta: meta).allowed;

  QuantumPermissionDecision require(
    dynamic rule,
    QuantumPermissionContext context, {
    String code = 'permission_denied',
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    final decision = evaluate(rule, context, meta: meta);
    if (!decision.allowed) {
      throw QuantumPermissionException(code, decision.reason,
          details: decision.meta);
    }
    return decision;
  }

  QuantumPermissionDecision _evaluateRule(
    dynamic rule,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    if (rule == null) {
      return const QuantumPermissionDecision.allow('no rule provided');
    }
    if (rule is QuantumPermissionDecision) return rule;
    if (rule is bool) {
      return rule
          ? const QuantumPermissionDecision.allow('boolean allow')
          : const QuantumPermissionDecision.deny('boolean deny');
    }
    if (rule is Future) {
      return const QuantumPermissionDecision.deny(
          'async rules must be resolved before evaluation');
    }
    if (rule is Function) {
      try {
        final dynamic result = Function.apply(rule, <dynamic>[context, meta]);
        if (result is QuantumPermissionDecision) return result;
        if (result is bool) {
          return result
              ? const QuantumPermissionDecision.allow('custom rule allowed')
              : const QuantumPermissionDecision.deny('custom rule denied');
        }
        if (result is Map && result['allowed'] is bool) {
          return QuantumPermissionDecision(
            allowed: result['allowed'] == true,
            reason: result['reason']?.toString() ?? 'custom rule',
            matched: (result['matched'] as List?)
                    ?.map((e) => e.toString())
                    .toList(growable: false) ??
                const <String>[],
            meta: (result['meta'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{},
          );
        }
      } catch (e) {
        return QuantumPermissionDecision.deny('custom rule error: $e');
      }
      return const QuantumPermissionDecision.deny(
          'custom rule returned unsupported value');
    }

    if (rule is String) {
      final trimmed = rule.trim();
      if (trimmed.isEmpty)
        return const QuantumPermissionDecision.allow('empty rule');
      if (trimmed == 'true')
        return const QuantumPermissionDecision.allow('literal true');
      if (trimmed == 'false')
        return const QuantumPermissionDecision.deny('literal false');
      final resolved = QuantumPermissionRegistry.instance
          .resolve(trimmed.startsWith('@') ? trimmed.substring(1) : trimmed);
      if (resolved != null) return evaluate(resolved, context, meta: meta);
      return _evaluateAtom({'role': trimmed}, context, meta: meta);
    }

    if (rule is List) {
      for (final item in rule) {
        final decision = evaluate(item, context, meta: meta);
        if (!decision.allowed) return decision;
      }
      return const QuantumPermissionDecision.allow('list allowed');
    }

    if (rule is Map) {
      return _evaluateMap(Map<String, dynamic>.from(rule), context, meta: meta);
    }

    return const QuantumPermissionDecision.deny('unsupported rule type');
  }

  QuantumPermissionDecision _evaluateMap(
    Map<String, dynamic> map,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    final List<String> matched = <String>[];

    if (map.containsKey('all') || map.containsKey('and')) {
      final raw = map['all'] ?? map['and'];
      final items = raw is List ? raw : <dynamic>[raw];
      for (final item in items) {
        final decision = evaluate(item, context, meta: meta);
        matched.addAll(decision.matched);
        if (!decision.allowed) return decision;
      }
      return QuantumPermissionDecision.allow('all matched', matched, map);
    }

    if (map.containsKey('any') || map.containsKey('or')) {
      final raw = map['any'] ?? map['or'];
      final items = raw is List ? raw : <dynamic>[raw];
      QuantumPermissionDecision? lastDenied;
      for (final item in items) {
        final decision = evaluate(item, context, meta: meta);
        if (decision.allowed) {
          matched.addAll(decision.matched);
          return QuantumPermissionDecision.allow('any matched', matched, map);
        }
        lastDenied = decision;
      }
      return lastDenied ??
          const QuantumPermissionDecision.deny('no matching any-rule');
    }

    if (map.containsKey('not')) {
      final decision = evaluate(map['not'], context, meta: meta);
      return decision.allowed
          ? QuantumPermissionDecision.deny(
              'negated rule allowed', decision.matched, map)
          : QuantumPermissionDecision.allow(
              'negated rule denied', decision.matched, map);
    }

    final List<QuantumPermissionDecision> fragments =
        <QuantumPermissionDecision>[];
    for (final entry in map.entries) {
      switch (entry.key) {
        case 'role':
        case 'roles':
        case 'userRole':
          fragments.add(_evaluateRole(entry.value, context));
          break;
        case 'permission':
        case 'permissions':
          fragments.add(_evaluatePermission(entry.value, context));
          break;
        case 'feature':
        case 'features':
        case 'featureFlag':
        case 'featureFlags':
          fragments.add(_evaluateFeature(entry.value, context));
          break;
        case 'subscription':
        case 'subscriptions':
        case 'plan':
          fragments.add(_evaluateSubscription(entry.value, context));
          break;
        case 'claim':
        case 'claims':
          fragments.add(_evaluateClaim(entry.value, context));
          break;
        case 'data':
        case 'fields':
        case 'field':
          fragments.add(_evaluateData(entry.value, context));
          break;
        case 'op':
        case 'operation':
          fragments.add(_evaluateOperation(entry.value, context));
          break;
        case 'resource':
        case 'scope':
        case 'schema':
          fragments.add(_evaluateScope(entry.key, entry.value, context));
          break;
        case 'time':
        case 'clock':
        case 'schedule':
          fragments.add(_evaluateTime(entry.value, context));
          break;
        case 'custom':
          fragments.add(_evaluateCustom(entry.value, context, meta: meta));
          break;
        case 'allow':
          if (entry.value is bool && entry.value == false) {
            return QuantumPermissionDecision.deny(
                'explicit allow=false', matched, map);
          }
          break;
        case 'deny':
          if (entry.value == true) {
            return QuantumPermissionDecision.deny(
                'explicit deny', matched, map);
          }
          break;
        case 'meta':
          break;
        default:
          break;
      }
    }

    for (final fragment in fragments) {
      if (!fragment.allowed) return fragment;
      matched.addAll(fragment.matched);
    }
    return QuantumPermissionDecision.allow('all atoms allowed', matched, map);
  }

  QuantumPermissionDecision _evaluateAtom(
    Map<String, dynamic> atom,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    if (atom.isEmpty)
      return const QuantumPermissionDecision.allow('empty atom');

    if (atom.containsKey('role')) return _evaluateRole(atom['role'], context);
    if (atom.containsKey('roles')) return _evaluateRole(atom['roles'], context);
    if (atom.containsKey('permission'))
      return _evaluatePermission(atom['permission'], context);
    if (atom.containsKey('permissions'))
      return _evaluatePermission(atom['permissions'], context);
    if (atom.containsKey('feature'))
      return _evaluateFeature(atom['feature'], context);
    if (atom.containsKey('features'))
      return _evaluateFeature(atom['features'], context);
    if (atom.containsKey('subscription'))
      return _evaluateSubscription(atom['subscription'], context);
    if (atom.containsKey('subscriptions'))
      return _evaluateSubscription(atom['subscriptions'], context);
    if (atom.containsKey('claim') || atom.containsKey('claims'))
      return _evaluateClaim(atom['claim'] ?? atom['claims'], context);
    if (atom.containsKey('data') ||
        atom.containsKey('field') ||
        atom.containsKey('fields'))
      return _evaluateData(
          atom['data'] ?? atom['field'] ?? atom['fields'], context);
    if (atom.containsKey('op') || atom.containsKey('operation'))
      return _evaluateOperation(atom['op'] ?? atom['operation'], context);
    if (atom.containsKey('resource') ||
        atom.containsKey('scope') ||
        atom.containsKey('schema'))
      return _evaluateScope(
          atom.containsKey('resource')
              ? 'resource'
              : atom.containsKey('scope')
                  ? 'scope'
                  : 'schema',
          atom['resource'] ?? atom['scope'] ?? atom['schema'],
          context);
    if (atom.containsKey('time') ||
        atom.containsKey('clock') ||
        atom.containsKey('schedule'))
      return _evaluateTime(
          atom['time'] ?? atom['clock'] ?? atom['schedule'], context);
    if (atom.containsKey('custom'))
      return _evaluateCustom(atom['custom'], context, meta: meta);
    if (atom.containsKey('rule'))
      return evaluate(atom['rule'], context, meta: meta);

    return _evaluateEquality(atom, context);
  }

  QuantumPermissionDecision _evaluateRole(
      dynamic raw, QuantumPermissionContext context) {
    final values = _toStringList(raw);
    if (values.isEmpty)
      return const QuantumPermissionDecision.allow('no role constraint');
    final hits = values.where(context.hasRole).toList(growable: false);
    if (hits.isNotEmpty) {
      return QuantumPermissionDecision.allow(
          'role matched', hits, <String, dynamic>{'required': values});
    }
    return QuantumPermissionDecision.deny(
        'missing required role', const <String>[], <String, dynamic>{
      'required': values,
      'actual': context.roles.toList(growable: false)
    });
  }

  QuantumPermissionDecision _evaluatePermission(
      dynamic raw, QuantumPermissionContext context) {
    final values = _toStringList(raw);
    if (values.isEmpty)
      return const QuantumPermissionDecision.allow('no permission constraint');
    final hits = values.where(context.hasPermission).toList(growable: false);
    if (hits.isNotEmpty) {
      return QuantumPermissionDecision.allow(
          'permission matched', hits, <String, dynamic>{'required': values});
    }
    return QuantumPermissionDecision.deny(
        'missing required permission', const <String>[], <String, dynamic>{
      'required': values,
      'actual': context.permissions.toList(growable: false)
    });
  }

  QuantumPermissionDecision _evaluateFeature(
      dynamic raw, QuantumPermissionContext context) {
    final values = _toStringList(raw);
    if (values.isEmpty)
      return const QuantumPermissionDecision.allow('no feature constraint');
    final hits = values.where(context.hasFeature).toList(growable: false);
    if (hits.isNotEmpty) {
      return QuantumPermissionDecision.allow(
          'feature matched', hits, <String, dynamic>{'required': values});
    }
    return QuantumPermissionDecision.deny(
        'missing required feature', const <String>[], <String, dynamic>{
      'required': values,
      'actual': context.features.toList(growable: false)
    });
  }

  QuantumPermissionDecision _evaluateSubscription(
      dynamic raw, QuantumPermissionContext context) {
    final values = _toStringList(raw);
    if (values.isEmpty)
      return const QuantumPermissionDecision.allow(
          'no subscription constraint');
    final hits = values.where(context.hasSubscription).toList(growable: false);
    if (hits.isNotEmpty) {
      return QuantumPermissionDecision.allow(
          'subscription matched', hits, <String, dynamic>{'required': values});
    }
    return QuantumPermissionDecision.deny(
        'missing required subscription', const <String>[], <String, dynamic>{
      'required': values,
      'actual': context.subscriptions.toList(growable: false)
    });
  }

  QuantumPermissionDecision _evaluateClaim(
      dynamic raw, QuantumPermissionContext context) {
    if (raw is String) {
      final value = context.claim(raw);
      return _truthyDecision(value, 'claim:$raw');
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final List<String> matched = <String>[];
      for (final entry in map.entries) {
        final dynamic current = context.claim(entry.key);
        final decision =
            _compareValue(entry.key, current, entry.value, context);
        if (!decision.allowed) return decision;
        matched.addAll(decision.matched);
      }
      return QuantumPermissionDecision.allow('claim map matched', matched, map);
    }
    if (raw is List) {
      for (final item in raw) {
        final decision = _evaluateClaim(item, context);
        if (!decision.allowed) return decision;
      }
      return const QuantumPermissionDecision.allow('claims list matched');
    }
    return const QuantumPermissionDecision.allow('claim rule empty');
  }

  QuantumPermissionDecision _evaluateData(
      dynamic raw, QuantumPermissionContext context) {
    if (raw is String) {
      final value = _lookupAny([context.data, context.env, context.meta], raw);
      return _truthyDecision(value, 'data:$raw');
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final entry in map.entries) {
        final current =
            _lookupAny([context.data, context.env, context.meta], entry.key);
        final decision =
            _compareValue(entry.key, current, entry.value, context);
        if (!decision.allowed) return decision;
      }
      return const QuantumPermissionDecision.allow('data map matched');
    }
    if (raw is List) {
      for (final item in raw) {
        final decision = _evaluateData(item, context);
        if (!decision.allowed) return decision;
      }
      return const QuantumPermissionDecision.allow('data list matched');
    }
    return const QuantumPermissionDecision.allow('data rule empty');
  }

  QuantumPermissionDecision _evaluateOperation(
      dynamic raw, QuantumPermissionContext context) {
    final values = _toStringList(raw);
    if (values.isEmpty)
      return const QuantumPermissionDecision.allow('no operation constraint');
    final hits =
        values.where((value) => context.opIs(value)).toList(growable: false);
    if (hits.isNotEmpty) {
      return QuantumPermissionDecision.allow(
          'operation matched', hits, <String, dynamic>{'required': values});
    }
    return QuantumPermissionDecision.deny('operation denied', const <String>[],
        <String, dynamic>{'required': values, 'actual': context.operation});
  }

  QuantumPermissionDecision _evaluateScope(
      String kind, dynamic raw, QuantumPermissionContext context) {
    final values = _toStringList(raw);
    if (values.isEmpty)
      return const QuantumPermissionDecision.allow('no scope constraint');
    final matched = values.where(context.scopeIs).toList(growable: false);
    if (matched.isNotEmpty) {
      return QuantumPermissionDecision.allow(
          '$kind matched', matched, <String, dynamic>{'required': values});
    }
    return QuantumPermissionDecision.deny(
        '$kind denied', const <String>[], <String, dynamic>{
      'required': values,
      'actual': <String?>[context.scope, context.resource, context.schema]
    });
  }

  QuantumPermissionDecision _evaluateTime(
      dynamic raw, QuantumPermissionContext context) {
    if (raw == null)
      return const QuantumPermissionDecision.allow('no time constraint');
    if (raw is bool)
      return raw
          ? const QuantumPermissionDecision.allow('time true')
          : const QuantumPermissionDecision.deny('time false');
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final start = _parseDateTime(map['from'] ?? map['start']);
      final end = _parseDateTime(map['to'] ?? map['end']);
      if (start != null && context.now.isBefore(start)) {
        return QuantumPermissionDecision.deny(
            'time before window',
            const <String>[],
            <String, dynamic>{'from': start.toIso8601String()});
      }
      if (end != null && context.now.isAfter(end)) {
        return QuantumPermissionDecision.deny('time after window',
            const <String>[], <String, dynamic>{'to': end.toIso8601String()});
      }
      final weekdays = _toIntList(map['weekdays'] ?? map['days']);
      if (weekdays.isNotEmpty && !weekdays.contains(context.now.weekday)) {
        return QuantumPermissionDecision.deny(
            'weekday not allowed', const <String>[], <String, dynamic>{
          'allowedDays': weekdays,
          'actual': context.now.weekday
        });
      }
      final hours = map['hours'];
      if (hours is Map) {
        final fromHour = (hours['from'] as num?)?.toInt() ??
            int.tryParse(hours['from']?.toString() ?? '');
        final toHour = (hours['to'] as num?)?.toInt() ??
            int.tryParse(hours['to']?.toString() ?? '');
        final h = context.now.hour;
        if (fromHour != null && h < fromHour) {
          return QuantumPermissionDecision.deny(
              'hour before window',
              const <String>[],
              <String, dynamic>{'from': fromHour, 'actual': h});
        }
        if (toHour != null && h > toHour) {
          return QuantumPermissionDecision.deny('hour after window',
              const <String>[], <String, dynamic>{'to': toHour, 'actual': h});
        }
      }
      return QuantumPermissionDecision.allow(
          'time window matched', const <String>[], map);
    }
    return const QuantumPermissionDecision.allow('time rule default');
  }

  QuantumPermissionDecision _evaluateCustom(
      dynamic raw, QuantumPermissionContext context,
      {Map<String, dynamic> meta = const <String, dynamic>{}}) {
    if (raw is String) {
      final resolved = QuantumPermissionRegistry.instance
          .resolve(raw.startsWith('@') ? raw.substring(1) : raw);
      if (resolved != null) return evaluate(resolved, context, meta: meta);
      return _evaluateAtom(<String, dynamic>{raw: true}, context, meta: meta);
    }
    if (raw is Function) {
      return _evaluateRule(raw, context, meta: meta);
    }
    if (raw is Map || raw is List || raw is bool) {
      return evaluate(raw, context, meta: meta);
    }
    return const QuantumPermissionDecision.allow('custom rule ignored');
  }

  QuantumPermissionDecision _evaluateEquality(
      Map<String, dynamic> atom, QuantumPermissionContext context) {
    final List<String> matched = <String>[];
    for (final entry in atom.entries) {
      final dynamic current = _lookupAny(
          [context.data, context.env, context.meta, context.claims], entry.key);
      final decision = _compareValue(entry.key, current, entry.value, context);
      if (!decision.allowed) return decision;
      matched.addAll(decision.matched);
    }
    return QuantumPermissionDecision.allow('equality matched', matched, atom);
  }

  QuantumPermissionDecision _compareValue(
    String key,
    dynamic current,
    dynamic expected,
    QuantumPermissionContext context,
  ) {
    if (expected is Map) {
      final map = Map<String, dynamic>.from(expected);
      final List<String> matched = <String>[];
      if (map.containsKey('exists')) {
        final bool exists = map['exists'] == true;
        final bool actualExists = current != null;
        if (exists != actualExists) {
          return QuantumPermissionDecision.deny(
              '$key exists mismatch',
              const <String>[],
              <String, dynamic>{'exists': exists, 'actual': actualExists});
        }
      }
      if (map.containsKey('equals') || map.containsKey('eq')) {
        final dynamic eq = map['equals'] ?? map['eq'];
        if (current != eq) {
          return QuantumPermissionDecision.deny(
              '$key equality mismatch',
              const <String>[],
              <String, dynamic>{'expected': eq, 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('in')) {
        final list = _toDynamicList(map['in']);
        if (!list.contains(current)) {
          return QuantumPermissionDecision.deny(
              '$key not in set',
              const <String>[],
              <String, dynamic>{'expected': list, 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('contains')) {
        final needle = map['contains'];
        final ok = current is String
            ? current.contains(needle.toString())
            : current is Iterable
                ? current.contains(needle)
                : false;
        if (!ok) {
          return QuantumPermissionDecision.deny(
              '$key missing contains constraint',
              const <String>[],
              <String, dynamic>{'needle': needle, 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('regex')) {
        final regex = RegExp(map['regex'].toString());
        final ok = current != null && regex.hasMatch(current.toString());
        if (!ok) {
          return QuantumPermissionDecision.deny(
              '$key regex mismatch',
              const <String>[],
              <String, dynamic>{'regex': regex.pattern, 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('gte') || map.containsKey('min')) {
        final minValue = map['gte'] ?? map['min'];
        if (!_compareNumeric(current, minValue, (a, b) => a >= b)) {
          return QuantumPermissionDecision.deny(
              '$key gte mismatch',
              const <String>[],
              <String, dynamic>{'min': minValue, 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('lte') || map.containsKey('max')) {
        final maxValue = map['lte'] ?? map['max'];
        if (!_compareNumeric(current, maxValue, (a, b) => a <= b)) {
          return QuantumPermissionDecision.deny(
              '$key lte mismatch',
              const <String>[],
              <String, dynamic>{'max': maxValue, 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('gt')) {
        if (!_compareNumeric(current, map['gt'], (a, b) => a > b)) {
          return QuantumPermissionDecision.deny(
              '$key gt mismatch',
              const <String>[],
              <String, dynamic>{'gt': map['gt'], 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('lt')) {
        if (!_compareNumeric(current, map['lt'], (a, b) => a < b)) {
          return QuantumPermissionDecision.deny(
              '$key lt mismatch',
              const <String>[],
              <String, dynamic>{'lt': map['lt'], 'actual': current});
        }
        matched.add(key);
      }
      if (map.containsKey('not')) {
        final bool same = current == map['not'];
        if (same) {
          return QuantumPermissionDecision.deny(
              '$key forbidden value matched',
              const <String>[],
              <String, dynamic>{'not': map['not'], 'actual': current});
        }
      }
      if (matched.isNotEmpty || map.isEmpty) {
        return QuantumPermissionDecision.allow(
            'comparison matched', matched, map);
      }
      return QuantumPermissionDecision.allow(
          'comparison no-op', const <String>[], map);
    }

    if (expected is List) {
      final ok = expected.contains(current);
      return ok
          ? QuantumPermissionDecision.allow('$key matched list', <String>[key],
              <String, dynamic>{'expected': expected, 'actual': current})
          : QuantumPermissionDecision.deny(
              '$key list mismatch',
              const <String>[],
              <String, dynamic>{'expected': expected, 'actual': current});
    }

    final bool ok =
        current == expected || current?.toString() == expected.toString();
    return ok
        ? QuantumPermissionDecision.allow('$key matched', <String>[key],
            <String, dynamic>{'expected': expected, 'actual': current})
        : QuantumPermissionDecision.deny('$key mismatch', const <String>[],
            <String, dynamic>{'expected': expected, 'actual': current});
  }

  QuantumPermissionDecision _truthyDecision(dynamic value, String label) {
    final ok = value == true ||
        value == 1 ||
        value == '1' ||
        value == 'true' ||
        value == 'yes' ||
        value == 'on';
    return ok
        ? QuantumPermissionDecision.allow('$label truthy', <String>[label])
        : QuantumPermissionDecision.deny('$label falsy', const <String>[],
            <String, dynamic>{'value': value});
  }

  bool _compareNumeric(
      dynamic current, dynamic expected, bool Function(num a, num b) test) {
    final a =
        current is num ? current : num.tryParse(current?.toString() ?? '');
    final b =
        expected is num ? expected : num.tryParse(expected?.toString() ?? '');
    if (a == null || b == null) return false;
    return test(a, b);
  }

  dynamic _resolveRule(dynamic rule) {
    if (rule is String) {
      final trimmed = rule.trim();
      if (trimmed.startsWith('@')) {
        return QuantumPermissionRegistry.instance
                .resolve(trimmed.substring(1)) ??
            rule;
      }
      if (QuantumPermissionRegistry.instance.contains(trimmed)) {
        return QuantumPermissionRegistry.instance.resolve(trimmed) ?? rule;
      }
    }
    return rule;
  }

  String _cacheKey(dynamic rule, QuantumPermissionContext context,
      Map<String, dynamic> meta) {
    return _stableStringify(<String, dynamic>{
      'rule': rule,
      'user': context.userId,
      'roles': context.roles.toList(growable: false)..sort(),
      'permissions': context.permissions.toList(growable: false)..sort(),
      'features': context.features.toList(growable: false)..sort(),
      'subscriptions': context.subscriptions.toList(growable: false)..sort(),
      'scope': context.scope,
      'resource': context.resource,
      'operation': context.operation,
      'feature': context.feature,
      'schema': context.schema,
      'data': context.data,
      'env': context.env,
      'meta': meta,
    });
  }

  String _stableStringify(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((e) => e.toString()).toList(growable: false)
        ..sort();
      return '{${keys.map((k) => '${jsonEncode(k)}:${_stableStringify(value[k])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_stableStringify).join(',')}]';
    }
    return jsonEncode(value);
  }

  List<String> _toStringList(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is String) return <String>[raw];
    if (raw is Iterable) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
    }
    return <String>[raw.toString()];
  }

  List<int> _toIntList(dynamic raw) {
    if (raw == null) return const <int>[];
    if (raw is int) return <int>[raw];
    if (raw is Iterable) {
      return raw
          .map((e) => int.tryParse(e.toString()) ?? -1)
          .where((e) => e >= 0)
          .toList(growable: false);
    }
    final parsed = int.tryParse(raw.toString());
    return parsed == null ? const <int>[] : <int>[parsed];
  }

  List<dynamic> _toDynamicList(dynamic raw) {
    if (raw == null) return const <dynamic>[];
    if (raw is List) return List<dynamic>.from(raw);
    if (raw is Iterable) return raw.toList(growable: false);
    return <dynamic>[raw];
  }

  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}

extension QuantumSessionPermissionExtensions on SessionContext {
  QuantumPermissionContext permissionContext({
    Map<String, dynamic> env = const <String, dynamic>{},
    Map<String, dynamic> data = const <String, dynamic>{},
    String? scope,
    String? resource,
    String? operation,
    String? feature,
    String? schema,
    DateTime? now,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumPermissionContext.fromSession(
      this,
      env: env,
      data: data,
      scope: scope,
      resource: resource,
      operation: operation,
      feature: feature,
      schema: schema,
      now: now,
      meta: meta,
    );
  }

  bool can(
    dynamic rule, {
    Map<String, dynamic> env = const <String, dynamic>{},
    Map<String, dynamic> data = const <String, dynamic>{},
    String? scope,
    String? resource,
    String? operation,
    String? feature,
    String? schema,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumPermissionEngine.instance.allows(
      rule,
      permissionContext(
        env: env,
        data: data,
        scope: scope,
        resource: resource,
        operation: operation,
        feature: feature,
        schema: schema,
        meta: meta,
      ),
      meta: meta,
    );
  }

  bool hasRoleValue(String role) => roles.contains(role);
  bool hasPermissionValue(String permission) =>
      permissions.contains(permission);
  bool hasFeatureValue(String feature) => features.contains(feature);
  bool hasSubscriptionValue(String subscription) =>
      subscriptions.contains(subscription);

  List<String> get roles =>
      QuantumPermissionContext.fromSession(this).roles.toList(growable: false);
  List<String> get permissions => QuantumPermissionContext.fromSession(this)
      .permissions
      .toList(growable: false);
  List<String> get features => QuantumPermissionContext.fromSession(this)
      .features
      .toList(growable: false);
  List<String> get subscriptions => QuantumPermissionContext.fromSession(this)
      .subscriptions
      .toList(growable: false);

  SessionContext withClaims(Map<String, dynamic> newClaims) => SessionContext(
        userId: userId,
        sessionId: sessionId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        claims: Map<String, dynamic>.from(claims)..addAll(newClaims),
        authProviderUsed: authProviderUsed,
        deviceId: deviceId,
      );
}

// ════════════════════════════════════════════════════════════════════════════
// File-level utility functions and constants
// ════════════════════════════════════════════════════════════════════════════

const Object _missing = Object();

dynamic _lookupAny(List<dynamic> sources, String path) {
  final parts = path.split('.');
  for (final source in sources) {
    final value = _lookup(source, parts);
    if (value != _missing) return value;
  }
  return null;
}

dynamic _lookup(dynamic source, List<String> parts) {
  dynamic current = source;
  for (final part in parts) {
    if (current is Map) {
      if (!current.containsKey(part)) return _missing;
      current = current[part];
    } else if (current is List) {
      final index = int.tryParse(part);
      if (index == null || index < 0 || index >= current.length) {
        return _missing;
      }
      current = current[index];
    } else {
      return _missing;
    }
  }
  return current;
}

Set<String> _mergeStringSets(Iterable<dynamic> values) {
  final out = <String>{};
  for (final raw in values) {
    if (raw == null) continue;
    if (raw is String) {
      if (raw.trim().isNotEmpty) out.add(raw.trim());
      continue;
    }
    if (raw is Iterable) {
      for (final item in raw) {
        final s = item?.toString().trim() ?? '';
        if (s.isNotEmpty) out.add(s);
      }
      continue;
    }
    final s = raw.toString().trim();
    if (s.isNotEmpty) out.add(s);
  }
  return out;
}
