import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SwitchAnimation()),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class SwitchAnimation extends StatefulWidget {
  const SwitchAnimation({super.key});

  @override
  State<SwitchAnimation> createState() => _SwitchAnimationState();
}

class _SwitchAnimationState extends State<SwitchAnimation> {
  final ValueNotifier<bool> _trigger = ValueNotifier(false);

  @override
  void dispose() {
    _trigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simple implicit animation for the container
    final containerStyle = BoxStyler()
        .color(_trigger.value ? Colors.deepPurpleAccent : Colors.grey.shade300)
        .height(30)
        .width(65)
        .borderRadiusAll(Radius.circular(40))
        .alignment(
          _trigger.value ? Alignment.centerRight : Alignment.centerLeft,
        )
        .animate(AnimationConfig.easeOut(300.ms));

    // Complex keyframe animation for the thumb
    final thumbStyle = BoxStyler()
        .height(30)
        .width(40)
        .color(Colors.white)
        .foregroundRadialGradient(
          colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent],
          stops: [0.3, 1],
          focal: Alignment.center,
          focalRadius: 1.1,
        )
        .foregroundDecoration(
          BoxDecorationMix().borderRadius(
            BorderRadiusMix.all(Radius.circular(40)),
          ),
        )
        .borderRounded(40)
        .scale(0.85)
        .shadowOnly(
          color: Colors.black.withValues(alpha: 0.1),
          offset: Offset(2, 4),
          blurRadius: 4,
          spreadRadius: 3,
        )
        .keyframeAnimation(
          trigger: _trigger,
          timeline: [
            KeyframeTrack<double>('scale', [
              Keyframe.easeOutSine(1.25, 200.ms),
              Keyframe.elasticOut(0.85, 500.ms),
            ], initial: 0.85),
            KeyframeTrack<double>('width', [
              Keyframe.decelerate(50, 100.ms),
              Keyframe.linear(50, 100.ms),
              Keyframe.elasticOut(40, 500.ms),
            ], initial: 40),
          ],
          styleBuilder: (values, style) =>
              style.scale(values.get('scale')).width(values.get('width')),
        );

    return Center(
      child: Pressable(
        onPress: () {
          setState(() {
            _trigger.value = !_trigger.value;
          });
        },
        child: Box(
          style: containerStyle,
          child: Box(style: thumbStyle),
        ),
      ),
    );
  }
}
