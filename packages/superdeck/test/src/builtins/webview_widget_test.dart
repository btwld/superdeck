import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/builtins/webview_widget.dart';
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

  group('WebViewDto', () {
    group('schema', () {
      test('accepts valid arguments', () {
        final result = WebViewDto.schema.safeParse({
          'url': 'https://example.com/page',
          'cacheKey': 'shared',
          'title': 'Example',
          'allowedHosts': ['example.com', 'cdn.example.com'],
          'showControls': true,
          'javascript': false,
        });

        expect(result.isOk, isTrue);
      });

      test('rejects missing url', () {
        final result = WebViewDto.schema.safeParse({});
        expect(result.isOk, isFalse);
      });
    });

    group('parse', () {
      test('returns typed values with defaults', () {
        final dto = WebViewDto.parse({'url': 'https://example.com'});

        expect(dto.url, 'https://example.com');
        expect(dto.cacheKey, isNull);
        expect(dto.title, isNull);
        expect(dto.allowedHosts, isNull);
        expect(dto.showControls, isFalse);
        expect(dto.javascript, isTrue);
      });

      test('parses optional fields', () {
        final dto = WebViewDto.parse({
          'url': 'https://example.com/app',
          'cacheKey': 'k1',
          'title': 'App',
          'allowedHosts': ['example.com'],
          'showControls': true,
          'javascript': false,
        });

        expect(dto.cacheKey, 'k1');
        expect(dto.title, 'App');
        expect(dto.allowedHosts, ['example.com']);
        expect(dto.showControls, isTrue);
        expect(dto.javascript, isFalse);
      });

      test('rejects non-http schemes and relative urls', () {
        final invalid = [
          {'url': 'ftp://example.com'},
          {'url': 'file:///tmp/x'},
          {'url': 'javascript:alert(1)'},
          {'url': '/relative/path'},
          {'url': 'example.com'},
          {'url': ''},
        ];

        for (final args in invalid) {
          expect(
            () => WebViewDto.parse(args),
            throwsA(anything),
            reason: 'should reject $args',
          );
        }
      });

      test('accepts http and https absolute urls', () {
        expect(
          WebViewDto.parse({'url': 'http://localhost:8080'}).url,
          'http://localhost:8080',
        );
        expect(
          WebViewDto.parse({'url': 'https://example.com/path?q=1'}).url,
          'https://example.com/path?q=1',
        );
      });
    });
  });

  group('WebViewWidget', () {
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

    testWidgets('renders a web view for a valid url', (tester) async {
      const size = Size(640, 480);

      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: size,
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com/demo'},
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(WebViewWrapper), findsOneWidget);

      final wrapper = tester.widget<WebViewWrapper>(
        find.byType(WebViewWrapper),
      );
      expect(tester.getSize(find.byType(WebViewWrapper)), size);
      expect(wrapper.url, 'https://example.com/demo');
      expect(wrapper.showControls, isFalse);
      expect(find.byKey(const ValueKey('fake-web-view')), findsOneWidget);
      expect(webViewPlatform.controllers, hasLength(1));
      expect(
        webViewPlatform.controllers.single.loadedRequests.single.uri.toString(),
        'https://example.com/demo',
      );
      expect(
        webViewPlatform.controllers.single.javaScriptMode,
        JavaScriptMode.unrestricted,
      );
    });

    testWidgets('renders when optional webview APIs are unsupported', (
      tester,
    ) async {
      webViewPlatform = _WebLikeWebViewPlatform();
      WebViewPlatform.instance = webViewPlatform;

      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com/web', 'javascript': false},
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('fake-web-view')), findsOneWidget);
      expect(webViewPlatform.controllers, hasLength(1));
      expect(webViewPlatform.controllers.single.navigationDelegate, isNull);
      expect(webViewPlatform.controllers.single.javaScriptMode, isNull);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      expect(
        webViewPlatform.controllers.single.loadedRequests.single.uri.toString(),
        'https://example.com/web',
      );
    });

    testWidgets('fills the block viewport under scrollable constraints', (
      tester,
    ) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          unboundedHeight: true,
          args: {'url': 'https://example.com/scrollable'},
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(WebViewWrapper)), const Size(640, 480));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reuses controller on remount with same cache identity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com/a'},
        ),
      );
      await tester.pump();

      expect(webViewPlatform.controllers, hasLength(1));
      expect(webViewPlatform.controllers.single.loadedRequests, hasLength(1));

      // Dispose the tree (leave slide).
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Remount same block identity.
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com/a'},
        ),
      );
      await tester.pump();

      expect(webViewPlatform.controllers, hasLength(1));
      expect(webViewPlatform.controllers.single.loadedRequests, hasLength(1));
      expect(deckController.webViewControllerCache.length, 1);
    });

    testWidgets('loads again when url changes for the same identity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com/first'},
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com/second'},
        ),
      );
      await tester.pump();

      final controller = webViewPlatform.controllers.single;
      expect(controller.loadedRequests, hasLength(2));
      expect(
        controller.loadedRequests.last.uri.toString(),
        'https://example.com/second',
      );
    });

    testWidgets(
      'explicit cacheKey sequential remount reuses controller without reload',
      (tester) async {
        await tester.pumpWidget(
          _WebViewHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-0:s0:b0',
            args: {
              'url': 'https://example.com/shared',
              'cacheKey': 'shared-key',
            },
          ),
        );
        await tester.pump();

        expect(webViewPlatform.controllers, hasLength(1));
        expect(webViewPlatform.controllers.single.loadedRequests, hasLength(1));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        // Different block runtime key, same cacheKey — sequential remount.
        await tester.pumpWidget(
          _WebViewHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-1:s0:b0',
            args: {
              'url': 'https://example.com/shared',
              'cacheKey': 'shared-key',
            },
          ),
        );
        await tester.pump();

        expect(webViewPlatform.controllers, hasLength(1));
        expect(webViewPlatform.controllers.single.loadedRequests, hasLength(1));
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          1,
        );
      },
    );

    testWidgets(
      'concurrent same cacheKey mounts use a local fallback controller',
      (tester) async {
        await tester.pumpWidget(
          _TwoWebViewsHarness(
            deckController: deckController,
            size: const Size(640, 240),
            firstRuntimeKey: 'slide-0:s0:b0',
            secondRuntimeKey: 'slide-0:s0:b1',
            args: {
              'url': 'https://example.com/shared',
              'cacheKey': 'shared-key',
            },
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(WebViewWrapper), findsNWidgets(2));
        expect(webViewPlatform.controllers, hasLength(2));
        expect(deckController.webViewControllerCache.length, 1);
        expect(
          webViewPlatform.controllers[0].loadedRequests.single.uri.toString(),
          'https://example.com/shared',
        );
        expect(
          webViewPlatform.controllers[1].loadedRequests.single.uri.toString(),
          'https://example.com/shared',
        );
      },
    );

    testWidgets(
      'switching to an already-loaded cache identity reveals the surface',
      (tester) async {
        // Warm entry B.
        await tester.pumpWidget(
          _WebViewHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-0:s0:b0',
            args: {'url': 'https://example.com/b', 'cacheKey': 'entry-b'},
          ),
        );
        await tester.pump();
        final entryB = webViewPlatform.controllers.single;
        expect(entryB.loadedRequests, hasLength(1));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        // Mount entry A (loading, surface hidden).
        await tester.pumpWidget(
          _WebViewHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-0:s0:b0',
            args: {'url': 'https://example.com/a', 'cacheKey': 'entry-a'},
          ),
        );
        await tester.pump();
        expect(webViewPlatform.controllers, hasLength(2));
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          0,
        );

        // Switch onto already-warmed B without remount (isInitial: false).
        await tester.pumpWidget(
          _WebViewHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-0:s0:b0',
            args: {'url': 'https://example.com/b', 'cacheKey': 'entry-b'},
          ),
        );
        await tester.pump();

        // B was already loaded — no additional loadRequest.
        expect(entryB.loadedRequests, hasLength(1));
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          1,
        );
      },
    );

    testWidgets('rebinds when the inherited deck controller changes', (
      tester,
    ) async {
      final secondLoader = MockDeckLoader();
      final secondController = DeckController(
        deckLoader: secondLoader,
        options: DeckOptions(),
      );
      addTearDown(() async {
        secondController.dispose();
        await secondLoader.dispose();
      });

      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com'},
        ),
      );
      await tester.pump();

      expect(webViewPlatform.controllers, hasLength(1));
      expect(deckController.webViewControllerCache.length, 1);

      await tester.pumpWidget(
        _WebViewHarness(
          deckController: secondController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com'},
        ),
      );
      await tester.pump();

      expect(webViewPlatform.controllers, hasLength(2));
      expect(secondController.webViewControllerCache.length, 1);
      expect(
        webViewPlatform.controllers.last.loadedRequests.single.uri.toString(),
        'https://example.com',
      );
    });

    testWidgets('javascript and allowedHosts updates without loadRequest', (
      tester,
    ) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {
            'url': 'https://example.com',
            'javascript': true,
            'allowedHosts': ['example.com'],
          },
        ),
      );
      await tester.pump();

      final controller = webViewPlatform.controllers.single;
      expect(controller.loadedRequests, hasLength(1));
      expect(controller.javaScriptMode, JavaScriptMode.unrestricted);

      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {
            'url': 'https://example.com',
            'javascript': false,
            'allowedHosts': ['example.com', 'cdn.example.com'],
          },
        ),
      );
      await tester.pump();

      expect(controller.loadedRequests, hasLength(1));
      expect(controller.javaScriptMode, JavaScriptMode.disabled);

      final delegate =
          controller.navigationDelegate! as _FakeNavigationDelegate;
      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(
            url: 'https://cdn.example.com/asset.js',
            isMainFrame: true,
          ),
        ),
        NavigationDecision.navigate,
      );
    });

    testWidgets('navigation policy allows configured hosts only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {
            'url': 'https://example.com',
            'allowedHosts': ['example.com', 'cdn.example.com'],
          },
        ),
      );
      await tester.pump();

      final delegate =
          webViewPlatform.controllers.single.navigationDelegate!
              as _FakeNavigationDelegate;

      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(
            url: 'https://example.com/next',
            isMainFrame: true,
          ),
        ),
        NavigationDecision.navigate,
      );
      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(
            url: 'https://cdn.example.com/asset.js',
            isMainFrame: true,
          ),
        ),
        NavigationDecision.navigate,
      );
      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(
            url: 'https://evil.com/phishing',
            isMainFrame: true,
          ),
        ),
        NavigationDecision.prevent,
      );
    });

    testWidgets('default host policy allows only source host', (tester) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com/page'},
        ),
      );
      await tester.pump();

      final delegate =
          webViewPlatform.controllers.single.navigationDelegate!
              as _FakeNavigationDelegate;

      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(
            url: 'https://example.com/other',
            isMainFrame: true,
          ),
        ),
        NavigationDecision.navigate,
      );
      expect(
        await delegate.onNavigationRequest?.call(
          const NavigationRequest(url: 'https://other.com/', isMainFrame: true),
        ),
        NavigationDecision.prevent,
      );
    });

    testWidgets('showControls enables refresh', (tester) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com', 'showControls': true},
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 200));
      expect(webViewPlatform.controllers.single.reloadCount, 1);
    });

    testWidgets(
      'refresh falls back to loadRequest when reload is unsupported',
      (tester) async {
        webViewPlatform = _WebLikeWebViewPlatform();
        WebViewPlatform.instance = webViewPlatform;

        await tester.pumpWidget(
          _WebViewHarness(
            deckController: deckController,
            size: const Size(640, 480),
            runtimeKey: 'slide-0:s0:b0',
            args: {'url': 'https://example.com', 'showControls': true},
          ),
        );
        await tester.pump();

        final controller = webViewPlatform.controllers.single;

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 150));

        expect(tester.takeException(), isNull);
        expect(controller.reloadCount, 0);
        expect(controller.loadedRequests, hasLength(2));
        expect(
          controller.loadedRequests.last.uri.toString(),
          'https://example.com',
        );
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          1,
        );
      },
    );

    testWidgets('static rendering shows title placeholder without controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          isStaticRendering: true,
          args: {'url': 'https://example.com', 'title': 'Static Title'},
        ),
      );
      await tester.pump();

      expect(find.text('Static Title'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Static Title')).style?.color,
        const Color(0xDD000000),
      );
      expect(tester.getSize(find.byType(WebViewWrapper)), const Size(640, 480));
      expect(find.byKey(const ValueKey('fake-web-view')), findsNothing);
      expect(webViewPlatform.controllers, isEmpty);
      expect(deckController.webViewControllerCache.length, 0);
    });

    testWidgets('deck dispose clears the webview cache', (tester) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com'},
        ),
      );
      await tester.pump();

      expect(deckController.webViewControllerCache.length, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      deckController.dispose();

      expect(deckController.webViewControllerCache.length, 0);

      // Avoid double-dispose in tearDown by replacing with a fresh controller.
      deckController = DeckController(
        deckLoader: MockDeckLoader(),
        options: DeckOptions(),
      );
    });

    testWidgets('javascript false disables javascript mode', (tester) async {
      await tester.pumpWidget(
        _WebViewHarness(
          deckController: deckController,
          size: const Size(640, 480),
          runtimeKey: 'slide-0:s0:b0',
          args: {'url': 'https://example.com', 'javascript': false},
        ),
      );
      await tester.pump();

      expect(
        webViewPlatform.controllers.single.javaScriptMode,
        JavaScriptMode.disabled,
      );
    });
  });
}

