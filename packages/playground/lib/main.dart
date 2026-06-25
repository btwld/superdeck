import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/stores/ai_store.dart';
import 'package:playground/stores/deck_customization_store.dart';
import 'package:playground/stores/editor_state.dart';
import 'package:playground/utils/memory_asset_cache_store.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:playground/utils/text_editor_controller.dart';
import 'package:playground/features/presentation/presentation_page.dart';
import 'package:playground/utils/takeover_route.dart';
import 'package:playground/features/editor/editor_page.dart';
import 'package:playground/features/ai/chat/view/chat_screen.dart';
import 'package:playground/features/ai/remix/view/remix_screen.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

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
          case '/ai/remix':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const RemixScreen(),
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

class _Providers extends StatefulWidget {
  const _Providers({required this.child});

  final Widget child;
  @override
  State<_Providers> createState() => _ProvidersState();
}

class _ProvidersState extends State<_Providers> {
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
      child: widget.child,
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
