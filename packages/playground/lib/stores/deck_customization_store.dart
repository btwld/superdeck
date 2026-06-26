import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../features/ai/core/ai/schemas/deck_schemas.dart';
import '../features/ai/core/utils/style_builder.dart';

/// Curated font families surfaced in the playground's customization sidebar.
const playgroundFontFamilies = <String>[
  'Inter',
  'Roboto',
  'Playfair Display',
  'Source Serif Pro',
  'JetBrains Mono',
  'Space Grotesk',
  'Lora',
  'DM Sans',
];

/// Background swatches shown in the customization sidebar.
///
/// Token swatches resolve through the active [HeroTheme]; the last two are
/// fixed white/black for decks targeting a known display environment.
final playgroundBackgroundSwatches = <PlaygroundSwatch>[
  PlaygroundSwatch(label: 'Background', color: $background()),
  PlaygroundSwatch(label: 'Surface', color: $surface()),
  PlaygroundSwatch(label: 'Muted', color: $muted()),
  PlaygroundSwatch(label: 'Accent', color: $accent()),
  const PlaygroundSwatch(label: 'White', color: Color(0xFFFFFFFF)),
  const PlaygroundSwatch(label: 'Black', color: Color(0xFF000000)),
];

/// Text swatches mirror background swatches; the default heading color uses
/// `$foreground` so headings remain legible on the seeded background.
final playgroundTextSwatches = <PlaygroundSwatch>[
  PlaygroundSwatch(label: 'Foreground', color: $foreground()),
  PlaygroundSwatch(label: 'Muted', color: $muted()),
  PlaygroundSwatch(label: 'Accent', color: $accent()),
  PlaygroundSwatch(label: 'Surface', color: $surface()),
  const PlaygroundSwatch(label: 'White', color: Color(0xFFFFFFFF)),
  const PlaygroundSwatch(label: 'Black', color: Color(0xFF000000)),
];

@immutable
class PlaygroundSwatch {
  const PlaygroundSwatch({required this.label, required this.color});

  final String label;
  final Color color;
}

/// Per-heading typography state. Each [TextLevel] owns four independent
/// signals; the store derives a [TextStyler] from them on every change.
class TextLevelSignals {
  TextLevelSignals({
    required Color color,
    required double size,
    required int weight,
    required String family,
  }) : color = signal<Color>(color),
       size = signal<double>(size),
       weight = signal<int>(weight),
       family = signal<String>(family);

  final Signal<Color> color;
  final Signal<double> size;
  final Signal<int> weight;
  final Signal<String> family;

  void dispose() {
    color.dispose();
    size.dispose();
    weight.dispose();
    family.dispose();
  }
}

enum TextLevel { h1, h2, h3, p }

/// Owns the playground's deck-wide customization state and pushes a fresh
/// [DeckOptions] into the [DeckController] on every change.
///
/// All state is in-memory; reloading the page resets to the seeded defaults.
class DeckCustomizationStore {
  DeckCustomizationStore(this._controller) {
    levels = {
      TextLevel.h1: TextLevelSignals(
        color: $foreground(),
        size: 40,
        weight: 700,
        family: 'Inter',
      ),
      TextLevel.h2: TextLevelSignals(
        color: $foreground(),
        size: 32,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h3: TextLevelSignals(
        color: $foreground(),
        size: 24,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.p: TextLevelSignals(
        color: $foreground(),
        size: 18,
        weight: 400,
        family: 'Inter',
      ),
    };

    _slideStyle = computed<SlideStyle>(() {
      return SlideStyle(
        h1: _stylerFor(TextLevel.h1),
        h2: _stylerFor(TextLevel.h2),
        h3: _stylerFor(TextLevel.h3),
        p: _stylerFor(TextLevel.p),
      );
    });

    _effectCleanup = effect(() {
      final style = _slideStyle.value;
      final bg = background.value;
      _controller.options.value = DeckOptions(
        baseStyle: style,
        parts: SlideParts(background: Box(style: BoxStyler().color(bg))),
      );
    });
  }

  final DeckController _controller;

  final Signal<Color> background = signal<Color>($background());

  late final Map<TextLevel, TextLevelSignals> levels;

  late final ReadonlySignal<SlideStyle> _slideStyle;
  late final EffectCleanup _effectCleanup;

  TextLevelSignals level(TextLevel level) => levels[level]!;

  TextStyler _stylerFor(TextLevel level) {
    final signals = levels[level]!;
    return _buildTextStyler(
      color: signals.color.value,
      size: signals.size.value,
      weight: signals.weight.value,
      family: signals.family.value,
    );
  }

  TextStyler _buildTextStyler({
    required Color color,
    required double size,
    required int weight,
    required String family,
  }) {
    final fontWeight = _fontWeightFor(weight);
    final resolvedFamily = _resolveFamily(family, fontWeight);
    return TextStyler().style(
      TextStyleMix(
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
        fontFamily: resolvedFamily.fontFamily,
        fontFamilyFallback: resolvedFamily.fontFamilyFallback,
      ),
    );
  }

  /// Resolves `family` through `google_fonts`, swallowing missing-weight
  /// errors so a stray slider tick never crashes the editor.
  TextStyle _resolveFamily(String family, FontWeight weight) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return const TextStyle();
    }
    try {
      return GoogleFonts.getFont(family, fontWeight: weight);
    } catch (_) {
      try {
        return GoogleFonts.getFont(family);
      } catch (_) {
        return const TextStyle();
      }
    }
  }

  FontWeight _fontWeightFor(int value) {
    switch (value) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
    }
    return FontWeight.w400;
  }

  /// Applies an AI-generated [DeckStyleType] to the store's signals.
  ///
  /// Maps:
  /// - `style.colors.background` → [background]
  /// - `style.colors.heading` + `style.fonts.headline` → h1 / h2 / h3 color & family
  /// - `style.colors.body` + `style.fonts.body` → p color & family
  ///
  /// The reactive effect will push updated [DeckOptions] to the controller.
  void applyFromAiStyle(DeckStyleType style) {
    final extracted = extractAiStyleColors(style);

    background.value = extracted.backgroundColor;

    for (final heading in [TextLevel.h1, TextLevel.h2, TextLevel.h3]) {
      level(heading)
        ..color.value = extracted.headingColor
        ..family.value = extracted.headlineFontFamily;
    }

    level(TextLevel.p)
      ..color.value = extracted.bodyColor
      ..family.value = extracted.bodyFontFamily;
  }

  void dispose() {
    _effectCleanup();
    background.dispose();
    for (final signals in levels.values) {
      signals.dispose();
    }
    _slideStyle.dispose();
  }
}
