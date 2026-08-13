import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../../capture/slide_capture_readiness.dart';
import '../../utils/constants.dart';
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
    case 'data':
      final bytes = uri.data?.contentAsBytes();
      if (bytes == null) {
        return AssetImage(uri.path);
      }
      return MemoryImage(bytes);
    default:
      // Relative paths are filesystem-backed in native debug runtimes
      // (for example .superdeck-generated assets and local project images)
      // and bundled assets everywhere else.
      if (kCanRunProcess) {
        return FileImage(File(uri.path).absolute);
      }
      return AssetImage(uri.path);
  }
}

class CachedImage extends StatefulWidget {
  final Uri uri;

  final Size? targetSize; // ignore: unused-code

  final StyleSpec<ImageSpec> styleSpec;

  const CachedImage({
    super.key,
    this.targetSize,
    required this.uri,
    this.styleSpec = const StyleSpec(spec: ImageSpec()),
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  SlideCaptureReadinessHandle? _readiness;
  Uri? _trackedUri;

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _completeReadiness();
      _trackedUri = null;
    }
  }

  @override
  void dispose() {
    _completeReadiness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureReadiness(context);
    final imageProvider = getImageProvider(widget.uri);

    return StyledImage(
      image: imageProvider,
      styleSpec: widget.styleSpec,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) _completeReadiness();
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        _completeReadiness();
        return ErrorWidgets.simple('Error loading image: ${widget.uri}');
      },
    );
  }

  void _ensureReadiness(BuildContext context) {
    if (_trackedUri == widget.uri && _readiness != null) return;
    _completeReadiness();
    _trackedUri = widget.uri;
    _readiness = SlideCaptureReadiness.track(
      context,
      label: 'image:${widget.uri}',
    );
  }

  void _completeReadiness() {
    _readiness?.complete();
    _readiness = null;
  }
}
