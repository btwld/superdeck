import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'package:superdeck_example/src/parts/background.dart';
import 'package:superdeck_example/src/parts/footer.dart';
import 'package:superdeck_example/src/parts/header.dart';
import 'package:superdeck_example/src/style.dart';
import 'package:superdeck_example/src/templates.dart';
import 'package:superdeck_example/src/widgets/demo_widgets.dart';

var _reviewScreenshotRun = 0;
final _testRunRoot = Directory.current.path;
final _reviewScreenshotBoundaryKey = GlobalKey(
  debugLabel: 'review-screenshot-boundary',
);
const _slideTransitionSettleDuration = Duration(milliseconds: 100);
const _testSlideTransitionDuration = Duration.zero;

void assertNoFlutterException(WidgetTester tester) {
  final exceptions = <Object>[];

  while (true) {
    final exception = tester.takeException();
    if (exception == null) break;
    exceptions.add(exception);
  }

  if (exceptions.isEmpty) return;

  fail('Unexpected Flutter exception(s):\n${exceptions.join('\n\n')}');
}

void assertNoRenderedPresentationErrors(WidgetTester tester) {
  const errorTextPatterns = [
    'Error loading presentation',
    'Widget not found:',
    'Error building widget:',
    'Error loading image:',
    'Invalid image source:',
    'Image source is empty',
  ];

  final renderedErrors = <String>[];

  for (final pattern in errorTextPatterns) {
    final finder = find.textContaining(pattern);
    for (final element in finder.evaluate()) {
      final widget = element.widget;
      if (widget is Text) {
        renderedErrors.add(
          widget.data ?? widget.textSpan?.toPlainText() ?? pattern,
        );
      } else {
        renderedErrors.add(pattern);
      }
    }
  }

  if (renderedErrors.isEmpty) return;

  fail('Rendered presentation error(s):\n${renderedErrors.join('\n\n')}');
}

void assertPresentationHealthy(WidgetTester tester, DeckController controller) {
  if (controller.session.hasFatalError.value) {
    fail(
      'Presentation has fatal error: ${controller.session.error.value}\n'
      '${describeDeckControllerState(controller)}',
    );
  }

  assertNoRenderedPresentationErrors(tester);
  assertNoFlutterException(tester);
}

/// Opt-in review screenshots are artifact-only PNGs for human inspection.
///
/// Pixel assertions belong in package golden tests, such as the PDF export
/// dialog golden, not in these end-to-end integration scenarios.
Future<Directory?> captureAllSlidesForReview(
  WidgetTester tester,
  DeckController controller, {
  required String suiteName,
  required String scenarioName,
}) async {
  if (Platform.environment['SUPERDECK_CAPTURE_SLIDES'] != '1') return null;

  final originalIndex = controller.presentation.currentIndex.value;
  final outputDir = await _createReviewScreenshotOutputDir(
    suiteName: suiteName,
    scenarioName: scenarioName,
  );

  final totalSlides = controller.presentation.totalSlides.value;
  for (var index = 0; index < totalSlides; index++) {
    await tester.navigateToSlide(controller, index);
    await tester.pumpFor(const Duration(milliseconds: 150));
    assertPresentationHealthy(tester, controller);

    final slide = controller.slides.value[index];
    final slideNumber = (index + 1).toString().padLeft(2, '0');
    final fileName = '${slideNumber}_${_slug(slide.key)}.png';
    final bytes = await _captureReviewScreenshot();

    await File('${outputDir.path}/$fileName').writeAsBytes(bytes, flush: true);
  }

  if (originalIndex >= 0 && originalIndex < totalSlides) {
    await tester.navigateToSlide(controller, originalIndex);
  }

  return outputDir;
}

/// Captures clean, static slide frames without interactive app-shell chrome.
Future<Directory?> captureRenderedSlidesForReview(
  WidgetTester tester,
  DeckController controller, {
  required String suiteName,
  required String scenarioName,
}) async {
  if (Platform.environment['SUPERDECK_CAPTURE_SLIDES'] != '1') return null;

  final outputDir = await _createReviewScreenshotOutputDir(
    suiteName: suiteName,
    scenarioName: scenarioName,
  );
  final renderContext = tester.element(find.byType(Scaffold).first);
  final captureService = SlideCaptureService();
  final slides = controller.slides.value;

  for (var index = 0; index < slides.length; index++) {
    final slide = slides[index];
    final slideNumber = (index + 1).toString().padLeft(2, '0');
    final title = slide.options.title ?? slide.key;
    final fileName = '${slideNumber}_${_slug(title)}.png';
    final bytes = await captureService.capture(
      quality: SlideCaptureQuality.good,
      slide: slide,
      context: renderContext,
    );

    await File('${outputDir.path}/$fileName').writeAsBytes(bytes, flush: true);
  }

  return outputDir;
}

