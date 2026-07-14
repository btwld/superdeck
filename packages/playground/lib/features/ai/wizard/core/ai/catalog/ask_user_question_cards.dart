import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../prompts/image_style_prompts.dart';
import '../../ui/ui.dart';
import '../../utils/color_utils.dart';
import '../../utils/font_utils.dart';

// ─────────────────────────────────── STYLING UTILITIES ───────────────────────────────────

/// Returns body text style for selected state.
TextStyler? selectedBodyStyle(bool selected) =>
    selected ? TextStyler().color($accent()) : null;

/// Returns caption text style for selected state.
TextStyler? selectedCaptionStyle(bool selected) =>
    selected ? TextStyler().color($accent()) : null;

// ─────────────────────────────────── CARD WIDGETS ───────────────────────────────────

/// Radio option card with title and optional description.
class RadioOptionCard extends StatelessWidget {
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback? onTap;

  const RadioOptionCard({
    super.key,
    required this.title,
    this.description,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = FlexBoxStyler()
        .column()
        .spacing(4)
        .crossAxisAlignment(CrossAxisAlignment.start);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: 'Option: $title${description != null ? ', $description' : ''}',
      child: Pressable(
        onPress: onTap,
        child: SdCard(
          isSelected: selected,
          style: FlexBoxStyler().minHeight(SdTokens.cardMinHeight),
          child: content(
            children: [
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

/// Style option card with color swatches and font previews.
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
        .mainAxisSize(MainAxisSize.min)
        .spacing(4)
        .crossAxisAlignment(CrossAxisAlignment.start);

    final colorRow = FlexBoxStyler().paddingY(5).row();

    final recipe = theme.recipe;

    final bodyStyle = selectedBodyStyle(selected);
    final captionStyle = selectedCaptionStyle(selected);

    final headlineFontLoaded = tryGetGoogleFontFamily(recipe.headlineFamily);
    final bodyFontLoaded = tryGetGoogleFontFamily(recipe.bodyFamily);

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
              SdBody(theme.title, style: bodyStyle),
              SdCaption(theme.description, style: captionStyle),
              colorRow(
                children: recipe.palette.previewColors
                    .map(
                      (color) => SdColorCircle(
                        color: hexToColor(color),
                        interactive: true,
                      ),
                    )
                    .toList(),
              ),
              SdBody(
                recipe.headlineFamily,
                style: headlineFontLoaded != null
                    ? TextStyler()
                          .fontFamily(headlineFontLoaded)
                          .merge(bodyStyle)
                    : bodyStyle,
              ),
              SdCaption(
                recipe.bodyFamily,
                style: bodyFontLoaded != null
                    ? TextStyler()
                          .fontFamily(bodyFontLoaded)
                          .merge(captionStyle)
                    : captionStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Image style option card with generated preview image.
class ImageStyleOptionCard extends StatelessWidget {
  final ImageStyle style;
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
          Icon(
            Icons.broken_image_outlined,
            color: $muted.resolve(context),
            size: 32,
          ),
          GestureDetector(
            onTap: onRetry,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(Icons.refresh, size: 16, color: $accent.resolve(context)),
                Text(
                  'Retry',
                  style: $paragraphSmall
                      .mix()
                      .resolve(context)
                      .copyWith(color: $accent.resolve(context)),
                ),
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
      child: Icon(
        Icons.image_outlined,
        color: $muted.resolve(context),
        size: 40,
      ),
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
                child: SdBody(style.title, style: selectedBodyStyle(selected)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
