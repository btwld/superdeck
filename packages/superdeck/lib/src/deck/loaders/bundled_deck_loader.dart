import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Asset-based [DeckLoader] implementation for runtimes without file processes.
///
/// [load] returns a short stream that emits [DeckLoadingEvent] followed by
/// [DeckLoadedEvent] (on success) or [DeckErrorEvent] (on failure),
/// then closes. No build-status watching in bundled mode.
class BundledDeckLoader extends DeckLoader {
  BundledDeckLoader({required super.configuration});

  @override
  Stream<DeckEvent> load() async* {
    yield DeckLoadingEvent('Loading bundled deck…');
    try {
      final content = await rootBundle.loadString(
        configuration.bundledDeckJsonPath,
      );
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        throw Exception(
          'Expected JSON object in bundled deck at '
          '${configuration.bundledDeckJsonPath}, got ${decoded.runtimeType}',
        );
      }
      final data = Map<String, Object?>.from(decoded);
      yield DeckLoadedEvent(Deck.parse(data));
    } on Exception catch (error) {
      yield DeckErrorEvent('Superdeck reference error', error: error);
    } on Error catch (error) {
      // rootBundle.loadString throws FlutterError (an Error, not Exception)
      yield DeckErrorEvent(
        'Superdeck reference error',
        error: Exception(error.toString()),
      );
    }
  }

  @override
  Future<void> dispose() => Future<void>.value();
}
