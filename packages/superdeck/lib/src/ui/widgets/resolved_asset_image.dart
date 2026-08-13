import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../capture/slide_capture_readiness.dart';
import 'cache_image_widget.dart';

/// Renders an image whose source is a bare asset key by resolving it through an
/// [AssetCacheStore].
///
/// The store returns a `data:` URI for in-memory caches (web / `MemoryAssetCacheStore`)
/// or a `file:` URI for disk caches — both handled by [getImageProvider]. On a
/// cache miss the [fallback] URI is used, preserving the renderer's default
/// behavior for keys that aren't cached.
///
/// Resolution happens once per [assetKey] (re-run only when the key or store
/// changes), so live re-renders of the slide don't re-resolve on every frame.
class ResolvedAssetImage extends StatefulWidget {
  const ResolvedAssetImage({
    super.key,
    required this.assetKey,
    required this.store,
    required this.fallback,
    this.targetSize,
    this.styleSpec = const StyleSpec(spec: ImageSpec()),
  });

  final String assetKey;
  final AssetCacheStore store;
  final Uri fallback;
  final Size? targetSize;
  final StyleSpec<ImageSpec> styleSpec;

  @override
  State<ResolvedAssetImage> createState() => _ResolvedAssetImageState();
}

class _ResolvedAssetImageState extends State<ResolvedAssetImage> {
  late Future<Uri?> _resolved;
  SlideCaptureReadinessHandle? _readiness;
  var _resolutionComplete = false;
  var _resolutionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _startResolution();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trackResolution();
  }

  @override
  void didUpdateWidget(ResolvedAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetKey != widget.assetKey ||
        oldWidget.store != widget.store) {
      _startResolution();
      _trackResolution();
    }
  }

  @override
  void dispose() {
    _completeReadiness();
    super.dispose();
  }

  Future<Uri?> _resolve() async {
    try {
      return await widget.store.resolve(widget.assetKey);
    } catch (_) {
      return null;
    }
  }

  void _startResolution() {
    _completeReadiness();
    _resolutionComplete = false;
    final generation = ++_resolutionGeneration;
    _resolved = _resolve();
    _resolved.whenComplete(() {
      if (generation != _resolutionGeneration) return;
      _resolutionComplete = true;
      _completeReadiness();
    });
  }

  void _trackResolution() {
    if (_resolutionComplete || _readiness != null) return;
    _readiness = SlideCaptureReadiness.track(
      context,
      label: 'asset:${widget.assetKey}',
    );
  }

  void _completeReadiness() {
    _readiness?.complete();
    _readiness = null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uri?>(
      future: _resolved,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Brief placeholder while the (fast, usually in-memory) resolve runs.
          return SizedBox.fromSize(size: widget.targetSize);
        }
        final uri = snapshot.data ?? widget.fallback;
        return CachedImage(
          uri: uri,
          targetSize: widget.targetSize,
          styleSpec: widget.styleSpec,
        );
      },
    );
  }
}
