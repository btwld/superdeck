import 'package:flutter/material.dart'
    show TextTheme, ThemeData, ColorScheme, Theme;
import 'package:flutter/widgets.dart';

/// Extension methods on BuildContext for UI utilities.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns true if the current screen width is considered small (< 600px).
  bool get isSmall => MediaQuery.sizeOf(this).width < 600;
}
