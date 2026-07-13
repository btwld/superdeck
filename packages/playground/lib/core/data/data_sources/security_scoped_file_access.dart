import 'package:flutter/services.dart';

import '../../../features/editor/domain/files/deck_file.dart';

/// Bridges opaque macOS security-scoped bookmarks to the native runner.
///
/// App-owned files without a bookmark are intentional no-ops.
class SecurityScopedFileAccess {
  const SecurityScopedFileAccess({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  /// Channel shared with `MainFlutterWindow.swift`.
  static const channelName =
      'dev.superdeck.playground/security_scoped_bookmarks';

  final MethodChannel _channel;

  /// Opens the native panel and returns its path plus persistent access data.
  Future<DeckFileReference?> pickDeckFile() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickDeckFile',
    );
    if (result == null) return null;
    return _referenceFrom(result, operation: 'selection');
  }

  /// Starts access and returns the current path/bookmark after resolution.
  Future<DeckFileReference> startAccessing(DeckFileReference reference) async {
    final bookmark = reference.bookmark;
    if (bookmark == null) return reference;

    final result = await _channel.invokeMapMethod<String, Object?>(
      'startAccessing',
      bookmark,
    );
    if (result == null) {
      throw StateError('Native bookmark resolution returned no data.');
    }
    return _referenceFrom(result, operation: 'resolution');
  }

  DeckFileReference _referenceFrom(
    Map<String, Object?> result, {
    required String operation,
  }) {
    final path = result['path'];
    final refreshedBookmark = result['bookmark'];
    if (path is! String ||
        path.isEmpty ||
        refreshedBookmark is! String ||
        refreshedBookmark.isEmpty) {
      throw StateError('Native bookmark $operation returned invalid data.');
    }
    return DeckFileReference(path: path, bookmark: refreshedBookmark);
  }

  /// Stops access previously started for [reference].
  Future<void> stopAccessing(DeckFileReference reference) async {
    final bookmark = reference.bookmark;
    if (bookmark == null) return;
    await _channel.invokeMethod<void>('stopAccessing', bookmark);
  }
}
