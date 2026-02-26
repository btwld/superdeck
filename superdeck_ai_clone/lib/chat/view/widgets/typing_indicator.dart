import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

/// Animated typing indicator with three bouncing dots.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = FortalTokens.gray9.resolve(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Stagger each dot's animation
            final delay = index * 0.15;
            final progress = (_controller.value + delay) % 1.0;
            // Use sine wave for smooth bounce
            final bounce = math.sin(progress * math.pi);

            return Transform.translate(
              offset: Offset(0, -bounce * 5),
              child: Opacity(opacity: 0.4 + (bounce * 0.6), child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}
