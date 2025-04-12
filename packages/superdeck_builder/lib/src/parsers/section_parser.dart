import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';

import 'base_parser.dart';
import 'block_parser.dart';

class SectionParser extends BaseParser<List<SlideSection>> {
  const SectionParser();

  @override
  List<SlideSection> parse(String content) {
    final parsedBlocks = const BlockParser().parse(content);

    final updatedContent = _updateIgnoredTags(content);

    // If there are no tag blocks, we can just add the entire markdown as a single section.
    if (parsedBlocks.isEmpty) {
      return [SlideSection.text(updatedContent)];
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
          ? SlideSection.parse(parsedBlock.data)
          : SlideElement.parse(parsedBlock.data);

      aggregator
        ..addBlock(block)
        ..addContent(blockContent);
    }

    return aggregator.sections;
  }
}

String _updateIgnoredTags(String content) {
  final lines = LineSplitter().convert(content);

  List<String> updatedLines = [];

  for (final line in lines) {
    final ignoreTag = '_@';
    final trimmedLine = line.trim();
    if (trimmedLine.startsWith(ignoreTag)) {
      updatedLines.add(line.replaceFirst(ignoreTag, '@'));
      continue;
    }

    updatedLines.add(line);
  }

  return updatedLines.join('\n');
}

class _SectionAggregator {
  List<SlideSection> sections = [];

  _SectionAggregator();

  SlideSection _getSection() {
    if (sections.isEmpty) {
      sections.add(SlideSection([]));
    }

    return sections.last;
  }

  void addContent(String content) {
    final section = _getSection();
    final block = section.blocks.lastOrNull;
    final blocks = [...section.blocks];

    if (content.trim().isEmpty) {
      return;
    }

    if (block is MarkdownElement) {
      final newContent =
          block.content.isEmpty ? content : '${block.content}\n$content';

      blocks.last = block.copyWith(content: newContent);
    } else {
      blocks.add(MarkdownElement(content));
    }

    sections.last = section.copyWith(blocks: blocks);
  }

  void addBlock(SlideElement block) {
    if (block is SlideSection) {
      sections.add(block);
    } else {
      final lastSection = _getSection();
      final blocks = [...lastSection.blocks, block];

      sections.last = lastSection.copyWith(blocks: blocks);
    }
  }
}
