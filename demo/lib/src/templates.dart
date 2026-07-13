import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

import 'google_font_helpers.dart';

/// A corporate-style template with a branded header and subtle footer.
SlideTemplate corporateTemplate() {
  return SlideTemplate(
    baseStyle: SlideStyler(
      h1: TextStyler().style(
        TextStyleMix(
          fontFamily: safeGoogleFontFamily(GoogleFonts.poppins),
          fontSize: 64,
          fontWeight: FontWeight.bold,
        ),
      ),
      h2: TextStyler().style(
        TextStyleMix(
          fontFamily: safeGoogleFontFamily(GoogleFonts.poppins),
          fontSize: 40,
          fontWeight: FontWeight.w500,
        ),
      ),
      p: TextStyler().style(
        TextStyleMix(
          fontFamily: safeGoogleFontFamily(GoogleFonts.inter),
          fontSize: 24,
        ),
      ),
    ),
    styles: {
      'highlight': SlideStyler(
        h1: TextStyler().style(
          TextStyleMix(
            color: const Color(0xFF1A73E8),
            fontSize: 72,
            fontWeight: FontWeight.w900,
          ),
        ),
        blockContainer: BlockStyler(
          decoration: BoxDecorationMix(
            gradient: LinearGradientMix(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    },
    parts: const SlideParts(
      header: _CorporateHeader(),
      footer: _CorporateFooter(),
    ),
  );
}

/// A minimal template with no chrome — just typography.
SlideTemplate minimalTemplate() {
  return SlideTemplate(
    baseStyle: SlideStyler(
      h1: TextStyler().style(
        TextStyleMix(
          fontFamily: safeGoogleFontFamily(GoogleFonts.notoSerif),
          fontSize: 48,
          fontWeight: FontWeight.w300,
        ),
      ),
      p: TextStyler().style(
        TextStyleMix(
          fontFamily: safeGoogleFontFamily(GoogleFonts.notoSerif),
          fontSize: 22,
          height: 1.8,
        ),
      ),
    ),
  );
}

class _CorporateHeader extends StatelessWidget implements PreferredSizeWidget {
  const _CorporateHeader();

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final slide = SlideConfiguration.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          const Icon(Icons.business, color: Color(0xFF1A73E8), size: 28),
          const SizedBox(width: 12),
          if (slide.options.title != null)
            Text(
              slide.options.title!,
              style: safeGoogleFont(
                () => GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                fallback: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          const Spacer(),
          Text(
            '${slide.slideIndex + 1}',
            style: safeGoogleFont(
              () => GoogleFonts.poppins(fontSize: 16, color: Colors.white38),
              fallback: const TextStyle(fontSize: 16, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

class _CorporateFooter extends StatelessWidget implements PreferredSizeWidget {
  const _CorporateFooter();

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Text(
            'SuperDeck Corp',
            style: safeGoogleFont(
              () => GoogleFonts.inter(fontSize: 14, color: Colors.white30),
              fallback: const TextStyle(fontSize: 14, color: Colors.white30),
            ),
          ),
          const Spacer(),
          Text(
            'Confidential',
            style: safeGoogleFont(
              () => GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white24,
                fontStyle: FontStyle.italic,
              ),
              fallback: const TextStyle(
                fontSize: 12,
                color: Colors.white24,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
