import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

import '../../modules/common/helpers/constants.dart';

ImageProvider getImageProvider(Uri uri) {
  switch (uri.scheme) {
    case 'http':
    case 'https':
      return CachedNetworkImageProvider(uri.toString());
    default:
      if (kCanRunProcess) {
        return FileImage(File.fromUri(uri));
      } else {
        return AssetImage(uri.path);
      }
  }
}

class CachedImage extends StatelessWidget {
  final Uri uri;

  final Size? targetSize;

  final ImageSpec spec;

  const CachedImage({
    super.key,
    this.targetSize,
    required this.uri,
    this.spec = const ImageSpec(),
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = getImageProvider(uri);

    return AnimatedImageSpecWidget(
      image: imageProvider,
      spec: spec,
      // frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      //   return Container(
      //     padding: const EdgeInsets.all(0),
      //     constraints: BoxConstraints.loose(imageSize ?? size),
      //     decoration: BoxDecoration(
      //       color: Colors.green,
      //       image: DecorationImage(
      //         image: imageProvider,
      //         fit: widget.spec.fit,
      //         alignment: widget.spec.alignment ?? Alignment.center,
      //       ),
      //     ),
      //   );
      // },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red,
          child: Center(
            child: Text('Error loading image: $uri '),
          ),
        );
      },
    );
  }
}
