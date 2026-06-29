import 'package:flutter/material.dart';

import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import 'user_action_dispatch.dart';
import '../../debug_logger.dart';
import '../../ui/ui.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'remix_component_normalizer.dart';
import 'remix_component_preview_examples.dart';
import 'remix_component_renderer.dart';
import 'remix_component_schema.dart';
import 'typed_catalog_item.dart';

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// RemixComponentPreview catalog component for component selection.
final remixComponentPreview = typedCatalogItem<RemixComponentPreviewType>(
  name: 'RemixComponentPreview',
  dataSchema: componentSchema(
    remixComponentPreviewSchema.toJsonSchemaBuilder(),
  ),
  exampleData: remixComponentPreviewExamples,
  normalizeData: (data) => normalizeRemixComponentPreviewData(
    Map<String, Object?>.from(data as Map),
  ),
  parse: RemixComponentPreviewType.parse,
  widgetBuilder: (context, data) =>
      _RemixComponentPreviewContent(data: data, itemContext: context),
);

/// Converts a parsed theme into a context-friendly map with only non-null fields.
Map<String, String> _themeContext(UiThemeType theme) {
  return {
    if (theme.accent != null) 'accent': theme.accent!.name,
    if (theme.gray != null) 'gray': theme.gray!.name,
    if (theme.brightness != null) 'brightness': theme.brightness!.name,
  };
}

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _RemixComponentPreviewContent extends StatefulWidget {
  final RemixComponentPreviewType data;
  final CatalogItemContext itemContext;

  const _RemixComponentPreviewContent({
    required this.data,
    required this.itemContext,
  });

  @override
  State<_RemixComponentPreviewContent> createState() =>
      _RemixComponentPreviewContentState();
}

class _RemixComponentPreviewContentState
    extends State<_RemixComponentPreviewContent> {
  int? _selectedIndex;
  ComponentOptionType? _selectedOption;

  bool get _canSubmit => _selectedOption != null;

  Map<String, dynamic> _buildActionContext() {
    if (_selectedOption case final option?) {
      return {
        'selectedComponent': option.id,
        'selectedTitle': option.title,
        'selectedDescription': option.description,
        'message': option.title,
        if (widget.data.theme case final theme?)
          'selectedTheme': _themeContext(theme),
      };
    }
    return {};
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: _canSubmit,
    itemContext: widget.itemContext,
    action: widget.data.action,
    contextBuilder: _buildActionContext,
  );

  @override
  Widget build(BuildContext context) {
    return CatalogQuestionStep(
      question: widget.data.question,
      description: widget.data.description,
      body: _buildOptions(),
      canSubmit: _canSubmit,
      onSubmit: _submitAction,
    );
  }

  Widget _buildOptions() {
    final options = widget.data.componentOptions;

    if (options.isEmpty) {
      debugLog.log(
        'RemixComponentPreview',
        'WARNING: component preview has no options.',
      );
      return const SdBody('No component options configured');
    }

    final optionsRow = FlexBoxStyler()
        .spacing(16)
        .wrap(WidgetModifierConfig.intrinsicHeight());

    Widget content = optionsRow(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedIndex == index;

        return Expanded(
          child: _ComponentOptionCard(
            option: option,
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _selectedOption = option;
              });
            },
          ),
        );
      }).toList(),
    );

    // Always apply a Fortal scope so all options use consistent tokens.
    // When theme is provided, use its values; otherwise use defaults.
    var accent = FortalAccentColor.iris;
    var gray = FortalGrayColor.slate;
    var brightness = Brightness.light;

    if (widget.data.theme case final theme?) {
      accent = theme.accent?.fortalColor ?? accent;
      gray = theme.gray?.fortalColor ?? gray;
      brightness = theme.brightness?.flutterBrightness ?? brightness;
    }

    content = FortalScope(
      accent: accent,
      gray: gray,
      brightness: brightness,
      child: content,
    );

    return content;
  }
}

// ─────────────────────────────────── OPTION CARD ───────────────────────────────────

class _ComponentOptionCard extends StatelessWidget {
  final ComponentOptionType option;
  final bool selected;
  final VoidCallback? onTap;

  const _ComponentOptionCard({
    required this.option,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = FlexBoxStyler()
        .column()
        .crossAxisAlignment(CrossAxisAlignment.stretch)
        .spacing(12);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: 'Component: ${option.title}, ${option.description}',
      child: Pressable(
        onPress: onTap,
        child: SdCard(
          isSelected: selected,
          style: FlexBoxStyler()
              .crossAxisAlignment(CrossAxisAlignment.stretch)
              .paddingAll(0),
          child: content(
            children: [
              // Live component preview
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _buildPreview(context),
              ),
              // Divider
              const SdDivider(),
              // Title and description
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final nodes = option.nodes;
    final rootId = option.rootNodeId;

    // Convert list of nodes to a map keyed by node id for fast lookup
    final nodeMap = <String, UiNodeType>{
      for (final node in nodes) node.id: node,
    };

    if (!nodeMap.containsKey(rootId)) {
      debugLog.log(
        'RemixComponentPreview',
        'WARNING: rootNodeId "$rootId" not found in nodes.',
      );
      return const SdBody('Invalid component tree');
    }

    // Preview is visual-only:
    // - ExcludeSemantics removes rendered form elements from the DOM so they
    //   don't compete with the chat input for browser text-input routing.
    // - ExcludeFocus prevents keyboard focus traversal into previews.
    // - IgnorePointer blocks pointer events on rendered widgets.
    return ExcludeSemantics(
      child: ExcludeFocus(
        child: IgnorePointer(
          child: ComponentTreeRenderer(nodeMap: nodeMap, rootNodeId: rootId),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    final info = FlexBoxStyler()
        .column()
        .spacing(4)
        .crossAxisAlignment(CrossAxisAlignment.start);

    return info(
      children: [
        SdBody(option.title, style: TextStyler().fontWeight(FontWeight.w600)),
        SdCaption(option.description),
      ],
    );
  }
}
