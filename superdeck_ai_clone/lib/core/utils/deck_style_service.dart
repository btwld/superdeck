import 'dart:convert';
import 'dart:io';

import 'package:signals/signals_flutter.dart';
import 'package:superdeck_ai/core/ai/schemas/deck_schemas.dart';
import 'package:superdeck_ai/core/constants/paths.dart';
import 'package:superdeck_ai/core/debug_logger.dart';

/// Service for reading style configuration from superdeck.json.
///
/// Provides both async and sync access to the persisted style.
/// Call [preloadStyle] at app startup to populate the cache,
/// then [readStyleFromCache] can be used synchronously in routing.
class DeckStyleService {
  static final _styleSignal = signal<DeckStyleType?>(null);
  static bool _preloaded = false;

  static ReadonlySignal<DeckStyleType?> get style => _styleSignal;

  /// Preloads style from .superdeck/superdeck.json asynchronously.
  ///
  /// Call this at app startup to populate the cache before routing.
  /// This is non-blocking and won't affect UI thread.
  static Future<void> preloadStyle() async {
    if (_preloaded) return;

    try {
      final file = File(Paths.deckJsonPath);
      if (!await file.exists()) {
        // File doesn't exist - expected case, mark preloaded
        _preloaded = true;
        return;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      _styleSignal.value = DeckStyleType.safeParse(data['style']).getOrNull();
      _preloaded = true;
    } on FormatException catch (e) {
      // Invalid JSON - permanent error, mark preloaded
      debugLog.log('STYLE', 'Invalid JSON in deck file: $e');
      _styleSignal.value = null;
      _preloaded = true;
    } catch (e) {
      // I/O or other transient error - allow retry
      debugLog.log('STYLE', 'Could not preload style (will retry): $e');
      // Don't set _preloaded = true, allowing retry on next call
    }
  }

  /// Reads style from the in-memory cache.
  ///
  /// Returns null if cache is empty or style was not present.
  /// Call [preloadStyle] at app startup to populate the cache.
  static DeckStyleType? readStyleFromCache() {
    return _styleSignal.value;
  }

  /// Updates style and notifies listeners.
  static void setStyle(DeckStyleType? style) {
    _styleSignal.value = style;
    _preloaded = true;
  }

  /// Parses [rawStyle] and updates cache only if valid.
  ///
  /// Returns parsed style when valid, null when [rawStyle] is null or invalid.
  static DeckStyleType? setStyleFromJson(Object? rawStyle) {
    if (rawStyle == null) {
      setStyle(null);
      return null;
    }

    final parsed = DeckStyleType.safeParse(rawStyle).getOrNull();
    if (parsed == null) {
      return null;
    }

    setStyle(parsed);
    return parsed;
  }

  /// Updates the cached style.
  ///
  /// Call this after generation to update the in-memory cache
  /// without requiring a disk read.
  static void updateCache(DeckStyleType? style) {
    setStyle(style);
  }

  /// Clears the cached style.
  ///
  /// Call this after generating a new presentation to ensure
  /// fresh style is read on next access.
  static void clearCache() {
    _styleSignal.value = null;
    _preloaded = false;
  }
}
