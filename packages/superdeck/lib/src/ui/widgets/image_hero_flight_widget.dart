import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'cache_image_widget.dart';
import 'hero_element.dart';

/// Builds an image shuttle from the Hero endpoints for either flight direction.
Widget buildImageHeroFlight(
  BuildContext context,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  final to = HeroElement.of<ImageElement>(toContext);
  final from = HeroElement.maybeOf<ImageElement>(fromContext) ?? to;
  return ImageHeroFlight(
    from: from,
    to: to,
    animation: direction == HeroFlightDirection.push
        ? animation
        : ReverseAnimation(animation),
  );
}

/// Moves an image between frames while blending different image sources.
class ImageHeroFlight extends StatelessWidget {
  final ImageElement from;
  final ImageElement to;
  final Animation<double> animation;

  const ImageHeroFlight({
    super.key,
    required this.from,
    required this.to,
    required this.animation,
  });

  Widget _image(ImageElement element, ImageSpec spec) =>
      element.flightImage ??
      CachedImage(
        key: ValueKey(element.uri),
        uri: element.uri,
        styleSpec: StyleSpec(spec: spec),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = animation.value;
      final spec = from.spec.lerp(to.spec, t);
      final blend = Curves.easeInOut.transform(t);

      // Hero's overlay already interpolates the measured endpoint rectangles.
      // A second size tween from block dimensions is wrong for intrinsically sized
      // images and images with only one explicit dimension.
      final sameUri = from.uri == to.uri;
      final endpoint = to.flightImage ?? from.flightImage;
      return SizedBox.expand(
        key: const ValueKey('image-hero-flight'),
        child: sameUri
            ? endpoint ?? _image(from, spec)
            : Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(opacity: 1 - blend, child: _image(from, spec)),
                  Opacity(opacity: blend, child: _image(to, spec)),
                ],
              ),
      );
    },
  );
}
