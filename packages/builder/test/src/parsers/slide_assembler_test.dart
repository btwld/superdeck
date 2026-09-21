import 'dart:convert';
import 'dart:io';

import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// The assembly the CLI build and the editor preview share.
///
/// The two used to hold identical copies of these four calls. These tests fix
/// what the shared function produces, over the decks the repository actually
/// ships, so a future change to one consumer cannot quietly change the other.
void main() {
  String canonical(List<Slide> slides) =>
      jsonEncode([for (final slide in slides) slide.toJson()]);

  group('assembleSlides', () {
    test('reads front matter, sections and comments off one slide', () {
      final slides = assembleSlides('''
---
title: Opening
layout: fullscreen
---

# Hello

<!-- a speaker note -->

@section
Body text
''');

      expect(slides, hasLength(1));
      final slide = slides.single;
      expect(slide.options?.title, 'Opening');
      expect(slide.sections, isNotEmpty);
      expect(slide.comments, contains('a speaker note'));
    });

    test('splits a deck the way the separators say', () {
      final slides = assembleSlides('# One\n\n---\n\n# Two\n\n---\n\n# Three\n');

      expect(slides, hasLength(3));
      expect(slides.map((slide) => slide.key).toSet(), hasLength(3));
    });

    test('reports invalid recognized front matter', () {
      expect(
        () => assembleSlides('---\ntitle: "unclosed\n---\nBody\n'),
        throwsFormatException,
      );
    });

    test('assembles the demo deck', () {
      final demo = File('../../demo/slides.md');
      if (!demo.existsSync()) {
        markTestSkipped('demo/slides.md not found');

        return;
      }

      final slides = assembleSlides(demo.readAsStringSync());

      expect(slides, hasLength(greaterThan(20)));
      expect(
        slides.every((slide) => slide.key.isNotEmpty),
        isTrue,
        reason: 'every slide is addressable',
      );
      // Assembling twice is the same deck: no counters, clocks or randomness.
      expect(canonical(assembleSlides(demo.readAsStringSync())),
          canonical(slides));
    });
  });
}
