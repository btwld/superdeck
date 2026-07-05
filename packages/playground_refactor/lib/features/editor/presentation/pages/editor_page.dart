import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';

import '../../domain/stores/editor_store.dart';
import '../widgets/customization_sidebar.dart';
import '../widgets/editor_controls.dart';
import '../widgets/preview_sidebar.dart';
import '../widgets/text_editor.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EditorStore>();

    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: Box(
        style: BoxStyler().color($background()),
        child: Stack(
          children: [
            RowBox(
              children: [
                _AnimatedSidebar(
                  visible: store.showPreviewSidebar,
                  alignment: Alignment.centerLeft,
                  child: const PreviewSidebar(),
                ),
                const Expanded(child: TextEditor()),
                _AnimatedSidebar(
                  visible: store.showCustomizationSidebar,
                  alignment: Alignment.centerRight,
                  child: const CustomizationSidebar(),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: EditorControls(
                  showPreviewSidebar: store.showPreviewSidebar,
                  showCustomizationSidebar: store.showCustomizationSidebar,
                  onTogglePreviewSidebar: store.togglePreviewSidebar,
                  onToggleCustomizationSidebar: store.toggleCustomizationSidebar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapses [child] horizontally when [visible] is false.
///
/// The child keeps its intrinsic width and is clipped to the animating box, so
/// the sidebar appears to fold toward [alignment]'s edge while the editor
/// smoothly claims the freed space.
class _AnimatedSidebar extends StatelessWidget {
  const _AnimatedSidebar({
    required this.visible,
    required this.alignment,
    required this.child,
  });

  static const _duration = Duration(milliseconds: 250);
  static const _curve = Curves.easeInOutCubic;

  final bool visible;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        alignment: alignment,
        widthFactor: visible ? 1.0 : 0.0,
        duration: _duration,
        curve: _curve,
        child: child,
      ),
    );
  }
}
