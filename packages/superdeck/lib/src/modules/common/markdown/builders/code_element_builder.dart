import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../../../../superdeck.dart';
import '../../../../components/molecules/element_provider.dart';
import '../../helpers/syntax_highlighter.dart';
import '../../helpers/utils.dart';
import '../markdown_helpers.dart';
import 'element_data_provider.dart';

class CodeElementBuilder extends MarkdownElementBuilder {
  final MarkdownCodeblockSpec? spec;

  CodeElementBuilder(this.spec);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final spec = this.spec ?? const MarkdownCodeblockSpec();
    // Extract language from the class attribute, default to 'dart'
    var language = 'dart';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      }
    }

    // Extract hero tag if present
    final tagAndContent = getTagAndContent(element.textContent);
    final heroTag = tagAndContent.tag;

    final spans = SyntaxHighlight.render(
      tagAndContent.content.trim(),
      language,
    );

    // Build the code widget
    Widget codeWidget = Row(
      children: [
        Expanded(
          child: BoxSpecWidget(
            spec: spec.container,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: spans.map((span) {
                return RichText(
                  text: TextSpan(
                    style: spec.textStyle,
                    children: [span],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );

    // Provide _CodeElementData for Hero animations
    return Builder(builder: (context) {
      final blockData = ElementData.of(context);
      final slide = SlideConfiguration.of(context);

      final hasHero = heroTag != null && !slide.isExporting;

      final codeOffset = getTotalModifierSpacing(spec);

      final totalSize = Size(
        blockData.size.width - codeOffset.dx,
        blockData.size.height - codeOffset.dy,
      );

      // If a hero tag is present, wrap the widget in a Hero
      if (hasHero) {
        codeWidget = _CodeElementHero(
          tag: heroTag,
          child: codeWidget,
        );
      }
      return CodeElementDataProvider(
        text: tagAndContent.content.trim(),
        language: language,
        spec: spec,
        size: totalSize,
        child: codeWidget,
      );
    });
  }
}

class _CodeElementHero extends StatelessWidget {
  const _CodeElementHero({
    required this.tag,
    required this.child,
  });

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: child,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        final toBlock = ElementDataProvider.of<CodeElementDataProvider>(
          toHeroContext,
        );
        final fromBlock = ElementDataProvider.maybeOf<CodeElementDataProvider>(
          fromHeroContext,
        );

        final fromBlockSize =
            fromBlock?.size ?? ElementDataProvider.ofAny(fromHeroContext).size;

        final fromBlockText = fromBlock?.text ?? toBlock.text;

        final fromBlockSpec = fromBlock?.spec ?? toBlock.spec;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final interpolatedSpec = fromBlockSpec.lerp(
              toBlock.spec,
              animation.value,
            );
            final interpolatedSize = Size.lerp(
              fromBlockSize,
              toBlock.size,
              animation.value,
            )!;

            final interpolatedText = lerpString(
              fromBlockText,
              toBlock.text,
              animation.value,
            );

            final spans = SyntaxHighlight.render(
              interpolatedText,
              toBlock.language,
            );

            return Wrap(
              clipBehavior: Clip.hardEdge,
              children: [
                SizedBox.fromSize(
                  size: interpolatedSize,
                  child: BoxSpecWidget(
                    spec: interpolatedSpec.container,
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
