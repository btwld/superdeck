/// Port for replacing the editor's whole document.
///
/// Implemented by the presentation-layer `TextEditorController` and driven by AI
/// generation, so the agent command depends on this capability (a domain type)
/// rather than the concrete, super_editor-coupled controller.
abstract interface class MarkdownEditor {
  /// Replaces the entire editor document with [markdown].
  void replaceMarkdown(String markdown);
}
