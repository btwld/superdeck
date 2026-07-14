import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ExpansionTile, Material;
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';
import 'package:provider/provider.dart';

import '../../domain/files/deck_image_manifest.dart';
import '../../domain/stores/deck_file_session.dart';
import '../../domain/stores/deck_image_issue_store.dart';
import 'new_deck_dialog.dart';

/// Bar sitting on top of the text editor: the `New` / `Open` actions on the
/// left, followed by the bound deck's filename. When the bound file is lost
/// (deleted/moved) it also surfaces the controller's warning as a banner.
class EditorHeader extends StatelessWidget {
  const EditorHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeckFileSession>();
    final imageIssues = context.watch<DeckImageIssueStore>();
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
                onPressed: session.isBound ? session.openDeck : null,
              ),
            ],
          ),
        ),
        if (warning != null) _WarningBanner(message: warning),
        if (imageIssues.issues.isNotEmpty || imageIssues.errorMessage != null)
          _ImageIssuesBanner(store: imageIssues),
      ],
    );
  }
}

class _ImageIssuesBanner extends StatelessWidget {
  const _ImageIssuesBanner({required this.store});

  final DeckImageIssueStore store;

  @override
  Widget build(BuildContext context) {
    final issues = store.issues;
    final count = issues.length;
    final title = switch (count) {
      0 => 'Image issues unavailable',
      1 => '1 image needs attention',
      _ => '$count images need attention',
    };
    return Material(
      key: const ValueKey('editor-image-issues'),
      color: $danger.resolve(context).withValues(alpha: 0.08),
      child: ExpansionTile(
        dense: true,
        leading: Icon(
          CupertinoIcons.photo_fill_on_rectangle_fill,
          size: 16,
          color: $danger.resolve(context),
        ),
        title: Text(
          title,
          style: TextStyle(color: $danger.resolve(context), fontSize: 12),
        ),
        subtitle: store.errorMessage == null
            ? null
            : Text(store.errorMessage!, style: const TextStyle(fontSize: 11)),
        children: issues
            .map((issue) => _ImageIssueRow(store: store, issue: issue))
            .toList(),
      ),
    );
  }
}

class _ImageIssueRow extends StatelessWidget {
  const _ImageIssueRow({required this.store, required this.issue});

  final DeckImageIssueStore store;
  final DeckImageManifestEntry issue;

  @override
  Widget build(BuildContext context) {
    final retrying = store.isRetrying(issue.assetKey);
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.slideKey, style: const TextStyle(fontSize: 12)),
                Text(
                  issue.error ?? 'Image generation failed.',
                  style: TextStyle(
                    color: $muted.resolve(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          HeroButton(
            key: ValueKey('editor-image-retry-${issue.assetKey}'),
            label: 'Retry',
            iconLeft: CupertinoIcons.refresh,
            size: .sm,
            variant: .ghost,
            loading: retrying,
            onPressed: retrying ? null : () => store.retry(issue),
          ),
        ],
      ),
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
