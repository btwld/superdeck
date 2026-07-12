import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/markdown/markdown_element_builders_registry.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/rendering/blocks/markdown_render_scope.dart';
import 'package:superdeck/src/styling/components/markdown_codeblock.dart';
import 'package:superdeck/src/styling/components/markdown_list.dart';
import 'package:superdeck/src/styling/components/slide.dart';
import 'package:superdeck/src/ui/widgets/hero_element.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('TextElementBuilder - visitElementAfterWithContext Migration', () {
    group('Basic Rendering', () {
      testWidgets(
        'renders markdown headers using visitElementAfterWithContext',
        (tester) async {
          const markdown = '# Test Header';

          await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
          await tester.pumpAndSettle();

          // Verify header text is rendered
          expect(find.text('Test Header'), findsOneWidget);
        },
      );

      testWidgets(
        'renders markdown paragraphs using visitElementAfterWithContext',
        (tester) async {
          const markdown = 'Regular paragraph text.';

          await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
          await tester.pumpAndSettle();

          // Verify paragraph text is rendered
          expect(find.text('Regular paragraph text.'), findsOneWidget);
        },
      );
    });

    group('Inline Markdown styles from SlideSpec', () {
      const strongColor = Color(0xFFFF0000);
      const emColor = Color(0xFF00FF00);
      const delColor = Color(0xFF0000FF);
      const linkColor = Color(0xFFFF00FF);
      const codeColor = Color(0xFF00FFFF);

      SlideSpec styledSpec({List<Directive<String>>? textDirectives}) =>
          SlideSpec(
            strong: const TextStyle(
              color: strongColor,
              fontWeight: FontWeight.w900,
            ),
            em: const TextStyle(color: emColor, fontStyle: FontStyle.italic),
            del: const TextStyle(
              color: delColor,
              decoration: TextDecoration.lineThrough,
            ),
            link: const TextStyle(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            code: const StyleSpec(
              spec: MarkdownCodeblockSpec(
                textStyle: TextStyle(color: codeColor, fontFamily: 'Courier'),
              ),
            ),
            textScaleFactor: const TextScaler.linear(1.5),
            p: StyleSpec(
              spec: TextSpec(
                style: const TextStyle(fontSize: 20, color: Colors.white),
                textDirectives: textDirectives,
              ),
            ),
            h1: const StyleSpec(
              spec: TextSpec(
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            list: const StyleSpec(
              spec: MarkdownListSpec(
                text: StyleSpec(
                  spec: TextSpec(
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          );

      testWidgets('applies uppercase directive without dropping strong style', (
        tester,
      ) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'Hello **world**',
            slideSpec: styledSpec(
              textDirectives: const [UppercaseStringDirective()],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_hasRenderedText(tester, 'HELLO WORLD'), isTrue);
        expect(
          _findTextSpanStyle(
            tester,
            containing: 'WORLD',
            color: strongColor,
            fontWeight: FontWeight.w900,
          ),
          isNotNull,
        );
      });

      testWidgets('applies inline code and link styles under uppercase', (
        tester,
      ) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'Use `print` and [docs](https://example.com)',
            slideSpec: styledSpec(
              textDirectives: const [UppercaseStringDirective()],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_hasRenderedText(tester, 'USE PRINT AND DOCS'), isTrue);
        expect(
          _findTextSpanStyle(tester, containing: 'PRINT', color: codeColor),
          isNotNull,
        );
        expect(
          _findTextSpanStyle(tester, containing: 'DOCS', color: linkColor),
          isNotNull,
        );
      });

      testWidgets('applies capitalize directive to the whole paragraph', (
        tester,
      ) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'hello **world**',
            slideSpec: styledSpec(
              textDirectives: const [CapitalizeStringDirective()],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_hasRenderedText(tester, 'Hello world'), isTrue);
        expect(_hasRenderedText(tester, 'Hello World'), isFalse);
        expect(
          _findTextSpanStyle(
            tester,
            containing: 'world',
            color: strongColor,
            fontWeight: FontWeight.w900,
          ),
          isNotNull,
        );
      });

      testWidgets('applies strong style inside a paragraph', (tester) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'Hello **world** there',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('world'), findsOneWidget);
        expect(
          _findTextSpanStyle(
            tester,
            containing: 'world',
            color: strongColor,
            fontWeight: FontWeight.w900,
          ),
          isNotNull,
          reason:
              'strong text must use SlideSpec.strong, not flattened plain text',
        );
      });

      testWidgets('applies em style inside a paragraph', (tester) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'Hello *world* there',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _findTextSpanStyle(
            tester,
            containing: 'world',
            color: emColor,
            fontStyle: FontStyle.italic,
          ),
          isNotNull,
        );
      });

      testWidgets('applies del style inside a paragraph', (tester) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'Hello ~~world~~ there',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _findTextSpanStyle(
            tester,
            containing: 'world',
            color: delColor,
            decoration: TextDecoration.lineThrough,
          ),
          isNotNull,
        );
      });

      testWidgets('applies link style inside a paragraph', (tester) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'See [docs](https://example.com) now',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _findTextSpanStyle(tester, containing: 'docs', color: linkColor),
          isNotNull,
        );
      });

      testWidgets('applies inline code style inside a paragraph', (
        tester,
      ) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'Use `print` please',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _findTextSpanStyle(tester, containing: 'print', color: codeColor),
          isNotNull,
        );
      });

      testWidgets('applies strong style inside a heading', (tester) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: '# Hello **world**',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _findTextSpanStyle(
            tester,
            containing: 'world',
            color: strongColor,
            fontWeight: FontWeight.w900,
          ),
          isNotNull,
        );
      });

      testWidgets('applies strong style inside a list item', (tester) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: '- Hello **world**',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _findTextSpanStyle(
            tester,
            containing: 'world',
            color: strongColor,
            fontWeight: FontWeight.w900,
          ),
          isNotNull,
        );
      });

      testWidgets('applies textScaleFactor from SlideSpec on paragraphs', (
        tester,
      ) async {
        await tester.pumpWidget(
          _MarkdownHarness(
            markdown: 'Scaled text here',
            slideSpec: styledSpec(),
          ),
        );
        await tester.pumpAndSettle();

        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        final scaled = textWidgets.any(
          (t) => t.textScaler == const TextScaler.linear(1.5),
        );
        expect(
          scaled,
          isTrue,
          reason: 'SlideSpec.textScaleFactor must scale paragraph text',
        );
      });
    });

    group('BlockConfiguration Access', () {
      testWidgets(
        'header elements access BlockConfiguration from StyleSpecBuilder context',
        (tester) async {
          const markdown = '## Header with Size';

          await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
          await tester.pumpAndSettle();

          // Verify rendering completed without BlockConfiguration access errors
          expect(find.text('Header with Size'), findsOneWidget);

          // Verify StyleSpecBuilder is in widget tree (indicates proper context)
          final allWidgets = tester.allWidgets.toList();
          final hasStyleSpecBuilder = allWidgets.any(
            (widget) => widget.toString().contains('StyleSpecBuilder'),
          );
          expect(hasStyleSpecBuilder, isTrue);
        },
      );

      testWidgets(
        'header with Hero tag accesses BlockConfiguration for size calculation',
        (tester) async {
          const markdown = '# Title {.heading}';

          await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
          await tester.pumpAndSettle();

          // Verify text is rendered (CSS tag stripped by getTagAndContent)
          expect(find.text('Title'), findsOneWidget);

          // Verify no BlockConfiguration access errors occurred
          // If BlockConfiguration.of(context) failed, widget tree wouldn't render
          final allWidgets = tester.allWidgets.toList();
          expect(allWidgets, isNotEmpty);
        },
      );
    });

    group('Code Block Rendering', () {
      testWidgets(
        'code blocks access BlockConfiguration from StyleSpecBuilder context',
        (tester) async {
          const markdown = '''
```dart
void main() {
  print('test');
}
```
''';

          await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
          await tester.pumpAndSettle();

          // Verify code renders through CodeElementBuilder (uses RichText)
          expect(find.byType(RichText), findsWidgets);

          // Verify StyleSpecBuilder is in widget tree (proves BlockConfiguration access succeeded)
          final allWidgets = tester.allWidgets.toList();
          final hasStyleSpecBuilder = allWidgets.any(
            (widget) =>
                widget.toString().contains('StyleSpecBuilder') &&
                widget.toString().contains('MarkdownCodeblockSpec'),
          );
          expect(hasStyleSpecBuilder, isTrue);
        },
      );

      testWidgets(
        'code hero uses the real inner block frame without subtracting again',
        (tester) async {
          const markdown = '''
```dart {.code-hero}
void main() {}
```
''';

          await tester.pumpWidget(
            _MarkdownHarness(
              markdown: markdown,
              slideSpec: SlideSpec(
                code: StyleSpec(
                  spec: MarkdownCodeblockSpec(
                    container: StyleSpec(
                      spec: BoxSpec(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(border: Border.all(width: 2)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Verify code is rendered (uses RichText for syntax highlighting)
          expect(find.byType(RichText), findsWidgets);

          final heroElement = tester.widget<HeroElement<CodeElement>>(
            find.byWidgetPredicate(
              (widget) => widget is HeroElement<CodeElement>,
            ),
          );
          expect(heroElement.data.size, const Size(800, 600));
        },
      );
    });

    group('visitText Method', () {
      testWidgets(
        'text nodes access BlockConfiguration from StyleSpecBuilder context',
        (tester) async {
          const markdown = 'Plain text content';

          await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
          await tester.pumpAndSettle();

          // Verify text is rendered via visitText method
          expect(find.text('Plain text content'), findsOneWidget);

          // Verify StyleSpecBuilder is in widget tree
          final allWidgets = tester.allWidgets.toList();
          final hasStyleSpecBuilder = allWidgets.any(
            (widget) => widget.toString().contains('StyleSpecBuilder'),
          );
          expect(hasStyleSpecBuilder, isTrue);
        },
      );

      testWidgets('text nodes with Hero tag access BlockConfiguration correctly', (
        tester,
      ) async {
        const markdown = 'Text with tag {.text-hero}';

        await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
        await tester.pumpAndSettle();

        // Verify text is rendered (tag stripped, becomes part of paragraph)
        // The CSS tag is removed by getTagAndContent in visitText
        expect(find.textContaining('Text with tag'), findsOneWidget);

        // Verify no BlockConfiguration access errors during Hero data creation
        // If BlockConfiguration.of(context) in visitText failed, rendering would throw
        final allWidgets = tester.allWidgets.toList();
        expect(allWidgets, isNotEmpty);
      });
    });
  });
}

/// Finds a [TextStyle] on a rendered [TextSpan] whose text contains [containing]
/// and matches the optional style predicates.
TextStyle? _findTextSpanStyle(
  WidgetTester tester, {
  required String containing,
  Color? color,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  TextDecoration? decoration,
}) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final root = text.textSpan ?? TextSpan(text: text.data);
    final match = _searchSpan(
      root,
      containing: containing,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
    );
    if (match != null) return match;
  }

  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final match = _searchSpan(
      rich.text,
      containing: containing,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
    );
    if (match != null) return match;
  }

  return null;
}

bool _hasRenderedText(WidgetTester tester, String expected) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final plain = text.data ?? text.textSpan?.toPlainText();
    if (plain == expected) return true;
  }

  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    if (rich.text.toPlainText() == expected) return true;
  }

  return false;
}

