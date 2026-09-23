import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/generation/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/generation/core/engine/services/deck_theme_resolution.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_generation_controller.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_page.dart';
import 'package:playground/features/ai/wizard/presentation/wizard_view.dart';
import 'package:playground/features/export/data/deck_export_saver.dart';
import 'package:playground/features/export/domain/deck_export.dart';
import 'package:provider/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// A 1x1 PNG, so the artwork an export carries is real bytes.
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

  Future<WizardGenerationController> pumpCompletedDeck(
    WidgetTester tester,
    DeckExportSaver exportSaver,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WizardPage(
            isConfigured: true,
            generationService: _ExportFlowGenerationService(),
            exportSaver: exportSaver,
          ),
        ),
        GoRoute(
          path: '/present/:index',
          builder: (context, state) => const Scaffold(body: Text('presenting')),
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

    final wizard = Provider.of<WizardGenerationController>(
      tester.element(find.byType(WizardView)),
      listen: false,
    );
    await wizard.createOutline(_request);
    await tester.pump();
    await tester.tap(find.text('Approve & build'));
    await tester.pumpAndSettle();

    expect(find.text('Your presentation is ready'), findsOneWidget);

    return wizard;
  }

  testWidgets('exporting a finished deck writes its markdown and artwork', (
    tester,
  ) async {
    final exports = <DeckExport>[];
    await pumpCompletedDeck(tester, (export) async {
      exports.add(export);

      return true;
    });

    await tester.tap(find.text('Export deck'));
    await tester.pumpAndSettle();

    final export = exports.single;
    expect(export.name, 'Opening');
    final markdown = utf8.decode(export.files['slides.md']!);
    expect(markdown, contains('Urban gardens strengthen cities.'));
    expect(
      markdown,
      contains('src: assets/hero.png'),
      reason: 'the slides point at artwork shipped beside them',
    );
    expect(export.files['assets/hero.png'], _png);
    expect(find.text('Exported "Opening".'), findsOneWidget);
  });

  testWidgets('cancelling the save dialog reports nothing', (tester) async {
    await pumpCompletedDeck(tester, (_) async => false);

    await tester.tap(find.text('Export deck'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Exported'), findsNothing);
    expect(find.text('Export deck'), findsOneWidget);
  });

  testWidgets('a failed export says why', (tester) async {
    await pumpCompletedDeck(tester, (_) async => throw StateError('disk full'));

    await tester.tap(find.text('Export deck'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('The deck could not be exported'),
      findsOneWidget,
    );
    expect(find.textContaining('disk full'), findsOneWidget);
  });

  testWidgets('a new generation drops the previous export notice', (
    tester,
  ) async {
    final wizard = await pumpCompletedDeck(tester, (_) async => true);
    await tester.tap(find.text('Export deck'));
    await tester.pumpAndSettle();
    expect(find.text('Exported "Opening".'), findsOneWidget);

    await wizard.createOutline(_request);
    await tester.pump();
    await tester.tap(find.text('Approve & build'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Exported'), findsNothing);
  });
}

final class _ExportFlowGenerationService extends DeckGeneratorService {
  _ExportFlowGenerationService() : super(apiKey: 'test-key');

  final DeckPlan _plan = _exportFlowPlan();

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

DeckPlan _exportFlowPlan() {
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
