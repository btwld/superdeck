import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart' show BoxSpec;
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/features/ai/quick_agent/domain/generated_deck_style_mapper.dart';
import 'package:superdeck/src/styling/block_variant.dart'
    show BlockVariantScope;
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
      for (final style in [_darkGeneratedStyle, _lightGeneratedStyle]) {
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
    final tablePadding = table.cellPadding!;
    expect(tablePadding.left, closeTo(13.2, 0.01));
    expect(tablePadding.top, closeTo(6.6, 0.01));
  });

  testWidgets('applies the selected theme runtime recipe end to end', (
    tester,
  ) async {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    final catalog = PresentationThemeCatalog.withDefaults();
    final typography = PresentationTypographyCatalog.withDefaults();
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

    double resolvedCodeRadius(String themeId) {
      final descriptor = catalog.current(themeId)!;
      final resolved = catalog.resolve(
        id: descriptor.id,
        version: descriptor.version,
        typographyCatalog: typography,
      );
      store.applyGeneratedStyle(resolved.toGeneratedDeckStyle());
      final codeContainer = controller.options.value.baseStyle!
          .resolve(context)
          .spec
          .code!
          .spec
          .container!
          .spec;
      final decoration = codeContainer.decoration! as BoxDecoration;
      final borderRadius = decoration.borderRadius! as BorderRadius;

      return borderRadius.topLeft.x;
    }

    expect(resolvedCodeRadius('technical-paper'), 6);
    expect(resolvedCodeRadius('civic-blueprint'), 0);
  });

  testWidgets('renders recipe-owned spacing, components, and treatments', (
    tester,
  ) async {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    final catalog = PresentationThemeCatalog.withDefaults();
    final descriptor = catalog.current('technical-paper')!;
    final resolved = catalog.resolve(
      id: descriptor.id,
      version: descriptor.version,
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );
    store.applyGeneratedStyle(resolved.toGeneratedDeckStyle());
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

    final base = controller.options.value.baseStyle!.resolve(context).spec;
    final slidePadding = base.slideContainer.spec.padding! as EdgeInsets;
    expect(slidePadding.left, closeTo(53.2, 0.01));
    expect(slidePadding.top, closeTo(53.2, 0.01));
    final cellPadding = base.table!.spec.cellPadding!;
    expect(cellPadding.left, closeTo(11.4, 0.01));
    expect(cellPadding.top, closeTo(5.7, 0.01));
    expect(base.table!.spec.border!.top.width, 1.5);
    final quoteDecoration = base.blockquote!.spec.decoration!;
    expect((quoteDecoration.border! as Border).left.width, 4);
    final codePadding = base.code!.spec.container!.spec.padding! as EdgeInsets;
    expect(codePadding.left, closeTo(22.8, 0.01));
    expect(base.link!.color, resolved.toGeneratedDeckStyle().accent);

    final data = controller.options.value.styles['data']!.resolve(context).spec;
    expect(data.h1!.spec.style!.fontSize, closeTo(52.48, 0.01));
    final dataSlide = data.slideContainer.spec.decoration! as BoxDecoration;
    expect(dataSlide.color, resolved.toGeneratedDeckStyle().surface);
    final dataBlock = data.blockContainer.spec.decoration! as BoxDecoration;
    expect(dataBlock.color, resolved.toGeneratedDeckStyle().surface);
    expect((dataBlock.border! as Border).top.width, 1.5);
  });

  testWidgets('keeps generated hero slides chrome-free and unpadded', (
    tester,
  ) async {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    final descriptor = defaultPresentationThemeCatalog.current(
      'editorial-midnight',
    )!;
    final resolved = defaultPresentationThemeCatalog.resolve(
      id: descriptor.id,
      version: descriptor.version,
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );
    store.applyGeneratedStyle(resolved.toGeneratedDeckStyle());
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

    final options = controller.options.value;
    final hero = options.styles['hero']!.resolve(context).spec;

    expect(options.parts.header, isNull);
    expect(options.parts.footer, isNull);
    expect(hero.blockContainer.spec.padding, EdgeInsets.zero);
  });

  testWidgets(
    'keeps the bold hero display scale within its split-slide frame',
    (tester) async {
      final controller = newController();
      addTearDown(controller.dispose);
      final store = DeckCustomizationStore(controller);
      addTearDown(store.dispose);
      final descriptor = defaultPresentationThemeCatalog.current(
        'bold-product',
      )!;
      final resolved = defaultPresentationThemeCatalog.resolve(
        id: descriptor.id,
        version: descriptor.version,
        typographyCatalog: PresentationTypographyCatalog.withDefaults(),
      );
      store.applyGeneratedStyle(resolved.toGeneratedDeckStyle());
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

      final hero = controller.options.value.styles['hero']!
          .resolve(context)
          .spec;

      expect(hero.h1!.spec.style!.fontSize, 112);
    },
  );

  testWidgets('styles built-in and custom element containers safely', (
    tester,
  ) async {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    final catalog = PresentationThemeCatalog.withDefaults();
    final descriptor = catalog.current('technical-paper')!;
    final resolved = catalog.resolve(
      id: descriptor.id,
      version: descriptor.version,
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );
    store.applyGeneratedStyle(resolved.toGeneratedDeckStyle());

    Future<BoxSpec> resolveBlock(String blockName, {String? treatment}) async {
      late BoxSpec spec;
      await tester.pumpWidget(
        MaterialApp(
          home: BlockVariantScope(
            name: blockName,
            child: Builder(
              builder: (context) {
                final style = treatment == null
                    ? controller.options.value.baseStyle!
                    : controller.options.value.styles[treatment]!;
                spec = style.resolve(context).spec.blockContainer.spec;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      return spec;
    }

    final image = await resolveBlock('image');
    expect(image.padding, EdgeInsets.zero);
    expect(image.margin, EdgeInsets.zero);
    expect((image.decoration! as BoxDecoration).color, Colors.transparent);

    final webview = await resolveBlock('webview');
    expect(webview.padding, EdgeInsets.zero);
    final webviewDecoration = webview.decoration! as BoxDecoration;
    expect(webviewDecoration.color, resolved.toGeneratedDeckStyle().surface);
    expect((webviewDecoration.border! as Border).top.width, 1.5);
    expect(webviewDecoration.borderRadius, BorderRadius.circular(6));

    final qrcode = await resolveBlock('qrcode');
    final qrPadding = qrcode.padding! as EdgeInsets;
    expect(qrPadding.left, closeTo(22.8, 0.01));
    expect(
      (qrcode.decoration! as BoxDecoration).color,
      resolved.toGeneratedDeckStyle().surfaceAlt,
    );

    final custom = await resolveBlock('sales_chart', treatment: 'visual');
    final customDecoration = custom.decoration! as BoxDecoration;
    expect(customDecoration.color, resolved.toGeneratedDeckStyle().surface);
    expect((customDecoration.border! as Border).top.width, 1.5);
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

  test('uses an explicitly registered weight instead of synthesizing one', () {
    final controller = newController();
    addTearDown(controller.dispose);
    final store = DeckCustomizationStore(controller);
    addTearDown(store.dispose);
    final catalog = PresentationThemeCatalog.withDefaults();
    final descriptor = catalog.current('playful-learning')!;
    final resolved = catalog.resolve(
      id: descriptor.id,
      version: descriptor.version,
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );

    store.applyGeneratedStyle(resolved.toGeneratedDeckStyle());

    expect(store.level(TextLevel.h1).family, 'Lobster');
    expect(store.level(TextLevel.h1).weight, 400);
    expect(store.level(TextLevel.h2).weight, 400);
  });

  testWidgets('resolves every theme to exact registered families and weights', (
    tester,
  ) async {
    final controller = newController();
    addTearDown(controller.dispose);
    final typography = PresentationTypographyCatalog.withDefaults();
    final store = DeckCustomizationStore(
      controller,
      typographyCatalog: typography,
    );
    addTearDown(store.dispose);
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

    for (final theme in defaultPresentationThemeCatalog.currentThemes) {
      final resolved = defaultPresentationThemeCatalog.resolve(
        id: theme.id,
        version: theme.version,
        typographyCatalog: typography,
      );
      store.applyGeneratedStyle(resolved.toGeneratedDeckStyle());
      final base = controller.options.value.baseStyle!.resolve(context).spec;
      final headline = typography.resolve(theme.recipe.headlineFamily)!;
      final body = typography.resolve(theme.recipe.bodyFamily)!;

      expect(
        base.h1!.spec.style!.fontFamily,
        headline.family,
        reason: theme.id,
      );
      expect(base.p!.spec.style!.fontFamily, body.family, reason: theme.id);
      expect(
        headline.weights,
        contains(base.h1!.spec.style!.fontWeight!.value),
        reason: theme.id,
      );
      expect(
        body.weights,
        contains(base.p!.spec.style!.fontWeight!.value),
        reason: theme.id,
      );
      expect(
        controller.options.value.styles.keys.toSet(),
        presentationThemeTreatmentNames,
        reason: theme.id,
      );
    }
  });
}

final _darkGeneratedStyle = GeneratedDeckStyle(
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
  runtime: defaultPresentationThemeCatalog
      .current('editorial-midnight')!
      .recipe
      .runtime,
);

final _lightGeneratedStyle = GeneratedDeckStyle(
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
  runtime: defaultPresentationThemeCatalog
      .current('nordic-air')!
      .recipe
      .runtime,
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
  runtime: defaultPresentationThemeCatalog
      .current('technical-paper')!
      .recipe
      .runtime,
);
