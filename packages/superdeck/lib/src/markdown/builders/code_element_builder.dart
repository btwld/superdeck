import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../../styling/components/markdown_codeblock.dart';
import '../../ui/widgets/hero_element.dart';
import '../../ui/widgets/text_hero_flight.dart';
import '../../utils/syntax_highlighter.dart';
import '../markdown_helpers.dart';
import '../markdown_hero_mixin.dart';
import 'mermaid_code_block.dart';

class CodeElementBuilder extends MarkdownElementBuilder with MarkdownHeroMixin {
  final StyleSpec<MarkdownCodeblockSpec> styleSpec;

  CodeElementBuilder([
    this.styleSpec = const StyleSpec(spec: MarkdownCodeblockSpec()),
  ]);

  Color? _codeBackground(MarkdownCodeblockSpec spec) {
    final decoration = spec.container?.spec.decoration;
    return switch (decoration) {
      BoxDecoration(:final color?) => color,
      _ => null,
    };
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
    if (language == 'mermaid') {
      return MermaidCodeBlock(code: tagAndContent.content);
    }

    return StyleSpecBuilder<MarkdownCodeblockSpec>(
      styleSpec: styleSpec,
      builder: (builderContext, spec) {
        // Access BlockConfiguration from StyleSpecBuilder's builderContext (not the method's context parameter).
        // StyleSpecBuilder wraps our widget in the Mix framework's context, ensuring BlockConfiguration
        // InheritedWidget is available in the widget tree. The method parameter context comes
        // from flutter_markdown_plus and may not have Mix framework ancestors yet.
        final blockData = BlockConfiguration.of(builderContext);
        final spans = SyntaxHighlight.render(
          tagAndContent.content.trim(),
          language,
          backgroundColor: _codeBackground(spec),
        );

        // Build the code widget
        Widget codeWidget = Row(
          children: [
            Expanded(
              child: Box(
                styleSpec: spec.container,
                child: RichText(
                  text: TextSpan(
                    style: spec.textStyle,
                    children: [
                      for (var i = 0; i < spans.length; i++) ...[
                        if (i > 0) const TextSpan(text: '\n'),
                        spans[i],
                      ],
                    ],
                  ),
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
          flightShuttleBuilder: buildCodeHeroFlight,
        );
      },
    );
  }
}
