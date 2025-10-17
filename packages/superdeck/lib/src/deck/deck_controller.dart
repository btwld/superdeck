import 'dart:async';

import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'deck_options.dart';
import 'deck_provider.dart';
import 'slide_configuration_builder.dart';
import 'slide_configuration.dart';

/// Loading state for the deck
enum DeckLoadingState { idle, loading, loaded, error }

/// Controller for deck data and state management
///
/// Handles loading deck data, managing options, building slide configurations,
/// and UI state (menu, notes, rebuilding). Navigation is handled separately
/// by NavigationController.
class DeckController extends ChangeNotifier {
  // Data layer
  final DeckRepository _repository;
  final SlideConfigurationBuilder _slideBuilder;

  // Stream subscription
  StreamSubscription<Deck>? _deckSubscription;

  // Deck state
  DeckLoadingState _loadingState = DeckLoadingState.idle;
  Deck? _currentDeck;
  Object? _error;

  // UI state
  DeckOptions _options;
  bool _isMenuOpen = false;
  bool _isNotesOpen = false;
  bool _isRebuilding = false;

  // Public getters
  DeckLoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == DeckLoadingState.loading;
  bool get hasError => _loadingState == DeckLoadingState.error;
  Object? get error => _error;
  DeckOptions get options => _options;
  bool get isMenuOpen => _isMenuOpen;
  bool get isNotesOpen => _isNotesOpen;
  bool get isRebuilding => _isRebuilding;
  DeckRepository get repository => _repository;

  // Computed properties
  List<SlideConfiguration> get slides {
    if (_currentDeck == null) return [];
    return _slideBuilder.buildConfigurations(_currentDeck!.slides, _options);
  }

  int get totalSlides => slides.length;

  DeckController({
    required DeckRepository repository,
    required DeckOptions options,
  }) : _repository = repository,
       _options = options,
       _slideBuilder = SlideConfigurationBuilder(
         configuration: repository.configuration,
       ) {
    _startDeckStream();
  }

  // Stream handling
  void _startDeckStream() {
    _loadingState = DeckLoadingState.loading;
    notifyListeners();

    _deckSubscription = _repository.loadDeckStream().listen(
      (deck) {
        _currentDeck = deck;
        _loadingState = DeckLoadingState.loaded;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error;
        _loadingState = DeckLoadingState.error;
        notifyListeners();
      },
    );
  }

  // UI state methods - Menu
  void openMenu() {
    if (!_isMenuOpen) {
      _isMenuOpen = true;
      notifyListeners();
    }
  }

  void closeMenu() {
    if (_isMenuOpen) {
      _isMenuOpen = false;
      notifyListeners();
    }
  }

  // UI state methods - Notes
  void toggleNotes() {
    _isNotesOpen = !_isNotesOpen;
    notifyListeners();
  }

  // UI state methods - Options
  void updateOptions(DeckOptions newOptions) {
    if (_options != newOptions) {
      _options = newOptions;
      notifyListeners();
    }
  }

  void setRebuilding(bool value) {
    if (_isRebuilding != value) {
      _isRebuilding = value;
      notifyListeners();
    }
  }

  // Static accessor
  static DeckController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<DeckProvider>();
    if (provider == null) {
      throw FlutterError('DeckProvider not found in widget tree');
    }
    return provider.controller;
  }

  @override
  void dispose() {
    _deckSubscription?.cancel();
    super.dispose();
  }
}
