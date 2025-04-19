import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart' as core;

import '../common/helpers/provider.dart';
import '../models/deck_reference.dart';

/// Provider for deck data
class DeckProvider with ProviderMixin, ChangeNotifier {
  final core.PresentationRepository _repository;
  DeckReference? _deckReference;

  DeckProvider(core.PresentationConfig configuration)
      : _repository = core.LocalPresentationRepository(configuration);

  /// Initialize the provider
  @override
  Future<void> initialize() async {
    await _repository.initialize();
    await _loadDeck();
  }

  /// Load the deck from the repository
  Future<void> _loadDeck() async {
    try {
      final presentation = await _repository.loadDeckReference();
      _deckReference = DeckReference.fromCore(presentation);
      notifyListeners();
    } catch (e) {
      // Handle error
      debugPrint('Error loading deck: $e');
    }
  }

  /// Get the current deck reference
  DeckReference? get deckReference => _deckReference;
}
