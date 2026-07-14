import 'package:flutter/services.dart';

import '../../../features/editor/domain/files/deck_file.dart';

/// A user-selected directory that remains accessible across app launches.
final class SecurityScopedDirectoryReference {
  const SecurityScopedDirectoryReference({
    required this.path,
    required this.bookmark,
  });

  final String path;
  final String bookmark;

  @override
  int get hashCode => Object.hash(path, bookmark);

  @override
  bool operator ==(Object other) {
    return other is SecurityScopedDirectoryReference &&
        other.path == path &&
        other.bookmark == bookmark;
  }
}

/// Bridges opaque macOS security-scoped bookmarks to the native runner.
///
/// Files covered by the active decks-directory scope have no individual
/// bookmark and are intentional no-ops.
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
    final reference = _referenceValues(result, operation: 'selection');
    return DeckFileReference(
      path: reference.path,
      bookmark: reference.bookmark,
    );
  }

  /// Prompts for the parent directory where the `SuperDeck` folder will live.
  Future<SecurityScopedDirectoryReference?> pickDecksDirectory() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickDecksDirectory',
    );
    if (result == null) return null;
    final reference = _referenceValues(
      result,
      operation: 'directory selection',
    );
    return SecurityScopedDirectoryReference(
      path: reference.path,
      bookmark: reference.bookmark,
    );
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
    final active = _referenceValues(result, operation: 'resolution');
    return DeckFileReference(path: active.path, bookmark: active.bookmark);
  }

  /// Starts persistent access to a previously selected decks directory.
  Future<SecurityScopedDirectoryReference> startAccessingDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'startAccessing',
      reference.bookmark,
    );
    if (result == null) {
      throw StateError(
        'Native directory bookmark resolution returned no data.',
      );
    }
    final active = _referenceValues(result, operation: 'directory resolution');
    return SecurityScopedDirectoryReference(
      path: active.path,
      bookmark: active.bookmark,
    );
  }

  ({String path, String bookmark}) _referenceValues(
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
    return (path: path, bookmark: refreshedBookmark);
  }

  /// Stops access previously started for [reference].
  Future<void> stopAccessing(DeckFileReference reference) async {
    final bookmark = reference.bookmark;
    if (bookmark == null) return;
    await _channel.invokeMethod<void>('stopAccessing', bookmark);
  }

  /// Stops access to a directory activated by [startAccessingDirectory].
  Future<void> stopAccessingDirectory(
    SecurityScopedDirectoryReference reference,
  ) async {
    await _channel.invokeMethod<void>('stopAccessing', reference.bookmark);
  }
}
