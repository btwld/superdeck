import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../../styling/components/markdown_codeblock.dart';
import '../../ui/widgets/hero_element.dart';
import '../../ui/widgets/overflow_clip.dart';
import '../../utils/syntax_highlighter.dart';
import '../markdown_helpers.dart';
import '../markdown_hero_mixin.dart';

class CodeElementBuilder extends MarkdownElementBuilder with MarkdownHeroMixin {
  final StyleSpec<MarkdownCodeblockSpec> styleSpec;

  CodeElementBuilder([
    this.styleSpec = const StyleSpec(spec: MarkdownCodeblockSpec()),
  ]);

  TextStyle _resolveTrailingStyle(List<TextSpan> lines, TextStyle baseStyle) {
    TextStyle? resolveFromSpan(TextSpan span) {
      if ((span.text?.isNotEmpty ?? false) && span.style != null) {
        return span.style;
      }
      if (span.children != null && span.children!.isNotEmpty) {
        for (var i = span.children!.length - 1; i >= 0; i--) {
          final child = span.children![i];
          if (child is TextSpan) {
            final candidate = resolveFromSpan(child);
            if (candidate != null) {
              return candidate;
            }
          }
        }
      }
      return span.style;
    }

    for (var i = lines.length - 1; i >= 0; i--) {
      final candidate = resolveFromSpan(lines[i]);
      if (candidate != null) {
        return candidate;
      }
    }

    return baseStyle;
  }

  InlineSpan _buildFadingLineSpan(
    TextSpan lineSpan, {
    required bool isLastLine,
    String? fadeChar,
    TextStyle? fadeTextStyle,
  }) {
    if (lineSpan.children != null && lineSpan.children!.isNotEmpty) {
      final children = List<InlineSpan>.from(lineSpan.children!);
      if (isLastLine && fadeChar != null && fadeChar != '\n') {
        children.add(TextSpan(text: fadeChar, style: fadeTextStyle));
      }

      return TextSpan(style: lineSpan.style, children: children);
    }

    final children = <InlineSpan>[];
    if (lineSpan.text != null && lineSpan.text!.isNotEmpty) {
      children.add(TextSpan(text: lineSpan.text, style: lineSpan.style));
    }
    if (isLastLine && fadeChar != null && fadeChar != '\n') {
      children.add(TextSpan(text: fadeChar, style: fadeTextStyle));
    }

    return TextSpan(children: children);
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    var language = 'dart';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      }
    }

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
        // Access BlockConfiguration from StyleSpecBuilder's builderContext (not the method's context parameter).
        // StyleSpecBuilder wraps our widget in the Mix framework's context, ensuring BlockConfiguration
        // InheritedWidget is available in the widget tree. The method parameter context comes
        // from flutter_markdown_plus and may not have Mix framework ancestors yet.
        final blockData = BlockConfiguration.of(builderContext);

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

        return applyHeroIfNeeded<CodeElement>(
          context: builderContext,
          child: codeWidget,
          heroTag: heroTag,
          heroData: CodeElement(
            text: tagAndContent.content.trim(),
            language: language,
            spec: spec,
            size: blockData.size,
          ),
          buildFlight: (context, from, to, t) {
            final fromSize = from.size;
            final fromText = from.text;
            final fromSpec = from.spec;

            final interpolatedSpec = fromSpec.lerp(to.spec, t);
            final interpolatedSize = Size.lerp(fromSize, to.size, t)!;
            final lerpResult = lerpStringWithFade(fromText, to.text, t);
            final committedText = lerpResult.text;
            final fadeChar = lerpResult.hasFadingChar
                ? lerpResult.fadingChar
                : null;

            final highlightedLines = SyntaxHighlight.render(
              committedText,
              to.language,
            );
            final trailingStyle = _resolveTrailingStyle(
              highlightedLines,
              interpolatedSpec.textStyle ?? const TextStyle(),
            );
            final fadeBaseStyle = trailingStyle;
            final baseColor = fadeBaseStyle.color ?? const Color(0xFF000000);
            final fadeOpacity = lerpResult.fadeOpacity.clamp(0.0, 1.0);
            // Use fadeOpacity directly (already 0.0-1.0 range)
            // Apply minimum threshold (0.001) to avoid rendering nearly-invisible characters
            // which can cause rendering artifacts or performance issues in Flutter's text engine.
            final adjustedOpacity = fadeOpacity > 0.001 ? fadeOpacity : 0.0;
            final fadeColor = baseColor.withValues(alpha: adjustedOpacity);
            final fadeTextStyle = fadeBaseStyle.copyWith(color: fadeColor);

            return OverflowClip(
              child: SizedBox.fromSize(
                size: interpolatedSize,
                child: Box(
                  styleSpec: interpolatedSpec.container,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: () {
                      if (highlightedLines.isEmpty) {
                        if (fadeChar != null && fadeChar != '\n') {
                          return [
                            RichText(
                              text: TextSpan(
                                style: interpolatedSpec.textStyle,
                                children: [
                                  TextSpan(
                                    text: fadeChar,
                                    style: fadeTextStyle,
                                  ),
                                ],
                              ),
                            ),
                          ];
                        }

                        return <Widget>[];
                      }

                      return List.generate(highlightedLines.length, (index) {
                        final lineSpan = highlightedLines[index];
                        final isLastLine = index == highlightedLines.length - 1;
                        final richLine = _buildFadingLineSpan(
                          lineSpan,
                          isLastLine: isLastLine,
                          fadeChar: fadeChar,
                          fadeTextStyle: fadeTextStyle,
                        );

                        return RichText(
                          text: TextSpan(
                            style: interpolatedSpec.textStyle,
                            children: [richLine],
                          ),
                        );
                      });
                    }(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
