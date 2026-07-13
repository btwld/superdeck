import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:super_editor/super_editor.dart';

import '../../utils/edit_reaction.dart';
import '../../utils/text_editor_controller.dart';
import 'editor_header.dart';

/// Thin view over [TextEditorController.editor]. The controller owns the
/// document model, its reaction pipeline, and all navigation logic; this widget
/// only supplies the super_editor presentation config (keyboard actions, caret
/// overlay, and the syntax-highlighting stylesheet).
class TextEditor extends StatelessWidget {
  const TextEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.read<TextEditorController>().editor;

    return Padding(
      padding: const .symmetric(vertical: 16, horizontal: 4),
      child: HeroCard(
        child: Column(
          children: [
            const EditorHeader(),
            Expanded(
              child: SuperEditor(
                editor: editor,
                keyboardActions: [...defaultKeyboardActions],
                documentOverlayBuilders: [
                  DefaultCaretOverlayBuilder(
                    caretStyle: CaretStyle(color: $accent.resolve(context)),
                  ),
                ],
                stylesheet: Stylesheet(
                  rules: [
                    StyleRule(BlockSelector.all, (doc, docNode) {
                      return {
                        Styles.textStyle: TextStyle(
                          color: $muted.resolve(context),
                          fontSize: 16,
                          height: 1.4,
                          fontFamily: GoogleFonts.googleSansCode().fontFamily,
                        ),
                      };
                    }),
                  ],
                  inlineTextStyler: (attributions, textStyle) {
                    var style = const TextStyle(fontSize: 16).merge(textStyle);

                    for (final attribution in attributions) {
                      switch (attribution) {
                        case separatorAttribution:
                          style = style.copyWith(
                            color: $separatorTertiary.resolve(context),
                          );
                          break;
                        case headerAttribution:
                          style = style.copyWith(
                            fontWeight: FontWeight.bold,
                            color: $foreground.resolve(context),
                          );
                          break;
                        case blockAttribution:
                          style = style.copyWith(
                            color: $danger.resolve(context),
                          );
                          break;
                        case blockKeyAttribution:
                          style = style.copyWith(
                            color: $warning.resolve(context),
                          );
                          break;
                        case blockValueAttribution:
                          style = style.copyWith(
                            color: $foreground.resolve(context),
                          );
                          break;
                      }
                    }
                    return style;
                  },
                  documentPadding: const .all(32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
