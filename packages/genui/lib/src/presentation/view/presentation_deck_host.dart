import 'package:flutter/widgets.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import '../../utils/deck_style_service.dart';
import '../../utils/style_builder.dart';
import 'loading.dart';

typedef DeckAppBuilder = Widget Function(SuperDeckRuntime runtime);
typedef DeckRuntimeLoader =
    Future<SuperDeckRuntime> Function(DeckPresentation presentation);

class PresentationDeckHost extends StatelessWidget {
  const PresentationDeckHost({
    super.key,
    DeckAppBuilder? deckAppBuilder,
    DeckRuntimeLoader? runtimeLoader,
  }) : _deckAppBuilder = deckAppBuilder ?? _defaultDeckAppBuilder,
       _runtimeLoader = runtimeLoader ?? _defaultRuntimeLoader;

  final DeckAppBuilder _deckAppBuilder;
  final DeckRuntimeLoader _runtimeLoader;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final style = DeckStyleService.style.value;
      final presentation = buildDeckPresentationFromStyle(style);
      return FutureBuilder<SuperDeckRuntime>(
        future: _runtimeLoader(presentation),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load presentation: ${snapshot.error}'),
            );
          }
          final runtime = snapshot.data;
          if (runtime == null) {
            return const Center(child: IsometricLoading());
          }
          return _deckAppBuilder(runtime);
        },
      );
    });
  }

  static Widget _defaultDeckAppBuilder(SuperDeckRuntime runtime) {
    return SuperDeckApp(runtime: runtime);
  }

  static Future<SuperDeckRuntime> _defaultRuntimeLoader(
    DeckPresentation presentation,
  ) {
    return SuperDeckRuntime.create(
      source: const DeckSource.local(),
      runtimeConfig: const DeckRuntimeConfig(),
      presentation: presentation,
    );
  }
}
