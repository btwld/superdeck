import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

final class GeneratedThemePalette {
  const GeneratedThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.heading,
    required this.body,
    required this.accent,
    required this.accentContrast,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color heading;
  final Color body;
  final Color accent;
  final Color accentContrast;
}

final class PresentationTextStyles {
  const PresentationTextStyles({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.body,
  });

  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle h5;
  final TextStyle h6;
  final TextStyle body;
}

/// Maps semantic generation choices to safe renderer-owned slide styling.
final class GeneratedDeckThemeFactory {
  const GeneratedDeckThemeFactory();

  static const treatmentNames = {
    'hero',
    'section',
    'content',
    'data',
    'quote',
    'visual',
    'closing',
  };

  DeckOptions build({
    required GeneratedThemePalette palette,
    required PresentationTextStyles text,
    required String direction,
    required String density,
  }) {
    final borderColor = Color.lerp(palette.surface, palette.body, 0.4)!;
    final codeBackground = Color.lerp(
      palette.surface,
      palette.heading,
      palette.background.computeLuminance() < 0.5 ? 0.1 : 0.05,
    )!;
    final tableFontSize = text.body.fontSize! > 20 ? 20.0 : text.body.fontSize!;
    final tableText = text.body.copyWith(fontSize: tableFontSize, height: 1.15);
    final baseStyle = SlideStyler(
      h1: _text(text.h1),
      h2: _text(text.h2),
      h3: _text(text.h3),
      h4: _text(text.h4),
      h5: _text(text.h5),
      h6: _text(text.h6),
      p: _text(text.body),
      list: MarkdownListStyler(
        bullet: _text(text.body),
        text: _text(text.body),
      ),
      link: TextStyleMix(color: palette.accent),
      table: MarkdownTableStyler(
        headStyle: TextStyleMix.value(
          tableText.copyWith(
            color: palette.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        bodyStyle: TextStyleMix.value(tableText),
        cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        border: TableBorder.all(color: borderColor, width: 1.5),
        cellDecoration: BoxDecoration(color: palette.surfaceAlt),
        verticalAlignment: TableCellVerticalAlignment.middle,
      ),
      blockquote: MarkdownBlockquoteStyler(
        textStyle: TextStyleMix.value(
          text.body.copyWith(fontSize: text.body.fontSize! * 1.35, height: 1.3),
        ),
        padding: const EdgeInsets.only(bottom: 12, left: 28),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: palette.accent, width: 5)),
        ),
      ),
      code: MarkdownCodeblockStyler(
        textStyle: TextStyleMix.value(text.body.copyWith(height: 1.45)),
        container: BoxStyler(
          padding: EdgeInsetsMix.all(24),
          decoration: BoxDecorationMix(
            color: codeBackground,
            borderRadius: BorderRadiusMix.circular(12),
          ),
        ),
      ),
      slideContainer: _slideContainer(palette.background, density: density),
    );

    return DeckOptions(
      baseStyle: baseStyle,
      styles: {
        'hero': _heroStyle(palette, text, direction, density),
        'section': _sectionStyle(palette, text, direction, density),
        'content': SlideStyler(
          h1: _text(
            text.h2.copyWith(fontSize: text.h2.fontSize! * 0.8, height: 1),
          ),
          h2: _text(
            text.h3.copyWith(fontSize: text.h3.fontSize! * 0.78, height: 1),
          ),
          h3: _text(
            text.h4.copyWith(fontSize: text.h4.fontSize! * 0.8, height: 1.05),
          ),
          slideContainer: _slideContainer(palette.background, density: density),
        ),
        'data': SlideStyler(
          h1: _text(text.h2.copyWith(height: 1)),
          h2: _text(
            text.h3.copyWith(fontSize: text.h3.fontSize! * 0.78, height: 1),
          ),
          h3: _text(
            text.h4.copyWith(fontSize: text.h4.fontSize! * 0.8, height: 1.05),
          ),
          slideContainer: _slideContainer(palette.surface, density: density),
          blockContainer: BlockStyler(
            decoration: BoxDecorationMix(
              color: palette.surfaceAlt,
              borderRadius: BorderRadiusMix.circular(
                direction == 'playful' ? 24 : 12,
              ),
            ),
          ),
        ),
        'quote': SlideStyler(
          slideContainer: _slideContainer(
            direction == 'editorial' ? palette.surface : palette.background,
            density: density,
          ),
          h1: _text(
            text.h2.copyWith(
              color: palette.accent,
              fontSize: text.h2.fontSize! * 0.9,
              height: 1,
            ),
          ),
          h2: _text(
            text.h3.copyWith(
              color: palette.accent,
              fontSize: text.h3.fontSize! * 0.78,
              height: 1,
            ),
          ),
        ),
        'visual': SlideStyler(
          h1: _text(
            text.h2.copyWith(fontSize: text.h2.fontSize! * 0.8, height: 1),
          ),
          h2: _text(
            text.h3.copyWith(fontSize: text.h3.fontSize! * 0.78, height: 1),
          ),
          slideContainer: _slideContainer(
            palette.surfaceAlt,
            density: 'compact',
          ),
        ),
        'closing': _closingStyle(palette, text, direction, density),
      },
      parts: SlideParts(
        background: Box(style: BoxStyler().color(palette.background)),
      ),
    );
  }
}

