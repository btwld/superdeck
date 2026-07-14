import 'dart:typed_data';

/// Aspect ratios supported by Wizard image generation.
enum GeneratedImageAspectRatio {
  preview16x9('16:9'),
  slide3x4('3:4');

  const GeneratedImageAspectRatio(this.apiValue);

  final String apiValue;

  static GeneratedImageAspectRatio parse(String value) {
    return values.firstWhere(
      (ratio) => ratio.apiValue == value,
      orElse: () => throw FormatException(
        'Unsupported generated image aspect ratio: $value',
      ),
    );
  }
}

/// Persistence status for an image planned during deck generation.
enum GeneratedImageStatus { ready, failed }

/// A generated or failed slide image together with everything needed to retry.
final class GeneratedImageAsset {
  GeneratedImageAsset.success({
    required this.assetKey,
    required this.slideKey,
    required this.subject,
    required this.prompt,
    required this.aspectRatio,
    required List<int> bytes,
  }) : bytes = Uint8List.fromList(bytes),
       error = null;

  const GeneratedImageAsset.failure({
    required this.assetKey,
    required this.slideKey,
    required this.subject,
    required this.prompt,
    required this.aspectRatio,
    required this.error,
  }) : bytes = null;

  final String assetKey;
  final String slideKey;
  final String subject;
  final String prompt;
  final GeneratedImageAspectRatio aspectRatio;
  final Uint8List? bytes;
  final String? error;

  GeneratedImageStatus get status =>
      bytes == null ? GeneratedImageStatus.failed : GeneratedImageStatus.ready;
}
