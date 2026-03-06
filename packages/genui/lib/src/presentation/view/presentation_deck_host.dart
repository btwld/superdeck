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
    Future<SuperDeckRuntime> Function(DeckPresentation presentation)?
    runtimeLoader,
  }) : deckAppBuilder =
           deckAppBuilder ?? ((runtime) => SuperDeckApp(runtime: runtime)),
       runtimeLoader =
           runtimeLoader ??
           ((presentation) => SuperDeckRuntime.create(
             source: _kCanRunProcess
                 ? const DeckSource.local()
                 : const DeckSource.bundle(),
             runtimeConfig: const DeckRuntimeConfig(),
             presentation: presentation,
           ));

  final Widget Function(SuperDeckRuntime runtime) deckAppBuilder;
  final Future<SuperDeckRuntime> Function(DeckPresentation presentation)
  runtimeLoader;

  @override
  State<PresentationDeckHost> createState() => _PresentationDeckHostState();
}

class _PresentationDeckHostState extends State<PresentationDeckHost> {
  DeckPresentation? _cachedPresentation;
  Future<SuperDeckRuntime>? _runtimeFuture;

  @override
  void didUpdateWidget(covariant PresentationDeckHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.runtimeLoader, widget.runtimeLoader)) {
      _cachedPresentation = null;
      _runtimeFuture = null;
    }
  }

  Future<SuperDeckRuntime> _runtimeFutureFor(DeckPresentation presentation) {
    final canReuseFuture =
        _runtimeFuture != null && _cachedPresentation == presentation;
    if (canReuseFuture) {
      return _runtimeFuture!;
    }

    _cachedPresentation = presentation;
    _runtimeFuture = widget.runtimeLoader(presentation);
    return _runtimeFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final style = DeckStyleService.style.value;
      final presentation = buildDeckPresentationFromStyle(style);
      return FutureBuilder<SuperDeckRuntime>(
        future: _runtimeFutureFor(presentation),
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
