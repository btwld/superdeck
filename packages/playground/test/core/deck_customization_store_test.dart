import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Avoid runtime font fetching in tests while retaining the selected local
  // font-family name in generated text styles.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  DeckController newController() =>
      DeckController(deckLoader: MemoryDeckLoader(), options: DeckOptions());

  test('seeds DeckOptions on construction', () {
    final controller = newController();
    addTearDown(controller.dispose);

    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    expect(controller.options.value.baseStyle, isNotNull);
  });

  test('mutations push new options and notify once', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    final seeded = controller.options.value;
    var notifications = 0;
    store.addListener(() => notifications++);

    store.setSize(TextLevel.h1, 64);

    expect(store.level(TextLevel.h1).size, 64);
    expect(notifications, 1);
    expect(identical(controller.options.value, seeded), isFalse);
  });

  test('no-op mutation does not notify', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    final current = store.level(TextLevel.h1).size;
    var notifications = 0;
    store.addListener(() => notifications++);

    store.setSize(TextLevel.h1, current);

    expect(notifications, 0);
  });

  test('applies a generated palette and font system in one update', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);

    store.applyGeneratedStyle(_darkGeneratedStyle);

    expect(store.background, const Color(0xFF101828));
    expect(store.level(TextLevel.h1).color, const Color(0xFFF9FAFB));
    expect(store.level(TextLevel.h1).family, 'Montserrat');
    expect(store.level(TextLevel.p).color, const Color(0xFFD0D5DD));
    expect(store.level(TextLevel.p).family, 'Open Sans');
    expect(store.level(TextLevel.h1).size, 112);
    expect(store.level(TextLevel.p).size, 22);
    expect(
      controller.options.value.styles.keys,
      containsAll([
        'hero',
        'section',
        'content',
        'data',
        'quote',
        'visual',
        'closing',
      ]),
    );
    expect(notifications, 1);
  });

  test(
    'derives table, quote, code, and link styles for light and dark decks',
    () {
      for (final style in const [_darkGeneratedStyle, _lightGeneratedStyle]) {
        final controller = newController();
        addTearDown(controller.dispose);
        final store = DeckCustomizationStore(controller);
        addTearDown(store.dispose);

        store.applyGeneratedStyle(style);
        final baseStyle = controller.options.value.baseStyle!;

        expect(baseStyle.$table, isNotNull);
        expect(baseStyle.$blockquote, isNotNull);
        expect(baseStyle.$code, isNotNull);
        expect(baseStyle.$link, isNotNull);
      }
    },
  );

  testWidgets('uses treatment-specific typography and contrast-safe lists', (
    tester,
  ) async {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    store.applyGeneratedStyle(_darkGeneratedStyle);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    double h1Size(String treatment) => controller
        .options
        .value
        .styles[treatment]!
        .resolve(context)
        .spec
        .h1!
        .spec
        .style!
        .fontSize!;

    expect(h1Size('hero'), greaterThan(h1Size('section')));
    expect(h1Size('section'), greaterThan(h1Size('content')));
    expect(h1Size('content'), closeTo(57.6, 0.01));
    expect(h1Size('data'), lessThanOrEqualTo(72));
    expect(h1Size('visual'), closeTo(h1Size('content'), 0.01));
    expect(h1Size('closing'), closeTo(h1Size('section'), 0.01));

    Color? listTextColor(String treatment) => controller
        .options
        .value
        .styles[treatment]!
        .resolve(context)
        .spec
        .list!
        .spec
        .text!
        .spec
        .style!
        .color;

    expect(listTextColor('section'), _darkGeneratedStyle.accentContrast);
    expect(listTextColor('closing'), _darkGeneratedStyle.accentContrast);

    final table = controller.options.value.baseStyle!
        .resolve(context)
        .spec
        .table!
        .spec;
    expect(table.bodyStyle!.fontSize, lessThanOrEqualTo(20));
    expect(
      table.cellPadding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  });

  test('rejects an unavailable generated font with a precise error', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);

    expect(
      () => store.applyGeneratedStyle(
        _generatedStyle(
          headlineFamily: 'Invented Display',
          bodyFamily: 'Inter',
        ),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('not registered for headline use'),
        ),
      ),
    );
  });

  test('retains an application-registered bundled custom family', () {
    const custom = PresentationFontDescriptor(
      id: 'brand-sans',
      family: 'Brand Sans',
      description: 'Application brand font',
      source: PresentationFontSource.bundled,
      roles: {PresentationFontRole.headline, PresentationFontRole.body},
      weights: {400, 600, 700},
    );
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(
      controller,
      typographyCatalog: PresentationTypographyCatalog.withDefaults(
        registeredFonts: const [custom],
      ),
    );
    addTearDown(store.dispose);

    store.applyGeneratedStyle(
      _generatedStyle(headlineFamily: 'Brand Sans', bodyFamily: 'Brand Sans'),
    );

    expect(store.level(TextLevel.h1).family, 'Brand Sans');
    expect(store.level(TextLevel.p).family, 'Brand Sans');
  });
}

const _darkGeneratedStyle = GeneratedDeckStyle(
  background: Color(0xFF101828),
  surface: Color(0xFF1D2939),
  surfaceAlt: Color(0xFF344054),
  heading: Color(0xFFF9FAFB),
  body: Color(0xFFD0D5DD),
  accent: Color(0xFF6941C6),
  accentContrast: Color(0xFFFFFFFF),
  headlineFamily: 'Montserrat',
  bodyFamily: 'Open Sans',
  direction: 'editorial',
  density: 'balanced',
  typeScale: 'dramatic',
);

const _lightGeneratedStyle = GeneratedDeckStyle(
  background: Color(0xFFF8FAFC),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE2E8F0),
  heading: Color(0xFF0F172A),
  body: Color(0xFF334155),
  accent: Color(0xFF1D4ED8),
  accentContrast: Color(0xFFFFFFFF),
  headlineFamily: 'Playfair Display',
  bodyFamily: 'Source Serif 4',
  direction: 'minimal',
  density: 'spacious',
  typeScale: 'balanced',
);

GeneratedDeckStyle _generatedStyle({
  required String headlineFamily,
  required String bodyFamily,
}) => GeneratedDeckStyle(
  background: const Color(0xFF101828),
  surface: const Color(0xFF1D2939),
  surfaceAlt: const Color(0xFF344054),
  heading: const Color(0xFFF9FAFB),
  body: const Color(0xFFD0D5DD),
  accent: const Color(0xFF6941C6),
  accentContrast: const Color(0xFFFFFFFF),
  headlineFamily: headlineFamily,
  bodyFamily: bodyFamily,
  direction: 'technical',
  density: 'balanced',
  typeScale: 'balanced',
);
