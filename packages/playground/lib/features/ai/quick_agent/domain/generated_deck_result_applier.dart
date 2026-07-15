import 'package:superdeck_builder/superdeck_builder.dart';

import '../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../core/engine/services/deck_generator_service.dart';
import 'generated_deck_style_mapper.dart';

/// Loads one accepted generation result into the shared document and renderer.
void applyGeneratedDeckResult({
  required DeckGenerationResult result,
  required DeckDocumentStore documentStore,
  MemoryDeckLoader? deckLoader,
  required DeckCustomizationStore customizationStore,
}) {
  final markdown = const SlideSerializer().serialize(result.slides);
  documentStore.replaceMarkdown(markdown);
  deckLoader?.updateMarkdown(markdown);
  if (result.theme case final theme?) {
    customizationStore.applyGeneratedStyle(theme.toGeneratedDeckStyle());
  }
}