SlideStyler _heroStyle(
  GeneratedThemePalette palette,
  PresentationTextStyles text,
  String direction,
  String density,
) {
  final useAccent = direction == 'bold' || direction == 'playful';
  final foreground = useAccent ? palette.accentContrast : palette.heading;
  final background = switch (direction) {
    'bold' => palette.accent,
    'playful' => palette.surfaceAlt,
    'editorial' => palette.surface,
    _ => palette.background,
  };
  return SlideStyler(
    h1: _text(
      text.h1.copyWith(
        color: foreground,
        fontSize: text.h1.fontSize! * (direction == 'minimal' ? 0.9 : 1.08),
        fontStyle: direction == 'editorial' ? FontStyle.italic : null,
        height: 1,
      ),
    ),
    h2: _text(text.h3.copyWith(color: foreground, height: 1)),
    p: _text(text.body.copyWith(color: foreground)),
    list: _list(text.body.copyWith(color: foreground)),
    link: TextStyleMix(color: foreground),
    slideContainer: _slideContainer(background, density: density),
  );
}

SlideStyler _sectionStyle(
  GeneratedThemePalette palette,
  PresentationTextStyles text,
  String direction,
  String density,
) {
  final background = direction == 'minimal'
      ? palette.surfaceAlt
      : palette.accent;
  final foreground = direction == 'minimal'
      ? palette.heading
      : palette.accentContrast;
  return SlideStyler(
    h1: _text(
      text.h2.copyWith(
        color: foreground,
        fontSize: text.h2.fontSize! * 0.9,
        height: 1,
      ),
    ),
    h2: _text(
      text.h3.copyWith(
        color: foreground,
        fontSize: text.h3.fontSize! * 0.78,
        height: 1,
      ),
    ),
    h3: _text(
      text.h4.copyWith(
        color: foreground,
        fontSize: text.h4.fontSize! * 0.8,
        height: 1.05,
      ),
    ),
    p: _text(text.body.copyWith(color: foreground)),
    list: _list(text.body.copyWith(color: foreground)),
    link: TextStyleMix(color: foreground),
    slideContainer: _slideContainer(background, density: density),
  );
}

SlideStyler _closingStyle(
  GeneratedThemePalette palette,
  PresentationTextStyles text,
  String direction,
  String density,
) {
  final useAccent = direction != 'minimal';
  final background = useAccent ? palette.accent : palette.surface;
  final foreground = useAccent ? palette.accentContrast : palette.heading;
  return SlideStyler(
    h1: _text(
      text.h2.copyWith(
        color: foreground,
        fontSize: text.h2.fontSize! * 0.9,
        height: 1,
      ),
    ),
    h2: _text(text.h3.copyWith(color: foreground, height: 1)),
    p: _text(text.body.copyWith(color: foreground)),
    list: _list(text.body.copyWith(color: foreground)),
    link: TextStyleMix(color: foreground),
    slideContainer: _slideContainer(background, density: density),
  );
}

TextStyler _text(TextStyle style) =>
    TextStyler().style(TextStyleMix.value(style));

MarkdownListStyler _list(TextStyle style) =>
    MarkdownListStyler(bullet: _text(style), text: _text(style));

BoxStyler _slideContainer(Color color, {required String density}) => BoxStyler(
  padding: EdgeInsetsMix.all(switch (density) {
    'spacious' => 72,
    'compact' => 40,
    _ => 56,
  }),
  decoration: BoxDecorationMix(color: color),
);
