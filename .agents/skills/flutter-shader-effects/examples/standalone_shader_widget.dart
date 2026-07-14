// Template for a standalone SuperDeck shader effect widget.
//
// To use:
// 1. Copy to demo/lib/src/widgets/<effect_name>.dart and rename the classes.
// 2. Create demo/shaders/<effect_name>.frag (see effect_template.frag).
// 3. Declare the shader in demo/pubspec.yaml under `flutter: shaders:`.
// 4. Register in demo_widgets.dart: '<effect-name>': EffectName.fromArgs.
// 5. Add a mirrored test under demo/test/.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class EffectName extends StatefulWidget {
  final double speed;
  final double intensity;
  final Color colorA;
  final Color colorB;

  const EffectName({
    super.key,
    this.speed = 1,
    this.intensity = 1,
    this.colorA = const Color(0xFF55F6C1),
    this.colorB = const Color(0xFF8B5CF6),
  }) : assert(speed > 0),
       assert(intensity >= 0);

  factory EffectName.fromArgs(Map<String, Object?> args) => EffectName(
    speed: (args['speed'] as num?)?.toDouble() ?? 1,
    intensity: (args['intensity'] as num?)?.toDouble() ?? 1,
  );

  @override
  State<EffectName> createState() => _EffectNameState();
}

class _EffectNameState extends State<EffectName>
    with SingleTickerProviderStateMixin {
  // Loaded once per app; every instance reuses the compiled program.
  static final _program = ui.FragmentProgram.fromAsset(
    'shaders/effect_name.frag',
  );

  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion and off-screen slides freeze uTime; the shader must
    // still render a good static frame.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (TickerMode.valuesOf(context).enabled && !reduceMotion) {
      if (!_animation.isAnimating) _animation.repeat();
    } else {
      _animation.stop();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Outer boundary isolates the deck; inner one isolates per-frame paints.
    return RepaintBoundary(
      child: FutureBuilder<ui.FragmentProgram>(
        future: _program,
        builder: (context, snapshot) => snapshot.hasData
            ? RepaintBoundary(
                child: CustomPaint(
                  painter: _EffectPainter(
                    shader: snapshot.requireData.fragmentShader(),
                    animation: _animation,
                    speed: widget.speed,
                    intensity: widget.intensity,
                    colorA: widget.colorA,
                    colorB: widget.colorB,
                  ),
                  child: const SizedBox.expand(),
                ),
              )
            : const ColoredBox(color: Color(0xFF080B18)),
      ),
    );
  }
}

class _EffectPainter extends CustomPainter {
  final ui.FragmentShader _shader;
  final Animation<double> _animation;
  final double _speed;
  final Paint _paint;

  _EffectPainter({
    required ui.FragmentShader shader,
    required Animation<double> animation,
    required double speed,
    required double intensity,
    required Color colorA,
    required Color colorB,
  }) : _shader = shader,
       _animation = animation,
       _speed = speed,
       _paint = Paint()..shader = shader,
       // repaint: animation drives frames without setState.
       super(repaint: animation) {
    // Static uniforms set once; slots follow the .frag declaration order.
    shader
      ..setFloat(3, intensity) // uIntensity
      ..setFloat(4, colorA.r) // uColorA
      ..setFloat(5, colorA.g)
      ..setFloat(6, colorA.b)
      ..setFloat(7, colorB.r) // uColorB
      ..setFloat(8, colorB.g)
      ..setFloat(9, colorB.b);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _shader
      ..setFloat(0, size.width) // uSize
      ..setFloat(1, size.height)
      ..setFloat(2, _animation.value * 3600 * _speed); // uTime
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(_EffectPainter oldDelegate) =>
      oldDelegate._shader != _shader || oldDelegate._speed != _speed;
}