Future<Directory?> captureCurrentViewForReview(
  WidgetTester tester, {
  required String suiteName,
  required String scenarioName,
  String fileName = 'current-view.png',
}) async {
  if (Platform.environment['SUPERDECK_CAPTURE_SLIDES'] != '1') return null;

  final outputDir = await _createReviewScreenshotOutputDir(
    suiteName: suiteName,
    scenarioName: scenarioName,
  );
  await tester.pumpFor(const Duration(milliseconds: 150));
  final normalizedFileName = fileName.endsWith('.png')
      ? _slug(fileName)
      : '${_slug(fileName)}.png';
  final bytes = await _captureReviewScreenshot();
  await File(
    '${outputDir.path}/$normalizedFileName',
  ).writeAsBytes(bytes, flush: true);

  return outputDir;
}

Future<Directory> _createReviewScreenshotOutputDir({
  required String suiteName,
  required String scenarioName,
}) async {
  final runId = (++_reviewScreenshotRun).toString().padLeft(3, '0');
  final outputDir = Directory(
    '${_reviewScreenshotRoot().path}/${_slug(suiteName)}/'
    '${runId}_${_slug(scenarioName)}',
  );
  if (await outputDir.exists()) {
    await outputDir.delete(recursive: true);
  }
  await outputDir.create(recursive: true);

  return outputDir;
}

Future<List<int>> _captureReviewScreenshot() async {
  final boundaryContext = _reviewScreenshotBoundaryKey.currentContext;
  if (boundaryContext == null) {
    throw StateError('Review screenshot boundary is not mounted.');
  }
  if (!boundaryContext.mounted) {
    throw StateError('Review screenshot boundary is no longer mounted.');
  }

  final renderObject = boundaryContext.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError(
      'Review screenshot boundary has unexpected render object: '
      '${renderObject.runtimeType}',
    );
  }

  final image = await renderObject.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  if (byteData == null) {
    throw StateError('Could not encode review screenshot.');
  }

  return byteData.buffer.asUint8List();
}

Directory _reviewScreenshotRoot() {
  final configured = Platform.environment['SUPERDECK_SCREENSHOT_DIR'];
  if (configured != null && configured.trim().isNotEmpty) {
    return Directory(configured);
  }

  return Directory('$_testRunRoot/build/integration_screenshots');
}

String _slug(String value) {
  final slug = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  return slug.isEmpty ? 'unnamed' : slug;
}

String describeDeckControllerState(DeckController? controller) {
  if (controller == null) {
    return 'DeckController: null';
  }

  return [
    'DeckController state:',
    '  isLoading=${controller.session.isLoading.value}',
    '  hasError=${controller.session.hasFatalError.value}',
    '  error=${controller.session.error.value}',
    '  totalSlides=${controller.presentation.totalSlides.value}',
    '  currentIndex=${controller.presentation.currentIndex.value}',
    '  isMenuOpen=${controller.presentation.isMenuOpen.value}',
    '  isNotesOpen=${controller.presentation.isNotesOpen.value}',
  ].join('\n');
}

/// Test app widget that mirrors the production app configuration.
class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    this.deckLoader,
    this.workspace,
    this.options,
    this.extraWidgets = const {},
    this.plugins = const [],
  });

  final DeckLoader? deckLoader;
  final DeckWorkspace? workspace;
  final DeckOptions? options;
  final Map<String, WidgetFactory> extraWidgets;
  final List<DeckRuntimePlugin> plugins;

  static bool _initialized = false;

  /// Initializes dependencies for testing. Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    WidgetsFlutterBinding.ensureInitialized();
    SignalsObserver.instance = null;
    GoogleFonts.config.allowRuntimeFetching = false;
    WidgetsBinding.instance.ensureSemantics();
    await SuperDeckApp.initialize();
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _reviewScreenshotBoundaryKey,
      child: SuperDeckApp(
        deckLoader: deckLoader,
        workspace: workspace,
        assetCacheStore: const _TransparentThumbnailCacheStore(),
        options:
            options ??
            DeckOptions(
              baseStyle: borderedStyle(),
              widgets: {
                ...demoWidgets,
                'twitter': _testTwitterWidget,
                ...extraWidgets,
              },
              // Mirror the deck-level styles registered in `lib/main.dart` so
              // the harness resolves every `style:` used in `slides.md`.
              styles: {
                'announcement': announcementStyle(),
                'quote': quoteStyle(),
                'boxed': boxedStyle(),
              },
              templates: {
                'corporate': corporateTemplate(),
                'minimal': minimalTemplate(),
              },
              parts: const SlideParts(
                header: HeaderPart(),
                footer: FooterPart(),
                background: BackgroundPart(),
              ),
            ),
        transitionDuration: _testSlideTransitionDuration,
        plugins: plugins,
      ),
    );
  }
}

