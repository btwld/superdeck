import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Generates a short, human-readable hash for use as identifiers (e.g., slide keys).
///
/// This function uses a fast custom hashing algorithm to transform the input string
/// into a unique, 8-character alphanumeric identifier. It is optimized for creating
/// compact, human-readable keys that can be used in URLs, file names, or as unique
/// identifiers.
///
/// **Use this for:**
/// - Slide keys and presentation identifiers
/// - Short, human-readable IDs
/// - URL-safe identifiers
///
/// **Don't use this for:**
/// - Cryptographic purposes or security
/// - Cache keys (use [generateContentHash] instead)
/// - Data integrity verification
///
/// Note: This is needed as Dart's built-in `hashCode` for strings is not guaranteed
/// to be consistent across different platforms or Dart versions.
///
/// [valueToHash] is the string input that you want to convert into a hash ID.
///
/// Returns an 8-character alphanumeric string that represents the hashed ID.
///
/// Example:
/// ```dart
/// final slideKey = generateValueHash('# My Slide Title');
/// // Returns something like: 'aB3dE9fG'
/// ```
String generateValueHash(String valueToHash) {
  const characters =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  int hash = 0;

  for (int i = 0; i < valueToHash.length; i++) {
    int charCode = valueToHash.codeUnitAt(i);
    hash = (hash * 31 + charCode) % 2147483647;
  }

  String shortId = '';
  int base = characters.length;
  int remainingHash = hash;

  for (int i = 0; i < 8; i++) {
    shortId += characters[remainingHash % base];
    remainingHash = (remainingHash * 31 + hash + i) % 2147483647;
  }

  return shortId;
}

/// Generates a cryptographic SHA-256 hash for secure cache keys and content verification.
///
/// This function uses the SHA-256 cryptographic hash algorithm to create a secure,
/// unique hash of the input content. It is suitable for cache keys, content
/// verification, and detecting changes in data.
///
/// **Use this for:**
/// - Cache keys (MarkdownCache, SlideCache)
/// - Content verification and change detection
/// - Secure, collision-resistant hashing
///
/// **Don't use this for:**
/// - Human-readable identifiers (use [generateValueHash] instead)
/// - Short IDs or keys
/// - Performance-critical tight loops (SHA-256 is slower than simple hashing)
///
/// [content] is the string content to hash
/// [truncateLength] optionally truncates the hash to specified length (e.g. 16 chars).
/// Use with caution as truncation reduces collision resistance.
///
/// Returns the hex string representation of the SHA-256 hash (64 characters if not truncated).
///
/// Example:
/// ```dart
/// final cacheKey = generateContentHash('slide content here');
/// // Returns something like: 'a7b3c8d9e2f1a4b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0'
///
/// final shortCacheKey = generateContentHash('slide content', truncateLength: 16);
/// // Returns something like: 'a7b3c8d9e2f1a4b6'
/// ```
String generateContentHash(String content, {int? truncateLength}) {
  final bytes = utf8.encode(content);
  final hash = sha256.convert(bytes).toString();
  return truncateLength != null ? hash.substring(0, truncateLength) : hash;
}
