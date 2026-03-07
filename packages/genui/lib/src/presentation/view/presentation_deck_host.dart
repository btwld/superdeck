import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../utils/deck_style_service.dart';
import '../../utils/style_builder.dart';
import 'loading.dart';

const _kCanRunProcess =
    kDebugMode && !kIsWeb && !bool.fromEnvironment('FLUTTER_TEST');

class PresentationDeckHost extends StatefulWidget {
  PresentationDeckHost({
    super.key,
    Widget Function(SuperDeckRuntime runtime)? deckAppBuilder,
    Future<SuperDeckRuntime> Function(DeckTheme theme)? runtimeLoader,
  }) : deckAppBuilder =
           deckAppBuilder ?? ((runtime) => SuperDeckApp(runtime: runtime)),
       runtimeLoader =
           runtimeLoader ??
           ((theme) => SuperDeckRuntime.create(
             config: _kCanRunProcess
                 ? const DeckConfig.local()
                 : const DeckConfig.bundle(),
             theme: theme,
           ));

  final Widget Function(SuperDeckRuntime runtime) deckAppBuilder;
  final Future<SuperDeckRuntime> Function(DeckTheme theme) runtimeLoader;

  @override
  State<PresentationDeckHost> createState() => _PresentationDeckHostState();
}

class _PresentationDeckHostState extends State<PresentationDeckHost> {
  DeckTheme? _cachedTheme;
  Future<SuperDeckRuntime>? _runtimeFuture;

  @override
  void didUpdateWidget(covariant PresentationDeckHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.runtimeLoader, widget.runtimeLoader)) {
      _cachedTheme = null;
      _runtimeFuture = null;
    }
  }

  Future<SuperDeckRuntime> _runtimeFutureFor(DeckTheme theme) {
    final canReuseFuture = _runtimeFuture != null && _cachedTheme == theme;
    if (canReuseFuture) {
      return _runtimeFuture!;
    }

    _cachedTheme = theme;
    _runtimeFuture = widget.runtimeLoader(theme);
    return _runtimeFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final style = DeckStyleService.style.value;
      final theme = buildDeckThemeFromStyle(style);
      return FutureBuilder<SuperDeckRuntime>(
        future: _runtimeFutureFor(theme),
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
          return widget.deckAppBuilder(runtime);
        },
      );
    });
  }
}
