import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_plan_validator.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_theme_resolution.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_element_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_model_client.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generated_slide_validator.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_quality_report.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_trace.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_validation_issue.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/theme_json_serializer.dart';
import 'package:playground/features/ai/quick_agent/domain/generated_deck_style_mapper.dart';
import 'package:superdeck/src/utils/syntax_highlighter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart' show Slide, WidgetBlock;

const _apiKey = String.fromEnvironment('GOOGLE_AI_API_KEY');
const _selectedFixture = String.fromEnvironment(
  'LIVE_FIXTURE',
  defaultValue: 'all',
);
const _artifactPath = String.fromEnvironment('LIVE_ARTIFACT');
const _includeDebugLayout = bool.fromEnvironment('LIVE_DEBUG_LAYOUT');
const _renderThemeQualification = bool.fromEnvironment(
  'LIVE_THEME_QUALIFICATION',
);
const _runFakeCheckpoint = bool.fromEnvironment('LIVE_FAKE_CHECKPOINT');
const _smokeFixtures = ['narrative', 'comparison_table', 'visual_elements'];
const _largeDeckFixtures = [
  'narrative_10',
  'decision_data_15',
  'visual_product_20',
];
final _themeCatalog = PresentationThemeCatalog.withDefaults();
final _typographyCatalog = PresentationTypographyCatalog.withDefaults();

