import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../../styling/components/slide.dart';
import '../../ui/widgets/hero_element.dart';
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
/// Hero flight animation still uses the plain flattened string so existing
/// text-interpolation semantics stay stable.
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
    // For header elements (h1–h6), the parser attaches 'hero' to attributes.
    final heroTag = element.attributes['hero'];

    // Flattened content for hero flight + empty checks.
    final textContent = element.textContent;
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
          heroData: TextElement(
            text: transformed,
            spec: spec,
            size: blockData.size,
          ),
          buildFlight: _buildStableFlight,
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
          heroData: TextElement(
            text: transformed,
            spec: spec,
            size: BlockConfiguration.of(context).size,
          ),
          buildFlight: _buildStableFlight,
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

  /// Shared flight painter for both headers and plain text.
  ///
  /// Strategy:
  /// 1) Normalize text with directives *before* diffing.
  /// 2) Paint exactly three spans:
  ///    - committed prefix (opaque),
  ///    - single fading grapheme (variable opacity),
  ///    - ghost suffix (alpha=0) to pin wrapping and prevent flicker.
  Widget _buildStableFlight(
    BuildContext context,
    TextElement from,
    TextElement to,
    double t,
  ) {
    final spec = from.spec.lerp(to.spec, t);

    String applyDirectives(String v) => spec.textDirectives?.apply(v) ?? v;

    // Normalize first, then interpolate.
    final startN = applyDirectives(from.text);
    final endN = applyDirectives(to.text);

    final lerp = lerpStringWithFade(startN, endN, t);

    final baseStyle = (spec.style ?? const TextStyle());
    final baseColor = baseStyle.color ?? const Color(0xFF000000);

    final children = <InlineSpan>[];

    // 1) Committed prefix (fully visible)
    final committed = lerp.text;
    if (committed.isNotEmpty) {
      children.add(TextSpan(text: committed));
    }

    // 2) Fading grapheme (single character; variable opacity)
    final hasFade = lerp.fadingChar != null;
    final fadeAlpha = lerp.fadeOpacity.clamp(0.0, 1.0);
    if (hasFade) {
      // Keep an epsilon > 0 to avoid a 1-frame visual artifact when alpha jumps from 0.
      // When opacity transitions from exactly 0.0 to a small value, Flutter may render
      // the character for one frame before the opacity change takes effect, creating a
      // brief "flash". This threshold prevents that by ensuring near-zero values are
      // treated as fully transparent.
      final visibleAlpha = fadeAlpha > 0.01 ? fadeAlpha : 0.0;
      children.add(
        TextSpan(
          text: lerp.fadingChar!,
          style: baseStyle.copyWith(
            color: baseColor.withValues(alpha: visibleAlpha),
          ),
        ),
      );
    }

    // 3) Ghost suffix (alpha=0) to stabilize shaping & wrapping.
    //    Choose the active source based on phase: start (<0.5) vs end (>=0.5).
    final committedG = committed.characters.length;
    final visibleCountG = committedG + (hasFade ? 1 : 0);
    final active = (t < 0.5) ? startN : endN;
    final ghostSuffix = active.characters.skip(visibleCountG).toString();

    if (ghostSuffix.isNotEmpty) {
      children.add(
        TextSpan(
          text: ghostSuffix,
          style: baseStyle.copyWith(color: baseColor.withValues(alpha: 0.0)),
        ),
      );
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: children),
      strutStyle: spec.strutStyle,
      textAlign: spec.textAlign,
      textDirection: spec.textDirection,
      locale: spec.locale,
      softWrap: spec.softWrap,
      overflow: spec.overflow,
      textScaler: spec.textScaler,
      maxLines: spec.maxLines,
      textWidthBasis: spec.textWidthBasis,
      textHeightBehavior: spec.textHeightBehavior,
      selectionColor: spec.selectionColor,
      semanticsLabel: spec.semanticsLabel,
    );
  }
}
