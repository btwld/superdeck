import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';
import 'package:superdeck/src/markdown/markdown_inline_spans.dart';
import 'package:superdeck/src/styling/components/markdown_codeblock.dart';
import 'package:superdeck/src/styling/components/slide.dart';

void main() {
  group('buildMarkdownInlineSpans', () {
    const strongColor = Color(0xFFFF0000);
    const emColor = Color(0xFF00FF00);
    const delColor = Color(0xFF0000FF);
    const linkColor = Color(0xFFFF00FF);
    const codeColor = Color(0xFF00FFFF);

    final slideSpec = const SlideSpec(
      strong: TextStyle(color: strongColor, fontWeight: FontWeight.w900),
      em: TextStyle(color: emColor, fontStyle: FontStyle.italic),
      del: TextStyle(color: delColor, decoration: TextDecoration.lineThrough),
      link: TextStyle(color: linkColor, decoration: TextDecoration.underline),
      code: StyleSpec(
        spec: MarkdownCodeblockSpec(
          textStyle: TextStyle(color: codeColor, fontFamily: 'Courier'),
        ),
      ),
    );

    const base = TextStyle(fontSize: 16, color: Color(0xFFFFFFFF));

    List<md.Node> parseInline(String markdown) {
      final document = md.Document(extensionSet: md.ExtensionSet.gitHubWeb);
      final nodes = document.parseLines(markdown.split('\n'));
      final paragraph = nodes.whereType<md.Element>().firstWhere(
        (e) => e.tag == 'p' || e.tag.startsWith('h') || e.tag == 'li',
        orElse: () => nodes.whereType<md.Element>().first,
      );
      // For lists, walk into the first li.
      if (paragraph.tag == 'ul' || paragraph.tag == 'ol') {
        final li = paragraph.children!.whereType<md.Element>().first;
        return li.children ?? const [];
      }
      return paragraph.children ?? const [];
    }

    TextStyle? styleOf(List<InlineSpan> spans, String text) {
      TextStyle? found;
      void walk(InlineSpan span, TextStyle? inherited) {
        if (span is! TextSpan) return;
        final style = inherited?.merge(span.style) ?? span.style;
        if (span.text != null && span.text!.contains(text)) {
          found = style;
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          walk(child, style);
        }
      }

      for (final span in spans) {
        walk(span, base);
      }
      return found;
    }

    test('maps strong from SlideSpec', () {
      final spans = buildMarkdownInlineSpans(
        nodes: parseInline('Hello **world**'),
        baseStyle: base,
        slideSpec: slideSpec,
      );
      final style = styleOf(spans, 'world');
      expect(style?.color, strongColor);
      expect(style?.fontWeight, FontWeight.w900);
    });

    test('maps em from SlideSpec', () {
      final spans = buildMarkdownInlineSpans(
        nodes: parseInline('Hello *world*'),
        baseStyle: base,
        slideSpec: slideSpec,
      );
      final style = styleOf(spans, 'world');
      expect(style?.color, emColor);
      expect(style?.fontStyle, FontStyle.italic);
    });

    test('maps del from SlideSpec', () {
      final spans = buildMarkdownInlineSpans(
        nodes: parseInline('Hello ~~world~~'),
        baseStyle: base,
        slideSpec: slideSpec,
      );
      final style = styleOf(spans, 'world');
      expect(style?.color, delColor);
      expect(style?.decoration, TextDecoration.lineThrough);
    });

    test('maps link from SlideSpec', () {
      final spans = buildMarkdownInlineSpans(
        nodes: parseInline('See [docs](https://example.com)'),
        baseStyle: base,
        slideSpec: slideSpec,
      );
      final style = styleOf(spans, 'docs');
      expect(style?.color, linkColor);
    });

    test('maps inline code from SlideSpec.code textStyle', () {
      final spans = buildMarkdownInlineSpans(
        nodes: parseInline('Use `print`'),
        baseStyle: base,
        slideSpec: slideSpec,
      );
      final style = styleOf(spans, 'print');
      expect(style?.color, codeColor);
    });

    test('nests strong inside em', () {
      final spans = buildMarkdownInlineSpans(
        nodes: parseInline('***both***'),
        baseStyle: base,
        slideSpec: slideSpec,
      );
      final style = styleOf(spans, 'both');
      expect(style?.fontWeight, FontWeight.w900);
      expect(style?.fontStyle, FontStyle.italic);
    });

    test('hasInlineMarkdownElements detects markup', () {
      expect(hasInlineMarkdownElements(parseInline('plain')), isFalse);
      expect(hasInlineMarkdownElements(parseInline('**x**')), isTrue);
    });
  });
}
