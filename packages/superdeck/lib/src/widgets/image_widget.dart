import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/widget_definition.dart';
import '../rendering/blocks/block_provider.dart';
import '../ui/widgets/cache_image_widget.dart';
import '../utils/converters.dart';

/// Strongly-typed data transfer object for image widget.
class ImageDto {
  /// Image source.
  ///
  /// Can be:
  /// - A Flutter asset path (for example, `assets/logo.png`)
  /// - An absolute file path (for example, `/Users/me/image.png` or `file:///Users/me/image.png`)
  /// - A URL (for example, `https://...`)
  final Uri src;

  /// How the image should fit within its bounds.
  final ImageFit fit;

  /// Optional explicit width.
  final double? width;

  /// Optional explicit height.
  final double? height;

  const ImageDto({
    required this.src,
    this.fit = ImageFit.contain,
    this.width,
    this.height,
  });

  /// Schema for validating image arguments.
  static final schema = Ack.object({
    'src': Ack.string().notEmpty(),
    'fit': ImageFit.schema.nullable().optional(),
    'width': Ack.double().positive().nullable().optional(),
    'height': Ack.double().positive().nullable().optional(),
  });

  /// Parses and validates raw map into typed ImageDto.
  static ImageDto parse(Map<String, Object?> map) {
    final rawSrc = map['src'];
    final trimmedSrc = rawSrc is String ? rawSrc.trim() : rawSrc;
    final normalizedMap = <String, Object?>{
      ...map,
      if (trimmedSrc is String) 'src': trimmedSrc,
    };
    schema.parse(normalizedMap); // Validate first

    final src = (normalizedMap['src'] as String).trim();
    if (src.isEmpty) {
      throw const FormatException('Image widget requires a non-empty "src".');
    }

    final uri = _parseUri(src);

    // Parse optional fit
    final fitStr = normalizedMap['fit'] as String?;
    final fit = fitStr != null ? ImageFit.fromJson(fitStr) : ImageFit.contain;

    return ImageDto(
      src: uri,
      fit: fit,
      width: (normalizedMap['width'] as num?)?.toDouble(),
      height: (normalizedMap['height'] as num?)?.toDouble(),
    );
  }

  static Uri _parseUri(String src) {
    // Handle Windows absolute paths (e.g., C:\path\to\file.png).
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(src)) {
      return Uri.file(src);
    }

    return Uri.parse(src);
  }
}

/// Built-in widget for displaying images in slides.
///
/// Usage in markdown:
/// ```markdown
/// @image {
///   src: assets/logo.png
///   fit: contain
///   width: 300
///   height: 200
/// }
/// ```
///
/// Parameters:
/// - `src` (required): Asset path, file path, or URL
/// - `fit` (optional): ImageFit enum value (cover, contain, fill, etc.) - default: contain
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

    // Get alignment from block configuration.
    final alignment = data.align;

    final image = CachedImage(
      uri: args.src,
      targetSize: data.size,
      styleSpec: StyleSpec(
        spec: spec.image.spec.copyWith(
          fit: ConverterHelper.toBoxFit(args.fit),
          alignment: ConverterHelper.toAlignment(alignment),
        ),
      ),
    );

    final constrained = (args.width != null || args.height != null)
        ? SizedBox(width: args.width, height: args.height, child: image)
        : image;

    // Align within the block when the image is smaller than the available space.
    return Align(
      alignment: ConverterHelper.toAlignment(alignment),
      child: constrained,
    );
  }
}
