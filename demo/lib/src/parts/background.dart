import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';
import 'package:superdeck/superdeck.dart';

OMeshRect _meshBuilder(List<Color> colors) {
  return OMeshRect(
    width: 3,
    height: 3,
    fallbackColor: const Color(0xff0e0e0e),
    backgroundColor: const Color(0x00d6d6d6),
    vertices: [
      (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, // Row 1

      (0.0, 0.5).v, (0.5, 0.5).v, (1.0, 0.5).v, // Row 2

      (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, // Row 3
    ],
    colors: colors,
  );
}

class BackgroundPart extends StatelessWidget {
  const BackgroundPart({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final configuration = SlideConfiguration.of(context);

    return _AnimatedSwitcherOMesh(
      slide: configuration,
    );
  }
}

// animate bwett colors and previous colors in duration
class _AnimatedSwitcherOMesh extends StatefulWidget {
  final SlideConfiguration slide;

  const _AnimatedSwitcherOMesh({
    required this.slide,
  });

  @override
  _AnimatedSwitcherOMeshState createState() => _AnimatedSwitcherOMeshState();
}

class _AnimatedSwitcherOMeshState extends State<_AnimatedSwitcherOMesh>
    with SingleTickerProviderStateMixin {
  late List<Color> _colors;

  final _duration = const Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _colors = _determiniscOrderBasedOnIndex(widget.slide.slideIndex);
  }

  @override
  void didUpdateWidget(covariant _AnimatedSwitcherOMesh oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.slide.slideIndex != oldWidget.slide.slideIndex) {
      setState(() {
        _colors = _determiniscOrderBasedOnIndex(widget.slide.slideIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOMeshGradient(
      mesh: _meshBuilder(_colors),
      duration: _duration,
    );
  }
}

final _buildColors = [
  const Color.fromARGB(255, 5, 10, 18), // very dark blue
  const Color.fromARGB(255, 8, 18, 28), // dark aqua-blue
  const Color.fromARGB(255, 10, 22, 35), // dark cyan-blue
  const Color.fromARGB(255, 12, 30, 48), // teal/blue (replaces purple)
  const Color.fromARGB(255, 15, 40, 58), // deeper cyan (replaces purple)
  const Color.fromARGB(255, 8, 18, 26), // dark aqua
  const Color.fromARGB(255, 5, 12, 20), // very dark aqua
  const Color.fromARGB(255, 0, 0, 0), // black anchor
  const Color.fromARGB(255, 5, 5, 5), // near black anchor
];
List<Color> _determiniscOrderBasedOnIndex(int index) {
  return _buildColors.sublist(index % _buildColors.length)
    ..addAll(_buildColors.sublist(0, index % _buildColors.length));
}
