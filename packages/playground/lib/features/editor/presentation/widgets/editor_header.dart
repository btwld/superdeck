import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';

import '../../domain/stores/deck_file_controller.dart';
import 'new_deck_dialog.dart';

/// Top bar for the editor showing the bound deck's filename and the
/// `New` / `Open` actions. When the bound file is lost (deleted/moved) it also
/// surfaces the controller's warning as a banner.
class EditorHeader extends StatelessWidget {
  const EditorHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeckFileController>();
    final warning = controller.warning;

    return ColumnBox(
      style: FlexBoxStyler().mainAxisSize(.min),
      children: [
        Box(
          style: BoxStyler()
              .width(double.infinity)
              .color($background())
              .padding(.horizontal(16).vertical(8))
              .borderBottom(color: $border()),
          child: RowBox(
            style: FlexBoxStyler()
                .mainAxisAlignment(.spaceBetween)
                .crossAxisAlignment(.center)
                .spacing(12),
            children: [
              _FileName(
                name: controller.fileName,
                unbound: !controller.isBound,
              ),
              RowBox(
                style: FlexBoxStyler().mainAxisSize(.min).spacing(8),
                children: [
                  HeroButton(
                    label: 'New',
                    iconLeft: CupertinoIcons.add,
                    size: .sm,
                    variant: .secondary,
                    onPressed: () => showNewDeckDialog(context, controller),
                  ),
                  HeroButton(
                    label: 'Open',
                    iconLeft: CupertinoIcons.folder,
                    size: .sm,
                    variant: .ghost,
                    onPressed: controller.openDeck,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (warning != null) _WarningBanner(message: warning),
      ],
    );
  }
}

class _FileName extends StatelessWidget {
  const _FileName({required this.name, required this.unbound});

  final String name;
  final bool unbound;

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler().mainAxisSize(.min).spacing(8),
      children: [
        Icon(
          unbound
              ? CupertinoIcons.exclamationmark_triangle_fill
              : CupertinoIcons.doc_text,
          size: 15,
          color: unbound ? $warning.resolve(context) : $muted.resolve(context),
        ),
        StyledText(
          name,
          style: TextStyler()
              .color(unbound ? $warning() : $foreground())
              .style($labelMedium.mix()),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler()
          .width(double.infinity)
          .color($warning().withValues(alpha: 0.12))
          .padding(.horizontal(16).vertical(8)),
      child: RowBox(
        style: FlexBoxStyler().mainAxisSize(.min).spacing(8),
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 14,
            color: $warning.resolve(context),
          ),
          StyledText(
            message,
            style: TextStyler().color($warning()).style($labelSmall.mix()),
          ),
        ],
      ),
    );
  }
}
