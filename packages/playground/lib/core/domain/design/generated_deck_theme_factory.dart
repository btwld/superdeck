import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

import 'presentation_theme_catalog.dart';

final class GeneratedThemePalette {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color heading;
  final Color body;
  final Color accent;
  final Color accentContrast;

  const GeneratedThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.heading,
    required this.body,
    required this.accent,
    required this.accentContrast,
  });
}

final class PresentationTextStyles {
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle h5;
  final TextStyle h6;
  final TextStyle body;

  const PresentationTextStyles({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.body,
  });
}

/// Maps one resolved renderer-owned recipe to presentation-scale styling.
final class GeneratedDeckThemeFactory {
  static const treatmentNames = presentationThemeTreatmentNames;

  const GeneratedDeckThemeFactory();

  DeckOptions build({
    required GeneratedThemePalette palette,
    required PresentationTextStyles text,
    required String density,
    required PresentationThemeRuntimeRecipe runtime,
    bool debug = false,
  }) {
    final borderColor = Color.lerp(palette.surface, palette.body, 0.4)!;
    final tableFontSize = text.body.fontSize! > 20 ? 20.0 : text.body.fontSize!;
    final tableText = text.body.copyWith(fontSize: tableFontSize, height: 1.15);
    final componentDecoration = _componentDecoration(palette, runtime);
    final baseStyle = SlideStyler(
      h1: _text(text.h1),
      h2: _text(text.h2),
      h3: _text(text.h3),
      h4: _text(text.h4),
      h5: _text(text.h5),
      h6: _text(text.h6),
      p: _text(text.body),
      link: TextStyleMix.value(
        text.body.copyWith(color: palette.accent, decoration: .underline),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: palette.accent,
            width: _atLeast(runtime.borderWidth, 1),
          ),
        ),
      ),
      blockquote: MarkdownBlockquoteStyler(
        textStyle: TextStyleMix.value(
          text.body.copyWith(fontSize: text.body.fontSize! * 1.35, height: 1.3),
        ),
        padding: EdgeInsets.only(
          left: 28 * runtime.spacingScale,
          bottom: 12 * runtime.spacingScale,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: palette.accent,
              width: runtime.quoteRuleWidth,
            ),
          ),
        ),
      ),
      list: _list(text.body),
      table: MarkdownTableStyler(
        headStyle: TextStyleMix.value(
          tableText.copyWith(
            color: palette.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        bodyStyle: TextStyleMix.value(tableText),
        border: TableBorder.all(color: borderColor, width: runtime.borderWidth),
        cellPadding: EdgeInsets.symmetric(
          vertical: 6 * runtime.spacingScale,
          horizontal: 12 * runtime.spacingScale,
        ),
        cellDecoration: _componentBoxDecoration(palette, runtime),
        verticalAlignment: TableCellVerticalAlignment.middle,
      ),
      code: MarkdownCodeblockStyler(
        textStyle: TextStyleMix.value(text.body.copyWith(height: 1.45)),
        container: BoxStyler(
          padding: EdgeInsetsMix.all(24 * runtime.spacingScale),
          decoration: componentDecoration,
        ),
      ),
      blockContainer: _blockContainer(palette, runtime, .none),
      slideContainer: _slideContainer(
        palette.background,
        palette,
        density: density,
        runtime: runtime,
      ),
    );
    final styles = <String, SlideStyler>{
      for (final entry in runtime.treatments.byName.entries)
        entry.key: _treatmentStyle(
          entry.key,
          entry.value,
          palette,
          text,
          density,
          runtime,
        ),
    };

    return DeckOptions(
      baseStyle: baseStyle,
      styles: styles,
      parts: SlideParts(
        header: null,
        footer: null,
        background: Box(style: BoxStyler().color(palette.background)),
      ),
      debug: debug,
    );
  }
}

