import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/domain/design/presentation_image_style_catalog.dart';
import 'image_generator.dart';

enum ImageStylePreviewStatus { loading, ready, failed }

/// Current preview state for one exact versioned style.
final class ImageStylePreview {
  final PresentationImageStyleDescriptor style;
  final ImageStylePreviewStatus status;
  final Uint8List? bytes;
  final String? error;

  const ImageStylePreview({
    required this.style,
    required this.status,
    this.bytes,
    this.error,
  });

  ImageStylePreview copyWith({
    PresentationImageStyleDescriptor? style,
    ImageStylePreviewStatus? status,
    Uint8List? bytes,
    String? error,
    bool clearBytes = false,
    bool clearError = false,
  }) {
    return ImageStylePreview(
      style: style ?? this.style,
      status: status ?? this.status,
      bytes: clearBytes ? null : (bytes ?? this.bytes),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Owns the Wizard preview plan and begins it immediately after topic entry.
///
/// Provider calls cannot currently be aborted, so reset/restart invalidates an
/// epoch and ignores all late results. Repeating the same topic is idempotent.
final class ImageStylePreviewCoordinator extends ChangeNotifier {
  final ImageGenerator _generator;
  final List<PresentationImageStyleDescriptor> _styles;

  String? _topic;
  List<ImageStylePreview> _previews = const [];
  var _epoch = 0;
  var _disposed = false;

  ImageStylePreviewCoordinator({
    required ImageGenerator generator,
    required PresentationImageStyleCatalog catalog,
    Iterable<String> styleIds = featuredPresentationImageStyleIds,
  }) : _generator = generator,
       _styles = .unmodifiable(
         styleIds.map((id) {
           final style = catalog.current(id);
           if (style == null) {
             throw ArgumentError('Unknown preview image style "$id".');
           }

           return style;
         }),
       ) {
    if (_styles.length != 3 ||
        _styles.map((style) => style.id).toSet().length != 3) {
      throw ArgumentError('Image preview plan requires three unique styles.');
    }
  }

  Future<void> _generate(
    PresentationImageStyleDescriptor style,
    int epoch,
  ) async {
    final topic = _topic;
    if (topic == null) return;
    final prompt = buildPresentationImagePrompt(style.buildPrompt(topic));
    final result = await generateImageSafely(
      _generator,
      ImageGenerationRequest(prompt: prompt, aspectRatio: .landscape16x9),
    );
    if (_disposed || epoch != _epoch) return;

    final index = _previews.indexWhere(
      (preview) => preview.style.id == style.id,
    );
    if (index < 0) return;
    _replace(index, switch (result) {
      ImageGenerationSuccess(:final bytes) => _previews[index].copyWith(
        status: .ready,
        bytes: bytes,
        clearError: true,
      ),
      ImageGenerationFailure(:final message) => _previews[index].copyWith(
        status: .failed,
        error: message,
        clearBytes: true,
      ),
    });
    notifyListeners();
  }

  void _replace(int index, ImageStylePreview preview) {
    _previews = [..._previews]..[index] = preview;
  }

  String? get topic => _topic;

  List<ImageStylePreview> get previews => .unmodifiable(_previews);

  void prefetch(String rawTopic) {
    final topic = rawTopic.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (topic.isEmpty || _disposed) return;
    if (_topic == topic && _previews.isNotEmpty) return;

    final epoch = ++_epoch;
    _topic = topic;
    _previews = [
      for (final style in _styles)
        ImageStylePreview(style: style, status: .loading),
    ];
    notifyListeners();

    for (final style in _styles) {
      unawaited(_generate(style, epoch));
    }
  }

  void retry(String styleId) {
    if (_disposed || _topic == null) return;
    final index = _previews.indexWhere(
      (preview) => preview.style.id == styleId,
    );
    if (index < 0 || _previews[index].status != .failed) return;

    _replace(
      index,
      _previews[index].copyWith(
        status: .loading,
        clearBytes: true,
        clearError: true,
      ),
    );
    notifyListeners();
    unawaited(_generate(_previews[index].style, _epoch));
  }

  void reset() {
    if (_disposed) return;
    _epoch++;
    _topic = null;
    _previews = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
