import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

import '../google_font_helpers.dart';

const _imageBlock = BlockVariant('image');
const _metricBlock = BlockVariant('showcaseMetric');

final _displayFamily = safeGoogleFontFamily(GoogleFonts.interTight);
final _bodyFamily = safeGoogleFontFamily(GoogleFonts.inter);

const _ink = Color(0xFFF7F4F2);
const _mutedInk = Color(0xFFC9C6CE);
const _coral = Color(0xFFFF8A65);
const _violet = Color(0xFFA890FF);
const _teal = Color(0xFF59D6C8);

SlideStyle showcaseBaseStyle() {
  return SlideStyle(
    h1: TextStyler().style(
      TextStyleMix(
        fontFamily: _displayFamily,
        fontSize: 82,
        fontWeight: FontWeight.w800,
        height: 0.98,
        letterSpacing: -3,
        color: _ink,
      ),
    ),
    h2: TextStyler().style(
      TextStyleMix(
        fontFamily: _displayFamily,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.04,
        letterSpacing: -1.5,
        color: _ink,
      ),
    ),
    h3: TextStyler().style(
      TextStyleMix(
        fontFamily: _displayFamily,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.12,
        letterSpacing: -0.7,
        color: _ink,
      ),
    ),
    h4: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.6,
        color: _coral,
      ),
    ),
    p: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 21,
        fontWeight: FontWeight.w400,
        height: 1.48,
        color: _mutedInk,
      ),
    ),
    strong: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
    em: const TextStyle(fontStyle: FontStyle.italic, color: _coral),
    del: const TextStyle(
      color: Color(0xFF77737D),
      decoration: TextDecoration.lineThrough,
      decorationColor: Color(0xFFAAA6AF),
    ),
    link: const TextStyle(
      color: _teal,
      decoration: TextDecoration.underline,
      decorationColor: Color(0x9959D6C8),
    ),
    list: MarkdownListStyle(
      text: TextStyler().style(
        TextStyleMix(
          fontFamily: _bodyFamily,
          fontSize: 20,
          height: 1.5,
          color: const Color(0xFFD5D1D9),
        ),
      ),
      bullet: TextStyler().style(
        TextStyleMix(
          fontFamily: _bodyFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFF8A65),
        ),
      ),
    ),
    blockquote: MarkdownBlockquoteStyle(
      textStyle: TextStyle(
        fontFamily: _displayFamily,
        fontSize: 25,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFF0ECF1),
      ),
      padding: const EdgeInsets.only(left: 26),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFFF8A65), width: 3)),
      ),
    ),
    alert: MarkdownAlertStyle(
      note: _alertType(const Color(0xFF6CB6FF)),
      tip: _alertType(_teal),
      important: _alertType(_violet),
      warning: _alertType(const Color(0xFFFFB15A)),
      caution: _alertType(const Color(0xFFFF6B7A)),
    ),
    table: MarkdownTableStyle(
      headStyle: TextStyle(
        fontFamily: _bodyFamily,
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: _coral,
      ),
      bodyStyle: TextStyle(
        fontFamily: _bodyFamily,
        fontSize: 16,
        height: 1.35,
        color: const Color(0xFFD8D4DC),
      ),
      headAlignment: TextAlign.left,
      border: const TableBorder(
        top: BorderSide(color: Color(0x38FFFFFF)),
        bottom: BorderSide(color: Color(0x38FFFFFF)),
        horizontalInside: BorderSide(color: Color(0x20FFFFFF)),
        verticalInside: BorderSide(color: Color(0x18FFFFFF)),
      ),
      cellPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      cellDecoration: const BoxDecoration(color: Color(0x0CFFFFFF)),
      verticalAlignment: TableCellVerticalAlignment.middle,
    ),
    checkbox: MarkdownCheckboxStyle(
      textStyle: TextStyle(
        fontFamily: _bodyFamily,
        fontSize: 18,
        height: 1.5,
        color: const Color(0xFFD8D4DC),
      ),
      icon: IconStyler(color: _teal, size: 20),
    ),
    blockContainer: BlockStyler(padding: EdgeInsetsGeometryMix.all(0))
        .variants([
          VariantStyle(
            _imageBlock,
            BlockStyler(
              padding: EdgeInsetsGeometryMix.all(0),
              margin: EdgeInsetsGeometryMix.all(0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecorationMix(
                color: const Color(0xFF121219),
                border: BorderMix.all(
                  BorderSideMix(color: const Color(0x2EFFFFFF), width: 1),
                ),
                borderRadius: BorderRadiusMix.circular(30),
              ),
            ),
          ),
          VariantStyle(
            _metricBlock,
            BlockStyler(
              padding: EdgeInsetsGeometryMix.symmetric(
                horizontal: 30,
                vertical: 28,
              ),
              decoration: _panelDecoration(radius: 26),
            ),
          ),
        ]),
    slideContainer: BoxStyler(
      padding: EdgeInsetsGeometryMix.symmetric(horizontal: 50, vertical: 30),
    ),
  );
}

