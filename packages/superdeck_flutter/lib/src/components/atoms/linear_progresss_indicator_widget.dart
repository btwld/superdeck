import 'package:flutter/material.dart';

class AnimatedLinearProgressIndicator extends StatefulWidget {
  final double progress;

  const AnimatedLinearProgressIndicator({
    super.key,
    required this.progress,
  });

  @override
  State<AnimatedLinearProgressIndicator> createState() =>
      _AnimatedLinearProgressIndicatorState();
}

class _AnimatedLinearProgressIndicatorState
    extends State<AnimatedLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(_animationController);
    _animationController.forward();
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
        return LinearProgressIndicator(
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          value: _animation.value,
        );
      },
    );
  }
}
