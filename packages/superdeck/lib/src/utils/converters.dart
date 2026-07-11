import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

extension BlockInsetsExtension on BlockInsets {
  EdgeInsets get toEdgeInsets => EdgeInsets.fromLTRB(left, top, right, bottom);
}

extension BoxSpecOffsetExtension on BoxSpec {
  /// Calculates the total spacing offset from padding, margin, and border.
  Offset get calculateBlockOffset {
    final paddingX = padding?.horizontal ?? 0.0;
    final paddingY = padding?.vertical ?? 0.0;
    final marginX = margin?.horizontal ?? 0.0;
    final marginY = margin?.vertical ?? 0.0;

    final borderDimensions = decoration is BoxDecoration
        ? (decoration as BoxDecoration).border?.dimensions
        : null;

    final borderX = borderDimensions?.horizontal ?? 0.0;
    final borderY = borderDimensions?.vertical ?? 0.0;

    return Offset(paddingX + marginX + borderX, paddingY + marginY + borderY);
  }
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

  // ignore: unused-code
  (MainAxisAlignment mainAxis, CrossAxisAlignment crossAxis) toFlexAlignment(
    Axis axis,
  ) {
    final isHorizontal = axis == Axis.horizontal;

    if (isHorizontal) {
      return switch (this) {
        ContentAlignment.topLeft => (
          MainAxisAlignment.start,
          CrossAxisAlignment.start,
        ),
        ContentAlignment.topCenter => (
          MainAxisAlignment.center,
          CrossAxisAlignment.start,
        ),
        ContentAlignment.topRight => (
          MainAxisAlignment.end,
          CrossAxisAlignment.start,
        ),
        ContentAlignment.centerLeft => (
          MainAxisAlignment.start,
          CrossAxisAlignment.center,
        ),
        ContentAlignment.center => (
          MainAxisAlignment.center,
          CrossAxisAlignment.center,
        ),
        ContentAlignment.centerRight => (
          MainAxisAlignment.end,
          CrossAxisAlignment.center,
        ),
        ContentAlignment.bottomLeft => (
          MainAxisAlignment.start,
          CrossAxisAlignment.end,
        ),
        ContentAlignment.bottomCenter => (
          MainAxisAlignment.center,
          CrossAxisAlignment.end,
        ),
        ContentAlignment.bottomRight => (
          MainAxisAlignment.end,
          CrossAxisAlignment.end,
        ),
      };
    } else {
      return switch (this) {
        ContentAlignment.topLeft => (
          MainAxisAlignment.start,
          CrossAxisAlignment.start,
        ),
        ContentAlignment.topCenter => (
          MainAxisAlignment.start,
          CrossAxisAlignment.center,
        ),
        ContentAlignment.topRight => (
          MainAxisAlignment.start,
          CrossAxisAlignment.end,
        ),
        ContentAlignment.centerLeft => (
          MainAxisAlignment.center,
          CrossAxisAlignment.start,
        ),
        ContentAlignment.center => (
          MainAxisAlignment.center,
          CrossAxisAlignment.center,
        ),
        ContentAlignment.centerRight => (
          MainAxisAlignment.center,
          CrossAxisAlignment.end,
        ),
        ContentAlignment.bottomLeft => (
          MainAxisAlignment.end,
          CrossAxisAlignment.start,
        ),
        ContentAlignment.bottomCenter => (
          MainAxisAlignment.end,
          CrossAxisAlignment.center,
        ),
        ContentAlignment.bottomRight => (
          MainAxisAlignment.end,
          CrossAxisAlignment.end,
        ),
      };
    }
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
