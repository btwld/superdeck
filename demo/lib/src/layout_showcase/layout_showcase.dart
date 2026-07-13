import 'package:flutter/widgets.dart';
import 'package:superdeck/superdeck.dart';

import 'showcase_parts.dart';
import 'showcase_style.dart';
import 'showcase_widgets.dart';
import 'showcase_workspace.dart';

export 'showcase_workspace.dart';

DeckOptions layoutShowcaseOptions() {
  return DeckOptions(
    baseStyle: showcaseBaseStyle(),
    styles: {
      'cover': showcaseCoverStyle(),
      'compact': showcaseCompactStyle(),
      'panels': showcasePanelStyle(),
      'closing': showcaseClosingStyle(),
    },
    widgets: showcaseWidgets,
    parts: const SlideParts(
      header: null,
      background: ShowcaseBackground(),
      footer: ShowcaseFooter(),
    ),
  );
}

class LayoutShowcaseApp extends StatelessWidget {
  const LayoutShowcaseApp({
    super.key,
    this.deckLoader,
    this.transitionDuration = const Duration(milliseconds: 650),
  });

  final DeckLoader? deckLoader;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    return SuperDeckApp(
      options: layoutShowcaseOptions(),
      workspace: layoutShowcaseWorkspace,
      deckLoader: deckLoader,
      transitionDuration: transitionDuration,
    );
  }
}
