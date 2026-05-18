import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/stores/slide_configuration_store.dart';
import 'package:playground/utils/memory_deck_loader.dart';
import 'package:playground/features/presentation/presentation_page.dart';
import 'package:playground/utils/takeover_route.dart';
import 'package:playground/features/editor/editor_page.dart';
import 'package:provider/provider.dart';
import 'package:remix/remix.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  SignalsObserver.instance = null;
  runApp(const PlaygroundApp());
}

class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key});

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

class _PlaygroundAppState extends State<PlaygroundApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superdeck',
      builder: (context, child) {
        return _Theme(child: _Providers(child: child!));
      },
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/present':
            return TakeoverRoute<void>(
              settings: settings,
              builder: (_) => const PresentationPage(),
            );
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const EditorPage(),
            );
        }
      },
    );
  }
}

class _Providers extends StatefulWidget {
  const _Providers({required this.child});

  final Widget child;
  @override
  State<_Providers> createState() => _ProvidersState();
}

class _ProvidersState extends State<_Providers> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MemoryDeckLoader>(create: (_) => MemoryDeckLoader()),
        Provider<DeckController>(
          create: (context) {
            final baseStyle = SlideStyle(
              h1: TextStyler().style(.color($foreground())),
              h2: TextStyler().style(.color($foreground())),
              h3: TextStyler().style(.color($foreground())),
              h4: TextStyler().style(.color($foreground())),
              h5: TextStyler().style(.color($foreground())),
              h6: TextStyler().style(.color($foreground())),
              p: TextStyler().style(.color($foreground())),
            );

            return DeckController(
              deckLoader: context.read<MemoryDeckLoader>(),
              options: .new(baseStyle: baseStyle),
            );
          },
        ),
        ChangeNotifierProvider<SlideConfigurationStore>(
          create: (context) =>
              SlideConfigurationStore(context.read<DeckController>()),
        ),
      ],
      child: widget.child,
    );
  }
}

class _Theme extends StatelessWidget {
  const _Theme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroTheme(
      data: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? .dark()
          : .light(),
      child: child,
    );
  }
}
