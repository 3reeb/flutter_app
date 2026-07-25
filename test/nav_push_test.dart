import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  testWidgets('Test nav.push from surface', (tester) async {
    final routes = [
      QLRouteBuilder.localJson(
        path: '/',
        schemaBuilder: (info) => {
          'type': 'action:button',
          'props': {
            'text': 'Go to flex',
            'onClick': [
              {'action': 'nav.push', 'path': '/flex'}
            ]
          }
        },
      ),
      QLRouteBuilder.localJson(
        path: '/flex',
        schemaBuilder: (info) => {
          'type': 'text',
          'props': {'text': 'Flex Page'}
        },
      ),
    ];

    final appRouter = QLNavController(
      routes: routes,
      initialRoute: '/',
    );

    final env = QuantumAppEnvironment(
      router: appRouter,
      vm: QuantumVM.instance,
      primitives: QEngine.instance,
      nativeBridges: QLNativeBridgeRegistry.instance,
      pipelines: QLPipelineRegistry.instance,
      schemas: QLSchemaRegistry.instance,
      stores: QLStoreRegistry.instance,
      asyncSignals: QLAsyncRegistry.instance,
      overlays: QuantumOverlay.instance,
      telemetry: QuantumTelemetry.instance,
      services: const QuantumRuntimeServices(),
      config: QuantumAppConfig(appName: 'Test', domains: [], telemetry: const QuantumTelemetryConfig(enabled: false)),
    );

    // Make sure 'nav.push' is correctly registered in _actions
    QuantumVM.instance.registerAction(
      'nav.push',
      LambdaActionPlugin((payload, store, ctx) async {
        final path = payload['path']?.toString();
        print('NAV PUSH CALLED WITH PATH: $path');
        if (path != null) await env.router.pushPath(path);
        return null;
      }),
    );

    await tester.pumpWidget(MaterialApp.router(
      routerDelegate: QLRouterDelegate(appRouter),
      routeInformationParser: const QLRouteParser(),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Go to flex'), findsOneWidget);

    debugDumpApp();

    print('TAPPING NOW');
    await tester.tap(find.text('Go to flex'));
    await tester.pumpAndSettle();

    print('STACK SIZE: ${appRouter.stack.length}');
  });
}