class _TwoWebViewsHarness extends StatelessWidget {
  final DeckController deckController;
  final Map<String, Object?> args;
  final Size size;
  final String firstRuntimeKey;
  final String secondRuntimeKey;

  const _TwoWebViewsHarness({
    required this.deckController,
    required this.args,
    required this.size,
    required this.firstRuntimeKey,
    required this.secondRuntimeKey,
  });

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration(
      slideIndex: 0,
      style: SlideStyler(),
      slide: Slide(
        key: 'slide-0',
        sections: [
          SectionBlock([ContentBlock('placeholder')]),
        ],
      ),
      thumbnailKey: buildThumbnailKey('slide-0'),
    );

    Widget webView(String runtimeKey) {
      return SizedBox.fromSize(
        size: size,
        child: InheritedData<BlockConfiguration>(
          data: BlockConfiguration(
            spec: const SlideSpec(),
            size: size,
            align: ContentAlignment.centerLeft,
            runtimeKey: runtimeKey,
          ),
          child: WebViewWidget(args),
        ),
      );
    }

    return MaterialApp(
      home: InheritedData<DeckController>(
        data: deckController,
        child: InheritedData<SlideConfiguration>(
          data: slide,
          child: Scaffold(
            body: Column(
              children: [webView(firstRuntimeKey), webView(secondRuntimeKey)],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebViewHarness extends StatelessWidget {
  final DeckController deckController;
  final Map<String, Object?> args;
  final Size size;
  final String runtimeKey;
  final bool isStaticRendering;
  final bool unboundedHeight;

  const _WebViewHarness({
    required this.deckController,
    required this.args,
    required this.size,
    required this.runtimeKey,
    this.isStaticRendering = false,
    this.unboundedHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration(
      slideIndex: 0,
      style: SlideStyler(),
      slide: Slide(
        key: 'slide-0',
        sections: [
          SectionBlock([ContentBlock('placeholder')]),
        ],
      ),
      thumbnailKey: buildThumbnailKey('slide-0'),
      isStaticRendering: isStaticRendering,
    );

    final webView = InheritedData<BlockConfiguration>(
      data: BlockConfiguration(
        spec: const SlideSpec(),
        size: size,
        align: ContentAlignment.centerLeft,
        runtimeKey: runtimeKey,
      ),
      child: WebViewWidget(args),
    );

    return MaterialApp(
      home: InheritedData<DeckController>(
        data: deckController,
        child: InheritedData<SlideConfiguration>(
          data: slide,
          child: Scaffold(
            body: unboundedHeight
                ? SingleChildScrollView(
                    child: SizedBox(width: size.width, child: webView),
                  )
                : Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox.fromSize(size: size, child: webView),
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
