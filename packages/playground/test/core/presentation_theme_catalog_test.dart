import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_color_contrast.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';

void main() {
  group('PresentationThemeCatalog', () {
    test('ships twelve described, materially distinct versioned themes', () {
      final catalog = PresentationThemeCatalog.withDefaults();

      expect(catalog.themes, hasLength(12));
      expect(
        catalog.currentThemes.map((theme) => theme.id),
        defaultPresentationThemeIds,
      );
      expect(
        catalog.themes.map((theme) => '${theme.id}@${theme.version}').toSet(),
        hasLength(catalog.themes.length),
      );
      expect(
        catalog.themes.every((theme) => theme.description.trim().isNotEmpty),
        isTrue,
      );
      expect(
        catalog.themes.map((theme) => theme.recipe.direction).toSet(),
        presentationThemeDirections.toSet(),
      );
      expect(
        catalog.themes
            .map(
              (theme) => [
                theme.recipe.headlineFamily,
                theme.recipe.bodyFamily,
                theme.recipe.direction,
                theme.recipe.defaultDensity,
                theme.recipe.typeScale,
              ].join('|'),
            )
            .toSet(),
        hasLength(catalog.themes.length),
      );
    });

    test(
      'model projection never exposes palette, font, or runtime recipes',
      () {
        final theme = PresentationThemeCatalog.withDefaults().themes.first;

        final projection = theme.toModelCandidate();
        final serialized = projection.toString();

        expect(projection.keys, {'id', 'title', 'description', 'tags'});
        final tags = projection['tags']! as List<String>;
        expect(tags.toSet(), hasLength(tags.length));
        expect(serialized, isNot(contains('#')));
        expect(serialized, isNot(contains(theme.recipe.headlineFamily)));
        expect(serialized, isNot(contains(theme.recipe.bodyFamily)));
        expect(serialized, isNot(contains('typeScale')));
      },
    );

    test('each theme owns a complete renderer recipe', () {
      final themes = PresentationThemeCatalog.withDefaults().currentThemes;

      for (final theme in themes) {
        final runtime = theme.recipe.runtime;
        expect(
          runtime.treatments.names,
          presentationThemeTreatmentNames,
          reason: theme.id,
        );
        expect(
          runtime.spacingScale,
          inInclusiveRange(0.8, 1.2),
          reason: theme.id,
        );
        expect(runtime.cornerRadius, inInclusiveRange(0, 32), reason: theme.id);
        expect(runtime.borderWidth, inInclusiveRange(0, 3), reason: theme.id);
      }

      expect(
        themes.map((theme) => theme.recipe.runtime.surfaceStyle).toSet(),
        hasLength(3),
      );
      expect(
        themes.map((theme) => theme.recipe.runtime.decorativeStyle).toSet(),
        hasLength(greaterThanOrEqualTo(4)),
      );
    });

    test('every table surface remains legible in light and dark themes', () {
      final themes = PresentationThemeCatalog.withDefaults().currentThemes;

      for (final theme in themes) {
        final palette = theme.recipe.palette;
        final surface = switch (theme.recipe.runtime.surfaceStyle) {
          PresentationThemeSurfaceStyle.tonal => palette.surfaceAlt,
          PresentationThemeSurfaceStyle.flat ||
          PresentationThemeSurfaceStyle.outlined => palette.surface,
        };

        expect(
          calculatePresentationContrast(palette.body, surface),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.id} table body',
        );
        expect(
          calculatePresentationContrast(palette.heading, surface),
          greaterThanOrEqualTo(3),
          reason: '${theme.id} table heading',
        );
      }
    });

    test('unconstrained shortlist is deterministic and direction-diverse', () {
      final catalog = PresentationThemeCatalog.withDefaults();
      const criteria = PresentationThemeSelectionCriteria(
        userIntent: 'Create a clear presentation.',
      );

      final first = catalog.shortlist(criteria);
      final second = catalog.shortlist(criteria);

      expect(first.map((theme) => theme.id), second.map((theme) => theme.id));
      expect(
        first.map((theme) => theme.recipe.direction).toSet(),
        hasLength(presentationThemeDirections.length),
      );
    });

    test('hard constraints filter to an eligible described direction', () {
      final catalog = PresentationThemeCatalog.withDefaults();

      final candidates = catalog.shortlist(
        const PresentationThemeSelectionCriteria(
          userIntent: 'A reliability leadership narrative',
          designDirection: 'Editorial',
        ),
      );

      expect(candidates, hasLength(inInclusiveRange(3, 5)));
      expect(
        candidates.every((theme) => theme.directionTags.contains('editorial')),
        isTrue,
      );
    });

    test('an explicit theme wins over conflicting inferred direction', () {
      final catalog = PresentationThemeCatalog.withDefaults();

      final candidates = catalog.shortlist(
        const PresentationThemeSelectionCriteria(
          userIntent: 'A restrained editorial story',
          explicitThemeId: 'bold-product',
          designDirection: 'editorial',
        ),
      );

      expect(candidates.single.id, 'bold-product');
    });

    test('rejects unknown explicit and stale canonical references', () {
      final catalog = PresentationThemeCatalog.withDefaults();
      final typography = PresentationTypographyCatalog.withDefaults();

      expect(
        () => catalog.shortlist(
          const PresentationThemeSelectionCriteria(
            userIntent: 'Test',
            explicitThemeId: 'missing-theme',
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => catalog.resolve(
          id: 'editorial-midnight',
          version: 999,
          typographyCatalog: typography,
        ),
        throwsArgumentError,
      );
    });

    test('applies exact validated brand overrides over the base recipe', () {
      final catalog = PresentationThemeCatalog.withDefaults();
      final typography = PresentationTypographyCatalog.withDefaults();

      final resolved = catalog.resolve(
        id: 'technical-paper',
        version: 1,
        density: 'compact',
        typographyCatalog: typography,
        brandOverride: const PresentationThemeBrandOverride(
          background: '#FFFFFF',
          heading: '#111827',
          body: '#374151',
          headlineFamily: 'Montserrat',
          bodyFamily: 'Inter',
        ),
      );

      expect(resolved.palette.background, '#FFFFFF');
      expect(resolved.palette.heading, '#111827');
      expect(resolved.palette.body, '#374151');
      expect(resolved.headlineFamily, 'Montserrat');
      expect(resolved.bodyFamily, 'Inter');
      expect(resolved.density, 'compact');
      expect(
        resolved.palette.accent,
        resolved.descriptor.recipe.palette.accent,
      );
    });

    test('rejects a brand override that breaks readable contrast', () {
      final catalog = PresentationThemeCatalog.withDefaults();

      expect(
        () => catalog.resolve(
          id: 'technical-paper',
          version: 1,
          typographyCatalog: PresentationTypographyCatalog.withDefaults(),
          brandOverride: const PresentationThemeBrandOverride(
            background: '#FFFFFF',
            heading: '#FFFFFF',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rechecks every semantic treatment after a brand override', () {
      final catalog = PresentationThemeCatalog.withDefaults();

      expect(
        () => catalog.resolve(
          id: 'technical-paper',
          version: 1,
          typographyCatalog: PresentationTypographyCatalog.withDefaults(),
          brandOverride: const PresentationThemeBrandOverride(
            accent: '#F5F7FA',
            accentContrast: '#102A43',
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('quote heading'),
          ),
        ),
      );
    });
  });
}