typedef _CaptureResult = ({
  List<File> pngs,
  int replayedSlideCount,
  Set<String> resolvedFontFamilies,
  Duration elapsed,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialize SuperDeck's fallback style while runtime fetching is disabled;
  // generated captures replace its typography, and this prevents the fallback
  // Poppins request from contaminating GoogleFonts.pendingFonts().
  GoogleFonts.config.allowRuntimeFetching = false;
  final _ = defaultSlideStyle;
  // This file is explicitly opt-in and must bypass flutter_test's HTTP 400
  // isolation so the production Gemini client can reach the network.
  HttpOverrides.global = null;
  GoogleFonts.config.allowRuntimeFetching = true;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );

  if (_renderThemeQualification) {
    testWidgets(
      'captures the deterministic representative theme matrix',
      (tester) async {
        final markdown = (await tester.runAsync(
          () => File(
            'test_live/ai_generation/fixtures/theme_qualification.md',
          ).readAsString(),
        ))!;
        final output = (await tester.runAsync(
          () => _createRunDirectory('theme_qualification'),
        ))!;
        final manifest = <Map<String, Object?>>[];

        for (final themeId in featuredPresentationThemeIds) {
          final descriptor = _themeCatalog.current(themeId)!;
          final theme = _themeCatalog.resolve(
            id: descriptor.id,
            version: descriptor.version,
            typographyCatalog: _typographyCatalog,
          );
          final themeOutput = (await tester.runAsync(
            () => Directory(p.join(output.path, themeId)).create(),
          ))!;
          final capture = await _captureSlides(
            tester: tester,
            output: themeOutput,
            markdown: markdown,
            theme: theme,
            expectedSlideCount: 10,
          );
          final contactSheet = (await tester.runAsync(
            () => _writeContactSheet(themeOutput, capture.pngs),
          ))!;
          await tester.runAsync(
            () => _expectThemeGolden(themeId, contactSheet),
          );
          manifest.add(_themeQualificationEntry(theme, capture));
          expect(capture.pngs, hasLength(10), reason: themeId);
        }

        await tester.runAsync(
          () => File(p.join(output.path, 'manifest.json')).writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'fixture': 'theme_qualification.md',
              'logicalResolution': {'width': 1280, 'height': 720},
              'themes': manifest,
            }),
          ),
        );
        // ignore: avoid_print
        print('Theme qualification artifacts: ${output.path}');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
    return;
  }

  if (_runFakeCheckpoint) {
    testWidgets(
      'runs the deterministic ten-slide fake-model checkpoint',
      (tester) async {
        const request = DeckGenerationRequest(
          userIntent:
              'Create a ten-slide internal decision story. Teams spent 42% '
              'less weekly synthesis time.',
          slideCount: 10,
          audience: 'Product and engineering leaders',
          approach: 'Evidence-led operating narrative',
          themeId: 'technical-paper',
        );
        final client = _FakeCheckpointModelClient();
        final traces = <GenerationTraceEvent>[];
        final result = await DeckGeneratorService(
          apiKey: 'deterministic-fake-key',
          modelClientFactory: (_) => client,
        ).generate(request, onTrace: traces.add);

        expect(
          result.success,
          isTrue,
          reason: const JsonEncoder.withIndent('  ').convert({
            'error': result.error,
            'validation': traces
                .where((event) => event.kind == GenerationTraceKind.validation)
                .map((event) => event.toJson())
                .toList(),
          }),
        );
        expect(result.slides, hasLength(10));
        expect(result.plan!.slides, hasLength(10));
        expect(result.plan!.theme.id, 'technical-paper');
        expect(result.plan!.theme.version, 1);
        expect(client.requests, hasLength(4));
        expect(
          client.requests.map(
            (modelRequest) =>
                modelRequest.generationConfig!.thinkingConfig!.thinkingBudget,
          ),
          everyElement(0),
        );
        expect(client.requests.map((modelRequest) => modelRequest.model), [
          'models/gemini-3.5-flash',
          'models/gemini-3.1-flash-lite',
          'models/gemini-3.1-flash-lite',
          'models/gemini-3.1-flash-lite',
        ]);

        final sectionRequests = traces
            .where(
              (event) =>
                  event.kind == GenerationTraceKind.request &&
                  event.phase == GenerationTracePhase.slide,
            )
            .toList(growable: false);
        expect(sectionRequests, hasLength(3));
        expect(sectionRequests.map((event) => event.slideIndex), [1, 4, 8]);
        const expectedSectionKeys = [
          ['opening', 'signals', 'synthesis'],
          ['choices', 'alignment', 'practice', 'principle'],
          ['verification', 'action', 'close'],
        ];
        final sectionPlanKeys = [
          for (final event in sectionRequests)
            _parseSectionPlanKeys(event.prompt!),
        ];
        for (final (index, event) in sectionRequests.indexed) {
          expect(
            sectionPlanKeys[index],
            expectedSectionKeys[index],
            reason: 'section ${index + 1} ordered plan',
          );
          expect(
            event.prompt,
            contains('## Canonical shape examples'),
            reason: 'section ${index + 1} canonical examples',
          );
        }

        final output = (await tester.runAsync(
          () => _createRunDirectory('fake_checkpoint_10'),
        ))!;
        final markdown = const SlideSerializer().serialize(result.slides);
        final deckJson = {
          'theme': serializeDeckThemeReference(result.plan!.theme),
          'slides': result.slides.map((slide) => slide.toMap()).toList(),
        };
        await tester.runAsync(() async {
          const encoder = JsonEncoder.withIndent('  ');
          await File(
            p.join(output.path, 'request.json'),
          ).writeAsString(encoder.convert(request.toMap()));
          await File(
            p.join(output.path, 'deck.json'),
          ).writeAsString(encoder.convert(deckJson));
          await File(p.join(output.path, 'slides.md')).writeAsString(markdown);
          await File(p.join(output.path, 'trace.json')).writeAsString(
            encoder.convert(traces.map((event) => event.toJson()).toList()),
          );
          await _writeTraceArtifacts(output, traces, plan: result.plan);
        });

        final capture = await _captureSlides(
          tester: tester,
          output: output,
          markdown: markdown,
          theme: result.theme!,
          expectedSlideCount: 10,
        );
        final contactSheet = (await tester.runAsync(
          () => _writeContactSheet(output, capture.pngs),
        ))!;
        final styleSnapshot = await _resolvedStyleSnapshot(
          tester,
          result.theme!,
        );
        expect(styleSnapshot['headlineFamily'], 'Space Grotesk');
        expect(
          styleSnapshot['headlineRuntimeFamily'],
          startsWith('SpaceGrotesk_'),
        );
        expect(styleSnapshot['bodyFamily'], 'Open Sans');
        expect(styleSnapshot['bodyRuntimeFamily'], startsWith('OpenSans_'));
        expect(styleSnapshot['header'], isNull);
        expect(styleSnapshot['footer'], isNull);
        expect(
          styleSnapshot['treatments'],
          presentationThemeTreatmentNames.toList()..sort(),
        );
        final report = GenerationQualityReport.evaluate(
          request: request,
          plan: result.plan!,
          slides: result.slides,
          traces: traces,
          replayedSlideCount: capture.replayedSlideCount,
          capturedSlideCount: capture.pngs.length,
          resolvedFontFamilies: capture.resolvedFontFamilies,
          captureElapsed: capture.elapsed,
        );
        await tester.runAsync(() async {
          const encoder = JsonEncoder.withIndent('  ');
          await File(p.join(output.path, 'checkpoint.json')).writeAsString(
            encoder.convert({
              'sectionPlanKeys': sectionPlanKeys,
              'resolvedStyle': styleSnapshot,
              'qualityReport': report.toJson(),
              'contactSheet': p.basename(contactSheet.path),
            }),
          );
        });

        expect(capture.replayedSlideCount, 10);
        expect(capture.pngs, hasLength(10));
        expect(report.passed, isTrue, reason: jsonEncode(report.toJson()));
        // ignore: avoid_print
        print('Fake checkpoint artifacts: ${output.path}');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
    return;
  }

  if (_artifactPath.isNotEmpty) {
    testWidgets(
      'recaptures an existing live generation artifact',
      (tester) async {
        // ignore: avoid_print
        print('Loading artifact $_artifactPath');
        final artifact = (await tester.runAsync(() async {
          final output = Directory(_artifactPath);
          final deckJson =
              jsonDecode(
                    await File(p.join(output.path, 'deck.json')).readAsString(),
                  )
                  as Map<String, Object?>;
          final requestJson =
              jsonDecode(
                    await File(
                      p.join(output.path, 'request.json'),
                    ).readAsString(),
                  )
                  as Map<String, Object?>;
          final planJson =
              jsonDecode(
                    await File(
                      p.join(output.path, 'deck_plan.json'),
                    ).readAsString(),
                  )
                  as Map<String, Object?>;
          final themeReference = Map<String, Object?>.from(
            deckJson['theme']! as Map,
          );
          return (
            output: output,
            markdown: await File(
              p.join(output.path, 'slides.md'),
            ).readAsString(),
            theme: resolveDeckThemeMap(
              themeReference,
              themeCatalog: _themeCatalog,
              typographyCatalog: _typographyCatalog,
            ),
            themeReference: themeReference,
            slideCount: (deckJson['slides'] as List).length,
            plan: DeckPlanType.parse(planJson),
            request: DeckGenerationRequest.fromMap(requestJson),
            rawSlides: [
              for (final rawSlide in deckJson['slides']! as List)
                Map<String, dynamic>.from(rawSlide as Map),
            ],
          );
        }))!;
        final auditErrors = <String>[
          if (jsonEncode(artifact.themeReference) !=
              jsonEncode(serializeDeckThemeReference(artifact.plan.theme)))
            'deck.json theme does not match deck_plan.json theme.',
          ...validateDeckPlanIssues(
            artifact.plan,
            request: artifact.request,
          ).blockingIssues.map((issue) => issue.message),
          for (final (index, rawSlide) in artifact.rawSlides.indexed)
            ...validateGeneratedSlideIssues(
              expectedKey: artifact.plan.slides[index].key,
              rawSlide: rawSlide,
              planSlide: artifact.plan.slides[index],
              request: artifact.request,
              elementCatalog: GenerationElementCatalog.builtIn(),
            ).blockingIssues.map(
              (issue) => 'Slide ${index + 1}: ${issue.message}',
            ),
        ];
        expect(
          auditErrors,
          isEmpty,
          reason:
              'Saved artifact failed current semantic validation:\n'
              '${auditErrors.join('\n')}',
        );
        final capture = await _captureSlides(
          tester: tester,
          output: artifact.output,
          markdown: artifact.markdown,
          theme: artifact.theme,
          expectedSlideCount: artifact.slideCount,
        );
        // ignore: avoid_print
        print('Writing contact sheet from ${capture.pngs.length} captures');
        await tester.runAsync(
          () => _writeContactSheet(artifact.output, capture.pngs),
        );
        expect(capture.pngs, isNotEmpty);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
    return;
  }

  for (final fixture in _selectedFixtures()) {
    group('live generation: $fixture', () {
      late Directory output;
      late String markdown;
      late ResolvedPresentationTheme theme;
      late DeckPlanType plan;
      late DeckGenerationRequest request;
      late List<Slide> slides;
      var traces = <GenerationTraceEvent>[];
      var expectedSlideCount = 0;
      var generationReady = false;

      test(
        'generates and writes model artifacts',
        () async {
          final brief = await File(
            'test_live/ai_generation/fixtures/$fixture.txt',
          ).readAsString();
          final service = DeckGeneratorService(apiKey: _apiKey);
          request = _requestForFixture(fixture, brief);
          final result = await service.generate(request, onTrace: traces.add);
          output = await _createRunDirectory(fixture);

          await File(p.join(output.path, 'brief.txt')).writeAsString(brief);
          await File(p.join(output.path, 'request.json')).writeAsString(
            const JsonEncoder.withIndent('  ').convert(request.toMap()),
          );
          await File(p.join(output.path, 'trace.json')).writeAsString(
            const JsonEncoder.withIndent(
              '  ',
            ).convert(traces.map((event) => event.toJson()).toList()),
          );
          await _writeTraceArtifacts(output, traces, plan: result.plan);

          expect(result.success, isTrue, reason: result.error);
          expect(result.slides, isNotEmpty);
          plan = result.plan!;
          slides = result.slides;
          final deckJson = {
            'theme': serializeDeckThemeReference(result.plan!.theme),
            'slides': result.slides.map((slide) => slide.toMap()).toList(),
          };
          await File(
            p.join(output.path, 'deck.json'),
          ).writeAsString(const JsonEncoder.withIndent('  ').convert(deckJson));
          markdown = const SlideSerializer().serialize(result.slides);
          theme = result.theme!;
          expectedSlideCount = result.slideCount;
          await File(p.join(output.path, 'slides.md')).writeAsString(markdown);
          await File(p.join(output.path, 'validation.json')).writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'success': result.success,
              'slideCount': result.slideCount,
              'validationEvents': traces
                  .where(
                    (event) => event.kind == GenerationTraceKind.validation,
                  )
                  .map((event) => event.toJson())
                  .toList(),
            }),
          );

          generationReady = true;
        },
        skip: _apiKey.isEmpty,
        timeout: const Timeout(Duration(minutes: 15)),
      );

      testWidgets(
        'captures PNGs and contact sheet',
        (tester) async {
          if (!generationReady) return;
          final capture = await _captureSlides(
            tester: tester,
            output: output,
            markdown: markdown,
            theme: theme,
            expectedSlideCount: expectedSlideCount,
          );
          await tester.runAsync(() => _writeContactSheet(output, capture.pngs));
          final report = GenerationQualityReport.evaluate(
            request: request,
            plan: plan,
            slides: slides,
            traces: traces,
            replayedSlideCount: capture.replayedSlideCount,
            capturedSlideCount: capture.pngs.length,
            resolvedFontFamilies: capture.resolvedFontFamilies,
            captureElapsed: capture.elapsed,
          );
          await tester.runAsync(
            () =>
                File(p.join(output.path, 'quality_report.json')).writeAsString(
                  const JsonEncoder.withIndent('  ').convert(report.toJson()),
                ),
          );
          expect(capture.pngs, hasLength(expectedSlideCount));
          expect(
            report.passed,
            isTrue,
            reason: const JsonEncoder.withIndent('  ').convert(report.toJson()),
          );
        },
        skip: _apiKey.isEmpty,
        timeout: const Timeout(Duration(minutes: 5)),
      );
    });
  }
}

