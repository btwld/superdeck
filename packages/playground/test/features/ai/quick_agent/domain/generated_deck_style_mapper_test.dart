import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart';
import 'package:playground/features/ai/quick_agent/domain/generated_deck_style_mapper.dart';

void main() {
  test('maps generated palette and typography into renderer style', () {
    final source = DeckStyleType.parse({
      'name': 'Technical editorial',
      'direction': 'technical',
      'density': 'compact',
      'typeScale': 'dense',
      'colors': {
        'background': '#102030',
        'surface': '#203040',
        'surfaceAlt': '#304050',
        'heading': '#F0E0D0',
        'body': '#D0C0B0',
        'accent': '#A0B0C0',
        'accentContrast': '#001020',
      },
      'fonts': {'headline': 'Bebas Neue', 'body': 'Inter'},
    });

    final result = source.toGeneratedDeckStyle();

    expect(result.background, const Color(0xFF102030));
    expect(result.surface, const Color(0xFF203040));
    expect(result.surfaceAlt, const Color(0xFF304050));
    expect(result.heading, const Color(0xFFF0E0D0));
    expect(result.body, const Color(0xFFD0C0B0));
    expect(result.accent, const Color(0xFFA0B0C0));
    expect(result.accentContrast, const Color(0xFF001020));
    expect(result.headlineFamily, 'Bebas Neue');
    expect(result.bodyFamily, 'Inter');
    expect(result.direction, 'technical');
    expect(result.density, 'compact');
    expect(result.typeScale, 'dense');
  });
}
