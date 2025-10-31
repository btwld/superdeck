import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/widget_definition.dart';
import '../rendering/blocks/block_provider.dart';
import '../ui/widgets/cache_image_widget.dart';
import '../utils/converters.dart';

/// Strongly-typed data transfer object for image widget.
class ImageDto {
  /// The asset to display.
  final GeneratedAsset asset;

  /// How the image should fit within its bounds.
  final ImageFit fit;

  /// Optional explicit width.
  final double? width;

  /// Optional explicit height.
  final double? height;

  const ImageDto({
    required this.asset,
    this.fit = ImageFit.cover,
    this.width,
    this.height,
  });

  /// Schema for validating image arguments.
  static final schema = Ack.object({
    'asset': GeneratedAsset.schema,
    'fit': ImageFit.schema.nullable().optional(),
    'width': Ack.double().positive().nullable().optional(),
    'height': Ack.double().positive().nullable().optional(),
  });

  /// Parses and validates raw map into typed ImageDto.
  static ImageDto parse(Map<String, Object?> map) {
    schema.parse(map); // Validate first

    // Parse asset
    final assetMap = map['asset'] as Map<String, dynamic>;
    final asset = GeneratedAsset.fromMap(assetMap);

    // Parse optional fit
    final fitStr = map['fit'] as String?;
    final fit = fitStr != null ? ImageFit.fromJson(fitStr) : ImageFit.cover;

    return ImageDto(
      asset: asset,
      fit: fit,
      width: (map['width'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
    );
  }
}

/// Built-in widget for displaying images in slides.
///
/// Usage in markdown:
/// ```markdown
/// @image {
///   asset:
///     name: example
///     extension: png
///     type: image
///   fit: contain
///   width: 300
///   height: 200
/// }
/// ```
///
/// Parameters:
/// - `asset` (required): GeneratedAsset map with name, extension, type
/// - `fit` (optional): ImageFit enum value (cover, contain, fill, etc.) - default: cover
/// - `width` (optional): Image width in logical pixels
/// - `height` (optional): Image height in logical pixels
class ImageWidget extends WidgetDefinition<ImageDto> {
  const ImageWidget();

  @override
  ImageDto parse(Map<String, Object?> args) => ImageDto.parse(args);

  @override
  Widget build(BuildContext context, ImageDto args) {
    // Access block configuration for styling and sizing
    final data = BlockConfiguration.of(context);
    final spec = data.spec;

    // Get alignment from block configuration
    final alignment = data.align;

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