TextStyle? _searchSpan(
  InlineSpan span, {
  required String containing,
  Color? color,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  TextDecoration? decoration,
  TextStyle? inherited,
}) {
  if (span is! TextSpan) return null;

  final style = inherited?.merge(span.style) ?? span.style;
  final text = span.text;
  if (text != null && text.contains(containing)) {
    final matchesColor = color == null || style?.color == color;
    final matchesWeight = fontWeight == null || style?.fontWeight == fontWeight;
    final matchesFontStyle = fontStyle == null || style?.fontStyle == fontStyle;
    final matchesDecoration =
        decoration == null || style?.decoration == decoration;
    if (matchesColor &&
        matchesWeight &&
        matchesFontStyle &&
        matchesDecoration) {
      return style;
    }
  }

  for (final child in span.children ?? const <InlineSpan>[]) {
    final found = _searchSpan(
      child,
      containing: containing,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      inherited: style,
    );
    if (found != null) return found;
  }
  return null;
}

/// Test harness that provides complete rendering context for markdown elements.
///
/// This harness sets up:
/// - MaterialApp for Flutter widgets
/// - `InheritedData<SlideConfiguration>` for slide config
/// - BlockConfiguration with a known size (800x600) for layout
/// - MarkdownRenderScope with registry, styleSheet, and extensionSet
/// - MarkdownBody with all required syntaxes and builders
class _MarkdownHarness extends StatelessWidget {
  const _MarkdownHarness({
    required this.markdown,
    this.slideSpec = const SlideSpec(),
  });

