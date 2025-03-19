import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}

extension ColorX on Color {
  Color useOpacity(double opacity) => withAlpha((255.0 * opacity).round());
}