Map<String, Object?> _themeQualificationEntry(
  ResolvedPresentationTheme theme,
  _CaptureResult capture,
) {
  final runtime = theme.descriptor.recipe.runtime;

  return {
    'id': theme.descriptor.id,
    'version': theme.descriptor.version,
    'title': theme.descriptor.title,
    'description': theme.descriptor.description,
    'direction': theme.direction,
    'density': theme.density,
    'typeScale': theme.typeScale,
    'palette': {
      'background': theme.palette.background,
      'surface': theme.palette.surface,
      'surfaceAlt': theme.palette.surfaceAlt,
      'heading': theme.palette.heading,
      'body': theme.palette.body,
      'accent': theme.palette.accent,
      'accentContrast': theme.palette.accentContrast,
    },
    'fonts': {
      'headline': theme.headlineFamily,
      'body': theme.bodyFamily,
      'resolved': capture.resolvedFontFamilies.toList()..sort(),
    },
    'runtime': {
      'spacingScale': runtime.spacingScale,
      'cornerRadius': runtime.cornerRadius,
      'borderWidth': runtime.borderWidth,
      'quoteRuleWidth': runtime.quoteRuleWidth,
      'surfaceStyle': runtime.surfaceStyle.name,
      'decorativeStyle': runtime.decorativeStyle.name,
      'treatments': {
        for (final entry in runtime.treatments.byName.entries)
          entry.key: {
            'background': entry.value.background.name,
            'heading': entry.value.heading.name,
            'body': entry.value.body.name,
            'headlineScale': entry.value.headlineScale,
            'italicHeadline': entry.value.italicHeadline,
            'blockStyle': entry.value.blockStyle.name,
          },
      },
    },
    'captures': capture.pngs.length,
    'captureElapsedMs': capture.elapsed.inMilliseconds,
  };
}

