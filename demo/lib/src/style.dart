import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

import 'google_font_helpers.dart';

SlideStyler announcementStyle() {
  return SlideStyler(
    h1: TextStyler().style(
      TextStyleMix(
        fontSize: 140,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 201, 195, 139),
        height: 0.6,
      ),
    ),
    h2: TextStyler().style(TextStyleMix(fontSize: 140, height: 0.6)),
    h3: TextStyler().style(
      TextStyleMix(
        fontSize: 60,
        color: Colors.white,
        fontWeight: FontWeight.w100,
      ),
    ),
    blockContainer: BlockStyler(
      decoration: BoxDecorationMix(
        gradient: LinearGradientMix(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.95),
          ],
        ),
      ),
    ),
  );
}

SlideStyler quoteStyle() {
  return SlideStyler(
    h1: TextStyler().style(
      TextStyleMix(
        fontFamily: safeGoogleFontFamily(GoogleFonts.notoSerif),
        fontSize: 32,
      ),
    ),
    blockquote: MarkdownBlockquoteStyler(
      textStyle: TextStyleMix.value(
        safeGoogleFont(
          () => GoogleFonts.notoSerif(fontSize: 32),
          fallback: const TextStyle(fontSize: 32),
        ),
      ),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.red, width: 4)),
      ),
    ),
    p: TextStyler().style(TextStyleMix(fontSize: 32)),
    h6: TextStyler().style(
      TextStyleMix(
        fontFamily: safeGoogleFontFamily(GoogleFonts.notoSerif),
        fontSize: 20,
      ),
    ),
  );
}

/// Decorated block containers so the layout demo slides can visibly
/// distinguish section spacing, block margin, and block padding.
SlideStyler boxedStyle() {
  return SlideStyler(
    blockContainer: BlockStyler(
      padding: EdgeInsetsGeometryMix.all(24),
      decoration: BoxDecorationMix(
        color: Colors.white.withValues(alpha: 0.06),
        border: BoxBorderMix.all(
          BorderSideMix(color: Colors.white38, width: 2),
        ),
        borderRadius: BorderRadiusMix.all(const Radius.circular(12)),
      ),
    ),
  );
}

SlideStyler borderedStyle() {
  return SlideStyler(
    modifier: WidgetModifierConfig(
      modifiers: [
        BoxModifierMix(
          BoxStyler(
            // No margin/padding - border goes to viewport edges
            decoration: BoxDecorationMix(
              border: BoxBorderMix.all(
                BorderSideMix(
                  color: Colors.white,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              borderRadius: BorderRadiusMix.all(Radius.circular(16)),
            ),
          ),
        ),
      ],
    ),
  );
}
