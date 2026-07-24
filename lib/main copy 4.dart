import 'package:flutter/material.dart';
import 'quantum.dart';

void main() {
  bootQuantumApp(
    QuantumAppConfig(
      appName: "Quantum Orbital Command",
      themeMode: ThemeMode.dark,
      telemetry: const QuantumTelemetryConfig(
        enabled: true,
        enableFrameMonitorInDebug: false,
      ),
      registry: OrbitalRegistry(),
      domains: [
        QuantumDomain(
          name: "core",
          routes: [
            QLRoute(
              path: '/',
              transition: QLTransitionType.fade,
              builder: (context, info) {
                // 1. Initialize State
                final store = QLStoreRegistry.instance.defaultStore;
                final state =
                    orbitalDashboardManifest['state'] as Map<String, dynamic>;
                state.forEach((key, value) {
                  if (store.get(key) == null) {
                    store.set(key, value);
                  }
                });

                // 2. Compile AST Synchronously
                final ast = QLCompiler.compile(
                  orbitalDashboardManifest['ui'],
                  orbitalDashboardManifest[r'$define'] ?? {},
                  {},
                );

                // 3. Render
                return QLDataScope(
                  moduleStore: store,
                  child: QuantumVM.instance.renderWidget(context, ast),
                );
              },
            )
          ],
        )
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// THE OMEGA REGISTRY: SYSTEM EXTENSIONS & NATIVE WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class OrbitalRegistry extends QuantumProductionRegistry {
  @override
  void install([QuantumVM? target]) {
    super.install(target);

    final vm = target ?? QuantumVM.instance;

    // 🚀 THE SCREEN FIX: Custom Bounded Screen Wrapper
    vm.define('screen', (ctx) {
      return Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(ctx.flutterContext).height,
          minWidth: MediaQuery.sizeOf(ctx.flutterContext).width,
        ),
        color: const Color(0xFF0F172A), // Absolute Solid bg-slate-900
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ctx.children,
          ),
        ),
      );
    });

    // 🚀 INJECT PIPELINES
    final thrustSchema = QLSchemaCompiler.compile('thrust_schema',
        {'id': 'string', 'status': 'string', 'temp': 'number'});
    final thrustPipeline =
        QLDataPipeline(id: 'thrusters', schema: thrustSchema);
    thrustPipeline.ingest([
      {"id": "T-Alpha", "status": "nominal", "temp": 124},
      {"id": "T-Beta", "status": "warning", "temp": 380},
      {"id": "T-Gamma", "status": "critical", "temp": 950},
      {"id": "T-Delta", "status": "nominal", "temp": 110},
    ]);
    QLPipelineRegistry.instance.register(thrustPipeline);

    final crewSchema = QLSchemaCompiler.compile('crew_schema', {
      'id': 'string',
      'name': 'string',
      'role': 'string',
      'health': 'number'
    });
    final crewPipeline = QLDataPipeline(id: 'crew', schema: crewSchema);
    crewPipeline.ingest([
      {"id": "c1", "name": "Cmdr. Ripley", "role": "Navigation", "health": 5},
      {"id": "c2", "name": "Dr. Bowman", "role": "Science", "health": 4},
      {"id": "c3", "name": "Ash", "role": "Systems", "health": 2}
    ]);
    QLPipelineRegistry.instance.register(crewPipeline);

    final serverSchema = QLSchemaCompiler.compile('server_schema', {
      'id': 'string',
      'host': 'string',
      'load': 'number',
      'status': 'string'
    });
    final serverPipeline = QLDataPipeline(id: 'servers', schema: serverSchema);
    serverPipeline.ingest([
      {"id": "SRV-01", "host": "us-east-1", "load": 42.5, "status": "nominal"},
      {"id": "SRV-02", "host": "eu-west-2", "load": 89.2, "status": "warning"},
      {"id": "SRV-03", "host": "ap-south-1", "load": 99.9, "status": "critical"}
    ]);
    QLPipelineRegistry.instance.register(serverPipeline);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// THE OMEGA MANIFEST: DEEP SPACE COMMAND DASHBOARD
// ════════════════════════════════════════════════════════════════════════════

final Map<String, dynamic> orbitalDashboardManifest = {
  "state": {
    "missionTime": "T+ 04:22:10",
    "phase": "Orbital Insertion",
    "thrustLevel": 78.5,
    "autoPilot": true,
    "shieldHarmonics": "#06B6D4",
    "logsOpen": false,
    "activeCam": 0,
  },
  r"$define": {
    "MetricCard": {
      "type": "card",
      "props": {
        "fill": "solid", // 🚀 FIX: Solid dark fill
        "intent": "slate-800",
        "depth": "floating",
        "magneto": {"intensity": 1.2}
      },
      "children": [
        {
          "type": "text",
          "style": "text-xs text-cyan-300 font-bold uppercase tracking-wide",
          "props": {"text": "{{ props.label }}"}
        },
        {
          "type": "text",
          "style": "text-3xl font-black text-white mt-4",
          "props": {"text": "{{ props.value }}"}
        }
      ]
    },
    "SectionTitle": {
      "type": "text",
      "style":
          "text-lg font-bold text-white mb-12 border-b-1 border-slate-700 pb-4",
      "props": {"text": "{{ props.text }}"}
    }
  },
  r"$let": {"isCritical": "{{ state.thrustLevel | eq('100') }}"},
  "ui": {
    "type": "screen",
    "children": [
      // ── APP BAR ──
      {
        "type": "app_bar",
        "style":
            "px-24 py-16 bg-slate-950/80 border-b-1 border-slate-800 justify-between items-center",
        "children": [
          {
            "type": "row",
            "style": "items-center gap-12",
            "children": [
              {
                "type": "box",
                "style":
                    "w-32 h-32 rounded-full bg-cyan-500 shadow-lg shadow-cyan-500/50 flex-center",
                "children": [
                  {"type": "text", "style": "text-white font-bold", "text": "Ω"}
                ]
              },
              {
                "type": "text",
                "style": "text-xl font-black text-white tracking-widest",
                "text": "QUANTUM ORBITAL COMMAND"
              }
            ]
          },
          {
            "type": "badge",
            "props": {
              "intent": "emerald",
              "fill": "solid",
              "value": "SYSTEMS NOMINAL"
            }
          }
        ]
      },

      // ── MAIN DASHBOARD LAYOUT ──
      {
        r"$layout": [
          "hero     hero     side",
          "metrics  metrics  side",
          "controls servers  servers",
          "crew     crew     logs"
        ],
        "style": "p-24",
        "gap": 20,
        "slots": {
          // ── SLOT 1: HERO ──
          "hero": {
            "type": "stack", // 🚀 FIX: Bounded constraints
            "style":
                "rounded-16 overflow-hidden relative h-240 w-full shadow-2xl",
            "children": [
              {
                "type": "carousel",
                "props": {"bind": "activeCam", "effect": "fade"},
                "children": [
                  {
                    "type": "q_image",
                    "props": {
                      "src":
                          "https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1000&auto=format&fit=crop"
                    }
                  },
                  {
                    "type": "q_image",
                    "props": {
                      "src":
                          "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=1000&auto=format&fit=crop"
                    }
                  }
                ]
              },
              {
                "type": "glass_pane",
                "style":
                    "absolute bottom-16 left-16 right-16 p-16 flex row justify-between items-end rounded-12",
                "children": [
                  {
                    "type": "col",
                    "children": [
                      {
                        "type": "text",
                        "style":
                            "text-sm text-cyan-200 uppercase tracking-wide",
                        "text": "Mission Clock"
                      },
                      {
                        "type": "text",
                        "style": "text-4xl font-black text-white font-mono",
                        "props": {"text": "{{ state.missionTime }}"}
                      }
                    ]
                  },
                  {
                    "type": "badge",
                    "props": {
                      "intent": "blue",
                      "fill": "solid",
                      "size": "lg",
                      "value": "PHASE: ORBITAL INSERTION"
                    }
                  }
                ]
              }
            ]
          },

          // ── SLOT 2: METRICS ──
          "metrics": {
            "type": "row",
            "style": "gap-16",
            r"$apply": {
              "props": {"expand": true}
            },
            "children": [
              {
                r"$call": "MetricCard",
                "props": {"label": "Velocity", "value": "24,800 km/h"}
              },
              {
                r"$call": "MetricCard",
                "props": {"label": "Altitude", "value": "408.5 km"}
              },
              {
                r"$call": "MetricCard",
                "props": {"label": "Hull Temp", "value": "1,240 °C"}
              }
            ]
          },

          // ── SLOT 3: SIDE (Thrusters) ──
          "side": {
            "type": "card",
            "props": {
              "fill": "solid",
              "intent": "slate-900",
              "edge": "hairline"
            }, // 🚀 FIX: Solid dark theme
            "children": [
              {
                r"$call": "SectionTitle",
                "props": {"text": "THRUSTER ARRAY"}
              },
              {
                "type": "q_repeater", // 🚀 FIX: Hard Pipeline Linker
                "props": {"pipeline": "thrusters"},
                "children": [
                  {
                    "type": "row",
                    "style":
                        "justify-between items-center p-12 rounded-8 bg-slate-800/50 border-1 border-slate-700 mb-12",
                    "children": [
                      {
                        "type": "row",
                        "style": "items-center gap-12",
                        "children": [
                          {
                            r"$switch": "{{ item.status }}",
                            "cases": {
                              "nominal": {
                                "type": "box",
                                "style":
                                    "w-12 h-12 rounded-full bg-emerald-500 shadow-lg shadow-emerald-500/50"
                              },
                              "warning": {
                                "type": "box",
                                "style":
                                    "w-12 h-12 rounded-full bg-amber-500 shadow-lg shadow-amber-500/50 animate-pulse"
                              },
                              "critical": {
                                "type": "box",
                                "style":
                                    "w-12 h-12 rounded-full bg-red-500 shadow-lg shadow-red-500/50 animate-bounce"
                              }
                            }
                          },
                          {
                            "type": "text",
                            "style": "text-sm font-bold text-white",
                            "props": {"text": "{{ item.id }}"}
                          }
                        ]
                      },
                      {
                        "type": "text",
                        "style": "text-xs font-mono text-slate-400",
                        "props": {"text": "{{ item.temp }} °C"}
                      }
                    ]
                  }
                ]
              }
            ]
          },

          // ── SLOT 4: CONTROLS ──
          "controls": {
            "type": "card",
            "props": {
              "fill": "solid",
              "intent": "slate-900",
              "edge": "hairline"
            },
            "children": [
              {
                r"$call": "SectionTitle",
                "props": {"text": "MANUAL OVERRIDE"}
              },
              {
                "type": "text",
                "style": "text-xs text-slate-400 mb-8",
                "text": "Main Engine Thrust"
              },
              {
                "type": "slider",
                "props": {
                  "bind": "thrustLevel",
                  "min": 0,
                  "max": 100,
                  "intent": "cyan"
                }
              },
              {"type": "box", "style": "h-20"},
              {
                "type": "toggle",
                "props": {
                  "bind": "autoPilot",
                  "label": "Navigational Auto-Pilot",
                  "intent": "emerald"
                }
              },
              {"type": "box", "style": "h-20"},
              {
                "type": "text",
                "style": "text-xs text-slate-400 mb-8",
                "text": "Shield Harmonics"
              },
              {
                "type": "color_field",
                "props": {
                  "bind": "shieldHarmonics",
                  "palette": [
                    "#06B6D4",
                    "#3B82F6",
                    "#8B5CF6",
                    "#EC4899",
                    "#EF4444"
                  ]
                }
              },
              {"type": "box", "style": "h-24"},
              {
                "type": "button",
                "props": {
                  "value": "INITIATE BURN",
                  "intent": "red",
                  "fill": "solid", // 🚀 FIX: Force red button
                  "depth": "glow",
                  "scale": "lg",
                  "onClick": [
                    {
                      "action": "overlay.open",
                      "config": {
                        "style":
                            "bg-slate-900 rounded-16 border-1 border-red-500/50 p-24"
                      },
                      "blueprint": {
                        "type": "col",
                        "style": "gap-16 items-center",
                        "children": [
                          {
                            "type": "text",
                            "style": "text-xl font-bold text-white",
                            "text": "AUTHORIZATION REQUIRED"
                          },
                          {
                            "type": "text",
                            "style": "text-sm text-slate-400 text-center",
                            "text": "Enter Commander PIN to override safeties."
                          },
                          {
                            "type": "pin_field",
                            "props": {
                              "length": 4,
                              "intent": "red",
                              "onComplete": ["overlay.close"]
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            ]
          },

          // ── SLOT 5: SERVERS ──
          "servers": {
            "type": "card",
            "props": {
              "fill": "solid",
              "intent": "slate-900",
              "edge": "hairline"
            }, // 🚀 FIX: Dark Theme
            "children": [
              {
                r"$call": "SectionTitle",
                "props": {"text": "SERVER CLUSTER STATUS"}
              },
              {
                "type": "row",
                "style":
                    "justify-between p-12 border-b-1 border-slate-700 mb-8",
                "children": [
                  {
                    "type": "text",
                    "style": "font-bold text-slate-400 w-80",
                    "text": "NODE"
                  },
                  {
                    "type": "text",
                    "style": "font-bold text-slate-400 w-120",
                    "text": "REGION"
                  },
                  {
                    "type": "text",
                    "style": "font-bold text-slate-400 w-120",
                    "text": "LOAD"
                  },
                  {
                    "type": "text",
                    "style": "font-bold text-slate-400 w-80",
                    "text": "STATUS"
                  }
                ]
              },
              {
                "type": "q_repeater", // 🚀 FIX: Pipeline Iteration
                "props": {"pipeline": "servers"},
                "children": [
                  {
                    "type": "row",
                    "style":
                        "justify-between items-center p-12 border-b-1 border-slate-800",
                    "children": [
                      {
                        "type": "text",
                        "style": "font-mono text-white w-80",
                        "props": {"text": "{{ item.id }}"}
                      },
                      {
                        "type": "text",
                        "style": "text-sm text-slate-300 w-120",
                        "props": {"text": "{{ item.host }}"}
                      },
                      {
                        "type": "row",
                        "style": "items-center gap-8 w-120",
                        "children": [
                          {
                            "type": "text",
                            "style": "text-sm text-white w-44",
                            "props": {"text": "{{ item.load }}%"}
                          },
                          {
                            "type": "box",
                            "style":
                                "h-4 rounded-full bg-slate-700 flex-1 overflow-hidden",
                            "children": [
                              {
                                "type": "box",
                                "style": "h-full bg-cyan-500",
                                "props": {"style": "width: {{ item.load }}%"}
                              }
                            ]
                          }
                        ]
                      },
                      {
                        "type": "box",
                        "style": "w-80",
                        "children": [
                          {
                            r"$switch": "{{ item.status }}",
                            "cases": {
                              "nominal": {
                                "type": "badge",
                                "props": {
                                  "intent": "emerald",
                                  "fill": "solid",
                                  "value": "ONLINE"
                                }
                              },
                              "warning": {
                                "type": "badge",
                                "props": {
                                  "intent": "amber",
                                  "fill": "solid",
                                  "value": "WARNING"
                                }
                              },
                              "critical": {
                                "type": "badge",
                                "props": {
                                  "intent": "red",
                                  "fill": "solid",
                                  "value": "CRITICAL"
                                }
                              }
                            }
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          },

          // ── SLOT 6: CREW ──
          "crew": {
            "type": "card",
            "props": {
              "fill": "solid",
              "intent": "slate-900",
              "edge": "hairline"
            }, // 🚀 FIX: Dark Theme
            "children": [
              {
                r"$call": "SectionTitle",
                "props": {"text": "ACTIVE CREW"}
              },
              {
                "type": "q_repeater", // 🚀 FIX: Pipeline Iteration
                "props": {"pipeline": "crew"},
                "children": [
                  {
                    "type": "card",
                    "style": "w-200 mb-12 mr-12",
                    "props": {
                      "fill": "solid",
                      "intent": "slate-800",
                      "edge": "hairline"
                    },
                    "children": [
                      {
                        "type": "row",
                        "style": "justify-between items-start",
                        "children": [
                          {
                            "type": "col",
                            "style": "gap-4",
                            "children": [
                              {
                                "type": "text",
                                "style": "text-sm font-bold text-white",
                                "props": {"text": "{{ item.name }}"}
                              },
                              {
                                "type": "text",
                                "style": "text-xs text-cyan-400",
                                "props": {"text": "{{ item.role }}"}
                              }
                            ]
                          },
                          {
                            "type": "badge",
                            "props": {
                              "intent": "blue",
                              "fill": "solid",
                              "value": "HP: {{ item.health }}"
                            }
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          },

          // ── SLOT 7: LOGS ──
          "logs": {
            "type": "card",
            "props": {
              "fill": "solid",
              "intent": "slate-900",
              "edge": "hairline"
            }, // 🚀 FIX: Dark Theme
            "children": [
              {
                "type": "row",
                "style": "justify-between items-center py-8 cursor-pointer",
                "props": {
                  "onClick": [
                    {"action": "state.toggle", "key": "logsOpen"}
                  ]
                },
                "children": [
                  {
                    "type": "text",
                    "style": "text-lg font-bold text-white",
                    "text": "MISSION LOGS (ENCRYPTED)"
                  },
                  {
                    r"$switch": "{{ state.logsOpen }}",
                    "cases": {
                      "true": {
                        "type": "text",
                        "style": "text-slate-500",
                        "text": "▲"
                      },
                      "default": {
                        "type": "text",
                        "style": "text-slate-500",
                        "text": "▼"
                      }
                    }
                  }
                ]
              },
              {
                "type": "col",
                "style": "gap-8 mt-12 pt-12 border-t-1 border-slate-800",
                "props": {r"$if": "{{ state.logsOpen }}"},
                "children": [
                  {
                    "type": "text",
                    "style": "text-xs font-mono text-slate-400",
                    "text": "[04:20:00] Thruster T-Gamma temperature rising."
                  },
                  {
                    "type": "text",
                    "style": "text-xs font-mono text-slate-400",
                    "text": "[04:21:15] Auto-pilot engaged."
                  },
                  {
                    "type": "text",
                    "style": "text-xs font-mono text-red-400",
                    "text":
                        "[04:22:10] WARNING: Hull integrity compromised in Sector 4."
                  }
                ]
              }
            ]
          }
        }
      }
    ]
  }
};
