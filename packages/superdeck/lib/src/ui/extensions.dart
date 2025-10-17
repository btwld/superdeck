import 'package:flutter/material.dart';

/// Extension methods on BuildContext for UI utilities.
extension BuildContextExt on BuildContext {
  /// Returns true if the current screen width is considered small (< 600px).
  bool get isSmall => MediaQuery.sizeOf(this).width < 600;
}
