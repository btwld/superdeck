import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:playground/app/providers.dart';
import 'package:playground/app/router.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_image_style.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_question_cards.dart';
import 'package:playground/features/ai/wizard/core/ui/ui.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:playground/features/editor/domain/files/deck_image_manifest.dart';
import 'package:playground/features/editor/presentation/pages/editor_page.dart';
import 'package:provider/provider.dart';

import '../test/helpers/fake_deck_file_repository.dart';

const _screenshotKey = ValueKey('integration-screenshot-surface');

final class _ControlledImageGenerator implements ImageGenerator {
  final List<ImageGenerationRequest> requests = [];
  final List<Completer<ImageGenerationResult>> _responses = [];

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) {
    requests.add(request);
    final response = Completer<ImageGenerationResult>();
    _responses.add(response);
    return response.future;
  }

  void completeNext(ImageGenerationResult result) {
    _responses.firstWhere((response) => !response.isCompleted).complete(result);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory screenshotDirectory;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    screenshotDirectory = Directory.systemTemp.createTempSync(
      'superdeck-wizard-image-generation-',
    );
    debugPrint('Integration screenshots: ${screenshotDirectory.path}');
  });

  testWidgets('Wizard previews and editor retries render on macOS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final watercolor = await _fixturePng(
      background: const Color(0xffdbeafe),
      foreground: const Color(0xff2563eb),
      accent: const Color(0xfff97316),
    );
    final geometric = await _fixturePng(
      background: const Color(0xffffedd5),
      foreground: const Color(0xff7c3aed),
      accent: const Color(0xff0f766e),
    );
    final minimalist = await _fixturePng(
      background: const Color(0xffecfccb),
      foreground: const Color(0xff15803d),
      accent: const Color(0xff4338ca),
    );

    final previewGenerator = _ControlledImageGenerator();
    final dataModel = InMemoryDataModel();
    addTearDown(dataModel.dispose);
    await tester.pumpWidget(
      _styleStepApp(generator: previewGenerator, dataModel: dataModel),
    );

    expect(find.byType(ImageStyleOptionCard), findsNWidgets(3));
    expect(find.byType(SdSpinner), findsNWidgets(3));
    expect(previewGenerator.requests, hasLength(1));
    await _capture(
      tester: tester,
      directory: screenshotDirectory,
      name: '01-wizard-previews-loading',
    );

    previewGenerator.completeNext(ImageGenerationSuccess(watercolor));
    await _pumpUntil(
      tester,
      () => previewGenerator.requests.length == 2,
      description: 'second preview request',
    );
    previewGenerator.completeNext(
      const ImageGenerationFailure('Provider unavailable. Try again.'),
    );
    await _pumpUntil(
      tester,
      () => previewGenerator.requests.length == 3,
      description: 'third preview request',
    );
    previewGenerator.completeNext(ImageGenerationSuccess(geometric));
    await _pumpUntil(
      tester,
      () => find.byType(SdSpinner).evaluate().isEmpty,
      description: 'completed preview states',
    );

    await tester.tap(
      find.byKey(const ValueKey('wizard-image-style-select-minimalist')),
    );
    await tester.pump();
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      tester
          .widget<ImageStyleOptionCard>(
            find.byKey(const ValueKey('wizard-image-style-minimalist')),
          )
          .selected,
      isTrue,
    );
    await _capture(
      tester: tester,
      directory: screenshotDirectory,
      name: '02-wizard-selected-broken-preview',
    );

    await tester.tap(
      find.byKey(const ValueKey('wizard-image-style-retry-minimalist')),
    );
    await tester.pump();
    expect(previewGenerator.requests, hasLength(4));
    previewGenerator.completeNext(ImageGenerationSuccess(minimalist));
    await _pumpUntil(
      tester,
      () => find.byIcon(Icons.broken_image_outlined).evaluate().isEmpty,
      description: 'successful preview retry',
    );
    await _capture(
      tester: tester,
      directory: screenshotDirectory,
      name: '03-wizard-preview-retry-success',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    const reference = DeckFileReference(path: '/decks/image-retry.md');
    const failedImage = GeneratedImageAsset.failure(
      assetKey: 'slide-02-risk-illustration.png',
      slideKey: 'risk',
      subject: 'a fragile bridge above a widening gap',
      prompt: 'Paint a fragile bridge above a widening gap.',
      aspectRatio: GeneratedImageAspectRatio.slide3x4,
      error: 'The provider returned no image. Try again.',
    );
    final repository = FakeDeckFileRepository()
      ..rememberedDeck = reference
      ..files[reference.path] = '# Image retry\n'
      ..imageManifests[deckAssetsDirectoryPath(reference.path)] =
          DeckImageManifest.fromAssets([failedImage]);
    final retryGenerator = _ControlledImageGenerator();

    await tester.pumpWidget(
      _editorApp(repository: repository, generator: retryGenerator),
    );
    await _pumpUntil(
      tester,
      () => find.byType(EditorPage).evaluate().isNotEmpty,
      description: 'editor bootstrap',
    );
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey('editor-image-issues'))
          .evaluate()
          .isNotEmpty,
      description: 'image issues manifest',
    );

    await tester.tap(find.byKey(const ValueKey('editor-image-issues')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('risk'), findsOneWidget);
    expect(
      find.text('The provider returned no image. Try again.'),
      findsOneWidget,
    );
    await _capture(
      tester: tester,
      directory: screenshotDirectory,
      name: '04-editor-image-issues-expanded',
    );

    await tester.tap(
      find.byKey(
        const ValueKey('editor-image-retry-slide-02-risk-illustration.png'),
      ),
    );
    await tester.pump();
    expect(retryGenerator.requests, hasLength(1));
    expect(retryGenerator.requests.single.prompt, failedImage.prompt);
    expect(
      retryGenerator.requests.single.aspectRatio,
      GeneratedImageAspectRatio.slide3x4,
    );
    retryGenerator.completeNext(ImageGenerationSuccess(minimalist));
    await _pumpUntil(
      tester,
      () =>
          find.byKey(const ValueKey('editor-image-issues')).evaluate().isEmpty,
      description: 'resolved editor image issue',
    );
    await _capture(
      tester: tester,
      directory: screenshotDirectory,
      name: '05-editor-image-retry-success',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}

Widget _styleStepApp({
  required ImageGenerator generator,
  required InMemoryDataModel dataModel,
}) {
  return RepaintBoundary(
    key: _screenshotKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HeroTheme(
        data: HeroThemeData.light(),
        child: Provider<ImageGenerator>.value(
          value: generator,
          child: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Builder(
                    builder: (context) => askUserImageStyle.widgetBuilder(
                      CatalogItemContext(
                        data: {
                          'question': 'Choose an artwork style',
                          'description':
                              'Preview one subject in three visual directions.',
                          'subject': 'a small team mapping a bold new idea',
                          'imageStyles': [
                            'watercolor',
                            'minimalist',
                            'geometric',
                          ],
                          'action': {
                            'name': 'submit_answer',
                            'context': <Object>[],
                          },
                        },
                        id: 'root',
                        type: 'AskUserImageStyle',
                        buildChild: (id, [dataContext]) => const SizedBox(),
                        dispatchEvent: (_) {},
                        buildContext: context,
                        dataContext: DataContext(dataModel, DataPath.root),
                        getComponent: (_) => null,
                        getCatalogItem: (_) => null,
                        surfaceId: 'integration-surface',
                        reportError: (error, stackTrace) => fail('$error'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _editorApp({
  required FakeDeckFileRepository repository,
  required ImageGenerator generator,
}) {
  return RepaintBoundary(
    key: _screenshotKey,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(initialLocation: '/editor'),
      builder: (context, child) => HeroTheme(
        data: HeroThemeData.light(),
        child: AppProviders(
          deckFileRepository: repository,
          imageGenerator: generator,
          child: child!,
        ),
      ),
    ),
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $description.');
}

Future<void> _capture({
  required WidgetTester tester,
  required Directory directory,
  required String name,
}) async {
  await tester.pump(const Duration(milliseconds: 500));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_screenshotKey),
  );
  _markSubtreeNeedsPaint(boundary);
  await tester.pump(const Duration(milliseconds: 32));
  final image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) fail('Could not encode screenshot $name.');
  final png = data.buffer.asUint8List();
  final file = File('${directory.path}/$name.png');
  await tester.runAsync(() => file.writeAsBytes(png, flush: true));
  expect(await file.length(), greaterThan(0));
  debugPrint('Screenshot: ${file.path}');
}

void _markSubtreeNeedsPaint(RenderObject renderObject) {
  renderObject.markNeedsPaint();
  renderObject.visitChildren(_markSubtreeNeedsPaint);
}

Future<Uint8List> _fixturePng({
  required Color background,
  required Color foreground,
  required Color accent,
}) async {
  const size = Size(960, 540);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final backgroundPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      [background, Color.lerp(background, foreground, 0.22)!],
    );
  canvas.drawRect(Offset.zero & size, backgroundPaint);

  final path = Path()
    ..moveTo(120, 420)
    ..quadraticBezierTo(340, 90, 510, 310)
    ..quadraticBezierTo(670, 500, 850, 120);
  canvas.drawPath(
    path,
    Paint()
      ..color = foreground.withValues(alpha: 0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawCircle(
    const Offset(700, 190),
    88,
    Paint()..color = accent.withValues(alpha: 0.88),
  );
  canvas.drawCircle(
    const Offset(285, 230),
    54,
    Paint()..color = Colors.white.withValues(alpha: 0.88),
  );

  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) throw StateError('Could not encode fixture PNG.');
  return data.buffer.asUint8List();
}
