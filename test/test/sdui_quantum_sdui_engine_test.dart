import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('SduiEncryptedPayload round-trips through JSON', () {
    final payload = SduiEncryptedPayload(
      version: 1,
      keyId: 'kid',
      iv: 'a',
      ct: 'b',
      tag: 'c',
      sig: 'd',
      timestamp: DateTime.utc(2024, 1, 1),
    );

    final json = payload.toJson();
    final decoded = SduiEncryptedPayload.fromJson(json);
    expect(decoded.keyId, 'kid');
    expect(decoded.isValid, isTrue);
    expect(decoded.toString(), contains('kid'));
  });

  test('SduiKeyStore registers, derives and removes keys', () {
    SduiKeyStore.instance.registerKey(
        kid: 'one', aesKey: testAesKey, sigKey: testSigKey, setActive: true);
    expect(SduiKeyStore.instance.activeKeyId, 'one');
    expect(SduiKeyStore.instance.hasKey('one'), isTrue);

    SduiKeyStore.instance.removeKey('one');
    expect(SduiKeyStore.instance.hasKey('one'), isFalse);
  });

  test('SduiReplayGuard rejects repeated nonces', () {
    expect(SduiReplayGuard.instance.claimNonce('nonce-1'), isTrue);
    expect(SduiReplayGuard.instance.claimNonce('nonce-1'), isFalse);
  });

  test('QuantumSduiEngine processes plain payload maps and JSON strings',
      () async {
    final engine = QuantumSduiEngine.instance;

    final blueprint1 =
        await engine.processRaw(basicBlueprint(text: 'hello', type: 'text'));
    expect(blueprint1, isA<QLBlueprint>());
    expect(blueprint1.props['text'], 'hello');

    final blueprint2 = await engine
        .processRaw(jsonEncode(basicBlueprint(text: 'world', type: 'text')));
    expect(blueprint2.type, blueprint1.type);
  });

  test('QuantumSduiEngine rejects invalid raw input types', () async {
    await expectLater(
      QuantumSduiEngine.instance.processRaw(123),
      throwsA(isA<QuantumSduiException>()),
    );
  });

  test('QuantumApiEngine performs GET/POST requests and caches responses',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var hits = 0;
    server.listen((request) async {
      hits += 1;
      request.response.headers.contentType = ContentType.json;
      if (request.method == 'GET') {
        request.response
            .write(jsonEncode({'ok': true, 'path': request.uri.path}));
      } else {
        final body = await utf8.decoder.bind(request).join();
        request.response
            .write(jsonEncode({'method': request.method, 'body': body}));
      }
      await request.response.close();
    });

    addTearDown(() async {
      await server.close(force: true);
      QuantumApiEngine.instance.clearCache();
    });

    QuantumApiEngine.instance
        .configure(baseUrl: 'http://127.0.0.1:${server.port}');
    final first = await QuantumApiEngine.instance.get('/hello');
    final second = await QuantumApiEngine.instance.get('/hello');
    expect(first['ok'], isTrue);
    expect(second['ok'], isTrue);
    expect(hits, 1);

    final post =
        await QuantumApiEngine.instance.post('/submit', {'name': 'Ada'});
    expect(post['method'], 'POST');
    expect(post['body'], contains('Ada'));
  });
}
