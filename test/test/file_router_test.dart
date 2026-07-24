import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  test('QLFileRouteParser parses dynamic, catch-all and index files', () {
    final route =
        QLFileRouteParser.parse('pages/users/[id]/posts/index.yaml', 'pages')!;
    expect(route.routePath, '/users/:id/posts');
    expect(route.paramNames, contains('id'));

    final catchAll =
        QLFileRouteParser.parse('pages/blog/[...slug].yaml', 'pages')!;
    expect(catchAll.isCatchAll, isTrue);
    expect(catchAll.routePath, '/blog/*');
  });

  test('QLFileRouteParser skips special files and config files', () {
    expect(QLFileRouteParser.parse('pages/_layout.yaml', 'pages'), isNull);
    expect(QLFileRouteParser.parse('pages/ROUTES.yaml', 'pages'), isNull);
    expect(QLFileRouteParser.isSpecial('_middleware'), isTrue);
    expect(QLFileRouteParser.isPageFile('pages/home.yaml', 'pages'), isTrue);
  });
}
