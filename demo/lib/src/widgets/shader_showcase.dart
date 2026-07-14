import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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
  heatAirflow(
    'Heat · Airflow',
    ShaderMood.dramatic,
    'Organic convective vapor',
    Color(0xFFFFC46B),
    Color(0xFFB42318),
  ),
  heatHaze(
    'Heat · Haze',
    ShaderMood.subtle,
    'Convective mirage shimmer',
    Color(0xFFFFD99A),
    Color(0xFFFF6B35),
  ),
  heatRadiance(
    'Heat · Radiance',
    ShaderMood.subtle,
    'Expanding thermal waves',
    Color(0xFFFFE3A3),
    Color(0xFFFF7A1A),
  ),
  coldAirflow(
    'Cold · Airflow',
    ShaderMood.dramatic,
    'Descending laminar jets',
    Color(0xFFD9FBFF),
    Color(0xFF0EA5E9),
  ),
  coldMist(
    'Cold · Mist',
    ShaderMood.dramatic,
    'Cascading chilled vapor',
    Color(0xFFBDEBFF),
    Color(0xFF2563EB),
  ),
  coldCrystal(
    'Cold · Crystal',
    ShaderMood.subtle,
    'Growing faceted frost',
    Color(0xFFE6FDFF),
    Color(0xFF67E8F9),
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

  bool get usesThermalProgram =>
      index >= heatAirflow.index && index <= coldCrystal.index;

  int get programIndex =>
      usesThermalProgram ? index - heatAirflow.index : index;

  bool get isAirflow => this == heatAirflow || this == coldAirflow;
}

class ShaderShowcase extends StatefulWidget {
  final ShaderEffect effect;
  final bool showControls;
  final bool showReadout;
  final bool showStrengthControl;
  final double speed;
  final double intensity;
  final double quality;

  const ShaderShowcase({
    super.key,
    this.effect = ShaderEffect.aurora,
    this.showControls = true,
    this.showReadout = false,
    this.showStrengthControl = false,
    this.speed = 1,
    this.intensity = 1,
    this.quality = 0.5,
  }) : assert(speed > 0),
       assert(intensity >= 0),
       assert(quality >= 0 && quality <= 1);

  factory ShaderShowcase.fromArgs(Map<String, Object?> args) => ShaderShowcase(
    effect: ShaderEffect.parse(args['effect'] as String? ?? 'aurora'),
    showControls: args['showControls'] as bool? ?? true,
    showReadout: args['showReadout'] as bool? ?? false,
    showStrengthControl: args['showStrengthControl'] as bool? ?? false,
    speed: (args['speed'] as num?)?.toDouble() ?? 1,
    intensity: (args['intensity'] as num?)?.toDouble() ?? 1,
    quality: (args['quality'] as num?)?.toDouble() ?? 0.5,
  );

  @override
  State<ShaderShowcase> createState() => _ShaderShowcaseState();
}

