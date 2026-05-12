import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:playground/main.dart';
import 'package:provider/provider.dart';

import '../../utils/memory_deck_loader.dart';
import 'preview_sidebar.dart';
import 'text_editor.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loader = context.read<MemoryDeckLoader>();

    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: Box(
        style: BoxStyler().color($background()),
        child: RowBox(
          children: [
            Expanded(
              child: TextEditor(
                initialText: initialMarkdown,
                onChanged: (markdown) => loader.updateMarkdown(markdown),
              ),
            ),
            SlidesSidebar(
              onPlay: () => Navigator.of(context).pushNamed('/present'),
            ),
          ],
        ),
      ),
    );
  }
}
