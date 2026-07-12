import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

extension BlockInsetsExtension on BlockInsets {
  EdgeInsets get toEdgeInsets => EdgeInsets.fromLTRB(left, top, right, bottom);
}

extension ImageFitExtension on ImageFit {
  BoxFit get toBoxFit {
    return switch (this) {
      ImageFit.fill => BoxFit.fill,
      ImageFit.contain => BoxFit.contain,
      ImageFit.cover => BoxFit.cover,
      ImageFit.fitWidth => BoxFit.fitWidth,
      ImageFit.fitHeight => BoxFit.fitHeight,
      ImageFit.none => BoxFit.none,
      ImageFit.scaleDown => BoxFit.scaleDown,
    };
  }
}

extension ContentAlignmentExtension on ContentAlignment {
  Alignment get toAlignment {
    return switch (this) {
      ContentAlignment.topLeft => Alignment.topLeft,
      ContentAlignment.topCenter => Alignment.topCenter,
      ContentAlignment.topRight => Alignment.topRight,
      ContentAlignment.centerLeft => Alignment.centerLeft,
      ContentAlignment.center => Alignment.center,
      ContentAlignment.centerRight => Alignment.centerRight,
      ContentAlignment.bottomLeft => Alignment.bottomLeft,
      ContentAlignment.bottomCenter => Alignment.bottomCenter,
      ContentAlignment.bottomRight => Alignment.bottomRight,
    };
  }
}

/// Converts a hex color string to a [Color].
///
/// Accepts 6-digit RGB (`"ff0000"`) or 8-digit ARGB (`"80ff0000"`).
/// The `#` prefix is optional. 6-digit values default to fully opaque.
Color hexToColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  final fullHex = hexCode.length == 6 ? 'FF$hexCode' : hexCode;
  return Color(int.parse(fullHex, radix: 16));
}
