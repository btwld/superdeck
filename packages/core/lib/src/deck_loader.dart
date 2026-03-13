import 'package:meta/meta.dart';

import 'deck_configuration.dart';
import 'models/deck_model.dart';

sealed class DeckEvent {}

class DeckLoadingEvent extends DeckEvent {
  final String message;

  DeckLoadingEvent(this.message);
}

class DeckLoadedEvent extends DeckEvent {
  final Deck deck;

  DeckLoadedEvent(this.deck);
}

class DeckErrorEvent extends DeckEvent {
  final String message;
  final Object? error;

  DeckErrorEvent(this.message, {this.error});
}

class DeckRebuildingEvent extends DeckEvent {
  DeckRebuildingEvent();
}

abstract class DeckLoader {
  @protected
  final DeckConfiguration configuration;
  const DeckLoader({required this.configuration});

  Stream<DeckEvent> load();
  Future<void> reload();

  Future<void> dispose();
}
