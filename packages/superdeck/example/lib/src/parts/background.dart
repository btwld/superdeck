import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';
import 'package:superdeck/superdeck.dart';

// Color _colorFromHex(String hexString) {
//   hexString = hexString.trim();
//   if (hexString.isEmpty) {
//     return Colors.black; // Default color if null or empty
//   }
//   hexString = hexString.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
//   hexString = hexString.replaceAll('#', '');
//   if (hexString.length == 6) {
//     hexString = 'FF$hexString'; // Add opacity if not provided
//   }
//   return Color(int.parse(hexString, radix: 16));
// }

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
  const Color.fromARGB(255, 5, 5, 28),
  const Color.fromARGB(255, 5, 5, 5),
  const Color.fromARGB(255, 3, 19, 48),
  const Color.fromARGB(255, 41, 12, 56),
  const Color.fromARGB(255, 5, 5, 5),
  const Color.fromARGB(255, 5, 5, 5),
  const Color.fromARGB(255, 17, 0, 63),
  const Color.fromARGB(255, 0, 0, 0),
  const Color.fromARGB(255, 5, 5, 5),
];
List<Color> _determiniscOrderBasedOnIndex(int index) {
  return _buildColors.sublist(index % _buildColors.length)
    ..addAll(_buildColors.sublist(0, index % _buildColors.length));
}
