import 'package:markdown/markdown.dart' as md;

/// Block syntax that parses standalone images as top-level `<img>` elements.
///
/// CommonMark wraps images in `<p>` tags, which causes TextElementBuilder to
/// flatten them to plain text before ImageElementBuilder can process them.
/// This syntax intercepts standalone image lines during block parsing.
///
/// Supported forms:
/// - `![alt](url)`
/// - `![alt](url "title")`
/// - `![alt](url) {.hero}`
///
/// Note: Only standalone images are supported. Inline images within text
/// (e.g., `See ![icon](x.png) here`) are not handled by this syntax.
class ImageBlockSyntax extends md.BlockSyntax {
  /// Pattern matches standalone image lines: `![alt](url)` with optional hero tag
  ///
  /// Captures:
  /// - Group 1: alt text
  /// - Group 2: url
  /// - Group 3: optional title in quotes
  /// - Group 4: optional {.hero} marker
  static final _pattern = RegExp(
    r'^\s*!\[([^\]]*)\]\(([^)]+?)(?:\s+"([^"]*)")?\)\s*(?:\{\.([a-zA-Z][\w-]*)\})?\s*$',
  );

  ImageBlockSyntax();

  @override
  RegExp get pattern => _pattern;

  @override
  bool canParse(md.BlockParser parser) {
    // Only match if it's a standalone image line (not part of other content)
    return pattern.hasMatch(parser.current.content);
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    parser.advance();

    final alt = match.group(1) ?? '';
    final src = match.group(2)!;
    final title = match.group(3);
    final hero = match.group(4);

    // Create a top-level <img> element (NOT wrapped in <p>)
    final element = md.Element.empty('img')
      ..attributes['src'] = src
      ..attributes['alt'] = alt;

    if (title != null) {
      element.attributes['title'] = title;
    }

    if (hero != null) {
      element.attributes['hero'] = hero;
    }

    return element;
  }
}
