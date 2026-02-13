import 'dart:typed_data';

/// Platform-aware thumbnail persistence interface.
///
/// Implementations persist thumbnail bytes in a platform-appropriate cache:
/// - IO platforms: filesystem-backed cache in the application directory.
/// - Web: browser-backed persistent storage.
abstract interface class ThumbnailCacheStore {
  /// Returns the cached thumbnail URI for [slideKey], or null if not found.
  Future<Uri?> resolve({required String slideKey, String? filePath});

  /// Persists [bytes] for [slideKey] and returns the resulting URI.
  Future<Uri?> write({
    required String slideKey,
    String? filePath,
    required Uint8List bytes,
  });

  /// Removes cached thumbnail for [slideKey], if present.
  Future<void> delete({required String slideKey, String? filePath});
}
