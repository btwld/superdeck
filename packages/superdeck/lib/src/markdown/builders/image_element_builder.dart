import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';
import '../../deck/slide_configuration.dart';
import '../../rendering/blocks/block_provider.dart';
import '../../rendering/blocks/image_hero_positions.dart';
import '../../ui/widgets/cache_image_widget.dart';
import '../../ui/widgets/error_widgets.dart';
import '../../ui/widgets/hero_element.dart';
import '../../ui/widgets/image_hero_flight_widget.dart';
import '../../ui/widgets/provider.dart';
import '../../ui/widgets/resolved_asset_image.dart';
import '../../utils/uri_validator.dart';
import '../markdown_hero_mixin.dart';

/// True for a bare asset-key reference (no scheme, no path separators), e.g.
/// `slide-intro-illustration.png` — a candidate for [AssetCacheStore] resolution.
bool isBareAssetKey(Uri uri) =>
    uri.scheme.isEmpty &&
    uri.path.isNotEmpty &&
    !uri.path.contains('/') &&
    !uri.path.contains('\\');

class ImageElementBuilder extends MarkdownElementBuilder
    with MarkdownHeroMixin {
  final StyleSpec<ImageSpec> styleSpec;

  // Restarts only when `_MarkdownBuilder` recreates the registry that owns this
  // builder. Nested bodies, such as alerts, reuse this builder but parse with
  // `nestedBlockSyntaxes`, so their images never advance the count.
  int _nextImageIndex = 0;

  ImageElementBuilder([this.styleSpec = const StyleSpec(spec: ImageSpec())]);

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // For unit tests that call visitElementAfter directly without context.
    // In real rendering, visitElementAfterWithContext will be called instead
    // because isBlockElement() returns true.
    throw UnsupportedError(
      'ImageElementBuilder requires BuildContext for BlockConfiguration access. '
      'Use visitElementAfterWithContext or render through MarkdownBody.',
    );
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final src = element.attributes['src'];

    // Validate URI
    final Uri uri;
    try {
      final validated = UriValidator.validate(src);
      if (validated == null) {
        return ErrorWidgets.simple('Image source is empty');
      }
      uri = validated;
    } catch (e) {
      return ErrorWidgets.simple('Invalid image source: ${e.toString()}');
    }

    final slide = InheritedData.maybeOf<SlideConfiguration>(context);
    final block = BlockConfiguration.of(context);
    final isStandalone =
        element.attributes['data-superdeck-block-image'] == 'true';
    final heroTag =
        element.attributes['hero'] ??
        (isStandalone && (slide?.animateImages ?? true)
            ? automaticImageHeroTag(block.imageHeroStart + _nextImageIndex)
            : null);
    if (isStandalone) _nextImageIndex++;

    // Access BlockConfiguration from the context parameter (available because isBlockElement() is true)
    final totalSize = block.size;

    // A bare key (e.g. an AI-generated `slide-x-illustration.png`) is resolved
    // through the slide's asset cache when one is bound.
    final assetCacheStore = slide?.assetCacheStore;
    if (assetCacheStore != null && isBareAssetKey(uri)) {
      final image = ConstrainedBox(
        constraints: BoxConstraints.tight(totalSize),
        child: ResolvedAssetImage(
          assetKey: uri.path,
          store: assetCacheStore,
          fallback: uri,
          targetSize: totalSize,
          styleSpec: styleSpec,
        ),
      );
      return applyHeroIfNeeded<ImageElement>(
        context: context,
        child: image,
        heroTag: heroTag,
        heroData: ImageElement(
          spec: styleSpec.spec,
          uri: uri,
          size: totalSize,
          flightImage: image,
        ),
        flightShuttleBuilder: ImageHeroFlight.buildShuttle,
      );
    }

    return StyleSpecBuilder<ImageSpec>(
      builder: (builderContext, spec) {
        final imageWidget = ConstrainedBox(
          constraints: BoxConstraints.tight(totalSize),
          child: CachedImage(uri: uri, styleSpec: styleSpec),
        );

        return applyHeroIfNeeded<ImageElement>(
          context: builderContext,
          child: imageWidget,
          heroTag: heroTag,
          heroData: ImageElement(spec: spec, uri: uri, size: totalSize),
          flightShuttleBuilder: ImageHeroFlight.buildShuttle,
        );
      },
      styleSpec: styleSpec,
    );
  }
}
