import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../presentation/deck_extension.dart';
import '../presentation/deck_theme.dart';
import '../runtime/deck_controller.dart';
import '../runtime/superdeck_provider.dart';
import '../ui/widgets/provider.dart';
import 'app_shell.dart';
import 'theme.dart';
import 'tokens/colors.dart';

class SuperDeckApp extends StatefulWidget {
  const SuperDeckApp({
    super.key,
    this.theme = const DeckTheme(),
    this.extensions = const <DeckExtension>[],
  });

  final DeckTheme theme;
  final List<DeckExtension> extensions;

  @override
  State<SuperDeckApp> createState() => _SuperDeckAppState();
}

class _SuperDeckAppState extends State<SuperDeckApp> {
  DeckController? _deckController;
  DeckDataState? _dataState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final dataState = SuperDeckProvider.of(context);
    if (_dataState != dataState) {
      _deckController?.dispose();
      _dataState = dataState;
      _deckController = DeckController(
        dataState: dataState,
        theme: widget.theme,
        extensions: widget.extensions,
      );
    }
  }

  @override
  void didUpdateWidget(covariant SuperDeckApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != oldWidget.theme) {
      _deckController?.updateTheme(widget.theme);
    }
  }

  @override
  void dispose() {
    _deckController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _deckController!;

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
