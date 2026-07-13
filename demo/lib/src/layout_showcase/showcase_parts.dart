import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:superdeck/superdeck.dart';

class ShowcaseBackground extends StatelessWidget {
  const ShowcaseBackground({super.key});

  static const _accents = [
    Color(0xFFFF7A59),
    Color(0xFF8B7CFF),
    Color(0xFFFFB15A),
    Color(0xFFDF6FFF),
    Color(0xFF58D5C9),
    Color(0xFFFF876B),
  ];

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration.of(context);
    final accent = _accents[slide.slideIndex % _accents.length];

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF09090D)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.82, -0.78),
                radius: 1.08,
                colors: [
                  accent.withValues(alpha: 0.15),
                  const Color(0xFF111018).withValues(alpha: 0.7),
                  const Color(0xFF09090D),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
          Positioned(
            right: -180,
            bottom: -220,
            width: 560,
            height: 560,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.11), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomPaint(painter: _ShowcaseGridPainter(accent: accent)),
        ],
      ),
    );
  }
}

class ShowcaseFooter extends StatelessWidget implements PreferredSizeWidget {
  const ShowcaseFooter({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(38);

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        children: [
          const Text(
            'SUPERDECK  /  LAYOUT STUDY',
            style: TextStyle(
              color: Color(0xFF77737D),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
            ),
          ),
          const Spacer(),
          Container(width: 48, height: 1, color: const Color(0x35FFFFFF)),
          const SizedBox(width: 14),
          Text(
            '${slide.slideIndex + 1}'.padLeft(2, '0'),
            style: const TextStyle(
              color: Color(0xFFAAA6AF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseGridPainter extends CustomPainter {
  const _ShowcaseGridPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 1;
    const step = 80.0;

    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final arcPaint = Paint()
      ..color = accent.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final diameter = math.min(size.width, size.height) * 1.12;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.92, size.height * 0.1),
        radius: diameter / 2,
      ),
      math.pi * 0.58,
      math.pi * 0.82,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ShowcaseGridPainter oldDelegate) {
    return accent != oldDelegate.accent;
  }
}
