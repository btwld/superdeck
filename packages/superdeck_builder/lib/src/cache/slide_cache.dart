import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:superdeck_builder/src/parsers/markdown_parser.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Cache for processed slide data
class SlideCache {
  final Directory _cacheDir;

  SlideCache(String cacheDirPath) : _cacheDir = Directory(cacheDirPath);

  /// Initialize the cache directory
  Future<void> initialize() async {
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
  }

  /// Compute a hash for the slide content
  String _computeHash(RawSlideMarkdown slide) {
    final content = slide.content + slide.frontmatter.toString();
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  /// Get the cache file for a slide
  File _getCacheFile(String slideKey, String hash) {
    return File('${_cacheDir.path}/${slideKey}_$hash.json');
  }

  /// Check if a valid cache exists for the slide
  Future<bool> hasValidCache(RawSlideMarkdown slide) async {
    final hash = _computeHash(slide);
    final cacheFile = _getCacheFile(slide.key, hash);
    return await cacheFile.exists();
  }

  /// Save processed slide to cache
  Future<void> cacheSlide(
      RawSlideMarkdown rawSlide, Slide processedSlide) async {
    final hash = _computeHash(rawSlide);
    final cacheFile = _getCacheFile(rawSlide.key, hash);

    // Use the mappable mixin to convert to JSON
    final json = processedSlide.toJson();
    await cacheFile.writeAsString(json);
  }

  /// Get a cached slide if available
  Future<Slide?> getCachedSlide(RawSlideMarkdown slide) async {
    if (!await hasValidCache(slide)) {
      return null;
    }

    final hash = _computeHash(slide);
    final cacheFile = _getCacheFile(slide.key, hash);

    try {
      final content = await cacheFile.readAsString();
      return Slide.parse(jsonDecode(content) as Map<String, dynamic>);
    } catch (e) {
      // If there's an error reading or parsing the cache, return null
      return null;
    }
  }

  /// Clear all cached slides
  Future<void> clearCache() async {
    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          await entity.delete();
        }
      }
    }
  }
}
