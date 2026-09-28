import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'cache_image_widget.dart';
import 'hero_element.dart';

/// Moves an image between frames while blending different image sources.
Widget buildImageHeroFlight(
  BuildContext context,
  ImageElement from,
  ImageElement to,
  double t,
) {
  final spec = from.spec.lerp(to.spec, t);
  final blend = Curves.easeInOut.transform(t);

  Widget image(ImageElement element) =>
      element.flightImage ??
      CachedImage(
        key: ValueKey(element.uri),
        uri: element.uri,
        styleSpec: StyleSpec(spec: spec),
      );

  // Hero's overlay already interpolates the measured endpoint rectangles.
  // A second size tween from block dimensions is wrong for intrinsically sized
  // images and images with only one explicit dimension.
  return SizedBox.expand(
    key: const ValueKey('image-hero-flight'),
    child:
        from.uri == to.uri && from.flightImage == null && to.flightImage == null
        ? image(from)
        : Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: 1 - blend, child: image(from)),
              Opacity(opacity: blend, child: image(to)),
            ],
          ),
  );
}
