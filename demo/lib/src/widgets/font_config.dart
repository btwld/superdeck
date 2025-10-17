import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font configurations for demo widgets.
///
/// Provides consistent font styling across all demo examples
/// for Mix, Naked UI, and Remix components.
class DemoFonts {
  DemoFonts._();

  // Mix examples use a modern, geometric sans-serif
  static TextStyle get mixFont => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static String? get mixFontFamily => GoogleFonts.inter().fontFamily;

  // Naked UI examples use a clean, accessible sans-serif
  static TextStyle get nakedFont => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static String? get nakedFontFamily => GoogleFonts.roboto().fontFamily;

  // Remix examples use a professional system font
  static TextStyle get remixFont => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static String? get remixFontFamily => GoogleFonts.poppins().fontFamily;

  // Code examples use monospace
  static TextStyle get codeFont =>
      GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w400);

  static String? get codeFontFamily => GoogleFonts.jetBrainsMono().fontFamily;

  // Heading font for demo titles
  static TextStyle get headingFont => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
}
