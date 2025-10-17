import 'package:superdeck_core/superdeck_core.dart';

import 'block_parser.dart';

/// Stage 2 of 3-stage parsing: Converts slide markdown into structured layout.
///
/// Parses custom @section/@column directives to create a tree of [SectionBlock]
/// objects representing the slide's layout structure. This is build-time processing
/// specific to SuperDeck's layout DSL.
///
/// See also:
/// - [MarkdownParser] - Stage 1: Splits presentation into slides
/// - [BlockParser] - Parses individual @section/@column directives
class SectionParser {
  const SectionParser();

  List<SectionBlock> parse(String content) {
    final parsedBlocks = const BlockParser().parse(content);

    final updatedContent = _updateIgnoredTags(content);

    // If there are no tag blocks, we can just add the entire markdown as a single section.
    if (parsedBlocks.isEmpty) {
      return [SectionBlock.text(updatedContent)];
    }

    final aggregator = _SectionAggregator();

    final firstBlock = parsedBlocks.first;

    if (firstBlock.startIndex > 0) {
      aggregator.addContent(updatedContent.substring(0, firstBlock.startIndex));
    }

    for (var idx = 0; idx < parsedBlocks.length; idx++) {
      final parsedBlock = parsedBlocks[idx];

      final isLast = idx == parsedBlocks.length - 1;

      String blockContent;
      if (isLast) {
        blockContent = updatedContent.substring(parsedBlock.endIndex).trim();
      } else {
        final nextBlock = parsedBlocks[idx + 1];
        blockContent = updatedContent.substring(
          parsedBlock.endIndex,
          nextBlock.startIndex,
        );
      }

      final block = parsedBlock.type == 'section'
          ? SectionBlock.parse(parsedBlock.data)
          : Block.parse(parsedBlock.data);

      aggregator
        ..addBlock(block)
        ..addContent(blockContent);
    }

    return aggregator.sections;
  }
}

String _updateIgnoredTags(String content) {
  return content.split('\n').map((line) {
    return line.trim().startsWith('_@')
        ? line.replaceFirst('_@', '@')
        : line;
  }).join('\n');
}

class _SectionAggregator {
  List<SectionBlock> sections = [];

  _SectionAggregator();

  SectionBlock _getSection() {
    if (sections.isEmpty) {
      sections.add(SectionBlock([]));
    }

    return sections.last;
  }

  void addContent(String content) {
    if (content.trim().isEmpty) return;

    final section = _getSection();
    final lastBlock = section.blocks.lastOrNull;

    final updatedBlocks = switch (lastBlock) {
      ColumnBlock(content: final existingContent) => [
          ...section.blocks.take(section.blocks.length - 1),
          lastBlock.copyWith(
            content: existingContent.isEmpty
                ? content
                : '$existingContent\n$content',
          ),
        ],
      _ => [...section.blocks, ColumnBlock(content)],
    };

    sections.last = section.copyWith(blocks: updatedBlocks);
  }

  void addBlock(Block block) {
    if (block is SectionBlock) {
      sections.add(block);
    } else {
      final lastSection = _getSection();
      final blocks = [...lastSection.blocks, block];

      sections.last = lastSection.copyWith(blocks: blocks);
    }
  }
}
