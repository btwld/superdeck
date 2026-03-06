import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';
import '../ai/schemas/deck_schemas.dart';
import './color_utils.dart';

/// Builds [DeckPresentation] from AI-generated style configuration.
///
/// Takes the style object from [DeckGenerationResult] and creates
/// [DeckPresentation] with appropriate [SlideStyle] overrides for colors,
/// fonts, and background.
DeckPresentation buildDeckPresentationFromStyle(DeckStyleType? style) {
  if (style == null) return const DeckPresentation();

  final colors = style.colors;
  final fonts = style.fonts;

  // Extract colors with new semantic names
  final backgroundHex = colors.background;
  final headingHex = colors.heading;
  final bodyHex = colors.body;

  final headingColor = hexToColor(headingHex);
  final bodyColor = hexToColor(bodyHex);
  final backgroundColor = hexToColor(backgroundHex);

  // Font enums already carry the concrete family names to use in text styles.
  final headlineFontFamily = fonts.headline.fontFamily;
  final bodyFontFamily = fonts.body.fontFamily;

  TextStyler headingStyler() {
    var styler = TextStyler().style(TextStyleMix(color: headingColor));
    if (headlineFontFamily.isNotEmpty) {
      styler = styler.style(TextStyleMix(fontFamily: headlineFontFamily));
    }
    return styler;
  }

  // Build body text styler with color and optional font
  TextStyler bodyStyler() {
    var styler = TextStyler().style(TextStyleMix(color: bodyColor));
    if (bodyFontFamily.isNotEmpty) {
      styler = styler.style(TextStyleMix(fontFamily: bodyFontFamily));
    }
    return styler;
  }

  // Create style with color and font overrides
  final colorOverrideStyle = SlideStyle(
    // Headings use primary color + headline font
    h1: headingStyler(),
    h2: headingStyler(),
    h3: headingStyler(),
    h4: headingStyler(),
    h5: headingStyler(),
    h6: headingStyler(),

    // Body text uses secondary color + body font
    p: bodyStyler(),

    // Links and emphasis use body/heading colors
    a: TextStyle(color: bodyColor),
    strong: TextStyle(color: headingColor),

    // List styling - bullets and text use body color
    list: MarkdownListStyle(
      bullet: TextStyler().style(TextStyleMix(color: bodyColor)),
      text: bodyStyler(),
    ),

    // Table styling - colors for text, borders, and cell backgrounds
    table: MarkdownTableStyle(
      headStyle: TextStyle(color: headingColor, fontWeight: FontWeight.bold),
      bodyStyle: TextStyle(color: bodyColor),
      cellPadding: const EdgeInsets.all(12),
      border: TableBorder.all(color: bodyColor, width: 2),
      cellDecoration: BoxDecoration(color: bodyColor.withValues(alpha: 0.1)),
    ),

    // Blockquote styling - left bar uses body color
    blockquote: MarkdownBlockquoteStyle(
      textStyle: TextStyle(color: bodyColor, fontSize: 32),
      padding: const EdgeInsets.only(bottom: 12, left: 30),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: bodyColor, width: 4)),
      ),
    ),

    // Horizontal rule uses body color
    horizontalRuleDecoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: bodyColor, width: 2)),
    ),

    // Slide background color (if specified)
    slideContainer: BoxStyler().color(backgroundColor),
  );

  return DeckPresentation(baseStyle: colorOverrideStyle);
}
