import 'package:signals/signals_flutter.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/debug_logger.dart';

/// In-memory style state service.
///
/// Provides a reactive [Signal] for the current deck style.
/// No disk I/O — fully web-safe.
class DeckStyleService {
  static final _styleSignal = signal<DeckStyleType?>(null);
  static ReadonlySignal<DeckStyleType?> get style => _styleSignal;

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

  /// Clears the cached style.
  static void clearCache() {
    _styleSignal.value = null;
  }
}
