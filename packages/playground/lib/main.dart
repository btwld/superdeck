import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:playground/memory_deck_loader.dart';
import 'package:playground/preview_sidebar.dart';
import 'package:playground/text_editor.dart';
import 'package:superdeck/superdeck.dart';

const _initialMarkdown = '''---
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

void main() {
  runApp(const PlaygroundApp());
}

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playground',
      builder: (context, child) => HeroTheme(data: .dark(), child: child!),
      debugShowCheckedModeBanner: false,
      home: const PlaygroundHome(),
    );
  }
}

class PlaygroundHome extends StatefulWidget {
  const PlaygroundHome({super.key});

  @override
  State<PlaygroundHome> createState() => _PlaygroundHomeState();
}

class _PlaygroundHomeState extends State<PlaygroundHome> {
  late final MemoryDeckLoader _loader;
  late final DeckController _controller;

  @override
  void initState() {
    super.initState();
    _loader = MemoryDeckLoader();
    _controller = DeckController(deckLoader: _loader, options: DeckOptions());

    _loader.updateMarkdown(_initialMarkdown);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMarkdownChanged(String markdown) {
    _loader.updateMarkdown(markdown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: Box(
        style: BoxStyler().color($background()),
        child: RowBox(
          children: [
            Expanded(
              child: TextEditor(
                initialText: _initialMarkdown,
                onChanged: _onMarkdownChanged,
              ),
            ),
            SlidesSidebar(controller: _controller),
          ],
        ),
      ),
    );
  }
}
