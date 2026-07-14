import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'cache_image_widget.dart';

/// Renders an image whose source is a bare asset key by resolving it through an
/// [AssetCacheStore].
///
/// The store returns a `data:` URI for in-memory caches (web / `MemoryAssetCacheStore`)
/// or a `file:` URI for disk caches — both handled by [getImageProvider]. On a
/// cache miss the [fallback] URI is used, preserving the renderer's default
/// behavior for keys that aren't cached.
///
/// Resolution runs when the key or store changes. If the store also implements
/// [Listenable], notifications re-resolve the key so a newly written asset can
/// replace a previous cache miss without rebuilding the deck.
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

  @override
  void initState() {
    super.initState();
    _attachStoreListener(widget.store);
    _resolved = _resolve();
  }

  @override
  void didUpdateWidget(ResolvedAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final storeChanged = oldWidget.store != widget.store;
    if (storeChanged) {
      _detachStoreListener(oldWidget.store);
      _attachStoreListener(widget.store);
    }
    if (oldWidget.assetKey != widget.assetKey || storeChanged) {
      _resolved = _resolve();
    }
  }

  @override
  void dispose() {
    _detachStoreListener(widget.store);
    super.dispose();
  }

  void _attachStoreListener(AssetCacheStore store) {
    if (store case final Listenable listenable) {
      listenable.addListener(_onStoreChanged);
    }
  }

  void _detachStoreListener(AssetCacheStore store) {
    if (store case final Listenable listenable) {
      listenable.removeListener(_onStoreChanged);
    }
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {
      _resolved = _resolve();
    });
  }

  Future<Uri?> _resolve() async {
    try {
      return await widget.store.resolve(widget.assetKey);
    } catch (_) {
      return null;
    }
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
