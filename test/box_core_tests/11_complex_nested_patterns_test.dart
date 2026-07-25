// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: COMPLEX NESTED PATTERNS — PRODUCTION TESTS
// test/box_core_tests/11_complex_nested_patterns_test.dart
//
// These are REAL production patterns that exercise the engine under
// complex, multi-level, multi-subtype conditions.
//
// Patterns tested:
//  1. App shell: col → appbar + expanded(row → sidebar + expanded(col))
//  2. Settings page: col → section headers + card groups
//  3. Chat interface: col → messages(col+scroll) + input(row)
//  4. Dashboard: col → topbar + expanded(row → sidebar + expanded(grid))
//  5. E-commerce product detail: col → image(aspect) + info(col) + review(wrap)
//  6. Onboarding: stack → bg + col(center content) + overlay dots
//  7. Data table: col → header(row) + scrollable rows
//  8. Modal dialog pattern inside col
//  9. Infinite scroll list with measure on first item
//  10. Multi-panel responsive builder
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Complex Nested Patterns — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Full App Shell ──────────────────────────────────────────────────
    testWidgets('1.1 complete app shell: topbar + sidebar + scrollable content', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full min-w-0 min-h-0',
        'children': [
          // Top app bar
          {
            'type': 'row',
            'style': 'w-full h-56 bg-blue-700 items-center px-16 gap-12',
            'children': [
              colorBox('w-32 h-32 rounded-full bg-blue-300'),
              textLeaf('My App'),
              {
                'type': 'box:expanded',
                'children': [colorBox('w-full h-40 bg-blue-600 rounded-lg')],
              },
            ],
          },
          // Body
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'row',
                'style': 'w-full h-full min-w-0',
                'children': [
                  // Sidebar
                  {
                    'type': 'col',
                    'style': 'w-240 h-full bg-slate-800 gap-4',
                    'props': {'padding': [16]},
                    'children': List.generate(
                      6,
                      (i) => {
                        'type': 'row',
                        'style': 'w-full h-48 rounded-lg items-center gap-12 px-12',
                        'props': {
                          'onClick': [
                            {'action': 'state.set', 'key': 'activeNav', 'value': i}
                          ],
                        },
                        'children': [
                          colorBox('w-20 h-20 rounded-sm bg-slate-500'),
                          textLeaf('Nav $i'),
                        ],
                      },
                    ),
                  },
                  // Main content area
                  {
                    'type': 'box:expanded',
                    'children': [
                      {
                        'type': 'col',
                        'style': 'w-full h-full bg-slate-50',
                        'props': {'scrollable': true, 'padding': [24]},
                        'children': [
                          {
                            'type': 'grid',
                            'style': 'w-full',
                            'props': {'gridCols': '1fr 1fr 1fr 1fr', 'gap': 16},
                            'children': List.generate(
                              8,
                              (i) => {
                                'type': 'box:surface',
                                'style': 'h-100',
                                'props': {
                                  'fill': 'surface',
                                  'depth': 'raised',
                                  'intent': 'slate-900',
                                },
                                'children': [
                                  textLeaf('Metric $i'),
                                  {
                                    'type': 'text',
                                    'style': 'text-2xl font-bold',
                                    'props': {'text': '${(i + 1) * 42}'},
                                  },
                                ],
                              },
                            ),
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('My App'), findsOneWidget);
      expect(find.text('Nav 0'), findsOneWidget);
      expect(find.text('Metric 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. Settings Page Pattern ───────────────────────────────────────────
    testWidgets('2.1 settings page with grouped sections', (tester) async {
      final sections = [
        {'title': 'Account', 'items': ['Profile', 'Password', 'Email']},
        {'title': 'Preferences', 'items': ['Language', 'Theme', 'Notifications']},
        {'title': 'Privacy', 'items': ['Data', 'Permissions', 'Analytics']},
      ];

      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full bg-slate-50',
        'props': {'scrollable': true},
        'children': sections.map((section) {
          return {
            'type': 'col',
            'style': 'w-full gap-4',
            'props': {'padding': [16, 16, 8, 16]},
            'children': [
              textLeaf(section['title'] as String),
              {
                'type': 'box:surface',
                'style': 'w-full rounded-2xl',
                'props': {'fill': 'surface', 'depth': 'raised'},
                'children': (section['items'] as List<String>).map((item) {
                  return {
                    'type': 'row',
                    'style': 'w-full h-56 items-center px-20 gap-12',
                    'props': {
                      'onClick': [
                        {'action': 'state.set', 'key': 'selectedSetting', 'value': item}
                      ],
                    },
                    'children': [
                      colorBox('w-32 h-32 rounded-lg bg-blue-100'),
                      textLeaf(item),
                      {
                        'type': 'box:expanded',
                        'children': [colorBox('w-0 h-0')],
                      },
                      colorBox('w-16 h-16 bg-slate-300 rounded-sm'),
                    ],
                  };
                }).toList(),
              },
            ],
          };
        }).toList(),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Password'));
      await tester.pump();
      expect(testStore.get('selectedSetting'), equals('Password'));
    });

    // ── 3. Chat Interface Pattern ──────────────────────────────────────────
    testWidgets('3.1 chat interface: message list + input row', (tester) async {
      final messages = [
        {'sender': 'Alice', 'text': 'Hello!', 'mine': false},
        {'sender': 'Me', 'text': 'Hi Alice!', 'mine': true},
        {'sender': 'Alice', 'text': 'How are you?', 'mine': false},
        {'sender': 'Me', 'text': 'Great, thanks!', 'mine': true},
        {'sender': 'Alice', 'text': 'Want to meet later?', 'mine': false},
      ];

      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full bg-slate-50',
        'children': [
          // Header
          colorBox('w-full h-56 bg-white shadow-sm', label: 'Alice'),
          // Messages (scrollable)
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'col',
                'style': 'w-full h-full',
                'props': {'scrollable': true, 'padding': [12]},
                'children': messages.map((msg) {
                  final isMine = msg['mine'] as bool;
                  return {
                    'type': 'row',
                    'style': 'w-full ${isMine ? 'justify-end' : 'justify-start'} mb-8',
                    'children': [
                      {
                        'type': 'col',
                        'style': 'rounded-2xl px-16 py-10 '
                            '${isMine ? 'bg-blue-500' : 'bg-white shadow-sm'}',
                        'props': {'constrained': true, 'maxWidth': 280.0},
                        'children': [textLeaf(msg['text'] as String)],
                      },
                    ],
                  };
                }).toList(),
              },
            ],
          },
          // Input row
          {
            'type': 'row',
            'style': 'w-full h-64 bg-white items-center gap-12 px-16',
            'children': [
              {
                'type': 'box:expanded',
                'children': [colorBox('w-full h-40 bg-slate-100 rounded-full')],
              },
              colorBox('w-44 h-44 rounded-full bg-blue-500 items-center justify-center'),
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Hi Alice!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. E-Commerce Product Detail Page ─────────────────────────────────
    testWidgets('4.1 product detail: aspect image + info col + tag wrap + actions', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full bg-white',
        'props': {'scrollable': true},
        'children': [
          // Product image
          {
            'type': 'box:aspect',
            'props': {'ratio': 1.0},
            'children': [colorBox('w-full h-full bg-slate-100')],
          },
          // Product info
          {
            'type': 'col',
            'style': 'w-full gap-16',
            'props': {'padding': [24]},
            'children': [
              textLeaf('Wireless Headphones Pro'),
              {
                'type': 'row',
                'style': 'w-full items-center gap-8',
                'children': [
                  textLeaf('\$299.99'),
                  colorBox('px-12 py-6 rounded-full bg-green-100', label: 'In Stock'),
                ],
              },
              // Tags
              {
                'type': 'wrap',
                'style': 'w-full gap-8',
                'children': ['Wireless', 'Bluetooth 5.0', 'ANC', '30h Battery', 'USB-C']
                    .map((tag) => {
                          'type': 'col',
                          'style': 'rounded-full bg-slate-100 px-12 py-6',
                          'children': [textLeaf(tag)],
                        })
                    .toList(),
              },
              // Description
              textLeaf(
                  'Experience next-level audio with our premium wireless headphones. '
                  'Featuring advanced noise cancellation and studio-quality sound.'),
              // Color options
              {
                'type': 'row',
                'style': 'w-full items-center gap-12',
                'children': [
                  'bg-slate-900',
                  'bg-white border border-slate-200',
                  'bg-blue-600',
                  'bg-rose-600',
                ].map((c) => colorBox('w-40 h-40 rounded-full $c')).toList(),
              },
            ],
          },
          // Action buttons
          {
            'type': 'row',
            'style': 'w-full gap-12 px-24 pb-24',
            'children': [
              {
                'type': 'box:expanded',
                'children': [colorBox('w-full h-56 rounded-full bg-blue-600 items-center justify-center', label: 'Add to Cart')],
              },
              colorBox('w-56 h-56 rounded-full bg-slate-100 items-center justify-center'),
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Wireless Headphones Pro'), findsOneWidget);
      expect(find.text('\$299.99'), findsOneWidget);
      expect(find.text('Wireless'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 5. Onboarding with Stack ───────────────────────────────────────────
    testWidgets('5.1 onboarding screen: full-screen stack with overlay elements', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-full h-full',
        'children': [
          // Background gradient
          colorBox('w-full h-full bg-indigo-600'),
          // Content layer
          {
            'type': 'col',
            'style': 'w-full h-full items-center justify-center gap-24',
            'props': {'padding': [48]},
            'children': [
              colorBox('w-120 h-120 rounded-3xl bg-white/20'),
              textLeaf('Welcome to QuantumApp'),
              textLeaf('The next generation UI engine for modern apps'),
              {
                'type': 'col',
                'style': 'w-full h-56 rounded-full bg-white items-center justify-center',
                'props': {
                  'onClick': [
                    {'action': 'state.set', 'key': 'onboarded', 'value': true}
                  ],
                },
                'children': [textLeaf('Get Started')],
              },
            ],
          },
          // Dots indicator at bottom
          {
            'type': 'col',
            'style': 'w-full pb-48 items-center',
            'children': [
              {
                'type': 'row',
                'style': 'gap-8',
                'children': List.generate(
                  3,
                  (i) => colorBox(
                    'w-${i == 0 ? 24 : 8} h-8 rounded-full '
                    '${i == 0 ? 'bg-white' : 'bg-white/40'}',
                  ),
                ),
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to QuantumApp'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(testStore.get('onboarded'), isTrue);
    });

    // ── 6. Data Table Pattern ──────────────────────────────────────────────
    testWidgets('6.1 data table with header row + scrollable body rows', (tester) async {
      final columns = ['Name', 'Role', 'Status', 'Joined'];
      final rows = List.generate(
        10,
        (i) => ['User $i', 'Developer', i % 2 == 0 ? 'Active' : 'Inactive', '2024-01-${i + 1}'],
      );

      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [
          // Header
          {
            'type': 'row',
            'style': 'w-full h-48 bg-slate-100 items-center px-16',
            'children': columns
                .map((col) => {
                      'type': 'box:expanded',
                      'children': [textLeaf(col)],
                    })
                .toList(),
          },
          // Body
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'col',
                'style': 'w-full h-full',
                'props': {'scrollable': true},
                'children': rows
                    .asMap()
                    .entries
                    .map((entry) => {
                          'type': 'row',
                          'style': 'w-full h-56 items-center px-16 '
                              '${entry.key % 2 == 0 ? 'bg-white' : 'bg-slate-50'}',
                          'children': entry.value
                              .map((cell) => {
                                    'type': 'box:expanded',
                                    'children': [textLeaf(cell)],
                                  })
                              .toList(),
                        })
                    .toList(),
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('User 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Nested grid with surface cards ─────────────────────────────────
    testWidgets('7.1 analytics dashboard: nested grid with charts + stats', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full bg-slate-100',
        'props': {'scrollable': true, 'padding': [24]},
        'children': [
          // Top stats row
          {
            'type': 'grid',
            'style': 'w-full mb-24',
            'props': {'gridCols': '1fr 1fr 1fr 1fr', 'gap': 16},
            'children': [
              'Revenue', 'Users', 'Orders', 'Conversion'
            ].asMap().entries.map((e) => {
                  'type': 'box:surface',
                  'style': 'h-100',
                  'props': {'fill': 'surface', 'depth': 'raised'},
                  'children': [
                    textLeaf(e.value),
                    {
                      'type': 'text',
                      'style': 'text-3xl font-bold text-blue-600',
                      'props': {'text': '\$${(e.key + 1) * 12350}'},
                    },
                  ],
                }).toList(),
          },
          // Two column layout: chart + details
          {
            'type': 'grid',
            'style': 'w-full',
            'props': {'gridCols': '2fr 1fr', 'gap': 24},
            'children': [
              // Chart area
              {
                'type': 'box:surface',
                'style': 'h-300',
                'props': {'fill': 'surface', 'depth': 'raised'},
                'children': [
                  textLeaf('Revenue Over Time'),
                  colorBox('w-full h-200 bg-slate-100 rounded-xl mt-16'),
                ],
              },
              // Details col
              {
                'type': 'col',
                'style': 'gap-12',
                'children': List.generate(
                  4,
                  (i) => {
                    'type': 'box:surface',
                    'style': 'h-60',
                    'props': {'fill': 'surface', 'depth': 'flat'},
                    'children': [
                      {
                        'type': 'row',
                        'style': 'w-full h-full items-center gap-12',
                        'children': [
                          colorBox('w-32 h-32 rounded-full bg-blue-${(i + 1) * 100}'),
                          textLeaf('Metric ${i + 1}'),
                          {
                            'type': 'box:expanded',
                            'children': [colorBox('w-0 h-0')],
                          },
                          textLeaf('${(i + 1) * 23}%'),
                        ],
                      },
                    ],
                  },
                ),
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('Revenue Over Time'), findsOneWidget);
      expect(find.text('Metric 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. Scroll with measure on sentinel item ────────────────────────────
    testWidgets('8.1 box:measure within scrollable list tracks scroll sentinel', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'props': {'scrollable': true},
        'children': [
          // Sentinel measured item at the top
          {
            'type': 'box:measure',
            'props': {'bind': 'first_item_bounds'},
            'children': [textLeaf('First Measured Item')],
          },
          ...List.generate(
            30,
            (i) => textLeaf('List Item $i'),
          ),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('First Measured Item'), findsOneWidget);
      // After settlement, the measure node should have written bounds
      expect(testStore.get('first_item_bounds'), isA<Map>());
      expect(tester.takeException(), isNull);
    });

    // ── 9. Responsive multi-panel ─────────────────────────────────────────
    testWidgets('9.1 box:builder drives adaptive layout based on constraints', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'box:builder',
          'children': [
            // In our test, maxWidth = 800px → use 2-col layout
            {
              'type': 'grid',
              'style': 'w-full',
              'props': {'gridCols': '1fr 1fr', 'gap': 16},
              'children': List.generate(
                6,
                (i) => colorBox('h-80 bg-slate-200 rounded-xl', label: 'Panel$i'),
              ),
            },
          ],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Panel0'), findsOneWidget);
      expect(find.text('Panel5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 10. Dynamic content list with action → store feedback loop ─────────
    testWidgets('10.1 list of cards each driving state.set on tap', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'props': {'scrollable': true},
        'children': List.generate(
          10,
          (i) => {
            'type': 'box:surface',
            'style': 'w-full h-80 mb-12',
            'props': {
              'fill': 'surface',
              'depth': 'raised',
              'onClick': [
                {'action': 'state.set', 'key': 'last_selected', 'value': i}
              ],
            },
            'children': [
              {
                'type': 'row',
                'style': 'w-full h-full items-center gap-16 px-20',
                'children': [
                  colorBox('w-48 h-48 rounded-full bg-blue-${(i % 5 + 1) * 100}'),
                  textLeaf('Item $i'),
                ],
              },
            ],
          },
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);

      await tester.tap(find.text('Item 3'));
      await tester.pump();
      expect(testStore.get('last_selected'), equals(3));

      await tester.tap(find.text('Item 7'));
      await tester.pump();
      expect(testStore.get('last_selected'), equals(7));
    });
  });
}
