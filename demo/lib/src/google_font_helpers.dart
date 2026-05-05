import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle safeGoogleFont(
  TextStyle Function() fontLoader, {
  TextStyle fallback = const TextStyle(),
}) {
  if (!GoogleFonts.config.allowRuntimeFetching) {
    return fallback;
  }

  return fontLoader();
}

String? safeGoogleFontFamily(TextStyle Function() fontLoader) {
  if (!GoogleFonts.config.allowRuntimeFetching) {
    return null;
  }

  return fontLoader().fontFamily;
}
