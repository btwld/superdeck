import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart' show SlideParts;
import 'package:superdeck/src/markdown/builders/mermaid_code_block.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../helpers/slide_test_harness.dart';

void main() {
  group('Mermaid fenced code rendering', () {
    testWidgets('routes Mermaid fences to the runtime diagram renderer', (
      tester,
    ) async {
      await SlideTestHarness.pumpSlide(
        tester,
        _slideWithFence('''
graph TD
  A[Start] --> B[Finish]
'''),
        resolution: const Size(800, 600),
      );

      expect(find.byType(MermaidDiagram), findsOneWidget);
      final diagram = tester.widget<MermaidDiagram>(
        find.byType(MermaidDiagram),
      );
      expect(diagram.style?.backgroundColor, 0x00000000);
    });

    testWidgets('uses legible Mermaid colors with a dark app theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: MermaidCodeBlock(
              code: '''
graph LR
  A[Start] -->|Next| B[Finish]
''',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final diagram = tester.widget<MermaidDiagram>(
        find.byType(MermaidDiagram),
      );
      expect(diagram.style?.themeMode, MermaidThemeMode.dark);
      expect(diagram.style?.backgroundColor, 0x00000000);
      expect(diagram.style?.defaultEdgeStyle.labelColor, 0xFFE0E0E0);
    });

    testWidgets('keeps non-Mermaid fences on the code rendering path', (
      tester,
    ) async {
      await SlideTestHarness.pumpSlide(
        tester,
        Slide(
          key: 'dart-code',
          sections: [
            SectionBlock([
              ContentBlock('''
```dart
void main() {}
```
'''),
            ]),
          ],
        ),
        resolution: const Size(800, 600),
      );

      expect(find.byType(MermaidDiagram), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('void main'),
        ),
        findsWidgets,
      );
    });

    testWidgets('does not paint an opaque code wrapper behind the diagram', (
      tester,
    ) async {
      await SlideTestHarness.pumpSlide(
        tester,
        _slideWithFence('''
graph TD
  A[Start] --> B[Finish]
'''),
        resolution: const Size(800, 600),
        parts: const SlideParts(header: null, footer: null),
      );

      final opaqueCodeWrappers = <BoxDecoration>[];
      tester.element(find.byType(MermaidDiagram)).visitAncestorElements((
        ancestor,
      ) {
        if (ancestor.widget is MarkdownBody) return false;

        final decoration = switch (ancestor.widget) {
          Container(:final decoration) => decoration,
          DecoratedBox(:final decoration) => decoration,
          _ => null,
        };
        if (decoration case BoxDecoration(
          color: final color?,
        ) when color.a > 0) {
          opaqueCodeWrappers.add(decoration);
        }

        return true;
      });

      expect(opaqueCodeWrappers, isEmpty);
    });

    for (final diagram in _supportedDiagrams.entries) {
      for (final resolution in const [Size(480, 320), Size(1440, 900)]) {
        testWidgets('renders ${diagram.key} at '
            '${resolution.width.toInt()}x${resolution.height.toInt()}', (
          tester,
        ) async {
          await SlideTestHarness.pumpSlide(
            tester,
            _slideWithFence(diagram.value),
            resolution: resolution,
            parts: const SlideParts(header: null, footer: null),
          );

          final mermaidFinder = find.byType(MermaidDiagram);
          final paintFinder = find.descendant(
            of: mermaidFinder,
            matching: find.byType(CustomPaint),
          );

          expect(mermaidFinder, findsOneWidget);
          expect(paintFinder, findsOneWidget);
          expect(
            find.textContaining('Unable to render Mermaid diagram'),
            findsNothing,
          );

          final diagramSize = tester.getSize(mermaidFinder);
          final paintSize = tester.getSize(paintFinder);
          expect(diagramSize.width, greaterThan(0));
          expect(diagramSize.width, lessThanOrEqualTo(resolution.width));
          expect(paintSize.width, greaterThan(0));
          expect(paintSize.height, greaterThan(0));
          expect(paintSize.width, lessThanOrEqualTo(diagramSize.width));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('shows an inline error for unsupported diagram syntax', (
      tester,
    ) async {
      await SlideTestHarness.pumpSlide(
        tester,
        _slideWithFence('''
classDiagram
  class Animal
'''),
        resolution: const Size(800, 600),
      );

      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(
        find.textContaining('Unable to render Mermaid diagram'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Slide _slideWithFence(String source) {
  return Slide(
    key: 'mermaid-diagram',
    sections: [
      SectionBlock([
        ContentBlock('''
```mermaid
${source.trim()}
```
'''),
      ]),
    ],
  );
}

const _supportedDiagrams = <String, String>{
  'flowchart': '''
graph TD
  A[Start] --> B{Ready?}
  B -->|Yes| C[Ship]
  B -->|No| D[Revise]
''',
  'sequence diagram': '''
sequenceDiagram
  participant Author
  participant SuperDeck
  Author->>SuperDeck: Render diagram
  SuperDeck-->>Author: Painted slide
''',
  'pie chart': '''
pie
  title Diagram usage
  "Flowcharts" : 55
  "Sequences" : 30
  "Other" : 15
''',
  'Gantt chart': '''
gantt
  title Launch plan
  dateFormat YYYY-MM-DD
  Outline :done, outline, 2025-01-06, 1d
  Build deck :active, deck, 2025-01-07, 2d
''',
  'timeline': '''
timeline
  title Product milestones
  Prototype : First demo
  Launch : Public release
''',
  'Kanban board': '''
kanban
  todo[To Do]
    task1[Write outline]
  doing[In Progress]
    task2[Build slides]
  done[Done]
    task3[Choose topic]
''',
  'radar chart': '''
radar-beta
  title Renderer qualities
  axis Speed, Portability, Fidelity, Simplicity
  curve runtime{5, 5, 3, 5}
''',
  'XY chart': '''
xychart-beta
  title "Render time"
  x-axis [Small, Medium, Large]
  y-axis "Milliseconds" 0 --> 100
  bar [20, 45, 80]
''',
};
