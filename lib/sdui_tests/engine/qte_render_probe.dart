/*
 * ============================================================================
 * File: qte_render_probe.dart
 * 
 * Description:
 * Serves as the UI introspection layer for the Quantum Test Engine. It locates widgets
 * based on diverse targeting strategies (keys, paths, semantic labels) and extracts
 * deep rendering information such as geometry, text content, computed styles, and states
 * (focus, enabled) directly from the underlying Flutter Element and RenderObject tree.
 * 
 * Key Components:
 * - QTEWidgetGeometry: Encapsulates the visual bounds and visibility of a widget.
 * - QTEProbeResult: A comprehensive readout of a widget's properties at a given moment.
 * - QTERenderProbe: The utility class performing the traversal and extraction.
 * 
 * Dependencies/Relationships:
 * Relies on lutter_test (Finders) and interacts with raw Flutter rendering classes
 * (like RenderBox, Element, DecoratedBox).
 * Essential for UI assertions evaluated in qte_assertion.dart.
 * 
 * Notes:
 * Extracting styles (like color and border radius) involves heuristic-based recursive
 * visits to child elements (e.g., unwrapping DecoratedBox or Container). This may
 * need updates if Flutter changes its internal widget composition for these properties.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'qte_schema.dart';

class QTEWidgetGeometry {
  final double width;
  final double height;
  final Offset globalOffset;
  final Rect globalRect;
  final bool isVisible;
  final double opacity;

  const QTEWidgetGeometry({
    required this.width,
    required this.height,
    required this.globalOffset,
    required this.globalRect,
    required this.isVisible,
    this.opacity = 1.0,
  });

  @override
  String toString() =>
      'QTEWidgetGeometry(${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)} '
      'at (${globalOffset.dx.toStringAsFixed(1)},${globalOffset.dy.toStringAsFixed(1)}) '
      'visible=$isVisible opacity=${opacity.toStringAsFixed(2)})';
}

class QTEProbeResult {
  final bool found;
  final QTEWidgetGeometry? geometry;
  final String? textContent;
  final TextStyle? textStyle;
  final Color? color;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? scrollOffset;
  final bool? isEnabled;
  final bool? isFocused;
  final String? error;

  const QTEProbeResult({
    required this.found,
    this.geometry,
    this.textContent,
    this.textStyle,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.scrollOffset,
    this.isEnabled,
    this.isFocused,
    this.error,
  });

  factory QTEProbeResult.notFound(String target) =>
      QTEProbeResult(found: false, error: 'Widget not found: $target');
  factory QTEProbeResult.error(String msg) =>
      QTEProbeResult(found: false, error: msg);
}

// ─────────────────────────────────────────────────────────────────────────────

class QTERenderProbe {
  final WidgetTester tester;

  QTERenderProbe(this.tester);

  // ── Find widget by target spec ─────────────────────────────────────────────
  Finder findByTarget(QTETargetSpec target) {
    Finder f;
    switch (target.by) {
      case QTETargetBy.key:
        f = find.byKey(ValueKey(target.value));
        if (_exists(f)) return f;
        f = find.byKey(Key(target.value));
        if (_exists(f)) return f;
        f = find.byKey(ValueKey('__qte_testId_${target.value}'));
        if (_exists(f)) return f;
        return find.byKey(ValueKey(target.value));

      case QTETargetBy.testId:
        f = find.byKey(ValueKey('__qte_testId_${target.value}'));
        if (_exists(f)) return f;
        f = find.byKey(ValueKey(target.value));
        if (_exists(f)) return f;
        f = find.byKey(Key(target.value));
        if (_exists(f)) return f;
        f = find.bySemanticsLabel(target.value);
        if (_exists(f)) return f;
        f = find.text(target.value);
        if (_exists(f)) return f;
        return find.byKey(ValueKey('__qte_testId_${target.value}'));

      case QTETargetBy.text:
        f = find.text(target.value);
        if (_exists(f)) return f;
        f = find.textContaining(target.value);
        if (_exists(f)) return f;
        f = find.bySemanticsLabel(target.value);
        if (_exists(f)) return f;
        return find.text(target.value);

      case QTETargetBy.type:
        f = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == target.value,
        );
        if (_exists(f)) return f;
        f = find.byWidgetPredicate(
          (w) => w.runtimeType.toString().toLowerCase().contains(target.value.toLowerCase()),
        );
        if (_exists(f)) return f;
        return find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == target.value,
        );

      case QTETargetBy.semanticLabel:
        f = find.bySemanticsLabel(target.value);
        if (_exists(f)) return f;
        return find.bySemanticsLabel(target.value);

      case QTETargetBy.path:
        final parts = target.value.split('.');
        Finder current = findByTarget(QTETargetSpec(by: QTETargetBy.key, value: parts.first));
        for (final part in parts.skip(1)) {
          final nextKey = findByTarget(QTETargetSpec(by: QTETargetBy.key, value: part));
          current = find.descendant(of: current, matching: nextKey);
        }
        return current;
    }
  }

  // ── Full probe ─────────────────────────────────────────────────────────────
  QTEProbeResult probe(QTETargetSpec target) {
    try {
      final finder = findByTarget(target);
      if (!_exists(finder)) return QTEProbeResult.notFound('${target.by.name}="${target.value}"');

      final element = tester.element(finder.first);
      final renderObj = element.renderObject;

      QTEWidgetGeometry? geometry;
      if (renderObj is RenderBox) {
        final size = renderObj.size;
        final globalPos = renderObj.localToGlobal(Offset.zero);
        final rect = globalPos & size;
        final viewportRect = Rect.fromLTWH(0, 0,
            tester.binding.renderViews.first.size.width,
            tester.binding.renderViews.first.size.height);
        final isVisible = rect.overlaps(viewportRect);
        geometry = QTEWidgetGeometry(
          width: size.width,
          height: size.height,
          globalOffset: globalPos,
          globalRect: rect,
          isVisible: isVisible,
          opacity: _readOpacity(element),
        );
      }

      return QTEProbeResult(
        found: true,
        geometry: geometry,
        textContent: _readText(element),
        textStyle: _readTextStyle(element),
        color: _readColor(element),
        backgroundColor: _readBackgroundColor(element),
        borderRadius: _readBorderRadius(element),
        scrollOffset: _readScrollOffset(element),
        isEnabled: _readEnabled(element),
        isFocused: _readFocused(element),
      );
    } catch (e) {
      return QTEProbeResult.error(e.toString());
    }
  }

  // ── Existence check ────────────────────────────────────────────────────────
  bool exists(QTETargetSpec target) => _exists(findByTarget(target));
  bool _exists(Finder f) {
    try { return tester.any(f); } catch (_) { return false; }
  }

  // ── Count ─────────────────────────────────────────────────────────────────
  int count(QTETargetSpec target) {
    try { return tester.widgetList(findByTarget(target)).length; } catch (_) { return 0; }
  }

  // ── Text extraction ───────────────────────────────────────────────────────
  String? _readText(Element el) {
    String? found;
    void visit(Element e) {
      final w = e.widget;
      if (w is Text && found == null) { found = w.data ?? w.textSpan?.toPlainText(); }
      if (w is RichText && found == null) { found = w.text.toPlainText(); }
      if (w is EditableText && found == null) { found = w.controller.text; }
      e.visitChildren(visit);
    }
    visit(el);
    return found;
  }

  // ── Text style extraction ─────────────────────────────────────────────────
  TextStyle? _readTextStyle(Element el) {
    TextStyle? found;
    void visit(Element e) {
      final w = e.widget;
      if (w is Text && found == null) { found = w.style; }
      if (w is DefaultTextStyle && found == null) { found = w.style; }
      e.visitChildren(visit);
    }
    visit(el);
    return found;
  }

  // ── Color extraction via BoxDecoration ────────────────────────────────────
  Color? _readColor(Element el) {
    Color? found;
    void visit(Element e) {
      final w = e.widget;
      if (w is DecoratedBox && found == null) {
        final dec = w.decoration;
        if (dec is BoxDecoration) found = dec.color;
      }
      if (w is ColoredBox && found == null) { found = w.color; }
      if (w is Container && found == null) {
        final dec = w.decoration;
        if (dec is BoxDecoration) found = dec.color;
        found ??= w.color;
      }
      e.visitChildren(visit);
    }
    visit(el);
    return found;
  }

  Color? _readBackgroundColor(Element el) {
    // Alias — try Material first then fall back to _readColor
    Color? found;
    void visit(Element e) {
      final w = e.widget;
      if (w is Material && found == null) { found = w.color; }
      if (w is Scaffold && found == null) { found = w.backgroundColor; }
      e.visitChildren(visit);
    }
    visit(el);
    return found ?? _readColor(el);
  }

  // ── Border radius ─────────────────────────────────────────────────────────
  double? _readBorderRadius(Element el) {
    double? found;
    void visit(Element e) {
      final w = e.widget;
      if (w is DecoratedBox && found == null) {
        final dec = w.decoration;
        if (dec is BoxDecoration) {
          final br = dec.borderRadius;
          if (br is BorderRadius) {
            found = br.topLeft.x;
          }
        }
      }
      if (w is ClipRRect && found == null) {
        final br = w.borderRadius;
        if (br is BorderRadius) found = br.topLeft.x;
      }
      e.visitChildren(visit);
    }
    visit(el);
    return found;
  }

  // ── Opacity ───────────────────────────────────────────────────────────────
  double _readOpacity(Element el) {
    double opacity = 1.0;
    void visit(Element e) {
      final w = e.widget;
      if (w is Opacity) { opacity *= w.opacity; }
      if (w is AnimatedOpacity) { opacity *= w.opacity; }
      e.visitChildren(visit);
    }
    visit(el);
    return opacity;
  }

  // ── Scroll offset ─────────────────────────────────────────────────────────
  double? _readScrollOffset(Element el) {
    double? found;
    void visit(Element e) {
      if (e is StatefulElement) {
        final state = e.state;
        if (state is ScrollableState && found == null) {
          found = state.position.pixels;
        }
      }
      e.visitChildren(visit);
    }
    visit(el);
    return found;
  }

  // ── Enabled state ─────────────────────────────────────────────────────────
  bool? _readEnabled(Element el) {
    bool? found;
    void visit(Element e) {
      final w = e.widget;
      if (w is IgnorePointer && found == null) found = !w.ignoring;
      if (w is AbsorbPointer && found == null) found = !w.absorbing;
      e.visitChildren(visit);
    }
    visit(el);
    return found;
  }

  // ── Focus state ───────────────────────────────────────────────────────────
  bool? _readFocused(Element el) {
    bool? found;
    void visit(Element e) {
      if (e is StatefulElement) {
        if (found == null) {
          try {
            final focus = Focus.of(e);
            found = focus.hasFocus;
          } catch (_) {}
        }
      }
      e.visitChildren(visit);
    }
    visit(el);
    return found;
  }

  // ── Pixel color sampling (for precise color testing) ──────────────────────
  Future<Color?> samplePixelAt(Offset globalPos) async {
    // takeScreenshot is not supported in basic widget tests without RepaintBoundary.
    return null;
  }

  // ── Color string to Flutter Color ─────────────────────────────────────────
  static Color? parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'transparent') return Colors.transparent;
    String s = raw.trim();
    if (s.startsWith('#')) {
      s = s.substring(1);
      if (s.length == 3) s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
      if (s.length == 6) s = 'FF$s';
      if (s.length == 8) {
        try { return Color(int.parse(s, radix: 16)); } catch (_) {}
      }
    }
    if (s.startsWith('rgba(')) {
      final inner = s.substring(5, s.length - 1);
      final parts = inner.split(',').map((p) => p.trim()).toList();
      if (parts.length == 4) {
        try {
          final r = int.parse(parts[0]);
          final g = int.parse(parts[1]);
          final b = int.parse(parts[2]);
          final a = (double.parse(parts[3]) * 255).round();
          return Color.fromARGB(a, r, g, b);
        } catch (_) {}
      }
    }
    return null;
  }

  // ── Color comparison with tolerance ───────────────────────────────────────
  static bool colorsMatch(Color a, Color b, {int tolerance = 5}) {
    return ((a.r * 255.0).round() - (b.r * 255.0).round()).abs() <= tolerance &&
        ((a.g * 255.0).round() - (b.g * 255.0).round()).abs() <= tolerance &&
        ((a.b * 255.0).round() - (b.b * 255.0).round()).abs() <= tolerance &&
        ((a.a * 255.0).round() - (b.a * 255.0).round()).abs() <= tolerance;
  }
}
