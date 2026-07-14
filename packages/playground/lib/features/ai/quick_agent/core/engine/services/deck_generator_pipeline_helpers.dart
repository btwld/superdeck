part of 'deck_generator_service.dart';

@visibleForTesting
List<Map<String, dynamic>> sanitizeGeneratedSlides(
  List<Map<String, dynamic>> slides,
) {
  return slides.map(_sanitizeSlide).nonNulls.toList();
}

@visibleForTesting
Map<String, dynamic> hydrateGeneratedElementSources({
  required Map<String, dynamic> slide,
  required DeckPlanSlideType planSlide,
  required GenerationElementCatalog elementCatalog,
}) {
  final hydrated = Map<String, dynamic>.from(slide);
  final rawSections = slide['sections'];
  if (rawSections is! List) return hydrated;

  hydrated['sections'] = [
    for (final rawSection in rawSections)
      if (rawSection is Map)
        _hydrateSectionElementSources(
          rawSection,
          planSlide: planSlide,
          elementCatalog: elementCatalog,
        )
      else
        rawSection,
  ];
  return hydrated;
}

Map<String, dynamic> _hydrateSectionElementSources(
  Map<dynamic, dynamic> rawSection, {
  required DeckPlanSlideType planSlide,
  required GenerationElementCatalog elementCatalog,
}) {
  final section = Map<String, dynamic>.from(rawSection);
  final rawBlocks = rawSection['blocks'];
  if (rawBlocks is! List) return section;
  section['blocks'] = [
    for (final rawBlock in rawBlocks)
      if (rawBlock is Map)
        _hydrateBlockElementSource(
          rawBlock,
          planSlide: planSlide,
          elementCatalog: elementCatalog,
        )
      else
        rawBlock,
  ];
  return section;
}

Map<String, dynamic> _hydrateBlockElementSource(
  Map<dynamic, dynamic> rawBlock, {
  required DeckPlanSlideType planSlide,
  required GenerationElementCatalog elementCatalog,
}) {
  final block = Map<String, dynamic>.from(rawBlock);
  if (block['type'] != WidgetBlock.key) return block;
  final name = block['name']?.toString();
  if (name == null) return block;

  final plannedElement = planSlide.elements?.where((element) {
    final plannedName = element.type == 'custom'
        ? element.widgetName
        : element.type;
    return plannedName == name;
  }).firstOrNull;
  final rawArgs = block['args'];
  final args = rawArgs is Map
      ? Map<String, Object?>.from(rawArgs)
      : <String, Object?>{};
  block['args'] = elementCatalog.normalizeDraftArguments(
    name,
    args,
    plannedElement?.source,
  );
  return block;
}

Map<String, dynamic>? _sanitizeSlide(Map<String, dynamic> slide) {
  final sanitizedSlide = Map<String, dynamic>.from(slide);
  final sections = <Map<String, dynamic>>[];
  final rawSections = slide['sections'];
  if (rawSections is List) {
    for (final rawSection in rawSections) {
      final cleaned = _sanitizeSection(rawSection);
      if (cleaned != null) {
        sections.add(cleaned);
      }
    }
  }

  if (sections.isEmpty) {
    return null;
  }

  sanitizedSlide['sections'] = sections;
  return sanitizedSlide;
}

Map<String, dynamic>? _sanitizeSection(dynamic rawSection) {
  if (rawSection is! Map) {
    return null;
  }

  final section = Map<String, dynamic>.from(rawSection);
  section['type'] = 'section';
  final rawBlocks = rawSection['blocks'];
  final blocks = <Map<String, dynamic>>[];

  if (rawBlocks is List) {
    for (final rawBlock in rawBlocks) {
      final cleaned = _sanitizeBlock(rawBlock);
      if (cleaned != null) {
        blocks.add(cleaned);
      }
    }
  }

  if (blocks.isEmpty) {
    return null;
  }

  section['blocks'] = blocks;
  return section;
}

Map<String, dynamic>? _sanitizeBlock(dynamic rawBlock) {
  if (rawBlock is! Map) {
    return null;
  }

  final block = Map<String, dynamic>.from(rawBlock);
  final rawType = block['type']?.toString().trim() ?? '';
  final type = rawType.isEmpty ? 'block' : rawType;

  if (type == 'block') {
    final content = _normalizeGeneratedMarkdown(
      block['content']?.toString().trim() ?? '',
    );
    if (content.isEmpty) {
      return null;
    }
    block['type'] = 'block';
    block['content'] = content;
    block.remove('name');
    return block;
  }

  if (type == 'widget') {
    final name = block['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      return null;
    }
    block['type'] = 'widget';
    block.remove('content');
    final draftArgs = block.remove('args');
    if (draftArgs is Map) {
      for (final entry in draftArgs.entries) {
        block.putIfAbsent(entry.key.toString(), () => entry.value);
      }
    }
    return block;
  }

  final content = _normalizeGeneratedMarkdown(
    block['content']?.toString().trim() ?? '',
  );
  if (content.isEmpty) {
    return null;
  }
  block['type'] = 'block';
  block['content'] = content;
  block.remove('name');
  return block;
}

String _normalizeGeneratedMarkdown(String content) {
  if (content.contains('\n') ||
      !content.contains(r'\n') ||
      !RegExp(r'^\s*(?:#{1,6}\s|[-*+]\s|>\s|\|)').hasMatch(content)) {
    return content;
  }
  return content.replaceAll(r'\n', '\n');
}
