import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/src/ui/ui.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';

typedef AsyncFileGenerator =
    Future<File> Function(BuildContext context, bool force);

enum AsyncFileStatus { idle, loading, done, error }

/// A model that asynchronously loads an image and uses Signals for reactivity.
class AsyncThumbnail {
  /// The generator function that asynchronously returns an Image.
  final AsyncFileGenerator _generator;

  // Signals for reactive state
  final _status = signal<AsyncFileStatus>(AsyncFileStatus.idle);
  final _imageFile = signal<File?>(null);
  final _error = signal<Object?>(null);

  // Non-reactive internal state
  bool _disposed = false;
  bool _isGenerating = false;

  // Readonly accessors
  ReadonlySignal<AsyncFileStatus> get status => _status;
  ReadonlySignal<Object?> get error => _error;

  AsyncThumbnail({required AsyncFileGenerator generator})
    : _generator = generator;

  Future<void> _generate(BuildContext context, {required bool force}) async {
    if (_disposed || _isGenerating) return;
    _isGenerating = true;

    _status.value = AsyncFileStatus.loading;
    final currentFile = _imageFile.value;
    if (currentFile != null) {
      FileImage(currentFile).evict();
    }
    _imageFile.value = null;

    try {
      final file = await _generator(context, force);

      // Guard after async - disposal could have happened during generation
      if (_disposed) return;

      _imageFile.value = file;
      _status.value = AsyncFileStatus.done;
      _error.value = null;
    } catch (error, stackTrace) {
      // Guard after async - don't update signals if disposed
      if (_disposed) return;

      debugPrint('[AsyncThumbnail] Failed to generate thumbnail: $error');
      debugPrint('[AsyncThumbnail] Stack trace: $stackTrace');
      _status.value = AsyncFileStatus.error;
      _error.value = error;
      _imageFile.value = null;
    } finally {
      _isGenerating = false;
    }
  }

  void dispose() {
    _disposed = true;

    // Dispose signals
    _status.dispose();
    _imageFile.dispose();
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

  Widget _errorWidget(BuildContext context, AsyncThumbnail thumbnail) {
    return ErrorWidgets.withRetry(
      'Failed to load thumbnail',
      () => thumbnail.load(context, true),
    );
  }

  /// Returns the resolved image provider when the file has loaded.
  ///
  /// Returns null if the file has not been generated yet.
  ImageProvider<Object>? get imageProvider {
    final file = _imageFile.value;
    if (file == null) {
      return null;
    }

    return getImageProvider(file.uri);
  }

  Widget build(BuildContext context) {
    return Watch((context) {
      return switch (_status.value) {
        AsyncFileStatus.idle => const IsometricLoading(),
        AsyncFileStatus.loading => const IsometricLoading(),
        AsyncFileStatus.done => _buildLoadedImage(context),
        AsyncFileStatus.error => _errorWidget(context, this),
      };
    });
  }

  Widget _buildLoadedImage(BuildContext context) {
    final provider = imageProvider;
    if (provider == null) {
      return _errorWidget(context, this);
    }

    return Image(
      gaplessPlayback: true,
      image: provider,
      errorBuilder: (context, error, _) {
        return _errorWidget(context, this);
      },
    );
  }
}
