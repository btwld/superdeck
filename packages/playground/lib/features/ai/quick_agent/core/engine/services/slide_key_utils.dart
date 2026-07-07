import 'package:superdeck_core/superdeck_core.dart';

final RegExp _safeSlideKeyPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$');

/// Generates a deterministic slide key based on slide content.
String generateSlideKey(Map<String, dynamic> slide, int index) {
  final options = slide['options'] as Map<String, dynamic>?;
  final title = options?['title'] as String?;

  String contentForHash;
  if (title != null && title.isNotEmpty) {
    contentForHash = title;
  } else {
    contentForHash = _extractFirstContent(slide) ?? 'slide';
  }

  final hashInput = '$index:$contentForHash';
  return generateValueHash(hashInput);
}

/// Returns true when [key] is safe for SuperDeck IDs and generated filenames.
bool isSafeSlideKey(String key) {
  if (key.length > 80) return false;
  return _safeSlideKeyPattern.hasMatch(key);
}

/// Converts an AI-provided key into a safe key, falling back to a content hash.
String normalizeSlideKey(Map<String, dynamic> slide, int index) {
  final raw = slide['key']?.toString().trim() ?? '';
  final normalized = raw
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');

  if (isSafeSlideKey(normalized)) {
    return normalized;
  }

  return generateSlideKey(slide, index);
}

String? _extractFirstContent(Map<String, dynamic> slide) {
  final sections = slide['sections'];
  if (sections is! List || sections.isEmpty) return null;

  for (final section in sections) {
    if (section is! Map) continue;
    final blocks = section['blocks'];
    if (blocks is! List) continue;

    for (final block in blocks) {
      if (block is! Map) continue;
      final content = block['content']?.toString();
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }
  }

  return null;
}

/// Generates a unique slide key that is not in [usedKeys].
///
/// Tries up to [maxAttempts] candidate keys derived from [slide] content,
/// starting at [index]. On exhaustion uses `'${generateSlideKey(slide, index)}-$index'`
/// as a guaranteed-distinct fallback (matching workflow behavior).
String generateUniqueSlideKey(
  Map<String, dynamic> slide,
  int index,
  Set<String> usedKeys, {
  int maxAttempts = 1024,
}) {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final candidate = generateSlideKey(slide, index + attempt);
    if (!usedKeys.contains(candidate)) return candidate;
  }
  return '${generateSlideKey(slide, index)}-$index';
}
