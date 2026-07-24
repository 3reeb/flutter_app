import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quantum.dart';

void main() {
  bootQuantumApp(
    QuantumAppConfig(
      appName: 'Quantum Omega Kitchen Sink',
      themeMode: ThemeMode.light,
      telemetry: const QuantumTelemetryConfig(
        enabled: true,
        enableFrameMonitorInDebug: true, // Shows FPS and Queue limits
      ),
      vm: const QuantumVMConfig(workerThreads: 4, simdArenaCapacity: 16384),
      domains: [
        QuantumDomain(
          name: 'showcase_domain',
          // 🚀 SEED GLOBAL SDUI STATE
          initialStoreData: {
            'mockList': [
              {'title': 'Quantum Core', 'desc': 'High-performance engine'},
              {'title': 'SDUI Matrix', 'desc': 'Server-driven UI'},
              {'title': 'Kinematics', 'desc': 'Hardware physics'},
            ],
            'pointer': {'x': 0.0, 'y': 0.0, 'p': 0.0},
            'timer_count': 0,
            'scroll': {'y': 0.0},
          },
          // 🚀 INJECT GOD-MODE ACTIONS
          actionFactories: {
            'nav.push': (env) =>
                LambdaActionPlugin((payload, store, ctx) async {
                  final path = payload['path']?.toString();
                  if (path != null) env.router.pushPath(path);
                  return null;
                }),
            'nav.pop': (env) => LambdaActionPlugin((payload, store, ctx) async {
                  env.router.pop();
                  return null;
                }),
            'system.toast': (env) =>
                LambdaActionPlugin((payload, store, ctx) async {
                  ctx.showQLToast(
                      builder: (c, close) =>
                          _toastUI(payload['text'] ?? 'Toast'));
                  return null;
                }),
            'system.increment_timer': (env) =>
                LambdaActionPlugin((payload, store, ctx) async {
                  final cur = store.get('timer_count') ?? 0;
                  store.set('timer_count', cur + 1);
                  return null;
                }),
          },
          // 🚀 REGISTER ALL ROUTES
          routes: [
            QLRouteBuilder.localJson(path: '/', schemaBuilder: _homeRoute),
            QLRouteBuilder.localJson(path: '/flex', schemaBuilder: _flexRoute),
            QLRouteBuilder.localJson(path: '/grid', schemaBuilder: _gridRoute),
            QLRouteBuilder.localJson(
                path: '/advanced', schemaBuilder: _advancedRoute),
            QLRouteBuilder.localJson(
                path: '/overlays', schemaBuilder: _overlaysRoute),
            QLRouteBuilder.localJson(
                path: '/forms', schemaBuilder: _formsRoute),
            QLRouteBuilder.localJson(
                path: '/controls', schemaBuilder: _controlsRoute),
            QLRouteBuilder.localJson(
                path: '/graphics', schemaBuilder: _graphicsRoute),
            QLRouteBuilder.localJson(
                path: '/kinematics', schemaBuilder: _kinematicsRoute),
            QLRouteBuilder.localJson(
                path: '/theming', schemaBuilder: _themingRoute),
          ],
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// 1. HOME MENU ROUTE
// ════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> _homeRoute(QLRouteInfo info) => {
      'type': 'col',
      'style': 'w-full h-full bg-slate-50',
      'props': {'scrollable': true},
      'children': [
        {
          'type': 'col',
          'style': 'p-24 gap-16',
          'children': [
            {
              'type': 'text:h1',
              'props': {'text': 'Omega Showcase'}
            },
            {
              'type': 'text:p',
              'style': 'text-slate-500 mb-16',
              'props': {
                'text': 'Test every primitive in the Quantum Framework.'
              }
            },
            {
              'type': 'grid',
              'props': {'gridCols': '1fr 1fr', 'gap': 12},
              'children': [
                _navCard('Flex & Flow', '/flex', 'Rows, Cols, Wrap', 'blue'),
                _navCard('Grid & Masonry', '/grid', 'Hardware Grid, Auto-Fit',
                    'indigo'),
                _navCard(
                    'Spatial', '/advanced', 'Split, Morph, Stacks', 'cyan'),
                _navCard('Overlays', '/overlays', 'Sheets, Modals, Windows',
                    'purple'),
                _navCard(
                    'Forms', '/forms', 'Headless Inputs, Scopes', 'emerald'),
                _navCard('Controls', '/controls', 'Tabs, Steppers, Repeaters',
                    'teal'),
                _navCard(
                    'Graphics', '/graphics', 'Canvas, Shapes, Media', 'rose'),
                _navCard('Kinematics', '/kinematics', 'Pointers, Timers, Sync',
                    'orange'),
                _navCard('Theming', '/theming', 'Neon, Brutalism, Gradients',
                    'amber'),
              ]
            }
          ]
        }
      ]
    };

// ════════════════════════════════════════════════════════════════════════════
// 2. KINEMATICS & HARDWARE ROUTE
// ════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> _kinematicsRoute(QLRouteInfo info) =>
    _pageShell('Kinematics & Hardware', [
      _section('Vsync Timer (120Hz Hardware Ticker)', {
        'type': 'system:timer', // Alias for system:timer
        'props': {
          'interval': 100, // 100ms
          'onTick': [
            {'action': 'system.increment_timer'}
          ]
        },
        'style':
            'w-full p-24 bg-white rounded-xl shadow-sm border border-slate-200 flex-center',
        'children': [
          {
            'type': 'text:label',
            'props': {'text': 'TIMER FIRING'}
          },
          {
            'type': 'text:h1',
            'style': 'text-5xl text-blue-600',
            'props': {'text': '{{state.timer_count}}'}
          }
        ]
      }),
      _section('Raw Pointer (Bypasses Gesture Arena)', {
        'type': 'raw_pointer', // Alias for action:raw_pointer
        'props': {
          'bindX': 'pointer.x',
          'bindY': 'pointer.y',
          'bindPressure': 'pointer.p'
        },
        'style': 'w-full h-200 bg-slate-800 rounded-xl flex-center',
        'children': [
          _txt('Drag Finger Here', style: 'text-slate-400 mb-8'),
          _txt('X: {{state.pointer.x}}', style: 'text-white font-mono'),
          _txt('Y: {{state.pointer.y}}', style: 'text-white font-mono'),
          _txt('Pressure: {{state.pointer.p}}', style: 'text-white font-mono'),
        ]
      }),
      _section('Sync Scroll (0-GC Scroll Telemetry)', {
        'type': 'sync_scroll', // Alias for system:sync_scroll
        'props': {'bindY': 'scroll.y'},
        'style':
            'w-full h-200 bg-white border border-slate-200 rounded-xl overflow-hidden',
        'children': [
          {
            'type': 'col',
            'props': {'scrollable': true},
            'style': 'w-full h-full p-16 gap-8',
            'children': List.generate(
                20, (i) => _demoBox('Scroll Item $i', color: 'teal'))
          }
        ]
      }),
      _txt('Scroll Y Position: {{state.scroll.y}}px',
          style: 'font-bold text-center w-full'),
    ]);

// ════════════════════════════════════════════════════════════════════════════
// 3. THEMING & PROCEDURAL CSS ROUTE
// ════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> _themingRoute(QLRouteInfo info) =>
    _pageShell('Theming & CSS', [
      _section('Procedural Gradients', {
        'type': 'col',
        'style': 'w-full gap-12',
        'children': [
          {
            'type': 'box',
            'style':
                'w-full h-64 rounded-xl bg-gradient-to-br from-blue-400 via-purple-500 to-pink-500'
          },
          {
            'type': 'box',
            'style':
                'w-full h-64 rounded-xl bg-gradient-to-r from-emerald-400 to-cyan-500'
          },
          {
            'type': 'box',
            'style':
                'w-full h-64 rounded-xl bg-gradient-to-b from-orange-400 to-rose-500'
          },
        ]
      }),
      _section('QDesignMatrix Depths', {
        'type': 'wrap',
        'props': {'gap': 16},
        'children': [
          {
            'type': 'card',
            'props': {'intent': 'brand-primary', 'depth': 'raised'},
            'children': [_txt('Raised', style: 'text-white')]
          },
          {
            'type': 'card',
            'props': {'intent': 'brand-secondary', 'depth': 'floating'},
            'children': [_txt('Floating', style: 'text-white')]
          },
          {
            'type': 'card',
            'props': {'intent': 'success', 'depth': 'glow'},
            'children': [_txt('Glow', style: 'text-white')]
          },
          {
            'type': 'card',
            'props': {'intent': 'error', 'depth': 'neon'},
            'children': [_txt('Neon', style: 'text-white')]
          },
          {
            'type': 'card',
            'props': {'intent': 'warning', 'depth': 'neobrutal'},
            'children': [_txt('Neobrutal', style: 'font-bold')]
          },
        ]
      }),
      _section('Typography Engine', {
        'type': 'col',
        'style':
            'w-full p-24 bg-white rounded-xl shadow-sm border border-slate-200 gap-16',
        'children': [
          {
            'type': 'text:h1',
            'style': 'tracking-tight',
            'props': {'text': 'Tracking Tight H1'}
          },
          {
            'type': 'text:p',
            'style': 'tracking-wide font-bold text-blue-600',
            'props': {'text': 'Tracking Wide & Bold & Colored'}
          },
          {
            'type': 'text:p',
            'style': 'italic text-slate-500',
            'props': {'text': 'Italicized muted text.'}
          },
          {
            'type': 'text:p',
            'style': 'leading-relaxed text-slate-800',
            'props': {
              'text':
                  'Leading relaxed. This is a very long text to demonstrate line height. It provides excellent readability for paragraphs.'
            }
          },
        ]
      }),
    ]);

// ════════════════════════════════════════════════════════════════════════════
// 4. GRAPHICS & CANVAS ROUTE
// ════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> _graphicsRoute(QLRouteInfo info) =>
    _pageShell('Graphics & Canvas', [
      _section('Procedural Bytecode (canvas:draw)', {
        'type': 'canvas:draw',
        'props': {
          'commands': [
            // [OpCode, X, Y, W, H, ColorHex]
            ['rect', 0, 0, 100, 100, '#3B82F6'],
            ['rect', 110, 0, 100, 100, '#10B981'],
            // [OpCode, X, Y, Radius, ColorHex]
            ['circle', 270, 50, 50, '#F43F5E'],
          ]
        },
        'style': 'w-full h-100',
      }),
      _section('Canvas Boolean Shapes', {
        'type': 'canvas:shape',
        'props': {
          'fillColor': '#8B5CF6', // Purple
          'shapeDef': {
            'base': {'type': 'rect', 'w': '100%', 'h': 120, 'radius': 24},
            'operations': [
              {
                'op': 'subtract',
                'shape': {'type': 'circle', 'x': '100%', 'y': 0, 'radius': 40}
              },
              {
                'op': 'subtract',
                'shape': {'type': 'circle', 'x': 0, 'y': '100%', 'radius': 40}
              }
            ]
          }
        },
        'style': 'w-full h-120',
      }),
      _section('Media & Avatars', {
        'type': 'row',
        'style': 'w-full gap-16 items-center justify-center',
        'children': [
          {
            'type': 'avatar',
            'props': {'src': 'https://i.pravatar.cc/150?u=10', 'size': 80}
          },
          {
            'type': 'avatar',
            'props': {'src': 'https://i.pravatar.cc/150?u=20', 'size': 64}
          },
          {
            'type': 'center', 'style': 'w-64 h-64 rounded-full bg-slate-200',
            'children': [
              {
                'type': 'media:icon',
                'props': {'codePoint': 0xe000, 'size': 32}
              }
            ] // Home icon
          }
        ]
      }),
    ]);

// ════════════════════════════════════════════════════════════════════════════
// 5. ADVANCED CONTROLS ROUTE
// ════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> _controlsRoute(QLRouteInfo info) =>
    _pageShell('Advanced Controls', [
      _section('Segmented Control (Template)', {
        'type': 'segmented_control',
        'props': {
          'items': [
            {'label': 'Daily', 'value': 'day'},
            {'label': 'Weekly', 'value': 'week'},
            {'label': 'Monthly', 'value': 'month'},
          ]
        },
      }),
      _section('Carousel (Template)', {
        'type': 'carousel',
        'style': 'h-200',
        'props': {
          'items': [
            {'content': _demoBox('Slide 1', color: 'blue')},
            {'content': _demoBox('Slide 2', color: 'indigo')},
            {'content': _demoBox('Slide 3', color: 'purple')},
          ]
        }
      }),
      _section('Stepper / Wizard (Template)', {
        'type': 'stepper',
        'props': {
          'steps': [
            {
              'label': 'Step 1',
              'content': _demoBox('Complete Step 1 to proceed.', color: 'slate')
            },
            {
              'label': 'Step 2',
              'content': _demoBox('Almost there!', color: 'slate')
            },
            {
              'label': 'Finish',
              'content': _demoBox('You made it!', color: 'emerald')
            },
          ]
        }
      }),
      _section('Tabs Engine (Native Logic)', {
        'type': 'tabs',
        'props': {
          'initialIndex': 0,
          'items': [
            {
              'label': 'Overview',
              'content': _demoBox('Overview Content', color: 'blue')
            },
            {
              'label': 'Settings',
              'content': _demoBox('Settings Content', color: 'teal')
            },
          ]
        },
      }),
      _section('Accordion (Multiple Logic)', {
        'type': 'accordion',
        'props': {
          'multiple': true,
          'items': [
            {
              'label': 'Section 1',
              'content':
                  _demoBox('Internal details about section 1.', color: 'teal')
            },
            {
              'label': 'Section 2',
              'content':
                  _demoBox('Internal details about section 2.', color: 'cyan')
            },
          ]
        },
      }),
      _section('System Repeater (List Iteration)', {
        'type': 'system:repeater',
        'props': {'bind': '{{state.mockList}}', 'as': 'listItem'},
        'style': 'w-full gap-8',
        'slots': {
          'item': {
            'type': 'row',
            'style':
                'w-full p-16 bg-white rounded-xl shadow-sm border border-slate-200 items-center justify-between',
            'children': [
              {
                'type': 'col',
                'children': [
                  {
                    'type': 'text:h3',
                    'props': {'text': '{{listItem.title}}'}
                  },
                  {
                    'type': 'text:p',
                    'style': 'text-slate-500',
                    'props': {'text': '{{listItem.desc}}'}
                  },
                ]
              },
              {
                'type': 'action:button',
                'props': {'text': 'View', 'fill': 'soft', 'scale': 'sm'}
              }
            ]
          }
        }
      }),
    ]);

// ════════════════════════════════════════════════════════════════════════════
// REUSABLE BUILDER HELPERS
// ════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> _pageShell(
        String title, List<Map<String, dynamic>> content) =>
    {
      'type': 'col',
      'style': 'w-full h-full bg-slate-50',
      'children': [
        {
          'type': 'row',
          'style':
              'w-full p-16 bg-white border-b border-slate-200 items-center gap-16',
          'children': [
            {
              'type': 'action:button',
              'props': {
                'text': '← Back',
                'fill': 'ghost',
                'scale': 'sm',
                'onClick': [
                  {'action': 'nav.pop'}
                ]
              }
            },
            {
              'type': 'text:h2',
              'props': {'text': title}
            },
          ]
        },
        {
          'type': 'col',
          'props': {'scrollable': true},
          'style': 'w-full flex-1',
          'children': [
            {'type': 'col', 'style': 'p-16 gap-32', 'children': content}
          ]
        }
      ]
    };

Map<String, dynamic> _section(String title, Map<String, dynamic> body) => {
      'type': 'col',
      'style': 'w-full gap-12',
      'children': [
        {
          'type': 'text:h3',
          'style': 'text-slate-800 pl-4',
          'props': {'text': title}
        },
        body
      ]
    };

Map<String, dynamic> _demoBox(String text, {String color = 'blue'}) => {
      'type': 'center',
      'style': 'bg-$color-500 rounded-lg p-16 shadow-sm w-full',
      'children': [_txt(text, style: 'text-white font-bold text-center')]
    };

Map<String, dynamic> _txt(String t, {String? style}) => {
      'type': 'text',
      'props': {'text': t},
      if (style != null) 'style': style
    };

Map<String, dynamic> _navCard(
        String title, String path, String subtitle, String color) =>
    {
      'type': 'action:button',
      'props': {
        'fill': 'surface',
        'depth': 'raised',
        'scale': 'fluid',
        'onClick': [
          {'action': 'nav.push', 'path': path}
        ]
      },
      'style': 'items-start px-20 py-16 gap-4 border-t-4 border-$color-500',
      'children': [
        {
          'type': 'text:h3',
          'props': {'text': title}
        },
        {
          'type': 'text:p',
          'style': 'text-slate-500 text-sm',
          'props': {'text': subtitle}
        },
      ]
    };

Map<String, dynamic> _btn(String text, String color,
        {String? action, Map<String, dynamic>? payload}) =>
    {
      'type': 'action:button',
      'props': {
        'text': text,
        'intent': color,
        'fill': 'solid',
        'scale': 'fluid',
        if (action != null)
          'onClick': [
            {'action': action, ...?payload}
          ]
      }
    };

Map<String, dynamic> _closeBtn() => {
      'type': 'action:button',
      'style': 'mt-16',
      'props': {
        'text': 'Close',
        'fill': 'soft',
        'scale': 'fluid',
        'onClick': [
          {'action': 'overlay.close'}
        ]
      }
    };

Map<String, dynamic> _modalCard(String title, String body) => {
      'type': 'col',
      'style': 'bg-white rounded-2xl p-24 w-full shadow-xl',
      'children': [
        {
          'type': 'text:h2',
          'props': {'text': title}
        },
        {
          'type': 'text:p',
          'style': 'text-slate-500 mt-8 mb-24',
          'props': {'text': body}
        },
        _closeBtn()
      ]
    };

Widget _toastUI(String text) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.black87, borderRadius: BorderRadius.circular(100)),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );

// ─────────────────────────────────────────────────────────────────────────────
// PREVIOUS ROUTE LOGIC RETAINED BELOW FOR COMPLETENESS
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _flexRoute(QLRouteInfo info) => _pageShell('Flex & Flow', [
      _section('Row (Space Between, Items Center)', {
        'type': 'row',
        'style':
            'w-full bg-white p-16 rounded-xl border border-slate-200 justify-between items-center',
        'children': [
          _demoBox('Left', color: 'indigo'),
          _demoBox('Center', color: 'blue'),
          _demoBox('Right', color: 'indigo')
        ]
      }),
      _section('Column (Stretch & Gap)', {
        'type': 'col',
        'style':
            'w-full bg-white p-16 rounded-xl border border-slate-200 items-stretch gap-8',
        'children': [
          _demoBox('Stretched Box 1', color: 'rose'),
          _demoBox('Stretched Box 2', color: 'rose')
        ]
      }),
      _section('Wrap (Fluid Flow Engine)', {
        'type': 'wrap',
        'style':
            'w-full bg-white p-16 rounded-xl border border-slate-200 gap-12',
        'children':
            List.generate(8, (i) => _demoBox('Wrap $i', color: 'emerald'))
      }),
    ]);

Map<String, dynamic> _gridRoute(QLRouteInfo info) =>
    _pageShell('Grid & Masonry', [
      _section('Hardware Grid (1fr 2fr 1fr)', {
        'type': 'grid',
        'props': {'gridCols': '1fr 2fr 1fr', 'gap': 12},
        'style': 'w-full',
        'children': [
          _demoBox('1fr', color: 'teal'),
          _demoBox('2fr (Wider)', color: 'teal'),
          _demoBox('1fr', color: 'teal'),
          {
            'type': 'grid_item',
            'props': {'colSpan': 3},
            'children': [_demoBox('Spans all 3 Columns', color: 'cyan')]
          }
        ]
      }),
      _section('Auto-Fit Grid (Responsive)', {
        'type': 'grid',
        'props': {'gridCols': 'repeat(auto-fit, minmax(100px, 1fr))', 'gap': 8},
        'style': 'w-full bg-slate-100 p-12 rounded-xl',
        'children': List.generate(7, (i) => _demoBox('Cell $i', color: 'blue'))
      }),
    ]);

Map<String, dynamic> _advancedRoute(QLRouteInfo info) =>
    _pageShell('Advanced Spatial', [
      _section('Split Pane', {
        'type': 'split',
        'props': {
          'direction': 'horizontal',
          'fractions': [0.3, 0.7],
          'height': 150
        },
        'style':
            'w-full bg-white rounded-xl border border-slate-200 overflow-hidden',
        'children': [
          {
            'type': 'center',
            'style': 'bg-blue-50 h-full w-full',
            'children': [_txt('Drag ->')]
          },
          {
            'type': 'center',
            'style': 'bg-emerald-50 h-full w-full',
            'children': [_txt('<- Drag')]
          },
        ]
      }),
      _section('Aspect Ratios', {
        'type': 'row',
        'props': {'gap': 16},
        'children': [
          {
            'type': 'col',
            'props': {'aspectBox': true, 'ratio': 1.0},
            'style': 'w-full bg-slate-800 rounded-xl flex-center',
            'children': [_txt('1:1 Aspect', style: 'text-white')]
          },
        ]
      }),
    ]);

Map<String, dynamic> _overlaysRoute(QLRouteInfo info) =>
    _pageShell('Overlays & Portals', [
      _section('Modal Dialogs', {
        'type': 'row',
        'style': 'w-full gap-12 wrap',
        'children': [
          {
            'type': 'portal:dialog',
            'props': {
              'bgEffect': 'blur',
              'bgBlurSigma': 16.0,
              'extrude3D': false
            },
            'slots': {
              'trigger': _btn('Standard Blur Dialog', 'blue'),
              'content': _modalCard(
                  'Blurred Background', 'Notice the frosted glass background.')
            }
          },
          {
            'type': 'portal:dialog',
            'props': {'bgEffect': 'darken', 'extrude3D': true},
            'slots': {
              'trigger': _btn('3D Extruded Dialog', 'purple'),
              'content': _modalCard(
                  '3D Extrusion', 'Flies in using a perspective matrix.')
            }
          },
        ]
      }),
      _section('Sheets & Drawers', {
        'type': 'row',
        'style': 'w-full gap-12 wrap',
        'children': [
          {
            'type': 'portal:sheet',
            'props': {'edge': 'bottom', 'bgEffect': 'zoomBack', 'h': 400},
            'slots': {
              'trigger': _btn('Bottom Sheet (ZoomBack)', 'emerald'),
              'content': {
                'type': 'col',
                'style': 'w-full h-full bg-white rounded-t-3xl p-24 shadow-lg',
                'children': [
                  {
                    'type': 'center',
                    'style':
                        'w-48 h-6 bg-slate-200 rounded-full mb-24 self-center'
                  },
                  {
                    'type': 'text:h2',
                    'props': {'text': 'Bottom Sheet'}
                  },
                  {
                    'type': 'text:p',
                    'style': 'text-slate-500 mt-8 flex-1',
                    'props': {
                      'text': 'Notice the root view scales back beautifully.'
                    }
                  },
                  _closeBtn()
                ]
              }
            }
          },
        ]
      }),
      _section('Anchored Modals', {
        'type': 'row',
        'style': 'w-full gap-16 justify-between items-center',
        'children': [
          {
            'type': 'portal:menu',
            'props': {'matchAnchorWidth': false},
            'slots': {
              'trigger': _btn('Popover Menu', 'rose'),
              'content': {
                'type': 'col',
                'style':
                    'bg-white shadow-lg border border-slate-200 rounded-lg p-8 w-200',
                'children': [
                  {
                    'type': 'text:p',
                    'style': 'p-8 font-bold border-b border-slate-100',
                    'props': {'text': 'Options'}
                  },
                  {
                    'type': 'action:button',
                    'style': 'mt-4',
                    'props': {
                      'text': 'Settings',
                      'fill': 'ghost',
                      'scale': 'sm',
                      'onClick': [
                        {'action': 'overlay.close'}
                      ]
                    }
                  },
                ]
              }
            }
          },
        ]
      }),
    ]);

Map<String, dynamic> _formsRoute(QLRouteInfo info) =>
    _pageShell('Forms Engine', [
      _section('God-Mode Form Scope', {
        'type': 'form_scope', // Alias for control:form_scope
        'props': {'id': 'my_form'},
        'style':
            'w-full bg-white p-24 rounded-2xl border border-slate-200 shadow-sm gap-16',
        'children': [
          {
            'type': 'text:h3',
            'props': {'text': 'Profile Setup'}
          },
          {
            'type': 'text_field',
            'props': {
              'bind': 'user.name',
              'label': 'Full Name',
              'placeholder': 'John Doe'
            }
          },
          {
            'type': 'password_field',
            'props': {
              'bind': 'user.password',
              'label': 'Password',
              'placeholder': '••••••••'
            }
          },
          {
            'type': 'textarea',
            'props': {'bind': 'user.bio', 'label': 'Biography', 'minLines': 3}
          },
          {
            'type': 'row',
            'style': 'w-full gap-16 mt-8',
            'children': [
              {
                'type': 'col',
                'style': 'flex-1 gap-8',
                'children': [
                  {
                    'type': 'text:label',
                    'props': {'text': 'Volume Level'}
                  },
                  {
                    'type': 'slider',
                    'props': {
                      'bind': 'user.volume',
                      'min': 0,
                      'max': 100,
                      'initialValue': 50
                    }
                  }
                ]
              },
              {
                'type': 'col',
                'style': 'flex-1 items-end justify-center',
                'children': [
                  {
                    'type': 'toggle',
                    'props': {
                      'bind': 'user.notifications',
                      'label': 'Enable Alerts',
                      'initialValue': true
                    }
                  }
                ]
              }
            ]
          },
          {
            'type': 'row',
            'style':
                'w-full justify-between items-center mt-16 pt-16 border-t border-slate-100',
            'children': [
              _btn('Submit Form', 'brand-primary',
                  action: 'system.toast',
                  payload: {'text': 'Form logic executed!'}),
              {
                'type': 'text:p',
                'style': 'text-slate-400 font-mono text-xs',
                'props': {'text': 'Valid: {{my_form.isValid}}'}
              }
            ]
          }
        ]
      })
    ]);
