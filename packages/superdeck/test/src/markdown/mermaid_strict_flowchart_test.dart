import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_core/mermaid_core.dart';
import 'package:mermaid_flutter/mermaid_flutter.dart';
import 'package:superdeck/src/markdown/builders/mermaid_code_block.dart';
import 'package:superdeck/src/markdown/mermaid/mermaid_source_check.dart';

/// The two inputs mermaid.js rejects and mermaid_core 0.3.0 draws anyway.
///
/// Ground truth recorded against mermaid.js 12.0.0 via `mermaid.parse`:
/// both are syntax errors there. Upstream Dart renders one node labelled
/// "Start --> B[Finish" for the first, and two nodes with an invisible edge
/// for the second.
const _unbalancedBracket = 'graph TD\n  A[Start --> B[Finish]\n';
const _tildeArrow = 'graph TD\n  A ~~> B\n';

void main() {
  group('strict flowchart check', () {
    test('rejects an unquoted bracket inside a node label', () {
      expect(
        () => checkMermaidSource(_unbalancedBracket),
        throwsA(
          isA<MermaidParseException>().having(
            (error) => error.line,
            'line',
            2,
          ),
        ),
      );
    });

    test('rejects a tilde link carrying an arrow head', () {
      expect(
        () => checkMermaidSource(_tildeArrow),
        throwsA(
          isA<MermaidParseException>().having(
            (error) => error.message,
            'message',
            contains('~~~'),
          ),
        ),
      );
    });

    test('keeps a quoted bracket, which mermaid.js accepts', () {
      expect(
        () => checkMermaidSource('graph TD\n  A["array [0]"] --> B\n'),
        returnsNormally,
      );
    });

    test('keeps the invisible link mermaid.js does define', () {
      expect(
        () => checkMermaidSource('graph TD\n  A ~~~ B\n'),
        returnsNormally,
      );
    });

    test('accepts representative flowchart shapes, styles and directives', () {
      const sources = [
        'flowchart TB\n  subgraph one\n    A --> B\n  end\n  B --> C\n',
        'flowchart TD\n  A([round]) --> B[[sub]] --> C[(db)]\n'
            '  C --> D((circle)) --> E{{hex}} --> F[/para/]\n',
        'graph LR\n  A[🚀 Launch] --> B[✅ Done]\n',
        'graph LR\n  A["`**bold** label`"] --> B\n',
        'graph LR\n  A --> B\n  classDef hot fill:#f96\n  class A hot\n',
        'graph LR\n  A --> B\n  linkStyle 0 stroke:#f00\n',
        'graph LR\n  A[Open] --> B\n  click A "https://example.com" "Tip"\n',
        '%%{init: {"flowchart": {"defaultRenderer": "elk"}}}%%\n'
            'flowchart TD\n  A --> B\n',
        '---\nconfig:\n  look: handDrawn\n---\nflowchart LR\n  A --> B\n',
        'graph LR\n  %% a comment\n  A -- label --> B\n',
        'graph LR\n  A -.-> B ==> C\n',
      ];

      for (final source in sources) {
        expect(
          () => checkMermaidSource(source),
          returnsNormally,
          reason: source,
        );
      }
    });

    test('leaves other diagram families to the renderer', () {
      // A sequence diagram the strict flowchart parser would not understand.
      expect(
        () => checkMermaidSource('sequenceDiagram\n  A->>B: hi\n'),
        returnsNormally,
      );
    });
  });

  group('the slide reports what it cannot draw', () {
    Future<void> pumpDiagram(WidgetTester tester, String code) {
      return tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MermaidCodeBlock(code: code))),
      );
    }

    testWidgets('an unbalanced bracket is reported, not drawn', (tester) async {
      await pumpDiagram(tester, _unbalancedBracket);
      await tester.pump();

      expect(find.byType(MermaidDiagram), findsNothing);
      expect(
        find.textContaining('Unable to render Mermaid diagram'),
        findsOneWidget,
      );
    });

    testWidgets('a tilde arrow is reported, not silently invisible', (
      tester,
    ) async {
      await pumpDiagram(tester, _tildeArrow);
      await tester.pump();

      expect(find.byType(MermaidDiagram), findsNothing);
      expect(
        find.textContaining('Unable to render Mermaid diagram'),
        findsOneWidget,
      );
    });

    testWidgets('a valid diagram still draws', (tester) async {
      await pumpDiagram(tester, 'graph TD\n  A[Start] --> B[End]\n');
      await tester.pump();

      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(
        find.textContaining('Unable to render Mermaid diagram'),
        findsNothing,
      );
    });
  });
}
