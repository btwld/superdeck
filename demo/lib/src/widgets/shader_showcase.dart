import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum ShaderMood {
  subtle('Subtle'),
  dramatic('Dramatic');

  final String label;

  const ShaderMood(this.label);
}

enum ShaderEffect {
  aurora(
    'Aurora',
    ShaderMood.subtle,
    'Slow luminous curtains',
    Color(0xFF55F6C1),
    Color(0xFF8B5CF6),
  ),
  silk(
    'Silk',
    ShaderMood.subtle,
    'Soft flowing fabric',
    Color(0xFFC4B5FD),
    Color(0xFF60A5FA),
  ),
  mesh(
    'Mesh Gradient',
    ShaderMood.subtle,
    'Quiet drifting color fields',
    Color(0xFFFB7185),
    Color(0xFF38BDF8),
  ),
  caustics(
    'Caustics',
    ShaderMood.subtle,
    'Underwater light',
    Color(0xFF67E8F9),
    Color(0xFF1D4ED8),
  ),
  topography(
    'Topography',
    ShaderMood.subtle,
    'Living contour lines',
    Color(0xFFA3E635),
    Color(0xFF22D3EE),
  ),
  holographic(
    'Holographic',
    ShaderMood.subtle,
    'Prismatic sheen',
    Color(0xFFF9A8D4),
    Color(0xFF67E8F9),
  ),
  smoke(
    'Cinematic Smoke',
    ShaderMood.dramatic,
    'Rising, edge-lit plume',
    Color(0xFFDCE7F3),
    Color(0xFF64748B),
  ),
  nebula(
    'Nebula',
    ShaderMood.dramatic,
    'Deep-space clouds',
    Color(0xFFF472B6),
    Color(0xFF22D3EE),
  ),
  ink(
    'Ink Bloom',
    ShaderMood.dramatic,
    'Liquid color bloom',
    Color(0xFFFB7185),
    Color(0xFFA78BFA),
  ),
  plasma(
    'Plasma',
    ShaderMood.dramatic,
    'Electric color field',
    Color(0xFFFF4D9D),
    Color(0xFF5DE1FF),
  ),
  ripples(
    'Ripples',
    ShaderMood.dramatic,
    'Concentric interference',
    Color(0xFF31E8FF),
    Color(0xFF2563EB),
  ),
  vortex(
    'Vortex',
    ShaderMood.dramatic,
    'Spiral energy',
    Color(0xFFFFB86B),
    Color(0xFF9D4EDD),
  ),
  volumetricSmoke(
    'Volumetric Smoke',
    ShaderMood.dramatic,
    'Ray-marched, self-shadowed plume',
    Color(0xFFE9EEF5),
    Color(0xFF63748A),
  );

  final String label;
  final ShaderMood mood;
  final String description;
  final Color colorA;
  final Color colorB;

  const ShaderEffect(
    this.label,
    this.mood,
    this.description,
    this.colorA,
    this.colorB,
  );

  static ShaderEffect parse(String value) => values.firstWhere(
    (effect) => effect.name == value,
    orElse: () => throw ArgumentError.value(value, 'effect'),
  );
}

class ShaderShowcase extends StatefulWidget {
  final ShaderEffect effect;
  final bool showControls;
  final double speed;
  final double intensity;
  final double quality;

  const ShaderShowcase({
    super.key,
    this.effect = ShaderEffect.aurora,
    this.showControls = true,
    this.speed = 1,
    this.intensity = 1,
    this.quality = 0.5,
  }) : assert(speed > 0),
       assert(intensity >= 0),
       assert(quality >= 0 && quality <= 1);

  factory ShaderShowcase.fromArgs(Map<String, Object?> args) => ShaderShowcase(
    effect: ShaderEffect.parse(args['effect'] as String? ?? 'aurora'),
    showControls: args['showControls'] as bool? ?? true,
    speed: (args['speed'] as num?)?.toDouble() ?? 1,
    intensity: (args['intensity'] as num?)?.toDouble() ?? 1,
    quality: (args['quality'] as num?)?.toDouble() ?? 0.5,
  );

  @override
  State<ShaderShowcase> createState() => _ShaderShowcaseState();
}

