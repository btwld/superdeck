import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';
import 'package:superdeck/superdeck.dart';

/// Neutral fallbacks used when no theme-resolved seed colors are supplied
/// (e.g. in unit tests). Production wiring passes the resolved `$background` /
/// `$foreground` tokens from the provider's context.
const _defaultBackground = Color(0xFF000000);
const _defaultForeground = Color(0xFFFFFFFF);

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
  'Montserrat',
  'Poppins',
  'Oswald',
  'Lobster',
  'Open Sans',
  'Lato',
  'Source Serif 4',
];

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

/// Immutable typography value captured at an AI session boundary.
@immutable
final class TextLevelStyleSnapshot {
  const TextLevelStyleSnapshot({
    required this.color,
    required this.size,
    required this.weight,
    required this.family,
  });

  final Color color;
  final double size;
  final int weight;
  final String family;

  TextLevelStyleSnapshot copyWith({Color? color, String? family}) {
    return TextLevelStyleSnapshot(
      color: color ?? this.color,
      size: size,
      weight: weight,
      family: family ?? this.family,
    );
  }
}

/// Deep immutable copy of all deck-wide manual customization state.
@immutable
final class DeckCustomizationSnapshot {
  DeckCustomizationSnapshot({
    required this.background,
    required Map<TextLevel, TextLevelStyleSnapshot> levels,
  }) : _levels = Map<TextLevel, TextLevelStyleSnapshot>.unmodifiable(levels);

  final Color background;
  final Map<TextLevel, TextLevelStyleSnapshot> _levels;

  TextLevelStyleSnapshot level(TextLevel level) => _levels[level]!;

  DeckCustomizationSnapshot copyWith({
    Color? background,
    Map<TextLevel, TextLevelStyleSnapshot>? levels,
  }) {
    return DeckCustomizationSnapshot(
      background: background ?? this.background,
      levels: levels ?? _levels,
    );
  }
}

/// Owns the playground's deck-wide customization state and pushes a fresh
/// [DeckOptions] into the [DeckController] on every change.
///
/// Ported from the signal-based original to a plain [ChangeNotifier]: each
/// mutation updates a field, rebuilds the [DeckOptions], writes it to the
/// controller, and notifies. All state is in-memory; reloading resets to the
/// seeded defaults. The AI-style entry point (`applyFromAiStyle`) is omitted —
/// this slice ships without AI.
class DeckCustomizationStore extends ChangeNotifier {
  DeckCustomizationStore(
    this._controller, {
    Color background = _defaultBackground,
    Color foreground = _defaultForeground,
  }) : _background = background {
    _levels = {
      TextLevel.h1: TextLevelStyle(
        color: foreground,
        size: 40,
        weight: 700,
        family: 'Inter',
      ),
      TextLevel.h2: TextLevelStyle(
        color: foreground,
        size: 32,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h3: TextLevelStyle(
        color: foreground,
        size: 24,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h4: TextLevelStyle(
        color: foreground,
        size: 20,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h5: TextLevelStyle(
        color: foreground,
        size: 18,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.h6: TextLevelStyle(
        color: foreground,
        size: 16,
        weight: 600,
        family: 'Inter',
      ),
      TextLevel.p: TextLevelStyle(
        color: foreground,
        size: 18,
        weight: 400,
        family: 'Inter',
      ),
    };
    // Seed the controller's options once (replaces the old startup effect).
    _pushOptions();
  }

  final DeckController _controller;

  Color _background;

  late final Map<TextLevel, TextLevelStyle> _levels;

  Color get background => _background;

  set background(Color value) {
    if (_background == value) return;
    _background = value;
    _apply();
  }

  TextLevelStyle level(TextLevel level) => _levels[level]!;

  DeckCustomizationSnapshot captureSnapshot() {
    return DeckCustomizationSnapshot(
      background: _background,
      levels: {
        for (final entry in _levels.entries)
          entry.key: TextLevelStyleSnapshot(
            color: entry.value.color,
            size: entry.value.size,
            weight: entry.value.weight,
            family: entry.value.family,
          ),
      },
    );
  }

  void restoreSnapshot(DeckCustomizationSnapshot snapshot) {
    _background = snapshot.background;
    for (final level in TextLevel.values) {
      final source = snapshot.level(level);
      final target = _levels[level]!;
      target
        ..color = source.color
        ..size = source.size
        ..weight = source.weight
        ..family = source.family;
    }
    _apply();
  }

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
    if (target.family == family) return;
    target.family = family;
    _apply();
  }

  /// Rebuilds and pushes [DeckOptions], then notifies listeners.
  void _apply() {
    _pushOptions();
    notifyListeners();
  }

  void _pushOptions() {
    _controller.options.value = DeckOptions(
      baseStyle: SlideStyler(
        h1: _stylerFor(TextLevel.h1),
        h2: _stylerFor(TextLevel.h2),
        h3: _stylerFor(TextLevel.h3),
        h4: _stylerFor(TextLevel.h4),
        h5: _stylerFor(TextLevel.h5),
        h6: _stylerFor(TextLevel.h6),
        p: _stylerFor(TextLevel.p),
        list: .new(
          bullet: _stylerFor(TextLevel.p),
          text: _stylerFor(TextLevel.p),
        ),
      ),
      parts: SlideParts(background: Box(style: BoxStyler().color(_background))),
    );
  }

  TextStyler _stylerFor(TextLevel level) {
    final style = _levels[level]!;
    return _buildTextStyler(
      color: style.color,
      size: style.size,
      weight: style.weight,
      family: style.family,
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

  FontWeight _fontWeightFor(int value) => FontWeight.values.firstWhere(
    (weight) => weight.value == value,
    orElse: () => FontWeight.w400,
  );
}
