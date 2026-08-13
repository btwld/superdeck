import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/features/ai/quick_agent/domain/generated_deck_style_mapper.dart';

void main() {
  test('maps generated palette and typography into renderer style', () {
    final source = PresentationThemeCatalog.withDefaults().resolve(
      id: 'technical-paper',
      version: 1,
      density: 'compact',
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );

    final result = source.toGeneratedDeckStyle();

    expect(result.background, const Color(0xFFF5F7FA));
    expect(result.surface, const Color(0xFFFFFFFF));
    expect(result.surfaceAlt, const Color(0xFFE7EDF4));
    expect(result.heading, const Color(0xFF102A43));
    expect(result.body, const Color(0xFF243B53));
    expect(result.accent, const Color(0xFF0967D2));
    expect(result.accentContrast, const Color(0xFFFFFFFF));
    expect(result.headlineFamily, 'Space Grotesk');
    expect(result.bodyFamily, 'Open Sans');
    expect(result.direction, 'technical');
    expect(result.density, 'compact');
    expect(result.typeScale, 'balanced');
    expect(result.runtime, same(source.descriptor.recipe.runtime));
  });
}
