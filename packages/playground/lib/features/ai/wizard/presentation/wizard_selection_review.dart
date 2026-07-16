import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../core/ai/wizard_context.dart';
import '../core/ui/ui.dart';
import '../core/utils/color_utils.dart';

/// Application-owned review of the selections accepted during the GenUI flow.
class WizardSelectionReview extends StatelessWidget {
  const WizardSelectionReview({
    super.key,
    required this.wizardContext,
    required this.imageStyleCatalog,
    required this.themeCatalog,
    required this.onCreateOutline,
    this.onStartOver,
    this.showArtwork = true,
  });

  final WizardContext wizardContext;
  final PresentationImageStyleCatalog imageStyleCatalog;
  final PresentationThemeCatalog themeCatalog;
  final VoidCallback onCreateOutline;
  final VoidCallback? onStartOver;
  final bool showArtwork;

  @override
  Widget build(BuildContext context) {
    final theme = wizardContext.themeId == null
        ? null
        : themeCatalog.current(wizardContext.themeId!);
    final emphasis = wizardContext.emphasis?.join(', ') ?? '';
    final imageStyle = _resolveImageStyle(wizardContext, imageStyleCatalog);

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SdPanel(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 20,
              children: [
                Row(
                  crossAxisAlignment: .start,
                  spacing: 12,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: $accentSoft.resolve(context),
                        borderRadius: .circular(12),
                      ),
                      width: 42,
                      height: 42,
                      child: Icon(
                        LucideIcons.layers,
                        size: 21,
                        color: $accent.resolve(context),
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
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
                  imageStyle: imageStyle,
                  showArtwork: showArtwork,
                ),
                Row(
                  mainAxisAlignment: .end,
                  spacing: 12,
                  children: [
                    if (onStartOver != null)
                      SdButton(
                        label: 'Start over',
                        onPressed: onStartOver,
                        variant: .ghost,
                      ),
                    SdButton(
                      label: 'Create outline',
                      onPressed: onCreateOutline,
                      icon: LucideIcons.sparkles,
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
  final String label;

  final String value;
  const _ReviewItem(this.label, this.value);
}

class _ReviewItems extends StatelessWidget {
  const _ReviewItems({
    required this.items,
    required this.theme,
    required this.imageStyle,
    required this.showArtwork,
  });

  final List<_ReviewItem> items;
  final PresentationThemeDescriptor? theme;
  final PresentationImageStyleDescriptor? imageStyle;
  final bool showArtwork;

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
        if (showArtwork) ...[
          Divider(height: 1, color: $separator.resolve(context)),
          _ReviewRow(
            label: 'Artwork',
            child: imageStyle == null
                ? const SdBody('Artwork direction unavailable')
                : Column(
                    crossAxisAlignment: .start,
                    spacing: 4,
                    children: [
                      SdBody(imageStyle!.title),
                      SdCaption(imageStyle!.description),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

PresentationImageStyleDescriptor? _resolveImageStyle(
  WizardContext context,
  PresentationImageStyleCatalog catalog,
) {
  final id = context.imageStyleId;
  final version = context.imageStyleVersion;
  if (id == null || version == null) return null;
  try {
    return catalog.resolve(id: id, version: version);
  } on ArgumentError {
    return null;
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: .start,
              spacing: 8,
              children: [SdCaption(label), child],
            );
          }

          return Row(
            crossAxisAlignment: .start,
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
      crossAxisAlignment: .start,
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
