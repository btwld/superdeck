part of 'deck_generator_service.dart';

/// Sanitizes a slide key for safe filesystem use.
///
/// Removes or replaces characters that are invalid in filenames across
/// common filesystems (Windows, macOS, Linux).
String _fileSafeKey(String key, int index) {
  final cleaned = key
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00]'), '-') // Invalid on Windows
      .replaceAll(RegExp(r'\s+'), '-') // Spaces to dashes
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-') // Keep only safe chars
      .replaceAll(RegExp(r'-{2,}'), '-') // Collapse multiple dashes
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), ''); // Trim leading/trailing
  return cleaned.isEmpty ? 'slide-$index' : cleaned;
}

/// Removes stale asset files that don't match current slide keys.
Future<void> _cleanupStaleAssets(
  List<Map<String, dynamic>> slides, {
  Map<String, int> sourceSlideIndicesByKey = const {},
}) async {
  final assetsDir = Directory(Paths.superdeckAssetsPath);
  if (!await assetsDir.exists()) return;

  // Build set of valid filenames using sanitized keys
  final validThumbnails = <String>{};
  final validIllustrations = <String>{};

  for (var i = 0; i < slides.length; i++) {
    final key = slides[i]['key']?.toString();
    if (key == null) continue;
    final sourceIndex = sourceSlideIndicesByKey[key] ?? i;
    final safeKey = _fileSafeKey(key, sourceIndex);
    validThumbnails.add('thumbnail_$safeKey.png');
    validIllustrations.add('slide-$safeKey-illustration.png');
  }

  try {
    await for (final entity in assetsDir.list()) {
      if (entity is! File) continue;

      final filename = p.basename(entity.path);
      if (filename == '.gitkeep') continue;

      var shouldDelete = false;

      if (filename.startsWith('thumbnail_')) {
        shouldDelete = !validThumbnails.contains(filename);
      } else if (filename.startsWith('slide-') &&
          filename.endsWith('-illustration.png')) {
        shouldDelete = !validIllustrations.contains(filename);
      } else if (filename.startsWith('slide-') &&
          filename.endsWith('-bg.png')) {
        shouldDelete = true;
      }

      if (shouldDelete) {
        try {
          await entity.delete();
        } catch (e) {
          debugLog.log('CLEANUP', 'Could not delete $filename: $e');
        }
      }
    }
  } catch (e) {
    debugLog.log('CLEANUP', 'Could not list assets directory: $e');
  }
}

/// Image requirement extracted from outline.
class _ImageRequirement {
  const _ImageRequirement({
    required this.slideKey,
    required this.subject,
    required this.sourceSlideIndex,
  });

  final String slideKey;
  final String subject;
  final int sourceSlideIndex;
}

/// Results from parallel image generation.
class _ImageGenerationResults {
  const _ImageGenerationResults({
    required this.successes,
    required this.failures,
  });

  final Map<String, String> successes;
  final Map<String, String> failures;
}

List<Map<String, dynamic>> _sanitizeSlides(List<Map<String, dynamic>> slides) {
  return slides.map(_sanitizeSlide).nonNulls.toList();
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

  slide['sections'] = sections;
  return slide;
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
