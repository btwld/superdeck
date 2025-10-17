import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

import '../../rendering/blocks/block_provider.dart';
import '../../ui/widgets/cache_image_widget.dart';
import '../../ui/widgets/error_widgets.dart';
import '../../ui/widgets/hero_element.dart';
import '../../utils/uri_validator.dart';
import '../markdown_hero_mixin.dart';

class ImageElementBuilder extends MarkdownElementBuilder
    with MarkdownHeroMixin {
  final StyleSpec<ImageSpec> styleSpec;

  ImageElementBuilder([this.styleSpec = const StyleSpec(spec: ImageSpec())]);

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // For unit tests that call visitElementAfter directly without context.
    // In real rendering, visitElementAfterWithContext will be called instead
    // because isBlockElement() returns true.
    throw UnsupportedError(
      'ImageElementBuilder requires BuildContext for BlockData access. '
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

    final heroTag = element.attributes['hero'];

    // Access BlockData from the context parameter (available because isBlockElement() is true)
    final totalSize = BlockData.of(context).size;

    return StyleSpecBuilder<ImageSpec>(
      styleSpec: styleSpec,
      builder: (builderContext, spec) {
        Widget imageWidget = ConstrainedBox(
          constraints: BoxConstraints.tight(totalSize),
          child: CachedImage(
            uri: uri,
            targetSize: totalSize,
            styleSpec: styleSpec,
          ),
        );

        return applyHeroIfNeeded<ImageElement>(
          context: builderContext,
          child: imageWidget,
          heroTag: heroTag,
          heroData: ImageElement(size: totalSize, spec: spec, uri: uri),
          buildFlight: (flightContext, from, to, t) {
            final fromSize = from.size;
            final fromSpec = from.spec;
            final fromUri = from.uri;

            final interpolatedSize = Size.lerp(fromSize, to.size, t)!;
            final interpolatedSpec = fromSpec.lerp(to.spec, t);
            // Switch to destination image halfway through transition
            final displayUri = t < 0.5 ? fromUri : to.uri;

            return Container(
              constraints: BoxConstraints.tight(interpolatedSize),
              child: CachedImage(
                uri: displayUri,
                targetSize: interpolatedSize,
                styleSpec: StyleSpec(spec: interpolatedSpec),
              ),
            );
          },
        );
      },
    );
  }
}
