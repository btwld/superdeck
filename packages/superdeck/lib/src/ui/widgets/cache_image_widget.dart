import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import 'error_widgets.dart';

ImageProvider getImageProvider(Uri uri) {
  final isMermaid = uri.path.contains('mermaid_');

  if (isMermaid) {
    debugPrint('[CachedImage] getImageProvider called with URI: $uri');
    debugPrint('[CachedImage]   scheme: ${uri.scheme}');
    debugPrint('[CachedImage]   path: ${uri.path}');
    debugPrint('[CachedImage]   hasAbsolutePath: ${uri.hasAbsolutePath}');
  }

  switch (uri.scheme) {
    case 'http':
    case 'https':
      if (isMermaid) {
        debugPrint('[CachedImage]   Using CachedNetworkImageProvider');
      }
      return CachedNetworkImageProvider(uri.toString());
    case 'file':
      if (kIsWeb) {
        if (isMermaid) {
          debugPrint('[CachedImage]   Using AssetImage with path: ${uri.path}');
        }
        return AssetImage(uri.path);
      }
      return _fileImage(uri, isMermaid);
    default:
      // Absolute paths are treated as files on non-web platforms.
      if (!kIsWeb && uri.hasAbsolutePath) {
        return _fileImage(uri, isMermaid);
      }
      if (isMermaid) {
        debugPrint('[CachedImage]   Using AssetImage with path: ${uri.path}');
      }
      return AssetImage(uri.path);
  }
}

ImageProvider _fileImage(Uri uri, bool isMermaid) {
  final file = File.fromUri(uri);
  if (isMermaid) {
    debugPrint('[CachedImage]   Using FileImage with path: ${file.path}');
    debugPrint('[CachedImage]   File absolute path: ${file.absolute.path}');

    // Check if file exists
    final exists = file.existsSync();
    debugPrint('[CachedImage]   File exists: $exists');

    if (!exists) {
      debugPrint(
        '[CachedImage]   ERROR: File does NOT exist at path: ${file.absolute.path}',
      );
      // Check if it exists with .superdeck prefix
      final withPrefix = File(
        '.superdeck/assets/${uri.pathSegments.last}',
      );
      final prefixExists = withPrefix.existsSync();
      debugPrint(
        '[CachedImage]   Trying with .superdeck prefix: ${withPrefix.path}',
      );
      debugPrint('[CachedImage]   Prefix path exists: $prefixExists');
    }
  }
  return FileImage(file);
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
    final isMermaid = uri.path.contains('mermaid_');
    if (isMermaid) {
      debugPrint('[CachedImage.build] Building image widget for URI: $uri');
    }
    final imageProvider = getImageProvider(uri);

    return StyledImage(
      image: imageProvider,
      styleSpec: styleSpec,
      errorBuilder: (context, error, stackTrace) {
        if (isMermaid) {
          debugPrint('[CachedImage] ERROR loading image: $uri');
          debugPrint('[CachedImage]   Error: $error');
          debugPrint('[CachedImage]   StackTrace: $stackTrace');
        }
        return ErrorWidgets.simple('Error loading image: $uri');
      },
    );
  }
}
