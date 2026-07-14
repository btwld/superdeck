part of 'summary_card.dart';

/// Extracts generation context from summary items.
///
/// Uses [WizardContextKeys] for standardized label-to-key mapping.
/// Logs warnings for any unmapped labels to aid debugging.
WizardContext extractWizardContextFromSummaryItems(
  List<SummaryItemType> items,
) {
  final contextMap = <String, dynamic>{};
  final unmappedLabels = <String>[];

  for (final item in items) {
    final shapeError = item.shapeValidationError;
    if (shapeError != null) {
      debugLog.log(
        'SummaryCard',
        'Invalid item shape for "${item.label}": $shapeError',
      );
      continue;
    }

    final key = WizardContextKeys.labelToKey(item.label);
    if (key == null) {
      unmappedLabels.add(item.label);
      continue;
    }

    // Use generated nullable getters for optional fields
    final itemTitle = item.title;
    final itemDescription = item.description;
    final itemText = item.text;
    final itemThemeId = item.themeId;
    final itemImageStyleId = item.imageStyleId;

    // Extract the primary value
    if (itemThemeId != null) {
      contextMap[WizardContextKeys.themeId] = itemThemeId;
    } else if (itemText != null) {
      contextMap[key] = _parseContextValue(key, itemText);
    } else if (itemTitle != null) {
      contextMap[key] = itemTitle;
    }

    // Extract image style data for generation context
    if (itemImageStyleId != null) {
      contextMap[WizardContextKeys.imageStyleId] = itemImageStyleId.name;
      contextMap[WizardContextKeys.imageStyleName] = itemImageStyleId.title;
      contextMap.putIfAbsent(
        WizardContextKeys.imageStyleDescription,
        () => itemImageStyleId.description,
      );
    }
    if (key == WizardContextKeys.imageStyleName && itemDescription != null) {
      contextMap[WizardContextKeys.imageStyleDescription] = itemDescription;
    }
  }

  // Log warnings for unmapped labels
  if (unmappedLabels.isNotEmpty) {
    debugLog.log(
      'SummaryCard',
      'Unmapped labels ignored: ${unmappedLabels.join(", ")}',
    );
  }

  final context = WizardContext.fromMap(contextMap);

  // Validate required context keys
  _validateRequiredContext(context);

  return context;
}

/// Parses a text value for a specific context key.
///
/// Handles special parsing like extracting numbers from slide count text.
dynamic _parseContextValue(String key, String text) {
  if (key == WizardContextKeys.slideCount) {
    // Match patterns like "12 slides", "12", "Slide Count: 12"
    final match = RegExp(r'\b(\d{1,3})\b').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? text;
    }
    return text;
  }
  return text;
}

/// Validates that required context keys are present.
///
/// Logs warnings for any missing required keys.
void _validateRequiredContext(WizardContext context) {
  final missing = <String>[];

  if (context.topic == null) missing.add(WizardContextKeys.topic);
  if (context.audience == null) missing.add(WizardContextKeys.audience);
  if (context.slideCount == null) missing.add(WizardContextKeys.slideCount);

  if (missing.isNotEmpty) {
    debugLog.log(
      'SummaryCard',
      'Missing recommended context keys: ${missing.join(", ")}',
    );
  }
}

/// The main summary card widget.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.items,
    required this.themeCatalog,
    this.generateSlides,
  });

  final String title;
  final List<SummaryItemType> items;
  final PresentationThemeCatalog themeCatalog;
  final VoidCallback? generateSlides;

  FlexBoxStyler get _container => .new()
      .borderRadiusAll(Radius.circular(SdTokens.cardRadius))
      .mainAxisSize(.min)
      .spacing(16)
      .crossAxisAlignment(.start)
      .paddingAll(SdTokens.cardPadding)
      .borderAll(color: $border())
      .column();

  @override
  Widget build(BuildContext context) {
    return _container(
      children: [
        SdHeadline(title),
        LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (constraints.maxHeight * 0.6).clamp(200.0, 500.0),
            ),
            child: SingleChildScrollView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: items
                    .map(
                      (item) => _SummaryCardItem(
                        item: item,
                        themeCatalog: themeCatalog,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SdButton(
            label: 'Generate Slides',
            icon: Icons.generating_tokens,
            onPressed: generateSlides,
          ),
        ),
      ],
    );
  }
}

