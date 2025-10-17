import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:superdeck/src/rendering/blocks/block_provider.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck/src/markdown/builders/alert_element_builder.dart';
import 'package:superdeck/src/markdown/markdown_element_builders_registry.dart';
import 'package:superdeck/src/rendering/blocks/markdown_render_scope.dart';
import 'package:superdeck/src/styling/slide_spec.dart';
import 'package:superdeck/src/styling/slide_style.dart';
import 'package:superdeck/src/deck/slide_configuration.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('AlertBlockSyntax', () {
    test('stores markdown source attribute', () {
      final document = md.Document(
        blockSyntaxes: const [AlertBlockSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(const [
        '> [!NOTE]',
        '> **Bold** text',
      ]);

      final alert = nodes.first as md.Element;
      expect(alert.tag, 'alert');
      expect(alert.attributes['type'], 'note');
      expect(
        alert.attributes[AlertBlockSyntax.markdownSourceAttribute],
        '**Bold** text',
      );
    });

    test('stores markdown source with list items', () {
      final document = md.Document(
        blockSyntaxes: const [AlertBlockSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(const [
        '> [!TIP]',
        '> This has **bold** text and a list:',
        '>',
        '> - Item 1',
        '> - Item 2',
      ]);

      final alert = nodes.first as md.Element;
      expect(alert.tag, 'alert');
      expect(alert.attributes['type'], 'tip');

      final rawMarkdown =
          alert.attributes[AlertBlockSyntax.markdownSourceAttribute];
      expect(rawMarkdown, contains('- Item 1'));
      expect(rawMarkdown, contains('- Item 2'));
      expect(alert.children?.length, 2); // paragraph + list
    });
  });

  group('ImageHeroSyntax', () {
    test('adds hero attribute for inline image', () {
      final document = md.Document(
        inlineSyntaxes: [ImageHeroSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(const ['![alt](image.png){.hero}']);
      final paragraph = nodes.whereType<md.Element>().first;
      final image = paragraph.children!
          .whereType<md.Element>()
          .firstWhere((element) => element.tag == 'img');
      expect(image.attributes['hero'], 'hero');
      expect(
        paragraph.children!.whereType<md.Text>().map((e) => e.text),
        isNot(contains('{.hero}')),
      );
    });

    test('adds hero attribute for reference image', () {
      final document = md.Document(
        inlineSyntaxes: [ImageHeroSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(const [
        '![Text][id]{.figure}',
        '',
        '[id]: https://example.com/image.png "Title"',
      ]);

      final paragraph = nodes.whereType<md.Element>().first;
      final image = paragraph.children!
          .whereType<md.Element>()
          .firstWhere((element) => element.tag == 'img');
      expect(image.attributes['hero'], 'figure');
      expect(
        paragraph.children!.whereType<md.Text>().map((e) => e.text.trim()),
        isNot(contains('{.figure}')),
      );
    });

    test('handles nested parentheses in image URL', () {
      final document = md.Document(
        inlineSyntaxes: [ImageHeroSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(const [
        '![alt](https://example.com/img_(v1).png) {.hero}',
      ]);

      final paragraph = nodes.whereType<md.Element>().first;
      final image = paragraph.children!
          .whereType<md.Element>()
          .firstWhere((element) => element.tag == 'img');

      expect(image.attributes['hero'], 'hero');
      expect(image.attributes['src'], 'https://example.com/img_(v1).png');
    });

    test('uses first class and consumes attribute text with whitespace', () {
      final document = md.Document(
        inlineSyntaxes: [ImageHeroSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(
        const ['![alt](image.png) {.hero .secondary}'],
      );

      final paragraph = nodes.whereType<md.Element>().first;
      final image = paragraph.children!
          .whereType<md.Element>()
          .firstWhere((element) => element.tag == 'img');

      expect(image.attributes['hero'], 'hero');
      expect(
        paragraph.children!
            .whereType<md.Text>()
            .map((element) => element.text.trim()),
        everyElement(isEmpty),
      );
    });

    test('ignores invalid class names', () {
      final document = md.Document(
        inlineSyntaxes: [ImageHeroSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(const ['![alt](image.png){.123bad}']);
      final paragraph = nodes.whereType<md.Element>().first;
      final image = paragraph.children!
          .whereType<md.Element>()
          .firstWhere((element) => element.tag == 'img');

      expect(image.attributes['hero'], isNull);
      expect(
        paragraph.children!.whereType<md.Text>().map((e) => e.text.trim()),
        contains('{.123bad}'),
      );
    });
  });

  group('Markdown builders rendering', () {
    testWidgets('renders list items correctly', (tester) async {
      const markdown = '''
- Item 1
- Item 2
''';

      await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('renders list with text above', (tester) async {
      const markdown = '''
This has **bold** text and a list:

- Item 1
- Item 2
''';

      await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
      await tester.pumpAndSettle();

      expect(find.textContaining('bold'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('alert preserves nested markdown content', (tester) async {
      const markdown = '''
> [!TIP]
> This has **bold** text and a list:
>
> - Item 1
> - Item 2
''';

      await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
      await tester.pumpAndSettle();

      expect(find.textContaining('bold'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('fenced code block applies hero animation', (tester) async {
      const markdown = '''
```dart {.code-hero}
void main() {}
```
''';

      await tester.pumpWidget(_MarkdownHarness(markdown: markdown));
      await tester.pumpAndSettle();

      final heroes = tester.widgetList<Hero>(find.byType(Hero));
      expect(
        heroes.any((hero) => hero.tag == 'code-hero'),
        isTrue,
      );
    });
  });
}

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

    final blockData = BlockData<ColumnBlock>(
      block: ColumnBlock(markdown),
      spec: slideSpec,
      size: const Size(800, 600),
    );

    return MaterialApp(
      home: InheritedData<SlideConfiguration>(
        data: slideConfiguration,
        child: InheritedData<BlockData<ColumnBlock>>(
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
