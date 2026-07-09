import 'package:flutter/painting.dart';
import 'package:markdown/markdown.dart' as md;

import '../styling/components/slide.dart';
import 'markdown_helpers.dart';

/// Default inline styles applied when [SlideSpec] omits a field.
///
/// Markdown semantics still need bold/italic/strike even without an explicit
/// [SlideStyle] override; user styles merge on top via [TextStyle.merge].
const TextStyle kDefaultStrongStyle = TextStyle(fontWeight: FontWeight.bold);
const TextStyle kDefaultEmStyle = TextStyle(fontStyle: FontStyle.italic);
const TextStyle kDefaultDelStyle = TextStyle(
  decoration: TextDecoration.lineThrough,
);
const TextStyle kDefaultCodeStyle = TextStyle(fontFamily: 'monospace');

/// Builds [InlineSpan]s from markdown AST children, applying [SlideSpec]
/// inline styles (`strong`, `em`, `del`, `link`/`a`, inline `code`).
///
/// Standalone images are not rendered here — use [ImageBlockSyntax] / `@image`.
/// Inline images contribute only their alt text when present.
List<InlineSpan> buildMarkdownInlineSpans({
  required List<md.Node>? nodes,
  required TextStyle baseStyle,
  required SlideSpec slideSpec,
}) {
  if (nodes == null || nodes.isEmpty) return const [];

  final spans = <InlineSpan>[];
  for (final node in nodes) {
    spans.addAll(
      _spansForNode(node, baseStyle: baseStyle, slideSpec: slideSpec),
    );
  }
  return spans;
}

/// Whether [nodes] contain any inline element that needs styled spans
/// (as opposed to plain flattened text).
bool hasInlineMarkdownElements(List<md.Node>? nodes) {
  if (nodes == null) return false;
  for (final node in nodes) {
    if (node is md.Element) return true;
  }
  return false;
}

/// Resolves the [TextStyle] contribution for a single inline tag.
TextStyle inlineStyleForTag(String tag, SlideSpec slideSpec) {
  switch (tag) {
    case 'strong':
    case 'b':
      return kDefaultStrongStyle.merge(slideSpec.strong);
    case 'em':
    case 'i':
      return kDefaultEmStyle.merge(slideSpec.em);
    case 'del':
    case 's':
      return kDefaultDelStyle.merge(slideSpec.del);
    case 'a':
      return (slideSpec.link ?? slideSpec.a) ?? const TextStyle();
    case 'code':
      return kDefaultCodeStyle.merge(slideSpec.code?.spec.textStyle);
    case 'img':
      return slideSpec.img ?? const TextStyle();
    default:
      return const TextStyle();
  }
}

List<InlineSpan> _spansForNode(
  md.Node node, {
  required TextStyle baseStyle,
  required SlideSpec slideSpec,
}) {
  if (node is md.Text) {
    final text = _normalizeTextNode(node.text);
    if (text.isEmpty) return const [];
    return [TextSpan(text: text, style: baseStyle)];
  }

  if (node is md.Element) {
    return _spansForElement(node, baseStyle: baseStyle, slideSpec: slideSpec);
  }

  return const [];
}

List<InlineSpan> _spansForElement(
  md.Element element, {
  required TextStyle baseStyle,
  required SlideSpec slideSpec,
}) {
  final tag = element.tag;

  if (tag == 'br') {
    return [TextSpan(text: '\n', style: baseStyle)];
  }

  // Inline images: alt text only (standalone images use ImageElementBuilder).
  if (tag == 'img') {
    final alt = element.attributes['alt'] ?? '';
    if (alt.isEmpty) return const [];
    final style = baseStyle.merge(inlineStyleForTag(tag, slideSpec));
    return [TextSpan(text: alt, style: style)];
  }

  final style = baseStyle.merge(inlineStyleForTag(tag, slideSpec));
  final children = element.children;
  if (children == null || children.isEmpty) {
    final plain = _normalizeTextNode(element.textContent);
    if (plain.isEmpty) return const [];
    return [TextSpan(text: plain, style: style)];
  }

  return buildMarkdownInlineSpans(
    nodes: children,
    baseStyle: style,
    slideSpec: slideSpec,
  );
}

String _normalizeTextNode(String raw) {
  final withoutHero = getTagAndContent(raw).content;
  return withoutHero.replaceAll(
    RegExp(r'<br\s*/?>', caseSensitive: false),
    '\n',
  );
}
