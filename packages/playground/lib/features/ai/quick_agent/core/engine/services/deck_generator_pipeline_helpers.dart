part of 'deck_generator_service.dart';

@visibleForTesting
List<Map<String, dynamic>> sanitizeGeneratedSlides(
  List<Map<String, dynamic>> slides,
) {
  return slides.map(_sanitizeSlide).nonNulls.toList();
}

@visibleForTesting
String? validateGeneratedSlideCount({
  required int expectedSlideCount,
  required int actualSlideCount,
}) {
  final minimumSlideCount = minimumUsableSlideCount(expectedSlideCount);
  if (minimumSlideCount <= 0 || actualSlideCount >= minimumSlideCount) {
    return null;
  }

  final slideNoun = actualSlideCount == 1 ? 'slide' : 'slides';
  return 'Generated only $actualSlideCount usable $slideNoun; expected at least '
      '$minimumSlideCount of $expectedSlideCount requested slides. '
      'Please try again.';
}

@visibleForTesting
int minimumUsableSlideCount(int expectedSlideCount) {
  if (expectedSlideCount <= 1) {
    return expectedSlideCount;
  }

  final seventyFivePercent = (expectedSlideCount * 3 + 3) ~/ 4;
  return seventyFivePercent < 2 ? 2 : seventyFivePercent;
}

Map<String, dynamic>? _sanitizeSlide(Map<String, dynamic> slide) {
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

  _sanitizeSlideOptions(slide);
  slide['sections'] = sections;
  return slide;
}

void _sanitizeSlideOptions(Map<String, dynamic> slide) {
  final rawOptions = slide['options'];
  if (rawOptions is! Map) {
    slide.remove('options');
    return;
  }

  final options = Map<String, dynamic>.from(rawOptions);
  final safeOptions = <String, dynamic>{
    if (options['title'] case final String title when title.trim().isNotEmpty)
      'title': title,
    if (options['layout'] case final String layout
        when layout.trim().isNotEmpty)
      'layout': layout,
  };

  if (safeOptions.isEmpty) {
    slide.remove('options');
  } else {
    slide['options'] = safeOptions;
  }
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
    final content = block['content']?.toString().trim() ?? '';
    if (content.isEmpty) {
      return null;
    }
    block['type'] = 'block';
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
    return block;
  }

  final content = block['content']?.toString().trim() ?? '';
  if (content.isEmpty) {
    return null;
  }
  block['type'] = 'block';
  block.remove('name');
  return block;
}
