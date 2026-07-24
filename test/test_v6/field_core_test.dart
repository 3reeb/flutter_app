import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

QLBlueprint _fieldNode(
  String subtype, {
  required String id,
  String? bind,
  String? label,
  String? placeholder,
  Map<String, dynamic> extraProps = const {},
  List<QLBlueprint> children = const [],
}) {
  return QLBlueprint(
    type: 'field:$subtype',
    props: <String, dynamic>{
      'id': id,
      if (bind != null) 'bind': bind,
      if (label != null) 'label': label,
      if (placeholder != null) 'placeholder': placeholder,
      ...extraProps,
    },
    children: children,
  );
}

Future<void> _pumpField(
  WidgetTester tester,
  QLBlueprint node, {
  QLDataStore? store,
  double width = 420,
}) async {
  final QLDataStore effectiveStore =
      store ?? QLStoreRegistry.instance.defaultStore;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QLDataScope(
          localStore: effectiveStore,
          localData: const <String, dynamic>{},
          child: Builder(
            builder: (context) => Center(
              child: SizedBox(
                width: width,
                child: QuantumVM.instance.renderWidget(context, node),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

EditableText _editableText(WidgetTester tester,
    {Finder? within, int index = 0}) {
  final Finder finder = within == null
      ? find.byType(EditableText)
      : find.descendant(of: within, matching: find.byType(EditableText));
  return tester.widget<EditableText>(finder.at(index));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    QuantumVM.instance.initialize();
    registerOmniComponents(QuantumVM.instance);
  });

  setUp(() {
    clearQuantumInputRegistry();
    QLStoreRegistry.instance.clearAll();
  });

  tearDown(() {
    clearQuantumInputRegistry();
    QLStoreRegistry.instance.clearAll();
  });

  group('field core registrations', () {
    test('registers the expected aliases for field subtypes', () {
      final vm = QuantumVM.instance;
      expect(vm.getAlias('text_field')?['type'], 'field:text');
      expect(vm.getAlias('textarea')?['type'], 'field:multiline');
      expect(vm.getAlias('email_field')?['type'], 'field:email');
      expect(vm.getAlias('password_field')?['type'], 'field:password');
      expect(vm.getAlias('number_field')?['type'], 'field:number');
      expect(vm.getAlias('search_field')?['type'], 'field:search');
      expect(vm.getAlias('date_field')?['type'], 'field:date');
      expect(vm.getAlias('select_field')?['type'], 'field:select');
      expect(vm.getAlias('toggle')?['type'], 'field:toggle');
      expect(vm.getAlias('slider')?['type'], 'field:slider');
    });

    test('unknown aliases are not silently invented', () {
      expect(QuantumVM.instance.getAlias('not_a_real_field_alias'), isNull);
    });
  });

  group('text field shell behavior', () {
    testWidgets('shows placeholder when empty, then focuses and syncs store',
        (tester) async {
      final store = QLDataStore(namespace: 'field-text-empty');
      await _pumpField(
        tester,
        _fieldNode(
          'text',
          id: 'name_field',
          bind: 'profile.name',
          label: 'Name',
          placeholder: 'Enter full name',
        ),
        store: store,
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Enter full name'), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Ada Lovelace');
      await tester.pumpAndSettle();

      expect(store.get('profile.name'), 'Ada Lovelace');
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('respects readOnly and does not mutate when edited directly',
        (tester) async {
      final store = QLDataStore(namespace: 'field-text-readonly');
      store.set('profile.handle', 'locked-value');

      await _pumpField(
        tester,
        _fieldNode(
          'text',
          id: 'handle_field',
          bind: 'profile.handle',
          label: 'Handle',
          extraProps: const <String, dynamic>{'readOnly': true},
        ),
        store: store,
      );

      final editable = _editableText(tester);
      expect(editable.controller.text, 'locked-value');

      await tester.enterText(find.byType(EditableText), 'changed-value');
      await tester.pumpAndSettle();

      expect(store.get('profile.handle'), 'locked-value');
    });

    testWidgets(
        'maps keyboard type, multiline settings, and password obscuring correctly',
        (tester) async {
      final cases = <({
        String subtype,
        Map<String, dynamic> extraProps,
        TextInputType expectedType,
        bool obscure,
        int minLines,
        int maxLines,
      })>[
        (
          subtype: 'email',
          extraProps: const <String, dynamic>{},
          expectedType: TextInputType.emailAddress,
          obscure: false,
          minLines: 1,
          maxLines: 1,
        ),
        (
          subtype: 'tel',
          extraProps: const <String, dynamic>{},
          expectedType: TextInputType.phone,
          obscure: false,
          minLines: 1,
          maxLines: 1,
        ),
        (
          subtype: 'url',
          extraProps: const <String, dynamic>{},
          expectedType: TextInputType.url,
          obscure: false,
          minLines: 1,
          maxLines: 1,
        ),
        (
          subtype: 'number',
          extraProps: const <String, dynamic>{'decimal': true},
          expectedType: const TextInputType.numberWithOptions(decimal: true),
          obscure: false,
          minLines: 1,
          maxLines: 1,
        ),
        (
          subtype: 'password',
          extraProps: const <String, dynamic>{},
          expectedType: TextInputType.text,
          obscure: true,
          minLines: 1,
          maxLines: 1,
        ),
        (
          subtype: 'textarea',
          extraProps: const <String, dynamic>{'minLines': 4, 'maxLines': 9},
          expectedType: TextInputType.multiline,
          obscure: false,
          minLines: 4,
          maxLines: 9,
        ),
      ];

      for (final testCase in cases) {
        final store = QLDataStore(namespace: 'field-${testCase.subtype}');
        final id = '${testCase.subtype}_field';
        store.set('value.$id', 'seed');

        await _pumpField(
          tester,
          _fieldNode(
            testCase.subtype,
            id: id,
            bind: 'value.$id',
            label: testCase.subtype,
            extraProps: testCase.extraProps,
          ),
          store: store,
        );

        final editable = _editableText(tester);
        expect(editable.keyboardType, testCase.expectedType);
        expect(editable.obscureText, testCase.obscure);
        expect(editable.minLines, testCase.minLines);
        expect(editable.maxLines, testCase.maxLines);
        expect(store.get('value.$id'), 'seed');

        clearQuantumInputRegistry();
        QLStoreRegistry.instance.clearAll();
      }
    });

    testWidgets('search fields show a clear affordance and clear the binding',
        (tester) async {
      final store = QLDataStore(namespace: 'field-search');
      store.set('query', 'openai');

      await _pumpField(
        tester,
        _fieldNode(
          'search',
          id: 'search_field',
          bind: 'query',
          label: 'Search',
          placeholder: 'Type to search',
        ),
        store: store,
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(store.get('query'), '');
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('toggle and checkbox family', () {
    testWidgets('toggle flips the bound store and responds to keyboard input',
        (tester) async {
      final store = QLDataStore(namespace: 'field-toggle');
      store.set('feature.enabled', false);

      await _pumpField(
        tester,
        _fieldNode(
          'toggle',
          id: 'toggle_feature',
          bind: 'feature.enabled',
          label: 'Enable feature',
        ),
        store: store,
      );

      expect(store.get('feature.enabled'), isFalse);
      await tester.tap(find.byType(QLRawToggle));
      await tester.pumpAndSettle();
      expect(store.get('feature.enabled'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(store.get('feature.enabled'), isFalse);
    });

    testWidgets('disabled toggle does not change state on tap', (tester) async {
      final store = QLDataStore(namespace: 'field-toggle-disabled');
      store.set('feature.enabled', false);

      await _pumpField(
        tester,
        _fieldNode(
          'toggle',
          id: 'toggle_disabled',
          bind: 'feature.enabled',
          label: 'Locked toggle',
          extraProps: const <String, dynamic>{'disabled': true},
        ),
        store: store,
      );

      await tester.tap(find.byType(QLRawToggle));
      await tester.pumpAndSettle();
      expect(store.get('feature.enabled'), isFalse);
    });

    testWidgets('checkbox and radio preserve the bound boolean contract',
        (tester) async {
      final checkboxStore = QLDataStore(namespace: 'field-checkbox');
      checkboxStore.set('accept', false);

      await _pumpField(
        tester,
        _fieldNode(
          'checkbox',
          id: 'accept_checkbox',
          bind: 'accept',
          label: 'Accept terms',
        ),
        store: checkboxStore,
      );
      await tester.tap(find.byType(QLRawToggle));
      await tester.pumpAndSettle();
      expect(checkboxStore.get('accept'), isTrue);

      final radioStore = QLDataStore(namespace: 'field-radio');
      radioStore.set('plan.basic', false);
      await _pumpField(
        tester,
        _fieldNode(
          'radio',
          id: 'plan_radio',
          bind: 'plan.basic',
          label: 'Basic plan',
        ),
        store: radioStore,
      );
      await tester.tap(find.byType(QLRawToggle));
      await tester.pumpAndSettle();
      expect(radioStore.get('plan.basic'), isTrue);
    });
  });

  group('slider family', () {
    testWidgets('slider drags, snaps to divisions, and clamps at the bounds',
        (tester) async {
      final store = QLDataStore(namespace: 'field-slider');
      store.set('volume', 25.0);

      await _pumpField(
        tester,
        _fieldNode(
          'slider',
          id: 'volume_slider',
          bind: 'volume',
          label: 'Volume',
          extraProps: const <String, dynamic>{
            'min': 0.0,
            'max': 100.0,
            'divisions': 4,
          },
        ),
        store: store,
        width: 360,
      );

      final initial = store.get('volume') as num;
      expect(initial.toDouble(), 25.0);

      await tester.drag(find.byType(QLRawSlider), const Offset(280, 0));
      await tester.pumpAndSettle();

      final afterRight = (store.get('volume') as num).toDouble();
      expect(afterRight, inInclusiveRange(75.0, 100.0));

      await tester.drag(find.byType(QLRawSlider), const Offset(-999, 0));
      await tester.pumpAndSettle();

      final afterLeft = (store.get('volume') as num).toDouble();
      expect(afterLeft, 0.0);
    });

    testWidgets('disabled slider ignores drag gestures', (tester) async {
      final store = QLDataStore(namespace: 'field-slider-disabled');
      store.set('volume', 25.0);

      await _pumpField(
        tester,
        _fieldNode(
          'slider',
          id: 'volume_slider_disabled',
          bind: 'volume',
          label: 'Volume',
          extraProps: const <String, dynamic>{
            'min': 0.0,
            'max': 100.0,
            'disabled': true,
          },
        ),
        store: store,
        width: 360,
      );

      await tester.drag(find.byType(QLRawSlider), const Offset(280, 0));
      await tester.pumpAndSettle();
      expect((store.get('volume') as num).toDouble(), 25.0);
    });
  });

  group('inline and rich text field modes', () {
    testWidgets('cell mode enters edit mode on double tap and submits to store',
        (tester) async {
      final store = QLDataStore(namespace: 'field-cell');
      store.set('sheet.a1', 'Alpha');

      await _pumpField(
        tester,
        _fieldNode(
          'cell',
          id: 'cell_a1',
          bind: 'sheet.a1',
        ),
        store: store,
      );

      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Alpha'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(store.get('sheet.a1'), 'Beta');
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('rich text mode keeps a toolbar and propagates edits',
        (tester) async {
      final store = QLDataStore(namespace: 'field-rich-text');
      store.set('doc.body', 'Hello');

      await _pumpField(
        tester,
        _fieldNode(
          'rich_text',
          id: 'doc_rich_text',
          bind: 'doc.body',
        ),
        store: store,
      );

      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underlined), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hello world');
      await tester.pumpAndSettle();

      expect(store.get('doc.body'), 'Hello world');
    });
  });

  testWidgets('unknown field subtype produces a visible error message',
      (tester) async {
    final store = QLDataStore(namespace: 'field-unknown');

    await _pumpField(
      tester,
      _fieldNode(
        'made_up_subtype',
        id: 'unknown_field',
      ),
      store: store,
    );

    expect(find.textContaining('Unknown field subtype:'), findsOneWidget);
  });
}
