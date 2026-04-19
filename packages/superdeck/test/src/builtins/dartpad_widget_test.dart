import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/builtins/dartpad_widget.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/ui/widgets/webview_wrapper.dart';
import 'package:superdeck_core/superdeck_core.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

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
      });
    });

    group('schema', () {
      test('accepts valid arguments', () {
        final result = DartPadDto.schema.safeParse({
          'id': 'snippet',
          'theme': 'dark',
          'embed': false,
          'run': true,
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
        });

        expect(dto.id, 'snippet');
        expect(dto.theme, DartPadTheme.dark);
        expect(dto.embed, isFalse);
        expect(dto.run, isFalse);
      });

      test('uses defaults when optional fields are omitted or null', () {
        final omitted = DartPadDto.parse({'id': 'omitted'});
        final explicitNull = DartPadDto.parse({
          'id': 'explicit-null',
          'theme': null,
          'embed': null,
          'run': null,
        });

        expect(omitted.theme, isNull);
        expect(omitted.embed, isTrue);
        expect(omitted.run, isTrue);
        expect(explicitNull.theme, isNull);
        expect(explicitNull.embed, isTrue);
        expect(explicitNull.run, isTrue);
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

    setUp(() {
      webViewPlatform = _FakeWebViewPlatform();
      WebViewPlatform.instance = webViewPlatform;
    });

    testWidgets('renders a web view wrapper for the DartPad URL', (
      tester,
    ) async {
      const size = Size(640, 480);

      await tester.pumpWidget(
        _DartPadHarness(
          size: size,
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

      expect(wrapper.size, size);
      expect(
        wrapper.url,
        'https://dartpad.dev/?id=snippet&theme=light&embed=true&run=false',
      );
      expect(find.byKey(const ValueKey('fake-web-view')), findsOneWidget);
      expect(webViewPlatform.controllers, hasLength(1));
      expect(
        webViewPlatform.controllers.single.loadedRequests.single.uri.toString(),
        wrapper.url,
      );
    });
  });
}

class _DartPadHarness extends StatelessWidget {
  final Map<String, Object?> args;
  final Size size;

  const _DartPadHarness({required this.args, required this.size});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InheritedData<BlockConfiguration>(
        data: BlockConfiguration(
          spec: const SlideSpec(),
          size: size,
          align: null,
        ),
        child: Scaffold(body: DartPadWidget(args)),
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
