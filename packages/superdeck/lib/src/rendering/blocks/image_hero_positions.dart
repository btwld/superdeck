import 'package:markdown/markdown.dart' as md;
import 'package:superdeck_core/superdeck_core.dart';

import '../../markdown/markdown_element_builders_registry.dart';

/// Positions image Heroes by their order in a slide, regardless of layout.
class ImageHeroPositions {
  final Map<(int, int), int> _starts = {};

  ImageHeroPositions(Slide slide) {
    var nextIndex = 0;
    for (final (sectionIndex, section) in slide.sections.indexed) {
      for (final (blockIndex, block) in section.blocks.indexed) {
        _starts[(sectionIndex, blockIndex)] = nextIndex;
        nextIndex += switch (block) {
          WidgetBlock(name: 'image') => 1,
          ContentBlock(:final content) => _countMarkdownImages(content),
          _ => 0,
        };
      }
    }
  }

  static int _countMarkdownImages(String content) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      blockSyntaxes: markdownBlockSyntaxes(),
    );
    // Inline images become alt text in MarkdownViewer, and nested standalone
    // images render without an automatic tag, so only top-level standalone
    // images consume a Hero position.
    return document
        .parseLines(content.split('\n'))
        .whereType<md.Element>()
        .where(
          (element) =>
              element.attributes['data-superdeck-block-image'] == 'true',
        )
        .length;
  }

  int start(int sectionIndex, int blockIndex) =>
      _starts[(sectionIndex, blockIndex)] ?? 0;
}

// Colons keep generated tags disjoint from author-defined class identifiers.
String automaticImageHeroTag(int index) => 'superdeck:image:$index';
