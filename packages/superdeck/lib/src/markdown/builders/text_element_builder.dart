import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../markdown_helpers.dart';
import '../../ui/widgets/hero_element.dart';
import '../markdown_hero_mixin.dart';

String _transformLineBreaks(String text) => text.replaceAll('<br>', '\n');

/// Builds text elements from markdown, handling CSS class tags for Hero animations.
///
/// This builder processes markdown text nodes and:
/// - Filters out standalone CSS tag text nodes (e.g., " {.heading}")
/// - Extracts CSS class tags for Hero animation identifiers
/// - Transforms HTML line breaks (`<br>`) to newline characters
/// - Applies Mix `StyleSpec<TextSpec>` styling to the text
///
/// **CSS Class Tag Behavior**:
/// CSS class tags like `{.heading}`, `{.subheading}`, etc. are used ONLY for
/// Hero animations during slide transitions. They do NOT apply custom Mix styles.
/// The tags are removed from the displayed text in two ways:
///
/// 1. **Standalone tag nodes**: When markdown like `# Title {.heading}` is parsed,
///    the `{.heading}` becomes a separate text node. This builder filters out such
///    standalone tag nodes to prevent them from being rendered as visible text.
///
/// 2. **Inline tags**: Tags within text content are stripped by `getTagAndContent()`
///    before rendering.
///
/// **Hero Animation Integration**:
/// When a CSS class tag is present and the slide is NOT being exported:
/// - The tag is extracted from the header element's `hero` attribute
/// - A Hero widget wraps the text using the tag name as the identifier
/// - This enables smooth animated transitions between slides with matching tags
///
/// See also:
/// - [getTagAndContent] for CSS class tag extraction and content stripping
/// - [MarkdownHeroMixin] for Hero animation implementation
/// - [HeaderTagSyntax] for header-level tag extraction
class TextElementBuilder extends MarkdownElementBuilder with MarkdownHeroMixin {
  final StyleSpec<TextSpec> styleSpec;

  TextElementBuilder([this.styleSpec = const StyleSpec(spec: TextSpec())]);

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // For header elements (h1-h6), extract hero tag from element attributes
    final heroTag = element.attributes['hero'];

    // Get the text content from the element
    // NOTE: element.textContent flattens ALL child nodes (including <img>, <a>, etc.)
    // to plain text, discarding element structure. This means inline images like
    // "Text with ![icon](img.png) here" will have the <img> removed.
    // For standalone images, we use ImageBlockSyntax to create top-level <img>
    // elements that bypass this paragraph flattening. See REPORT.md for details.
    final textContent = element.textContent;