class _SummaryCardItem extends StatelessWidget {
  const _SummaryCardItem({required this.item, required this.themeCatalog});

  final SummaryItemType item;
  final PresentationThemeCatalog themeCatalog;

  // Label with fixed width for consistent alignment
  TextStyler get _label => TextStyler()
      .color($foreground())
      .style($paragraphMedium.mix())
      .wrap(WidgetModifierConfig.sizedBox(width: 140));

  Widget _buildContent() {
    final shapeError = item.shapeValidationError;
    if (shapeError != null) {
      debugLog.log(
        'SummaryCard',
        'Rendering fallback for "${item.label}": $shapeError',
      );
      return _SummaryCardItemTitleDescription(
        title: item.title ?? item.text ?? '',
        description: item.description ?? 'Invalid summary item data',
      );
    }

    // Use generated nullable getters for optional fields
    final itemTitle = item.title;
    final itemDescription = item.description;
    final itemText = item.text;
    final itemImageStyleId = item.imageStyleId;

    // Theme items resolve all preview metadata from the shared catalog.
    if (item.hasThemeData) {
      final itemThemeId = item.themeId!;
      final theme = themeCatalog.current(itemThemeId);
      if (theme != null) return _SummaryCardItemTheme(theme: theme);
    }

    // Image style items
    if (item.hasImageStyleData) {
      return _SummaryCardItemImageStyle(imageStyle: itemImageStyleId!);
    }

    // Default: titleDescription or text display
    return _SummaryCardItemTitleDescription(
      title: itemTitle ?? itemText ?? '',
      description: itemDescription,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SdPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(item.label),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}

class _SummaryCardItemTitleDescription extends StatelessWidget {
  final String title;
  final String? description;

  const _SummaryCardItemTitleDescription({
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final flex = FlexBoxStyler()
        .spacing(4)
        .mainAxisAlignment(.start)
        .crossAxisAlignment(.start)
        .column();

    return flex(
      children: [
        SdBody(title),
        if (description != null) SdCaption(description!),
      ],
    );
  }
}

class _SummaryCardItemTheme extends StatelessWidget {
  const _SummaryCardItemTheme({required this.theme});

  final PresentationThemeDescriptor theme;

  @override
  Widget build(BuildContext context) {
    final flex = FlexBoxStyler()
        .spacing(4)
        .mainAxisAlignment(.start)
        .crossAxisAlignment(.start)
        .column();

    final colorRow = FlexBoxStyler().paddingY(5).row();

    final recipe = theme.recipe;
    final headlineFontLoaded = tryGetGoogleFontFamily(recipe.headlineFamily);
    final bodyFontLoaded = tryGetGoogleFontFamily(recipe.bodyFamily);

    return flex(
      children: [
        SdBody(theme.title),
        SdCaption(theme.description),
        colorRow(
          children: recipe.palette.previewColors
              .map((color) => SdColorCircle(color: hexToColor(color)))
              .toList(),
        ),
        SdBody(
          recipe.headlineFamily,
          style: headlineFontLoaded != null
              ? TextStyler().fontFamily(headlineFontLoaded)
              : null,
        ),
        SdCaption(
          recipe.bodyFamily,
          style: bodyFontLoaded != null
              ? TextStyler().fontFamily(bodyFontLoaded)
              : null,
        ),
      ],
    );
  }
}

/// Widget for displaying image style summary items.
class _SummaryCardItemImageStyle extends StatelessWidget {
  final ImageStyle imageStyle;

  const _SummaryCardItemImageStyle({required this.imageStyle});

  @override
  Widget build(BuildContext context) {
    final flex = FlexBoxStyler()
        .spacing(4)
        .mainAxisAlignment(.start)
        .crossAxisAlignment(.start)
        .column();

    // Show style name and description from enum
    return flex(
      children: [SdBody(imageStyle.title), SdCaption(imageStyle.description)],
    );
  }
}
