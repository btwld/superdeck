import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/widget_definition.dart';
import '../rendering/blocks/block_provider.dart';
import '../ui/widgets/cache_image_widget.dart';
import '../utils/converters.dart';

/// Strongly-typed arguments for image widget.
class ImageArgs {
  /// The asset to display.
  final GeneratedAsset asset;

  /// How the image should fit within its bounds.
  final ImageFit fit;

  /// Optional explicit width.
  final double? width;

  /// Optional explicit height.
  final double? height;

  const ImageArgs({
    required this.asset,
    this.fit = ImageFit.cover,
    this.width,
    this.height,
  });

  /// Schema for validating image arguments.
  static final schema = Ack.object({
    'asset': GeneratedAsset.schema,
    'fit': ImageFit.schema.nullable().optional(),
    'width': Ack.double().nullable().optional(),
    'height': Ack.double().nullable().optional(),
  });

  /// Parses and validates raw map into typed ImageArgs.
  static ImageArgs parse(Map<String, Object?> map) {
    schema.parse(map); // Validate first

    // Parse asset
    final assetMap = map['asset'] as Map<String, dynamic>;
    final asset = GeneratedAsset.fromMap(assetMap);

    // Parse optional fit
    final fitStr = map['fit'] as String?;
    final fit = fitStr != null ? ImageFit.fromJson(fitStr) : ImageFit.cover;

    return ImageArgs(
      asset: asset,
      fit: fit,
      width: (map['width'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
    );
  }
}

/// Built-in widget for displaying images in slides.
///
/// Replaces the former ImageBlock with a schema-validated custom widget.
///
/// Usage in markdown:
/// ```markdown
/// @image {
///   asset:
///     fileName: images/example.png
///   fit: contain
///   width: 300
///   height: 200
/// }
/// ```
///
/// Parameters:
/// - `asset` (required): GeneratedAsset map with fileName
/// - `fit` (optional): ImageFit enum value (cover, contain, fill, etc.)
/// - `width` (optional): Image width in logical pixels
/// - `height` (optional): Image height in logical pixels
class ImageWidget extends WidgetDefinition<ImageArgs> {
  const ImageWidget();

  @override
  ImageArgs parse(Map<String, Object?> args) => ImageArgs.parse(args);

  @override
  Widget build(BuildContext context, ImageArgs args) {
    // Access block data for styling and sizing
    final data = BlockData.of(context);
    final spec = data.spec;

    // Get alignment from block data
    final alignment = data.block.align;

    // YAML-sourced URIs are trusted - no validation needed
    return CachedImage(
      uri: Uri.parse(args.asset.fileName),
      targetSize: data.size,
      styleSpec: StyleSpec(
        spec: spec.image.spec.copyWith(
          fit: ConverterHelper.toBoxFit(args.fit),
          alignment: ConverterHelper.toAlignment(alignment),
        ),
      ),
    );
  }
}