DeckGenerationRequest _requestForFixture(String fixture, String brief) {
  return switch (fixture) {
    'narrative' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 6,
      audience: 'Engineering leaders',
      approach: 'Confident editorial narrative',
      themeId: 'editorial-midnight',
      designDirection: 'Dark navy editorial',
    ),
    'comparison_table' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 5,
      audience: 'Product team',
      approach: 'Evidence-led decision deck',
      themeId: 'technical-paper',
      designDirection: 'Light warm',
    ),
    'visual_elements' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 5,
      audience: 'Developers and technical leaders',
      approach: 'Product launch briefing',
      themeId: 'bold-product',
      designDirection: 'Bold dark',
      groundedElements: const [
        GroundedGenerationElement(
          type: 'image',
          source:
              'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
          purpose: 'Ground the platform story in a developer workspace',
        ),
        GroundedGenerationElement(
          type: 'qrcode',
          source: 'https://example.com/developer-platform',
          purpose: 'Let the audience open the developer platform',
        ),
        GroundedGenerationElement(
          type: 'webview',
          source: 'https://example.com',
          purpose: 'Demonstrate the live product surface',
        ),
      ],
    ),
    'narrative_10' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 10,
      audience: 'Senior product and engineering leaders',
      approach: 'Editorial strategy narrative with a strong opening and close',
      themeId: 'editorial-midnight',
      emphasis: const [
        'one clear assertion per slide',
        'purposeful pacing across three acts',
        'credible operational evidence',
      ],
      designDirection: 'Editorial, dark, restrained, and cinematic',
      headlineFont: 'Playfair Display',
      bodyFont: 'Inter',
    ),
    'decision_data_15' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 15,
      audience: 'Executive investment committee',
      approach: 'Evidence-led decision memo presented as a technical deck',
      themeId: 'technical-paper',
      emphasis: const [
        'readable tables and metrics',
        'clear trade-offs',
        'decision-ready recommendation',
      ],
      designDirection: 'Technical, light, precise, and information-rich',
      headlineFont: 'Space Grotesk',
      bodyFont: 'Open Sans',
    ),
    'visual_product_20' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 20,
      audience: 'Customers, partners, and developer advocates',
      approach: 'Bold product launch story with varied visual rhythm',
      themeId: 'bold-product',
      emphasis: const [
        'product value before feature detail',
        'meaningful layout variation',
        'specific proof and next steps',
      ],
      designDirection: 'Bold, dark, energetic, and product-forward',
      headlineFont: 'Montserrat',
      bodyFont: 'DM Sans',
      groundedElements: const [
        GroundedGenerationElement(
          type: 'image',
          source: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71',
          purpose: 'Show a polished analytics product surface',
        ),
        GroundedGenerationElement(
          type: 'qrcode',
          source: 'https://superdeck-dev.web.app',
          purpose: 'Let the audience open the live SuperDeck experience',
        ),
      ],
    ),
    _ => throw ArgumentError.value(fixture, 'fixture', 'Unknown fixture'),
  };
}

List<String> _selectedFixtures() => switch (_selectedFixture) {
  'all' => _smokeFixtures,
  'large_deck_matrix' => _largeDeckFixtures,
  final fixture
      when _smokeFixtures.contains(fixture) ||
          _largeDeckFixtures.contains(fixture) =>
    [fixture],
  _ => throw ArgumentError.value(
    _selectedFixture,
    'LIVE_FIXTURE',
    'Use all, large_deck_matrix, or a registered fixture name.',
  ),
};

