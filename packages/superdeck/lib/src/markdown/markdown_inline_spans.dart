import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:markdown/markdown.dart' as md;
import 'package:superdeck_core/superdeck_core.dart'
    as core
    show heroAnyBracePattern;

import '../styling/components/slide.dart';

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
  String Function(String text)? transformText,
}) {
  if (nodes == null || nodes.isEmpty) return const [];

  final runs = <_TextRun>[];
  for (final node in nodes) {
    _collectRunsForNode(
      node,
      style: baseStyle,
      slideSpec: slideSpec,
      runs: runs,
    );
  }
  if (runs.isEmpty) return const [];

  if (transformText == null) return _spansFromRuns(runs);

  final plainText = runs.map((run) => run.text).join();
  final transformed = transformText(plainText);
  if (plainText.characters.length != transformed.characters.length) {
    return [TextSpan(text: transformed, style: baseStyle)];
  }

  return _spansFromTransformedRuns(runs, transformed);
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

void _collectRunsForNode(
  md.Node node, {
  required TextStyle style,
  required SlideSpec slideSpec,
  required List<_TextRun> runs,
}) {
  if (node is md.Text) {
    _addRun(runs, _normalizeTextNode(node.text), style);
    return;
  }

  if (node is md.Element) {
    _collectRunsForElement(
      node,
      style: style,
      slideSpec: slideSpec,
      runs: runs,
    );
  }
}

void _collectRunsForElement(
  md.Element element, {
  required TextStyle style,
  required SlideSpec slideSpec,
  required List<_TextRun> runs,
}) {
  final tag = element.tag;

  if (tag == 'br') {
    _addRun(runs, '\n', style);
    return;
  }

  // Inline images: alt text only (standalone images use ImageElementBuilder).
  if (tag == 'img') {
    final alt = element.attributes['alt'] ?? '';
    final imageStyle = style.merge(inlineStyleForTag(tag, slideSpec));
    _addRun(runs, alt, imageStyle);
    return;
  }

  final elementStyle = style.merge(inlineStyleForTag(tag, slideSpec));
  final children = element.children;
  if (children == null || children.isEmpty) {
    _addRun(runs, _normalizeTextNode(element.textContent), elementStyle);
    return;
  }

  for (final child in children) {
    _collectRunsForNode(
      child,
      style: elementStyle,
      slideSpec: slideSpec,
      runs: runs,
    );
  }
}

void _addRun(List<_TextRun> runs, String text, TextStyle style) {
  if (text.isEmpty) return;
  runs.add(_TextRun(text, style));
}

List<InlineSpan> _spansFromRuns(List<_TextRun> runs) {
  return [for (final run in runs) TextSpan(text: run.text, style: run.style)];
}

List<InlineSpan> _spansFromTransformedRuns(
  List<_TextRun> runs,
  String transformed,
) {
  var remaining = transformed.characters;
  final spans = <InlineSpan>[];

  for (final run in runs) {
    final length = run.text.characters.length;
    final text = remaining.take(length).toString();
    remaining = remaining.skip(length);
    if (text.isNotEmpty) {
      spans.add(TextSpan(text: text, style: run.style));
    }
  }

  return spans;
}

String _normalizeTextNode(String raw) {
  final withoutHero = raw.replaceAll(core.heroAnyBracePattern, '');
  if (withoutHero.trim().isEmpty && withoutHero != raw) return '';

  return withoutHero.replaceAll(
    RegExp(r'<br\s*/?>', caseSensitive: false),
    '\n',
  );
}

final class _TextRun {
  final String text;
  final TextStyle style;

  const _TextRun(this.text, this.style);
}
