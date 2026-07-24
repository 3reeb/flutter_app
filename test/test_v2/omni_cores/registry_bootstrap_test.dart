
import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  setUpAll(() {
    bootstrapQuantum(includeConnect: false);
  });

  group('Quantum VM bootstrap', () {
    test('registry kinds stay stable', () {
      expect(
        vm.registeredRegistryKinds(),
        equals(<String>[
          'action',
          'plugin',
          'alias',
          'slottype',
          'slotnodes',
          'module',
          'macro',
          'template',
          'layout',
          'schema',
          'pipe',
        ]),
      );
    });

    test('main bootstrap does not register connect automatically', () {
      expect(vm.registryEntry('connect', kind: 'widget'), isNull);
    });

    test('main bootstrap registers alias entries', () {
      expect(vm.registryEntries(kind: 'alias'), isNotEmpty);
    });

    test('main bootstrap registers plugin entries', () {
      expect(vm.registryEntries(kind: 'widget'), isNotEmpty);
    });

      test('box core plugin is registered', () {
        final entry = vm.registryEntry("box", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "box");
        expect(entry.description, "Universal structural container");
      });

      test('box core tags stay aligned', () {
        final entry = vm.registryEntry("box", kind: 'widget')!;
        expect(entry.tags, equals(["core", "container", "box"]));
      });

      test('action core plugin is registered', () {
        final entry = vm.registryEntry("action", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "action");
        expect(entry.description, "Interactive action trigger");
      });

      test('action core tags stay aligned', () {
        final entry = vm.registryEntry("action", kind: 'widget')!;
        expect(entry.tags, equals(["core", "action"]));
      });

      test('field core plugin is registered', () {
        final entry = vm.registryEntry("field", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "field");
        expect(entry.description, "Universal field and control renderer");
      });

      test('field core tags stay aligned', () {
        final entry = vm.registryEntry("field", kind: 'widget')!;
        expect(entry.tags, equals(["core", "field", "input"]));
      });

      test('text core plugin is registered', () {
        final entry = vm.registryEntry("text", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "text");
        expect(entry.description, "Typography and text rendering core");
      });

      test('text core tags stay aligned', () {
        final entry = vm.registryEntry("text", kind: 'widget')!;
        expect(entry.tags, equals(["core", "text"]));
      });

      test('media core plugin is registered', () {
        final entry = vm.registryEntry("media", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "media");
        expect(entry.description, "Media and asset presentation core");
      });

      test('media core tags stay aligned', () {
        final entry = vm.registryEntry("media", kind: 'widget')!;
        expect(entry.tags, equals(["core", "media"]));
      });

      test('visual core plugin is registered', () {
        final entry = vm.registryEntry("visual", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "visual");
        expect(entry.description, "Top-level visual composition core");
      });

      test('visual core tags stay aligned', () {
        final entry = vm.registryEntry("visual", kind: 'widget')!;
        expect(entry.tags, equals(["core", "visual"]));
      });

      test('hook core plugin is registered', () {
        final entry = vm.registryEntry("hook", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "hook");
        expect(entry.description, "Top-level hook and lifecycle core");
      });

      test('hook core tags stay aligned', () {
        final entry = vm.registryEntry("hook", kind: 'widget')!;
        expect(entry.tags, equals(["core", "hook"]));
      });

      test('data core plugin is registered', () {
        final entry = vm.registryEntry("data", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "data");
        expect(entry.description, "Data access and reactive data core");
      });

      test('data core tags stay aligned', () {
        final entry = vm.registryEntry("data", kind: 'widget')!;
        expect(entry.tags, equals(["core", "data"]));
      });

      test('portal core plugin is registered', () {
        final entry = vm.registryEntry("portal", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "portal");
        expect(entry.description, "Overlay, dialog, and portal surfaces");
      });

      test('portal core tags stay aligned', () {
        final entry = vm.registryEntry("portal", kind: 'widget')!;
        expect(entry.tags, equals(["core", "portal"]));
      });

      test('control core plugin is registered', () {
        final entry = vm.registryEntry("control", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "control");
        expect(entry.description, "Control-flow and orchestration core");
      });

      test('control core tags stay aligned', () {
        final entry = vm.registryEntry("control", kind: 'widget')!;
        expect(entry.tags, equals(["core", "control"]));
      });

      test('canvas core plugin is registered', () {
        final entry = vm.registryEntry("canvas", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "canvas");
        expect(entry.description, "Canvas and GPU rendering core");
      });

      test('canvas core tags stay aligned', () {
        final entry = vm.registryEntry("canvas", kind: 'widget')!;
        expect(entry.tags, equals(["core", "canvas"]));
      });

      test('system core plugin is registered', () {
        final entry = vm.registryEntry("system", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "system");
        expect(entry.description, "System services, observers, and runtime tools");
      });

      test('system core tags stay aligned', () {
        final entry = vm.registryEntry("system", kind: 'widget')!;
        expect(entry.tags, equals(["core", "system"]));
      });

      test('template core plugin is registered', () {
        final entry = vm.registryEntry("template", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "template");
        expect(entry.description, "Template composition core");
      });

      test('template core tags stay aligned', () {
        final entry = vm.registryEntry("template", kind: 'widget')!;
        expect(entry.tags, equals(["core", "template"]));
      });

      test('layout core plugin is registered', () {
        final entry = vm.registryEntry("layout", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "layout");
        expect(entry.description, "Layout composition core");
      });

      test('layout core tags stay aligned', () {
        final entry = vm.registryEntry("layout", kind: 'widget')!;
        expect(entry.tags, equals(["core", "layout"]));
      });

      test('decoration core plugin is registered', () {
        final entry = vm.registryEntry("decoration", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "decoration");
        expect(entry.description, "Decorative styling and semantic adornment core");
      });

      test('decoration core tags stay aligned', () {
        final entry = vm.registryEntry("decoration", kind: 'widget')!;
        expect(entry.tags, equals(["core", "decoration"]));
      });

      test('chart core plugin is registered', () {
        final entry = vm.registryEntry("chart", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "chart");
        expect(entry.description, "Chart rendering and visualization core");
      });

      test('chart core tags stay aligned', () {
        final entry = vm.registryEntry("chart", kind: 'widget')!;
        expect(entry.tags, equals(["core", "chart", "visualization"]));
      });

      test('animation core plugin is registered', () {
        final entry = vm.registryEntry("animation", kind: 'widget');
        expect(entry, isNotNull);
        expect(entry!.kind, 'widget');
        expect(entry.name, "animation");
        expect(entry.description, "Animation orchestration and motion core");
      });

      test('animation core tags stay aligned', () {
        final entry = vm.registryEntry("animation", kind: 'widget')!;
        expect(entry.tags, equals(["core", "animation", "motion"]));
      });

      test('main alias registry contains template aliases', () {
        expect(vm.registryEntries(kind: 'alias', query: 'template').length, greaterThan(0));
      });
    });
  }


