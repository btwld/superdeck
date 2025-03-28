import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../../../superdeck.dart';
import 'builders/alert_element_builder.dart';
import 'builders/code_element_builder.dart';
import 'builders/image_element_builder.dart';
import 'builders/text_element_builder.dart';
import 'builders/zero_padding_builder.dart';
import 'markdown_helpers.dart';

class SpecMarkdownBuilders {
  final SlideSpec spec;

  SpecMarkdownBuilders(this.spec);

  final List<md.BlockSyntax> blockSyntaxes = [
    const CustomHeaderSyntax(),
    const AlertBlockSyntax(),
  ];

  final List<md.InlineSyntax> inlineSyntaxes = [
    CustomImageSyntax(),
  ];

  late final builders = <String, MarkdownElementBuilder>{
    'h1': TextElementBuilder(spec.h1),
    'h2': TextElementBuilder(spec.h2),
    'h3': TextElementBuilder(spec.h3),
    'h4': TextElementBuilder(spec.h4),
    'h5': TextElementBuilder(spec.h5),
    'h6': TextElementBuilder(spec.h6),
    'alert': AlertElementBuilder(spec.alert),
    'p': TextElementBuilder(spec.p),
    'code': CodeElementBuilder(spec.code),
    'img': ImageElementBuilder(spec.image),
    'li': TextElementBuilder(spec.list?.text),
  };

  Map<String, MarkdownPaddingBuilder> get paddingBuilders {
    return _kBlockTags.fold(
      <String, MarkdownPaddingBuilder>{},
      (map, tag) => map..[tag] = ZeroPaddingBuilder(),
    );
  }

  Widget Function(bool) get checkboxBuilder {
    return (bool checked) {
      final icon = checked ? Icons.check_box : Icons.check_box_outline_blank;
      return IconSpecWidget(icon, spec: spec.checkbox?.icon);
    };
  }

  Widget Function(MarkdownBulletParameters params) get bulletBuilder {
    return (parameters) {
      final contents = switch (parameters.style) {
        BulletStyle.unorderedList => '•',
        BulletStyle.orderedList => '${parameters.index + 1}.',
      };
      return TextSpecWidget(spec: spec.list?.bullet, contents);
    };
  }
}

final _kBlockTags = <String>[
  'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', //
  'ul', 'ol', 'li', 'blockquote', //
  'pre', 'ol', 'ul', 'hr', 'table', //
  'thead', 'tbody', 'tr', 'section'
];

class CustomHeaderSyntax extends md.HeaderSyntax {
  const CustomHeaderSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final element = super.parse(parser) as md.Element;

    final tag = getTagAndContent(parser.lines.first.content).tag;
    if (tag != null) {
      element.attributes['hero'] = tag;
    }
    return element;
  }
}

class CustomImageSyntax extends md.InlineSyntax {
  CustomImageSyntax() : super(_pattern);

  static const String _pattern = r'!\[(.*?)\]\((.*?)\)(?:\s*\{\.([^\}]+)\})?';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final altText = match.group(1)!;
    final url = match.group(2)!;
    final tag = match.group(3);

    final element = md.Element.empty('img');
    element.attributes['src'] = url;
    element.attributes['alt'] = altText;

    if (tag != null) {
      element.attributes['hero'] = tag;
    }

    parser.addNode(element);
    return true;
  }
}
