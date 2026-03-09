import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart' show Deck;

import '../../utils/deck_style_service.dart';
import '../../utils/style_builder.dart';

const _kCanRunProcess =
    kDebugMode && !kIsWeb && !bool.fromEnvironment('FLUTTER_TEST');

class PresentationDeckHost extends StatelessWidget {
  const PresentationDeckHost({
    super.key,
    this.config = _kDefaultConfig,
    this.appBuilder,
  });

  static const _kDefaultConfig = _kCanRunProcess
      ? DeckConfig.local()
      : DeckConfig.bundle();

  final DeckConfig config;
  final Widget Function(DeckTheme theme, Deck deck)? appBuilder;

  @override
  Widget build(BuildContext context) {
    return SuperDeckProvider(
      config: config,
      builder: (context, deck) {
        return Watch((context) {
          final style = DeckStyleService.style.value;
          final theme = buildDeckThemeFromStyle(style);
          return appBuilder?.call(theme, deck) ??
              SuperDeckApp(deck: deck, theme: theme);
        });
      },
    );
  }
}