class _ShaderShowcaseState extends State<ShaderShowcase>
    with TickerProviderStateMixin {
  static const _strengthSpring = SpringDescription(
    mass: 1,
    stiffness: 55,
    damping: 16,
  );
  static final Future<ui.FragmentProgram> _program =
      ui.FragmentProgram.fromAsset('shaders/shader_showcase.frag');
  static final Future<ui.FragmentProgram> _thermalProgram =
      ui.FragmentProgram.fromAsset('shaders/thermal_showcase.frag');
  static final Future<ui.FragmentProgram> _heatRefractionProgram =
      ui.FragmentProgram.fromAsset('shaders/heat_refraction.frag');
  static final Future<ui.FragmentProgram> _volumetricSmokeProgram =
      ui.FragmentProgram.fromAsset('shaders/volumetric_smoke.frag');

  final _menuKey = GlobalKey<PopupMenuButtonState<ShaderEffect>>();
  late final AnimationController _animation;
  late final AnimationController _strengthAnimation;
  late final _FlowClock _flowClock;
  late final _FrameRateLimiter _limitedRepaint;
  late ShaderEffect _effect;
  late double _targetIntensity;
  // Created once when the program resolves and reused across rebuilds — avoids
  // allocating a fresh shader per build and makes shouldRepaint meaningful.
  ui.FragmentShader? _shader;
  ui.FragmentShader? _thermalShader;
  ui.FragmentShader? _heatRefractionShader;
  ui.FragmentShader? _volumetricSmokeShader;
  Future<void>? _shaderLoad;
  Future<void>? _thermalShaderLoad;
  Future<void>? _heatRefractionShaderLoad;
  Future<void>? _volumetricSmokeShaderLoad;

  void _loadShaderFor(ShaderEffect effect) {
    if (effect == ShaderEffect.volumetricSmoke) {
      _volumetricSmokeShaderLoad ??= _volumetricSmokeProgram.then((program) {
        if (mounted) {
          setState(() => _volumetricSmokeShader = program.fragmentShader());
        }
      });
    } else if (effect.usesThermalProgram) {
      _thermalShaderLoad ??= _thermalProgram.then((program) {
        if (mounted) setState(() => _thermalShader = program.fragmentShader());
      });
      if (effect == ShaderEffect.heatAirflow) {
        _heatRefractionShaderLoad ??= _heatRefractionProgram.then((program) {
          if (mounted) {
            setState(() => _heatRefractionShader = program.fragmentShader());
          }
        });
      }
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

  void _animateIntensityTo(double target) {
    final distance = target - _strengthAnimation.value;
    final velocity = _strengthAnimation.velocity;
    final isMovingTowardTarget =
        distance != 0 &&
        velocity != 0 &&
        distance.isNegative == velocity.isNegative;
    final carriedVelocity = isMovingTowardTarget
        ? velocity.clamp(-1.5, 1.5).toDouble()
        : 0.0;
    _strengthAnimation.animateWith(
      SpringSimulation(
        _strengthSpring,
        _strengthAnimation.value,
        target,
        carriedVelocity,
      ),
    );
  }

  void _setIntensity(double value) {
    final target = value.clamp(0.0, 1.0);
    if (_targetIntensity == target) return;
    setState(() => _targetIntensity = target);
    _animateIntensityTo(target);
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

  Widget _buildShaderCanvas(ui.FragmentShader shader, double intensity) {
    Widget canvas = RepaintBoundary(
      child: CustomPaint(
        key: const ValueKey('shader-showcase-canvas'),
        painter: _ShaderPainter(
          shader: shader,
          animation: _animation,
          flowClock: _flowClock,
          effect: _effect,
          speed: widget.speed,
          intensity: intensity,
        ),
      ),
    );
    final refractionShader = _heatRefractionShader;
    if (_effect == ShaderEffect.heatAirflow &&
        refractionShader != null &&
        ui.ImageFilter.isShaderFilterSupported) {
      canvas = _HeatRefractionFilter(
        shader: refractionShader,
        flowClock: _flowClock,
        repaint: _limitedRepaint,
        speed: widget.speed,
        intensity: intensity,
        child: canvas,
      );
    }
    return canvas;
  }

  @override
  void initState() {
    super.initState();
    _effect = widget.effect;
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    );
    _targetIntensity = widget.intensity;
    _strengthAnimation = AnimationController.unbounded(
      vsync: this,
      value: _targetIntensity,
    );
    _flowClock = _FlowClock(
      animation: _animation,
      intensity: _strengthAnimation,
    );
    _limitedRepaint = _FrameRateLimiter(
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
    if (oldWidget.intensity != widget.intensity) {
      _targetIntensity = widget.intensity;
      _animateIntensityTo(_targetIntensity);
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    _thermalShader?.dispose();
    _heatRefractionShader?.dispose();
    _volumetricSmokeShader?.dispose();
    _limitedRepaint.dispose();
    _flowClock.dispose();
    _strengthAnimation.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _effect.usesThermalProgram ? _thermalShader : _shader;
    final volumetricSmokeShader = _volumetricSmokeShader;
    return AnimatedBuilder(
      animation: _strengthAnimation,
      builder: (context, _) {
        final intensity = _strengthAnimation.value;
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
                          repaint: _limitedRepaint,
                          speed: widget.speed,
                          intensity: intensity,
                          quality: widget.quality,
                        ),
                      ),
                    )
                  else
                    const ColoredBox(color: Color(0xFF080B18))
                else if (shader != null)
                  _buildShaderCanvas(shader, intensity)
                else
                  const ColoredBox(color: Color(0xFF080B18)),
                if (widget.showReadout && _effect.isAirflow)
                  _AirflowReadout(
                    effect: _effect,
                    intensity: intensity,
                    showStrengthControl: widget.showStrengthControl,
                    strengthValue: _targetIntensity.clamp(0.0, 1.0),
                    onStrengthChanged: _setIntensity,
                  ),
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
      },
    );
  }
}

class _HeatRefractionFilter extends StatelessWidget {
  final ui.FragmentShader shader;
  final ValueListenable<double> flowClock;
  final Listenable repaint;
  final double speed;
  final double intensity;
  final Widget child;

  const _HeatRefractionFilter({
    required this.shader,
    required this.flowClock,
    required this.repaint,
    required this.speed,
    required this.intensity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repaint,
      child: child,
      builder: (context, filteredChild) {
        shader
          ..setFloat(2, flowClock.value * speed)
          ..setFloat(3, intensity);
        return ImageFiltered(
          imageFilter: ui.ImageFilter.shader(shader),
          child: filteredChild,
        );
      },
    );
  }
}

class _AirflowReadout extends StatelessWidget {
  final ShaderEffect effect;
  final double intensity;
  final bool showStrengthControl;
  final double strengthValue;
  final ValueChanged<double> onStrengthChanged;

  const _AirflowReadout({
    required this.effect,
    required this.intensity,
    required this.showStrengthControl,
    required this.strengthValue,
    required this.onStrengthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isHeat = effect == ShaderEffect.heatAirflow;
    final accent = isHeat ? const Color(0xFFFFC46B) : const Color(0xFF8DEBFF);
    final temperature = isHeat ? '28' : '18';
    final mode = isHeat ? 'HEATING' : 'COOLING';
    final powerLabel = switch (intensity) {
      < 0.4 => 'LOW',
      < 0.75 => 'MEDIUM',
      _ => 'HIGH',
    };
    final activeBars = (intensity.clamp(0.0, 1.0) * 5).ceil();
    final strengthPercent = (strengthValue * 100).round();

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: Semantics(
            label: '$mode, $temperature degrees, airflow $powerLabel',
            child: ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.07),
                              blurRadius: 52,
                              spreadRadius: -18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 64,
                    top: 54,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.65),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'THERMAL AIRFLOW',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.86),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mode,
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.90),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6.0,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              temperature,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 152,
                                fontWeight: FontWeight.w200,
                                height: 0.78,
                                letterSpacing: -8,
                              ),
                            ),
                            Text(
                              '°',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 66,
                                fontWeight: FontWeight.w200,
                                height: 0.82,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.air_rounded, color: accent, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'AIRFLOW  $powerLabel',
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.90),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.7,
                              ),
                            ),
                            const SizedBox(width: 18),
                            for (var index = 0; index < 5; index++) ...[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: accent.withValues(
                                    alpha: index < activeBars ? 0.90 : 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              if (index < 4) const SizedBox(width: 5),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 64,
                    bottom: 52,
                    child: Text(
                      isHeat ? 'WARM CURRENT' : 'CHILLED CURRENT',
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.52),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showStrengthControl)
          Positioned(
            left: 64,
            bottom: 36,
            child: SizedBox(
              width: 500,
              height: 40,
              child: Row(
                children: [
                  Text(
                    'OUTPUT',
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Semantics(
                      label: 'Airflow strength',
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          activeTrackColor: accent.withValues(alpha: 0.90),
                          inactiveTrackColor: accent.withValues(alpha: 0.18),
                          thumbColor: Colors.white,
                          overlayColor: accent.withValues(alpha: 0.12),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                        ),
                        child: Slider(
                          key: const ValueKey('airflow-strength-slider'),
                          value: strengthValue,
                          onChanged: onStrengthChanged,
                          semanticFormatterCallback: (value) =>
                              '${(value * 100).round()} percent',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '$strengthPercent%',
                      key: const ValueKey('airflow-strength-value'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader _shader;
  final Animation<double> _animation;
  final ValueListenable<double> _flowClock;
  final ShaderEffect _effect;
  final double _intensity;
  final double _speedMultiplier;
  final Paint _paint;

  _ShaderPainter({
    required ui.FragmentShader shader,
    required Animation<double> animation,
    required ValueListenable<double> flowClock,
    required ShaderEffect effect,
    required double speed,
    required double intensity,
  }) : _shader = shader,
       _animation = animation,
       _flowClock = flowClock,
       _effect = effect,
       _intensity = intensity,
       _speedMultiplier = speed,
       _paint = Paint()..shader = shader,
       super(repaint: effect.isAirflow ? flowClock : animation) {
    // Static uniforms (3-10) set once here; the shader is shared across
    // rebuilds, so colors follow from _effect and intensity is tracked too.
    shader
      ..setFloat(3, effect.programIndex.toDouble())
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
    final time = _effect.isAirflow ? _flowClock.value : _animation.value * 3600;
    _shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time * _speedMultiplier);
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

class _FlowClock extends ChangeNotifier implements ValueListenable<double> {
  static const _maximumDeltaSeconds = 1 / 15;

  final ValueListenable<double> intensity;

  final Animation<double> _animation;

  double? _lastAnimationSeconds;
  double _value = 0;

  _FlowClock({required Animation<double> animation, required this.intensity})
    : _animation = animation {
    animation.addListener(_handleTick);
  }

  void _handleTick() {
    final animationSeconds = _animation.value * 3600;
    final lastAnimationSeconds = _lastAnimationSeconds;
    _lastAnimationSeconds = animationSeconds;
    if (lastAnimationSeconds == null) return;

    var deltaSeconds = animationSeconds - lastAnimationSeconds;
    if (deltaSeconds < 0) deltaSeconds += 3600;
    deltaSeconds = deltaSeconds.clamp(0.0, _maximumDeltaSeconds).toDouble();

    final power = intensity.value.clamp(0.0, 1.0).toDouble();
    final energy = power * power * (3 - 2 * power);
    final rate = 0.42 + 1.43 * energy;
    _value += deltaSeconds * rate;
    notifyListeners();
  }

  @override
  double get value => _value;

  @override
  void dispose() {
    _animation.removeListener(_handleTick);
    super.dispose();
  }
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
