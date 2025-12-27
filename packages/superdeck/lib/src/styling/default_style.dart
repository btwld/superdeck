import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';

import 'styling.dart';

/// Safely loads a Google Font, falling back to platform default when runtime
/// fetching is disabled (e.g., in tests).
TextStyle _safeGoogleFont(TextStyle Function() fontLoader) {
  // When runtime fetching is disabled (typically in tests), Google Fonts
  // requires bundled font assets. Since we don't bundle fonts for tests,
  // use platform default instead.
  if (!GoogleFonts.config.allowRuntimeFetching) {
    return const TextStyle();
  }
  return fontLoader();
}

// Base text style for the presentation
TextStyle get _baseTextStyle =>
    _safeGoogleFont(GoogleFonts.poppins).copyWith(fontSize: 24, color: Colors.white);

// Custom variants for different block types
const onGist = NamedVariant('gist');
const onDebug = NamedVariant('debug');
const onImage = NamedVariant('image');

WidgetModifierConfig _pad(EdgeInsetsGeometryMix value) =>
    WidgetModifierConfig.padding(value);

/// Creates the default base slide style with all typography, alerts, code blocks, etc.
///
/// This provides the foundation styling for all slides including:
/// - Typography (headings h1-h6, paragraphs)
/// - Alerts (note, tip, important, warning, caution)
/// - Code blocks
/// - Tables
/// - Blockquotes
/// - Lists
/// - Layout containers
SlideStyle _createDefaultSlideStyle() {
  // Create a helper for alert type styling to reduce repetition
  MarkdownAlertTypeStyle createAlertType(Color color) {
    return MarkdownAlertTypeStyle(
      heading: TextStyler()
          .style(
            TextStyleMix(
              fontSize: _baseTextStyle.fontSize,
              color: _baseTextStyle.color,
              fontFamily: _baseTextStyle.fontFamily,
              fontWeight: FontWeight.bold,
            ),
          )
          .textAlign(TextAlign.left),
      description: TextStyler()
          .style(
            TextStyleMix(
              fontSize: _baseTextStyle.fontSize,
              color: _baseTextStyle.color,
              fontFamily: _baseTextStyle.fontFamily,
            ),
          )
          .textAlign(TextAlign.left),
      icon: IconStyler(color: color),
      container: BoxStyler(
        padding: EdgeInsetsGeometryMix.symmetric(horizontal: 24, vertical: 8),
        margin: EdgeInsetsGeometryMix.symmetric(vertical: 12),
        decoration: BoxDecorationMix(
          color: color.withValues(alpha: 0.05),
          border: BorderMix(left: BorderSideMix(color: color, width: 4)),
        ),
      ),
      containerFlex: FlexBoxStyler()
          .spacing(12)
          .crossAxisAlignment(CrossAxisAlignment.start),
      headingFlex: FlexBoxStyler(spacing: 8),
    );
  }

  return SlideStyle(
    // Typography - Headings
    h1: TextStyler()
        .style(
          TextStyleMix(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
        .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 16))),

    h2: TextStyler()
        .style(
          TextStyleMix(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
        .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 12))),

    h3: TextStyler()
        .style(
          TextStyleMix(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
        .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 12))),

    h4: TextStyler()
        .style(
          TextStyleMix(
            fontSize: 36,
            fontWeight: FontWeight.normal,
            height: 1.3,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
        .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 8))),

    h5: TextStyler()
        .style(
          TextStyleMix(
            fontSize: 24,
            fontWeight: FontWeight.normal,
            height: 1.4,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
        .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 4))),

    h6: TextStyler()
        .style(
          TextStyleMix(
            fontSize: _baseTextStyle.fontSize,
            height: 1.4,
            fontWeight: FontWeight.normal,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
        .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 3))),

    // Paragraph
    p: TextStyler()
        .style(
          TextStyleMix(
            fontSize: _baseTextStyle.fontSize,
            height: 1.6,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
        .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 12))),

    // Inline text styles
    link: _baseTextStyle.copyWith(color: const Color.fromARGB(255, 66, 82, 96)),

    // Alerts - using helper function for each type
    alert: MarkdownAlertStyle(
      note: createAlertType(Colors.blue),
      tip: createAlertType(Colors.green),
      important: createAlertType(Colors.deepPurpleAccent),
      warning: createAlertType(Colors.amber),
      caution: createAlertType(Colors.redAccent),
    ),

    // Code blocks
    code: MarkdownCodeblockStyle(
      textStyle: _safeGoogleFont(() => GoogleFonts.jetBrainsMono(fontSize: 18))
          .copyWith(height: 1.8),
      container: BoxStyler(
        padding: EdgeInsetsMix.all(32),
        decoration: BoxDecorationMix(
          color: const Color.fromARGB(255, 0, 0, 0),
          borderRadius: BorderRadiusMix.circular(10),
        ),
      ),
    ),

    // Tables
    table: MarkdownTableStyle(
      headStyle: _baseTextStyle.copyWith(fontWeight: FontWeight.bold),
      bodyStyle: _baseTextStyle,
      cellPadding: const EdgeInsets.all(12),
      border: TableBorder.all(color: Colors.grey, width: 2),
      cellDecoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1)),
    ),

    // Blockquotes
    blockquote: MarkdownBlockquoteStyle(
      textStyle: _baseTextStyle.copyWith(fontSize: 32),
      padding: const EdgeInsets.only(bottom: 12, left: 30),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey, width: 4)),
      ),
    ),

    // Lists
    list: MarkdownListStyle(
      bullet: TextStyler().style(
        TextStyleMix(
          fontSize: _baseTextStyle.fontSize,
          color: _baseTextStyle.color,
          fontFamily: _baseTextStyle.fontFamily,
        ),
      ),
      text: TextStyler()
          .style(
          TextStyleMix(
            fontSize: _baseTextStyle.fontSize,
            height: 1.6,
            color: _baseTextStyle.color,
            fontFamily: _baseTextStyle.fontFamily,
          ),
        )
          .wrap(_pad(EdgeInsetsGeometryMix.only(bottom: 8))),
    ),

    // Checkbox
    checkbox: MarkdownCheckboxStyle(textStyle: _baseTextStyle),

    // Block container with variants for different block types
    blockContainer: BoxStyler(padding: EdgeInsetsGeometryMix.all(40)).variants([
      // Image variant - no padding
      VariantStyle(onImage, BoxStyler(padding: EdgeInsetsGeometryMix.all(0))),
      // Gist variant - no padding or margin
      VariantStyle(
        onGist,
        BoxStyler(
          padding: EdgeInsetsGeometryMix.all(0),
          margin: EdgeInsetsGeometryMix.all(0),
        ),
      ),
    ]),

    // Slide container - wraps entire slide content
    slideContainer: BoxStyler(),

    // Horizontal rule
    horizontalRuleDecoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey, width: 2)),
    ),
  );
}

/// Default base slide style - created once and reused.
///
/// This style is ALWAYS applied as the foundation, then user-provided
/// styles are merged on top of it.
final defaultSlideStyle = _createDefaultSlideStyle();
