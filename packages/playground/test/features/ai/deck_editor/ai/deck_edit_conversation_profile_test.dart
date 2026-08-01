import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_edit_catalog.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_edit_conversation_profile.dart';
import 'package:playground/features/ai/deck_editor/ai/deck_tools_adapter.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_store.dart';
import 'package:playground/features/ai/deck_editor/domain/deck_tools_service.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  final adapter = DeckToolsAdapter(
    DeckToolsService(deckStore: _EmptyDeckStore()),
  );

  test('deck-edit catalog contains only safe input components', () {
    expect(deckEditCatalog.catalogId, 'com.superdeck.ai.deck_edit');
    expect(deckEditCatalog.items.map((item) => item.name), [
      'AskUserRadio',
      'AskUserCheckbox',
      'AskUserSlider',
      'AskUserText',
      'AskUserStyle',
    ]);
    expect(
      deckEditCatalog.items.map((item) => item.name),
      isNot(contains('SummaryCard')),
    );
  });

  test('deck-edit profile uses its prompt, catalog, and seven tools', () {
    final profile = deckEditConversationProfile(adapter);

    expect(profile.catalog, same(deckEditCatalog));
    expect(profile.promptName, 'deck_edit_system');
    expect(
      profile.tools.map((tool) => tool.name),
      adapter.tools.map((e) => e.name),
    );
    expect(profile.tools, hasLength(7));
  });
}

class _EmptyDeckStore implements DeckStore {
  @override
  List<Slide> read() => const [];

  @override
  Future<List<Slide>> restore(String markdown) async => const [];

  @override
  Future<List<Slide>> synchronize() async => const [];

  @override
  Future<List<Slide>> write(List<Slide> slides) async => slides;
}
