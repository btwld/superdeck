part of 'deck_generator_service.dart';

final class _PlannedImage {
  const _PlannedImage({
    required this.slideKey,
    required this.subject,
    required this.assetKey,
  });

  final String slideKey;
  final String subject;
  final String assetKey;
}

Future<List<GeneratedImageAsset>> _runImagePhase(
  DeckGeneratorService owner, {
  required Map<String, dynamic> outline,
  required DeckGenerationImageConfiguration? configuration,
  required GenerationProgressCallback? onProgress,
  required ImageGenerationProgressCallback? onImageProgress,
  required bool Function()? isCancelled,
}) async {
  final generator = owner.imageGenerator;
  if (configuration == null || generator == null) return const [];

  onProgress?.call(GenerationPhase.generatingImages);
  return generateImagesForOutline(
    outline: outline,
    configuration: configuration,
    generator: generator,
    onProgress: onImageProgress,
    isCancelled: isCancelled,
  );
}

@visibleForTesting
Future<List<GeneratedImageAsset>> generateImagesForOutline({
  required Map<String, dynamic> outline,
  required DeckGenerationImageConfiguration configuration,
  required ImageGenerator generator,
  ImageGenerationProgressCallback? onProgress,
  bool Function()? isCancelled,
}) async {
  final planned = _plannedImages(outline);
  if (planned.isEmpty) {
    onProgress?.call(0, 0);
    return const [];
  }

  var nextIndex = 0;
  var completed = 0;
  final results = List<GeneratedImageAsset?>.filled(planned.length, null);
  onProgress?.call(0, planned.length);

  Future<void> worker() async {
    while (true) {
      if (isCancelled?.call() ?? false) return;
      final workIndex = nextIndex++;
      if (workIndex >= planned.length) return;

      final image = planned[workIndex];
      final styledSubject = '${image.subject}, ${configuration.styleTreatment}';
      final prompt = buildPresentationImagePrompt(
        styledSubject,
        backgroundColor: configuration.backgroundColor,
      );
      ImageGenerationResult result;
      try {
        result = await generator.generate(
          ImageGenerationRequest(
            prompt: prompt,
            aspectRatio: GeneratedImageAspectRatio.slide3x4,
          ),
        );
      } catch (error) {
        result = ImageGenerationFailure(
          const ErrorClassifier().getUserMessage(error),
        );
      }

      results[workIndex] = switch (result) {
        ImageGenerationSuccess(:final bytes) => GeneratedImageAsset.success(
          assetKey: image.assetKey,
          slideKey: image.slideKey,
          subject: image.subject,
          prompt: prompt,
          aspectRatio: GeneratedImageAspectRatio.slide3x4,
          bytes: bytes,
        ),
        ImageGenerationFailure(:final message) => GeneratedImageAsset.failure(
          assetKey: image.assetKey,
          slideKey: image.slideKey,
          subject: image.subject,
          prompt: prompt,
          aspectRatio: GeneratedImageAspectRatio.slide3x4,
          error: message,
        ),
      };
      completed++;
      onProgress?.call(completed, planned.length);
    }
  }

  final workerCount = planned.length < 2 ? planned.length : 2;
  await Future.wait(List.generate(workerCount, (_) => worker()));
  return results.nonNulls.toList(growable: false);
}

List<_PlannedImage> _plannedImages(Map<String, dynamic> outline) {
  final slides = outline['slides'];
  if (slides is! List) return const [];

  final planned = <_PlannedImage>[];
  for (final entry in slides.asMap().entries) {
    final slide = entry.value;
    if (slide is! Map) continue;
    final requirement = slide['imageRequirement'];
    if (requirement is! Map) continue;
    final subject = requirement['subject']?.toString().trim() ?? '';
    if (subject.isEmpty) continue;
    final slideKey =
        slide['key']?.toString().trim() ?? 'slide-${entry.key + 1}';
    planned.add(
      _PlannedImage(
        slideKey: slideKey,
        subject: subject,
        assetKey: buildGeneratedAssetKey(entry.key, slideKey),
      ),
    );
  }
  return planned;
}

@visibleForTesting
String buildGeneratedAssetKey(int slideIndex, String slideKey) {
  final slug = slideKey
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  final safeSlug = slug.isEmpty ? 'slide' : slug;
  final filenameSlug = safeSlug.length <= 64
      ? safeSlug
      : safeSlug.substring(0, 64).replaceFirst(RegExp('-+\$'), '');
  final number = (slideIndex + 1).toString().padLeft(2, '0');
  return 'slide-$number-$filenameSlug-illustration.png';
}

@visibleForTesting
String formatGeneratedImagesForPrompt(List<GeneratedImageAsset> images) {
  if (images.isEmpty) {
    return '## Generated Image Assets\n\nNo image assets were supplied. Keep the deck text-only.';
  }

  final buffer = StringBuffer()
    ..writeln('## Generated Image Assets (required)')
    ..writeln()
    ..writeln(
      'For every entry below, place a second content block on the matching '
      'slide containing exactly `![subject](asset-key)`. Use the exact bare '
      'asset key even when its status is failed; failed assets intentionally '
      'render as broken placeholders until the user retries them.',
    )
    ..writeln();
  for (final image in images) {
    buffer.writeln(
      '- Slide `${image.slideKey}`: `${image.assetKey}` '
      '(${image.status.name}) — ${image.subject}',
    );
  }
  return buffer.toString();
}

/// Ensures the model cannot omit a planned asset reference from its slide.
///
/// The final-deck prompt still controls placement. This fallback only appends
/// the exact bare key when the matching slide contains no such image.
@visibleForTesting
void ensureGeneratedImageReferences(
  List<Map<String, dynamic>> slides,
  List<GeneratedImageAsset> images,
) {
  for (final image in images) {
    Map<String, dynamic>? matchingSlide;
    for (final slide in slides) {
      if (slide['key'] == image.slideKey) {
        matchingSlide = slide;
        break;
      }
    }
    if (matchingSlide == null || _containsAssetKey(matchingSlide, image)) {
      continue;
    }

    final sections = (matchingSlide['sections'] as List)
        .map((section) => Map<String, dynamic>.from(section as Map))
        .toList();
    matchingSlide['sections'] = sections;
    Map<String, dynamic>? targetSection;
    for (final rawSection in sections.reversed) {
      final section = rawSection;
      final blocks = (section['blocks'] as List)
          .map((block) => Map<String, dynamic>.from(block as Map))
          .toList();
      section['blocks'] = blocks;
      if (blocks.length < 2) {
        targetSection = section;
        break;
      }
    }

    final block = <String, dynamic>{
      'type': 'block',
      'content': _imageMarkdown(image),
    };
    if (targetSection == null) {
      sections.add(<String, dynamic>{
        'type': 'section',
        'blocks': <Map<String, dynamic>>[block],
      });
    } else {
      (targetSection['blocks'] as List<Map<String, dynamic>>).add(block);
    }
  }
}

bool _containsAssetKey(Map<String, dynamic> slide, GeneratedImageAsset image) {
  final sections = slide['sections'];
  if (sections is! List) return false;
  for (final section in sections) {
    if (section is! Map) continue;
    final blocks = section['blocks'];
    if (blocks is! List) continue;
    for (final block in blocks) {
      if (block is! Map) continue;
      final content = block['content'];
      if (content is String && content.contains('](${image.assetKey})')) {
        return true;
      }
    }
  }
  return false;
}

String _imageMarkdown(GeneratedImageAsset image) {
  final altText = image.subject
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]')
      .trim();
  return '![$altText](${image.assetKey})';
}
