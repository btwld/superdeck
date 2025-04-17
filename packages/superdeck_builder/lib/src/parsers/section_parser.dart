import 'dart:convert';

import 'package:superdeck_core/superdeck_core.dart';

import 'base_parser.dart';
import 'block_parser.dart';

class SectionParser extends BaseParser<List<SectionBlock>> {
  const SectionParser();

  @override
  List<SectionBlock> parse(String content) {
    final parsedBlocks = const BlockParser().parse(content);

    final updatedContent = _updateIgnoredTags(content);

    if (parsedBlocks.isEmpty) {
      return [SectionBlock.text(updatedContent)];
    }

    final aggregator = _SectionAggregator();

    final firstBlock = parsedBlocks.first;

    if (firstBlock.startIndex > 0) {
      aggregator.addContent(updatedContent.substring(0, firstBlock.startIndex));
    }

    const knownBlockKeys = {
      SectionBlock.key,
      MarkdownBlock.key,
      ImageBlock.key,
      DartPadBlock.key,
      WidgetBlock.key,
    };

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

      Map<String, dynamic> blockData;
      final originalData = parsedBlock._data;

      if (knownBlockKeys.contains(parsedBlock.type)) {
        blockData = {...originalData, 'type': parsedBlock.type};
      } else {
        blockData = {
          ...originalData,
          'id': parsedBlock.type,
          'type': WidgetBlock.key
        };
      }

      final BaseBlock block = BaseBlockMapper.fromMap(blockData);

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
    final currentSection = _getSection();
    final lastBlock = currentSection.blocks.lastOrNull;
    final currentBlocks = [...currentSection.blocks];

    if (content.trim().isEmpty) {
      return;
    }

    if (lastBlock is MarkdownBlock) {
      final newContent = lastBlock.content.isEmpty
          ? content
          : '${lastBlock.content}\n$content';

      currentBlocks[currentBlocks.length - 1] = MarkdownBlock(
        newContent,
        align: lastBlock.align,
        flex: lastBlock.flex,
        scrollable: lastBlock.scrollable,
      );
    } else {
      currentBlocks.add(MarkdownBlock(content));
    }

    sections[sections.length - 1] = SectionBlock(
      currentBlocks,
      align: currentSection.align,
      flex: currentSection.flex,
      scrollable: currentSection.scrollable,
    );
  }

  void addBlock(BaseBlock block) {
    if (block is SectionBlock) {
      sections.add(block);
    } else {
      final currentSection = _getSection();
      final newBlocks = [...currentSection.blocks, block];

      sections[sections.length - 1] = SectionBlock(
        newBlocks,
        align: currentSection.align,
        flex: currentSection.flex,
        scrollable: currentSection.scrollable,
      );
    }
  }
}
