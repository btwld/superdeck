import 'dart:io';

import 'package:flutter/material.dart';
import 'package:superdeck/src/components/atoms/cache_image_widget.dart';
import 'package:superdeck/src/modules/deck/slide_configuration.dart';

import '../../components/atoms/loading_indicator.dart';
import '../common/helpers/constants.dart';
import '../common/helpers/provider.dart';
import 'slide_capture_service.dart';

typedef AsyncFileGenerator = Future<File> Function(
  BuildContext context,
  bool force,
);

enum AsyncFileStatus {
  idle,
  loading,
  done,
  error,
}

/// A model that asynchronously loads an image and notifies listeners of changes.
class AsyncThumbnail extends ChangeNotifier {
  AsyncFileStatus _status = AsyncFileStatus.idle;
  File? _imageFile;
  Object? _error;
  bool _disposed = false;

  /// The generator function that asynchronously returns an Image.
  final AsyncFileGenerator _generator;

  AsyncThumbnail({required AsyncFileGenerator generator})
      : _generator = generator;

  Future<void> _generate(BuildContext context, [bool force = false]) async {
    if (_disposed) return;

    _status = AsyncFileStatus.loading;
    _error = null;
    if (_imageFile != null) {
      FileImage(_imageFile!).evict();
    }
    _imageFile = null;
    notifyListeners();

    try {
      _imageFile = await _generator(context, force);
    } catch (e) {
      _error = e;
      _status = AsyncFileStatus.error;
      _imageFile = null;
    } finally {
      _status = AsyncFileStatus.done;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 40,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => thumbnail.load(context, true),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  /// Synchronously returns the loaded image.
  ///
  /// Should be called only when the image has finished loading.
  /// Throws an exception if the image is still loading or if loading failed.
  File get requireData {
    return switch (_status) {
      AsyncFileStatus.idle => throw Exception("Image has not been loaded yet."),
      AsyncFileStatus.loading => throw Exception("Image is still loading."),
      AsyncFileStatus.error => throw Exception("Image failed to load: $_error"),
      AsyncFileStatus.done => _imageFile!,
    };
  }

  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, child) {
        return switch (_status) {
          AsyncFileStatus.idle => const IsometricLoading(),
          AsyncFileStatus.loading => const IsometricLoading(),
          AsyncFileStatus.done => Image(
              gaplessPlayback: true,
              image: getImageProvider(requireData.uri),
              errorBuilder: (context, error, _) {
                return _errorWidget(context, this);
              },
            ),
          AsyncFileStatus.error => _errorWidget(context, this),
        };
      },
    );
  }
}

/// A controller that manages thumbnail images for slides.
class ThumbnailController extends ChangeNotifier {
  ThumbnailController();

  final Map<String, AsyncThumbnail> _thumbnails = {};
  final _slideCaptureService = SlideCaptureService();

  void generateThumbnails(
    List<SlideConfiguration> slides,
    BuildContext context, {
    bool force = false,
  }) {
    for (final slide in slides) {
      _getAsyncThumbnail(slide, context).load(context, force);
    }
  }

  @override
  void dispose() {
    super.dispose();

    for (final thumbnail in _thumbnails.values) {
      thumbnail.dispose();
    }
    _thumbnails.clear();
  }

  AsyncThumbnail get(
    SlideConfiguration slide,
    BuildContext context,
  ) {
    return _getAsyncThumbnail(slide, context)..load(context);
  }

  AsyncThumbnail _getAsyncThumbnail(
      SlideConfiguration slide, BuildContext context) {
    return _thumbnails.putIfAbsent(slide.key, () {
      return AsyncThumbnail(generator: (context, force) async {
        return _generateThumbnail(
          slide: slide,
          context: context,
          force: force,
        );
      });
    });
  }

  Future<File> _generateThumbnail({
    required SlideConfiguration slide,
    required BuildContext context,
    required bool force,
  }) async {
    final thumbnailFile = File(slide.thumbnailFile);

    if (!kCanRunProcess) {
      return thumbnailFile;
    }

    final isValid =
        await thumbnailFile.exists() && (await thumbnailFile.length()) > 0;

    if (isValid && !force) {
      return thumbnailFile;
    }

    final imageData = await _slideCaptureService.capture(
      slide: slide,
      // ignore: use_build_context_synchronously
      context: context,
    );

    await thumbnailFile.writeAsBytes(imageData, flush: false);

    return thumbnailFile;
  }

  static ThumbnailController of(BuildContext context) {
    return InheritedNotifierData.of<ThumbnailController>(context);
  }
}
