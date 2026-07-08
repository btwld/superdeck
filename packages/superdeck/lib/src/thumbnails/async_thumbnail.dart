import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../ui/widgets/cache_image_widget.dart';
import '../ui/widgets/error_widgets.dart';
import '../ui/widgets/loading_indicator.dart';

typedef AsyncFileGenerator =
    Future<Uri?> Function(BuildContext context, {required bool force});

enum AsyncFileStatus { idle, loading, done, error }

/// An asynchronously loaded thumbnail backed by signals.
class AsyncThumbnail {
  final String thumbnailKey;
  final AsyncFileGenerator _generator;

  final _status = signal<AsyncFileStatus>(AsyncFileStatus.idle);
  final _imageUri = signal<Uri?>(null);
  final _error = signal<Object?>(null);
  ImageProvider<Object>? _cachedProvider;

  bool _disposed = false;
  bool _isGenerating = false;
  bool _pendingForce = false;

  AsyncThumbnail({
    required this.thumbnailKey,
    required AsyncFileGenerator generator,
  }) : _generator = generator;

  Future<void> _generate(BuildContext context, {required bool force}) async {
    if (_disposed || _isGenerating) return;
    _isGenerating = true;

    _status.value = AsyncFileStatus.loading;
    final currentUri = _imageUri.value;
    if (currentUri != null) {
      // Evict only the previous thumbnail provider to avoid global cache churn.
      final cachedProvider = _cachedProvider;
      if (cachedProvider != null) {
        imageCache.evict(cachedProvider);
      }
    }
    _imageUri.value = null;
    _cachedProvider = null;

    try {
      final uri = await _generator(context, force: force);

      // Guard after async - disposal could have happened during generation
      if (_disposed) return;

      if (uri == null) {
        _status.value = AsyncFileStatus.error;
        _error.value = StateError('Thumbnail unavailable');
        _imageUri.value = null;
        _cachedProvider = null;
        return;
      }

      _imageUri.value = uri;
      _cachedProvider = getImageProvider(uri);
      _status.value = AsyncFileStatus.done;
      _error.value = null;
    } catch (error, _) {
      // Guard after async - don't update signals if disposed
      if (_disposed) return;

      _status.value = AsyncFileStatus.error;
      _error.value = error;
      _imageUri.value = null;
      _cachedProvider = null;
    } finally {
      _isGenerating = false;
      if (!_disposed && _pendingForce && context.mounted) {
        _pendingForce = false;
        unawaited(_generate(context, force: true));
      } else {
        _pendingForce = false;
      }
    }
  }

  void dispose() {
    _disposed = true;
    _pendingForce = false;
    _cachedProvider = null;
    _status.dispose();
    _imageUri.dispose();
    _error.dispose();
  }

  Future<void> load(BuildContext context, [bool force = false]) {
    if (_disposed) return Future.value();
    if (_isGenerating) {
      if (force) {
        _pendingForce = true;
      }
      return Future.value();
    }
    if (force) {
      return _generate(context, force: true);
    }

    return switch (_status.value) {
      AsyncFileStatus.done || AsyncFileStatus.loading => Future.value(),
      AsyncFileStatus.idle ||
      AsyncFileStatus.error => _generate(context, force: false),
    };
  }

  Widget _errorWidget(BuildContext context, AsyncThumbnail thumbnail) {
    return ErrorWidgets.withRetry(
      'Failed to load thumbnail',
      () => thumbnail.load(context, true),
    );
  }

  ReadonlySignal<AsyncFileStatus> get status => _status;
  ReadonlySignal<Object?> get error => _error;

  /// The cached image provider, or `null` before loading completes.
  ImageProvider<Object>? get imageProvider {
    return _cachedProvider;
  }

  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        return switch (_status.value) {
          AsyncFileStatus.idle => const IsometricLoading(),
          AsyncFileStatus.loading => const IsometricLoading(),
          AsyncFileStatus.done => _buildLoadedImage(context),
          AsyncFileStatus.error => _errorWidget(context, this),
        };
      },
    );
  }

  Widget _buildLoadedImage(BuildContext context) {
    final provider = imageProvider;
    if (provider == null) {
      return _errorWidget(context, this);
    }

    return Image(
      gaplessPlayback: false,
      image: provider,
      errorBuilder: (context, error, _) => _errorWidget(context, this),
    );
  }
}