Future<Directory> _createRunDirectory(String fixture) async {
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  return Directory(
    'test_live/ai_generation/artifacts/${fixture}_$stamp',
  ).create(recursive: true);
}

Future<void> _writeTraceArtifacts(
  Directory output,
  List<GenerationTraceEvent> traces, {
  DeckPlanType? plan,
}) async {
  if (plan != null) {
    await File(
      p.join(output.path, 'deck_plan.json'),
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(plan));
  }
  var slideRequestIndex = 0;
  for (final event in traces.where(
    (event) => event.phase == GenerationTracePhase.slide,
  )) {
    if (event.kind == GenerationTraceKind.request) {
      slideRequestIndex++;
      await File(
        p.join(
          output.path,
          'slide_${event.slideIndex}_attempt_${event.attempt}_prompt.txt',
        ),
      ).writeAsString(event.prompt ?? '');
    } else if (event.kind == GenerationTraceKind.response) {
      await File(
        p.join(
          output.path,
          'slide_${event.slideIndex}_attempt_${event.attempt}_response.json',
        ),
      ).writeAsString(event.response ?? '');
    }
  }
  final requestEvents = traces
      .where((event) => event.kind == GenerationTraceKind.request)
      .toList(growable: false);
  final outlineRequestCount = requestEvents
      .where((event) => event.phase == GenerationTracePhase.outline)
      .length;
  await File(p.join(output.path, 'metadata.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'models': traces
          .map((event) => event.model)
          .whereType<String>()
          .toSet()
          .toList(),
      'elapsedMs': traces.isEmpty ? 0 : traces.last.elapsed.inMilliseconds,
      'requestCount': requestEvents.length,
      'outlineRequestCount': outlineRequestCount,
      'slideRequestCount': slideRequestIndex,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    }),
  );
}

List<String> _parseSectionPlanKeys(String prompt) {
  const startMarker = '## Ordered slide plans\n';
  const endMarker = '\n\n## Boundary context';
  final start = prompt.indexOf(startMarker);
  final end = prompt.indexOf(endMarker, start + startMarker.length);
  if (start < 0 || end < 0) {
    throw FormatException('Section prompt does not contain ordered plans.');
  }
  final payload = prompt.substring(start + startMarker.length, end).trim();
  final decoded = jsonDecode(payload);
  if (decoded is! List) {
    throw FormatException('Ordered section plans are not a JSON list.');
  }
  return [
    for (final entry in decoded)
      if (entry is Map && entry['key'] is String) entry['key']! as String,
  ];
}

Future<Map<String, Object?>> _resolvedStyleSnapshot(
  WidgetTester tester,
  ResolvedPresentationTheme theme,
) async {
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
  if (!context.mounted) {
    throw StateError('Resolved-style context was unmounted.');
  }
  final loader = MemoryDeckLoader();
  final controller = DeckController(deckLoader: loader, options: DeckOptions());
  final customization = DeckCustomizationStore(controller);
  try {
    customization.applyGeneratedStyle(theme.toGeneratedDeckStyle());
    final options = controller.options.value;
    final base = options.baseStyle!.resolve(context).spec;
    final headline = base.h1!.spec.style!;
    final body = base.p!.spec.style!;
    return {
      'theme': {
        'id': theme.descriptor.id,
        'version': theme.descriptor.version,
        'density': theme.density,
      },
      'headlineFamily': theme.headlineFamily,
      'headlineRuntimeFamily': headline.fontFamily,
      'headlineWeight': headline.fontWeight!.value,
      'bodyFamily': theme.bodyFamily,
      'bodyRuntimeFamily': body.fontFamily,
      'bodyWeight': body.fontWeight!.value,
      'header': options.parts.header?.runtimeType.toString(),
      'footer': options.parts.footer?.runtimeType.toString(),
      'treatments': options.styles.keys.toList()..sort(),
      'runtime': {
        'spacingScale': theme.descriptor.recipe.runtime.spacingScale,
        'cornerRadius': theme.descriptor.recipe.runtime.cornerRadius,
        'borderWidth': theme.descriptor.recipe.runtime.borderWidth,
        'quoteRuleWidth': theme.descriptor.recipe.runtime.quoteRuleWidth,
        'surfaceStyle': theme.descriptor.recipe.runtime.surfaceStyle.name,
        'decorativeStyle': theme.descriptor.recipe.runtime.decorativeStyle.name,
      },
    };
  } finally {
    customization.dispose();
    controller.dispose();
    loader.dispose();
  }
}

