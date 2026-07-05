import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';

/// Bottom-centered overlay bar for the editor.
///
/// Purely presentational: the page owns the sidebar visibility flags and passes
/// them in along with the toggle callbacks. Each button lights up (`primary`)
/// when its sidebar is showing and dims (`ghost`) when it's hidden.
class EditorControls extends StatelessWidget {
  const EditorControls({
    required this.showPreviewSidebar,
    required this.showCustomizationSidebar,
    required this.onTogglePreviewSidebar,
    required this.onToggleCustomizationSidebar,
    super.key,
  });

  final bool showPreviewSidebar;
  final bool showCustomizationSidebar;
  final VoidCallback onTogglePreviewSidebar;
  final VoidCallback onToggleCustomizationSidebar;

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler()
          .spacing(8)
          .mainAxisSize(.min)
          .padding(.horizontal(12).vertical(8))
          .color($overlay())
          .shape(.stadium().side(.color($border()))),
      children: [
        HeroIconButton(
          variant: showPreviewSidebar ? .primary : .ghost,
          size: .sm,
          icon: Icons.grid_view_rounded,
          onPressed: onTogglePreviewSidebar,
        ),
        HeroIconButton(
          variant: showCustomizationSidebar ? .primary : .ghost,
          size: .sm,
          icon: Icons.tune_rounded,
          onPressed: onToggleCustomizationSidebar,
        ),
      ],
    );
  }
}
