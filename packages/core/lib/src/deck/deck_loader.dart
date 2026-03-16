import 'package:meta/meta.dart';

import 'deck_configuration.dart';
import 'slide_model.dart';

sealed class SlidesEvent {}

class SlidesLoadingEvent extends SlidesEvent {
  final String message;

  SlidesLoadingEvent(this.message);
}

class SlidesLoadedEvent extends SlidesEvent {
  final List<Slide> slides;

  SlidesLoadedEvent(this.slides);
}

class SlidesErrorEvent extends SlidesEvent {
  final String message;
  final Object? error;

  SlidesErrorEvent(this.message, {this.error});
}

class SlidesRebuildingEvent extends SlidesEvent {
  SlidesRebuildingEvent();
}

abstract class DeckLoader {
  @protected
  final DeckConfiguration configuration;
  const DeckLoader({required this.configuration});

  Stream<SlidesEvent> load();
  Future<void> reload();

  Future<void> dispose();
}
