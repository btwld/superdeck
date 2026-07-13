import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';

import '../../domain/stores/deck_file_controller.dart';
import '../../domain/stores/editor_store.dart';
import '../widgets/customization_sidebar.dart';
import '../widgets/editor_controls.dart';
import '../widgets/new_deck_dialog.dart';
import '../widgets/preview_sidebar.dart';
import '../widgets/text_editor.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EditorStore>();
    final fileController = context.read<DeckFileController>();

    // ⌘N / ⌘O drive the file operations; the file operations otherwise live in
    // the header. Focus (autofocus) gives the shortcuts a target so they work
    // before the editor is clicked, without stealing focus once it is.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
            showNewDeckDialog(context, fileController),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true):
            fileController.openDeck,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: $background.resolve(context),
          body: Box(
            style: BoxStyler().color($background()),
            child: RowBox(
              children: [
                _AnimatedSidebar(
                  visible: store.showPreviewSidebar,
                  alignment: Alignment.centerLeft,
                  child: const PreviewSidebar(),
                ),

                // The filename bar sits on top of the editor pane only, not
                // spanning the sidebars.
                Expanded(
                  child: Stack(
                    children: [
                      const TextEditor(),
                      Align(
                        alignment: .bottomCenter,
                        child: Padding(
                          padding: const .only(bottom: 24),
                          child: EditorControls(
                            showPreviewSidebar: store.showPreviewSidebar,
                            showCustomizationSidebar:
                                store.showCustomizationSidebar,
                            onTogglePreviewSidebar: store.togglePreviewSidebar,
                            onToggleCustomizationSidebar:
                                store.toggleCustomizationSidebar,
                          ),
                        ),
                      ),
                      if (store.showPreviewSidebar)
                        Align(
                          alignment: .centerLeft,
                          child: _SidebarResizeHandle(
                            onDrag: (delta) =>
                                store.previewSidebarWidth += delta,
                          ),
                        ),
                      if (store.showCustomizationSidebar)
                        Align(
                          alignment: .centerRight,
                          child: _SidebarResizeHandle(
                            onDrag: (delta) =>
                                store.customizationSidebarWidth -= delta,
                          ),
                        ),
                    ],
                  ),
                ),
                _AnimatedSidebar(
                  visible: store.showCustomizationSidebar,
                  alignment: Alignment.centerRight,
                  child: const CustomizationSidebar(),
                ),
              ],
            ),
          ),
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

/// A thin vertical grabber that reports horizontal drag deltas.
///
/// Sits between a sidebar and the editor. [onDrag] receives the pointer's
/// horizontal movement in logical pixels (positive = rightward); callers map
/// that onto their sidebar's width, so a left sidebar grows while a right one
/// shrinks for the same rightward drag.
class _SidebarResizeHandle extends StatefulWidget {
  const _SidebarResizeHandle({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    // Bar highlights while dragging; hover lights it up too. The color change
    // tweens via `.animate`, replacing the former AnimatedContainer.
    final bar = BoxStyler()
        .width(7)
        .height(48)
        .borderRadius(.circular(10))
        .color(_active ? $accent() : $border())
        .animate(AnimationConfig.ease(const Duration(milliseconds: 120)));

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _active = true),
        onHorizontalDragUpdate: (details) => widget.onDrag(details.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _active = false),
        onHorizontalDragCancel: () => setState(() => _active = false),
        child: Box(style: bar),
      ),
    );
  }
}
