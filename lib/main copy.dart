import 'package:flutter/material.dart';
import 'quantum.dart';

void main() {
  bootQuantumApp(
    QuantumAppConfig(
      appName: 'Quantum Kicks',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      telemetry: const QuantumTelemetryConfig(enabled: true),
      vm: const QuantumVMConfig(workerThreads: 2),
      registry: QuantumProductionRegistry.commerce(
        actions: {'cart.add': (services) => _AddToCartAction()},
      ),
      domains: [
        QuantumDomain(
          name: 'Storefront',
          routes: [
            QLRouteBuilder.localJson(
              path: '/',
              schemaBuilder: (info) => StorefrontBlueprint.build(),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AddToCartAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final product = payload['product'];
    if (product == null) return;
    final List<dynamic> currentCart = store.get('cart') ?? [];
    final List<dynamic> updatedCart = List.from(currentCart)..add(product);
    store.set('cart', updatedCart);
    store.set('cartCount', updatedCart.length);
    return true;
  }
}

abstract class StorefrontBlueprint {
  static Map<String, dynamic> build() {
    return {
      "module": "omega_dashboard",
      "state": {
        "user": {
          "firstName": "Alex",
          "avatar": "",
        }
      },
      "ui": {
        "type": "page",
        "style": "bg-slate-950 text-white w-full h-full",
        "children": [
          // 🚀 THE FIX: We use native px-24 py-16 and justify-between directly in the style string!
          {
            "type": "app_bar",
            "style":
                "w-full border-b-1 border-white/10 bg-slate-900 px-24 py-16 justify-between items-center",
            "children": [
              {
                "type": "row",
                "style": "items-center gap-12",
                "children": [
                  {
                    "type": "box",
                    "style":
                        "w-40 h-40 border-2 border-primary rounded-full flex-center bg-slate-800",
                    "children": [
                      {
                        "type": "text",
                        "props": {"value": "👤"}
                      }
                    ]
                  },
                  {
                    "type": "col",
                    "style": "gap-4", // <--- MISSING EXPAND

                    "children": [
                      {
                        "type": "text",
                        "props": {"value": "Good morning,"},
                        "style": "text-slate-400 text-xs"
                      },
                      {
                        "type": "text",
                        "props": {"value": "{{state.user.firstName}}"},
                        "style": "text-white font-bold text-lg"
                      }
                    ]
                  }
                ]
              },
              {
                "type": "icon_button",
                "props": {
                  "intent": "slate-100",
                  "variant": "ghost",
                  "shape": "circle"
                },
                "slots": {
                  "icon": {
                    "type": "text",
                    "props": {"value": "🔔"},
                    "style": "text-xl"
                  }
                }
              }
            ]
          },

          // --- User Cards ---
          {
            "type": "col",
            "style": "p-24 gap-16 w-full",
            "children": [
              {
                "type": "user_card",
                "props": {
                  "userName": "Alex Quantum",
                  "userRole": "Lead Architect",
                  "avatarUrl": "https://i.pravatar.cc/150?u=alex",
                  "bio":
                      "Building the fastest framework in the world. Passionate about 120Hz performance.",
                  "actionText": "Follow"
                }
              },
              {
                "type": "user_card",
                "slots": {
                  "avatar": {"src": "https://images.com/alex.jpg"},
                  "name": {"text": "Alex Quantum"},
                  "action": {"value": "Follow"}
                }
              },
              {
                "type": "user_card",
                "slots": {
                  "name": {
                    "text": "Admin User",
                    "style":
                        "text-red-500 underline" // Appends to 'text-lg font-bold text-slate-900'
                  }
                }
              },
            ]
          }
        ]
      }
    };
  }
}
