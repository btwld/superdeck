import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../stores/editor_state.dart';

class PreviewSidebar extends StatelessWidget {
  const PreviewSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: false,
      child: StackBox(
        style: StackBoxStyler().width(218).marginAll(16),
        children: [
          ColumnBox(
            style: FlexBoxStyler().spacing(24),
            children: [Expanded(child: SlidesPreviewList())],
          ),
        ],
      ),
    );
  }
}

class SlidesPreviewList extends StatelessWidget {
  const SlidesPreviewList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeckController>();
    final editorState = context.read<EditorState>();

    return Watch((context) {
      final slides = controller.slides.value;
      final activeIndex = editorState.activeSlideIndex.value;

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
          clipBehavior: .none,
          itemCount: slides.length,
          itemBuilder: (context, index) {
            final isActive = index == activeIndex;
            return Padding(
              padding: const .only(bottom: 24),
              child: _PreviewItem(
                index: index,
                configuration: slides[index],
                isActive: isActive,
                onTap: () {
                  editorState.activeSlideIndex.value = index;
                },
              ),
            );
          },
        ),
      );
    });
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({
    required this.index,
    required this.configuration,
    this.isActive = false,
    this.onTap,
  });

  final int index;
  final SlideConfiguration configuration;
  final bool isActive;
  final VoidCallback? onTap;

  Widget _buildSlideRender() {
    return FittedBox(
      fit: .cover,
      alignment: .topLeft,
      child: SlideRenderView(configuration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeckController>();

    return GestureDetector(
      onTap: onTap,
      child: HeroCard(
        variant: .tertiary,
        child: Stack(
          alignment: .bottomRight,
          children: [
            Box(
              style: BoxStyler().wrap(.aspectRatio(16 / 9)),
              child: _SlidePreview(
                active: isActive,
                controller: controller,
                configuration: configuration,
                fallback: _buildSlideRender,
              ),
            ),
            Box(
              style: BoxStyler()
                  .marginAll(8)
                  .padding(.horizontal(10).vertical(2))
                  .color(isActive ? $accent() : $overlay())
                  .borderRounded(12)
                  .textStyle(
                    .color(
                      isActive ? $accentForeground() : $surfaceForeground(),
                    ).fontSize(12),
                  ),
              child: StyledText('${index + 1}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidePreview extends StatelessWidget {
  const _SlidePreview({
    required this.controller,
    required this.configuration,
    required this.active,
    required this.fallback,
  });

  final DeckController controller;
  final SlideConfiguration configuration;
  final bool active;
  final Widget Function() fallback;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final thumbnail = controller.presentation.getThumbnail(configuration.key);

      final status = thumbnail?.status.value;
      final isThumbnailReady = status == AsyncFileStatus.done && !active;

      return isThumbnailReady
          ? KeyedSubtree(
              key: const ValueKey('thumbnail'),
              child: Banner(
                message: 'Thumbnail',
                location: BannerLocation.topStart,
                child: thumbnail!.build(context),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('fallback'),
              child: Banner(
                message: 'Widget',
                location: BannerLocation.topStart,
                child: fallback(),
              ),
            );
    });
  }
}
