import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

class BaseStyle extends DeckStyle {
  BaseStyle();

  @override
  Style build() {
    return super.build().merge(
          Style(
              // $.baseTextStyle.as(GoogleFonts.poppins()),
              // $.h1.chain
              //   ..style.fontWeight.w900()
              //   ..style.fontSize(100),
              // $.h2.chain
              //   ..style.fontWeight.w100()
              //   ..style.fontSize(80),
              // $.h3.chain..style.fontSize(36),
              // $.alert.all.chain
              //   ..heading.style.fontSize(24)
              //   ..icon.size(36)
              //   ..description.style.fontSize(24)
              //   ..description.style.fontWeight.w400(),
              // $.alert.note.chain
              //   ..heading.style.color(_accent)
              //   ..icon.color(_accent)
              //   ..container.border.left.color(_accent),
              // $.code.chain
              //   ..textStyle.as(GoogleFonts.jetBrainsMono())
              //   ..decoration.color(
              //     const Color.fromARGB(255, 3, 17, 19),
              //   )
              //   ..decoration.border.all(
              //         color: const Color.fromARGB(255, 6, 49, 50),
              //         width: 1,
              //       ),
              ),
        );
  }
}

class CoverStyle extends DeckStyle {
  CoverStyle();

  @override
  Style build() {
    return super.build().merge(
          Style(
            $.h1.chain
              ..style.as(GoogleFonts.poppins())
              ..style.fontSize(100),
            $.blockContainer.gradient.linear(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.useOpacity(0.5),
                Colors.black.useOpacity(0.95),
              ],
            ),
          ),
        );
  }
}

class AnnouncementStyle extends DeckStyle {
  AnnouncementStyle();
  @override
  Style build() {
    return super.build().merge(
          Style(
            $.baseTextStyle.height(0.6),
            $.h1.chain
              ..style.fontSize(140)
              ..style.bold()
              ..style.color(const Color.fromARGB(255, 201, 195, 139)),
            $.h2.style.fontSize(140),
            $.h3.chain
              ..style.fontSize(60)
              ..style.color(Colors.white)
              ..style.fontWeight(FontWeight.w100),
            $.blockContainer.gradient.linear(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.useOpacity(0.5),
                Colors.black.useOpacity(0.95),
              ],
            ),
          ),
        );
  }
}

class QuoteStyle extends DeckStyle {
  QuoteStyle();
  @override
  Style build() {
    return super.build().merge(
          Style(
            $.blockquote.chain
              ..textStyle.as(GoogleFonts.notoSerif())
              ..decoration.border.left(
                    width: 4,
                    color: Colors.red,
                  ),
            $.p.style.fontSize(32),
            $.h6.chain
              ..style.as(GoogleFonts.notoSerif())
              ..style.fontSize(20),
          ),
        );
  }
}
