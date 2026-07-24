import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:quantum_layout/quantum.dart';

final Uint8List testAesKey = Uint8List.fromList(
  List<int>.generate(32, (i) => (i + 1) & 0xff),
);

final Uint8List testSigKey = Uint8List.fromList(
  List<int>.generate(32, (i) => (255 - i) & 0xff),
);

void resetQuantumRuntime() {
  try {
    QLStoreRegistry.instance.clearAll();
  } catch (_) {}
  try {
    QLSliceRegistry.instance.clear();
  } catch (_) {}
  try {
    QLSliceRegistry.actionRegistrar = null;
  } catch (_) {}
  try {
    QLModuleRegistry.instance.clear();
  } catch (_) {}
  try {
    QLSchemaRegistry.instance.clear();
  } catch (_) {}
  try {
    QuantumSduiEngine.instance.clearCache();
  } catch (_) {}
  try {
    SduiKeyStore.instance.clear();
  } catch (_) {}
  try {
    SduiReplayGuard.instance.clear();
  } catch (_) {}
  try {
    QuantumApiEngine.instance.clearCache();
  } catch (_) {}
  try {
    QuantumVM.instance.clearRuntimeCaches();
  } catch (_) {}
  try {
    QuantumVM.instance.dispose();
  } catch (_) {}
  try {
    QEngine.instance.dispose();
  } catch (_) {}
  try {
    QuantumVM.instance.initialize(workerThreads: 1);
  } catch (_) {}
}

void registerTestKeys({String kid = 'test-kid'}) {
  SduiKeyStore.instance.registerKey(
    kid: kid,
    aesKey: testAesKey,
    sigKey: testSigKey,
    setActive: true,
  );
}

Map<String, dynamic> basicBlueprint({
  String text = 'Hello',
  String type = 'text',
}) {
  return <String, dynamic>{
    'ui': <String, dynamic>{
      'type': type,
      'props': <String, dynamic>{'text': text},
    },
  };
}

Map<String, dynamic> sampleSchemaDefinition() {
  return <String, dynamic>{
    'id': <String, dynamic>{
      'type': 'string',
      'required': true,
      'indexed': true,
    },
    'name': <String, dynamic>{
      'type': 'string',
      'required': true,
      'min': 2,
      'max': 40,
    },
    'age': <String, dynamic>{
      'type': 'number',
      'min': 0,
      'max': 130,
    },
    'active': <String, dynamic>{'type': 'boolean'},
    'status': <String, dynamic>{
      'type': 'enum',
      'options': ['draft', 'live', 'archived'],
      'required': true,
    },
    'profile': <String, dynamic>{
      'type': 'object',
      'fields': <String, dynamic>{
        'city': <String, dynamic>{'type': 'string'},
        'zip': <String, dynamic>{'type': 'string'},
      },
    },
    'tags': <String, dynamic>{
      'type': 'array',
      'items': <String, dynamic>{'type': 'string'},
    },
    'score': <String, dynamic>{
      'type': 'number',
      'computed': true,
      'compute': (Map<String, dynamic> record) =>
          ((record['age'] as num?)?.toDouble() ?? 0.0) + 10.0,
    },
  };
}

Map<String, dynamic> sampleBlueprintJson() {
  return <String, dynamic>{
    'type': 'box:col',
    'props': <String, dynamic>{'gap': 8},
    'children': <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'text',
        'props': {'text': 'one'}
      },
      <String, dynamic>{
        'type': 'text',
        'props': {'text': 'two'}
      },
    ],
  };
}

Map<String, dynamic> sampleManifest() {
  return <String, dynamic>{
    'module': 'shop',
    'state': <String, dynamic>{
      'counter': 1,
      'name': 'Ada',
      'doubleCounter': <String, dynamic>{
        'type': 'derived',
        'compute': 'counter * 2',
      },
    },
    'schemas': <String, dynamic>{
      'product': sampleSchemaDefinition(),
    },
    'pipelines': <String, dynamic>{
      'products': <String, dynamic>{
        'schema': 'product',
        'pageSize': 10,
        'autoFetch': false,
      },
    },
    'actions': <String, dynamic>{
      'mark': [
        <String, dynamic>{'action': 'state.set', 'key': 'flag', 'value': true}
      ],
    },
  };
}

File fixtureFile(String relativePath) => File('test/fixtures/$relativePath');

List<File> listJsonFixtures([String dir = 'test/fixtures/sdui']) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return const <File>[];
  final files = directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.json'))
      .toList(growable: false)
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String readFixtureJson(String relativePath) =>
    fixtureFile(relativePath).readAsStringSync();

Map<String, dynamic> parseFixtureJson(String relativePath) =>
    jsonDecode(readFixtureJson(relativePath)) as Map<String, dynamic>;
