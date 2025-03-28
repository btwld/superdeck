import 'package:flutter/material.dart';
import 'package:superdeck/src/modules/deck/slide_configuration.dart';

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

class BackgroundPart extends StatelessWidget {
  const BackgroundPart({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final configuration = SlideConfiguration.of(context);

    return const SizedBox.shrink();
  }
}
