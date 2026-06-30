import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import 'features/ai/chat/view/chat_screen.dart';
import 'features/ai/deck_edit/deck_edit_screen.dart';
import 'features/editor/editor_page.dart';
import 'features/presentation/presentation_page.dart';
import 'stores/ai_store.dart';
import 'stores/deck_customization_store.dart';
import 'stores/editor_state.dart';
import 'utils/memory_asset_cache_store.dart';
import 'utils/memory_deck_loader.dart';
import 'utils/text_editor_controller.dart';
import 'utils/takeover_route.dart';

void main() {
  SignalsObserver.instance = null;
  runApp(const PlaygroundApp());
}

class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key});

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

class _PlaygroundAppState extends State<PlaygroundApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superdeck',
      builder: (context, child) {
        return _Theme(child: _Providers(child: child!));
      },
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/present':
            return TakeoverRoute<void>(
              settings: settings,
              builder: (_) => const PresentationPage(),
            );
          case '/ai/wizard':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ChatScreen(),
            );
          case '/ai/edit':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const DeckEditScreen(),
            );
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const EditorPage(),
            );
        }
      },
    );
  }
}

class _Providers extends StatelessWidget {
  const _Providers({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MemoryDeckLoader>(create: (_) => MemoryDeckLoader()),
        // Shared asset cache store — used by both DeckController and AiStore.
        Provider<MemoryAssetCacheStore>(create: (_) => MemoryAssetCacheStore()),
        Provider<DeckController>(
          create: (context) => DeckController(
            deckLoader: context.read<MemoryDeckLoader>(),
            options: .new(),
            assetCacheStore: context.read<MemoryAssetCacheStore>(),
          ),
          dispose: (_, controller) => controller.dispose(),
        ),
        Provider<DeckCustomizationStore>(
          create: (context) =>
              DeckCustomizationStore(context.read<DeckController>()),
          dispose: (_, store) => store.dispose(),
        ),
        Provider<EditorState>(
          create: (_) => EditorState(),
          dispose: (_, state) => state.dispose(),
        ),
        Provider<TextEditorController>(
          create: (_) => TextEditorController(),
          dispose: (_, c) => c.dispose(),
        ),
        Provider<AiStore>(
          create: (context) => AiStore(
            deckLoader: context.read<MemoryDeckLoader>(),
            assetCacheStore: context.read<MemoryAssetCacheStore>(),
            customizationStore: context.read<DeckCustomizationStore>(),
            textEditorController: context.read<TextEditorController>(),
          ),
          dispose: (_, store) => store.dispose(),
        ),
      ],
      child: child,
    );
  }
}

class _Theme extends StatelessWidget {
  const _Theme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroTheme(
      data: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? .dark()
          : .light(),
      child: child,
    );
  }
}
