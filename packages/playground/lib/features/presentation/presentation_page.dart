import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../utils/memory_asset_cache_store.dart';

class PresentationPage extends StatefulWidget {
  const PresentationPage({super.key});

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  static const _transitionDuration = Duration(milliseconds: 400);

  // Each slide is rendered as its own route in this inner navigator. Slide
  // changes go through [Navigator.pushReplacement] so the [HeroController]
  // below observes a route transition and flies matching `Hero` widgets
  // between slides. A plain `setState` swap stays on one route, so the hero
  // controller never runs and hero animations never play.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final HeroController _heroController = HeroController();
  final FocusNode _focusNode = FocusNode();

  int _slideIndex = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _goNext() {
    final slides = context.read<DeckController>().slides.value;
    if (_slideIndex < slides.length - 1) {
      _goToSlide(_slideIndex + 1);
    }
  }

  void _goPrevious() {
    if (_slideIndex > 0) {
      _goToSlide(_slideIndex - 1);
    }
  }

  /// Replaces the current slide route with the route for [index]. The route
  /// transition is what drives hero flights between the two slides.
  void _goToSlide(int index) {
    _slideIndex = index;
    _navigatorKey.currentState?.pushReplacement(_buildSlideRoute(index));
  }

  Route<void> _buildSlideRoute(int index) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: 'slide-$index'),
      transitionDuration: _transitionDuration,
      reverseTransitionDuration: _transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _SlideStage(index: index),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeckController>();

    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.space) {
              _goNext();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _goPrevious();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Watch((context) {
          final slides = controller.slides.value;
          if (slides.isEmpty) {
            return const _EmptyState();
          }

          return GestureDetector(
            onTap: _goNext,
            child: Navigator(
              key: _navigatorKey,
              observers: [_heroController],
              onGenerateRoute: (_) =>
                  _buildSlideRoute(_slideIndex.clamp(0, slides.length - 1)),
            ),
          );
        }),
      ),
    );
  }
}

/// Renders a single slide, scaled to fit, as the content of one slide route.
class _SlideStage extends StatelessWidget {
  const _SlideStage({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final slides = context.read<DeckController>().slides.value;
    final slide = slides[index.clamp(0, slides.length - 1)];

    return Center(
      child: SizedBox.expand(
        child: FittedBox(
          fit: .fitWidth,
          child: SlideRenderView(
            slide,
            assetCacheStore: context.read<MemoryAssetCacheStore>(),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final style = TextStyler().style(.color($foreground()).fontSize(24));

    return Center(child: style('No slides'));
  }
}
