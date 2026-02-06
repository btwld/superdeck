import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Asset-based [DeckService] implementation for runtimes without file processes.
///
/// The standard [DeckService] relies on local file I/O and file watchers.
/// In web and release-like runtimes, deck data is read from bundled assets.
class BundledDeckService extends DeckService {
  BundledDeckService({
    required super.configuration,
    this.deckAssetPath = '.superdeck/superdeck.json',
  });

  final String deckAssetPath;
  final Logger _logger = Logger('BundledDeckService');

  @override
  Future<void> initialize() async {
    // No-op: bundled assets are generated ahead of time by the CLI.
  }

  @override
  Future<Deck> loadDeck() async {
    try {
      final content = await rootBundle.loadString(deckAssetPath);
      final data = jsonDecode(content) as Map<String, dynamic>;
      return Deck.fromMap(data);
    } on Object catch (error) {
      return Deck(
        slides: [
          Slide.error(
            title: 'Superdeck reference error',
            message: deckAssetPath,
            error: error is Exception ? error : Exception(error.toString()),
          ),
        ],
        configuration: configuration,
      );
    }
  }

  @override
  Stream<Deck> loadDeckStream() async* {
    _logger.info('Loading bundled deck from assets...');
    yield await loadDeck();
  }
}
