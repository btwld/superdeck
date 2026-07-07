import 'package:google_fonts/google_fonts.dart';

/// Safely loads a Google Font and returns its family name.
///
/// Returns `null` if the font cannot be loaded (e.g., invalid name,
/// network error, or font not available in GoogleFonts package).
String? tryGetGoogleFontFamily(String fontName) {
  try {
    return GoogleFonts.getFont(fontName).fontFamily;
  } catch (_) {
    return null;
  }
}
