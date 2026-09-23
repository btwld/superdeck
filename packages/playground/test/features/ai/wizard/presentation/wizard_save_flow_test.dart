import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/core/data/data_sources/deck_library_asset_store.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/generation/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_theme_resolution.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_generation_controller.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_page.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_view.dart';
import 'package:playground/features/library/domain/deck_library_controller.dart';
import 'package:provider/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../../helpers/fake_deck_library.dart';

/// A 1x1 PNG, so the artwork a save carries is real bytes.
final _png = <int>[
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 4, 0, 0, 0, 181, 28, 12, 2,
];

const _request = DeckGenerationRequest(
  userIntent: 'Urban gardens',
  slideCount: 1,
  themeId: 'technical-paper',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<
    ({
      WizardGenerationController wizard,
      DeckLibraryController library,
      DeckLibraryAssetStore assets,
    })
  >
  pumpCompletedDeck(WidgetTester tester, FakeDeckLibrary library) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WizardPage(
            isConfigured: true,
            generationService: _SaveFlowGenerationService(),
          ),
        ),
        GoRoute(
          path: '/present/:index',
          builder: (context, state) => const Scaffold(body: Text('presenting')),
        ),
        GoRoute(
          path: '/decks',
          builder: (context, state) => const Scaffold(body: Text('decks')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => HeroTheme(
          data: HeroThemeData.light(),
          child: AppProviders(deckLibrary: library, child: child!),
        ),
      ),
    );
    await tester.pump();

    final wizardContext = tester.element(find.byType(WizardView));
    final wizard = Provider.of<WizardGenerationController>(
      wizardContext,
      listen: false,
    );
    await wizard.createOutline(_request);
    await tester.pump();
    await tester.tap(find.text('Approve & build'));
    await tester.pumpAndSettle();

    expect(find.text('Your presentation is ready'), findsOneWidget);

    return (
      wizard: wizard,
      library: Provider.of<DeckLibraryController>(wizardContext, listen: false),
      assets: Provider.of<DeckLibraryAssetStore>(wizardContext, listen: false),
    );
  }

  testWidgets('saving a finished deck writes its markdown, artwork and theme', (
    tester,
  ) async {
    final library = FakeDeckLibrary();

    final scope = await pumpCompletedDeck(tester, library);

    await tester.tap(find.text('Save deck'));
    await tester.pumpAndSettle();

    // The dialog offers the deck's own topic and saves nothing until confirmed.
    expect(find.text('Save this deck'), findsOneWidget);
    expect(
      find.text('Urban gardens'),
      findsWidgets,
      reason: 'the dialog offers the deck topic as its name',
    );
    expect(library.saveCount, 0);

    await tester.enterText(
      find.byType(EditableText).last,
      'Urban gardens 2026',
    );
    await tester.tap(find.widgetWithText(GestureDetector, 'Save deck').last);
    await tester.pumpAndSettle();

    expect(library.saveCount, 1);
    final path = library.saved.single.reference.path;
    expect(
      library.markdown[path],
      contains('Urban gardens strengthen cities.'),
      reason: 'the saved deck carries the generated Markdown',
    );
    expect(
      library.assets[path]?['hero.png'],
      _png,
      reason: 'the saved deck carries the generated artwork',
    );
    expect(
      library.themes[path]?.toJson(),
      {'id': 'technical-paper', 'version': 1, 'density': 'balanced'},
      reason: 'the saved deck carries canonical, versioned theme metadata',
    );
    expect(
      (await scope.assets.resolve('hero.png'))?.scheme,
      'file',
      reason: 'the saved deck now answers for artwork',
    );
    expect(
      find.textContaining('Saved "Urban gardens 2026"'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the dialog writes nothing', (tester) async {
    final library = FakeDeckLibrary();
    await pumpCompletedDeck(tester, library);

    await tester.tap(find.text('Save deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(GestureDetector, 'Cancel').last);
    await tester.pumpAndSettle();

    expect(library.saveCount, 0);
    expect(library.saved, isEmpty);
  });

  testWidgets('a second save offers another copy rather than an overwrite', (
    tester,
  ) async {
    final library = FakeDeckLibrary();
    await pumpCompletedDeck(tester, library);

    await tester.tap(find.text('Save deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(GestureDetector, 'Save deck').last);
    await tester.pumpAndSettle();

    expect(find.text('Save another copy'), findsOneWidget);

    await tester.tap(find.text('Save another copy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(GestureDetector, 'Save deck').last);
    await tester.pumpAndSettle();

    expect(library.saveCount, 2);
    expect(library.saved.map((ref) => ref.name).toSet(), hasLength(2));
  });

  testWidgets('a new generation releases the saved deck it was showing', (
    tester,
  ) async {
    final library = FakeDeckLibrary();
    final scope = await pumpCompletedDeck(tester, library);

    await tester.tap(find.text('Save deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(GestureDetector, 'Save deck').last);
    await tester.pumpAndSettle();
    expect((await scope.assets.resolve('hero.png'))?.scheme, 'file');

    // Generating again publishes a new deck into the same runtime.
    await scope.wizard.createOutline(_request);
    await tester.pump();
    await tester.tap(find.text('Approve & build'));
    await tester.pumpAndSettle();

    expect(
      (await scope.assets.resolve('hero.png'))?.scheme,
      'data',
      reason: 'the new deck owns the runtime, so the saved deck must not '
          'answer for artwork any more',
    );
    expect(find.text('Save deck'), findsOneWidget);
  });

  testWidgets('a library that cannot save offers no save action', (
    tester,
  ) async {
    final library = FakeDeckLibrary()..canSave = false;

    await pumpCompletedDeck(tester, library);

    expect(find.text('Save deck'), findsNothing);
    expect(find.text('Present deck'), findsOneWidget);
  });
}

final class _SaveFlowGenerationService extends DeckGeneratorService {
  _SaveFlowGenerationService() : super(apiKey: 'test-key');

  final DeckPlan _plan = _saveFlowPlan();

  @override
  Future<DeckPlanningResult> plan(
    DeckGenerationRequest request, {
    onProgress,
    onTrace,
    isCancelled,
  }) async => DeckPlanningResult.success(_plan);

  @override
  Future<DeckGenerationResult> generateFromPlan(
    DeckGenerationRequest request,
    DeckPlan approvedPlan, {
    onProgress,
    onTrace,
    isCancelled,
  }) async => DeckGenerationResult.success(
    slides: [
      Slide.parse({
        'key': 'opening',
        'options': {'title': 'Opening', 'style': 'visual'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {
                'type': 'block',
                'content': '## Opening\n\nUrban gardens strengthen cities.',
              },
              {
                'type': 'widget',
                'name': 'image',
                'args': {'src': 'hero.png', 'fit': 'cover'},
              },
            ],
          },
        ],
      }),
    ],
    plan: approvedPlan,
    theme: resolveDeckThemeReference(
      approvedPlan.theme,
      themeCatalog: themeCatalog,
      typographyCatalog: typographyCatalog,
    ),
    generatedImages: [
      GeneratedImageAsset.success(assetKey: 'hero.png', bytes: _png),
    ],
  );
}

DeckPlan _saveFlowPlan() {
  final themes = PresentationThemeCatalog.withDefaults();
  final typography = PresentationTypographyCatalog.withDefaults();
  final descriptor = themes.current('technical-paper')!;

  return DeckPlan.parse({
    'topic': _request.userIntent,
    'story': 'Small interventions build city-scale resilience.',
    'theme': buildDeckThemeReference(
      descriptor: descriptor,
      request: _request,
      typographyCatalog: typography,
    ),
    'sections': [
      {
        'key': 'main',
        'title': 'Main story',
        'purpose': 'Explain the opportunity.',
        'transition': 'Move from context to action.',
        'slideKeys': ['opening'],
      },
    ],
    'slides': [
      {
        'key': 'opening',
        'title': 'Urban gardens matter',
        'purpose': 'Introduce the opportunity.',
        'sectionKey': 'main',
        'assertion': 'Urban gardens strengthen neighborhood resilience.',
        'contentUnits': ['One concrete supporting point'],
        'narrativeRole': 'opening',
        'contentBrief': 'Frame the opportunity clearly.',
        'continuity': 'Open the story and lead into action.',
        'composition': 'imageFullBleed',
        'treatment': 'visual',
        'density': 'balanced',
        'elements': [
          {
            'type': 'image',
            'purpose': 'Anchor the story.',
            'source': 'hero.png',
          },
        ],
      },
    ],
  });
}
