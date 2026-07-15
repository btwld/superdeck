import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const debugSectionColor = Color(0xFFFF4DCD);
const debugBlockColor = Color(0xFF00D5FF);
const debugMarginColor = Color(0xFFFFA62B);
const debugPaddingColor = Color(0xFF35E06F);

/// Draws a debug-only frame without participating in layout.
class LayoutDebugFrame extends StatelessWidget {
  final Color color;
  final Widget child;
  final double strokeWidth;

  const LayoutDebugFrame({
    super.key,
    required this.color,
    required this.child,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _FramePainter(color, strokeWidth),
      child: child,
    );
  }
}

/// Draws the allocated block, resolved margin, and resolved padding edges.
class BlockLayoutDebugOverlay extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const BlockLayoutDebugOverlay({
    super.key,
    required this.margin,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    return CustomPaint(
      foregroundPainter: _BlockInsetsPainter(
        margin: margin?.resolve(textDirection) ?? EdgeInsets.zero,
        padding: padding?.resolve(textDirection) ?? EdgeInsets.zero,
      ),
      child: child,
    );
  }
}

class LayoutDebugLabel extends StatelessWidget {
  final Color color;
  final String text;

  const LayoutDebugLabel({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF071018),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class LayoutDebugLegend extends StatelessWidget {
  const LayoutDebugLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6071018),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _LegendItem(color: debugSectionColor, label: 'SECTION'),
            SizedBox(width: 10),
            _LegendItem(color: debugBlockColor, label: 'BLOCK'),
            SizedBox(width: 10),
            _LegendItem(color: debugMarginColor, label: 'MARGIN'),
            SizedBox(width: 10),
            _LegendItem(color: debugPaddingColor, label: 'PADDING'),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(dimension: 10, child: ColoredBox(color: color)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BlockInsetsPainter extends CustomPainter {
  final EdgeInsets margin;
  final EdgeInsets padding;

  const _BlockInsetsPainter({required this.margin, required this.padding});

  @override
  void paint(Canvas canvas, Size size) {
    final blockRect = Offset.zero & size;
    final marginRect = _inset(blockRect, margin);
    final paddingRect = _inset(marginRect, padding);

    _drawFrame(canvas, blockRect, debugBlockColor, 4);
    _drawFrame(canvas, marginRect, debugMarginColor, 3);
    _drawFrame(canvas, paddingRect, debugPaddingColor, 2);
  }

  @override
  bool shouldRepaint(_BlockInsetsPainter oldDelegate) {
    return oldDelegate.margin != margin || oldDelegate.padding != padding;
  }
}

class _FramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _FramePainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    _drawFrame(canvas, Offset.zero & size, color, strokeWidth);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

Rect _inset(Rect rect, EdgeInsets insets) {
  final left = math.min(rect.right, rect.left + insets.left);
  final top = math.min(rect.bottom, rect.top + insets.top);
  final right = math.max(left, rect.right - insets.right);
  final bottom = math.max(top, rect.bottom - insets.bottom);
  return Rect.fromLTRB(left, top, right, bottom);
}

void _drawFrame(Canvas canvas, Rect rect, Color color, double strokeWidth) {
  if (rect.width <= strokeWidth || rect.height <= strokeWidth) return;
  canvas.drawRect(
    rect.deflate(strokeWidth / 2),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth,
  );
}
