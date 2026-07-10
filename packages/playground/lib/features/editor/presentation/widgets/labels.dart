import 'package:flutter/widgets.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';

/// A muted, small-caps label for an individual control (e.g. "Size", "Weight").
class ControlLabel extends StatelessWidget {
  const ControlLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return StyledText(
      text,
      style: TextStyler().color($muted()).style($labelSmall.mix()),
    );
  }
}

/// A foreground, medium-weight label heading a group of controls
/// (e.g. "Background").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return StyledText(
      text,
      style: TextStyler()
          .color($foreground())
          .style($labelMedium.mix())
          .wrap(.padding(.vertical(4))),
    );
  }
}
