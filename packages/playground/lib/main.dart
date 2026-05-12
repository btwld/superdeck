import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:playground/features/presentation/presentation_page.dart';
import 'package:playground/utils/takeover_route.dart';
import 'package:playground/features/editor/editor_page.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  runApp(const PlaygroundApp());
}

const initialMarkdown = '''---
title: Welcome

# Hello SuperDeck

This is a live preview playground.

---

## Second Slide

- Edit on the left
- Preview on the right

---
title: Welcome

# Hello SuperDeck

This is a live preview playground.

---

## Second Slide

- Edit on the left
- Preview on the right
''';

class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key});

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

class _PlaygroundAppState extends State<PlaygroundApp> {
  late final MemoryDeckLoader _loader;
  late final DeckController _controller;

  @override
  void initState() {
    super.initState();
    _loader = MemoryDeckLoader();
    _controller = DeckController(deckLoader: _loader, options: DeckOptions());
    _loader.updateMarkdown(initialMarkdown);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DeckController>.value(value: _controller),
        Provider<MemoryDeckLoader>.value(value: _loader),
      ],
      child: MaterialApp(
        title: 'Playground',
        builder: (context, child) {
          final isDark =
              MediaQuery.of(context).platformBrightness == Brightness.dark;
          return HeroTheme(
            data: isDark ? HeroThemeData.dark() : HeroThemeData.light(),
            child: child!,
          );
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
            default:
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const EditorPage(),
              );
          }
        },
      ),
    );
  }
}
