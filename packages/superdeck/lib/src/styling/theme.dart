import 'package:flutter/material.dart';

// TODO: Replace with Remix
ThemeData get theme => ThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSeed(
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  dialogTheme: const DialogThemeData(backgroundColor: Colors.black),
);
