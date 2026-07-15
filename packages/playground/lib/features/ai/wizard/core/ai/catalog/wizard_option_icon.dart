import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Small, model-safe icon vocabulary for Wizard option cards.
///
/// Keeping this list semantic and constrained makes generated choices stable
/// while still giving adjacent cards distinct visual identities.
enum WizardOptionIcon {
  audience,
  business,
  education,
  global,
  goal,
  data,
  idea,
  launch,
  layers,
  presentation,
  story,
  sparkles;

  IconData get iconData => switch (this) {
    audience => LucideIcons.users,
    business => LucideIcons.briefcase,
    education => LucideIcons.graduationCap,
    global => LucideIcons.globe,
    goal => LucideIcons.target,
    data => LucideIcons.chartBar,
    idea => LucideIcons.lightbulb,
    launch => LucideIcons.rocket,
    layers => LucideIcons.layers,
    presentation => LucideIcons.presentation,
    story => LucideIcons.bookOpen,
    sparkles => LucideIcons.sparkles,
  };

  static WizardOptionIcon fallbackFor(int index) =>
      values[index % values.length];
}
