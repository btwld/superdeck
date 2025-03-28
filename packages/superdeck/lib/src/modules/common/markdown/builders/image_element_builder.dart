import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';
import 'package:superdeck/src/components/molecules/block_provider.dart';
import 'package:superdeck/src/modules/deck/slide_configuration.dart';

import '../../../../components/atoms/cache_image_widget.dart';
import '../../helpers/utils.dart';
import 'element_data_provider.dart';

class ImageElementBuilder extends MarkdownElementBuilder {
  final ImageSpec spec;

  ImageElementBuilder(this.spec);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src']!;
    final heroTag = element.attributes['hero'];

    final uri = Uri.parse(src);

    return Builder(builder: (context) {
      final block = BlockData.of(context);
      final slide = SlideConfiguration.of(context);

      final hasHero = heroTag != null && !slide.isExporting;

      final contentOffset = getTotalModifierSpacing(spec);

      final totalSize = Size(
        block.size.width - contentOffset.dx,
        block.size.height - contentOffset.dy,
      );
      Widget current = AnimatedContainer(
        duration: Durations.medium1,
        constraints: BoxConstraints.tight(totalSize),
        child: CachedImage(
          uri: uri,
          targetSize: totalSize,
          spec: spec,
        ),
      );

      if (hasHero) {
        current = _ImageElementHero(
          tag: heroTag,
          child: current,
        );
      }

      return ImageElementDataProvider(
        size: totalSize,
        spec: spec,
        uri: uri,
        child: current,
      );
    });
  }
}

class _ImageElementHero extends StatelessWidget {
  const _ImageElementHero({
    required this.tag,
    required this.child,
  });

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: child,
      flightShuttleBuilder: (
        BuildContext context,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        final toBlock = ElementDataProvider.of<ImageElementDataProvider>(
          toHeroContext,
        );
        final fromBlock = ElementDataProvider.maybeOf<ImageElementDataProvider>(
          fromHeroContext,
        );

        final fromBlockSize =
            fromBlock?.size ?? ElementDataProvider.ofAny(fromHeroContext).size;

        final fromBlockSpec = fromBlock?.spec ?? toBlock.spec;

        final fromBlockUri = fromBlock?.uri ?? toBlock.uri;

        Widget buildImageWidget(Size size, ImageSpec spec, Uri uri) {
          return Container(
            constraints: BoxConstraints.tight(size),
            child: CachedImage(
              uri: uri,
              spec: spec,
            ),
          );
        }

        final interpolatedSize = Size.lerp(
          fromBlockSize,
          toBlock.size,
          animation.value,
        )!;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return buildImageWidget(
              interpolatedSize,
              fromBlockSpec.lerp(toBlock.spec, animation.value),
              animation.value < 0.5 ? fromBlockUri : toBlock.uri,
            );
          },
        );
      },
    );
  }
}
