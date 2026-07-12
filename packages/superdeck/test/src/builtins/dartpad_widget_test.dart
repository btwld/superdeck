import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/builtins/dartpad_widget.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/ui/widgets/webview_wrapper.dart';
import 'package:superdeck_core/superdeck_core.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../helpers/mock_deck_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DartPadDto', () {
    group('constructor', () {
      test('uses embed and run defaults', () {
        const dto = DartPadDto(id: 'snippet');

        expect(dto.id, 'snippet');
        expect(dto.theme, isNull);
        expect(dto.embed, isTrue);
        expect(dto.run, isTrue);
        expect(dto.cacheKey, isNull);
      });
    });

    group('schema', () {
      test('accepts valid arguments', () {
        final result = DartPadDto.schema.safeParse({
          'id': 'snippet',
          'theme': 'dark',
          'embed': false,
          'run': true,
          'cacheKey': 'shared-pad',
        });

        expect(result.isOk, isTrue);
      });

      test('rejects invalid arguments', () {
        final result = DartPadDto.schema.safeParse({
          'id': '',
          'embed': 'false',
        });

        expect(result.isOk, isFalse);
      });
    });

    group('parse', () {
      test('returns typed values for valid arguments', () {
        final dto = DartPadDto.parse({
          'id': 'snippet',
          'theme': 'dark',
          'embed': false,
          'run': false,
          'cacheKey': 'pad-1',
        });

        expect(dto.id, 'snippet');
        expect(dto.theme, DartPadTheme.dark);
        expect(dto.embed, isFalse);
        expect(dto.run, isFalse);
        expect(dto.cacheKey, 'pad-1');
      });

      test('uses defaults when optional fields are omitted or null', () {
        final omitted = DartPadDto.parse({'id': 'omitted'});
        final explicitNull = DartPadDto.parse({
          'id': 'explicit-null',
          'theme': null,
          'embed': null,
          'run': null,
          'cacheKey': null,
        });

        expect(omitted.theme, isNull);
        expect(omitted.embed, isTrue);
        expect(omitted.run, isTrue);
        expect(omitted.cacheKey, isNull);
        expect(explicitNull.theme, isNull);
        expect(explicitNull.embed, isTrue);
        expect(explicitNull.run, isTrue);
        expect(explicitNull.cacheKey, isNull);
      });

      test('rejects a missing or empty id', () {
        expect(() => DartPadDto.parse({}), throwsA(anything));
        expect(() => DartPadDto.parse({'id': ''}), throwsA(anything));
      });

      test('rejects arguments with wrong types', () {
        final invalidArgs = [
          {'id': 42},
          {'id': 'snippet', 'theme': 42},
          {'id': 'snippet', 'theme': 'neon'},
          {'id': 'snippet', 'embed': 'false'},
          {'id': 'snippet', 'run': 1},
        ];

        for (final args in invalidArgs) {
          expect(() => DartPadDto.parse(args), throwsA(anything));
        }
      });
    });

    group('toUrl', () {
      test('builds a DartPad URL with every argument', () {
        const dto = DartPadDto(
          id: 'snippet',
          theme: DartPadTheme.dark,
          embed: false,
          run: false,
        );

        expect(
          dto.toUrl(),
          'https://dartpad.dev/?id=snippet&theme=dark&embed=false&run=false',
        );
      });

      test('builds a DartPad URL with default arguments', () {
        const dto = DartPadDto(id: 'snippet');

        expect(
          dto.toUrl(),
          'https://dartpad.dev/?id=snippet&embed=true&run=true',
        );
      });
    });
  });

  group('DartPadWidget', () {
    late _FakeWebViewPlatform webViewPlatform;
    late MockDeckLoader loader;
    late DeckController deckController;

    setUp(() {
      webViewPlatform = _FakeWebViewPlatform();
      WebViewPlatform.instance = webViewPlatform;
      loader = MockDeckLoader();
      deckController = DeckController(
        deckLoader: loader,
        options: DeckOptions(),
      );
    });

    tearDown(() async {
      deckController.dispose();
      await loader.dispose();
    });

    testWidgets('renders a web view wrapper for the DartPad URL', (
      tester,
    ) async {
      const size = Size(640, 480);

      await tester.pumpWidget(
        _DartPadHarness(
          deckController: deckController,
          size: size,
          runtimeKey: 'slide-0:s0:b0',
          args: {
            'id': 'snippet',
            'theme': 'light',
            'embed': true,
            'run': false,
          },
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(WebViewWrapper), findsOneWidget);

      final wrapper = tester.widget<WebViewWrapper>(
        find.byType(WebViewWrapper),
      );

      expect(tester.getSize(find.byType(WebViewWrapper)), size);
      expect(
        wrapper.url,
        'https://dartpad.dev/?id=snippet&theme=light&embed=true&run=false',
      );
      expect(wrapper.showControls, isTrue);
      expect(wrapper.showClearControl, isTrue);
      expect(find.byKey(const ValueKey('fake-web-view')), findsOneWidget);
      expect(webViewPlatform.controllers, hasLength(1));
      expect(
        webViewPlatform.controllers.single.loadedRequests.single.uri.toString(),
        wrapper.url,
      );
      expect(
        webViewPlatform.controllers.single.javaScriptMode,
        JavaScriptMode.unrestricted,
      );
      expect(webViewPlatform.controllers.single.navigationDelegate, isNotNull);
    });

    testWidgets('reload and clear controls call the WebView controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        _DartPadHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: const {'id': 'snippet'},
        ),
      );
      await tester.pump();

      final controller = webViewPlatform.controllers.single;

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.reloadCount, 1);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(controller.javaScripts.single, contains("setValue('')"));
      expect(tester.takeException(), isNull);
    });

    testWidgets('controls tolerate unsupported web iframe APIs', (
      tester,
    ) async {
      webViewPlatform = _WebLikeWebViewPlatform();
      WebViewPlatform.instance = webViewPlatform;

      await tester.pumpWidget(
        _DartPadHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: const {'id': 'snippet'},
        ),
      );
      await tester.pump();

      final controller = webViewPlatform.controllers.single;

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.reloadCount, 0);
      expect(controller.loadedRequests, hasLength(2));

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(controller.javaScripts, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('page finished fades in the WebView', (tester) async {
      await tester.pumpWidget(
        _DartPadHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: const {'id': 'snippet'},
        ),
      );
      await tester.pump();

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );

      final delegate =
          webViewPlatform.controllers.single.navigationDelegate!
              as _FakeNavigationDelegate;
      delegate.onPageFinished?.call('https://dartpad.dev/?id=snippet');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
    });

    testWidgets('loads a new request when DartPad URL updates', (tester) async {
      await tester.pumpWidget(
        _DartPadHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: const {'id': 'first'},
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _DartPadHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: const {'id': 'second', 'theme': 'dark'},
        ),
      );
      await tester.pump();

      final controller = webViewPlatform.controllers.single;
      expect(controller.loadedRequests, hasLength(2));
      expect(
        controller.loadedRequests.last.uri.toString(),
        'https://dartpad.dev/?id=second&theme=dark&embed=true&run=true',
      );
    });

    testWidgets(
      'cached remount reuses controller and does not loadRequest again',
      (tester) async {
        await tester.pumpWidget(
          _DartPadHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-0:s0:b0',
            args: const {'id': 'snippet'},
          ),
        );
        await tester.pump();

        expect(webViewPlatform.controllers, hasLength(1));
        expect(webViewPlatform.controllers.single.loadedRequests, hasLength(1));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        await tester.pumpWidget(
          _DartPadHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-0:s0:b0',
            args: const {'id': 'snippet'},
          ),
        );
        await tester.pump();

        expect(webViewPlatform.controllers, hasLength(1));
        expect(webViewPlatform.controllers.single.loadedRequests, hasLength(1));

        // Refresh and clear still work after remount.
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump(const Duration(milliseconds: 200));
        expect(webViewPlatform.controllers.single.reloadCount, 1);

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();
        expect(
          webViewPlatform.controllers.single.javaScripts.single,
          contains("setValue('')"),
        );
      },
    );

    testWidgets('navigation delegate allows same host and blocks others', (
      tester,
    ) async {
      await tester.pumpWidget(
        _DartPadHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: const {'id': 'snippet'},
        ),
      );
      await tester.pump();

      final delegate =
          webViewPlatform.controllers.single.navigationDelegate!
              as _FakeNavigationDelegate;

      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(
            url: 'https://dartpad.dev/?id=next',
            isMainFrame: true,
          ),
        ),
        NavigationDecision.navigate,
      );
      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(
            url: 'https://example.com/phishing',
            isMainFrame: true,
          ),
        ),
        NavigationDecision.prevent,
      );
    });
  });
}

