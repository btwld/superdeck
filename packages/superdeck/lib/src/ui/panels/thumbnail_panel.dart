import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';

class ThumbnailPanel extends StatefulWidget {
  const ThumbnailPanel({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.activeIndex,
    required this.onItemTap,
    required this.scrollDirection,
  });

  final int activeIndex;
  final Axis scrollDirection;

  final Widget Function(int index, bool selected) itemBuilder;
  final void Function(int index) onItemTap;
  final int itemCount;

  @override
  State<ThumbnailPanel> createState() => _ThumbnailPanelState();
}

class _ThumbnailPanelState extends State<ThumbnailPanel> {
  static const _padding = 20.0;
  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeInOutCubic;

  /// Where a thumbnail ahead of the view lands, as a fraction of the viewport,
  /// so the thumbnails after it stay in view.
  static const _forwardAlignment = 0.7;

  final _pageStorageBucket = PageStorageBucket();
  final _scrollController = ScrollController();

  /// Scrolls just far enough to show the thumbnail at [index] in full.
  ///
  /// Every thumbnail has the same extent, so the list's scroll extent is exact
  /// and a thumbnail's offset follows from its index, even when it is not
  /// built yet.
  void _scrollToActiveSlide(int index) {
    if (!_scrollController.hasClients || widget.itemCount == 0) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    final viewport = position.viewportDimension;
    final extent =
        (position.maxScrollExtent + viewport - 2 * _padding) / widget.itemCount;
    final itemStart = _padding + index * extent;
    final itemEnd = itemStart + extent;
    final viewStart = position.pixels;
    final viewEnd = viewStart + viewport;
    if (itemStart >= viewStart && itemEnd <= viewEnd) return;

    final double target;
    if (itemEnd <= viewStart) {
      target = itemStart;
    } else if (itemStart >= viewEnd) {
      target = itemStart - viewport * _forwardAlignment;
    } else if (itemEnd > viewEnd) {
      // Cut off at the trailing edge: align its end with the view's end.
      target = itemEnd - viewport;
    } else {
      target = itemStart;
    }

    _scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: _duration,
      curve: _curve,
    );
  }

  @override
  void didUpdateWidget(ThumbnailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToActiveSlide(widget.activeIndex);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: _pageStorageBucket,
      child: Container(
        color: Colors.black,
        child: ListView.builder(
          key: PageStorageKey<String>(
            'thumbnail-panel-${widget.scrollDirection.name}',
          ),
          controller: _scrollController,
          scrollDirection: widget.scrollDirection,
          padding: const EdgeInsets.all(_padding),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Semantics(
                button: true,
                selected: index == widget.activeIndex,
                label: 'Slide thumbnail ${index + 1}',
                child: GestureDetector(
                  key: ValueKey<String>('slide-thumbnail-${index + 1}'),
                  onTap: () => widget.onItemTap(index),
                  child: widget.itemBuilder(index, index == widget.activeIndex),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
