import 'package:super_editor/super_editor.dart';

/// Pure document queries mapping between the caret and slide boundaries.
///
/// Slides are delimited by `---` separator lines; the first `---` is the
/// frontmatter separator. Kept free of editor state so they can be unit-tested
/// against a plain [MutableDocument].

/// Whether [text] is a slide separator line (`---`, ignoring surrounding
/// whitespace). The single source of truth for the separator rule, shared with
/// the syntax-highlighting reactions.
bool isSlideSeparator(String text) => text.trim() == '---';

bool _isSeparator(DocumentNode node) =>
    node is TextNode && isSlideSeparator(node.text.toPlainText());

/// The 0-based slide the node [nodeId] falls in. Anything before/at the first
/// `---` maps to slide 0.
int slideIndexForNode(MutableDocument document, String nodeId) {
  var separatorCount = 0;
  for (final node in document) {
    if (node.id == nodeId) break;
    if (_isSeparator(node)) separatorCount++;
  }
  return (separatorCount - 1).clamp(0, separatorCount);
}

/// The node id that starts slide [index]'s content — the node just after the
/// (index+1)th `---` separator, or the separator itself when the slide is still
/// empty. Null if that separator doesn't exist yet.
String? firstNodeOfSlide(MutableDocument document, int index) {
  var separatorCount = 0;
  for (final node in document) {
    if (!_isSeparator(node)) continue;
    if (++separatorCount != index + 1) continue;
    final nodeIndex = document.getNodeIndexById(node.id);
    if (nodeIndex + 1 < document.length) {
      return document.getNodeAt(nodeIndex + 1)!.id;
    }
    return node.id;
  }
  return null;
}