class _DartPadHarness extends StatelessWidget {
  final DeckController deckController;
  final Map<String, Object?> args;
  final Size size;
  final String runtimeKey;

  const _DartPadHarness({
    required this.deckController,
    required this.args,
    required this.size,
    required this.runtimeKey,
  });

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration(
      slideIndex: 0,
      style: SlideStyle(),
      slide: Slide(
        key: 'slide-0',
        sections: [
          SectionBlock([ContentBlock('placeholder')]),
        ],
      ),
      thumbnailKey: buildThumbnailKey('slide-0'),
    );

    return MaterialApp(
      home: InheritedData<DeckController>(
        data: deckController,
        child: InheritedData<SlideConfiguration>(
          data: slide,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: size,
                child: InheritedData<BlockConfiguration>(
                  data: BlockConfiguration(
                    spec: const SlideSpec(),
                    size: size,
                    align: ContentAlignment.centerLeft,
                    runtimeKey: runtimeKey,
                  ),
                  child: DartPadWidget(args),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FakeWebViewPlatform extends WebViewPlatform {
  final controllers = <_FakeWebViewController>[];

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = _FakeWebViewController(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _FakeNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _FakeWebViewWidget(params);
  }
}

class _WebLikeWebViewPlatform extends _FakeWebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = _WebLikeWebViewController(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    // Mirrors webview_flutter_web, which does not implement
    // createPlatformNavigationDelegate. NavigationDelegate(...) therefore throws
    // at construction, before the controller's setNavigationDelegate is reached.
    throw UnimplementedError(
      'createPlatformNavigationDelegate is not implemented on the current platform.',
    );
  }
}

class _FakeWebViewController extends PlatformWebViewController {
  final loadedRequests = <LoadRequestParams>[];
  final javaScripts = <String>[];

  JavaScriptMode? javaScriptMode;
  PlatformNavigationDelegate? navigationDelegate;
  int reloadCount = 0;

  _FakeWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedRequests.add(params);
  }

  @override
  Future<void> reload() async {
    reloadCount += 1;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    javaScripts.add(javaScript);
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    this.javaScriptMode = javaScriptMode;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    navigationDelegate = handler;
  }
}

class _WebLikeWebViewController extends _FakeWebViewController {
  _WebLikeWebViewController(super.params);

  @override
  Future<void> reload() {
    throw UnimplementedError(
      'reload is not implemented on the current platform',
    );
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    throw UnimplementedError(
      'runJavaScript is not implemented on the current platform',
    );
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) {
    throw UnimplementedError(
      'setJavaScriptMode is not implemented on the current platform',
    );
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) {
    throw UnimplementedError(
      'setPlatformNavigationDelegate is not implemented on the current platform',
    );
  }
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  NavigationRequestCallback? onNavigationRequest;
  PageEventCallback? onPageFinished;

  _FakeNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    this.onNavigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    this.onPageFinished = onPageFinished;
  }
}

class _FakeWebViewWidget extends PlatformWebViewWidget {
  _FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: ValueKey('fake-web-view'));
  }
}
