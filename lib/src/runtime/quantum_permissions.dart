/*
 * ============================================================================
 * File: quantum_permissions.dart
 * 
 * Description:
 * A comprehensive, declarative permissions and access control engine for Quantum. 
 * It evaluates complex JSON/Map-based rules against a unified context (containing 
 * session data, roles, claims, time windows, and feature flags) to yield 
 * deterministic allow/deny decisions.
 * 
 * Key Components:
 * - QuantumPermissionEngine: Singleton engine evaluating rules and caching decisions.
 * - QuantumPermissionContext: The unified context object aggregating user/env/data state.
 * - QuantumPermissionDecision: The immutable result of an evaluation (allowed, reason).
 * 
 * Dependencies/Relationships:
 * Relies on SessionContext from network modules. Used throughout the framework 
 * to gate actions, UI visibility, and data access.
 * 
 * Notes:
 * Supports rich logic operators (ll, ny, 
ot), time-based constraints, 
 * regex matching, and nested role/claim checks. Highly optimized with a cache.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// quantum_permissions.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:quantum_layout/src/platform/network/main.dart';

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

  void registerAll(Map<String, dynamic> rules) {
    _rules.addAll(rules);
  }

  dynamic resolve(String name) => _rules[name];
  bool contains(String name) => _rules.containsKey(name);
  dynamic remove(String name) => _rules.remove(name);
  Iterable<String> get names => _rules.keys;
  Map<String, dynamic> snapshot() => Map<String, dynamic>.unmodifiable(_rules);
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
      if (trimmed.isEmpty) {
        return const QuantumPermissionDecision.allow('empty rule');
      }
      if (trimmed == 'true') {
        return const QuantumPermissionDecision.allow('literal true');
      }
      if (trimmed == 'false') {
        return const QuantumPermissionDecision.deny('literal false');
      }
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
    if (atom.isEmpty) {
      return const QuantumPermissionDecision.allow('empty atom');
    }

    if (atom.containsKey('role')) return _evaluateRole(atom['role'], context);
    if (atom.containsKey('roles')) return _evaluateRole(atom['roles'], context);
    if (atom.containsKey('permission')) {
      return _evaluatePermission(atom['permission'], context);
    }
    if (atom.containsKey('permissions')) {
      return _evaluatePermission(atom['permissions'], context);
    }
    if (atom.containsKey('feature')) {
      return _evaluateFeature(atom['feature'], context);
    }
    if (atom.containsKey('features')) {
      return _evaluateFeature(atom['features'], context);
    }
    if (atom.containsKey('subscription')) {
      return _evaluateSubscription(atom['subscription'], context);
    }
    if (atom.containsKey('subscriptions')) {
      return _evaluateSubscription(atom['subscriptions'], context);
    }
    if (atom.containsKey('claim') || atom.containsKey('claims')) {
      return _evaluateClaim(atom['claim'] ?? atom['claims'], context);
    }
    if (atom.containsKey('data') ||
        atom.containsKey('field') ||
        atom.containsKey('fields')) {
      return _evaluateData(
          atom['data'] ?? atom['field'] ?? atom['fields'], context);
    }
    if (atom.containsKey('op') || atom.containsKey('operation')) {
      return _evaluateOperation(atom['op'] ?? atom['operation'], context);
    }
    if (atom.containsKey('resource') ||
        atom.containsKey('scope') ||
        atom.containsKey('schema')) {
      return _evaluateScope(
          atom.containsKey('resource')
              ? 'resource'
              : atom.containsKey('scope')
                  ? 'scope'
                  : 'schema',
          atom['resource'] ?? atom['scope'] ?? atom['schema'],
          context);
    }
    if (atom.containsKey('time') ||
        atom.containsKey('clock') ||
        atom.containsKey('schedule')) {
      return _evaluateTime(
          atom['time'] ?? atom['clock'] ?? atom['schedule'], context);
    }
    if (atom.containsKey('custom')) {
      return _evaluateCustom(atom['custom'], context, meta: meta);
    }
    if (atom.containsKey('rule')) {
      return evaluate(atom['rule'], context, meta: meta);
    }

    return _evaluateEquality(atom, context);
  }

  QuantumPermissionDecision _evaluateRole(
      dynamic raw, QuantumPermissionContext context) {
    final values = _toStringList(raw);
    if (values.isEmpty) {
      return const QuantumPermissionDecision.allow('no role constraint');
    }
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
    if (values.isEmpty) {
      return const QuantumPermissionDecision.allow('no permission constraint');
    }
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
    if (values.isEmpty) {
      return const QuantumPermissionDecision.allow('no feature constraint');
    }
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
    if (values.isEmpty) {
      return const QuantumPermissionDecision.allow(
          'no subscription constraint');
    }
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
    if (values.isEmpty) {
      return const QuantumPermissionDecision.allow('no operation constraint');
    }
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
    if (values.isEmpty) {
      return const QuantumPermissionDecision.allow('no scope constraint');
    }
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
    if (raw == null) {
      return const QuantumPermissionDecision.allow('no time constraint');
    }
    if (raw is bool) {
      return raw
          ? const QuantumPermissionDecision.allow('time true')
          : const QuantumPermissionDecision.deny('time false');
    }
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

// ════════════════════════════════════════════════════════════════════════════
// APP PERMISSION HUB (in-app capabilities, feature gates, computed logic)
// ════════════════════════════════════════════════════════════════════════════

enum QuantumAppPermissionKind {
  role,
  claim,
  feature,
  subscription,
  computed,
  custom,
}

class QuantumAppPermissionDescriptor {
  final String id;
  final String label;
  final QuantumAppPermissionKind kind;
  final String? description;
  final Set<String> aliases;
  final dynamic rule;
  final Map<String, dynamic> meta;

  const QuantumAppPermissionDescriptor({
    required this.id,
    required this.label,
    this.kind = QuantumAppPermissionKind.custom,
    this.description,
    this.aliases = const <String>{},
    this.rule,
    this.meta = const <String, dynamic>{},
  });

  factory QuantumAppPermissionDescriptor.core({
    required String id,
    required String label,
    required QuantumAppPermissionKind kind,
    String? description,
    Set<String> aliases = const <String>{},
    dynamic rule,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumAppPermissionDescriptor(
      id: id,
      label: label,
      kind: kind,
      description: description,
      aliases: Set<String>.unmodifiable(aliases),
      rule: rule,
      meta: Map<String, dynamic>.unmodifiable(meta),
    );
  }

  QuantumAppPermissionDescriptor copyWith({
    String? id,
    String? label,
    QuantumAppPermissionKind? kind,
    String? description,
    Set<String>? aliases,
    dynamic rule,
    Map<String, dynamic>? meta,
  }) {
    return QuantumAppPermissionDescriptor(
      id: id ?? this.id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      description: description ?? this.description,
      aliases: aliases ?? this.aliases,
      rule: rule ?? this.rule,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'kind': kind.name,
        'description': description,
        'aliases': aliases.toList(growable: false),
        'rule': rule is Function ? 'computed' : rule,
        'meta': meta,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuantumAppPermissionDescriptor && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class QuantumAppPermissionCenter {
  static final QuantumAppPermissionCenter instance =
      QuantumAppPermissionCenter._();

  QuantumAppPermissionCenter._() {
    registerCatalog(QuantumAppPermissionCatalog.core());
  }

  static const int _cacheLimit = 512;
  final Map<String, QuantumAppPermissionDescriptor> _descriptors =
      <String, QuantumAppPermissionDescriptor>{};
  final Map<String, String> _aliases = <String, String>{};
  final LinkedHashMap<String, QuantumPermissionDecision> _cache =
      LinkedHashMap<String, QuantumPermissionDecision>();

  Iterable<QuantumAppPermissionDescriptor> get descriptors =>
      List<QuantumAppPermissionDescriptor>.unmodifiable(_descriptors.values);

  bool contains(String permissionId) => _resolveId(permissionId) != null;

  QuantumAppPermissionDescriptor? descriptor(String permissionId) {
    final id = _resolveId(permissionId);
    return id == null ? null : _descriptors[id];
  }

  void registerCatalog(Iterable<QuantumAppPermissionDescriptor> catalog) {
    for (final descriptor in catalog) {
      registerPermission(descriptor);
    }
  }

  void registerPermission(
    QuantumAppPermissionDescriptor descriptor, {
    dynamic rule,
    bool overwrite = true,
  }) {
    final existingId = _resolveId(descriptor.id);
    if (existingId != null && !overwrite) {
      return;
    }

    final previous = _descriptors[descriptor.id];
    if (previous != null) {
      for (final alias in previous.aliases) {
        _aliases.remove(alias);
      }
    }

    final resolvedRule =
        rule ?? descriptor.rule ?? <String, dynamic>{'allow': true};
    _descriptors[descriptor.id] = descriptor.copyWith(rule: resolvedRule);
    _aliases[descriptor.id] = descriptor.id;
    for (final alias in descriptor.aliases) {
      _aliases[alias] = descriptor.id;
    }
    _cache.clear();
  }

  void registerRule(
    String permissionId,
    dynamic rule, {
    QuantumAppPermissionDescriptor? descriptor,
  }) {
    if (descriptor != null) {
      registerPermission(descriptor, rule: rule);
      return;
    }
    final id = _resolveId(permissionId) ?? permissionId;
    final current = _descriptors[id];
    if (current == null) {
      _aliases[id] = id;
      _descriptors[id] = QuantumAppPermissionDescriptor.core(
        id: id,
        label: id,
        kind: QuantumAppPermissionKind.computed,
        rule: rule,
      );
    } else {
      _descriptors[id] = current.copyWith(rule: rule);
    }
    _cache.clear();
  }

  bool removePermission(String permissionId) {
    final id = _resolveId(permissionId);
    if (id == null) return false;

    final descriptor = _descriptors.remove(id);
    if (descriptor != null) {
      for (final alias in descriptor.aliases) {
        _aliases.remove(alias);
      }
    }
    _aliases.remove(id);
    _cache.clear();
    return true;
  }

  void clear() {
    _descriptors.clear();
    _aliases.clear();
    _cache.clear();
  }

  QuantumPermissionDecision evaluate(
    String permissionId,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    final descriptor = _requireDescriptor(permissionId);
    return evaluateRule(
      descriptor.rule ?? descriptor.meta['rule'],
      context,
      meta: <String, dynamic>{
        ...meta,
        'appPermissionId': descriptor.id,
        'appPermissionKind': descriptor.kind.name,
      },
    );
  }

  QuantumPermissionDecision evaluateRule(
    dynamic rule,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    final dynamic resolved = _resolveRule(rule);
    final cacheKey = _cacheKey(resolved, context, meta);
    final cached = _cache.remove(cacheKey);
    if (cached != null) {
      _cache[cacheKey] = cached;
      return cached;
    }

    QuantumPermissionDecision decision;
    if (resolved is String && contains(resolved)) {
      decision = evaluate(resolved, context, meta: meta);
    } else {
      decision = QuantumPermissionEngine.instance.evaluate(
        resolved,
        context,
        meta: meta,
      );
    }

    if (_cache.length >= _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = decision;
    return decision;
  }

  bool can(
    dynamic rule,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) =>
      evaluateRule(rule, context, meta: meta).allowed;

  QuantumPermissionDecision require(
    dynamic rule,
    QuantumPermissionContext context, {
    String code = 'app_permission_denied',
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    final decision = evaluateRule(rule, context, meta: meta);
    if (!decision.allowed) {
      throw QuantumPermissionException(code, decision.reason,
          details: decision.meta);
    }
    return decision;
  }

  Future<T> guard<T>(
    dynamic rule,
    QuantumPermissionContext context,
    Future<T> Function() action, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    require(rule, context, meta: meta);
    return action();
  }

  bool isAdmin({
    SessionContext? session,
    Map<String, dynamic> env = const <String, dynamic>{},
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return can(
      'isAdmin',
      QuantumPermissionContext.fromSession(
        session,
        env: env,
        data: data,
        meta: meta,
      ),
      meta: meta,
    );
  }

  bool hasFeature(
    String featureName, {
    SessionContext? session,
    Map<String, dynamic> env = const <String, dynamic>{},
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return can(
      'hasFeature',
      QuantumPermissionContext.fromSession(
        session,
        env: env,
        data: data,
        meta: <String, dynamic>{...meta, 'feature': featureName},
      ),
      meta: <String, dynamic>{...meta, 'feature': featureName},
    );
  }

  QuantumAppPermissionDescriptor _requireDescriptor(String permissionId) {
    final descriptor = this.descriptor(permissionId);
    if (descriptor == null) {
      throw QuantumPermissionException(
        'app_permission_unknown',
        'Unknown app permission: $permissionId',
      );
    }
    return descriptor;
  }

  String? _resolveId(String permissionId) {
    final trimmed = permissionId.trim();
    if (trimmed.isEmpty) return null;
    return _aliases[trimmed] ?? _descriptors[trimmed]?.id;
  }

  dynamic _resolveRule(dynamic rule) {
    if (rule is String) {
      final trimmed = rule.trim();
      final id = _resolveId(
        trimmed.startsWith('@') ? trimmed.substring(1) : trimmed,
      );
      if (id != null && id != trimmed) {
        final descriptor = _descriptors[id];
        if (descriptor != null) {
          return _resolveRule(descriptor.rule ?? descriptor.meta['rule']);
        }
      }
      return rule;
    }
    if (rule is Map) {
      return Map<String, dynamic>.from(rule);
    }
    if (rule is List) {
      return List<dynamic>.from(rule);
    }
    return rule;
  }

  String _cacheKey(
    dynamic rule,
    QuantumPermissionContext context,
    Map<String, dynamic> meta,
  ) {
    return _appStableStringify(<String, dynamic>{
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
}

class QuantumAppPermissionCatalog {
  static Iterable<QuantumAppPermissionDescriptor> core() =>
      <QuantumAppPermissionDescriptor>[
        QuantumAppPermissionDescriptor.core(
          id: 'isAdmin',
          label: 'Administrator',
          kind: QuantumAppPermissionKind.computed,
          description:
              'Checks whether the current session is an administrator or elevated account.',
          aliases: <String>{'admin', 'is_admin'},
          rule: <String, dynamic>{
            'any': <dynamic>[
              <String, dynamic>{
                'claim': <String, dynamic>{'isAdmin': true}
              },
              <String, dynamic>{
                'role': <String>['admin', 'owner', 'superadmin']
              },
            ],
          },
        ),
        QuantumAppPermissionDescriptor.core(
          id: 'hasFeature',
          label: 'Feature Gate',
          kind: QuantumAppPermissionKind.feature,
          description:
              'Checks whether a named feature is enabled for the current session.',
          aliases: <String>{'featureGate', 'feature_enabled'},
          rule: (QuantumPermissionContext context, Map<String, dynamic> meta) {
            final featureName =
                (meta['feature'] ?? context.feature)?.toString() ?? '';
            return featureName.isNotEmpty && context.hasFeature(featureName);
          },
        ),
        QuantumAppPermissionDescriptor.core(
          id: 'hasSubscription',
          label: 'Subscription Gate',
          kind: QuantumAppPermissionKind.subscription,
          description:
              'Checks whether a subscription or plan requirement is satisfied.',
          aliases: <String>{'planGate', 'subscriptionGate'},
          rule: (QuantumPermissionContext context, Map<String, dynamic> meta) {
            final value =
                (meta['subscription'] ?? context.claim('plan'))?.toString() ??
                    '';
            return value.isNotEmpty && context.hasSubscription(value);
          },
        ),
      ];
}

// ════════════════════════════════════════════════════════════════════════════
// CENTRAL PERMISSION HUB
// ════════════════════════════════════════════════════════════════════════════

enum QuantumPermissionState {
  unknown,
  granted,
  limited,
  denied,
  restricted,
  permanentlyDenied,
  unavailable,
}

extension QuantumPermissionStateX on QuantumPermissionState {
  bool get isGranted =>
      this == QuantumPermissionState.granted ||
      this == QuantumPermissionState.limited;

  bool get isDenied =>
      this == QuantumPermissionState.denied ||
      this == QuantumPermissionState.restricted ||
      this == QuantumPermissionState.permanentlyDenied;

  bool get canAskAgain =>
      this != QuantumPermissionState.permanentlyDenied &&
      this != QuantumPermissionState.unavailable;
}

enum QuantumPermissionKind {
  camera,
  microphone,
  location,
  contacts,
  calendar,
  photos,
  notifications,
  phone,
  files,
  media,
  sensors,
  network,
  biometric,
  custom,
}

class QuantumPermissionDescriptor {
  final String id;
  final String label;
  final QuantumPermissionKind kind;
  final String? description;
  final Set<String> aliases;
  final Map<String, String> nativeIds;
  final dynamic defaultRule;
  final Map<String, dynamic> meta;

  const QuantumPermissionDescriptor({
    required this.id,
    required this.label,
    this.kind = QuantumPermissionKind.custom,
    this.description,
    this.aliases = const <String>{},
    this.nativeIds = const <String, String>{},
    this.defaultRule,
    this.meta = const <String, dynamic>{},
  });

  factory QuantumPermissionDescriptor.core({
    required String id,
    required String label,
    required QuantumPermissionKind kind,
    String? description,
    Set<String> aliases = const <String>{},
    Map<String, String> nativeIds = const <String, String>{},
    dynamic defaultRule,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumPermissionDescriptor(
      id: id,
      label: label,
      kind: kind,
      description: description,
      aliases: Set<String>.unmodifiable(aliases),
      nativeIds: Map<String, String>.unmodifiable(nativeIds),
      defaultRule: defaultRule,
      meta: Map<String, dynamic>.unmodifiable(meta),
    );
  }

  QuantumPermissionDescriptor copyWith({
    String? id,
    String? label,
    QuantumPermissionKind? kind,
    String? description,
    Set<String>? aliases,
    Map<String, String>? nativeIds,
    dynamic defaultRule,
    Map<String, dynamic>? meta,
  }) {
    return QuantumPermissionDescriptor(
      id: id ?? this.id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      description: description ?? this.description,
      aliases: aliases ?? this.aliases,
      nativeIds: nativeIds ?? this.nativeIds,
      defaultRule: defaultRule ?? this.defaultRule,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'kind': kind.name,
        'description': description,
        'aliases': aliases.toList(growable: false),
        'nativeIds': nativeIds,
        'defaultRule': defaultRule,
        'meta': meta,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuantumPermissionDescriptor && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class QuantumPermissionSnapshot {
  final String permissionId;
  final QuantumPermissionState state;
  final String source;
  final String reason;
  final DateTime updatedAt;
  final Map<String, dynamic> meta;

  // Removed 'const' keyword
  QuantumPermissionSnapshot({
    required this.permissionId,
    required this.state,
    required this.source,
    required this.reason,
    required this.updatedAt,
    this.meta = const <String, dynamic>{},
  });

  // Removed 'const' keyword
  QuantumPermissionSnapshot.unknown(
    String permissionId, {
    String source = 'unknown',
    String reason = 'permission status is unknown',
    DateTime? updatedAt,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) : this(
          permissionId: permissionId,
          state: QuantumPermissionState.unknown,
          source: source,
          reason: reason,
          updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          meta: meta,
        );

  // Removed 'const' keyword
  QuantumPermissionSnapshot.granted(
    String permissionId, {
    String source = 'native',
    String reason = 'granted',
    DateTime? updatedAt,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) : this(
          permissionId: permissionId,
          state: QuantumPermissionState.granted,
          source: source,
          reason: reason,
          updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          meta: meta,
        );

  // Removed 'const' keyword
  QuantumPermissionSnapshot.limited(
    String permissionId, {
    String source = 'native',
    String reason = 'limited',
    DateTime? updatedAt,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) : this(
          permissionId: permissionId,
          state: QuantumPermissionState.limited,
          source: source,
          reason: reason,
          updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          meta: meta,
        );

  // Removed 'const' keyword
  QuantumPermissionSnapshot.denied(
    String permissionId, {
    String source = 'native',
    String reason = 'denied',
    DateTime? updatedAt,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) : this(
          permissionId: permissionId,
          state: QuantumPermissionState.denied,
          source: source,
          reason: reason,
          updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          meta: meta,
        );

  // Removed 'const' keyword
  QuantumPermissionSnapshot.restricted(
    String permissionId, {
    String source = 'native',
    String reason = 'restricted',
    DateTime? updatedAt,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) : this(
          permissionId: permissionId,
          state: QuantumPermissionState.restricted,
          source: source,
          reason: reason,
          updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          meta: meta,
        );

  // Removed 'const' keyword
  QuantumPermissionSnapshot.permanentlyDenied(
    String permissionId, {
    String source = 'native',
    String reason = 'permanently denied',
    DateTime? updatedAt,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) : this(
          permissionId: permissionId,
          state: QuantumPermissionState.permanentlyDenied,
          source: source,
          reason: reason,
          updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          meta: meta,
        );

  // Removed 'const' keyword
  QuantumPermissionSnapshot.unavailable(
    String permissionId, {
    String source = 'native',
    String reason = 'unavailable',
    DateTime? updatedAt,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) : this(
          permissionId: permissionId,
          state: QuantumPermissionState.unavailable,
          source: source,
          reason: reason,
          updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          meta: meta,
        );

  bool get granted => state.isGranted;
  bool get denied => state.isDenied;
  bool get canAskAgain => state.canAskAgain;

  QuantumPermissionSnapshot copyWith({
    QuantumPermissionState? state,
    String? source,
    String? reason,
    DateTime? updatedAt,
    Map<String, dynamic>? meta,
  }) {
    return QuantumPermissionSnapshot(
      permissionId: permissionId,
      state: state ?? this.state,
      source: source ?? this.source,
      reason: reason ?? this.reason,
      updatedAt: updatedAt ?? this.updatedAt,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'permissionId': permissionId,
        'state': state.name,
        'source': source,
        'reason': reason,
        'updatedAt': updatedAt.toIso8601String(),
        'meta': meta,
        'granted': granted,
        'denied': denied,
        'canAskAgain': canAskAgain,
      };

  factory QuantumPermissionSnapshot.fromJson(Map<String, dynamic> json) {
    return QuantumPermissionSnapshot(
      permissionId:
          json['permissionId']?.toString() ?? json['id']?.toString() ?? '',
      state: _parsePermissionState(json['state']?.toString() ??
          json['status']?.toString() ??
          (json['granted'] == true ? 'granted' : 'unknown')),
      source: json['source']?.toString() ?? 'native',
      reason: json['reason']?.toString() ?? 'permission snapshot',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuantumPermissionSnapshot &&
          other.permissionId == permissionId &&
          other.state == state &&
          other.source == source &&
          other.reason == reason &&
          other.updatedAt == updatedAt &&
          _mapEquals(other.meta, meta));

  @override
  int get hashCode => Object.hash(
      permissionId, state, source, reason, updatedAt, _mapHash(meta));
}

abstract class QuantumPermissionSource {
  Future<QuantumPermissionSnapshot> check(
    QuantumPermissionDescriptor descriptor, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  });

  Future<QuantumPermissionSnapshot> request(
    QuantumPermissionDescriptor descriptor, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  });

  Future<bool> openSettings(
    QuantumPermissionDescriptor descriptor, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  });
}

class QuantumPermissionMemorySource implements QuantumPermissionSource {
  final Map<String, QuantumPermissionSnapshot> _snapshots =
      <String, QuantumPermissionSnapshot>{};

  void seed(QuantumPermissionSnapshot snapshot) {
    _snapshots[snapshot.permissionId] = snapshot;
  }

  void seedState(
    String permissionId, {
    QuantumPermissionState state = QuantumPermissionState.granted,
    String source = 'memory',
    String reason = 'seeded',
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    _snapshots[permissionId] = QuantumPermissionSnapshot(
      permissionId: permissionId,
      state: state,
      source: source,
      reason: reason,
      updatedAt: DateTime.now(),
      meta: meta,
    );
  }

  void clear([String? permissionId]) {
    if (permissionId == null) {
      _snapshots.clear();
      return;
    }
    _snapshots.remove(permissionId);
  }

  @override
  Future<QuantumPermissionSnapshot> check(
    QuantumPermissionDescriptor descriptor, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    return _snapshots[descriptor.id] ??
        QuantumPermissionSnapshot.unknown(
          descriptor.id,
          source: 'memory',
          meta: meta,
        );
  }

  @override
  Future<QuantumPermissionSnapshot> request(
    QuantumPermissionDescriptor descriptor, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    final current = _snapshots[descriptor.id];
    if (current != null) return current;
    return QuantumPermissionSnapshot.unavailable(
      descriptor.id,
      source: 'memory',
      reason: 'no native permission source configured',
      meta: meta,
    );
  }

  @override
  Future<bool> openSettings(
    QuantumPermissionDescriptor descriptor, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    return false;
  }
}

class QuantumPermissionNativeSource implements QuantumPermissionSource {
  QuantumPermissionNativeSource({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('quantum_permissions');

  final MethodChannel _channel;

  @override
  Future<QuantumPermissionSnapshot> check(
    QuantumPermissionDescriptor descriptor, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    return _invoke('check', descriptor, context: context, meta: meta);
  }

  @override
  Future<QuantumPermissionSnapshot> request(
    QuantumPermissionDescriptor descriptor, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    return _invoke('request', descriptor, context: context, meta: meta);
  }

  @override
  Future<bool> openSettings(
    QuantumPermissionDescriptor descriptor, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        'openSettings',
        <String, dynamic>{
          'permissionId': descriptor.id,
          'meta': meta,
        },
      );
      return raw == true;
    } on MissingPluginException {
      return false;
    }
  }

  Future<QuantumPermissionSnapshot> _invoke(
    String method,
    QuantumPermissionDescriptor descriptor, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        method,
        <String, dynamic>{
          'permissionId': descriptor.id,
          'descriptor': descriptor.toJson(),
          'context': context == null ? null : _contextToJson(context),
          'meta': meta,
        },
      );
      if (raw is Map) {
        return QuantumPermissionSnapshot.fromJson(
            Map<String, dynamic>.from(raw));
      }
      if (raw is bool) {
        return raw
            ? QuantumPermissionSnapshot.granted(
                descriptor.id,
                source: 'native',
                meta: meta,
              )
            : QuantumPermissionSnapshot.denied(
                descriptor.id,
                source: 'native',
                meta: meta,
              );
      }
      return QuantumPermissionSnapshot.unavailable(
        descriptor.id,
        source: 'native',
        reason: 'native bridge returned unsupported data',
        meta: meta,
      );
    } on MissingPluginException {
      return QuantumPermissionSnapshot.unavailable(
        descriptor.id,
        source: 'native',
        reason: 'native bridge not installed',
        meta: meta,
      );
    } on PlatformException catch (e) {
      return QuantumPermissionSnapshot.denied(
        descriptor.id,
        source: 'native',
        reason: e.message ?? e.code,
        meta: <String, dynamic>{
          ...meta,
          'code': e.code,
          'details': e.details,
        },
      );
    }
  }
}

class QuantumPermissionCenter {
  static final QuantumPermissionCenter instance = QuantumPermissionCenter._();

  QuantumPermissionCenter._() {
    registerCatalog(QuantumPermissionCatalog.core());
  }

  static const int _snapshotLimit = 128;
  static const Duration _cacheDuration = Duration(milliseconds: 750);

  final QuantumPermissionNativeSource _nativeSource =
      QuantumPermissionNativeSource();
  QuantumPermissionSource _source = QuantumPermissionMemorySource();

  final Map<String, QuantumPermissionDescriptor> _descriptors =
      <String, QuantumPermissionDescriptor>{};
  final Map<String, String> _aliases = <String, String>{};
  final Map<String, QuantumPermissionSnapshot> _snapshots =
      <String, QuantumPermissionSnapshot>{};
  final Map<String, DateTime> _lastSync = <String, DateTime>{};
  final Map<String, StreamController<QuantumPermissionSnapshot>> _watchers =
      <String, StreamController<QuantumPermissionSnapshot>>{};

  QuantumPermissionSource get source => _source;
  set source(QuantumPermissionSource value) => _source = value;

  Iterable<QuantumPermissionDescriptor> get descriptors =>
      List<QuantumPermissionDescriptor>.unmodifiable(_descriptors.values);

  bool contains(String permissionId) => _resolveId(permissionId) != null;

  QuantumPermissionDescriptor? descriptor(String permissionId) {
    final id = _resolveId(permissionId);
    return id == null ? null : _descriptors[id];
  }

  QuantumPermissionSnapshot? snapshot(String permissionId) {
    final id = _resolveId(permissionId);
    return id == null ? null : _snapshots[id];
  }

  void registerCatalog(Iterable<QuantumPermissionDescriptor> catalog) {
    for (final descriptor in catalog) {
      registerPermission(descriptor);
    }
  }

  void registerPermission(
    QuantumPermissionDescriptor descriptor, {
    dynamic rule,
    bool overwrite = true,
  }) {
    final existingId = _resolveId(descriptor.id);
    if (existingId != null && !overwrite && existingId != descriptor.id) {
      return;
    }

    final resolvedRule = rule ??
        descriptor.defaultRule ??
        <String, dynamic>{'permission': descriptor.id};

    _descriptors[descriptor.id] = descriptor;
    _aliases[descriptor.id] = descriptor.id;
    for (final alias in descriptor.aliases) {
      _aliases[alias] = descriptor.id;
    }
    QuantumPermissionRegistry.instance.register(descriptor.id, resolvedRule);
    for (final alias in descriptor.aliases) {
      QuantumPermissionRegistry.instance.register(alias, resolvedRule);
    }
    _snapshots.remove(descriptor.id);
    _lastSync.remove(descriptor.id);
  }

  void registerRule(
    String permissionId,
    dynamic rule, {
    QuantumPermissionDescriptor? descriptor,
  }) {
    if (descriptor != null) {
      registerPermission(descriptor, rule: rule);
      return;
    }
    final id = _resolveId(permissionId) ?? permissionId;
    QuantumPermissionRegistry.instance.register(id, rule);
    _aliases[id] = id;
  }

  bool removePermission(String permissionId) {
    final id = _resolveId(permissionId);
    if (id == null) return false;

    final descriptor = _descriptors.remove(id);
    if (descriptor != null) {
      QuantumPermissionRegistry.instance.remove(id);
      for (final alias in descriptor.aliases) {
        _aliases.remove(alias);
        QuantumPermissionRegistry.instance.remove(alias);
      }
    }
    _snapshots.remove(id);
    _lastSync.remove(id);
    return true;
  }

  void clear() {
    _descriptors.clear();
    _aliases.clear();
    _snapshots.clear();
    _lastSync.clear();
    QuantumPermissionRegistry.instance.clear();
  }

  QuantumPermissionDecision evaluatePolicy(
    String permissionId,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    final descriptor = this.descriptor(permissionId);
    final dynamic rule = QuantumPermissionRegistry.instance.resolve(
          _resolveId(permissionId) ?? permissionId,
        ) ??
        descriptor?.defaultRule;
    if (rule == null) {
      return const QuantumPermissionDecision.allow('no permission policy');
    }
    return QuantumPermissionEngine.instance.evaluate(rule, context, meta: meta);
  }

  bool allowsPolicy(
    String permissionId,
    QuantumPermissionContext context, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return evaluatePolicy(permissionId, context, meta: meta).allowed;
  }

  Future<QuantumPermissionSnapshot> check(
    String permissionId, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
    bool forceRefresh = false,
  }) async {
    final descriptor = _requireDescriptor(permissionId);
    final now = DateTime.now();
    final cached = _snapshots[descriptor.id];
    if (!forceRefresh &&
        cached != null &&
        now.difference(_lastSync[descriptor.id] ?? cached.updatedAt) <
            _cacheDuration) {
      return cached;
    }

    QuantumPermissionSnapshot snapshot;
    try {
      snapshot = await _nativeSource.check(
        descriptor,
        context: context,
        meta: meta,
      );
      if (snapshot.state == QuantumPermissionState.unavailable) {
        snapshot = await _source.check(
          descriptor,
          context: context,
          meta: meta,
        );
      }
    } catch (_) {
      snapshot = await _source.check(
        descriptor,
        context: context,
        meta: meta,
      );
    }

    final policy = context == null
        ? const QuantumPermissionDecision.allow('no policy context')
        : evaluatePolicy(
            descriptor.id,
            context,
            meta: meta,
          );

    if (!policy.allowed) {
      snapshot = QuantumPermissionSnapshot.denied(
        descriptor.id,
        source: 'policy',
        reason: policy.reason,
        updatedAt: now,
        meta: <String, dynamic>{
          ...snapshot.meta,
          ...policy.meta,
          'matched': policy.matched,
        },
      );
    } else if (snapshot.state == QuantumPermissionState.unknown &&
        descriptor.defaultRule == null) {
      snapshot = snapshot.copyWith(
        updatedAt: now,
        meta: <String, dynamic>{
          ...snapshot.meta,
          'policy': policy.toJson(),
        },
      );
    }

    _storeSnapshot(snapshot, now);
    return snapshot;
  }

  Future<QuantumPermissionSnapshot> request(
    String permissionId, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    final descriptor = _requireDescriptor(permissionId);
    final snapshot = await _nativeSource.request(
      descriptor,
      context: context,
      meta: meta,
    );
    final policy = context == null
        ? const QuantumPermissionDecision.allow('no policy context')
        : evaluatePolicy(
            descriptor.id,
            context,
            meta: meta,
          );
    final resolved = policy.allowed
        ? snapshot
        : QuantumPermissionSnapshot.denied(
            descriptor.id,
            source: 'policy',
            reason: policy.reason,
            updatedAt: DateTime.now(),
            meta: <String, dynamic>{
              ...snapshot.meta,
              ...policy.meta,
              'matched': policy.matched,
            },
          );
    _storeSnapshot(resolved, DateTime.now());
    return resolved;
  }

  Future<bool> openSettings(
    String permissionId, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    final descriptor = _requireDescriptor(permissionId);
    return _nativeSource.openSettings(descriptor, meta: meta);
  }

  Future<Map<String, QuantumPermissionSnapshot>> sync({
    Iterable<String>? permissionIds,
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    final ids = (permissionIds == null || permissionIds.isEmpty)
        ? _descriptors.keys
        : permissionIds.map((id) => _resolveId(id) ?? id);
    final results = <String, QuantumPermissionSnapshot>{};
    for (final id in ids) {
      final snapshot = await check(
        id,
        context: context,
        meta: meta,
        forceRefresh: true,
      );
      results[id] = snapshot;
    }
    return results;
  }

  Stream<QuantumPermissionSnapshot> watch(String permissionId) async* {
    final descriptor = _requireDescriptor(permissionId);
    final cached = _snapshots[descriptor.id];
    if (cached != null) yield cached;
    final controller = _watchers.putIfAbsent(
      descriptor.id,
      () => StreamController<QuantumPermissionSnapshot>.broadcast(sync: true),
    );
    yield* controller.stream;
  }

  void forget(String permissionId) {
    final id = _resolveId(permissionId);
    if (id == null) return;
    _snapshots.remove(id);
    _lastSync.remove(id);
  }

  Future<T> guarded<T>(
    String permissionId,
    QuantumPermissionContext context,
    Future<T> Function() action, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) async {
    final permissionSnapshot = await check(
      permissionId,
      context: context,
      meta: meta,
    );
    if (!permissionSnapshot.granted) {
      throw QuantumPermissionException(
        'permission_denied',
        permissionSnapshot.reason,
        details: permissionSnapshot.toJson(),
      );
    }
    return action();
  }

  QuantumPermissionDescriptor _requireDescriptor(String permissionId) {
    final descriptor = this.descriptor(permissionId);
    if (descriptor == null) {
      throw QuantumPermissionException(
        'permission_unknown',
        'Unknown permission: $permissionId',
      );
    }
    return descriptor;
  }

  String? _resolveId(String permissionId) {
    final trimmed = permissionId.trim();
    if (trimmed.isEmpty) return null;
    return _aliases[trimmed] ?? _descriptors[trimmed]?.id;
  }

  void _storeSnapshot(
    QuantumPermissionSnapshot snapshot,
    DateTime now,
  ) {
    if (_snapshots.length >= _snapshotLimit &&
        !_snapshots.containsKey(snapshot.permissionId)) {
      _snapshots.remove(_snapshots.keys.first);
    }
    _snapshots[snapshot.permissionId] = snapshot.copyWith(updatedAt: now);
    _lastSync[snapshot.permissionId] = now;
    _watchers[snapshot.permissionId]?.add(_snapshots[snapshot.permissionId]!);
  }
}

class QuantumPermissionCatalog {
  static Iterable<QuantumPermissionDescriptor> core() =>
      <QuantumPermissionDescriptor>[
        QuantumPermissionDescriptor.core(
          id: 'camera',
          label: 'Camera',
          kind: QuantumPermissionKind.camera,
          description: 'Capture photos and video from the device camera.',
          aliases: <String>{'photos.camera', 'media.camera'},
          nativeIds: <String, String>{
            'android': 'android.permission.CAMERA',
            'ios': 'NSCameraUsageDescription',
            'web': 'camera',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'microphone',
          label: 'Microphone',
          kind: QuantumPermissionKind.microphone,
          description: 'Record audio or join voice experiences.',
          aliases: <String>{'audio.recording', 'voice'},
          nativeIds: <String, String>{
            'android': 'android.permission.RECORD_AUDIO',
            'ios': 'NSMicrophoneUsageDescription',
            'web': 'microphone',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'location',
          label: 'Location',
          kind: QuantumPermissionKind.location,
          description: 'Access approximate or precise device location.',
          aliases: <String>{'gps', 'geo'},
          nativeIds: <String, String>{
            'android': 'android.permission.ACCESS_FINE_LOCATION',
            'ios': 'NSLocationWhenInUseUsageDescription',
            'web': 'geolocation',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'contacts',
          label: 'Contacts',
          kind: QuantumPermissionKind.contacts,
          description: 'Read and search the device address book.',
          nativeIds: <String, String>{
            'android': 'android.permission.READ_CONTACTS',
            'ios': 'NSContactsUsageDescription',
            'web': 'contacts',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'calendar',
          label: 'Calendar',
          kind: QuantumPermissionKind.calendar,
          description: 'Read or create calendar events.',
          nativeIds: <String, String>{
            'android': 'android.permission.READ_CALENDAR',
            'ios': 'NSCalendarsUsageDescription',
            'web': 'calendar',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'photos',
          label: 'Photos',
          kind: QuantumPermissionKind.photos,
          description: 'Read media library or photo picker selections.',
          aliases: <String>{'gallery', 'media.photos'},
          nativeIds: <String, String>{
            'android': 'android.permission.READ_MEDIA_IMAGES',
            'ios': 'NSPhotoLibraryUsageDescription',
            'web': 'photos',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'notifications',
          label: 'Notifications',
          kind: QuantumPermissionKind.notifications,
          description: 'Show or manage local and push notifications.',
          aliases: <String>{'push', 'localNotifications'},
          nativeIds: <String, String>{
            'android': 'android.permission.POST_NOTIFICATIONS',
            'ios': 'UNUserNotificationCenter',
            'web': 'notifications',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'phone',
          label: 'Phone',
          kind: QuantumPermissionKind.phone,
          description: 'Access phone state or phone-call related actions.',
          nativeIds: <String, String>{
            'android': 'android.permission.READ_PHONE_STATE',
            'ios': 'CTTelephonyNetworkInfo',
            'web': 'phone',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'files',
          label: 'Files',
          kind: QuantumPermissionKind.files,
          description: 'Read and write local files and document storage.',
          aliases: <String>{'storage', 'filesystem'},
          nativeIds: <String, String>{
            'android': 'android.permission.READ_EXTERNAL_STORAGE',
            'ios': 'UIDocumentPicker',
            'web': 'file-system',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'biometric',
          label: 'Biometric',
          kind: QuantumPermissionKind.biometric,
          description: 'Unlock protected actions using device biometrics.',
          aliases: <String>{'faceId', 'touchId'},
          nativeIds: <String, String>{
            'android': 'android.permission.USE_BIOMETRIC',
            'ios': 'LocalAuthentication',
            'web': 'biometric',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'sensors',
          label: 'Sensors',
          kind: QuantumPermissionKind.sensors,
          description: 'Access accelerometer, motion, and similar sensors.',
          nativeIds: <String, String>{
            'android': 'android.permission.BODY_SENSORS',
            'ios': 'CMMotionActivityManager',
            'web': 'sensors',
          },
        ),
        QuantumPermissionDescriptor.core(
          id: 'network',
          label: 'Network',
          kind: QuantumPermissionKind.network,
          description: 'Use device networking and remote connections.',
          aliases: <String>{'internet', 'remote'},
          nativeIds: <String, String>{
            'android': 'android.permission.INTERNET',
            'ios': 'network',
            'web': 'network',
          },
        ),
      ];
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    final dynamic other = b[entry.key];
    final dynamic value = entry.value;
    if (value is Map && other is Map) {
      if (!_mapEquals(
          Map<String, dynamic>.from(value), Map<String, dynamic>.from(other))) {
        return false;
      }
      continue;
    }
    if (value is List && other is List) {
      if (value.length != other.length) return false;
      for (var i = 0; i < value.length; i++) {
        final dynamic left = value[i];
        final dynamic right = other[i];
        if (left is Map && right is Map) {
          if (!_mapEquals(Map<String, dynamic>.from(left),
              Map<String, dynamic>.from(right))) {
            return false;
          }
        } else if (left != right) {
          return false;
        }
      }
      continue;
    }
    if (value != other) return false;
  }
  return true;
}

int _mapHash(Map<String, dynamic> value) {
  var hash = 0;
  final keys = value.keys.map((e) => e.toString()).toList(growable: false)
    ..sort();
  for (final key in keys) {
    hash = Object.hash(hash, key, value[key]);
  }
  return hash;
}

QuantumPermissionState _parsePermissionState(String raw) {
  switch (raw.toLowerCase()) {
    case 'granted':
    case 'allowed':
    case 'ok':
      return QuantumPermissionState.granted;
    case 'limited':
      return QuantumPermissionState.limited;
    case 'restricted':
      return QuantumPermissionState.restricted;
    case 'permanentlydenied':
    case 'permanent':
    case 'blocked':
      return QuantumPermissionState.permanentlyDenied;
    case 'denied':
    case 'refused':
      return QuantumPermissionState.denied;
    case 'unavailable':
    case 'missing':
      return QuantumPermissionState.unavailable;
    default:
      return QuantumPermissionState.unknown;
  }
}

String _appStableStringify(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((e) => e.toString()).toList(growable: false)
      ..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${_appStableStringify(value[k])}').join(',')}}';
  }
  if (value is List) {
    return '[${value.map(_appStableStringify).join(',')}]';
  }
  return jsonEncode(value);
}

Map<String, dynamic> _contextToJson(QuantumPermissionContext context) {
  return <String, dynamic>{
    'userId': context.userId,
    'scope': context.scope,
    'resource': context.resource,
    'operation': context.operation,
    'feature': context.feature,
    'schema': context.schema,
    'now': context.now.toIso8601String(),
    'env': context.env,
    'data': context.data,
    'meta': context.meta,
    'claims': context.claims,
    'roles': context.roles.toList(growable: false),
    'permissions': context.permissions.toList(growable: false),
    'features': context.features.toList(growable: false),
    'subscriptions': context.subscriptions.toList(growable: false),
  };
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
    return canApp(
      rule,
      env: env,
      data: data,
      scope: scope,
      resource: resource,
      operation: operation,
      feature: feature,
      schema: schema,
      meta: meta,
    );
  }

  bool canApp(
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
    return QuantumAppPermissionCenter.instance.can(
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

  bool isAdminApp({
    Map<String, dynamic> env = const <String, dynamic>{},
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumAppPermissionCenter.instance.isAdmin(
      session: this,
      env: env,
      data: data,
      meta: meta,
    );
  }

  bool hasRoleValue(String role) => roles.contains(role);
  bool hasPermissionValue(String permission) =>
      permissions.contains(permission);
  bool hasFeatureValue(String feature) => features.contains(feature);
  bool hasSubscriptionValue(String subscription) =>
      subscriptions.contains(subscription);

  bool get isAdmin =>
      QuantumAppPermissionCenter.instance.isAdmin(session: this);

  bool canUseFeature(String feature) =>
      QuantumAppPermissionCenter.instance.hasFeature(feature, session: this);

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

  Future<QuantumPermissionSnapshot> askPermission(
    String permissionId, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumPermissionCenter.instance.request(
      permissionId,
      context: context ??
          QuantumPermissionContext.fromSession(
            this,
            meta: meta,
          ),
      meta: meta,
    );
  }

  Future<QuantumPermissionSnapshot> checkPermission(
    String permissionId, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
    bool forceRefresh = false,
  }) {
    return QuantumPermissionCenter.instance.check(
      permissionId,
      context: context ??
          QuantumPermissionContext.fromSession(
            this,
            meta: meta,
          ),
      meta: meta,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, QuantumPermissionSnapshot>> syncPermissions(
    Iterable<String>? permissionIds, {
    QuantumPermissionContext? context,
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumPermissionCenter.instance.sync(
      permissionIds: permissionIds,
      context: context ??
          QuantumPermissionContext.fromSession(
            this,
            meta: meta,
          ),
      meta: meta,
    );
  }

  Future<bool> openPermissionSettings(
    String permissionId, {
    Map<String, dynamic> meta = const <String, dynamic>{},
  }) {
    return QuantumPermissionCenter.instance.openSettings(
      permissionId,
      meta: meta,
    );
  }

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
