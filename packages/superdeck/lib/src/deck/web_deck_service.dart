import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Web implementation of [DeckService] that reads deck JSON from Flutter assets.
///
/// The standard [DeckService] relies on dart:io file APIs which are unavailable
/// in web runtimes.
class WebDeckService extends DeckService {
  WebDeckService({
    required super.configuration,
    this.deckAssetPath = '.superdeck/superdeck.json',
  });

  final String deckAssetPath;
  final Logger _logger = Logger('WebDeckService');

  @override
  Future<void> initialize() async {
    // No-op on web: bundled assets are generated ahead of time by the CLI.
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
    _logger.info('Loading bundled deck on web...');
    yield await loadDeck();
  }
}
