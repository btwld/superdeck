import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'error_widgets.dart';

ImageProvider getImageProvider(Uri uri) {
  switch (uri.scheme) {
    case 'http':
    case 'https':
      return CachedNetworkImageProvider(uri.toString());
    case 'file':
      if (kIsWeb) {
        return AssetImage(uri.path);
      }
      return FileImage(File.fromUri(uri));
    default:
      // Absolute paths are treated as files on non-web platforms.
      if (!kIsWeb && uri.hasAbsolutePath) {
        return FileImage(File.fromUri(uri));
      }
      return AssetImage(uri.path);
  }
}

class CachedImage extends StatelessWidget {
  final Uri uri;

  final Size? targetSize;

  final StyleSpec<ImageSpec> styleSpec;

  const CachedImage({
    super.key,
    this.targetSize,
    required this.uri,
    this.styleSpec = const StyleSpec(spec: ImageSpec()),
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = getImageProvider(uri);

    return StyledImage(
      image: imageProvider,
      styleSpec: styleSpec,
      errorBuilder: (context, error, stackTrace) {
        return ErrorWidgets.simple('Error loading image: $uri');
      },
    );
  }
}
