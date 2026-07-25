import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Quantum Router Navigation Engine Real Tests', () {
    testWidgets('Router pushes and pops routes correctly and updates the tree', (tester) async {
      final controller = QLNavController(
        initialRoute: '/',
        routes: [
          QLRoute(
            path: '/',
            builder: (ctx, info) => const Text('Home Page'),
          ),
          QLRoute(
            path: '/flex',
            builder: (ctx, info) => const Text('Flex Page'),
          ),
          QLRoute(
            path: '/users/:id',
            builder: (ctx, info) => Text('User ${info.params['id']}'),
          ),
        ],
      );

      final delegate = QLRouterDelegate(controller);

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: delegate,
        routeInformationParser: _MockParser(),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('Flex Page'), findsNothing);

      // Push Flex
      controller.pushPath('/flex');
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsNothing);
      expect(find.text('Flex Page'), findsOneWidget);

      // Push User
      controller.pushPath('/users/123');
      await tester.pumpAndSettle();

      expect(find.text('Flex Page'), findsNothing);
      expect(find.text('User 123'), findsOneWidget);

      // Pop User
      controller.pop();
      await tester.pumpAndSettle();

      expect(find.text('User 123'), findsNothing);
      expect(find.text('Flex Page'), findsOneWidget);
    });
    
    testWidgets('Pushing same route multiple times adds to stack or what?', (tester) async {
      final controller = QLNavController(
        initialRoute: '/',
        routes: [
          QLRoute(
            path: '/',
            builder: (ctx, info) => const Text('Home'),
          ),
          QLRoute(
            path: '/product/:id',
            builder: (ctx, info) => Text('Product ${info.params['id']}'),
          ),
        ],
      );

      final delegate = QLRouterDelegate(controller);

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: delegate,
        routeInformationParser: _MockParser(),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(controller.stack.length, 1);

      controller.pushPath('/product/1');
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsOneWidget);
      expect(controller.stack.length, 2);

      controller.pushPath('/product/2');
      await tester.pumpAndSettle();
      expect(find.text('Product 2'), findsOneWidget);
      expect(controller.stack.length, 3);
      
      controller.pop();
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsOneWidget);
      expect(controller.stack.length, 2);
    });

    testWidgets('Tests query params and extra data', (tester) async {
      final controller = QLNavController(
        initialRoute: '/',
        routes: [
          QLRoute(
            path: '/',
            builder: (ctx, info) => const Text('Home'),
          ),
          QLRoute(
            path: '/search',
            builder: (ctx, info) => Text('Search ${info.query('q')} extra: ${info.extra}'),
          ),
        ],
      );

      final delegate = QLRouterDelegate(controller);

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: delegate,
        routeInformationParser: _MockParser(),
      ));

      await tester.pumpAndSettle();

      controller.pushPath('/search?q=hello', extra: 'world');
      await tester.pumpAndSettle();

      expect(find.text('Search hello extra: world'), findsOneWidget);
    });
  });
}

class _MockParser extends RouteInformationParser<QLRouteInfo> {
  @override
  Future<QLRouteInfo> parseRouteInformation(RouteInformation routeInformation) async {
    return QLRouteInfo(path: routeInformation.uri.path);
  }

  @override
  RouteInformation restoreRouteInformation(QLRouteInfo configuration) {
    return RouteInformation(uri: Uri.parse(configuration.path));
  }
}
