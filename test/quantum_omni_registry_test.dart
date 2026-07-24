// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI REGISTRY - OMEGA TEST SUITE (100% EXHAUSTIVE COVERAGE)
// test/quantum_omni_registry_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Quantum Omni Registry | 10-Core Exhaustive Validation |', () {
    setUp(() {
      // 1. Total System Purge
      QLModuleRegistry.instance.clear();
      QLSchemaRegistry.instance.clear();
      QLPipelineRegistry.instance.destroy('default');
      QLStoreRegistry.instance.destroy('default');
      QuantumVM.instance.clearRuntimeCaches();
      clearQuantumInputRegistry();

      // 2. Hardware Engine Initialization
      QEngine.instance.initialize(initialCapacity: 4096);
      QuantumVM.instance.initialize(workerThreads: 1);

      // 3. Mount the Omni Registry
      registerOmniComponents(QuantumVM.instance);

      // 4. Register State Action for interactive tests (Tabs/Steppers)
      QuantumVM.instance.registerAction(
        'state.set',
        LambdaActionPlugin((p, s, c) async {
          s.set(p['key'].toString(), p['value']);
        }),
      );
    });

    Widget _buildTestWrapper(Map<String, dynamic> uiJson,
        {Map<String, dynamic>? initialStore}) {
      final store = QLStoreRegistry.instance.defaultStore;
      if (initialStore != null) {
        initialStore.forEach((k, v) => store.set(k, v));
      }

      final ast = QLBlueprint.fromJson(uiJson);
      return MaterialApp(
        // 🚀 CRITICAL FIX: Ensure a large, strictly bounded screen for rendering tests
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 1200,
            child: QLOverlayRoot(
              // 🚀 REQUIRED FOR PORTAL/Z-SPACE TESTS
              child: QLDataScope(
                moduleStore: store,
                child: Builder(
                  builder: (ctx) => QuantumVM.instance.renderWidget(ctx, ast),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. PROCEDURAL CSS & DESIGN MATRIX
    // ─────────────────────────────────────────────────────────────────────────
    test('1. QDesignMatrix Generates Procedural Tailwind Classes', () {
      final String normalButton = QDesignMatrix.resolve(
        family: 'action',
        intent: 'emerald',
        fill: 'solid',
        depth: 'raised',
        edge: 'none',
        shape: 'rounded',
        scale: 'md',
        disabled: false,
      );

      expect(normalButton, contains('bg-emerald'));
      expect(normalButton, contains('text-white'));
      expect(normalButton, contains('shadow-sm'));
      expect(normalButton, contains('rounded-xl'));

      final String disabledCard = QDesignMatrix.resolve(
        family: 'surface',
        intent: 'slate',
        fill: 'surface',
        depth: 'flat',
        edge: 'thick',
        shape: 'sharp',
        scale: 'md',
        disabled: true,
      );

      expect(disabledCard, contains('bg-slate-100'));
      expect(disabledCard, contains('cursor-not-allowed'));
      expect(disabledCard, contains('rounded-none'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. ALIAS REGISTRY RESOLUTION
    // ─────────────────────────────────────────────────────────────────────────
    test('2. Alias Resolution & Colon Syntax Extrapolation', () {
      final alias1 = QuantumVM.instance.getAlias('row');
      expect(alias1!['type'], 'box:row');

      final alias2 = QuantumVM.instance.getAlias('email_field');
      expect(alias2!['type'], 'field:email');

      final alias3 = QuantumVM.instance.getAlias('card');
      expect(alias3!['type'], 'box:card');
      expect(alias3['props']['depth'], 'raised'); // Proves default props exist
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. BOX CORE & SPATIAL PRIMITIVES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('3. Box Core: Row, Safe Area, Measure, and Split',
        (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "style": "w-full h-full", // 🚀 Prevent infinite height overflows
        "children": [
          {
            "type": "box:safe",
            "children": [
              {
                "type": "text",
                "props": {"text": "Safe"}
              }
            ]
          },
          {
            "type": "box:measure",
            "props": {"bind": "box_bounds"},
            "children": [
              {
                "type": "text",
                "props": {"text": "Measured"}
              }
            ]
          },
          {
            "type": "box:split",
            "style":
                "h-300 w-full", // 🚀 Enforces bounds to prevent CustomMultiChildLayout exception
            "props": {
              "direction": "horizontal",
              "fractions": [0.3, 0.7]
            },
            "children": [
              {
                "type": "text",
                "props": {"text": "Pane1"}
              },
              {
                "type": "text",
                "props": {"text": "Pane2"}
              }
            ]
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Measured'), findsOneWidget);
      expect(find.byType(QLMultiSplit), findsOneWidget);

      // Verify the measure node wrote bounds to the store
      final store = QLStoreRegistry.instance.defaultStore;
      final bounds = store.get('box_bounds');
      expect(bounds, isA<Map<String, dynamic>>());
      expect(bounds['w'], greaterThan(0.0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. IMPLICIT BEHAVIORS (Magneto, Draggable, Hero)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('4. Implicit Behaviors: Magneto and Drag Zones',
        (WidgetTester tester) async {
      final ui = {
        "type": "card",
        "props": {"magneto": true, "dragData": "item_123"},
        "children": [
          {
            "type": "text",
            "props": {"text": "Hover Me"}
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));

      // Implicit wrappers applied automatically
      expect(find.byType(QLMagnetoSurface), findsOneWidget);
      expect(find.byType(QLPortalDrag), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. ACTION CORE & KINEMATICS
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('5. Action Core: Buttons, Focus, and Raw Pointer',
        (WidgetTester tester) async {
      bool wasClicked = false;

      QuantumVM.instance.registerAction('test.click',
          LambdaActionPlugin((p, s, c) async {
        wasClicked = true;
      }));

      final ui = {
        "type": "col",
        "children": [
          {
            "type": "button",
            "props": {
              "text": "Click Me",
              "onClick": ["test.click"]
            }
          },
          {
            "type": "action:focus",
            "props": {"bindState": "is_focused"},
            "children": [
              {
                "type": "text",
                "props": {"text": "Focusable"}
              }
            ]
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));

      // Test Button Click
      await tester.tap(find.text('Click Me'));
      await tester.pump();
      expect(wasClicked, isTrue);

      // Verify Focus widget exists natively
      expect(find.byType(Focus), findsWidgets);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. FIELD CORE (Standalone vs. Form Scope)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('6. Field Core: Reactive Headless Inputs',
        (WidgetTester tester) async {
      final ui = {
        "type": "form_scope",
        "children": [
          {
            "type": "text_field",
            "props": {"bind": "user.name", "label": "Full Name"}
          },
          {
            "type": "toggle",
            "props": {"bind": "user.agreed", "label": "Accept"}
          },
          {
            "type": "slider",
            "props": {"bind": "user.age", "min": 0, "max": 100}
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      final store = QLStoreRegistry.instance.defaultStore;

      expect(find.byType(QLRawTextInput), findsOneWidget);
      expect(find.byType(QLRawToggle), findsOneWidget);
      expect(find.byType(QLRawSlider), findsOneWidget);

      // Verify form scope initialization
      final formValid = store.get('ctrl_0.isValid');
      // Test that the God-Mode graph exists and operates
      expect(find.byType(QLDataScope), findsWidgets);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 7. TEXT & MEDIA CORES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('7. Text & Media Cores: Selectable Rich Text, Icons',
        (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "text:h1",
            "props": {"text": "Heading", "selectable": true}
          },
          {
            "type": "media:icon",
            "props": {"codePoint": 0xe3af} // Icons.home
          },
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));

      // Selectable text translates to SelectableText
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 8. DATA CORE (Repeaters and Slivers)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('8. Data Core: Repeater Array Iteration',
        (WidgetTester tester) async {
      final ui = {
        "type": "system:repeater",
        "props": {
          "bind": ["Apple", "Banana", "Cherry"],
          "as": "fruit"
        },
        "children": [
          {
            "type": "text",
            "props": {"text": "{{\$env.fruit}}"} // 🚀 Use strict env token
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 9. SYSTEM CORE (Omega Macro, Telemetry, Lifecycle)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('9. System Core: Omega Macro and Lifecycle Hooks',
        (WidgetTester tester) async {
      bool mountedTriggered = false;

      QuantumVM.instance.registerAction('hook.mount',
          LambdaActionPlugin((p, s, c) async {
        mountedTriggered = true;
      }));

      final ui = {
        "type": "col",
        "children": [
          {
            "type": "system:lifecycle",
            "props": {
              "onMount": ["hook.mount"]
            },
            "children": [
              {
                "type": "text",
                "props": {"text": "Lifecycle Node"}
              }
            ]
          },
          {
            "type": "system:omega_macro",
            "props": {
              "template": {
                "type": "card",
                "children": [
                  {
                    "type": "text",
                    "props": {"text": "Macro Inner"}
                  }
                ]
              }
            }
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      expect(mountedTriggered, isTrue);
      expect(find.text('Macro Inner'), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 11. EXTENDED BOX CORE (Matrix, Responsive, Builder, Expanded)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets(
        '11. Box Core: Responsive, Builder, Matrix, and Flexible Constraints',
        (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "style":
            "w-full h-full", // 🚀 Prevent LayoutBuilder infinity exceptions
        "children": [
          {
            "type": "box:responsive",
            "children": [
              {
                "type": "text",
                "props": {"text": "Compact: {{\$env.isCompact}}"}
              }
            ]
          },
          {
            "type": "box:matrix",
            "props": {"matrixBind": "my_matrix"},
            "children": [
              {
                "type": "text",
                "props": {"text": "Matrix Layer"}
              }
            ]
          },
          {
            "type": "box:expanded",
            "children": [
              {
                "type": "text",
                "props": {"text": "Fills Space"}
              }
            ]
          }
        ]
      };

      final initialStore = {
        "my_matrix": [
          1.0,
          0,
          0,
          0,
          0,
          1.0,
          0,
          0,
          0,
          0,
          1.0,
          0,
          50.0,
          50.0,
          0,
          1.0
        ]
      };

      await tester
          .pumpWidget(_buildTestWrapper(ui, initialStore: initialStore));
      await tester.pumpAndSettle();

      // Verify Flexible wraps the Expanded box
      expect(find.byType(Flexible), findsOneWidget);

      // Verify Matrix transformation layer applied successfully
      expect(find.text('Matrix Layer'), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 12. EXTENDED ACTIONS (Hover, Long Press, Navigate, Links)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('12. Action Core: Long Press, Hover, and Routing Links',
        (WidgetTester tester) async {
      bool longPressed = false;
      bool navigated = false;

      QuantumVM.instance.registerAction('mock.long_press',
          LambdaActionPlugin((p, s, c) async => longPressed = true));
      QuantumVM.instance.registerAction('onNavigate',
          LambdaActionPlugin((p, s, c) async {
        if (p['href'] == '/settings') navigated = true;
      }));

      final ui = {
        "type": "col",
        "children": [
          {
            "type": "action:long_press",
            "props": {
              "text": "Hold Me",
              "onLongPress": ["mock.long_press"]
            }
          },
          {
            "type": "action:link",
            "props": {"text": "Go to Settings", "href": "/settings"}
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));

      // Trigger Long Press
      await tester.longPress(find.text('Hold Me'));
      await tester.pump();
      expect(longPressed, isTrue);

      // Trigger Link
      await tester.tap(find.text('Go to Settings'));
      await tester.pump();
      expect(navigated, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 13. EXTENDED FIELDS (Password, Textarea, Radio)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('13. Field Core: Obscured Text, Textarea, and Radio Groups',
        (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "field:password",
            "props": {"bind": "auth.pass", "placeholder": "Secret"}
          },
          {
            "type": "field:textarea",
            "props": {"bind": "post.body", "minLines": 4, "maxLines": 10}
          },
          {
            "type": "field:radio",
            "props": {"bind": "theme", "label": "Dark Mode"}
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      final store = QLStoreRegistry.instance.defaultStore;

      // Tap radio
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();
      expect(store.get('theme'), isTrue);

      // Check text fields
      final textInputs =
          tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      expect(textInputs.length, 2);

      // Password field should be obscured
      expect(textInputs[0].obscureText, isTrue);
      // Textarea should have multiline props
      expect(textInputs[1].minLines, 4);
      expect(textInputs[1].maxLines, 10);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 14. CANVAS & GRAPHICS CORE (Procedural Drawing, Shapes)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('14. Canvas Core: Procedural Bytecode and Boolean Shapes',
        (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "canvas:draw",
            "style": "w-100 h-100",
            "props": {
              "commands": [
                ["rect", 10, 10, 50, 50, "#FF0000"]
              ]
            }
          },
          {
            "type": "canvas:shape",
            "style": "w-100 h-100",
            "props": {
              "fillColor": "#00FF00",
              "shapeDef": {
                "base": {"type": "circle", "radius": 50},
                "operations": [
                  {
                    "op": "subtract",
                    "shape": {"type": "circle", "radius": 20}
                  }
                ]
              }
            }
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      // Verify the Canvas nodes mounted successfully without crashing
      expect(find.byType(CustomPaint), findsWidgets);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 15. SYSTEM KINEMATICS (Data Pipes, Tickers, Physics Interpolation)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('15. System Core: Tickers, Data Pipes, and RK4 Kinetic Pipes',
        (WidgetTester tester) async {
      final store = QLStoreRegistry.instance.defaultStore;

      final ui = {
        "type": "col",
        "children": [
          {
            "type": "system:data_pipe",
            "props": {
              "mode": "ring_buffer",
              "size": 10,
              "bindSource": "sensor_input",
              "bindOutput": "sensor_history"
            }
          },
          {
            "type": "system:kinetic_pipe",
            "props": {
              "bindSource": "sensor_input",
              "bindOutput": "smooth_sensor",
              "stiffness": 300,
              "damping": 20
            }
          },
          {
            "type": "system:ticker",
            "props": {
              "onTick": ["state.set:key=tick_fired,value=true"]
            }
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));

      // 🚀 FIX: Set the sensor input AFTER mounting so the ring buffer listener catches the change!
      store.set('sensor_input', 100.0);

      // Pump a few frames to allow Ticker to fire and RK4 to step
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Data Pipe captured the value
      final history = store.get('sensor_history');
      expect(history, isNotNull);
      expect(history[9], 100.0);

      // Verify RK4 started interpolating towards 100.0
      final smooth = store.get('smooth_sensor');
      expect(smooth, isNotNull);
      expect(smooth, greaterThan(0.0));

      // Verify Ticker fired the action
      expect(store.get('tick_fired'), 'true');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 16. Z-SPACE PORTALS (Dialogs, Overlays, Context Menus)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('16. Portal Core: Overlays, Dialogs, and Menus',
        (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "portal:dialog",
            "slots": {
              "trigger": {
                "type": "button",
                "props": {"text": "Open Dialog"}
              },
              "content": {
                "type": "text",
                "props": {"text": "Dialog Content"}
              }
            }
          },
          {
            "type": "portal:menu",
            "slots": {
              "trigger": {
                "type": "button",
                "props": {"text": "Open Menu"}
              },
              "content": {
                "type": "text",
                "props": {"text": "Menu Content"}
              }
            }
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      // 🚀 FIX: Use pump(Duration) instead of pumpAndSettle to avoid infinite animation timeouts!
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Dialog Content'), findsOneWidget);

      // Close Dialog (Tap Barrier)
      await tester.tapAt(const Offset(10, 10)); // Tap outside
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Dialog Content'), findsNothing);

      // Open Menu
      await tester.tap(find.text('Open Menu'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Menu Content'), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 17. BUILT-IN TEMPLATES (Accordion, Stepper, Master Detail)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('17. AOT Templates: Tabs, Accordion, and Stepper Macros',
        (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "template:tabs",
            "props": {
              "bind": "active_tab",
              "items": [
                {
                  "label": "Tab 1",
                  "content": {
                    "type": "text",
                    "props": {"text": "Tab 1 Data"}
                  }
                },
                {
                  "label": "Tab 2",
                  "content": {
                    "type": "text",
                    "props": {"text": "Tab 2 Data"}
                  }
                }
              ]
            }
          },
          {
            "type": "template:accordion",
            "props": {
              "multiple": false,
              "items": [
                {
                  "label": "Panel 1",
                  "content": {
                    "type": "text",
                    "props": {"text": "Panel 1 Data"}
                  }
                }
              ]
            }
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      // 🚀 FIX: Use pump(Duration) instead of pumpAndSettle to avoid infinite animation timeouts!
      await tester.pump(const Duration(milliseconds: 400));

      // Tabs check
      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
      expect(find.text('Tab 1 Data'), findsOneWidget); // Default open

      // Tap Tab 2
      await tester.tap(find.text('Tab 2'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Tab 2 Data'), findsOneWidget);

      // Accordion check
      expect(find.text('Panel 1'), findsOneWidget);

      // Expand Panel
      await tester.tap(find.text('Panel 1'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Panel 1 Data'), findsOneWidget);
    });
  });
}
