import 'dart:convert';

import 'package:superdeck/src/models/block_model.dart';

import 'base_parser.dart';
import 'block_parser.dart';

class SectionParser extends BaseParser<List<SectionBlock>> {
  const SectionParser();

  @override
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
  List<SectionBlock> sections = [];

  _SectionAggregator();

  SectionBlock _getSection() {
    if (sections.isEmpty) {
      sections.add(SectionBlock([]));
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

    if (block is ColumnBlock) {
      final newContent =
          block.content.isEmpty ? content : '${block.content}\n$content';

      blocks.last = block.copyWith(content: newContent);
    } else {
      blocks.add(ColumnBlock(content));
    }

    sections.last = section.copyWith(blocks: blocks);
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
