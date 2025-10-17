import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../../rendering/blocks/block_widget.dart';
import '../../styling/styles.dart';
import '../../ui/widgets/hero_element.dart';
import '../../utils/syntax_highlighter.dart';
import '../markdown_helpers.dart';
import '../markdown_hero_mixin.dart';

class CodeElementBuilder extends MarkdownElementBuilder with MarkdownHeroMixin {
  final StyleSpec<MarkdownCodeblockSpec> styleSpec;

  CodeElementBuilder([
    this.styleSpec = const StyleSpec(spec: MarkdownCodeblockSpec()),
  ]);

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // Extract language from the class attribute, default to 'dart'
    var language = 'dart';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      }
    }

    // Extract hero tag if present (prefer attribute injected by parser)
    final attributeHero = element.attributes['hero'];
    final tagAndContent = getTagAndContent(element.textContent);
    final heroTag = attributeHero ?? tagAndContent.tag;

    final spans = SyntaxHighlight.render(
      tagAndContent.content.trim(),
      language,
    );

    return StyleSpecBuilder<MarkdownCodeblockSpec>(
      styleSpec: styleSpec,
      builder: (builderContext, spec) {
        // Access BlockData from StyleSpecBuilder's builderContext (not the method's context parameter).
        // StyleSpecBuilder wraps our widget in the Mix framework's context, ensuring BlockData
        // InheritedWidget is available in the widget tree. The method parameter context comes
        // from flutter_markdown_plus and may not have Mix framework ancestors yet.
        final blockData = BlockData.of(builderContext);

        // Build the code widget
        Widget codeWidget = Row(
          children: [
            Expanded(
              child: Box(
                styleSpec: spec.container,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: spans.map((span) {
                    return RichText(
                      text: TextSpan(style: spec.textStyle, children: [span]),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );

        final containerSpec = spec.container?.spec;
        final codeOffset = containerSpec != null
            ? BlockWidget.calculateBlockOffset(containerSpec)
            : Offset.zero;

        final totalSize = Size(
          blockData.size.width - codeOffset.dx,
          blockData.size.height - codeOffset.dy,
        );

        return applyHeroIfNeeded<CodeElement>(
          context: builderContext,
          child: codeWidget,
          heroTag: heroTag,
          heroData: CodeElement(
            text: tagAndContent.content.trim(),
            language: language,
            spec: spec,
            size: totalSize,
          ),
          buildFlight: (context, from, to, t) {
            final fromSize = from.size;
            final fromText = from.text;
            final fromSpec = from.spec;

            final interpolatedSpec = fromSpec.lerp(to.spec, t);
            final interpolatedSize = Size.lerp(fromSize, to.size, t)!;
            final interpolatedText = lerpString(fromText, to.text, t);

            final spans = SyntaxHighlight.render(interpolatedText, to.language);

            /// IMPORTANT: Do not remove this, its needed for overflow on flight
            return Wrap(
              clipBehavior: Clip.hardEdge,
              children: [
                SizedBox.fromSize(
                  size: interpolatedSize,
                  child: Box(
                    styleSpec: interpolatedSpec.container,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: spans.map((span) {
                        return RichText(
                          text: TextSpan(
                            style: interpolatedSpec.textStyle,
                            children: [span],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
