import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/core/data/data_sources/deck_library_asset_store.dart';
import 'package:playground/core/data/data_sources/memory_asset_cache_store.dart';
import 'package:playground/core/data/data_sources/memory_deck_loader.dart';
import 'package:playground/core/domain/stores/deck_customization_store.dart';
import 'package:playground/core/domain/stores/deck_document_store.dart';
import 'package:playground/features/library/domain/deck_library_controller.dart';
import 'package:playground/features/library/presentation/saved_decks_page.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

import '../../../helpers/fake_deck_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<({DeckLibraryController controller, DeckDocumentStore document})>
  pumpPage(WidgetTester tester, FakeDeckLibrary library) async {
    final memory = MemoryAssetCacheStore();
    final assets = DeckLibraryAssetStore(library: library, fallback: memory);
    final document = DeckDocumentStore(markdown: '');
    final loader = MemoryDeckLoader();
    final deckController = DeckController(
      deckLoader: loader,
      options: DeckOptions(),
      assetCacheStore: assets,
    );
    final customization = DeckCustomizationStore(
      deckController,
      background: Colors.black,
      foreground: Colors.white,
    );
    final controller = DeckLibraryController(
      library: library,
      documentStore: document,
      deckLoader: loader,
      customizationStore: customization,
      assetStore: assets,
    );
    addTearDown(() {
      controller.dispose();
      customization.dispose();
      deckController.dispose();
      loader.dispose();
      document.dispose();
    });

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/decks',
              builder: (context, state) => const SavedDecksPage(),
            ),
            GoRoute(
              path: '/present/:index',
              builder: (context, state) => const Text('presenting'),
            ),
          ],
          initialLocation: '/decks',
        ),
        builder: (context, child) => HeroTheme(
          data: HeroThemeData.dark(),
          child: ChangeNotifierProvider.value(value: controller, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (controller: controller, document: document);
  }

  testWidgets('offers nothing to present before a deck is saved', (
    tester,
  ) async {
    await pumpPage(tester, FakeDeckLibrary());

    expect(find.textContaining('No decks yet'), findsOneWidget);
    expect(find.text('Present'), findsNothing);
  });

  testWidgets('lists saved decks and presents the one chosen', (tester) async {
    final library = FakeDeckLibrary();
    await library.save(name: 'Quarterly review', markdown: '# Q3\n');
    final scope = await pumpPage(tester, library);

    expect(find.text('Quarterly review'), findsOneWidget);
    expect(find.textContaining(RegExp(r'Saved \d{4}-')), findsOneWidget);

    await tester.tap(find.text('Present'));
    await tester.pumpAndSettle();

    expect(find.text('presenting'), findsOneWidget);
    expect(scope.document.markdown, '# Q3\n');
  });

  testWidgets('a library it cannot read says so instead of looking empty', (
    tester,
  ) async {
    final library = FakeDeckLibrary()..listError = Exception('no folder');

    await pumpPage(tester, library);

    expect(find.textContaining('no folder'), findsOneWidget);
  });
}