    return StyleSpecBuilder<TextSpec>(
      styleSpec: styleSpec,
      builder: (builderContext, spec) {
        // Access BlockData from StyleSpecBuilder's builderContext (not the method's context parameter).
        // StyleSpecBuilder wraps our widget in the Mix framework's context, ensuring BlockData
        // InheritedWidget is available in the widget tree. The method parameter context comes
        // from flutter_markdown_plus and may not have Mix framework ancestors yet.
        final blockData = BlockData.of(builderContext);

        // Transform line breaks once and reuse
        final transformedContent = _transformLineBreaks(textContent);

        Widget result = StyledText(transformedContent, styleSpec: styleSpec);

        return applyHeroIfNeeded<TextElement>(
          context: builderContext,
          child: result,
          heroTag: heroTag,
          heroData: TextElement(
            text: transformedContent,
            spec: spec,
            // In Mix 2.0, modifiers are handled differently than Mix 1.x
            // Use full block size since offset calculation is not yet implemented
            // TODO(Mix 2.0): Calculate offset from modifiers when API is available
            size: blockData.size,
          ),
          buildFlight: (context, from, to, t) {
            final interpolatedSpec = from.spec.lerp(to.spec, t);
            final lerpResult = lerpStringWithFade(from.text, to.text, t);

            String applyDirectives(String value) {
              return interpolatedSpec.textDirectives?.apply(value) ?? value;
            }

            final committedText = applyDirectives(lerpResult.text);
            final fadingChar = lerpResult.fadingChar != null
                ? applyDirectives(lerpResult.fadingChar!)
                : null;

            final baseStyle = interpolatedSpec.style ?? const TextStyle();
            final spans = <InlineSpan>[];

            if (committedText.isNotEmpty) {
              spans.add(TextSpan(text: committedText));
            }

            if (lerpResult.hasFadingChar && fadingChar != null) {
              final baseColor = baseStyle.color ?? const Color(0xFF000000);
              final fadeOpacity = lerpResult.fadeOpacity.clamp(0.0, 1.0);
              final fadeAlpha = (baseColor.a * fadeOpacity).clamp(0.0, 1.0);
              final fadeColor = baseColor.withValues(alpha: fadeAlpha);
              spans.add(
                TextSpan(
                  text: fadingChar,
                  style: baseStyle.copyWith(color: fadeColor),
                ),
              );
            }

            return Text.rich(
              TextSpan(style: baseStyle, children: spans),
              strutStyle: interpolatedSpec.strutStyle,
              textAlign: interpolatedSpec.textAlign,
              textDirection: interpolatedSpec.textDirection,
              locale: interpolatedSpec.locale,
              softWrap: interpolatedSpec.softWrap,
              overflow: interpolatedSpec.overflow,
              textScaler: interpolatedSpec.textScaler,
              maxLines: interpolatedSpec.maxLines,
              textWidthBasis: interpolatedSpec.textWidthBasis,
              textHeightBehavior: interpolatedSpec.textHeightBehavior,
              selectionColor: interpolatedSpec.selectionColor,
              semanticsLabel: interpolatedSpec.semanticsLabel,
            );
          },
        );
      },
    );
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    // For standalone text nodes (not in headers), try to extract tag from text
    final (:tag, :content) = getTagAndContent(text.text);
    return StyleSpecBuilder<TextSpec>(
      styleSpec: styleSpec,
      builder: (context, spec) {
        // Transform line breaks once and reuse
        final transformedContent = _transformLineBreaks(content);

        Widget result = StyledText(transformedContent, styleSpec: styleSpec);

        return applyHeroIfNeeded<TextElement>(
          context: context,
          child: result,
          heroTag: tag,
          heroData: TextElement(
            text: transformedContent,
            spec: spec,
            // In Mix 2.0, modifiers are handled differently than Mix 1.x
            // Use full block size since offset calculation is not yet implemented
            // TODO(Mix 2.0): Calculate offset from modifiers when API is available
            size: BlockData.of(context).size,
          ),
          buildFlight: (context, from, to, t) {
            final interpolatedSpec = from.spec.lerp(to.spec, t);
            final lerpResult = lerpStringWithFade(from.text, to.text, t);

            String applyDirectives(String value) {
              return interpolatedSpec.textDirectives?.apply(value) ?? value;
            }

            final committedText = applyDirectives(lerpResult.text);
            final fadingChar = lerpResult.fadingChar != null
                ? applyDirectives(lerpResult.fadingChar!)
                : null;

            final baseStyle = interpolatedSpec.style ?? const TextStyle();
            final spans = <InlineSpan>[];

            if (committedText.isNotEmpty) {
              spans.add(TextSpan(text: committedText));
            }

            if (lerpResult.hasFadingChar && fadingChar != null) {
              final baseColor = baseStyle.color ?? const Color(0xFF000000);
              final fadeOpacity = lerpResult.fadeOpacity.clamp(0.0, 1.0);
              final fadeAlpha = (baseColor.a * fadeOpacity).clamp(0.0, 1.0);
              final fadeColor = baseColor.withValues(alpha: fadeAlpha);
              spans.add(
                TextSpan(
                  text: fadingChar,
                  style: baseStyle.copyWith(color: fadeColor),
                ),
              );
            }

            return Text.rich(
              TextSpan(style: baseStyle, children: spans),
              strutStyle: interpolatedSpec.strutStyle,
              textAlign: interpolatedSpec.textAlign,
              textDirection: interpolatedSpec.textDirection,
              locale: interpolatedSpec.locale,
              softWrap: interpolatedSpec.softWrap,
              overflow: interpolatedSpec.overflow,
              textScaler: interpolatedSpec.textScaler,
              maxLines: interpolatedSpec.maxLines,
              textWidthBasis: interpolatedSpec.textWidthBasis,
              textHeightBehavior: interpolatedSpec.textHeightBehavior,
              selectionColor: interpolatedSpec.selectionColor,
              semanticsLabel: interpolatedSpec.semanticsLabel,
            );
          },
        );
      },
    );
  }
}
