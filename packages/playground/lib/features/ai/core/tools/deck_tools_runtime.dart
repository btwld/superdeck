import 'dart:async';
import 'dart:typed_data';

import 'package:superdeck/superdeck.dart';

import '../ai/schemas/deck_schemas.dart';

/// Provides the current live slide configurations for deck-edit tools.
typedef SlideConfigurationsProvider = List<SlideConfiguration> Function();

/// Captures the exact slide configuration passed by the tool service.
typedef SlideCaptureFn =
    Future<Uint8List> Function(SlideConfiguration configuration);

/// Applies an AI-selected deck style to the live preview.
typedef DeckStyleApplier = FutureOr<void> Function(DeckStyleType style);

/// Reports whether the route-scoped deck-edit runtime is still available.
typedef DeckToolAvailability = bool Function();

/// Route-scoped runtime dependencies required by [DeckToolsService].
final class DeckToolsRuntime {
  const DeckToolsRuntime({
    required this.slideConfigurationsProvider,
    required this.captureSlide,
    required this.applyStyle,
    required this.isAvailable,
  });

  final SlideConfigurationsProvider slideConfigurationsProvider;
  final SlideCaptureFn captureSlide;
  final DeckStyleApplier applyStyle;
  final DeckToolAvailability isAvailable;

  List<SlideConfiguration> snapshotSlideConfigurations() {
    return List<SlideConfiguration>.unmodifiable(slideConfigurationsProvider());
  }
}