Future<_CaptureResult> _captureSlides({
  required WidgetTester tester,
  required Directory output,
  required String markdown,
  required ResolvedPresentationTheme theme,
  required int expectedSlideCount,
}) async {
  final startedAt = DateTime.now();
  // ignore: avoid_print
  print('Preparing capture context');
  await tester.runAsync(SyntaxHighlight.initialize);
  final resolvedFontFamilies = (await tester.runAsync(
    () => _loadCaptureFonts(theme),
  ))!;
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: theme.bodyFamily),
      home: Builder(
        builder: (value) {
          context = value;
          return const SizedBox();
        },
      ),
    ),
  );
  // ignore: avoid_print
  print('Creating in-memory deck');
  final loader = MemoryDeckLoader();
  final controller = DeckController(
    deckLoader: loader,
    options: DeckOptions(),
    assetCacheStore: MemoryAssetCacheStore(),
  );
  final customization = DeckCustomizationStore(controller);
  addTearDown(customization.dispose);
  addTearDown(controller.dispose);
  addTearDown(loader.dispose);
  customization.applyGeneratedStyle(theme.toGeneratedDeckStyle());
  loader.updateMarkdown(markdown);
  await tester.pump();
  final parsedConfigurations = controller.slides.value;
  if (parsedConfigurations.length != expectedSlideCount) {
    throw StateError(
      'Markdown replay produced ${parsedConfigurations.length} slides; '
      'expected $expectedSlideCount.',
    );
  }
  final loadedImages = (await tester.runAsync(
    () => _loadNetworkImages(parsedConfigurations),
  ))!;
  final captureConfigurations = [
    for (final configuration in parsedConfigurations)
      _withLoadedImages(configuration, loadedImages),
  ];
  // ignore: avoid_print
  print('Loaded ${captureConfigurations.length} slide configurations');
  if (!context.mounted) {
    throw StateError('Capture context was unmounted.');
  }
  final capture = SlideCaptureService();
  final files = <File>[];
  // ignore: avoid_print
  print('Entering real-time capture loop');
  try {
    await tester.runAsync(() async {
      for (final configuration in captureConfigurations) {
        if (!context.mounted) {
          throw StateError('Capture context was unmounted.');
        }
        final number = configuration.slideIndex + 1;
        // ignore: avoid_print
        print('Capturing slide $number/${captureConfigurations.length}');
        final bytes = await capture
            .capture(
              quality: SlideCaptureQuality.good,
              slide: configuration,
              context: context,
              includeDebugLayout: _includeDebugLayout,
            )
            .timeout(const Duration(seconds: 45));
        final file = File(
          p.join(output.path, 'slide_${number}_${configuration.key}.png'),
        );
        await file.writeAsBytes(bytes);
        files.add(file);
      }
    });
  } finally {
    for (final loadedImage in loadedImages.values) {
      loadedImage.dispose();
    }
  }
  // ignore: avoid_print
  print('Finished capture loop');
  return (
    pngs: files,
    replayedSlideCount: parsedConfigurations.length,
    resolvedFontFamilies: resolvedFontFamilies,
    elapsed: DateTime.now().difference(startedAt),
  );
}

Future<Map<String, ui.Image>> _loadNetworkImages(
  List<SlideConfiguration> configurations,
) async {
  final sources = <String>{
    for (final configuration in configurations)
      for (final section in configuration.sections)
        for (final block in section.blocks)
          if (block is WidgetBlock && block.name == 'image')
            if (block.args['src'] case final String src)
              if (_isNetworkSource(src)) src,
  };
  if (sources.isEmpty) return const {};

  final client = HttpClient();
  final loadedImages = <String, ui.Image>{};
  try {
    for (final source in sources) {
      final response = await (await client.getUrl(Uri.parse(source))).close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Generated image returned HTTP ${response.statusCode}',
          uri: Uri.parse(source),
        );
      }
      final bytes = BytesBuilder(copy: false);
      await response.forEach(bytes.add);
      final decoded = image.decodeImage(bytes.takeBytes());
      if (decoded == null) {
        throw StateError('Could not decode generated image $source');
      }
      final captureImage = decoded.width > 1280
          ? image.copyResize(decoded, width: 1280)
          : decoded;
      final codec = await ui.instantiateImageCodec(
        image.encodeJpg(captureImage, quality: 85),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      loadedImages[source] = frame.image;
    }
  } finally {
    client.close(force: true);
  }
  return loadedImages;
}

SlideConfiguration _withLoadedImages(
  SlideConfiguration configuration,
  Map<String, ui.Image> loadedImages,
) {
  if (loadedImages.isEmpty) return configuration;
  final originalImageFactory = configuration.widgets['image'];
  return configuration.copyWith(
    widgets: {
      ...configuration.widgets,
      'image': (args) {
        final loadedImage = loadedImages[args['src']];
        if (loadedImage == null) {
          return originalImageFactory?.call(args) ?? const SizedBox.shrink();
        }
        return SizedBox.expand(
          child: RawImage(image: loadedImage, fit: BoxFit.cover),
        );
      },
    },
  );
}

bool _isNetworkSource(String source) {
  final scheme = Uri.tryParse(source)?.scheme;
  return scheme == 'http' || scheme == 'https';
}

Future<Set<String>> _loadCaptureFonts(ResolvedPresentationTheme theme) async {
  final families = {theme.headlineFamily, theme.bodyFamily};
  final fontStyles = <TextStyle>[];
  for (final family in families) {
    final descriptor = _typographyCatalog.resolve(family);
    if (descriptor == null || !GoogleFonts.asMap().containsKey(family)) {
      throw StateError(
        'Live capture cannot resolve Google font "$family". '
        'Registered bundled fonts need an explicit capture loader.',
      );
    }
    for (final weight in descriptor.weights) {
      fontStyles.add(
        GoogleFonts.getFont(
          family,
          fontWeight: FontWeight.values.firstWhere(
            (candidate) => candidate.value == weight,
          ),
        ),
      );
    }
  }
  try {
    await GoogleFonts.pendingFonts(
      fontStyles,
    ).timeout(const Duration(seconds: 30));
  } on TimeoutException {
    throw StateError(
      'Timed out resolving live capture fonts: ${families.join(', ')}.',
    );
  }
  return families;
}

