import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/src/ui/ui.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';

typedef AsyncFileGenerator =
    Future<Uri?> Function(BuildContext context, bool force);

enum AsyncFileStatus { idle, loading, done, error }

/// A model that asynchronously loads an image and uses Signals for reactivity.
class AsyncThumbnail {
  /// The generator function that asynchronously returns an Image.
  final AsyncFileGenerator _generator;
  final String? filePath;

  // Signals for reactive state
  final _status = signal<AsyncFileStatus>(AsyncFileStatus.idle);
  final _imageUri = signal<Uri?>(null);
  final _error = signal<Object?>(null);

  // Non-reactive internal state
  bool _disposed = false;
  bool _isGenerating = false;

  // Readonly accessors
  ReadonlySignal<AsyncFileStatus> get status => _status;
  ReadonlySignal<Object?> get error => _error;
  bool get shouldRefreshOnSync {
    final currentStatus = _status.peek();
    return switch (currentStatus) {
      AsyncFileStatus.error => true,
      AsyncFileStatus.done => _imageUri.peek() == null,
      AsyncFileStatus.idle || AsyncFileStatus.loading => false,
    };
  }

  AsyncThumbnail({required AsyncFileGenerator generator, this.filePath})
    : _generator = generator;

  Future<void> _generate(BuildContext context, {required bool force}) async {
    if (_disposed || _isGenerating) return;
    _isGenerating = true;

    _status.value = AsyncFileStatus.loading;
    final currentUri = _imageUri.value;
    if (currentUri != null) {
      // Evict only the previous thumbnail provider to avoid flushing
      // unrelated images from the global image cache.
      unawaited(getImageProvider(currentUri).evict());
    }
    _imageUri.value = null;

    try {
      final uri = await _generator(context, force);

      // Guard after async - disposal could have happened during generation
      if (_disposed) return;

      _imageUri.value = uri;
      _status.value = AsyncFileStatus.done;
      _error.value = null;
    } catch (error, _) {
      // Guard after async - don't update signals if disposed
      if (_disposed) return;

      _status.value = AsyncFileStatus.error;
      _error.value = error;
      _imageUri.value = null;
    } finally {
      _isGenerating = false;
    }
  }

  void dispose() {
    _disposed = true;

    // Dispose signals
    _status.dispose();
    _imageUri.dispose();
    _error.dispose();
  }

  Future<void> load(BuildContext context, [bool force = false]) {
    if (_disposed || _isGenerating) return Future.value();
    if (force) {
      return _generate(context, force: true);
    }

    return switch (_status.value) {
      AsyncFileStatus.done || AsyncFileStatus.loading => Future.value(),
      AsyncFileStatus.idle ||
      AsyncFileStatus.error => _generate(context, force: false),
    };
  }

  Widget _placeholderWidget() {
    return ErrorWidgets.simple('Preview unavailable');
  }

  /// Returns the resolved image provider when the file has loaded.
  ///
  /// Returns null if the file has not been generated yet.
  ImageProvider<Object>? get imageProvider {
    final uri = _imageUri.value;
    if (uri == null) {
      return null;
    }

    return getImageProvider(uri);
  }

  Widget build(BuildContext context) {
    return Watch((context) {
      return switch (_status.value) {
        AsyncFileStatus.idle => _buildIdleState(context),
        AsyncFileStatus.loading => const IsometricLoading(),
        AsyncFileStatus.done => _buildLoadedImage(context),
        AsyncFileStatus.error => _placeholderWidget(),
      };
    });
  }

  Widget _buildIdleState(BuildContext context) {
    // Lazy load on first render to avoid preloading every thumbnail.
    unawaited(load(context));
    return const IsometricLoading();
  }

  Widget _buildLoadedImage(BuildContext context) {
    final provider = imageProvider;
    if (provider == null) {
      return _placeholderWidget();
    }

    return Image(
      gaplessPlayback: false,
      image: provider,
      errorBuilder: (context, error, _) => _placeholderWidget(),
    );
  }
}
