import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:superdeck/src/ui/ui.dart';
import 'package:superdeck/src/ui/widgets/cache_image_widget.dart';

typedef AsyncFileGenerator =
    Future<File> Function(BuildContext context, bool force);

enum AsyncFileStatus { idle, loading, done, error }

/// A model that asynchronously loads an image and notifies listeners of changes.
class AsyncThumbnail extends ChangeNotifier {
  AsyncFileStatus _status = AsyncFileStatus.idle;
  File? _imageFile;
  Object? _error;
  bool _disposed = false;

  /// The generator function that asynchronously returns an Image.
  final AsyncFileGenerator _generator;

  /// Returns the last error that occurred during thumbnail generation.
  Object? get error => _error;

  AsyncThumbnail({required AsyncFileGenerator generator})
    : _generator = generator;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _generate(BuildContext context, {required bool force}) async {
    if (_disposed) return;

    _status = AsyncFileStatus.loading;
    if (_imageFile != null) {
      FileImage(_imageFile!).evict();
    }
    _imageFile = null;
    _notify();

    try {
      _imageFile = await _generator(context, force);
      _status = AsyncFileStatus.done;
      _error = null;
    } catch (error, stackTrace) {
      debugPrint('[AsyncThumbnail] Failed to generate thumbnail: $error');
      debugPrint('[AsyncThumbnail] Stack trace: $stackTrace');
      _status = AsyncFileStatus.error;
      _error = error;
      _imageFile = null;
    }

    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load(BuildContext context, [bool force = false]) {
    if (_disposed) return Future.value();
    if (force) {
      return _generate(context, force: true);
    }

    return switch (_status) {
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
    final file = _imageFile;
    if (file == null) {
      return null;
    }

    return getImageProvider(file.uri);
  }

  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, child) {
        return switch (_status) {
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
      gaplessPlayback: true,
      image: provider,
      errorBuilder: (context, error, _) {
        return _errorWidget(context, this);
      },
    );
  }
}
