import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/design/presentation_theme_catalog.dart';
import '../core/ai/wizard_context.dart';
import '../core/ui/ui.dart';
import '../core/utils/color_utils.dart';

/// Application-owned review of the selections accepted during the GenUI flow.
class WizardSelectionReview extends StatelessWidget {
  const WizardSelectionReview({
    super.key,
    required this.wizardContext,
    required this.themeCatalog,
    required this.onCreateOutline,
    this.onStartOver,
  });

  final WizardContext wizardContext;
  final PresentationThemeCatalog themeCatalog;
  final VoidCallback onCreateOutline;
  final VoidCallback? onStartOver;

  @override
  Widget build(BuildContext context) {
    final theme = wizardContext.themeId == null
        ? null
        : themeCatalog.current(wizardContext.themeId!);
    final emphasis = wizardContext.emphasis?.join(', ') ?? '';

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SdPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: $accentSoft.resolve(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.layers,
                        size: 21,
                        color: $accent.resolve(context),
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          SdHeadline('Review your deck setup'),
                          SdCaption(
                            'Confirm the direction before creating the slide outline.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _ReviewItems(
                  items: [
                    _ReviewItem('Topic', wizardContext.topic ?? ''),
                    _ReviewItem('Audience', wizardContext.audience ?? ''),
                    _ReviewItem('Approach', wizardContext.approach ?? ''),
                    _ReviewItem('Emphasis', emphasis),
                    _ReviewItem(
                      'Deck length',
                      '${wizardContext.slideCount ?? 0} slides',
                    ),
                  ],
                  theme: theme,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 12,
                  children: [
                    if (onStartOver != null)
                      TextButton(
                        onPressed: onStartOver,
                        child: const Text('Start over'),
                      ),
                    SdButton(
                      label: 'Create outline',
                      icon: LucideIcons.sparkles,
                      onPressed: onCreateOutline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ReviewItem {
  const _ReviewItem(this.label, this.value);

  final String label;
  final String value;
}

class _ReviewItems extends StatelessWidget {
  const _ReviewItems({required this.items, required this.theme});

  final List<_ReviewItem> items;
  final PresentationThemeDescriptor? theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) Divider(height: 1, color: $separator.resolve(context)),
          _ReviewRow(label: item.label, child: SdBody(item.value)),
        ],
        Divider(height: 1, color: $separator.resolve(context)),
        _ReviewRow(
          label: 'Theme',
          child: theme == null
              ? const SdBody('Theme unavailable')
              : _ThemeSummary(theme: theme!),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [SdCaption(label), child],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: SdCaption(label)),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeSummary extends StatelessWidget {
  const _ThemeSummary({required this.theme});

  final PresentationThemeDescriptor theme;

  @override
  Widget build(BuildContext context) {
    final recipe = theme.recipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        SdBody(theme.title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in recipe.palette.previewColors)
              SdColorCircle(color: hexToColor(color)),
          ],
        ),
        SdCaption('${recipe.headlineFamily} + ${recipe.bodyFamily}'),
      ],
    );
  }
}
