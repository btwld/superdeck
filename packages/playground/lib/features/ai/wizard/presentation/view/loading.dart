import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Animated isometric cube loading indicator.
///
/// Displays a rotating isometric cube animation used during
/// presentation generation to indicate progress.
class IsometricLoading extends StatefulWidget {
  const IsometricLoading({super.key, this.color = Colors.white});

  final Color color;

  @override
  State createState() => _IsometricLoadingState();
}

class _IsometricLoadingState extends State<IsometricLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late final List<Color> _colors = [
    widget.color,
    widget.color.withValues(alpha: 0.7),
    widget.color.withValues(alpha: 0.4),
    widget.color.withValues(alpha: 0.2),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: IsometricLogoPainter(
            colors: List.generate(4, (index) {
              final startColorIndex =
                  ((_animation.value * _colors.length).floor() + index) %
                  _colors.length;
              final endColorIndex = (startColorIndex == _colors.length - 1)
                  ? 0
                  : startColorIndex + 1;
              final startColor = _colors[startColorIndex];
              final endColor = _colors[endColorIndex];
              final colorProgress = (_animation.value * _colors.length) % 1.0;
              return Color.lerp(startColor, endColor, colorProgress)!;
            }),
          ),
          child: const SizedBox(width: 100, height: 100),
        );
      },
    );
  }
}

/// Custom painter for rendering the isometric cube logo.
///
/// Draws a 3D isometric cube with customizable face colors.
/// Used by [IsometricLoading] and [EmptyState] for branding.
class IsometricLogoPainter extends CustomPainter {
  final List<Color> colors;

  // Original design dimensions for normalization
  static const _originalWidth = 200;
  static const _originalHeight = 226;

  IsometricLogoPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.9;
    final h = size.height;

    // Offset to center the drawing horizontally
    final offsetX = (size.width - w) / 2;

    // Helper to scale x and y coordinates relative to canvas size
    double x(double val) => (val / _originalWidth) * w + offsetX;
    double y(double val) => (val / _originalHeight) * h;

    final path1 = Path()
      ..moveTo(x(92), y(119))
      ..lineTo(x(0), y(66))
      ..lineTo(x(0), y(132))
      ..lineTo(x(71), y(173))
      ..lineTo(x(71), y(189))
      ..lineTo(x(0), y(148))
      ..lineTo(x(0), y(173))
      ..lineTo(x(92), y(226))
      ..lineTo(x(92), y(161))
      ..lineTo(x(21), y(119))
      ..lineTo(x(21), y(103))
      ..lineTo(x(92), y(144))
      ..close();

    final path2 = Path()
      ..moveTo(x(29), y(41))
      ..lineTo(x(8), y(53))
      ..lineTo(x(108), y(111))
      ..lineTo(x(108), y(202))
      ..lineTo(x(129), y(214))
      ..lineTo(x(129), y(99))
      ..close();

    final path3 = Path()
      ..moveTo(x(64), y(21))
      ..lineTo(x(43), y(33))
      ..lineTo(x(143), y(90))
      ..lineTo(x(143), y(182))
      ..lineTo(x(164), y(194))
      ..lineTo(x(164), y(78))
      ..close();

    final path4 = Path()
      ..moveTo(x(79), y(12))
      ..lineTo(x(179), y(70))
      ..lineTo(x(179), y(161))
      ..lineTo(x(200), y(173))
      ..lineTo(x(200), y(58))
      ..lineTo(x(169), y(40))
      ..lineTo(x(100), y(0))
      ..close();

    final paint1 = Paint()
      ..color = colors[0]
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = colors[1]
      ..style = PaintingStyle.fill;
    final paint3 = Paint()
      ..color = colors[2]
      ..style = PaintingStyle.fill;
    final paint4 = Paint()
      ..color = colors[3]
      ..style = PaintingStyle.fill;

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
    canvas.drawPath(path4, paint4);
  }

  @override
  bool shouldRepaint(IsometricLogoPainter oldDelegate) =>
      !listEquals(oldDelegate.colors, colors);
}
