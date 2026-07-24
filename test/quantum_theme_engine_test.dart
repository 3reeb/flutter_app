import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Your core framework imports
import 'package:quantum_layout/quantum.dart';

void main() {
  setUp(() {
    QEngine.instance.dispose();
    QEngine.instance.initialize(initialCapacity: 128, ecsCapacity: 128);
  });

  tearDown(() {
    QEngine.instance.dispose();
  });

  group('QThemeDictionary & QThemeGraph Tests', () {
    test('fromJson parses nested groups correctly', () {
      final json = {
        'colors': {
          'primary': '#FF0000',
          'secondary': {'color': '#00FF00'},
          'alias': 'primary',
        },
        'spacing': {
          'sm': 8.0,
          'md': {'number': 16.0},
        },
        'labels': {
          'title': 'Hello',
          'subtitle': {'text': 'World'},
        }
      };

      final dict = QThemeDictionary.fromJson(json);

      expect(dict.values['colors.primary']?.color, 0xFFFF0000);
      expect(dict.values['colors.secondary']?.color, 0xFF00FF00);
      expect(dict.aliases['colors.alias'], 'primary');
      expect(dict.values['spacing.sm']?.number, 8.0);
      expect(dict.values['spacing.md']?.number, 16.0);
      expect(dict.values['labels.title']?.text, 'Hello');
      expect(dict.values['labels.subtitle']?.text, 'World');
    });

    test('QThemeGraph resolves direct values and aliases', () {
      final dict = QThemeDictionary.fromJson({
        'colors': {
          'brand': '#123456',
          'btn-bg': 'colors.brand', // Alias to another key
          'direct-hex': '#AABBCC' // Alias to hex
        },
        'metrics': {'rad': 12.0}
      });

      final graph = QThemeGraph();
      graph.load(dict);

      expect(graph.color('colors.brand'), 0xFF123456);
      expect(graph.color('colors.btn-bg'), 0xFF123456); // Now succeeds
      expect(graph.color('colors.direct-hex'),
          0xFFAABBCC); // Added 'colors.' prefix
      expect(graph.color('missing-key', fallback: 0xFFFFFFFF), 0xFFFFFFFF);

      expect(graph.number('metrics.rad'), 12.0);
      expect(graph.number('missing.rad', fallback: 5.0), 5.0);
    });

    test('QThemeGraph detects and throws on cyclic aliases', () {
      final dict = QThemeDictionary.fromJson({
        'colors': {
          'a': 'colors.b',
          'b': 'colors.c',
          'c': 'colors.a', // Cycle!
        }
      });

      final graph = QThemeGraph();
      // Firing load() forces resolution logic which should instantly catch the cyclic dependency
      expect(() => graph.load(dict), throwsA(isA<StateError>()));
    });
  });

  group('QSimdArena Hardware Tests', () {
    test('Arena allocates and expands correctly', () {
      final arena = QSimdArena(capacity: 2);
      expect(arena.f32.length, 2 * QSimdArena.floatStride);

      arena.allocate(); // id: 1
      arena.allocate(); // id: 2
      final expandedId =
          arena.allocate(); // id: 3 -> triggers automatic expansion

      expect(expandedId, 3);
      expect(arena.f32.length, 4 * QSimdArena.floatStride);
    });

    test('Arena copyFrom replicates memory state accurately', () {
      final source = QSimdArena(capacity: 4);
      final dest = QSimdArena(capacity: 2);

      final id = source.allocate();
      source.f32[id * QSimdArena.floatStride + QF32.width] = 999.0;
      source.c32[id * QSimdArena.colorStride + QC32.background] = 0xFF112233;
      source.flags[id] = QFlags.isFlex;
      source.registerObject("TestObject");

      dest.copyFrom(source);

      expect(dest.f32.length, source.f32.length); // Expanded to match capacity
      expect(dest.f32[id * QSimdArena.floatStride + QF32.width], 999.0);
      expect(
          dest.c32[id * QSimdArena.colorStride + QC32.background], 0xFF112233);
      expect(dest.flags[id], QFlags.isFlex);
      expect(dest.objects[1], "TestObject");
    });
  });

  group('QMorpher Mathematics Tests', () {
    test('lerpFast interpolates floats and colors correctly', () {
      final start = QSimdArena(capacity: 4);
      final end = QSimdArena(capacity: 4);
      final out = QSimdArena(capacity: 4);

      final id = start.allocate();
      end.allocate();
      out.allocate();

      start.f32[id * QSimdArena.floatStride + QF32.width] = 100.0;
      end.f32[id * QSimdArena.floatStride + QF32.width] = 200.0;

      start.c32[id * QSimdArena.colorStride + QC32.background] = 0xFFFF0000;
      end.c32[id * QSimdArena.colorStride + QC32.background] = 0xFF0000FF;

      start.flags[id] = 0;
      end.flags[id] = QFlags.isFlex;

      QMorpher.lerpFast(start, end, 0.5, out);

      expect(out.f32[id * QSimdArena.floatStride + QF32.width], 150.0);
      expect(
          out.c32[id * QSimdArena.colorStride + QC32.background], 0xFF7f007f);
      expect(out.flags[id], 0);

      QMorpher.lerpFast(start, end, 0.6, out);
      expect(out.flags[id], QFlags.isFlex);
    });
  });

  group('QCompiler AST & Token Tests', () {
    test('Tokenizes explicit margins and padding combinations', () {
      final compiler = QEngine.instance.compiler;
      final ptr = compiler.compile('p-10 px-20 pt-5 m-5 my-15');
      final mem = QEngine.instance.mem;

      expect(mem.f32[ptr.fPtr + QF32.padLeft], 20.0);
      expect(mem.f32[ptr.fPtr + QF32.padRight], 20.0);
      expect(mem.f32[ptr.fPtr + QF32.padBottom], 10.0);
      expect(mem.f32[ptr.fPtr + QF32.padTop], 5.0);

      expect(mem.f32[ptr.fPtr + QF32.marLeft], 5.0);
      expect(mem.f32[ptr.fPtr + QF32.marRight], 5.0);
      expect(mem.f32[ptr.fPtr + QF32.marTop], 15.0);
      expect(mem.f32[ptr.fPtr + QF32.marBottom], 15.0);
    });

    test('Tokenizes Flexbox constraints & Alignment', () {
      final compiler = QEngine.instance.compiler;
      final ptr =
          compiler.compile('row justify-between items-center wrap grow gap-16');
      final mem = QEngine.instance.mem;

      expect(mem.flags[ptr.id] & QFlags.isFlex, QFlags.isFlex);
      expect(mem.flags[ptr.id] & QFlags.flexCol, 0);
      expect(mem.flags[ptr.id] & QFlags.justifyBetween, QFlags.justifyBetween);
      expect(mem.flags[ptr.id] & QFlags.itemsCenter, QFlags.itemsCenter);
      expect(mem.flags[ptr.id] & QFlags.wrap, QFlags.wrap);
      expect(mem.flags[ptr.id] & QFlags.expand, QFlags.expand);
      expect(mem.f32[ptr.fPtr + QF32.gap], 16.0);
    });

    test('Tokenizes Sizes & Typography', () {
      final compiler = QEngine.instance.compiler;
      final ptr = compiler.compile(
          'w-200 h-f text-3xl font-bold italic text-center tracking-wide leading-tight text-ellipsis');
      final mem = QEngine.instance.mem;

      expect(mem.f32[ptr.fPtr + QF32.width], 200.0);
      expect(mem.f32[ptr.fPtr + QF32.height], double.infinity);

      expect(mem.f32[ptr.fPtr + QF32.fontSize], 30.0);
      expect(mem.flags[ptr.id] & QFlags.fontBold, QFlags.fontBold);
      expect(mem.flags[ptr.id] & QFlags.fontItalic, QFlags.fontItalic);
      expect(mem.flags[ptr.id] & QFlags.textCenter, QFlags.textCenter);
      expect(mem.f32[ptr.fPtr + QF32.letterSpacing], 1.5);
      expect(mem.f32[ptr.fPtr + QF32.lineHeight],
          closeTo(1.1, 0.0001)); // Added closeTo for 32-bit precision
      expect(mem.flags[ptr.id] & QFlags.textEllipsis, QFlags.textEllipsis);
    });

    test('Tokenizes Visuals (Backgrounds, Gradients, Borders, Shadows, Blurs)',
        () {
      final compiler = QEngine.instance.compiler;
      final ptr = compiler.compile(
          'bg-[#112233] bg-gradient-to-br from-red to-blue via-white border-4 border-[#000000] shadow-glow blur-10 rounded-full opacity-50');
      final mem = QEngine.instance.mem;

      expect(mem.c32[ptr.cPtr + QC32.background], 0xFF112233);
      expect(mem.flags[ptr.id] & QFlags.hasGradient, QFlags.hasGradient);
      expect(mem.flags[ptr.id] & QFlags.gradToBR, QFlags.gradToBR);
      expect(mem.c32[ptr.cPtr + QC32.gradientFrom], 0xFFEF4444); // red
      expect(mem.c32[ptr.cPtr + QC32.gradientTo], 0xFF3B82F6); // blue
      expect(mem.c32[ptr.cPtr + QC32.gradientVia], 0xFFFFFFFF); // white

      expect(mem.flags[ptr.id] & QFlags.hasBorder, QFlags.hasBorder);
      expect(mem.f32[ptr.fPtr + QF32.borderWidth], 4.0);
      expect(mem.c32[ptr.cPtr + QC32.border], 0xFF000000);

      expect(mem.flags[ptr.id] & QFlags.hasShadow, QFlags.hasShadow);
      expect(mem.f32[ptr.fPtr + QF32.shadowBlur], 32.0); // glow
      expect(mem.f32[ptr.fPtr + QF32.shadowSpread], 8.0);

      expect(mem.flags[ptr.id] & QFlags.hasBlur, QFlags.hasBlur);
      expect(mem.f32[ptr.fPtr + QF32.blurSigma], 2.5); // Fixed division (10/4)

      expect(mem.f32[ptr.fPtr + QF32.radius], 9999.0); // rounded-full
      expect(mem.flags[ptr.id] & QFlags.hasRoundedClip, QFlags.hasRoundedClip);

      expect(mem.f32[ptr.fPtr + QF32.opacity], 0.5);
    });

    test('Environment Context Bitmask Filtering (Responsive & Dark Mode)', () {
      final compiler = QEngine.instance.compiler;

      final ptr = compiler.compile(
        'bg-white dark:bg-black sm:w-100 lg:w-300 dark:sm:text-red',
        contextMask: QContextBits.dark | QContextBits.sm,
      );
      final mem = QEngine.instance.mem;

      expect(mem.c32[ptr.cPtr + QC32.background], 0xFF000000); // dark applied
      expect(mem.f32[ptr.fPtr + QF32.width], 100.0); // sm applied, lg ignored
      expect(
          mem.c32[ptr.cPtr + QC32.text], 0xFFEF4444); // dark:sm combo applied
    });
  });

  group('Q Widget Rendering Tests', () {
    Widget buildTestApp(
      Widget child, {
      Brightness brightness = Brightness.light,
      Size size = const Size(800, 600),
      TextDirection textDirection = TextDirection.ltr,
    }) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Directionality(
            textDirection: textDirection,
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets('Basic Box rendering (Colors, Dimensions, Padding)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        const Q('bg-red w-200 h-150 p-20', text: 'Hello Quantum'),
      ));

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      expect(container.constraints?.minWidth, 200.0);
      expect(container.constraints?.minHeight, 150.0);
      expect(container.padding, const EdgeInsets.all(20));

      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFEF4444));

      final textFinder = find.text('Hello Quantum');
      expect(textFinder, findsOneWidget);
    });

    testWidgets('Flex Layout: Row, Alignments, and Spaced Gaps',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        const Q(
          'row justify-between items-end gap-16',
          children: [
            Text('A'),
            Text('B'),
            Text('C'),
          ],
        ),
      ));

      final flexFinder = find.byType(Flex);
      expect(flexFinder, findsOneWidget);

      final Flex flex = tester.widget(flexFinder);
      expect(flex.direction, Axis.horizontal);
      expect(flex.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.end);

      final children = flex.children;
      expect(children.length, 5); // 3 Texts + 2 SizedBoxes
      expect(children[1], isA<SizedBox>());
      expect((children[1] as SizedBox).width, 16.0);
    });

    testWidgets('Flex Layout: Col, Wrap, and Expanded integration',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        const Q('col', // Setup valid Parent Flex context
            children: [
              Q(
                'col flex-1', // col + expand
                children: [
                  Q('row wrap gap-10', children: [Text('A'), Text('B')]),
                ],
              )
            ]),
      ));

      // The child Q should be wrapped in Expanded due to `flex-1` AND being inside a valid Flex scope
      expect(find.byType(Expanded), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);

      final Wrap wrap = tester.widget(find.byType(Wrap));
      expect(wrap.direction, Axis.horizontal);
      expect(wrap.spacing, 10.0);
      expect(wrap.runSpacing, 10.0);
    });

    testWidgets('Typography: Span styling, Alignments, SelectableText',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        const Q(
          'text-2xl font-bold italic text-center tracking-wide',
          text: 'Typography Test',
        ),
      ));

      final textFinder = find.text('Typography Test');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.textAlign, TextAlign.center);
      expect(textWidget.style?.fontSize, 24.0);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(textWidget.style?.fontStyle, FontStyle.italic);
      expect(textWidget.style?.letterSpacing, 1.5);
    });

    testWidgets('Visual Modifiers: Blur, Shadows, Borders, Opacity',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        const Q(
            'bg-white border-2 border-black shadow-lg blur-10 opacity-50 rounded-full',
            text: 'FX'),
      ));

      expect(find.byType(ClipRRect), findsWidgets);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);

      final Container container = tester.widget(find
          .descendant(
              of: find.byType(Opacity), matching: find.byType(Container))
          .first);
      final BoxDecoration decoration = container.decoration as BoxDecoration;

      expect(decoration.border?.bottom.width, 2.0);
      expect(decoration.border?.bottom.color, const Color(0xFF000000));
      expect(decoration.borderRadius, BorderRadius.circular(9999.0));
      expect(decoration.boxShadow?.first.blurRadius, 24.0);
    });

    testWidgets(
        'Contextual Rendering: Dark Mode and Breakpoints trigger updates',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        const Q('bg-white dark:bg-black w-100 md:w-300', text: 'Responsive'),
        brightness: Brightness.light,
        size: const Size(400, 800), // < 640 is sm
      ));

      Container container = tester.widget(find.byType(Container));
      expect((container.decoration as BoxDecoration).color,
          const Color(0xFFFFFFFF));
      expect(container.constraints?.minWidth, 100.0);

      await tester.pumpWidget(buildTestApp(
        const Q('bg-white dark:bg-black w-100 md:w-300', text: 'Responsive'),
        brightness: Brightness.dark,
        size: const Size(800, 800), // >= 640 and < 1024 is md
      ));
      await tester.pumpAndSettle();

      container = tester.widget(find.byType(Container));
      expect((container.decoration as BoxDecoration).color,
          const Color(0xFF000000));
      expect(container.constraints?.minWidth, 300.0);
    });

    testWidgets('Q.merge combines Explicit Arrays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        Q.merge(
          ['bg-red', 'w-100', null, false, 'text-center'],
          padding: [10, 20, 30, 40], // T, R, B, L
          margin: [5, 15], // V, H
          text: 'Merged',
        ),
      ));

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      expect(
          container.padding,
          const EdgeInsets.fromLTRB(40.0, 10.0, 20.0,
              30.0)); // Left(40), Top(10), Right(20), Bottom(30)
      expect(
          container.margin,
          const EdgeInsets.fromLTRB(
              15.0, 5.0, 15.0, 5.0)); // Left(15), Top(5), Right(15), Bottom(5)

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.textAlign, TextAlign.center);
    });
  });

  group('QThemePresets', () {
    test('Loads Dark Vivid Theme into Graph successfully', () {
      final preset = QThemePresets.darkVivid();
      final graph = QEngine.instance.theme;
      graph.load(preset);

      expect(graph.color('colors.brand-primary'), 0xFF3B82F6);
      expect(graph.color('colors.surface'), 0xFF0F172A);
      expect(graph.number('spacing.md'), 12.0);
    });
  });
  group('QEngine Lifecycle & Theme Animation', () {
    testWidgets(
        'initialize(), dispose(), and animateTheme() execute without memory leaks',
        (WidgetTester tester) async {
      final engine = QEngine.instance;
      engine.dispose();
      engine.initialize(initialCapacity: 128);

      // Load initial theme (Black)
      engine.loadThemeDictionary(QThemeDictionary.fromJson({
        'colors': {'bg': '#000000'}
      }));

      // Compiles with the fully qualified 'colors.bg' key
      final ptr = engine.compiler.compile('bg-colors.bg');
      expect(engine.mem.c32[ptr.cPtr + QC32.background], 0xFF000000);

      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      engine.animateTheme(() {
        // Swap to White Theme. Recompiling the SAME token updates its memory ID in the target arena!
        engine.loadThemeDictionary(QThemeDictionary.fromJson({
          'colors': {'bg': '#FFFFFF'}
        }));
        engine.compiler.compile('bg-colors.bg');
      }, const TestVSync(), duration: const Duration(milliseconds: 300));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Mid-point color check (Gray)
      expect(engine.mem.c32[ptr.cPtr + QC32.background], 0xFF7F7F7F);

      await tester.pump(const Duration(milliseconds: 150));

      // End color check (White)
      expect(engine.mem.c32[ptr.cPtr + QC32.background], 0xFFFFFFFF);

      engine.dispose();
      expect(() => engine.mem, throwsA(isA<StateError>()));
    });
  });

  group('QCompiler Advanced Token Syntax & Opacity', () {
    test('Slash opacity modifier parses correctly', () {
      final compiler = QEngine.instance.compiler;

      // Base hex with 50% opacity
      final hexPtr = compiler.compile('bg-[#FFFFFF]/50');
      // 50% of 255 = 127.5 -> Dart rounds to 128 = 0x80
      expect(
          QEngine.instance.mem.c32[hexPtr.cPtr + QC32.background], 0x80FFFFFF);

      // Built-in color with 20% opacity
      final builtinPtr = compiler.compile('bg-black/20');
      // 20% of 255 = 51 = 0x33
      expect(QEngine.instance.mem.c32[builtinPtr.cPtr + QC32.background],
          0x33000000);
    });

    test('Built-in literal colors parse successfully', () {
      final compiler = QEngine.instance.compiler;
      final mem = QEngine.instance.mem;

      final ptr1 = compiler.compile('bg-transparent');
      expect(mem.c32[ptr1.cPtr + QC32.background], 0x00000000);

      final ptr2 = compiler.compile('bg-white');
      expect(mem.c32[ptr2.cPtr + QC32.background], 0xFFFFFFFF);

      final ptr3 = compiler.compile('bg-slate-900');
      expect(mem.c32[ptr3.cPtr + QC32.background], 0xFF0F172A);
    });

    test('Border overrides and shorthand variants', () {
      final compiler = QEngine.instance.compiler;
      final mem = QEngine.instance.mem;

      // Default border
      final defPtr = compiler.compile('border');
      expect(mem.flags[defPtr.id] & QFlags.hasBorder, QFlags.hasBorder);
      expect(mem.f32[defPtr.fPtr + QF32.borderWidth], 1.0);
      expect(mem.c32[defPtr.cPtr + QC32.border], 0xFFE2E8F0);

      // Explicit thickness and color
      final expPtr = compiler.compile('border-4 border-[#FF0000]');
      expect(mem.f32[expPtr.fPtr + QF32.borderWidth], 4.0);
      expect(mem.c32[expPtr.cPtr + QC32.border], 0xFFFF0000);
    });

    test('Corner radius absolute matching', () {
      final compiler = QEngine.instance.compiler;
      final mem = QEngine.instance.mem;

      expect(mem.f32[compiler.compile('rounded-none').fPtr + QF32.radius], 0.0);
      expect(mem.f32[compiler.compile('rounded-s').fPtr + QF32.radius], 4.0);
      expect(mem.f32[compiler.compile('rounded').fPtr + QF32.radius], 8.0);
      expect(mem.f32[compiler.compile('rounded-l').fPtr + QF32.radius], 16.0);
      expect(mem.f32[compiler.compile('rounded-24').fPtr + QF32.radius], 24.0);
    });
  });

  group('QCompiler Multiple Context States', () {
    test('Combinatorial context bitmasks (dark:hover:etc)', () {
      final compiler = QEngine.instance.compiler;
      final mem = QEngine.instance.mem;

      // Token requires Dark Mode AND Hover
      final ptr = compiler.compile('bg-white dark:hover:bg-red',
          contextMask: QContextBits.dark | QContextBits.hover);
      // Red should override white because context matches
      expect(mem.c32[ptr.cPtr + QC32.background], 0xFFEF4444);

      // Token requires Dark Mode AND Hover, but we only supply Dark
      final ptrFail = compiler.compile('bg-white dark:hover:bg-red',
          contextMask: QContextBits.dark);
      // Fails condition, stays white
      expect(mem.c32[ptrFail.cPtr + QC32.background], 0xFFFFFFFF);

      // Triple combo
      final ptrTriple = compiler.compile('bg-white rtl:dark:md:bg-black',
          contextMask: QContextBits.rtl | QContextBits.dark | QContextBits.md);
      expect(mem.c32[ptrTriple.cPtr + QC32.background], 0xFF000000);
    });
  });

  group('Q.merge Logic & Array Constraints', () {
    testWidgets('Q.merge Array Length Parsing Edge Cases (1, 2, 4 elements)',
        (WidgetTester tester) async {
      // 1 Element = All
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Q.merge([], padding: [10]))));
      Container c = tester.widget(find.byType(Container));
      expect(c.padding, const EdgeInsets.all(10.0));

      // 2 Elements = Vertical, Horizontal
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Q.merge([], padding: [10, 20]))));
      c = tester.widget(find.byType(Container));
      expect(c.padding,
          const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0));

      // 4 Elements = Top, Right, Bottom, Left
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: Q.merge([], padding: [1, 2, 3, 4]))));
      c = tester.widget(find.byType(Container));
      expect(
          c.padding,
          const EdgeInsets.fromLTRB(
              4.0, 1.0, 2.0, 3.0)); // Left(4), Top(1), Right(2), Bottom(3)
    });

    testWidgets(
        'Q.merge safely filters out nulls, falses, and empty strings in styles array',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Q.merge([
        'bg-red',
        null,
        false,
        '',
        'text-white',
        true ? 'rounded' : null
      ]))));

      Container c = tester.widget(find.byType(Container));
      final dec = c.decoration as BoxDecoration;

      expect(dec.color, const Color(0xFFEF4444));
      expect(dec.borderRadius, BorderRadius.circular(8.0));

      // Search specifically INSIDE the Q widget to avoid catching Scaffold's default text styles
      final textStyleFinder = find.descendant(
          of: find.byType(Q), matching: find.byType(DefaultTextStyle));
      expect(textStyleFinder, findsOneWidget);
    });
  });
}
