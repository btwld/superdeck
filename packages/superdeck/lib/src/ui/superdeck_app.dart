import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart' show Deck;

import '../presentation/deck_extension.dart';
import '../presentation/deck_theme.dart';
import '../runtime/deck_controller.dart';
import '../ui/widgets/provider.dart';
import 'app_shell.dart';
import 'theme.dart';
import 'tokens/colors.dart';

class SuperDeckApp extends StatefulWidget {
  const SuperDeckApp({
    super.key,
    required this.deck,
    this.theme = const DeckTheme(),
    this.extensions = const <DeckExtension>[],
  });

  final Deck deck;
  final DeckTheme theme;
  final List<DeckExtension> extensions;

  @override
  State<SuperDeckApp> createState() => _SuperDeckAppState();
}

class _SuperDeckAppState extends State<SuperDeckApp> {
  late DeckController _deckController;

  @override
  void initState() {
    super.initState();
    _deckController = _createController(widget.deck);
  }

  @override
  void didUpdateWidget(covariant SuperDeckApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    final configChanged =
        widget.deck.configuration != oldWidget.deck.configuration;

    if (configChanged) {
      _deckController.dispose();
      _deckController = _createController(widget.deck);
    } else if (widget.deck != oldWidget.deck) {
      _deckController.updateDeck(widget.deck);
    }

    if (widget.theme != oldWidget.theme) {
      _deckController.updateTheme(widget.theme);
    }
  }

  DeckController _createController(Deck deck) {
    return DeckController(
      deck: deck,
      theme: widget.theme,
      extensions: widget.extensions,
    );
  }

  @override
  void dispose() {
    _deckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _deckController;

    return InheritedData<DeckController>(
      data: controller,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Superdeck',
        routerConfig: controller.router,
        builder: (context, child) {
          return MixScope(
            colors: SDColors.colorMap,
            child: AppShell(child: child!),
          );
        },
        theme: theme,
      ),
    );
  }
}
