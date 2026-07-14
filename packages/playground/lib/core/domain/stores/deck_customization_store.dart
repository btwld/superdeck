import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:superdeck/superdeck.dart';

import '../design/generated_deck_theme_factory.dart';
import '../design/presentation_typography_catalog.dart';

/// Neutral fallbacks used when no theme-resolved seed colors are supplied
/// (e.g. in unit tests). Production wiring passes the resolved `$background` /
/// `$foreground` tokens from the provider's context.
const _defaultBackground = Color(0xFF000000);
const _defaultForeground = Color(0xFFFFFFFF);

/// Curated font families surfaced in the playground's customization sidebar.
final playgroundFontFamilies =
    PresentationTypographyCatalog.withDefaults().familyNames;

/// Renderer-ready style selected by the generation pipeline.
final class GeneratedDeckStyle {
  const GeneratedDeckStyle({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.heading,
    required this.body,
    required this.accent,
    required this.accentContrast,
    required this.headlineFamily,
    required this.bodyFamily,
    required this.direction,
    required this.density,
    required this.typeScale,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color heading;
  final Color body;
  final Color accent;
  final Color accentContrast;
  final String headlineFamily;
  final String bodyFamily;
  final String direction;
  final String density;
  final String typeScale;
}

enum TextLevel { h1, h2, h3, h4, h5, h6, p }

/// Mutable per-heading typography state for one [TextLevel].
class TextLevelStyle {
  TextLevelStyle({
    required this.color,
    required this.size,
    required this.weight,
    required this.family,
  });

  Color color;
  double size;
  int weight;
  String family;
}

/// Owns the playground's deck-wide customization state and pushes a fresh
/// [DeckOptions] into the [DeckController] on every change.
///
/// Ported from the signal-based original to a plain [ChangeNotifier]: each
/// mutation updates a field, rebuilds the [DeckOptions], writes it to the
/// controller, and notifies. All state is in-memory; reloading resets to the
/// seeded defaults.
class DeckCustomizationStore extends ChangeNotifier {
  DeckCustomizationStore(
    this._controller, {
    Color background = _defaultBackground,
    Color foreground = _defaultForeground,
    PresentationTypographyCatalog? typographyCatalog,
  }) : _background = background,
       _typographyCatalog =
           typographyCatalog ?? PresentationTypographyCatalog.withDefaults() {
    _surface = Color.lerp(background, foreground, 0.1)!;
    _surfaceAlt = Color.lerp(background, foreground, 0.18)!;
    _accent = foreground;
    _accentContrast = background;
    _levels = {
      TextLevel.h1: TextLevelStyle(
        color: foreground,
        size: 96,
        weight: 700,
        family: 'Inter',
      ),
      TextLevel.h2: TextLevelStyle(
        color: foreground,
        size: 64,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h3: TextLevelStyle(
        color: foreground,
        size: 46,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h4: TextLevelStyle(
        color: foreground,
        size: 36,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h5: TextLevelStyle(
        color: foreground,
        size: 30,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h6: TextLevelStyle(
        color: foreground,
        size: 26,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.p: TextLevelStyle(
        color: foreground,
        size: 24,
        weight: 400,
        family: 'Inter',
      ),
    };
    // Seed the controller's options once (replaces the old startup effect).
    _pushOptions();
  }

  final DeckController _controller;

  final PresentationTypographyCatalog _typographyCatalog;

  static const _themeFactory = GeneratedDeckThemeFactory();

  Color _background;

  late Color _surface;

  late Color _surfaceAlt;

  late Color _accent;

  late Color _accentContrast;

  String _direction = 'minimal';

  String _density = 'balanced';

  late final Map<TextLevel, TextLevelStyle> _levels;

  Color get background => _background;

  set background(Color value) {
    if (_background == value) return;
    _background = value;
    _apply();
  }

  TextLevelStyle level(TextLevel level) => _levels[level]!;

  void setColor(TextLevel level, Color color) {
    final target = _levels[level]!;
    if (target.color == color) return;
    target.color = color;
    _apply();
  }

  void setSize(TextLevel level, double size) {
    final target = _levels[level]!;
    if (target.size == size) return;
    target.size = size;
    _apply();
  }

  void setWeight(TextLevel level, int weight) {
    final target = _levels[level]!;
    if (target.weight == weight) return;
    target.weight = weight;
    _apply();
  }

  void setFamily(TextLevel level, String family) {
    final target = _levels[level]!;
    final role = level == TextLevel.p
        ? PresentationFontRole.body
        : PresentationFontRole.headline;
    final descriptor = _requireFont(family, role);
    if (target.family == descriptor.family) return;
    target.family = descriptor.family;
    _apply();
  }

  /// Applies one generated visual system and pushes one coherent option update.
  void applyGeneratedStyle(GeneratedDeckStyle style) {
    final headline = _requireFont(
      style.headlineFamily,
      PresentationFontRole.headline,
    );
    final body = _requireFont(style.bodyFamily, PresentationFontRole.body);
    _background = style.background;
    _surface = style.surface;
    _surfaceAlt = style.surfaceAlt;
    _accent = style.accent;
    _accentContrast = style.accentContrast;
    _direction = style.direction;
    _density = style.density;
    _applyTypeScale(style.typeScale);
    for (final level in TextLevel.values) {
      final target = _levels[level]!;
      final heading = level != TextLevel.p;
      target.color = heading ? style.heading : style.body;
      target.family = heading ? headline.family : body.family;
      if (heading) target.weight = _headlineWeight(style.direction, level);
    }
    _apply();
  }

  /// Rebuilds and pushes [DeckOptions], then notifies listeners.
  void _apply() {
    _pushOptions();
    notifyListeners();
  }

  void _pushOptions() {
    _controller.options.value = _themeFactory.build(
      palette: GeneratedThemePalette(
        background: _background,
        surface: _surface,
        surfaceAlt: _surfaceAlt,
        heading: _levels[TextLevel.h1]!.color,
        body: _levels[TextLevel.p]!.color,
        accent: _accent,
        accentContrast: _accentContrast,
      ),
      text: PresentationTextStyles(
        h1: _textStyleFor(TextLevel.h1),
        h2: _textStyleFor(TextLevel.h2),
        h3: _textStyleFor(TextLevel.h3),
        h4: _textStyleFor(TextLevel.h4),
        h5: _textStyleFor(TextLevel.h5),
        h6: _textStyleFor(TextLevel.h6),
        body: _textStyleFor(TextLevel.p),
      ),
      direction: _direction,
      density: _density,
    );
  }

  TextStyle _textStyleFor(TextLevel level) {
    final style = _levels[level]!;
    final fontWeight = _fontWeightFor(style.weight);
    final role = level == TextLevel.p
        ? PresentationFontRole.body
        : PresentationFontRole.headline;
    final resolvedFamily = _resolveFamily(style.family, fontWeight, role);
    return resolvedFamily.copyWith(
      fontSize: style.size,
      fontWeight: fontWeight,
      color: style.color,
    );
  }

  TextStyle _resolveFamily(
    String family,
    FontWeight weight,
    PresentationFontRole role,
  ) {
    final descriptor = _requireFont(family, role);
    if (descriptor.source == PresentationFontSource.bundled ||
        !GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(fontFamily: descriptor.family);
    }
    try {
      return GoogleFonts.getFont(descriptor.family, fontWeight: weight);
    } catch (firstError) {
      try {
        return GoogleFonts.getFont(descriptor.family);
      } catch (_) {
        throw StateError(
          'Registered font "${descriptor.family}" could not be resolved: '
          '$firstError',
        );
      }
    }
  }

  PresentationFontDescriptor _requireFont(
    String family,
    PresentationFontRole role,
  ) {
    final descriptor = _typographyCatalog.resolve(family);
    if (descriptor == null || !descriptor.roles.contains(role)) {
      throw ArgumentError(
        '${role == PresentationFontRole.headline ? 'Headline' : 'Body'} font '
        '"$family" is not registered for ${role.name} use.',
      );
    }
    return descriptor;
  }

  void _applyTypeScale(String typeScale) {
    final sizes = switch (typeScale) {
      'dramatic' => const [112.0, 72.0, 52.0, 40.0, 32.0, 28.0, 22.0],
      'dense' => const [80.0, 56.0, 42.0, 34.0, 28.0, 24.0, 20.0],
      _ => const [96.0, 64.0, 46.0, 36.0, 30.0, 26.0, 21.0],
    };
    for (final (index, level) in TextLevel.values.indexed) {
      _levels[level]!.size = sizes[index];
    }
  }

  int _headlineWeight(String direction, TextLevel level) {
    if (level == TextLevel.h1) {
      return switch (direction) {
        'minimal' => 500,
        'bold' => 800,
        _ => 700,
      };
    }
    return direction == 'minimal' ? 500 : 600;
  }

  FontWeight _fontWeightFor(int value) => FontWeight.values.firstWhere(
    (weight) => weight.value == value,
    orElse: () => FontWeight.w400,
  );
}
