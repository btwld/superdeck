import 'package:superdeck_ai/core/utils/hash_utils.dart';

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

String? _extractFirstContent(Map<String, dynamic> slide) {
  final sections = slide['sections'] as List?;
  if (sections == null || sections.isEmpty) return null;

  for (final section in sections) {
    final blocks = (section as Map?)?['blocks'] as List?;
    if (blocks == null) continue;

    for (final block in blocks) {
      final content = (block as Map?)?['content'] as String?;
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }
  }

  return null;
}
