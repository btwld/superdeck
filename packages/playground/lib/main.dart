import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:playground/preview_sidebar.dart';
import 'package:playground/text_editor.dart';

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

class PlaygroundHome extends StatelessWidget {
  const PlaygroundHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: Box(
        style: BoxStyler().color($background()),
        child: RowBox(
          children: [
            Expanded(child: TextEditor()),
            SlidesSidebar(),
          ],
        ),
      ),
    );
  }
}
