import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

SlideStyle coverStyle() {
  return SlideStyle(
    h1: TextStyler().style(TextStyleMix(
      fontFamily: GoogleFonts.poppins().fontFamily,
      fontSize: 100,
    )),
    blockContainer: BoxStyler(
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

SlideStyle announcementStyle() {
  return SlideStyle(
    h1: TextStyler().style(TextStyleMix(
      fontSize: 140,
      fontWeight: FontWeight.bold,
      color: const Color.fromARGB(255, 201, 195, 139),
      height: 0.6,
    )),
    h2: TextStyler().style(TextStyleMix(
      fontSize: 140,
      height: 0.6,
    )),
    h3: TextStyler().style(TextStyleMix(
      fontSize: 60,
      color: Colors.white,
      fontWeight: FontWeight.w100,
    )),
    blockContainer: BoxStyler(
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

SlideStyle quoteStyle() {
  return SlideStyle(
    h1: TextStyler().style(TextStyleMix(
      fontFamily: GoogleFonts.notoSerif().fontFamily,
      fontSize: 32,
    )),
    blockquote: MarkdownBlockquoteStyle(
      textStyle: GoogleFonts.notoSerif(fontSize: 32),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.red, width: 4),
        ),
      ),
    ),
    p: TextStyler().style(TextStyleMix(fontSize: 32)),
    h6: TextStyler().style(TextStyleMix(
      fontFamily: GoogleFonts.notoSerif().fontFamily,
      fontSize: 20,
    )),
  );
}
