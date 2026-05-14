import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:playground/stores/slide_configuration_store.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

class PreviewSidebar extends StatelessWidget {
  const PreviewSidebar({super.key, this.onPlay});

  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return StackBox(
      style: StackBoxStyler().width(218).marginAll(16),
      children: [
        ColumnBox(
          style: FlexBoxStyler().spacing(24),
          children: [Expanded(child: SlidesPreviewList())],
        ),
      ],
    );
  }
}

class SlidesPreviewList extends StatelessWidget {
  const SlidesPreviewList({super.key});

  @override
  Widget build(BuildContext context) {
    final slides = context.watch<SlideConfigurationStore>().slides;

    if (slides.isEmpty) {
      return Center(
        child: StyledText(
          'No slides',
          style: TextStyler().style(.color($muted())),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollBehavior().copyWith(scrollbars: false),
      child: ListView.builder(
        itemCount: slides.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const .only(bottom: 24),
            child: _PreviewItem(index: index, configuration: slides[index]),
          );
        },
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({required this.index, required this.configuration});

  final int index;
  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    // final textScaler = context.watch<SlideConfigurationStore>().textScaler;

    return HeroCard(
      variant: .tertiary,
      child: Stack(
        alignment: .bottomRight,
        children: [
          Box(
            style: BoxStyler().wrap(.aspectRatio(16 / 9)),
            child: FittedBox(
              fit: .cover,
              alignment: .topLeft,
              child: SlideRenderView(
                configuration.copyWith(
                  style: configuration.style.merge(
                    SlideStyle(textScaleFactor: TextScaler.linear(1)),
                  ),
                ),
              ),
            ),
          ),
          Box(
            style: BoxStyler()
                .marginAll(8)
                .padding(.horizontal(10).vertical(2))
                .color($overlay())
                .borderRounded(12)
                .textStyle(.color($surfaceForeground()).fontSize(12)),
            child: StyledText('${index + 1}'),
          ),
        ],
      ),
    );
  }
}
