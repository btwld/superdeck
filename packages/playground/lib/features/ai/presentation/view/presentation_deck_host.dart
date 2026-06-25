import 'package:flutter/widgets.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:playground/features/ai/core/superdeck_workspace.dart';
import 'package:playground/features/ai/core/utils/deck_style_service.dart';
import 'package:playground/features/ai/core/utils/style_builder.dart';

typedef DeckAppBuilder = Widget Function(DeckOptions options);

class PresentationDeckHost extends StatelessWidget {
  const PresentationDeckHost({super.key, DeckAppBuilder? deckAppBuilder})
    : _deckAppBuilder = deckAppBuilder ?? _defaultDeckAppBuilder;

  final DeckAppBuilder _deckAppBuilder;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final style = DeckStyleService.style.value;
      final options = buildDeckOptionsFromStyle(style);
      return _deckAppBuilder(options);
    });
  }

  static Widget _defaultDeckAppBuilder(DeckOptions options) {
    return SuperDeckApp(options: options, workspace: runtimeDeckWorkspace());
  }
}
