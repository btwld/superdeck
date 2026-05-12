import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

class SlidesSidebar extends StatelessWidget {
  const SlidesSidebar({super.key, required this.controller});

  final DeckController controller;

  @override
  Widget build(BuildContext context) {
    return StackBox(
      style: StackBoxStyler().minWidth(218).maxWidth(328).marginAll(16),
      children: [
        ColumnBox(
          style: FlexBoxStyler().spacing(24),
          children: [
            _Toolbar(),
            Expanded(child: _PreviewList(controller: controller)),
          ],
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler().spacing(8),
      children: [
        Spacer(),
        SizedBox(
          width: 48,
          child: HeroIconButton(
            icon: CupertinoIcons.share,
            variant: .secondary,
            onPressed: () {},
          ),
        ),
        SizedBox(
          width: 48,
          child: HeroIconButton(icon: CupertinoIcons.play, onPressed: () {}),
        ),
      ],
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.controller});

  final DeckController controller;

  @override
  Widget build(BuildContext context) {
    final slides = controller.slides.watch(context);

    if (slides.isEmpty) {
      return const Center(
        child: Text('No slides', style: TextStyle(color: Colors.white54)),
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
    return HeroCard(
      variant: .tertiary,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Box(
            style: BoxStyler().wrap(.aspectRatio(16 / 9)),
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: .topLeft,
              child: SlideRenderView(configuration),
            ),
          ),
          Box(
            style: BoxStyler()
                .marginAll(8)
                .padding(.horizontal(10).vertical(2))
                .color($backdrop())
                .borderRounded(12)
                .textStyle(.color($surfaceForeground()).fontSize(12)),
            child: StyledText('${index + 1}'),
          ),
        ],
      ),
    );
  }
}
