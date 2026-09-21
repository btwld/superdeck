import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:mermaid_flutter/mermaid_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart'
    show SlideCaptureReadiness, SlideParts;
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
      expect(diagram.theme.background.value, 0x00000000);
      expect(
        diagram.keepLastGoodSceneOnError,
        isFalse,
        reason: 'a slide must not export a stale diagram',
      );
      expect(diagram.semanticNodes, isTrue);
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
      final dark = ThemeData.dark().colorScheme;
      expect(diagram.theme.background.value, 0x00000000);
      expect(
        diagram.theme.primaryColor.value,
        dark.primaryContainer.toARGB32(),
        reason: 'diagram fills follow the app colour scheme',
      );
      expect(diagram.theme.primaryTextColor.value, dark.onPrimaryContainer.toARGB32());
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
          final fittedFinder = find.ancestor(
            of: mermaidFinder,
            matching: find.byType(FittedBox),
          );

          expect(mermaidFinder, findsOneWidget);
          expect(paintFinder, findsOneWidget);
          expect(
            find.textContaining('Unable to render Mermaid diagram'),
            findsNothing,
          );

          // The diagram keeps its natural scene size and is scaled down to
          // the width its Markdown block was given. Height flows like the
          // rest of the block's content.
          final shownSize = tester.getSize(fittedFinder.first);
          final paintSize = tester.getSize(paintFinder);
          expect(shownSize.width, greaterThan(0));
          expect(shownSize.width, lessThanOrEqualTo(resolution.width));
          expect(paintSize.width, greaterThan(0));
          expect(paintSize.height, greaterThan(0));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('shows an inline error for a diagram it cannot parse', (
      tester,
    ) async {
      await SlideTestHarness.pumpSlide(
        tester,
        _slideWithFence('''
graph TD
  A[Start] --> B[End]
  this line is prose, not a statement
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

    testWidgets('a rendered diagram releases the capture wait', (tester) async {
      final readiness = SlideCaptureReadiness();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: readiness.bind(
              const MermaidCodeBlock(code: 'graph TD\n  A --> B\n'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(readiness.isReady, isTrue);
      expect(readiness.failures, isEmpty);
    });

    testWidgets('a diagram that cannot render fails the capture wait', (
      tester,
    ) async {
      final readiness = SlideCaptureReadiness();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: readiness.bind(
              const MermaidCodeBlock(
                code: 'graph TD\n  A --> B\n  this is prose\n',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Export stops on this slide instead of writing a page without it.
      expect(readiness.isReady, isTrue);
      expect(readiness.failures, hasLength(1));
      expect(readiness.failures.single.label, startsWith('mermaid:'));
    });

    testWidgets('names an unknown diagram type instead of drawing nothing', (
      tester,
    ) async {
      await SlideTestHarness.pumpSlide(
        tester,
        _slideWithFence('''
notADiagramType
  A --> B
'''),
        resolution: const Size(800, 600),
      );

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
  'class diagram': '''
classDiagram
  Animal <|-- Duck
  Animal : +int age
  Animal : +isMammal()
  class Duck {
    +String beakColor
    +swim()
  }
''',
  'state diagram': '''
stateDiagram-v2
  [*] --> Draft
  Draft --> Review: submit
  Review --> Draft: changes
  Review --> [*]: approve
''',
  'entity relationship diagram': '''
erDiagram
  DECK ||--o{ SLIDE : contains
  SLIDE ||--o{ BLOCK : holds
''',
  'user journey': '''
journey
  title Preparing a talk
  section Draft
    Outline the story: 4: Speaker
    Write the slides: 3: Speaker
''',
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