Future<File> _writeContactSheet(Directory output, List<File> files) async {
  final decoded = <image.Image>[];
  for (final file in files) {
    final value = image.decodePng(await file.readAsBytes());
    if (value != null) decoded.add(image.copyResize(value, width: 480));
  }
  if (decoded.isEmpty) {
    throw StateError('Cannot create a contact sheet without decoded captures.');
  }
  const columns = 2;
  final cellWidth = decoded.first.width;
  final cellHeight = decoded
      .map((entry) => entry.height)
      .reduce((a, b) => a > b ? a : b);
  final rows = (decoded.length + columns - 1) ~/ columns;
  final sheet = image.Image(
    width: cellWidth * columns,
    height: cellHeight * rows,
  );
  image.fill(sheet, color: image.ColorRgb8(24, 24, 27));
  for (var index = 0; index < decoded.length; index++) {
    image.compositeImage(
      sheet,
      decoded[index],
      dstX: (index % columns) * cellWidth,
      dstY: (index ~/ columns) * cellHeight,
    );
  }
  final file = File(p.join(output.path, 'contact_sheet.png'));
  await file.writeAsBytes(image.encodePng(sheet));
  return file;
}

Future<void> _expectThemeGolden(String themeId, File actualFile) async {
  final expectedFile = File(
    p.join('test_live', 'ai_generation', 'goldens', '$themeId.png'),
  );
  if (!expectedFile.existsSync()) {
    throw StateError(
      'Missing reviewed theme golden for "$themeId": ${expectedFile.path}',
    );
  }
  final actual = image.decodePng(await actualFile.readAsBytes());
  final expected = image.decodePng(await expectedFile.readAsBytes());
  if (actual == null || expected == null) {
    throw StateError('Could not decode the "$themeId" theme golden pair.');
  }
  if (actual.width != expected.width || actual.height != expected.height) {
    throw TestFailure(
      'Theme golden "$themeId" changed dimensions from '
      '${expected.width}x${expected.height} to '
      '${actual.width}x${actual.height}.',
    );
  }
  final actualPixels = actual.getBytes(order: image.ChannelOrder.rgba);
  final expectedPixels = expected.getBytes(order: image.ChannelOrder.rgba);
  for (var index = 0; index < actualPixels.length; index++) {
    if (actualPixels[index] != expectedPixels[index]) {
      throw TestFailure(
        'Theme golden "$themeId" differs at RGBA byte $index. '
        'Review the generated contact sheet before updating the baseline.',
      );
    }
  }
}

final class _FakeCheckpointModelClient implements GenerationModelClient {
  _FakeCheckpointModelClient()
    : _responses = [
        _checkpointResponse(_checkpointPlanDraft()),
        for (final slides in _checkpointSectionSlides())
          _checkpointResponse({'slides': slides}),
      ];

  final List<google_ai.GenerateContentResponse> _responses;
  final requests = <google_ai.GenerateContentRequest>[];
  var _responseIndex = 0;

  @override
  void close() {}

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) async {
    requests.add(request);
    if (_responseIndex >= _responses.length) {
      throw StateError(
        'The deterministic fake received an unexpected repair request.',
      );
    }
    return _responses[_responseIndex++];
  }
}

google_ai.GenerateContentResponse _checkpointResponse(
  Map<String, Object?> value,
) => google_ai.GenerateContentResponse(
  candidates: [
    google_ai.Candidate(
      content: google_ai.Content(
        role: 'model',
        parts: [google_ai.Part(text: jsonEncode(value))],
      ),
    ),
  ],
);

