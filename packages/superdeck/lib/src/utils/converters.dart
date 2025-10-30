import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

class ConverterHelper {
  /// Calculates the total spacing offset from padding, margin, and border.
  ///
  /// Returns the combined horizontal and vertical spacing that reduces
  /// the available content area within a block.
  static Offset calculateBlockOffset(BoxSpec spec) {
    final padding = spec.padding ?? EdgeInsets.zero;
    final margin = spec.margin ?? EdgeInsets.zero;

    // Extract border dimensions if present
    final borderDimensions = spec.decoration is BoxDecoration
        ? (spec.decoration as BoxDecoration).border?.dimensions
        : null;

    return Offset(
      padding.horizontal + margin.horizontal + (borderDimensions?.horizontal ?? 0.0),
      padding.vertical + margin.vertical + (borderDimensions?.vertical ?? 0.0),
    );
  }

  static BoxFit toBoxFit(ImageFit fit) {
    return switch (fit) {
      ImageFit.fill => BoxFit.fill,
      ImageFit.contain => BoxFit.contain,
      ImageFit.cover => BoxFit.cover,
      ImageFit.fitWidth => BoxFit.fitWidth,
      ImageFit.fitHeight => BoxFit.fitHeight,
      ImageFit.none => BoxFit.none,
      ImageFit.scaleDown => BoxFit.scaleDown,
    };
  }

  static Alignment toAlignment(ContentAlignment? alignment) {
    if (alignment == null) {
      return Alignment.center;
    }
    return switch (alignment) {
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

  static (MainAxisAlignment mainAxis, CrossAxisAlignment crossAxis)
  toFlexAlignment(Axis axis, ContentAlignment alignment) {
    // For horizontal axis (Row): main = horizontal, cross = vertical
    // For vertical axis (Column): main = vertical, cross = horizontal
    // Note: vertical alignment is inverted for columns (end = top, start = bottom)
    final isHorizontal = axis == Axis.horizontal;

    if (isHorizontal) {
      return switch (alignment) {
        ContentAlignment.topLeft => (MainAxisAlignment.start, CrossAxisAlignment.start),
        ContentAlignment.topCenter => (MainAxisAlignment.center, CrossAxisAlignment.start),
        ContentAlignment.topRight => (MainAxisAlignment.end, CrossAxisAlignment.start),
        ContentAlignment.centerLeft => (MainAxisAlignment.start, CrossAxisAlignment.center),
        ContentAlignment.center => (MainAxisAlignment.center, CrossAxisAlignment.center),
        ContentAlignment.centerRight => (MainAxisAlignment.end, CrossAxisAlignment.center),
        ContentAlignment.bottomLeft => (MainAxisAlignment.start, CrossAxisAlignment.end),
        ContentAlignment.bottomCenter => (MainAxisAlignment.center, CrossAxisAlignment.end),
        ContentAlignment.bottomRight => (MainAxisAlignment.end, CrossAxisAlignment.end),
      };
    } else {
      // Column: vertical main axis requires inverted alignment
      return switch (alignment) {
        ContentAlignment.topLeft => (MainAxisAlignment.start, CrossAxisAlignment.start),
        ContentAlignment.topCenter => (MainAxisAlignment.start, CrossAxisAlignment.center),
        ContentAlignment.topRight => (MainAxisAlignment.start, CrossAxisAlignment.end),
        ContentAlignment.centerLeft => (MainAxisAlignment.center, CrossAxisAlignment.start),
        ContentAlignment.center => (MainAxisAlignment.center, CrossAxisAlignment.center),
        ContentAlignment.centerRight => (MainAxisAlignment.center, CrossAxisAlignment.end),
        ContentAlignment.bottomLeft => (MainAxisAlignment.end, CrossAxisAlignment.start),
        ContentAlignment.bottomCenter => (MainAxisAlignment.end, CrossAxisAlignment.center),
        ContentAlignment.bottomRight => (MainAxisAlignment.end, CrossAxisAlignment.end),
      };
    }
  }

  static (MainAxisAlignment mainAxis, CrossAxisAlignment crossAxis)
  toRowAlignment(ContentAlignment alignment) {
    return toFlexAlignment(Axis.horizontal, alignment);
  }

  static (MainAxisAlignment mainAxis, CrossAxisAlignment crossAxis)
  toColumnAlignment(ContentAlignment alignment) {
    return toFlexAlignment(Axis.vertical, alignment);
  }
}

/// Converts a hex color string to a Color object.
///
/// Supports:
/// - 6 digit RGB: "#ff0000" or "ff0000" → opaque color
/// - 8 digit RGBA: "#80ff0000" or "80ff0000" → color with alpha
///
/// The '#' prefix is optional. For 6-digit hex, alpha is set to FF (fully opaque).
Color hexToColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  final fullHex = hexCode.length == 6 ? 'FF$hexCode' : hexCode;
  return Color(int.parse(fullHex, radix: 16));
}
