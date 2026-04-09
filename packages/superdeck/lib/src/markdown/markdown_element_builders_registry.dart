import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../../superdeck.dart';
import 'builders/alert_element_builder.dart';
import 'builders/code_element_builder.dart';
import 'builders/image_element_builder.dart';
import 'builders/text_element_builder.dart';
import 'image_block_syntax.dart';

/// Registry for markdown element builders, syntaxes, and layout builders.
class SpecMarkdownBuilders {
  final SlideSpec spec;

  SpecMarkdownBuilders(this.spec);

  /// Custom block-level syntaxes.
  ///
  /// [ImageBlockSyntax] must be first to intercept standalone image lines
  /// before they get wrapped in `<p>` tags by the default paragraph parser.
  final List<md.BlockSyntax> blockSyntaxes = [
    ImageBlockSyntax(),
    const HeaderTagSyntax(),
    const HeroFencedCodeBlockSyntax(),
    const AlertBlockSyntax(),
  ];

  /// Custom inline syntaxes.
  final List<md.InlineSyntax> inlineSyntaxes = [ImageHeroSyntax()];

  /// Element builders for rendering markdown nodes to Flutter widgets.
  late final Map<String, MarkdownElementBuilder> builders = {
    'h1': TextElementBuilder(spec.h1 ?? const StyleSpec(spec: TextSpec())),
    'h2': TextElementBuilder(spec.h2 ?? const StyleSpec(spec: TextSpec())),
    'h3': TextElementBuilder(spec.h3 ?? const StyleSpec(spec: TextSpec())),
    'h4': TextElementBuilder(spec.h4 ?? const StyleSpec(spec: TextSpec())),
    'h5': TextElementBuilder(spec.h5 ?? const StyleSpec(spec: TextSpec())),
    'h6': TextElementBuilder(spec.h6 ?? const StyleSpec(spec: TextSpec())),
    'p': TextElementBuilder(spec.p ?? const StyleSpec(spec: TextSpec())),
    'alert': AlertElementBuilder(spec.alert),
    'code': CodeElementBuilder(
      spec.code ?? const StyleSpec(spec: MarkdownCodeblockSpec()),
    ),
    'img': ImageElementBuilder(spec.image),
    'li': TextElementBuilder(
      spec.list != null && spec.list!.spec.text != null
          ? spec.list!.spec.text!
          : const StyleSpec(spec: TextSpec()),
    ),
  };

  /// Returns zero-padding builders for all block-level tags.
  Map<String, MarkdownPaddingBuilder> get paddingBuilders {
    final zeroPadding = _ZeroPaddingBuilder();
    return _kBlockTags.fold(
      <String, MarkdownPaddingBuilder>{},
      (map, tag) => map..[tag] = zeroPadding,
    );
  }

  /// Checkbox builder for task lists.
  Widget Function(bool) get checkboxBuilder {
    return (bool checked) {
      final icon = checked ? Icons.check_box : Icons.check_box_outline_blank;
      final checkboxSpec =
          spec.checkbox != null && spec.checkbox!.spec.icon != null
          ? spec.checkbox!.spec.icon!
          : const StyleSpec(spec: IconSpec());
      return StyledIcon(icon: icon, styleSpec: checkboxSpec);
    };
  }

  /// Bullet builder for ordered and unordered lists.
  Widget Function(MarkdownBulletParameters params) get bulletBuilder {
    return (parameters) {
      final contents = switch (parameters.style) {
        BulletStyle.unorderedList => '•',
        BulletStyle.orderedList => '${parameters.index + 1}.',
      };
      final bulletSpec = spec.list != null && spec.list!.spec.bullet != null
          ? spec.list!.spec.bullet!
          : const StyleSpec(spec: TextSpec());
      return StyledText(contents, styleSpec: bulletSpec);
    };
  }
}

final _kBlockTags = <String>[
  'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', //
  'ul', 'ol', 'li', 'blockquote', //
  'pre', 'hr', 'table', //
  'thead', 'tbody', 'tr', 'section', 'alert',
];

class _ZeroPaddingBuilder extends MarkdownPaddingBuilder {
  @override
  EdgeInsets getPadding() => EdgeInsets.zero;
}