  final String markdown;
  final SlideSpec slideSpec;

  @override
  Widget build(BuildContext context) {
    final extensionSet = md.ExtensionSet.gitHubWeb;
    final registry = SpecMarkdownBuilders(slideSpec);
    final styleSheet = slideSpec.toStyle();
    final slideConfiguration = SlideConfiguration(
      slideIndex: 0,
      style: SlideStyle(),
      slide: Slide(key: 'test-slide'),
      thumbnailKey: 'thumb.png',
    );

    // Provide BlockConfiguration with a reasonable slide size for testing
    final blockData = BlockConfiguration(
      align: ContentAlignment.centerLeft,
      spec: slideSpec,
      size: const Size(800, 600),
      runtimeKey: 'test-slide:s0:b0',
    );

    return MaterialApp(
      home: InheritedData<SlideConfiguration>(
        data: slideConfiguration,
        child: InheritedData<BlockConfiguration>(
          data: blockData,
          child: Scaffold(
            body: MarkdownRenderScope(
              registry: registry,
              styleSheet: styleSheet,
              extensionSet: extensionSet,
              child: MarkdownBody(
                data: markdown,
                extensionSet: extensionSet,
                blockSyntaxes: registry.blockSyntaxes,
                inlineSyntaxes: registry.inlineSyntaxes,
                builders: registry.builders,
                paddingBuilders: registry.paddingBuilders,
                checkboxBuilder: registry.checkboxBuilder,
                bulletBuilder: registry.bulletBuilder,
                styleSheet: styleSheet,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
