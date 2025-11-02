import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:signals/signals.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'deck_options.dart';
import 'deck_provider.dart';
import 'slide_configuration.dart';
import 'slide_configuration_builder.dart';

/// Loading state for the deck
enum DeckLoadingState { idle, loading, loaded, error }

/// Controller for deck data and state management
///
/// Handles loading deck data, managing options, building slide configurations,
/// and UI state (menu, notes, rebuilding). Uses Signals for reactive state
/// management. Navigation is handled separately by NavigationController.
class DeckController {
  // Data layer
  final DeckService _deckService;
  final SlideConfigurationBuilder _slideBuilder;

  // Stream subscription
  StreamSubscription<Deck>? _deckSubscription;

  // Deck state signals (private)
  final _loadingState = signal<DeckLoadingState>(DeckLoadingState.idle);
  final _currentDeck = signal<Deck?>(null);
  final _error = signal<Object?>(null);
  final _options = signal<DeckOptions>(DeckOptions());

  // UI state signals (private)
  final _isMenuOpen = signal<bool>(false);
  final _isNotesOpen = signal<bool>(false);
  final _isRebuilding = signal<bool>(false);

  // Public readonly getters for signals
  ReadonlySignal<DeckLoadingState> get loadingState => _loadingState;
  ReadonlySignal<Object?> get error => _error;
  ReadonlySignal<DeckOptions> get options => _options;
  ReadonlySignal<bool> get isMenuOpen => _isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _isNotesOpen;
  ReadonlySignal<bool> get isRebuilding => _isRebuilding;

  // Computed signals
  late final ReadonlySignal<List<SlideConfiguration>> slides = computed(() {
    final deck = _currentDeck.value;
    if (deck == null) return <SlideConfiguration>[];
    return _slideBuilder.buildConfigurations(deck.slides, _options.value);
  });

  late final ReadonlySignal<int> totalSlides = computed(() => slides.value.length);

  late final ReadonlySignal<bool> isLoading = computed(
    () => _loadingState.value == DeckLoadingState.loading,
  );

  late final ReadonlySignal<bool> hasError = computed(
    () => _loadingState.value == DeckLoadingState.error,
  );

  // Service getter (for error retry)
  DeckService get repository => _deckService;

  DeckController({
    required DeckService deckService,
    required DeckOptions options,
  })  : _deckService = deckService,
        _slideBuilder = SlideConfigurationBuilder(
          configuration: deckService.configuration,
        ) {
    _options.value = options;
    _startDeckStream();
  }

  // Stream handling
  void _startDeckStream() {
    _loadingState.value = DeckLoadingState.loading;

    _deckSubscription = _deckService.loadDeckStream().listen(
      (deck) {
        _currentDeck.value = deck;
        _loadingState.value = DeckLoadingState.loaded;
        _error.value = null;
      },
      onError: (error) {
        _error.value = error;
        _loadingState.value = DeckLoadingState.error;
      },
    );
  }

  // UI state methods - Menu
  void openMenu() {
    _isMenuOpen.value = true;
  }

  void closeMenu() {
    _isMenuOpen.value = false;
  }

  // UI state methods - Notes
  void toggleNotes() {
    _isNotesOpen.value = !_isNotesOpen.value;
  }

  // UI state methods - Options
  void updateOptions(DeckOptions newOptions) {
    if (_options.value != newOptions) {
      _options.value = newOptions;
    }
  }

  void setRebuilding(bool value) {
    _isRebuilding.value = value;
  }

  // Static accessor
  static DeckController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<DeckProvider>();
    if (provider == null) {
      throw FlutterError('DeckProvider not found in widget tree');
    }
    return provider.controller;
  }

  void dispose() {
    _deckSubscription?.cancel();

    // Dispose all signals
    _loadingState.dispose();
    _currentDeck.dispose();
    _error.dispose();
    _options.dispose();
    _isMenuOpen.dispose();
    _isNotesOpen.dispose();
    _isRebuilding.dispose();

    // Dispose computed signals
    slides.dispose();
    totalSlides.dispose();
    isLoading.dispose();
    hasError.dispose();
  }
}
