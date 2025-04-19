import 'package:superdeck_core/superdeck_core.dart' as core;

import 'slide_model.dart';

/// Reference to a presentation deck
class DeckReference {
  final String id;
  final String title;
  final String description;
  final List<Slide> slides;

  const DeckReference({
    required this.id,
    required this.title,
    required this.description,
    required this.slides,
  });

  /// Create from core Presentation
  factory DeckReference.fromCore(core.Presentation presentation) {
    return DeckReference(
      id: 'deck', // Default ID
      title: 'Untitled Deck', // Default title
      description: '', // Default description
      slides: presentation.slides.map((s) => Slide.fromCore(s)).toList(),
    );
  }

  /// Convert to a core Presentation
  core.Presentation toCore(core.PresentationConfig config) {
    return core.Presentation(
      slides: slides.map((s) => s.toCore()).toList(),
      configuration: config,
    );
  }
}
