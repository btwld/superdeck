import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

/// Large display text for main headings.
///
/// Usage: `SdHeadline('Welcome')`
/// Override: `SdHeadline('Welcome', style: TextStyler().fontWeight(FontWeight.bold))`
class SdHeadline extends StatelessWidget {
  const SdHeadline(this.text, {super.key, this.style});

  final String text;
  final TextStyler? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyler()
        .style($titleH5.mix())
        .color($foreground());
    return defaultStyle.merge(style).call(text);
  }
}

/// Section title text.
///
/// Usage: `SdTitle('Settings')`
/// Override: `SdTitle('Settings', style: TextStyler().fontWeight(FontWeight.w600))`
class SdTitle extends StatelessWidget {
  const SdTitle(this.text, {super.key, this.style});

  final String text;
  final TextStyler? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyler()
        .style($paragraphLarge.mix())
        .color($foreground());
    return defaultStyle.merge(style).call(text);
  }
}

/// Regular body text.
///
/// Usage: `SdBody('Description here')`
/// Override: `SdBody('Text', style: TextStyler().color($accent()))`
class SdBody extends StatelessWidget {
  const SdBody(this.text, {super.key, this.style});

  final String text;
  final TextStyler? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyler()
        .style($paragraphMedium.mix())
        .color($muted());
    return defaultStyle.merge(style).call(text);
  }
}

/// Small secondary text for labels and captions.
///
/// Usage: `SdCaption('Updated 2 hours ago')`
/// Override: `SdCaption('Text', style: TextStyler().color($accent()))`
class SdCaption extends StatelessWidget {
  const SdCaption(this.text, {super.key, this.style});

  final String text;
  final TextStyler? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyler()
        .style($paragraphSmall.mix())
        .color($muted());
    return defaultStyle.merge(style).call(text);
  }
}

/// Subtle hint text.
///
/// Usage: `SdHint('Enter your name')`
/// Override: `SdHint('Hint', style: TextStyler().fontStyle(FontStyle.italic))`
class SdHint extends StatelessWidget {
  const SdHint(this.text, {super.key, this.style});

  final String text;
  final TextStyler? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyler()
        .style($paragraphSmall.mix())
        .color($fieldPlaceholder());
    return defaultStyle.merge(style).call(text);
  }
}
