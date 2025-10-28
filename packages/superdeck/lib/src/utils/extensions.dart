import 'package:flutter/material.dart'
    show TextTheme, ThemeData, ColorScheme, Theme;
import 'package:flutter/widgets.dart';

extension BuildContextX on BuildContext {
  // TODO: Replace with Remix
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}