Map<String, Object?> _checkpointPlanDraft() {
  const slideKeys = [
    'opening',
    'signals',
    'synthesis',
    'choices',
    'alignment',
    'practice',
    'principle',
    'verification',
    'action',
    'close',
  ];
  const sectionKeys = [
    'tension',
    'tension',
    'tension',
    'system',
    'system',
    'system',
    'system',
    'action',
    'action',
    'action',
  ];
  const titles = [
    'Evidence Becomes Momentum',
    'Signals Arrive Before Decisions',
    'Synthesis Time Shifted',
    'Choose the Operating Model',
    'Align the Decision Frame',
    'Build a Shared Practice',
    'Trust Needs a Visible Trail',
    'Verify the Working Contract',
    'Make the Practice Explicit',
    'Decide, Learn, Repeat',
  ];
  const compositions = [
    'title',
    'content',
    'metric',
    'table',
    'twoColumn',
    'threeColumn',
    'quote',
    'content',
    'titleLeft',
    'title',
  ];
  const treatments = [
    'hero',
    'content',
    'data',
    'data',
    'content',
    'data',
    'quote',
    'content',
    'section',
    'closing',
  ];
  const roles = [
    'opening',
    'problem',
    'evidence',
    'comparison',
    'insight',
    'process',
    'takeaway',
    'process',
    'transition',
    'closing',
  ];

  return {
    'topic': 'Evidence-led product decisions',
    'story':
        'Move from scattered observations to a shared, reviewable decision '
        'practice.',
    'theme': {'id': 'technical-paper'},
    'sections': [
      {
        'key': 'tension',
        'title': 'The tension',
        'purpose': 'Make the decision delay concrete.',
        'transition': 'Move from the delay to the operating choices.',
        'slideKeys': slideKeys.sublist(0, 3),
      },
      {
        'key': 'system',
        'title': 'The system',
        'purpose': 'Explain the shared evidence practice.',
        'transition': 'Translate the practice into an explicit next action.',
        'slideKeys': slideKeys.sublist(3, 7),
      },
      {
        'key': 'action',
        'title': 'The action',
        'purpose': 'Make the next review cycle practical.',
        'transition': 'Close with a clear decision rhythm.',
        'slideKeys': slideKeys.sublist(7),
      },
    ],
    'slides': [
      for (var index = 0; index < slideKeys.length; index++)
        {
          'key': slideKeys[index],
          'title': titles[index],
          'purpose': 'Advance the evidence-led decision story.',
          'sectionKey': sectionKeys[index],
          'assertion': index == 2
              ? 'Teams spent 42% less weekly synthesis time.'
              : 'The ${titles[index].toLowerCase()} idea advances the story.',
          'contentUnits': index == 2
              ? ['Teams spent 42% less weekly synthesis time.']
              : [
                  'Concrete evidence for ${slideKeys[index]}.',
                  'Practical implication for ${slideKeys[index]}.',
                ],
          'narrativeRole': roles[index],
          'contentBrief': 'Keep the slide concise and decision-oriented.',
          'continuity': 'Connect this idea to the surrounding decision flow.',
          'composition': compositions[index],
          'treatment': treatments[index],
          'density': index % 3 == 0 ? 'spacious' : 'balanced',
          'elements': <Object?>[],
        },
    ],
  };
}

List<Map<String, Object?>> _checkpointSlides() => [
  _checkpointSlide(
    key: 'opening',
    title: 'Evidence Becomes Momentum',
    style: 'hero',
    blocks: [
      '# Evidence Becomes Momentum\n\n'
          'A shared evidence practice turns observation into a decision.',
    ],
  ),
  _checkpointSlide(
    key: 'signals',
    title: 'Signals Arrive Before Decisions',
    style: 'content',
    blocks: [
      '## Signals arrive before decisions\n\n'
          'Research, support, and product observations accumulate while the '
          'decision frame stays implicit.',
    ],
  ),
  _checkpointSlide(
    key: 'synthesis',
    title: 'Synthesis Time Shifted',
    style: 'data',
    blocks: [
      '# Teams spent 42% less weekly synthesis time\n\n'
          'The operating gain comes from reviewing a connected evidence '
          'trail.',
    ],
  ),
  _checkpointSlide(
    key: 'choices',
    title: 'Choose the Operating Model',
    style: 'data',
    blocks: [
      '## Choose the operating model\n\n'
          '| Model | Decision pace | Evidence trail |\n'
          '| --- | --- | --- |\n'
          '| Quarterly review | Slow | Fragmented |\n'
          '| Team dashboard | Medium | Local |\n'
          '| Shared loop | Fast | Connected |',
    ],
  ),
  _checkpointSlide(
    key: 'alignment',
    title: 'Align the Decision Frame',
    style: 'content',
    blocks: [
      '### Evidence\n\nKeep claims linked to their source.',
      '### Decision\n\nName the owner, trade-off, and review date.',
    ],
  ),
  _checkpointSlide(
    key: 'practice',
    title: 'Build a Shared Practice',
    style: 'data',
    blocks: [
      '### Capture\n\nCollect the relevant signal.',
      '### Connect\n\nRelate it to the decision.',
      '### Commit\n\nRecord the next review action.',
    ],
  ),
  _checkpointSlide(
    key: 'principle',
    title: 'Trust Needs a Visible Trail',
    style: 'quote',
    blocks: [
      '> A recommendation earns trust when evidence and next action stay '
          'together.\n\nDecision design principle',
    ],
  ),
  _checkpointSlide(
    key: 'verification',
    title: 'Verify the Working Contract',
    style: 'content',
    blocks: [
      '## Verify the working contract\n\n'
          '- Keep the selected theme reference stable\n'
          '- Replay the canonical Markdown\n'
          '- Inspect every full-size capture',
    ],
  ),
  _checkpointSlide(
    key: 'action',
    title: 'Make the Practice Explicit',
    style: 'section',
    blocks: [
      '## Make the practice explicit\n\n'
          'Use a shared review rhythm and record what changes next.',
    ],
  ),
  _checkpointSlide(
    key: 'close',
    title: 'Decide, Learn, Repeat',
    style: 'closing',
    blocks: [
      '# Decide, learn, repeat\n\n'
          'Keep evidence, decisions, and learning in the same operating loop.',
    ],
  ),
];

List<List<Map<String, Object?>>> _checkpointSectionSlides() {
  final slides = _checkpointSlides();
  return [slides.sublist(0, 3), slides.sublist(3, 7), slides.sublist(7)];
}

Map<String, Object?> _checkpointSlide({
  required String key,
  required String title,
  required String style,
  required List<String> blocks,
}) => {
  'key': key,
  'options': {'title': title, 'style': style},
  'sections': [
    {
      'type': 'section',
      'blocks': [
        for (final content in blocks) {'type': 'block', 'content': content},
      ],
    },
  ],
};
