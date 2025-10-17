import 'package:markdown/markdown.dart' as md;

/// Block syntax for standalone images that should render as block elements.
///
/// **Why This Exists:**
///
/// By default, CommonMark parsers treat images as inline content and wrap them
/// in `<p>` tags. When TextElementBuilder processes these paragraphs, it uses
/// `element.textContent` which flattens all child nodes to plain text, discarding
/// the `<img>` element structure. This prevents ImageElementBuilder from ever
/// being called for the image.
///
/// This BlockSyntax solves the problem by intercepting standalone image lines
/// DURING the block parsing phase (before paragraph wrapping happens), creating
/// top-level `<img>` elements that go directly to ImageElementBuilder.
///
/// **Supported Forms:**
/// - `![alt](url)`
/// - `![alt](url "title")`
/// - `![alt](url) {.hero}`
///
/// **Benefits:**
/// - Images access BlockData context for slide sizing
/// - Images render as full-width block elements
/// - Hero animations are supported via `{.hero}` tags
/// - Simpler than modifying TextElementBuilder to preserve inline children
///
/// **Trade-offs:**
/// - ✅ Standalone images work perfectly (99% use case for presentations)
/// - ❌ Inline images like "See ![icon](x.png) here" are NOT supported
///   - These will be flattened by TextElementBuilder and won't render
///   - To support inline images would require modifying TextElementBuilder
///     to use Text.rich with WidgetSpan instead of element.textContent
///
/// **Design Decision:**
/// For SuperDeck (a presentation tool), standalone full-slide images are the
/// primary use case. Inline images within text are rare in presentations.
/// This simple ~50 line solution handles the common case elegantly, following
/// the same pattern as AlertBlockSyntax.
///
/// See REPORT.md "Update: Root Cause Correction" for technical details.
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
