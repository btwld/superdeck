import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../../../superdeck.dart';
import 'builders/alert_element_builder.dart';
import 'builders/code_element_builder.dart';
import 'builders/image_element_builder.dart';
import 'builders/text_element_builder.dart';
import 'image_block_syntax.dart';

/// Registry for all markdown element builders and custom syntaxes.
///
/// Centralizes the configuration of markdown parsing and rendering for
/// SuperDeck presentations. This class wires together:
/// - Custom markdown syntaxes (for parsing)
/// - Element builders (for rendering)
/// - Padding/bullet/checkbox builders (for layout)
///
/// Usage:
/// ```dart
/// final builders = SpecMarkdownBuilders(slideSpec);
///
/// MarkdownBody(
///   data: content,
///   builders: builders.builders,
///   blockSyntaxes: builders.blockSyntaxes,
///   inlineSyntaxes: builders.inlineSyntaxes,
///   // ... other properties
/// )
/// ```
class SpecMarkdownBuilders {
  final SlideSpec spec;

  SpecMarkdownBuilders(this.spec);

  /// Custom block-level syntaxes.
  ///
  /// These extend standard markdown to support SuperDeck features:
  /// - [ImageBlockSyntax] - Standalone images as block elements (MUST BE FIRST)
  /// - [HeaderTagSyntax] - Extracts hero tags from ATX headers
  /// - [HeroFencedCodeBlockSyntax] - Extracts hero tags from fenced code
  /// - [AlertBlockSyntax] - GitHub-style alert blocks
  ///
  /// IMPORTANT: ImageBlockSyntax must be first to intercept standalone image
  /// lines before they get parsed as paragraphs.
  final List<md.BlockSyntax> blockSyntaxes = [
    ImageBlockSyntax(), // Must be first!
    const HeaderTagSyntax(),
    const HeroFencedCodeBlockSyntax(),
    const AlertBlockSyntax(),
  ];

  /// Custom inline syntaxes.
  ///
  /// These extend standard markdown to support SuperDeck features:
  /// - [ImageHeroSyntax] - Adds hero tags to images
  final List<md.InlineSyntax> inlineSyntaxes = [ImageHeroSyntax()];

  /// Element builders for rendering markdown nodes to Flutter widgets.
  ///
  /// Preserve the existing null-aware defaults so we do not regress styling
  /// when a particular `SlideSpec` field is omitted.
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

  /// Padding builders for markdown block elements.
  ///
  /// Returns zero padding for all block-level tags to give full control
  /// to the Mix framework styling system.
  Map<String, MarkdownPaddingBuilder> get paddingBuilders {
    final zeroPadding = _ZeroPaddingBuilder();
    return _kBlockTags.fold(
      <String, MarkdownPaddingBuilder>{},
      (map, tag) => map..[tag] = zeroPadding,
    );
  }

  /// Checkbox builder for task lists.
  ///
  /// Renders checkboxes using the Mix framework [StyledIcon] with styling
  /// from [SlideSpec.checkbox].
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
  ///
  /// Renders list bullets using the Mix framework [StyledText] with styling
  /// from [SlideSpec.list.bullet].
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

/// Block-level HTML tags that receive zero padding.
///
/// These tags are styled entirely through the Mix framework, so we remove
/// default markdown padding to prevent conflicts.
final _kBlockTags = <String>[
  'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', //
  'ul', 'ol', 'li', 'blockquote', //
  'pre', 'ol', 'ul', 'hr', 'table', //
  'thead', 'tbody', 'tr', 'section', 'alert',
];

/// Inline padding builder that returns zero padding.
///
/// Inlined from zero_padding_builder.dart to eliminate unnecessary file for
/// single-purpose 3-line class.
class _ZeroPaddingBuilder extends MarkdownPaddingBuilder {
  @override
  EdgeInsets getPadding() => EdgeInsets.zero;
}
