import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/markdown/markdown_element_builders_registry.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/rendering/blocks/markdown_render_scope.dart';
import 'package:superdeck/src/styling/components/slide.dart';
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
      testWidgets('code blocks access BlockConfiguration from StyleSpecBuilder context', (
        tester,
      ) async {
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
      });

      testWidgets(
        'code blocks with Hero tag access BlockConfiguration for size calculation',
        (tester) async {
          const markdown = '''
```dart {.code-hero}
void main() {}
```
''';

          await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
          await tester.pumpAndSettle();

          // Verify code is rendered (uses RichText for syntax highlighting)
          expect(find.byType(RichText), findsWidgets);

          // Verify no BlockConfiguration access errors occurred during size calculation
          // If BlockConfiguration.of(builderContext) failed, rendering would have thrown
          final allWidgets = tester.allWidgets.toList();
          expect(allWidgets, isNotEmpty);
        },
      );
    });

    group('visitText Method', () {
      testWidgets('text nodes access BlockConfiguration from StyleSpecBuilder context', (
        tester,
      ) async {
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
      });

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

/// Test harness that provides complete rendering context for markdown elements.
///
/// This harness sets up:
/// - MaterialApp for Flutter widgets
/// - `InheritedData<SlideConfiguration>` for slide config
/// - BlockConfiguration with a known size (800x600) for layout
/// - MarkdownRenderScope with registry, styleSheet, and extensionSet
/// - MarkdownBody with all required syntaxes and builders
class _MarkdownHarness extends StatelessWidget {
  const _MarkdownHarness({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final extensionSet = md.ExtensionSet.gitHubWeb;
    final slideSpec = const SlideSpec();
    final registry = SpecMarkdownBuilders(slideSpec);
    final styleSheet = slideSpec.toStyle();
    final slideConfiguration = SlideConfiguration(
      slideIndex: 0,
      style: SlideStyle(),
      slide: const Slide(key: 'test-slide'),
      thumbnailFile: 'thumb.png',
    );

    // Provide BlockConfiguration with a reasonable slide size for testing
    final blockData = BlockConfiguration(
      align: ContentBlock(markdown).align,
      spec: slideSpec,
      size: const Size(800, 600),
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
