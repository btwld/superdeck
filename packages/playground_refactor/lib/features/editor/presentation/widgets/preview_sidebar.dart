import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';

import '../../../../core/domain/stores/deck_store.dart';
import '../../domain/stores/editor_store.dart';
import '../../domain/stores/thumbnail_store.dart';

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

/// Renders the slide previews and hosts [ThumbnailStore]'s context-bridge: it's
/// the widget that shows thumbnails and is always mounted, so it supplies the
/// live [BuildContext] the store's [ThumbnailStore.reload] needs. The store owns
/// *when* to regenerate; this widget owns only the frame + context hand-off.
class SlidesPreviewList extends StatefulWidget {
  const SlidesPreviewList({super.key});

  @override
  State<SlidesPreviewList> createState() => _SlidesPreviewListState();
}

class _SlidesPreviewListState extends State<SlidesPreviewList> {
  late final ThumbnailStore _store;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _store = context.read<ThumbnailStore>();
    _store.reloadRequests.addListener(_scheduleReload);
    // The store may have requested its initial reload before we mounted.
    _scheduleReload();
  }

  void _scheduleReload() {
    _store.reload(context);
  }

  @override
  void dispose() {
    _store.reloadRequests.removeListener(_scheduleReload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = context.watch<DeckStore>().slides;
    final activeIndex = context.select<EditorStore, int>(
      (store) => store.activeSlideIndex,
    );

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
              onTap: () => context.read<EditorStore>().activeSlideIndex = index,
            ),
          );
        },
      ),
    );
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
    required this.configuration,
    required this.active,
    required this.fallback,
  });

  final SlideConfiguration configuration;
  final bool active;
  final Widget Function() fallback;

  @override
  Widget build(BuildContext context) {
    final status = context.select<ThumbnailStore, AsyncFileStatus>(
      (store) => store.statusFor(configuration.key),
    );

    final thumbnail = status == AsyncFileStatus.done && !active
        ? context.read<ThumbnailStore>().thumbnailFor(configuration.key)
        : null;

    if (thumbnail == null) {
      return KeyedSubtree(
        key: const ValueKey('fallback'),
        child: Banner(
          message: 'Widget',
          location: BannerLocation.topStart,
          child: fallback(),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('thumbnail'),
      child: Banner(
        message: 'Thumbnail',
        location: BannerLocation.topStart,
        child: thumbnail.build(context),
      ),
    );
  }
}
