import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_example/src/widgets/shader_showcase.dart';

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for ${finder.describeMatch(Plurality.zero)}.');
}

void main() {
  test('exposes a balanced nineteen-effect catalog', () {
    expect(ShaderEffect.values, hasLength(19));
    expect(
      ShaderEffect.values.where((effect) => effect.mood == ShaderMood.subtle),
      hasLength(9),
    );
    expect(
      ShaderEffect.values.where((effect) => effect.mood == ShaderMood.dramatic),
      hasLength(10),
    );
  });

  test('catalog order matches both shader dispatch programs', () {
    expect(ShaderEffect.values.take(12).map((effect) => effect.name).toList(), [
      'aurora',
      'silk',
      'mesh',
      'caustics',
      'topography',
      'holographic',
      'smoke',
      'nebula',
      'ink',
      'plasma',
      'ripples',
      'vortex',
    ]);

    final thermalEffects = ShaderEffect.values
        .where((effect) => effect.usesThermalProgram)
        .toList();
    expect(thermalEffects.map((effect) => effect.name).toList(), [
      'heatAirflow',
      'heatHaze',
      'heatRadiance',
      'coldAirflow',
      'coldMist',
      'coldCrystal',
    ]);
    expect(thermalEffects.map((effect) => effect.programIndex), [
      0,
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(ShaderEffect.values.last, ShaderEffect.volumetricSmoke);
  });

  test('parse resolves names and rejects unknown values', () {
    expect(ShaderEffect.parse('smoke'), ShaderEffect.smoke);
    expect(ShaderEffect.parse('vortex'), ShaderEffect.vortex);
    expect(ShaderEffect.parse('heatAirflow'), ShaderEffect.heatAirflow);
    expect(ShaderEffect.parse('heatHaze'), ShaderEffect.heatHaze);
    expect(ShaderEffect.parse('heatRadiance'), ShaderEffect.heatRadiance);
    expect(ShaderEffect.parse('coldAirflow'), ShaderEffect.coldAirflow);
    expect(ShaderEffect.parse('coldMist'), ShaderEffect.coldMist);
    expect(ShaderEffect.parse('coldCrystal'), ShaderEffect.coldCrystal);
    expect(ShaderEffect.parse('volumetricSmoke'), ShaderEffect.volumetricSmoke);
    expect(() => ShaderEffect.parse('nope'), throwsArgumentError);
  });

  test('fromArgs applies defaults and overrides', () {
    final defaults = ShaderShowcase.fromArgs(const {});
    expect(defaults.effect, ShaderEffect.aurora);
    expect(defaults.showControls, isTrue);
    expect(defaults.showReadout, isFalse);
    expect(defaults.showStrengthControl, isFalse);
    expect(defaults.speed, 1);
    expect(defaults.intensity, 1);
    expect(defaults.quality, 0.5);

    final custom = ShaderShowcase.fromArgs(const {
      'effect': 'volumetricSmoke',
      'showControls': false,
      'showReadout': true,
      'showStrengthControl': true,
      'speed': 0.8,
      'intensity': 1.2,
      'quality': 0.75,
    });
    expect(custom.effect, ShaderEffect.volumetricSmoke);
    expect(custom.showControls, isFalse);
    expect(custom.showReadout, isTrue);
    expect(custom.showStrengthControl, isTrue);
    expect(custom.speed, 0.8);
    expect(custom.intensity, 1.2);
    expect(custom.quality, 0.75);
  });

  testWidgets('starts Volumetric Smoke and navigates out and back', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 800,
          height: 450,
          child: ShaderShowcase(effect: ShaderEffect.volumetricSmoke),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('volumetric-smoke-canvas')),
    );

    expect(
      find.byKey(const ValueKey('shader-showcase-volumetricSmoke')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('volumetric-smoke-canvas')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('shader-showcase-canvas')), findsNothing);

    await tester.tap(find.byTooltip('Next shader'));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('shader-showcase-canvas')),
    );
    expect(
      find.byKey(const ValueKey('shader-showcase-aurora')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Previous shader'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('shader-showcase-volumetricSmoke')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('volumetric-smoke-canvas')),
      findsOneWidget,
    );
  });

  testWidgets('switches between shader effects', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 800, height: 450, child: ShaderShowcase()),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('shader-showcase-aurora')),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Next shader')).label,
      'Next shader',
    );

    for (var step = 0; step < 6; step++) {
      await tester.tap(find.byTooltip('Next shader'));
      await tester.pump();
    }

    expect(find.byKey(const ValueKey('shader-showcase-smoke')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('loads and switches between hot and cold airflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 800,
          height: 450,
          child: ShaderShowcase(
            effect: ShaderEffect.heatAirflow,
            showControls: false,
            showReadout: true,
            showStrengthControl: true,
            intensity: 0.25,
          ),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('shader-showcase-canvas')),
    );
    expect(
      find.byKey(const ValueKey('shader-showcase-heatAirflow')),
      findsOneWidget,
    );
    expect(find.text('28'), findsOneWidget);
    expect(find.text('HEATING'), findsOneWidget);
    expect(find.text('AIRFLOW  LOW'), findsOneWidget);

    final sliderFinder = find.byKey(const ValueKey('airflow-strength-slider'));
    expect(sliderFinder, findsOneWidget);
    expect(tester.widget<Slider>(sliderFinder).value, 0.25);

    final sliderBounds = tester.getRect(sliderFinder);
    await tester.tapAt(Offset(sliderBounds.right - 16, sliderBounds.center.dy));
    await tester.pump();

    expect(sliderFinder, findsOneWidget);
    expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.9));
    expect(find.text('AIRFLOW  LOW'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));

    expect(
      tester.widget<Text>(find.textContaining('AIRFLOW  ')).data,
      'AIRFLOW  HIGH',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 800,
          height: 450,
          child: ShaderShowcase(
            effect: ShaderEffect.coldAirflow,
            showControls: false,
            showReadout: true,
            showStrengthControl: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('shader-showcase-coldAirflow')),
      findsOneWidget,
    );
    expect(find.text('18'), findsOneWidget);
    expect(find.text('COOLING'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('airflow-strength-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('shader-showcase-canvas')),
      findsOneWidget,
    );
  });

  testWidgets('previous wraps from the first effect to the last', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 800, height: 450, child: ShaderShowcase()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('shader-showcase-aurora')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Previous shader'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('shader-showcase-volumetricSmoke')),
      findsOneWidget,
    );
  });
}