SlideStyler _treatmentStyle(
  String name,
  PresentationThemeTreatmentRecipe treatment,
  GeneratedThemePalette palette,
  PresentationTextStyles text,
  String density,
  PresentationThemeRuntimeRecipe runtime,
) {
  final heading = _textColor(treatment.heading, palette);
  final body = _textColor(treatment.body, palette);
  final background = _backgroundColor(treatment.background, palette);
  final headlineBase = name == 'hero' ? text.h1 : text.h2;
  final supportScale = treatment.headlineScale > 1
      ? 1.0
      : treatment.headlineScale;
  final headlineStyle = headlineBase.copyWith(
    color: heading,
    fontSize: headlineBase.fontSize! * treatment.headlineScale,
    fontStyle: treatment.italicHeadline ? FontStyle.italic : .normal,
    height: 1,
  );
  final h2 = text.h3.copyWith(
    color: heading,
    fontSize: text.h3.fontSize! * supportScale,
    height: 1.05,
  );
  final h3 = text.h4.copyWith(
    color: heading,
    fontSize: text.h4.fontSize! * supportScale,
    height: 1.1,
  );
  final bodyStyle = text.body.copyWith(color: body);

  return SlideStyler(
    h1: _text(headlineStyle),
    h2: _text(h2),
    h3: _text(h3),
    p: _text(bodyStyle),
    link: TextStyleMix.value(bodyStyle.copyWith(decoration: .underline)),
    list: _list(bodyStyle),
    blockContainer: _blockContainer(palette, runtime, treatment.blockStyle),
    slideContainer: _slideContainer(
      background,
      palette,
      density: density,
      runtime: runtime,
    ),
  );
}

BlockStyler _blockContainer(
  GeneratedThemePalette palette,
  PresentationThemeRuntimeRecipe runtime,
  PresentationThemeBlockStyle style,
) => .new(
  padding: EdgeInsetsGeometryMix.all(
    style == .none ? 0 : 20 * runtime.spacingScale,
  ),
  margin: EdgeInsetsGeometryMix.all(
    style == .none ? 0 : 12 * runtime.spacingScale,
  ),
  decoration: _blockDecoration(style, palette, runtime),
  clipBehavior: .antiAlias,
  variants: [
    VariantStyle(
      const BlockVariant('image'),
      BlockStyler(
        padding: EdgeInsetsGeometryMix.all(0),
        margin: EdgeInsetsGeometryMix.all(0),
        decoration: _transparentDecoration(runtime),
        clipBehavior: .antiAlias,
      ),
    ),
    for (final name in const ['webview', 'dartpad', 'gist'])
      VariantStyle(
        BlockVariant(name),
        BlockStyler(
          padding: EdgeInsetsGeometryMix.all(0),
          margin: EdgeInsetsGeometryMix.all(0),
          decoration: _blockDecoration(.outlined, palette, runtime),
          clipBehavior: .antiAlias,
        ),
      ),
    VariantStyle(
      const BlockVariant('qrcode'),
      BlockStyler(
        padding: EdgeInsetsGeometryMix.all(24 * runtime.spacingScale),
        decoration: _blockDecoration(.tonal, palette, runtime),
        clipBehavior: .antiAlias,
      ),
    ),
  ],
);

BoxDecorationMix _blockDecoration(
  PresentationThemeBlockStyle style,
  GeneratedThemePalette palette,
  PresentationThemeRuntimeRecipe runtime,
) => switch (style) {
  .none => _transparentDecoration(runtime),
  .tonal => .new(
    borderRadius: BorderRadiusMix.circular(runtime.cornerRadius),
    color: palette.surfaceAlt,
  ),
  .outlined => .new(
    border: BorderMix.all(
      BorderSideMix(
        color: Color.lerp(palette.surface, palette.body, 0.4),
        width: runtime.borderWidth,
      ),
    ),
    borderRadius: BorderRadiusMix.circular(runtime.cornerRadius),
    color: palette.surface,
  ),
};

BoxDecorationMix _transparentDecoration(
  PresentationThemeRuntimeRecipe runtime,
) => .new(
  border: BorderMix.all(BorderSideMix(color: Colors.transparent, width: 0)),
  borderRadius: BorderRadiusMix.circular(runtime.cornerRadius),
  color: Colors.transparent,
);

