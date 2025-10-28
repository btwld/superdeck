import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:superdeck/src/markdown/builders/image_element_builder.dart';
import 'package:superdeck/src/markdown/markdown_element_builders_registry.dart';
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/rendering/blocks/markdown_render_scope.dart';
import 'package:superdeck/src/styling/slide_spec.dart';
import 'package:superdeck/src/styling/slide_style.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// TDD tests for image element rendering issue.
///
/// These tests verify that images render as block elements with proper
/// BlockData context access, ensuring the StyleSpecBuilder builder callback
/// executes correctly.
void main() {
  group('ImageElementBuilder - Block Element Rendering', () {
    test('declares itself as a block element', () {
      final builder = ImageElementBuilder();

      // ASSERTION: ImageElementBuilder should override isBlockElement() to
      // return true, making it behave like AlertElementBuilder
      expect(builder.isBlockElement(), isTrue);
    });

    testWidgets('image builder callback executes with BlockData access', (
      tester,
    ) async {
      const markdown = '![test](assets/test.png)';

      await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
      await tester.pumpAndSettle();

      // ASSERTION: The image should render through ImageElementBuilder
      // Look for the CachedImage widget which proves the builder was called
      expect(
        find.byType(ConstrainedBox),
        findsWidgets,
        reason:
            'Image should render with ConstrainedBox from ImageElementBuilder',
      );

      // Verify StyleSpecBuilder was used (proves builder callback executed)
      final allWidgets = tester.allWidgets.toList();
      final hasStyleSpecBuilder = allWidgets.any(
        (widget) => widget.toString().contains('StyleSpecBuilder<ImageSpec>'),
      );

      expect(
        hasStyleSpecBuilder,
        isTrue,
        reason: 'Should have StyleSpecBuilder<ImageSpec> in widget tree',
      );
    });

    testWidgets('image renders with block-level size constraints', (
      tester,
    ) async {
      const markdown = '![mermaid](assets/mermaid.png)';

      await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
      await tester.pumpAndSettle();

      // ASSERTION: The ConstrainedBox should have tight constraints
      // matching the BlockData size (800x600)
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      expect(
        constrainedBoxes,
        isNotEmpty,
        reason: 'Should find ConstrainedBox widgets',
      );

      // Find the image's ConstrainedBox (tight 800x600 from BlockData)
      final imageBox = constrainedBoxes.firstWhere(
        (box) =>
            box.constraints.maxWidth == 800.0 &&
            box.constraints.maxHeight == 600.0 &&
            box.constraints.minWidth == 800.0 &&
            box.constraints.minHeight == 600.0,
        orElse: () => throw TestFailure(
          'No ConstrainedBox found with tight 800x600 constraints from BlockData',
        ),
      );

      expect(imageBox, isNotNull);
      expect(imageBox.constraints.isTight, isTrue);
    });

    test('multiple standalone images are parsed as block elements', () {
      const markdown = '''
![image1](assets/img1.png)

![image2](assets/img2.png)
''';

      final registry = SpecMarkdownBuilders(const SlideSpec());
      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubWeb,
        blockSyntaxes: registry.blockSyntaxes,
        inlineSyntaxes: registry.inlineSyntaxes,
      );

      final nodes = document.parseLines(markdown.split('\n'));

      // ASSERTION: Both images should be parsed as top-level block elements
      final imageNodes = nodes
          .whereType<md.Element>()
          .where((e) => e.tag == 'img')
          .toList();

      expect(
        imageNodes.length,
        equals(2),
        reason: 'Should parse 2 standalone images as block elements',
      );
      expect(imageNodes[0].attributes['src'], equals('assets/img1.png'));
      expect(imageNodes[1].attributes['src'], equals('assets/img2.png'));
    });

    test('inline images are NOT supported (documented limitation)', () {
      // This test documents the current limitation: images within text are
      // flattened by TextElementBuilder.element.textContent and do not render
      const markdown = 'See the ![icon](small.png) icon here.';

      final registry = SpecMarkdownBuilders(const SlideSpec());
      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubWeb,
        blockSyntaxes: registry.blockSyntaxes,
        inlineSyntaxes: registry.inlineSyntaxes,
      );

      final nodes = document.parseLines(markdown.split('\n'));

      // ASSERTION: Image is nested in paragraph, NOT a top-level element
      final paragraphs = nodes
          .whereType<md.Element>()
          .where((e) => e.tag == 'p')
          .toList();
      expect(
        paragraphs.length,
        equals(1),
        reason: 'Text with inline image becomes paragraph',
      );

      final topLevelImages = nodes
          .whereType<md.Element>()
          .where((e) => e.tag == 'img')
          .toList();
      expect(
        topLevelImages.length,
        equals(0),
        reason: 'Inline images are NOT parsed as top-level block elements',
      );

      // The image is nested inside the paragraph but will be flattened by
      // TextElementBuilder.element.textContent when rendered
      final paragraph = paragraphs.first;
      final nestedImage = paragraph.children
          ?.whereType<md.Element>()
          .where((e) => e.tag == 'img')
          .toList();

      expect(
        nestedImage?.length,
        equals(1),
        reason: 'Image exists in AST as nested element',
      );
      expect(nestedImage?.first.attributes['src'], equals('small.png'));

      // NOTE: When rendered, TextElementBuilder will call element.textContent
      // which flattens this <img> to empty string, so it won't display.
      // To fix this would require modifying TextElementBuilder to preserve
      // inline children using Text.rich with WidgetSpan. See REPORT.md.
    });
  });
}

/// Test harness that provides proper BlockData and InheritedData context
/// for rendering markdown with images.
///
/// Mirrors the setup from markdown_builders_test.dart but specifically
/// configured for testing image rendering with block-level context.
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
      slide: const Slide(key: 'slide'),
      thumbnailFile: 'thumb.png',
    );

    // Provide BlockData with a reasonable slide size for testing
    final blockData = BlockData(
      block: ContentBlock(markdown),
      spec: slideSpec,
      size: const Size(800, 600),
    );

    return MaterialApp(
      home: InheritedData<SlideConfiguration>(
        data: slideConfiguration,
        child: InheritedData<BlockData>(
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