class _TransparentThumbnailCacheStore implements AssetCacheStore {
  const _TransparentThumbnailCacheStore();

  static Future<Uri>? _fixtureUriFuture;

  static Future<Uri> _fixtureUri() {
    return _fixtureUriFuture ??= _writeFixture();
  }

  static Future<Uri> _writeFixture() async {
    final file = File(
      '$_testRunRoot/build/integration_fixtures/thumbnails/'
      'transparent-thumbnail.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(
      base64Decode(transparentPixelPngBase64),
      flush: true,
    );
    return file.absolute.uri;
  }

  @override
  Future<void> delete(String assetKey) async {
    AssetCacheStore.validateAssetKey(assetKey);
  }

  @override
  Future<Uri?> resolve(String assetKey) async {
    AssetCacheStore.validateAssetKey(assetKey);
    return _fixtureUri();
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    AssetCacheStore.validateAssetKey(assetKey);
    return _fixtureUri();
  }
}

class _TestTwitterWidget extends StatelessWidget {
  const _TestTwitterWidget({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.purple,
        child: Text(
          'Twitter: $username',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

Widget _testTwitterWidget(Map<String, Object?> args) {
  return _TestTwitterWidget(username: args['username'] as String? ?? '');
}

/// Builds a minimal [Slide] with a single content block.
Slide makeSlide(String key, String content) {
  return Slide(
    key: key,
    sections: [
      SectionBlock([ContentBlock(content)]),
    ],
  );
}

List<Slide> makeSlides(int count) {
  return List.generate(
    count,
    (index) => makeSlide('s${index + 1}', '# Slide ${index + 1}'),
  );
}

/// Serializes slides to a JSON string suitable for `superdeck.json`.
String buildSlideJson(List<Slide> slides) {
  return jsonEncode(slides.map((s) => s.toJson()).toList());
}

String _statusJson(String status, int seq, {String? errorJson}) {
  final ts = '2026-03-10T10:00:${seq.toString().padLeft(2, '0')}.000Z';
  final buf = StringBuffer('{"status":"$status","timestamp":"$ts"');
  if (errorJson != null) {
    buf.write(',"error":$errorJson');
  }
  buf.write('}');
  return buf.toString();
}

/// Writes `superdeck.json` then `build_status.json` with `success` status.
Future<void> simulateBuildSuccess(
  DeckWorkspace ws,
  List<Slide> slides,
  int seq,
) async {
  await ws.superdeckDir.create(recursive: true);
  await ws.deckJson.writeAsString(buildSlideJson(slides));
  await ws.buildStatusJson.writeAsString(_statusJson('success', seq));
}

/// Writes `build_status.json` with `failure` status and an error message.
Future<void> simulateBuildFailure(
  DeckWorkspace ws,
  String message,
  int seq,
) async {
  await ws.superdeckDir.create(recursive: true);
  final errorMap = {'type': 'BuildFailure', 'message': message};
  await ws.buildStatusJson.writeAsString(
    _statusJson('failure', seq, errorJson: jsonEncode(errorMap)),
  );
}

/// Writes `build_status.json` with `building` status.
Future<void> simulateBuilding(DeckWorkspace ws, int seq) async {
  await ws.superdeckDir.create(recursive: true);
  await ws.buildStatusJson.writeAsString(_statusJson('building', seq));
}

Future<LocalImageFixture> createLocalPngFixture({
  String relativePath =
      'build/integration_fixtures/local_images/sample-local.png',
}) async {
  final file = File('${Directory.current.path}/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(base64Decode(transparentPixelPngBase64), flush: true);

  return LocalImageFixture(
    relativePath: relativePath,
    absolutePath: file.absolute.path,
    fileUri: file.absolute.uri.toString(),
  );
}

const transparentPixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

const transparentPixelDataUri =
    'data:image/png;base64,$transparentPixelPngBase64';

class LocalImageFixture {
  const LocalImageFixture({
    required this.relativePath,
    required this.absolutePath,
    required this.fileUri,
  });

  final String relativePath;
  final String absolutePath;
  final String fileUri;
}

/// Finds the DeckController from the widget tree.
///
/// Returns null if the controller cannot be found.
DeckController? findDeckController(WidgetTester tester) {
  try {
    final scaffoldFinder = find.byType(Scaffold);
    if (scaffoldFinder.evaluate().isEmpty) return null;

    final element = tester.element(scaffoldFinder.first);
    return DeckController.of(element);
  } catch (e) {
    return null;
  }
}

/// Extension on WidgetTester for common integration test operations.
extension IntegrationTestExtensions on WidgetTester {
  /// Pumps frames for a bounded amount of test time.
  Future<void> pumpFor(
    Duration duration, {
    Duration step = const Duration(milliseconds: 50),
  }) async {
    final steps = duration.inMicroseconds ~/ step.inMicroseconds;
    for (var i = 0; i < steps; i++) {
      await pump(step);
    }
  }

  /// Unmounts the current test app and flushes one frame of disposal work.
  Future<void> unmountTestApp() async {
    await pumpWidget(const SizedBox.shrink());
    await pump();
  }

  /// Pumps until [condition] is true or [timeout] is reached.
  Future<void> pumpUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration step = const Duration(milliseconds: 50),
    String debugLabel = 'condition',
    String Function()? onTimeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (condition()) {
        return;
      }
      await pump(step);
    }

    final diagnostics = onTimeout?.call();
    if (diagnostics == null || diagnostics.isEmpty) {
      fail('Timed out waiting for $debugLabel after ${timeout.inSeconds}s');
    }

    fail(
      'Timed out waiting for $debugLabel after ${timeout.inSeconds}s\n'
      'Diagnostics:\n$diagnostics',
    );
  }

  /// Pumps a [TestApp] with the given [DeckLoader], waits for slides to load.
  Future<DeckController> pumpTestAppWithLoader(
    DeckLoader loader, {
    required DeckWorkspace workspace,
    Map<String, WidgetFactory> extraWidgets = const {},
    List<DeckRuntimePlugin> plugins = const [],
  }) async {
    await pumpWidget(
      TestApp(
        deckLoader: loader,
        workspace: workspace,
        extraWidgets: extraWidgets,
        plugins: plugins,
      ),
    );
    await pumpFor(const Duration(milliseconds: 200));

    await pumpUntil(
      () => findDeckController(this) != null,
      timeout: const Duration(seconds: 15),
      debugLabel: 'DeckController to mount (with loader)',
      onTimeout: () => _startupDiagnostics(),
    );

    final controller = findDeckController(this)!;
    await waitForSlidesLoaded(controller);
    return controller;
  }

  /// Pumps the test app with a temporary workspace containing [slides].
  Future<DeckController> pumpTestAppWithSlides(
    List<Slide> slides, {
    Map<String, WidgetFactory> extraWidgets = const {},
    List<DeckRuntimePlugin> plugins = const [],
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('sd_fixture_app_');
    FileDeckLoader? loader;
    addTearDown(() async {
      await loader?.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final workspace = DeckWorkspace(projectDir: tempDir.path);
    await simulateBuildSuccess(workspace, slides, 1);

    final fileLoader = FileDeckLoader(workspace: workspace);
    loader = fileLoader;

    return pumpTestAppWithLoader(
      fileLoader,
      workspace: workspace,
      extraWidgets: extraWidgets,
      plugins: plugins,
    );
  }

  /// Pumps the test app, waits for it to fully load, and returns the controller.
  ///
  /// Fails the test if the controller cannot be found or slides fail to load.
  Future<DeckController> pumpTestApp() async {
    await pumpWidget(const TestApp());
    await pumpFor(const Duration(milliseconds: 200));

    await pumpUntil(
      () => findDeckController(this) != null,
      timeout: const Duration(seconds: 15),
      debugLabel: 'DeckController to mount',
      onTimeout: () => _startupDiagnostics(),
    );

    final controller = findDeckController(this)!;
    await waitForSlidesLoaded(controller);
    return controller;
  }

  /// Waits for the app to finish loading slides.
  Future<void> waitForSlidesLoaded(DeckController controller) async {
    await pumpUntil(
      () => !controller.session.isLoading.value,
      timeout: const Duration(seconds: 20),
      debugLabel: 'slides to finish loading',
      onTimeout: () => describeDeckControllerState(controller),
    );

    if (controller.session.hasFatalError.value) {
      fail(
        'Presentation failed to load: ${controller.session.error.value}\n'
        '${describeDeckControllerState(controller)}',
      );
    }

    await pumpFor(const Duration(milliseconds: 200));
  }

  /// Navigates to a specific slide and waits for transition to complete.
  Future<void> navigateToSlide(
    DeckController controller,
    int index, {
    String? context,
  }) async {
    unawaited(controller.presentation.goToSlide(index));
    await pumpUntil(
      () => controller.presentation.currentIndex.value == index,
      timeout: const Duration(seconds: 5),
      debugLabel: context ?? 'navigation to slide $index',
      onTimeout: () => describeDeckControllerState(controller),
    );
    await pumpFor(_slideTransitionSettleDuration);
  }

  Future<void> assertScrollableMoves(
    Finder scrollContainerFinder, {
    Offset dragOffset = const Offset(0, -320),
  }) async {
    expect(scrollContainerFinder, findsOneWidget);
    final scrollableFinder = find.descendant(
      of: scrollContainerFinder,
      matching: find.byType(Scrollable),
    );
    expect(scrollableFinder, findsOneWidget);
    final state = this.state<ScrollableState>(scrollableFinder.first);
    final before = state.position.pixels;

    await drag(scrollableFinder.first, dragOffset);
    await pumpFor(const Duration(milliseconds: 300));

    expect(state.position.pixels, greaterThan(before));
  }

  /// Taps a widget found by [finder], scrolling it into view first if needed.
  /// Uses `warnIfMissed: false` to handle edge-of-screen widgets (e.g. bottom bar).
  Future<void> tapByLabel(String label) async {
    final finder = find.bySemanticsLabel(label);
    expect(
      finder,
      findsWidgets,
      reason: 'Could not find widget with label "$label"',
    );
    await ensureVisible(finder.first);
    await pumpFor(const Duration(milliseconds: 100));
    await tap(finder.first, warnIfMissed: false);
  }

  Future<void> sendMetaKey(LogicalKeyboardKey key) async {
    await sendKeyDownEvent(LogicalKeyboardKey.meta);
    await sendKeyDownEvent(key);
    await sendKeyUpEvent(key);
    await sendKeyUpEvent(LogicalKeyboardKey.meta);
    await pumpFor(const Duration(milliseconds: 200));
  }

  String _startupDiagnostics() {
    final controller = findDeckController(this);
    return [
      describeDeckControllerState(controller),
      'Scaffold count=${find.byType(Scaffold).evaluate().length}',
      'Error text count=${find.textContaining('Error loading presentation').evaluate().length}',
    ].join('\n');
  }
}

Future<void> assertReviewScreenshots({
  required Directory? outputDir,
  required int expectedCount,
  Size expectedSize = const Size(1280, 720),
}) async {
  if (Platform.environment['SUPERDECK_CAPTURE_SLIDES'] != '1') return;
  if (outputDir == null) return;

  expect(await outputDir.exists(), isTrue);
  final pngFiles = <File>[];
  await for (final entity in outputDir.list()) {
    if (entity is File && entity.path.endsWith('.png')) {
      pngFiles.add(entity);
    }
  }
  pngFiles.sort((a, b) => a.path.compareTo(b.path));

  expect(pngFiles, hasLength(expectedCount));

  for (final file in pngFiles) {
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(1000), reason: file.path);

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    expect(image.width, expectedSize.width.toInt(), reason: file.path);
    expect(image.height, expectedSize.height.toInt(), reason: file.path);

    final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    expect(raw, isNotNull, reason: file.path);

    final pixels = raw!.buffer.asUint8List();
    var hasVisiblePixel = false;
    for (var i = 0; i < pixels.length; i += 4) {
      final red = pixels[i];
      final green = pixels[i + 1];
      final blue = pixels[i + 2];
      final alpha = pixels[i + 3];
      if (alpha > 0 && (red > 0 || green > 0 || blue > 0)) {
        hasVisiblePixel = true;
        break;
      }
    }

    expect(hasVisiblePixel, isTrue, reason: file.path);
  }
}
