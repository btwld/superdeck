import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generation_request.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_generator_service.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_plan_validator.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_element_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_quality_report.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/generation_trace.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/style_json_serializer.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart' show Slide, WidgetBlock;

const _apiKey = String.fromEnvironment('GOOGLE_AI_API_KEY');
const _selectedFixture = String.fromEnvironment(
  'LIVE_FIXTURE',
  defaultValue: 'all',
);
const _artifactPath = String.fromEnvironment('LIVE_ARTIFACT');
const _smokeFixtures = ['narrative', 'comparison_table', 'visual_elements'];
const _largeDeckFixtures = [
  'narrative_10',
  'decision_data_15',
  'visual_product_20',
];

typedef _CaptureResult = ({
  List<File> pngs,
  int replayedSlideCount,
  Set<String> resolvedFontFamilies,
  Duration elapsed,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This file is explicitly opt-in and must bypass flutter_test's HTTP 400
  // isolation so the production Gemini client can reach the network.
  HttpOverrides.global = null;
  GoogleFonts.config.allowRuntimeFetching = true;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );

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
          return (
            output: output,
            markdown: await File(
              p.join(output.path, 'slides.md'),
            ).readAsString(),
            style: DeckStyleType.parse(deckJson['style']),
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
          ...validateDeckPlan(artifact.plan, request: artifact.request),
          for (final (index, rawSlide) in artifact.rawSlides.indexed)
            ...validateGeneratedSlide(
              expectedKey: artifact.plan.slides[index].key,
              rawSlide: rawSlide,
              planSlide: artifact.plan.slides[index],
              request: artifact.request,
              elementCatalog: GenerationElementCatalog.builtIn(),
            ).map((error) => 'Slide ${index + 1}: $error'),
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
          style: artifact.style,
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
      late DeckStyleType style;
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
            'style': serializeDeckStyleForJson(result.style!),
            'slides': result.slides.map((slide) => slide.toMap()).toList(),
          };
          await File(
            p.join(output.path, 'deck.json'),
          ).writeAsString(const JsonEncoder.withIndent('  ').convert(deckJson));
          markdown = const SlideSerializer().serialize(result.slides);
          style = result.style!;
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
            style: style,
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

DeckGenerationRequest _requestForFixture(String fixture, String brief) {
  return switch (fixture) {
    'narrative' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 6,
      audience: 'Engineering leaders',
      approach: 'Confident editorial narrative',
      designDirection: 'Dark navy editorial',
    ),
    'comparison_table' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 5,
      audience: 'Product team',
      approach: 'Evidence-led decision deck',
      designDirection: 'Light warm',
    ),
    'visual_elements' => DeckGenerationRequest(
      userIntent: brief,
      slideCount: 5,
      audience: 'Developers and technical leaders',
      approach: 'Product launch briefing',
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
  var requestIndex = 0;
  for (final event in traces.where(
    (event) => event.phase == GenerationTracePhase.slide,
  )) {
    if (event.kind == GenerationTraceKind.request) {
      requestIndex++;
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
  await File(p.join(output.path, 'metadata.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'models': traces
          .map((event) => event.model)
          .whereType<String>()
          .toSet()
          .toList(),
      'elapsedMs': traces.isEmpty ? 0 : traces.last.elapsed.inMilliseconds,
      'requestCount': requestIndex,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    }),
  );
}

Future<_CaptureResult> _captureSlides({
  required WidgetTester tester,
  required Directory output,
  required String markdown,
  required DeckStyleType style,
  required int expectedSlideCount,
}) async {
  final startedAt = DateTime.now();
  // ignore: avoid_print
  print('Preparing capture context');
  final resolvedFontFamilies = (await tester.runAsync(
    () => _loadCaptureFonts(style),
  ))!;
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: style.fonts.body),
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
  customization.applyGeneratedStyle(
    GeneratedDeckStyle(
      background: _color(style.colors.background),
      surface: _color(style.colors.surface),
      surfaceAlt: _color(style.colors.surfaceAlt),
      heading: _color(style.colors.heading),
      body: _color(style.colors.body),
      accent: _color(style.colors.accent),
      accentContrast: _color(style.colors.accentContrast),
      headlineFamily: style.fonts.headline,
      bodyFamily: style.fonts.body,
      direction: style.direction,
      density: style.density,
      typeScale: style.typeScale,
    ),
  );
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

Future<Set<String>> _loadCaptureFonts(DeckStyleType style) async {
  final families = {style.fonts.headline, style.fonts.body};
  final fontStyles = <TextStyle>[];
  for (final family in families) {
    if (!GoogleFonts.asMap().containsKey(family)) {
      throw StateError(
        'Live capture cannot resolve Google font "$family". '
        'Registered bundled fonts need an explicit capture loader.',
      );
    }
    for (final weight in const [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
    ]) {
      fontStyles.add(GoogleFonts.getFont(family, fontWeight: weight));
    }
  }
  await GoogleFonts.pendingFonts(fontStyles);
  return families;
}

Future<void> _writeContactSheet(Directory output, List<File> files) async {
  final decoded = <image.Image>[];
  for (final file in files) {
    final value = image.decodePng(await file.readAsBytes());
    if (value != null) decoded.add(image.copyResize(value, width: 480));
  }
  if (decoded.isEmpty) return;
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
  await File(
    p.join(output.path, 'contact_sheet.png'),
  ).writeAsBytes(image.encodePng(sheet));
}

Color _color(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
}
