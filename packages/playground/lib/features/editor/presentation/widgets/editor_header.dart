import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';

import '../../domain/stores/deck_file_session.dart';
import 'new_deck_dialog.dart';

/// Bar sitting on top of the text editor: the `New` / `Open` actions on the
/// left, followed by the bound deck's filename. When the bound file is lost
/// (deleted/moved) it also surfaces the controller's warning as a banner.
class EditorHeader extends StatelessWidget {
  const EditorHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeckFileSession>();
    final warning = session.warning;

    return ColumnBox(
      style: FlexBoxStyler().mainAxisSize(.min),
      children: [
        Box(
          style: BoxStyler()
              .width(double.infinity)
              .color($backgroundSecondary())
              .padding(.horizontal(16).vertical(8))
              .borderBottom(color: $border()),
          child: RowBox(
            style: FlexBoxStyler()
                .mainAxisAlignment(.start)
                .crossAxisAlignment(.center)
                .spacing(8),
            children: [
              _FileName(name: session.fileName, unbound: !session.isBound),
              Spacer(),
              Box(style: BoxStyler().width(1).height(16).color($border())),
              HeroButton(
                label: 'New',
                iconLeft: CupertinoIcons.add,
                size: .sm,
                variant: .ghost,
                onPressed: () => showNewDeckDialog(context, session),
              ),
              HeroButton(
                label: 'Open',
                iconLeft: CupertinoIcons.folder,
                size: .sm,
                variant: .ghost,
                onPressed: session.openDeck,
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
        StyledIcon(
          icon: unbound
              ? CupertinoIcons.exclamationmark_triangle_fill
              : CupertinoIcons.doc_text,
          style: IconStyler().size(15).color(unbound ? $warning() : $muted()),
        ),
        StyledText(
          name,
          style: TextStyler()
              .color(unbound ? $warning() : $foreground())
              .style($labelSmall.mix()),
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
