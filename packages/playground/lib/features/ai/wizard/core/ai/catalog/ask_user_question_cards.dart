import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remix/remix.dart';

import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../ui/ui.dart';
import '../../utils/color_utils.dart';
import '../../utils/font_utils.dart';

// ─────────────────────────────────── STYLING UTILITIES ───────────────────────────────────

/// Returns body text style for selected state.
TextStyler? selectedBodyStyle(bool selected) =>
    selected ? TextStyler().color($foreground()).fontWeight(.w600) : null;

/// Returns caption text style for selected state.
TextStyler? selectedCaptionStyle(bool selected) =>
    selected ? TextStyler().color($muted()) : null;

// ─────────────────────────────────── CARD WIDGETS ───────────────────────────────────

/// Radio option card with title and optional description.
class RadioOptionCard extends StatelessWidget {
  const RadioOptionCard({
    super.key,
    required this.title,
    this.description,
    this.icon = LucideIcons.presentation,
    required this.selected,
    this.onTap,
  });

  final String title;
  final String? description;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = FlexBoxStyler()
        .column()
        .spacing(8)
        .crossAxisAlignment(CrossAxisAlignment.start);

    final iconColor = selected
        ? $accent.resolve(context)
        : $muted.resolve(context);
    final iconBackground = selected
        ? $accentSoft.resolve(context)
        : $surfaceTertiary.resolve(context);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: 'Option: $title${description != null ? ', $description' : ''}',
      child: Pressable(
        onPress: onTap,
        child: SdCard(
          isSelected: selected,
          style: FlexBoxStyler().minHeight(SdTokens.cardMinHeight),
          child: content(
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: .circular(10),
                ),
                width: 38,
                height: 38,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              SdBody(title, style: selectedBodyStyle(selected)),
              if (description != null && description!.isNotEmpty)
                SdCaption(description!, style: selectedCaptionStyle(selected)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Checkbox option card with label and checkbox indicator.
class CheckboxOptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const CheckboxOptionCard({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = FlexBoxStyler().spacing(12);

    return Semantics(
      checked: selected,
      label: 'Checkbox: $label',
      child: Pressable(
        onPress: onTap,
        child: SdCard(
          isSelected: selected,
          child: content(
            children: [
              SdCheckbox(selected: selected),
              Expanded(
                child: SdBody(label, style: selectedBodyStyle(selected)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Style option card with a composed palette and typography preview.
class StyleOptionCard extends StatelessWidget {
  const StyleOptionCard({
    super.key,
    required this.theme,
    required this.selected,
    this.onTap,
  });

  final PresentationThemeDescriptor theme;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = FlexBoxStyler()
        .column()
        .crossAxisAlignment(CrossAxisAlignment.stretch)
        .spacing(12)
        .mainAxisSize(MainAxisSize.min);

    final bodyStyle = selectedBodyStyle(selected);
    final captionStyle = selectedCaptionStyle(selected);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: 'Style: ${theme.title}, ${theme.description}',
      child: Pressable(
        onPress: onTap,
        child: SdCard(
          isSelected: selected,
          style: FlexBoxStyler().minHeight(SdTokens.cardMinHeight),
          child: content(
            children: [
              _ThemeSamplePreview(theme: theme),
              SdBody(theme.title, style: bodyStyle),
              SdCaption(theme.description, style: captionStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSamplePreview extends StatelessWidget {
  const _ThemeSamplePreview({required this.theme});

  final PresentationThemeDescriptor theme;

  @override
  Widget build(BuildContext context) {
    final recipe = theme.recipe;
    final palette = recipe.palette;
    final headlineFamily = tryGetGoogleFontFamily(recipe.headlineFamily);
    final bodyFamily = tryGetGoogleFontFamily(recipe.bodyFamily);
    final background = hexToColor(palette.background);
    final surface = hexToColor(palette.surface);
    final heading = hexToColor(palette.heading);
    final body = hexToColor(palette.body);
    final accent = hexToColor(palette.accent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: .all(color: surface, width: 2),
        borderRadius: .circular(12),
      ),
      width: .infinity,
      height: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: .circular(999),
            ),
            width: 38,
            height: 4,
          ),
          const Spacer(),
          Text(
            'Build what’s next',
            style: TextStyle(
              color: heading,
              fontSize: 22,
              fontWeight: .w700,
              height: 1.05,
              fontFamily: headlineFamily,
            ),
            overflow: .ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            'A clear story, beautifully presented.',
            style: TextStyle(
              color: body,
              fontSize: 12,
              fontWeight: .w400,
              height: 1.25,
              fontFamily: bodyFamily,
            ),
            overflow: .ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

/// Image style option card with generated preview image.
class ImageStyleOptionCard extends StatelessWidget {
  final PresentationImageStyleDescriptor style;
  final Uint8List? imageBytes;
  final bool isLoading;
  final bool hasFailed;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  const ImageStyleOptionCard({
    super.key,
    required this.style,
    this.imageBytes,
    this.isLoading = false,
    this.hasFailed = false,
    required this.selected,
    this.onTap,
    this.onRetry,
  });

  Widget _buildImagePreview(BuildContext context) {
    if (isLoading) {
      return Box(
        style: BoxStyler()
            .color($surfaceSecondary())
            .alignment(Alignment.center),
        child: SdSpinner(),
      );
    }

    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) => _buildPlaceholder(ctx),
      );
    }

    if (hasFailed) {
      return _buildRetryPlaceholder(context);
    }

    return _buildPlaceholder(context);
  }

  Widget _buildRetryPlaceholder(BuildContext context) {
    return Box(
      style: BoxStyler().color($surfaceSecondary()).alignment(Alignment.center),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Icon(LucideIcons.imageOff, size: 32, color: $muted.resolve(context)),
          GestureDetector(
            onTap: onRetry,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(
                  LucideIcons.refreshCw,
                  size: 16,
                  color: $accent.resolve(context),
                ),
                SdCaption('Retry', style: TextStyler().color($accent())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Box(
      style: BoxStyler().color($surfaceSecondary()).alignment(Alignment.center),
      child: Icon(LucideIcons.image, size: 40, color: $muted.resolve(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = FlexBoxStyler().column().crossAxisAlignment(
      CrossAxisAlignment.stretch,
    );

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: 'Image style: ${style.title}',
      child: Pressable(
        onPress: onTap,
        child: SdCard(
          isSelected: selected,
          style: FlexBoxStyler()
              .crossAxisAlignment(CrossAxisAlignment.stretch)
              .paddingAll(0),
          child: content(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(SdTokens.cardInnerRadius),
                  ),
                  child: _buildImagePreview(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    SdBody(style.title, style: selectedBodyStyle(selected)),
                    SdCaption(
                      style.description,
                      style: selectedCaptionStyle(selected),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
