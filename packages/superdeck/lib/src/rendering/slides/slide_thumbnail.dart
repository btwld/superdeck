import 'package:flutter/material.dart';

import '../../deck/slide_configuration.dart';
import '../../export/thumbnail_controller.dart';
import '../../utils/constants.dart';

class SlideThumbnail extends StatefulWidget {
  final bool selected;
  final SlideConfiguration slide;

  const SlideThumbnail({
    super.key,
    required this.selected,
    required this.slide,
  });

  @override
  State<SlideThumbnail> createState() => _SlideThumbnailState();
}

class _SlideThumbnailState extends State<SlideThumbnail> {
  ThumbnailController? _thumbnailController;
  AsyncThumbnail? _asyncThumbnail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeThumbnail();
  }

  @override
  void didUpdateWidget(SlideThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slide != widget.slide) {
      _initializeThumbnail();
    }
  }

  void _initializeThumbnail() {
    _thumbnailController = ThumbnailController.of(context);
    _asyncThumbnail = _thumbnailController!.get(widget.slide, context);
  }

  @override
  Widget build(BuildContext context) {
    // Return a loading placeholder if thumbnail isn't initialized yet
    if (_asyncThumbnail == null) {
      return _PreviewContainer(
        selected: widget.selected,
        child: AspectRatio(
          aspectRatio: kAspectRatio,
          child: Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    return _PreviewContainer(
      selected: widget.selected,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: kAspectRatio,
            child: _asyncThumbnail!.build(context),
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
    // Using Flutter widgets with AnimatedContainer for transitions
    final scale = selected ? 1.05 : 1.0;
    return AnimatedOpacity(
      opacity: selected ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(8),
        transform: Matrix4.diagonal3Values(scale, scale, 1.0),
        decoration: BoxDecoration(
          color: Colors.grey,
          border: Border.all(
            width: 2,
            color: selected ? Colors.cyan : Colors.transparent,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
