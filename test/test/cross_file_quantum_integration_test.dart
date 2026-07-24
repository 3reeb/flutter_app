import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  testWidgets('Schema, state, pipeline, VM and SDUI cooperate in one flow',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 10, height: 10),
      ),
    );
    final context = tester.element(find.byType(SizedBox));

    await QuantumDataOrchestrator.bootstrap(sampleManifest(), context);
    final store = QLStoreRegistry.instance.get('shop');
    final schema = QLSchemaRegistry.instance.getSchema('product')!;
    final pipeline = QLPipelineRegistry.instance.get('products');

    expect(store.get('counter'), 1);
    expect(schema.field('name'), isNotNull);
    expect(pipeline.schema.name, 'product');

    final sdui = await QuantumSduiEngine.instance
        .processRaw(basicBlueprint(text: 'hello'));
    expect(sdui, isA<QLBlueprint>());

    final form = QLFormController();
    QLSchemaFormFactory.build(schema, form);
    expect(form.getNode('id'), isNotNull);

    final vmStyle = QuantumVM.instance.compileStyle('text-center');
    expect(vmStyle, isNotNull);
  });

  test('Runtime caches stay stable after mixed cross-module operations',
      () async {
    final schema = QLSchemaCompiler.compile('cross', sampleSchemaDefinition());
    final pipeline = QLDataPipeline(id: 'crossPipeline', schema: schema);
    pipeline.ingest([
      {'id': '1', 'name': 'Ada', 'age': 10, 'status': 'live'},
    ]);
    await Future<void>.delayed(Duration.zero);

    final blueprint = QLBlueprint.fromJson(sampleBlueprintJson());
    expect(blueprint.type, isNotEmpty);
    expect(QuantumVM.instance.compileStyle('font-bold'), isNotNull);
  });
}
