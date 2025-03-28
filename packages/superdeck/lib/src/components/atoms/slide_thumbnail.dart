import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

import '../../modules/common/helpers/constants.dart';
import '../../modules/deck/slide_configuration.dart';
import '../../modules/slide_capture/thumbnail_controller.dart';

enum _PopMenuAction {
  refreshThumbnail(
    'Refresh Thumbnail',
    Icons.refresh,
  );

  const _PopMenuAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

class SlideThumbnail extends StatelessWidget {
  final bool selected;
  final SlideConfiguration slide;

  const SlideThumbnail({
    super.key,
    required this.selected,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailController = ThumbnailController.of(context);
    final asyncThumbnail = thumbnailController.get(slide, context);
    return _PreviewContainer(
      selected: selected,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: kAspectRatio,
            child: asyncThumbnail.build(context),
          ),
        ],
      ),
    );
  }
}

class _PreviewContainer extends StatelessWidget {
  final Widget child;
  final bool selected;

  const _PreviewContainer({
    required this.selected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final style = Style(
      $box.color.grey(),
      $box.margin.all(8),
      $box.border.width(2),
      $box.shadow(
        blurRadius: 4,
        spreadRadius: 1,
      ),
      selected ? $box.wrap.scale(1.05) : $box.wrap.scale(1),
      selected ? $box.wrap.opacity(1) : $box.wrap.opacity(0.5),
      selected ? $box.border.color.cyan() : $box.border.color.transparent(),
    ).animate();

    return Box(
      style: style,
      child: child,
    );
  }
}
