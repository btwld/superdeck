import 'package:signals/signals_flutter.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/debug_logger.dart';

/// In-memory style state service.
///
/// Provides a reactive [Signal] for the current deck style.
/// No disk I/O — fully web-safe. [preloadStyle] is a no-op.
class DeckStyleService {
  static final _styleSignal = signal<DeckStyleType?>(null);
  static ReadonlySignal<DeckStyleType?> get style => _styleSignal;

  /// No-op. Kept for call-site compatibility.
  ///
  /// Style is now set directly via [setStyle] or [setStyleFromJson] after
  /// generation, rather than being read from disk.
  static Future<void> preloadStyle() async {
    // No-op: style is set directly via setStyle after generation.
  }

  /// Reads style from the in-memory cache.
  ///
  /// Returns null if no style has been set.
  static DeckStyleType? readStyleFromCache() {
    return _styleSignal.value;
  }

  /// Updates style and notifies listeners.
  static void setStyle(DeckStyleType? style) {
    _styleSignal.value = style;
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
      debugLog.log('STYLE', 'Could not parse style from JSON: $rawStyle');
      return null;
    }

    setStyle(parsed);
    return parsed;
  }

  /// Updates the cached style.
  static void updateCache(DeckStyleType? style) {
    setStyle(style);
  }

  /// Clears the cached style.
  static void clearCache() {
    _styleSignal.value = null;
  }
}
