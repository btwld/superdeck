import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  final _duration = const Duration(milliseconds: 300);
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;
  late List<ItemPosition> _visibleItems;

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _visibleItems = [];
    _itemPositionsListener.itemPositions.addListener(_listener);
  }

  void _listener() {
    final newVisibleItems = _itemPositionsListener.itemPositions.value.toList();

    if (listEquals(newVisibleItems, _visibleItems)) return;

    setState(() {
      _visibleItems = newVisibleItems;
    });
  }

  @override
  void didUpdateWidget(ThumbnailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveSlide(widget.activeIndex);
      });
    }
  }

  void _scrollToActiveSlide(int index) {
    final visibleItems = _visibleItems;
    double alignment;

    if (visibleItems.isEmpty) return;

    final visibleItem = visibleItems.firstWhereOrNull(
      (e) => e.index == index,
    );

    if (visibleItem == null) {
      final isBeginning = visibleItems.first.index > index;

      alignment = isBeginning ? 0 : 0.7;
    } else {
      if (visibleItem.itemTrailingEdge > 1) {
        final totalSpace =
            visibleItem.itemTrailingEdge - visibleItem.itemLeadingEdge;
        alignment = 1 - totalSpace;
      } else if (visibleItem.itemLeadingEdge < 0) {
        alignment = 0;
      } else {
        alignment = visibleItem.itemLeadingEdge;
      }
    }

    _itemScrollController.scrollTo(
      index: index,
      alignment: alignment,
      duration: _duration,
      curve: _curve,
    );
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_listener);
    super.dispose();
  }

  final _curve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ScrollablePositionedList.builder(
          scrollDirection: widget.scrollDirection,
          itemCount: widget.itemCount,
          itemPositionsListener: _itemPositionsListener,
          itemScrollController: _itemScrollController,
          padding: const EdgeInsets.all(20),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
              child: GestureDetector(
                onTap: () => widget.onItemTap(index),
                child: widget.itemBuilder(index, index == widget.activeIndex),
              ),
            );
          }),
    );
  }
}
