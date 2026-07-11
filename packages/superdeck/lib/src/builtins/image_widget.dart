import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/slide_configuration.dart';
import '../markdown/builders/image_element_builder.dart' show isBareAssetKey;
import '../rendering/blocks/block_provider.dart';
import '../ui/widgets/cache_image_widget.dart';
import '../ui/widgets/provider.dart';
import '../ui/widgets/resolved_asset_image.dart';
import '../utils/converters.dart';

final _finitePositiveNumberSchema = Ack.number().finite().positive();

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

  /// Paint scale applied within the image frame.
  final double scale;

  ImageDto({
    required this.src,
    this.fit = ImageFit.contain,
    this.width,
    this.height,
    double scale = 1,
  }) : scale = _validateScale(scale);

  /// Schema for validating image arguments.
  ///
  /// `width`, `height`, and `scale` share one finite-positive numeric rule so
  /// integer authoring (`width: 300`, `scale: 1`) and doubles both validate.
  static final schema = Ack.object({
    'src': Ack.string().notEmpty(),
    'fit': ImageFit.schema.nullable().optional(),
    'width': _finitePositiveNumberSchema.nullable().optional(),
    'height': _finitePositiveNumberSchema.nullable().optional(),
    'scale': _finitePositiveNumberSchema.nullable().optional(),
  });

  /// Parses and validates raw map into typed ImageDto.
  static ImageDto parse(Map<String, Object?> map) {
    final rawSrc = map['src'];
    final trimmedSrc = rawSrc is String ? rawSrc.trim() : rawSrc;
    final normalizedMap = <String, Object?>{
      ...map,
      if (trimmedSrc is String) 'src': trimmedSrc,
    };
    final rawScale = normalizedMap['scale'];
    if (rawScale is num) {
      _validateScale(rawScale.toDouble());
    }
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
      scale: (normalizedMap['scale'] as num?)?.toDouble() ?? 1,
    );
  }

  static double _validateScale(double scale) {
    if (!scale.isFinite || scale <= 0) {
      throw ArgumentError.value(
        scale,
        'scale',
        'must be a finite number greater than zero',
      );
    }
    return scale;
  }

  /// Parses image source into a [Uri].
  ///
  /// Security: This method handles `@image` blocks from YAML configuration,
  /// which is trusted author-provided content. Markdown image sources
  /// (untrusted user content) use [UriValidator] for path traversal protection.
  static Uri _parseUri(String src) {
    // Handle Windows absolute paths (e.g., C:\path\to\file.png).
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(src)) {
      return Uri.file(src, windows: true);
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
/// - `scale` (optional): Paint scale within the image frame - default: 1
class ImageWidget extends StatelessWidget {
  final ImageDto _data;

  ImageWidget(Map<String, Object?> args, {super.key})
    : _data = ImageDto.parse(args);

  @override
  Widget build(BuildContext context) {
    final data = BlockConfiguration.of(context);
    final spec = data.spec;
    final alignment = data.align;
    final flutterAlignment = alignment.toAlignment;

    final styleSpec = StyleSpec(
      spec: spec.image.spec.copyWith(
        fit: _data.fit.toBoxFit,
        alignment: flutterAlignment,
      ),
    );

    // Resolve a bare-key src (e.g. an in-memory AI-generated image) through the
    // slide's asset cache when bound; otherwise render the source directly.
    final assetCacheStore = InheritedData.maybeOf<SlideConfiguration>(
      context,
    )?.assetCacheStore;
    final Widget image = (assetCacheStore != null && isBareAssetKey(_data.src))
        ? ResolvedAssetImage(
            assetKey: _data.src.path,
            store: assetCacheStore,
            fallback: _data.src,
            targetSize: data.size,
            styleSpec: styleSpec,
          )
        : CachedImage(
            uri: _data.src,
            targetSize: data.size,
            styleSpec: styleSpec,
          );

    final hasExplicitSize = _data.width != null || _data.height != null;

    if (_data.scale == 1) {
      final constrained = hasExplicitSize
          ? SizedBox(width: _data.width, height: _data.height, child: image)
          : image;
      return Align(alignment: flutterAlignment, child: constrained);
    }

    final transformed = Transform.scale(
      scale: _data.scale,
      alignment: flutterAlignment,
      child: image,
    );
    final Widget frame = hasExplicitSize
        ? SizedBox(width: _data.width, height: _data.height, child: transformed)
        : SizedBox.fromSize(
            size: data.size,
            child: Align(alignment: flutterAlignment, child: transformed),
          );

    return Align(
      alignment: flutterAlignment,
      child: ClipRect(child: frame),
    );
  }
}