SlideStyle showcaseCompactStyle() {
  return SlideStyle(
    h2: TextStyler().style(
      TextStyleMix(
        fontFamily: _displayFamily,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.04,
        letterSpacing: -1.2,
        color: _ink,
      ),
    ),
    h3: TextStyler().style(
      TextStyleMix(
        fontFamily: _displayFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.12,
        letterSpacing: -0.4,
        color: _ink,
      ),
    ),
    h4: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: _coral,
      ),
    ),
    p: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.42,
        color: _mutedInk,
      ),
    ),
    list: MarkdownListStyle(
      text: TextStyler().style(
        TextStyleMix(
          fontFamily: _bodyFamily,
          fontSize: 17,
          height: 1.42,
          color: const Color(0xFFD5D1D9),
        ),
      ),
      bullet: TextStyler().style(
        TextStyleMix(
          fontFamily: _bodyFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _coral,
        ),
      ),
    ),
    blockquote: MarkdownBlockquoteStyle(
      textStyle: TextStyle(
        fontFamily: _displayFamily,
        fontSize: 20,
        height: 1.34,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFF0ECF1),
      ),
      padding: const EdgeInsets.only(left: 20),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _coral, width: 3)),
      ),
    ),
    slideContainer: BoxStyler(
      padding: EdgeInsetsGeometryMix.symmetric(horizontal: 50, vertical: 24),
    ),
  );
}

SlideStyle showcasePanelStyle() {
  return showcaseCompactStyle().merge(
    SlideStyle(
      blockContainer: BlockStyler(
        padding: EdgeInsetsGeometryMix.symmetric(horizontal: 24, vertical: 22),
        margin: EdgeInsetsGeometryMix.symmetric(vertical: 8),
        decoration: _panelDecoration(radius: 22),
      ),
    ),
  );
}

SlideStyle showcaseCoverStyle() {
  return SlideStyle(
    h1: TextStyler().style(
      TextStyleMix(
        fontFamily: _displayFamily,
        fontSize: 96,
        fontWeight: FontWeight.w800,
        height: 0.92,
        letterSpacing: -4.5,
        color: const Color(0xFFF9F6F4),
      ),
    ),
    h2: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 25,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: const Color(0xFFBCB8C1),
      ),
    ),
    slideContainer: BoxStyler(
      padding: EdgeInsetsGeometryMix.symmetric(horizontal: 34, vertical: 34),
    ),
  );
}

SlideStyle showcaseClosingStyle() {
  return SlideStyle(
    h1: TextStyler().style(
      TextStyleMix(
        fontFamily: _displayFamily,
        fontSize: 74,
        fontWeight: FontWeight.w800,
        height: 0.96,
        letterSpacing: -3,
        color: const Color(0xFFF9F6F4),
      ),
    ),
    h2: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: const Color(0xFFFFA184),
      ),
    ),
  );
}

BoxDecorationMix _panelDecoration({required double radius}) {
  return BoxDecorationMix(
    gradient: LinearGradientMix(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [Color(0x14FFFFFF), Color(0x08FFFFFF)],
    ),
    border: BorderMix.all(
      BorderSideMix(color: const Color(0x24FFFFFF), width: 1),
    ),
    borderRadius: BorderRadiusMix.circular(radius),
  );
}

MarkdownAlertTypeStyle _alertType(Color color) {
  return MarkdownAlertTypeStyle(
    heading: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: color,
      ),
    ),
    description: TextStyler().style(
      TextStyleMix(
        fontFamily: _bodyFamily,
        fontSize: 15,
        height: 1.38,
        color: const Color(0xFFD8D4DC),
      ),
    ),
    icon: IconStyler(color: color, size: 19),
    container: BoxStyler(
      padding: EdgeInsetsGeometryMix.symmetric(horizontal: 20, vertical: 16),
      margin: EdgeInsetsGeometryMix.symmetric(vertical: 4),
      decoration: BoxDecorationMix(
        color: color.withValues(alpha: 0.07),
        border: BorderMix(left: BorderSideMix(color: color, width: 3)),
        borderRadius: BorderRadiusMix.circular(14),
      ),
    ),
    containerFlex: FlexBoxStyler()
        .spacing(9)
        .crossAxisAlignment(CrossAxisAlignment.start),
    headingFlex: FlexBoxStyler(spacing: 8),
  );
}
