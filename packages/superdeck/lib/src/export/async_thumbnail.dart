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
  bool _disposed = false;
  Timer? _debounceTimer;

  /// The generator function that asynchronously returns an Image.
  final AsyncFileGenerator _generator;

  AsyncThumbnail({required AsyncFileGenerator generator})
    : _generator = generator;

  /// Debounced notification to reduce excessive rebuilds
  void _debouncedNotifyListeners() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (!_disposed) {
        // Schedule notification after the current build frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) {
            notifyListeners();
          }
        });
      }
    });
  }

  Future<void> _generate(BuildContext context, [bool force = false]) async {
    if (_disposed) return;

    _status = AsyncFileStatus.loading;
    if (_imageFile != null) {
      FileImage(_imageFile!).evict();
    }
    _imageFile = null;
    _debouncedNotifyListeners();

    try {
      _imageFile = await _generator(context, force);
    } catch (e) {
      _status = AsyncFileStatus.error;
      _imageFile = null;
    } finally {
      _status = AsyncFileStatus.done;
      if (!_disposed) {
        _debouncedNotifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
    _disposed = true;
  }

  Future<void> load(BuildContext context, [bool force = false]) async {
    if (force) {
      return _generate(context, true);
    }
    return switch (_status) {
      AsyncFileStatus.idle => _generate(context),
      AsyncFileStatus.done => Future.value(),
      AsyncFileStatus.loading => Future.value(),
      AsyncFileStatus.error => _generate(context),
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
