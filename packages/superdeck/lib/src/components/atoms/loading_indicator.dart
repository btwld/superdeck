import 'package:flutter/material.dart';
import 'package:superdeck/src/modules/common/helpers/extensions.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
  });

  @override
  State createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      _triggerChange(widget.isLoading);
    }
  }

  Future<void> _triggerChange(bool isLoading) async {
    if (isLoading) {
      _animationController.reverse().then((value) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _animationController.forward().then((value) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || _animationController.isAnimating) {
      return FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          color: Colors.black87,
          child: const Center(
            child: IsometricLoading(),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class IsometricLoading extends StatefulWidget {
  const IsometricLoading({
    super.key,
    this.color = Colors.white,
  });

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
    widget.color.useOpacity(0.7),
    widget.color.useOpacity(0.4),
    widget.color.useOpacity(0.2),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
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
        return Transform.scale(
          scale: 0.2,
          child: CustomPaint(
            painter: IsometricLoadingPainter(
              colors: List.generate(
                4,
                (index) {
                  final startColorIndex =
                      ((_animation.value * _colors.length).floor() + index) %
                          _colors.length;
                  final endColorIndex = (startColorIndex == _colors.length - 1)
                      ? 0
                      : startColorIndex + 1;
                  final startColor = _colors[startColorIndex];
                  final endColor = _colors[endColorIndex];
                  final colorProgress =
                      (_animation.value * _colors.length) % 1.0;
                  return Color.lerp(startColor, endColor, colorProgress)!;
                },
              ),
            ),
            child: const SizedBox(width: 200, height: 200),
          ),
        );
      },
    );
  }
}

class IsometricLoadingPainter extends CustomPainter {
  final List<Color> colors;

  IsometricLoadingPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final canvasHeight = size.height;
    final canvasWidth = size.width;

    // Calculate the minimum and maximum Y-coordinates from the path data
    // Assuming the minimum Y-coordinate is 0
    const minY = 0.0;
    // Based on the maximum Y-coordinate value in the path data
    const maxY = 226.45;

    // Calculate the height of the paths
    const pathHeight = maxY - minY;

    // Calculate the scale factor based on the canvas size and path height
    final scaleFactor = canvasHeight / pathHeight;

    // Translate the canvas to center the paths
    canvas.translate(canvasWidth / 2 - 100.003 * scaleFactor, 0);

    // Scale the canvas based on the calculated scale factor
    canvas.scale(scaleFactor);

    final path1 = Path()
      ..moveTo(92.2116, 119.9706)
      ..lineTo(0, 66.7358)
      ..lineTo(0, 132.1824)
      ..lineTo(71.075, 173.2154)
      ..lineTo(71.075, 189.8452)
      ..lineTo(0, 148.812)
      ..lineTo(0, 173.2154)
      ..lineTo(92.2116, 226.45)
      ..lineTo(92.2116, 161.0138)
      ..lineTo(21.1366, 119.9706)
      ..lineTo(21.1366, 103.341)
      ..lineTo(92.2116, 144.384)
      ..close();

    final path2 = Path()
      ..moveTo(28.9178, 41.045)
      ..lineTo(7.78124, 53.2566)
      ..lineTo(107.7764, 110.9884)
      ..lineTo(107.7764, 202.038)
      ..lineTo(128.9128, 214.25)
      ..lineTo(128.9128, 98.7868)
      ..close();

    final path3 = Path()
      ..moveTo(64.4646, 20.5274)
      ..lineTo(43.3282, 32.7388)
      ..lineTo(143.3232, 90.4706)
      ..lineTo(143.3232, 181.521)
      ..lineTo(164.4598, 193.7328)
      ..lineTo(164.4598, 78.269)
      ..close();

    final path4 = Path()
      ..moveTo(78.875, 12.21148)
      ..lineTo(178.87, 69.9434)
      ..lineTo(178.87, 160.994)
      ..lineTo(200.006, 173.2054)
      ..lineTo(200.006, 57.7318)
      ..lineTo(169.2662, 39.99)
      ..lineTo(100.0116, 0)
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
  bool shouldRepaint(IsometricLoadingPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
