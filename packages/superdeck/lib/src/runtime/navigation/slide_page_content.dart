import 'package:flutter/material.dart' show Icons, Colors, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../rendering/slides/slide_screen.dart';
import '../superdeck_context.dart';

/// Widget for rendering slide page content.
class SlidePageContent extends StatelessWidget {
  const SlidePageContent({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final handle = SuperDeck.of(context);

    return Watch((context) {
      final slides = handle.slides.value;
      if (slides.isEmpty) {
        return const _NoSlidesScreen();
      }

      final safeIndex = index.clamp(0, slides.length - 1);
      return Semantics(
        label: 'Slide ${safeIndex + 1}',
        container: true,
        child: SlideScreen(slides[safeIndex]),
      );
    });
  }
}

class _NoSlidesScreen extends StatelessWidget {
  const _NoSlidesScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.slideshow_outlined, size: 72, color: Colors.blueGrey),
              SizedBox(height: 24),
              Text(
                'No slides available',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Add slides to your deck (slides.md) and rebuild to start presenting.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
