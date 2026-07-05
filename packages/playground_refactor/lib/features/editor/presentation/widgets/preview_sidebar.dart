import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../domain/stores/editor_store.dart';

class PreviewSidebar extends StatelessWidget {
  const PreviewSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final width = context.select<EditorStore, double>(
      (store) => store.previewSidebarWidth,
    );

    return HeroMode(
      enabled: false,
      child: StackBox(
        style: StackBoxStyler().width(width).marginAll(16),
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

/// Renders the slide previews as live [SlideRenderView]s.
///
/// No thumbnail cache: each visible preview renders the slide directly, so it's
/// always current and there's nothing to regenerate. `ListView.builder` keeps
/// this to the on-screen previews.
///
/// Slides come straight from `DeckController.slides` (a signal) via [Watch]; the
/// active-slide highlight still comes from `EditorStore` through Provider.
class SlidesPreviewList extends StatelessWidget {
  const SlidesPreviewList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeckController>();
    final activeIndex = context.select<EditorStore, int>(
      (store) => store.activeSlideIndex,
    );

    return Watch((context) {
      final slides = controller.slides.value;

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
            return Padding(
              padding: const .only(bottom: 24),
              child: _PreviewItem(
                index: index,
                configuration: slides[index],
                isActive: index == activeIndex,
                onTap: () =>
                    context.read<EditorStore>().activeSlideIndex = index,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HeroCard(
        variant: .tertiary,
        child: Stack(
          alignment: .bottomRight,
          children: [
            Box(
              style: BoxStyler().wrap(.aspectRatio(16 / 9)),
              child: FittedBox(
                fit: .cover,
                alignment: .topLeft,
                child: SlideRenderView(configuration),
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
