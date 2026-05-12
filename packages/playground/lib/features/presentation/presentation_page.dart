import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

class PresentationPage extends StatefulWidget {
  const PresentationPage({super.key});

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  int _slideIndex = 0;

  void _goNext() {
    final slides = context.read<DeckController>().slides.value;
    if (_slideIndex < slides.length - 1) {
      setState(() => _slideIndex++);
    }
  }

  void _goPrevious() {
    if (_slideIndex > 0) {
      setState(() => _slideIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeckController>();

    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
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
        child: GestureDetector(
          onTap: _goNext,
          child: Watch((context) {
            final slides = controller.slides.value;
            if (slides.isEmpty) {
              return _EmptyState();
            }

            final index = _slideIndex.clamp(0, slides.length - 1);

            return Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: SlideRenderView(slides[index]),
              ),
            );
          }),
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