BoxDecorationMix _componentDecoration(
  GeneratedThemePalette palette,
  PresentationThemeRuntimeRecipe runtime,
) => switch (runtime.surfaceStyle) {
  .flat => .new(
    borderRadius: BorderRadiusMix.circular(runtime.cornerRadius),
    color: palette.surface,
  ),
  .tonal => .new(
    borderRadius: BorderRadiusMix.circular(runtime.cornerRadius),
    color: palette.surfaceAlt,
  ),
  .outlined => .new(
    border: BorderMix.all(
      BorderSideMix(
        color: Color.lerp(palette.surface, palette.body, 0.4),
        width: runtime.borderWidth,
      ),
    ),
    borderRadius: BorderRadiusMix.circular(runtime.cornerRadius),
    color: palette.surface,
  ),
};

BoxDecoration _componentBoxDecoration(
  GeneratedThemePalette palette,
  PresentationThemeRuntimeRecipe runtime,
) {
  final borderRadius = BorderRadius.circular(runtime.cornerRadius);
  final outlineBorder = Border.all(
    color: Color.lerp(palette.surface, palette.body, 0.4)!,
    width: runtime.borderWidth,
  );

  return switch (runtime.surfaceStyle) {
    .flat => .new(color: palette.surface, borderRadius: borderRadius),
    .tonal => .new(color: palette.surfaceAlt, borderRadius: borderRadius),
    .outlined => .new(
      color: palette.surface,
      border: outlineBorder,
      borderRadius: borderRadius,
    ),
  };
}

BoxStyler _slideContainer(
  Color color,
  GeneratedThemePalette palette, {
  required String density,
  required PresentationThemeRuntimeRecipe runtime,
}) => BoxStyler(
  padding: EdgeInsetsMix.all(
    switch (density) {
          'spacious' => 72,
          'compact' => 40,
          _ => 56,
        } *
        runtime.spacingScale,
  ),
  decoration: BoxDecorationMix(
    border: _decorativeBorder(palette, runtime),
    color: color,
  ),
);

BorderMix? _decorativeBorder(
  GeneratedThemePalette palette,
  PresentationThemeRuntimeRecipe runtime,
) => switch (runtime.decorativeStyle) {
  .none => null,
  .rule => .bottom(
    BorderSideMix(
      color: palette.accent,
      width: _atLeast(runtime.borderWidth * 2, 2),
    ),
  ),
  .frame => .all(
    BorderSideMix(
      color: palette.accent,
      width: _atLeast(runtime.borderWidth, 1),
    ),
  ),
  .grid => .new(
    top: BorderSideMix(
      color: palette.accent,
      width: _atLeast(runtime.borderWidth, 1),
    ),
    bottom: BorderSideMix(
      color: palette.accent,
      width: _atLeast(runtime.borderWidth, 1),
    ),
    left: BorderSideMix(color: palette.body, width: runtime.borderWidth),
    right: BorderSideMix(color: palette.body, width: runtime.borderWidth),
  ),
  .poster => .left(
    BorderSideMix(
      color: palette.accent,
      width: _atLeast(runtime.quoteRuleWidth, 8),
    ),
  ),
};

Color _backgroundColor(
  PresentationThemeColorRole role,
  GeneratedThemePalette palette,
) => switch (role) {
  .background => palette.background,
  .surface => palette.surface,
  .surfaceAlt => palette.surfaceAlt,
  .accent => palette.accent,
};

Color _textColor(
  PresentationThemeTextColorRole role,
  GeneratedThemePalette palette,
) => switch (role) {
  .heading => palette.heading,
  .body => palette.body,
  .accent => palette.accent,
  .accentContrast => palette.accentContrast,
};

double _atLeast(double value, double minimum) =>
    value < minimum ? minimum : value;

TextStyler _text(TextStyle style) =>
    TextStyler().style(TextStyleMix.value(style));

MarkdownListStyler _list(TextStyle style) =>
    MarkdownListStyler(bullet: _text(style), text: _text(style));