class _ShaderShowcaseState extends State<ShaderShowcase>
    with SingleTickerProviderStateMixin {
  static final Future<ui.FragmentProgram> _program =
      ui.FragmentProgram.fromAsset('shaders/shader_showcase.frag');
  static final Future<ui.FragmentProgram> _volumetricSmokeProgram =
      ui.FragmentProgram.fromAsset('shaders/volumetric_smoke.frag');

  final _menuKey = GlobalKey<PopupMenuButtonState<ShaderEffect>>();
  late final AnimationController _animation;
  late final _FrameRateLimiter _volumetricRepaint;
  late ShaderEffect _effect;
  // Created once when the program resolves and reused across rebuilds — avoids
  // allocating a fresh shader per build and makes shouldRepaint meaningful.
  ui.FragmentShader? _shader;
  ui.FragmentShader? _volumetricSmokeShader;
  Future<void>? _shaderLoad;
  Future<void>? _volumetricSmokeShaderLoad;

  void _loadShaderFor(ShaderEffect effect) {
    if (effect == ShaderEffect.volumetricSmoke) {
      _volumetricSmokeShaderLoad ??= _volumetricSmokeProgram.then((program) {
        if (mounted) {
          setState(() => _volumetricSmokeShader = program.fragmentShader());
        }
      });
    } else {
      _shaderLoad ??= _program.then((program) {
        if (mounted) setState(() => _shader = program.fragmentShader());
      });
    }
  }

  void _selectEffect(ShaderEffect effect) {
    if (_effect == effect) return;
    _loadShaderFor(effect);
    setState(() => _effect = effect);
  }

  void _stepEffect(int offset) {
    final effects = ShaderEffect.values;
    final index = (_effect.index + offset) % effects.length;
    _selectEffect(effects[index]);
  }

  Widget _buildControls(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6141726),
          border: Border.all(color: const Color(0x33FFFFFF)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Previous shader',
              button: true,
              onTap: () => _stepEffect(-1),
              child: ExcludeSemantics(
                child: IconButton(
                  tooltip: 'Previous shader',
                  color: Colors.white,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _stepEffect(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
              ),
            ),
            Semantics(
              label: 'Choose shader effect: ${_effect.label}',
              button: true,
              onTap: () => _menuKey.currentState?.showButtonMenu(),
              child: ExcludeSemantics(
                child: PopupMenuButton<ShaderEffect>(
                  key: _menuKey,
                  initialValue: _effect,
                  tooltip: 'Choose shader effect',
                  onSelected: _selectEffect,
                  itemBuilder: (context) => [
                    for (final effect in ShaderEffect.values)
                      CheckedPopupMenuItem<ShaderEffect>(
                        value: effect,
                        checked: effect == _effect,
                        child: SizedBox(
                          width: 220,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(effect.label),
                              Text(
                                effect.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  child: SizedBox(
                    width: 176,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _effect.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_effect.mood.label}  •  '
                            '${_effect.index + 1}/'
                            '${ShaderEffect.values.length}',
                            style: const TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              label: 'Next shader',
              button: true,
              onTap: () => _stepEffect(1),
              child: ExcludeSemantics(
                child: IconButton(
                  tooltip: 'Next shader',
                  color: Colors.white,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _stepEffect(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _effect = widget.effect;
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    );
    _volumetricRepaint = _FrameRateLimiter(
      animation: _animation,
      maxFramesPerSecond: 30,
    );
    _loadShaderFor(_effect);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (TickerMode.valuesOf(context).enabled && !reduceMotion) {
      if (!_animation.isAnimating) _animation.repeat();
    } else {
      _animation.stop();
    }
  }

  @override
  void didUpdateWidget(covariant ShaderShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect != widget.effect) {
      _effect = widget.effect;
      _loadShaderFor(_effect);
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    _volumetricSmokeShader?.dispose();
    _volumetricRepaint.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    final volumetricSmokeShader = _volumetricSmokeShader;
    return RepaintBoundary(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          key: ValueKey('shader-showcase-${_effect.name}'),
          fit: StackFit.expand,
          children: [
            if (_effect == ShaderEffect.volumetricSmoke)
              if (volumetricSmokeShader != null)
                RepaintBoundary(
                  child: CustomPaint(
                    key: const ValueKey('volumetric-smoke-canvas'),
                    painter: _VolumetricSmokePainter(
                      shader: volumetricSmokeShader,
                      animation: _animation,
                      repaint: _volumetricRepaint,
                      speed: widget.speed,
                      intensity: widget.intensity,
                      quality: widget.quality,
                    ),
                  ),
                )
              else
                const ColoredBox(color: Color(0xFF080B18))
            else if (shader != null)
              RepaintBoundary(
                child: CustomPaint(
                  key: const ValueKey('shader-showcase-canvas'),
                  painter: _ShaderPainter(
                    shader: shader,
                    animation: _animation,
                    effect: _effect,
                    speed: widget.speed,
                    intensity: widget.intensity,
                  ),
                ),
              )
            else
              const ColoredBox(color: Color(0xFF080B18)),
            if (widget.showControls)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildControls(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader _shader;
  final Animation<double> _animation;
  final ShaderEffect _effect;
  final double _intensity;
  final double _speedMultiplier;
  final Paint _paint;

  _ShaderPainter({
    required ui.FragmentShader shader,
    required Animation<double> animation,
    required ShaderEffect effect,
    required double speed,
    required double intensity,
  }) : _shader = shader,
       _animation = animation,
       _effect = effect,
       _intensity = intensity,
       _speedMultiplier = speed,
       _paint = Paint()..shader = shader,
       super(repaint: animation) {
    // Static uniforms (3-10) set once here; the shader is shared across
    // rebuilds, so colors follow from _effect and intensity is tracked too.
    shader
      ..setFloat(3, effect.index.toDouble())
      ..setFloat(4, intensity)
      ..setFloat(5, effect.colorA.r)
      ..setFloat(6, effect.colorA.g)
      ..setFloat(7, effect.colorA.b)
      ..setFloat(8, effect.colorB.r)
      ..setFloat(9, effect.colorB.g)
      ..setFloat(10, effect.colorB.b);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, _animation.value * 3600 * _speedMultiplier);
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(_ShaderPainter oldDelegate) =>
      oldDelegate._effect != _effect ||
      oldDelegate._intensity != _intensity ||
      oldDelegate._speedMultiplier != _speedMultiplier;
}

class _VolumetricSmokePainter extends CustomPainter {
  final ui.FragmentShader _shader;
  late final Animation<double> _animation;
  final double _intensity;
  final double _quality;
  final double _speedMultiplier;
  late final Paint _paint;

  _VolumetricSmokePainter({
    required this._shader,
    required Animation<double> animation,
    required Listenable repaint,
    required double speed,
    required double intensity,
    required double quality,
  }) : _intensity = intensity,
       _quality = quality,
       _speedMultiplier = speed,
       super(repaint: repaint) {
    _animation = animation;
    _paint = Paint()..shader = _shader;
    // volumetric_smoke.frag slots: uSize 0-1, uTime 2, uIntensity 3,
    // uQuality 4.
    _shader
      ..setFloat(3, intensity)
      ..setFloat(4, quality);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, _animation.value * 3600 * _speedMultiplier);
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(_VolumetricSmokePainter oldDelegate) =>
      oldDelegate._shader != _shader ||
      oldDelegate._intensity != _intensity ||
      oldDelegate._quality != _quality ||
      oldDelegate._speedMultiplier != _speedMultiplier;
}

class _FrameRateLimiter extends ChangeNotifier {
  final Animation<double> _animation;
  final double _minimumDeltaSeconds;

  double? _lastNotificationSeconds;

  _FrameRateLimiter({
    required Animation<double> animation,
    required double maxFramesPerSecond,
  }) : _animation = animation,
       _minimumDeltaSeconds = 1 / maxFramesPerSecond {
    animation.addListener(_handleTick);
  }

  void _handleTick() {
    final seconds = _animation.value * 3600;
    final lastSeconds = _lastNotificationSeconds;
    if (lastSeconds == null ||
        seconds < lastSeconds ||
        seconds - lastSeconds >= _minimumDeltaSeconds) {
      _lastNotificationSeconds = seconds;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _animation.removeListener(_handleTick);
    super.dispose();
  }
}
