import 'package:mermaid_core/mermaid_core.dart';

import 'vendor/flowchart_strict_parser.dart';

/// Rejects flowchart sources that the renderer would draw incompletely.
///
/// The Dart Mermaid port accepts two inputs mermaid.js rejects, and renders
/// something plausible rather than reporting them: an unquoted `[` inside a
/// node label, and a tilde link carrying an arrow head. Both lose part of the
/// author's diagram without saying so, which a slide cannot afford.
///
/// The check runs the vendored copy of the port's own flowchart parser, which
/// differs from it only in those two places, so it accepts exactly what the
/// renderer accepts otherwise. Other diagram families are left to the
/// renderer, which already reports what it cannot parse.
///
/// Throws [MermaidParseException] with the offending line.
void checkMermaidSource(String source) {
  if (detectDiagramType(source) != DiagramType.flowchart) return;
  strictParseFlowchart(source);
}
