import '../schemas/outline_schema.dart';
import 'design_quality_metrics.dart';

/// Repairs mechanically derived deck-plan values without changing its content.
///
/// The model chooses the accent color, but `accentContrast` exists only to make
/// content readable on that accent. When the proposed foreground misses WCAG AA,
/// derive the safest monochrome foreground locally instead of spending another
/// model request on deterministic color arithmetic.
DeckPlanType normalizeDeckPlanAccentContrast(DeckPlanType plan) {
  final colors = plan.style.colors;
  if (calculateContrastRatio(colors.accentContrast, colors.accent) >= 4.5) {
    return plan;
  }

  final normalizedColors = Map<String, Object?>.from(colors)
    ..['accentContrast'] = mostReadableMonochromeForeground(colors.accent);
  final normalizedStyle = Map<String, Object?>.from(plan.style)
    ..['colors'] = normalizedColors;
  final normalizedPlan = Map<String, Object?>.from(plan)
    ..['style'] = normalizedStyle;
  return DeckPlanType.parse(normalizedPlan);
}
