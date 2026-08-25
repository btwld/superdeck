import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/app/router.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_page.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_view.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_theme_resolution.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_generation_controller.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';
import 'package:provider/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('default route reports a missing API key immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: createRouter(),
        builder: (context, child) => HeroTheme(
          data: HeroThemeData.light(),
          child: AppProviders(child: child!),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WizardPage), findsOneWidget);
    expect(find.byType(WizardView), findsNothing);
    expect(find.byType(EditorPage), findsNothing);
    expect(find.text('Google AI API key is not configured'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('configured page opens the isolated Wizard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => HeroTheme(
          data: HeroThemeData.light(),
          child: AppProviders(child: child!),
        ),
        home: WizardPage(
          isConfigured: true,
          generationService: DeckGeneratorService(apiKey: 'test-key'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WizardView), findsOneWidget);
    expect(find.byType(EditorPage), findsNothing);
    expect(find.text('What is the presentation about?'), findsOneWidget);
    expect(find.text('Describe your presentation topic…'), findsOneWidget);
    expect(find.byTooltip('Generation lab'), findsOneWidget);
  });

  testWidgets('debug action opens the generation lab route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WizardPage(
            isConfigured: true,
            generationService: DeckGeneratorService(apiKey: 'test-key'),
          ),
        ),
        GoRoute(
          path: '/debug/generation',
          builder: (context, state) =>
              const Scaffold(body: Text('Generation lab route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => HeroTheme(
          data: HeroThemeData.light(),
          child: AppProviders(child: child!),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Generation lab'));
    await tester.pumpAndSettle();

    expect(find.text('Generation lab route'), findsOneWidget);
  });

  testWidgets('approved outline loads the deck before Present navigation', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WizardPage(
            isConfigured: true,
            generationService: _PageGenerationService(),
          ),
        ),
        GoRoute(
          path: '/present/0',
          builder: (context, state) =>
              const Scaffold(body: Text('Presentation route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => HeroTheme(
          data: HeroThemeData.light(),
          child: AppProviders(child: child!),
        ),
      ),
    );
    await tester.pump();

    final wizardContext = tester.element(find.byType(WizardView));
    final controller = Provider.of<WizardGenerationController>(
      wizardContext,
      listen: false,
    );
    final loader = Provider.of<MemoryDeckLoader>(wizardContext, listen: false);
    final events = <SlidesEvent>[];
    final subscription = loader.load().listen(events.add);
    addTearDown(subscription.cancel);

    await controller.createOutline(_pageRequest);
    await tester.pump();
    expect(find.text('Review the story'), findsOneWidget);

    await tester.tap(find.text('Approve & build'));
    await tester.pumpAndSettle();

    expect(find.text('Your presentation is ready'), findsOneWidget);
    expect(events.whereType<SlidesLoadedEvent>().single.slides, hasLength(1));

    await tester.tap(find.text('Present deck'));
    await tester.pumpAndSettle();
    expect(find.text('Presentation route'), findsOneWidget);
  });
}

const _pageRequest = DeckGenerationRequest(
  userIntent: 'Urban gardens',
  slideCount: 1,
  themeId: 'technical-paper',
);

final class _PageGenerationService extends DeckGeneratorService {
  _PageGenerationService() : super(apiKey: 'test-key');

  final DeckPlan _plan = _pagePlan();

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
        'options': {'title': 'Opening', 'style': 'content'},
        'sections': [
          {
            'type': 'section',
            'blocks': [
              {
                'type': 'block',
                'content': '## Opening\n\nUrban gardens strengthen cities.',
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
  );
}

DeckPlan _pagePlan() {
  final themes = PresentationThemeCatalog.withDefaults();
  final typography = PresentationTypographyCatalog.withDefaults();
  final descriptor = themes.current('technical-paper')!;
  return DeckPlan.parse({
    'topic': _pageRequest.userIntent,
    'story': 'Small interventions build city-scale resilience.',
    'theme': buildDeckThemeReference(
      descriptor: descriptor,
      request: _pageRequest,
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
        'composition': 'content',
        'treatment': 'content',
        'density': 'balanced',
        'elements': <Object?>[],
      },
    ],
  });
}
