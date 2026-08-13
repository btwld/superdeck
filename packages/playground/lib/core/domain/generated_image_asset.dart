import 'dart:typed_data';

/// Aspect ratios supported by Wizard image generation.
enum GeneratedImageAspectRatio {
  landscape16x9('16:9'),
  slide3x4('3:4');

  const GeneratedImageAspectRatio(this.apiValue);

  final String apiValue;
}

/// Ready bytes or a typed failure for one generated slide image.
final class GeneratedImageAsset {
  final String assetKey;

  final Uint8List? bytes;

  final String? error;
  GeneratedImageAsset.success({
    required this.assetKey,
    required List<int> bytes,
  }) : bytes = Uint8List.fromList(bytes),
       error = null;

  const GeneratedImageAsset.failure({
    required this.assetKey,
    required String error,
  }) : bytes = null,
       error = error;
}
