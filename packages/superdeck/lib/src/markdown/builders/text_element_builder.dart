import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../../styling/components/slide.dart';
import '../../ui/widgets/hero_element.dart';
import '../../ui/widgets/text_hero_flight.dart';
import '../markdown_helpers.dart';
import '../markdown_hero_mixin.dart';
import '../markdown_inline_spans.dart';

/// Normalizes <br> variants to newlines (case-insensitive).
String _transformLineBreaks(String text) =>
    text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

/// Builds text from markdown nodes and wraps it in a Hero (when a valid tag is present).
///
/// - Walks inline markdown children so `strong` / `em` / `del` / links / code
///   receive [SlideSpec] styles (not flattened plain text)
/// - Filters standalone tag text nodes
/// - Strips inline CSS class tags from rendered text
/// - Transforms `<br>` to `\n`
/// - Uses a layout-stable flight painter to avoid last-word flicker
///
/// Flights preserve resolved inline styles and endpoint line breaks.
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
    // Headers carry an attribute; paragraphs retain the marker in their text.
    final taggedContent = getTagAndContent(element.textContent);
    final heroTag = element.attributes['hero'] ?? taggedContent.tag;

    // Flattened content for hero flight + empty checks.
    final textContent = taggedContent.content;
    return StyleSpecBuilder<TextSpec>(
      styleSpec: styleSpec,
      builder: (builderContext, spec) {
        final blockData = BlockConfiguration.of(builderContext);
        final slideSpec = blockData.spec;
        final transformed = _transformLineBreaks(textContent);

        // Avoid empty Heroes (common source of duplicate in-flight painters).
        if (transformed.trim().isEmpty) return const SizedBox.shrink();

        final child = _buildText(
          textSpec: spec,
          slideSpec: slideSpec,
          plainText: transformed,
          nodes: element.children,
        );

        return applyHeroIfNeeded<TextElement>(
          context: builderContext,
          child: child,
          heroTag: heroTag,
          heroData: TextElement(text: transformed, spec: spec),
          flightShuttleBuilder: buildTextHeroFlight,
        );
      },
    );
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final (:tag, :content) = getTagAndContent(text.text);

    return StyleSpecBuilder<TextSpec>(
      styleSpec: styleSpec,
      builder: (context, spec) {
        final slideSpec = BlockConfiguration.of(context).spec;
        final transformed = _transformLineBreaks(content);

        if (transformed.trim().isEmpty) return const SizedBox.shrink();

        final child = _buildText(
          textSpec: spec,
          slideSpec: slideSpec,
          plainText: transformed,
          nodes: null,
        );

        return applyHeroIfNeeded<TextElement>(
          context: context,
          child: child,
          heroTag: tag,
          heroData: TextElement(text: transformed, spec: spec),
          flightShuttleBuilder: buildTextHeroFlight,
        );
      },
    );
  }

  /// Renders [plainText], preserving inline styles when [nodes] contain markup.
  ///
  /// Prefer [Text.rich] when there is inline structure so `strong`/`em`/etc.
  /// map through [SlideSpec]. Plain runs stay on the simple [Text] path.
  Widget _buildText({
    required TextSpec textSpec,
    required SlideSpec slideSpec,
    required String plainText,
    required List<md.Node>? nodes,
  }) {
    final baseStyle = textSpec.style ?? const TextStyle();
    final textScaler = slideSpec.textScaleFactor ?? textSpec.textScaler;
    final displayText = textSpec.textDirectives?.apply(plainText) ?? plainText;

    if (!hasInlineMarkdownElements(nodes)) {
      return Text(
        displayText,
        style: baseStyle,
        strutStyle: textSpec.strutStyle,
        textAlign: textSpec.textAlign,
        textDirection: textSpec.textDirection,
        locale: textSpec.locale,
        softWrap: textSpec.softWrap,
        overflow: textSpec.overflow,
        textScaler: textScaler,
        maxLines: textSpec.maxLines,
        textWidthBasis: textSpec.textWidthBasis,
        textHeightBehavior: textSpec.textHeightBehavior,
        selectionColor: textSpec.selectionColor,
        semanticsLabel: textSpec.semanticsLabel,
      );
    }

    final spans = buildMarkdownInlineSpans(
      nodes: nodes,
      baseStyle: baseStyle,
      slideSpec: slideSpec,
      transformText: textSpec.textDirectives?.apply,
    );

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      strutStyle: textSpec.strutStyle,
      textAlign: textSpec.textAlign,
      textDirection: textSpec.textDirection,
      locale: textSpec.locale,
      softWrap: textSpec.softWrap,
      overflow: textSpec.overflow,
      textScaler: textScaler,
      maxLines: textSpec.maxLines,
      textWidthBasis: textSpec.textWidthBasis,
      textHeightBehavior: textSpec.textHeightBehavior,
      selectionColor: textSpec.selectionColor,
      semanticsLabel: textSpec.semanticsLabel,
    );
  }
}
