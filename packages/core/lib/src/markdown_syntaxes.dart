import 'package:collection/collection.dart';
import 'package:markdown/markdown.dart' as md;

import 'hero_tag_helpers.dart';

/// Markdown syntaxes that extract `{.hero}` markers and surface them as
/// attributes on the rendered elements.
///
/// Supports three contexts:
/// - Headers: `# Title {.hero}` → `<h1 hero="hero">Title</h1>`
/// - Images: `![alt](url) {.hero}` → `<img hero="hero" ... />`
/// - Code: ` ```dart {.hero}` → `<code hero="hero">...</code>`
///
/// Multiple classes can be specified; the first valid CSS identifier wins.
///
/// Example:
/// ```dart
/// final html = md.markdownToHtml(
///   '# Heading {.hero}\n![image](url.png) {.accent}',
///   blockSyntaxes: createHeroBlockSyntaxes(),
///   inlineSyntaxes: createHeroInlineSyntaxes(),
/// );
/// ```

// ============================================================================
// Public API
// ============================================================================

/// Creates block-level syntaxes for hero tag support.
/// Includes header and fenced code block parsing.
List<md.BlockSyntax> createHeroBlockSyntaxes() => const [
      HeaderTagSyntax(),
      HeroFencedCodeBlockSyntax(),
    ];

/// Creates inline-level syntaxes for hero tag support.
/// Currently includes image parsing.
List<md.InlineSyntax> createHeroInlineSyntaxes() => [
      ImageHeroSyntax(),
    ];

// ============================================================================
// Syntax Implementations
// ============================================================================

/// Header syntax that extracts trailing `{.hero}` markers.
///
/// Converts `# Title {.hero}` into `<h1 hero="hero">Title</h1>`.
/// The hero marker is removed from the visible text.
class HeaderTagSyntax extends md.HeaderSyntax {
  const HeaderTagSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final rawLine = parser.current.content;
    final match = pattern.firstMatch(rawLine);
    if (match == null) {
      final stripped = stripTrailingHeroMarker(rawLine);
      if (stripped.hero == null) {
        return super.parse(parser);
      }

      parser.advance();
      final inlineNodes = stripped.text.isEmpty
          ? <md.Node>[]
          : parser.document.parseInline(stripped.text);
      return md.Element('p', inlineNodes);
    }

    final matchedText = match[0]!;
    final openMarker = match[1]!;
    final closeMarker = match[2];
    final level = openMarker.length;
    final openMarkerStart = matchedText.indexOf(openMarker);
    final openMarkerEnd = openMarkerStart + level;

    String? content;
    if (closeMarker == null) {
      content = rawLine.substring(openMarkerEnd);
    } else {
      final closeMarkerStart = matchedText.lastIndexOf(closeMarker);
      content = rawLine.substring(openMarkerEnd, closeMarkerStart);
    }

    final strippedContent = stripTrailingHeroMarker(content.trim());

    parser.advance();

    if (closeMarker == null && RegExp(r'^#+$').hasMatch(strippedContent.text)) {
      final element = md.Element('h$level', const <md.Node>[]);
      if (strippedContent.hero != null) {
        element.attributes['hero'] = strippedContent.hero!;
      }
      return element;
    }

    final inlineNodes = strippedContent.text.isEmpty
        ? <md.Node>[]
        : parser.document.parseInline(strippedContent.text);

    final element = md.Element('h$level', inlineNodes);
    if (strippedContent.hero != null) {
      element.attributes['hero'] = strippedContent.hero!;
    }

    return element;
  }
}

/// Image syntax that extracts trailing `{.hero}` markers.
///
/// Converts `![alt](url) {.hero}` into `<img hero="hero" alt="alt" src="url" />`.
/// The marker must immediately follow the image with optional whitespace.
class ImageHeroSyntax extends md.ImageSyntax {
  ImageHeroSyntax({super.linkResolver});

  @override
  Iterable<md.Node>? close(
    md.InlineParser parser,
    covariant md.SimpleDelimiter opener,
    md.Delimiter? closer, {
    String? tag,
    required List<md.Node> Function() getChildren,
  }) {
    // Let parent handle standard image parsing
    final nodes = super.close(
      parser,
      opener,
      closer,
      tag: tag,
      getChildren: getChildren,
    );

    // Validate we got an image element
    if (nodes == null || nodes.isEmpty) return nodes;

    final element = nodes.firstOrNull;
    if (element is! md.Element || element.tag != 'img') return nodes;

    final hero = consumeTrailingHeroForInlineNode(parser);
    if (hero == null) {
      return nodes;
    }

    element.attributes['hero'] = hero;

    return nodes;
  }
}

/// Fenced code block syntax that extracts hero from info string.
///
/// Converts ` ```dart {.hero}` into `<code hero="hero" class="language-dart">`.
///
/// Note: The `{.hero}` marker remains in the info string after extraction,
/// but since language detection only looks at the first token, this doesn't
/// affect syntax highlighting or other tooling that inspects the info string.
class HeroFencedCodeBlockSyntax extends md.FencedCodeBlockSyntax {
  const HeroFencedCodeBlockSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final openingLine = parser.current.content;
    final hero = extractHeroFromFenceInfo(openingLine);

    // Let parent handle actual code block parsing
    final node = super.parse(parser);

    // Apply hero attribute to the <code> element if we found one
    if (hero != null && node is md.Element) {
      final codeElement = node.children
          ?.whereType<md.Element>()
          .firstWhereOrNull((e) => e.tag == 'code');

      if (codeElement != null) {
        codeElement.attributes['hero'] = hero;
      }
    }

    return node;
  }
}
