import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import 'package:playground/features/ai/core/ai/catalog/user_action_dispatch.dart';
import 'package:playground/features/ai/core/ai/schemas/genui_action_schema.dart';
import 'package:playground/features/ai/core/debug_logger.dart';
import 'package:playground/features/ai/core/ui/ui.dart';
import 'catalog_question_step.dart';
import 'remix_component_preview_examples.dart';
import 'remix_component_renderer.dart';

part 'remix_component_preview.g.dart';

// ─────────────────────────────────── ENUMS ───────────────────────────────────

/// Component types available for UI node rendering.
enum UiComponentType {
  // Layout
  row,
  column,

  // Display
  text,
  card,
  badge,
  callout,
  divider,
  progress,
  spinner,
  avatar,

  // Interactive
  button,
  iconButton,
  checkbox,
  switchToggle,
  radio,
  slider,
  textField,

  // Composite
  accordion,
  tabs,
}

/// Icons available for UI nodes, each mapped to a Material icon.
enum UiNodeIcon {
  star(Icons.star),
  favorite(Icons.favorite),
  check(Icons.check),
  close(Icons.close),
  add(Icons.add),
  remove(Icons.remove),
  search(Icons.search),
  settings(Icons.settings),
  home(Icons.home),
  person(Icons.person),
  mail(Icons.mail),
  notifications(Icons.notifications),
  info(Icons.info),
  warning(Icons.warning),
  error(Icons.error),
  lightbulb(Icons.lightbulb),
  rocket(Icons.rocket_launch),
  palette(Icons.palette),
  code(Icons.code),
  cloud(Icons.cloud);

  const UiNodeIcon(this.iconData);
  final IconData iconData;
}

/// Accent colors available for theming component previews.
/// Maps to [FortalAccentColor] from Remix.
enum UiAccentColor {
  amber,
  blue,
  crimson,
  cyan,
  gold,
  grass,
  green,
  indigo,
  iris,
  jade,
  lime,
  mint,
  orange,
  pink,
  plum,
  purple,
  red,
  ruby,
  sky,
  teal,
  tomato,
  violet,
  yellow;

  FortalAccentColor get fortalColor =>
      FortalAccentColor.values.firstWhere((e) => e.name == name);
}

/// Gray neutral families for theming. Maps to [FortalGrayColor] from Remix.
enum UiGrayColor {
  gray,
  mauve,
  slate,
  sage,
  olive,
  sand;

  FortalGrayColor get fortalColor =>
      FortalGrayColor.values.firstWhere((e) => e.name == name);
}

/// Brightness mode for theming.
enum UiBrightness {
  light,
  dark;

  Brightness get flutterBrightness => switch (this) {
    UiBrightness.light => Brightness.light,
    UiBrightness.dark => Brightness.dark,
  };
}

// ─────────────────────────────────── SCHEMAS ───────────────────────────────────

/// Schema for a single UI node in the component tree.
///
/// Each node represents a Remix component with optional children.
/// The `type` field determines which Remix widget gets rendered.
/// Children allow composition (e.g., a Card containing a Button and Text).
@AckType(name: 'UiNode')
final _uiNodeSchema = Ack.object({
  'id': Ack.string().describe('Unique identifier for this node'),
  'type': Ack.enumValues(
    UiComponentType.values,
  ).describe('Component type. Use row/column for layout, text for labels.'),
  'label': Ack.string().optional().describe(
    'Text label. Used as: button label, badge label, callout text, '
    'text content, textField hint, avatar fallback, accordion/tab title.',
  ),
  'description': Ack.string().optional().describe(
    'Secondary text. Used for callout description or accordion content.',
  ),
  'icon': Ack.enumValues(
    UiNodeIcon.values,
  ).optional().describe('Icon name from Material Icons'),
  'color': Ack.string()
      .matches(r'^#[0-9A-Fa-f]{6}$')
      .optional()
      .describe(
        'Hex color for badges, progress bars, or avatar background. e.g. "#6366F1"',
      ),
  'value': Ack.double()
      .min(0.0)
      .max(1.0)
      .optional()
      .describe(
        'Numeric value. Slider value (0.0-1.0) or progress percentage (0.0-1.0).',
      ),
  'selected': Ack.boolean().optional().describe(
    'Selected/checked state for checkbox, switch, radio.',
  ),
  'children': Ack.list(
    Ack.string(),
  ).optional().describe('Child node IDs referencing other nodes by their id.'),
}).describe('A single UI component node in the tree');

/// Schema for Fortal theme configuration.
///
/// All fields are optional — omitted fields inherit from the parent theme scope.
@AckType(name: 'UiTheme')
final _uiThemeSchema = Ack.object({
  'accent': Ack.enumValues(UiAccentColor.values).optional().describe(
    'Accent color for interactive elements (buttons, links, focus rings). '
    'Omit to use default iris. Popular choices: blue (professional), '
    'crimson (bold), green (natural), violet (creative).',
  ),
  'gray': Ack.enumValues(UiGrayColor.values).optional().describe(
    'Gray neutral for backgrounds, borders, text. Omit for default slate. '
    'Pairs: slate (balanced), mauve (cool/purple tint), sage (earthy/green tint).',
  ),
  'brightness': Ack.enumValues(UiBrightness.values).optional().describe(
    'Light or dark mode. Omit for default light. Use dark for dashboards, '
    'settings panels, or to contrast with the surrounding light interface.',
  ),
}).describe('Fortal theme configuration applied to this component option');

/// Schema for a complete component option that can be previewed and selected.
@AckType(name: 'ComponentOption')
final _componentOptionSchema = Ack.object({
  'id': Ack.string().describe('Unique identifier using snake_case'),
  'title': Ack.string().describe('Display name for this component composition'),
  'description': Ack.string().describe(
    'Brief explanation of what this component does',
  ),
  'rootNodeId': Ack.string().describe(
    'ID of the root node to start rendering from',
  ),
  'nodes': Ack.list(
    _uiNodeSchema,
  ).describe('All UI nodes that form the component tree'),
}).describe('A component composition option with its UI tree');

/// Top-level schema for the RemixComponentPreview catalog item.
@AckType(name: 'RemixComponentPreview')
final _remixComponentPreviewSchema =
    Ack.object({
      'question': Ack.string().describe('The question to display to the user'),
      'description': Ack.string().optional().describe(
        'Additional context or instructions',
      ),
      'componentOptions': Ack.list(
        _componentOptionSchema,
      ).describe('Component options to preview and select'),
      'theme': _uiThemeSchema.optional().describe(
        'Fortal theme applied to all component options. '
        'One shared theme for consistent preview.',
      ),
      'action': actionSchema,
    }).describe(
      'A question with live Remix component previews. '
      'User selects one component composition.',
    );

// ─────────────────────────────────── DATA NORMALIZATION ───────────────────────────────────

/// Valid enum name sets for case-insensitive matching.
final _componentTypeNames = {
  for (final v in UiComponentType.values) v.name.toLowerCase(): v.name,
};
final _iconNames = {
  for (final v in UiNodeIcon.values) v.name.toLowerCase(): v.name,
};
final _accentNames = {
  for (final v in UiAccentColor.values) v.name.toLowerCase(): v.name,
};
final _grayNames = {
  for (final v in UiGrayColor.values) v.name.toLowerCase(): v.name,
};
final _brightnessNames = {
  for (final v in UiBrightness.values) v.name.toLowerCase(): v.name,
};

/// Normalizes AI-generated preview data to handle common enum casing issues.
///
/// Gemini sometimes returns enum values in Title Case or UPPERCASE instead
/// of the expected camelCase/lowercase. This pre-processes the data before
/// Ack schema validation to prevent parse failures.
Map<String, Object?> _normalizePreviewData(Map<String, Object?> data) {
  final result = Map<String, Object?>.from(data);

  // Normalize theme enums
  if (result['theme'] case final Map<String, Object?> theme) {
    result['theme'] = _normalizeTheme(theme);
  }

  // Normalize component options
  if (result['componentOptions'] case final List options) {
    result['componentOptions'] = options.map((option) {
      if (option is! Map<String, Object?>) return option;
      final o = Map<String, Object?>.from(option);
      if (o['nodes'] case final List nodes) {
        o['nodes'] = nodes.map((node) {
          if (node is! Map<String, Object?>) return node;
          return _normalizeNode(node);
        }).toList();
      }
      return o;
    }).toList();
  }

  return result;
}

/// Common CSS color names that Gemini returns instead of hex codes.
const _namedColors = <String, String>{
  'red': '#EF4444',
  'green': '#22C55E',
  'blue': '#3B82F6',
  'yellow': '#EAB308',
  'orange': '#F97316',
  'purple': '#A855F7',
  'pink': '#EC4899',
  'cyan': '#06B6D4',
  'teal': '#14B8A6',
  'indigo': '#6366F1',
  'violet': '#8B5CF6',
  'gray': '#6B7280',
  'grey': '#6B7280',
  'white': '#FFFFFF',
  'black': '#000000',
};

final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// Normalizes a color value to hex format.
///
/// Accepts hex codes (pass-through) and common CSS color names.
/// Returns null for unrecognized values so the schema's optional field
/// is simply omitted rather than failing validation.
String? _normalizeColor(String color) {
  if (_hexColorPattern.hasMatch(color)) return color;
  return _namedColors[color.toLowerCase()];
}

Map<String, Object?> _normalizeNode(Map<String, Object?> node) {
  final n = Map<String, Object?>.from(node);
  if (n['type'] case final String type) {
    n['type'] = _componentTypeNames[type.toLowerCase()] ?? type;
  }
  if (n['icon'] case final String icon) {
    n['icon'] = _iconNames[icon.toLowerCase()] ?? icon;
  }
  if (n['color'] case final String color) {
    final normalized = _normalizeColor(color);
    if (normalized != null) {
      n['color'] = normalized;
    } else {
      n.remove('color');
    }
  }
  return n;
}

Map<String, Object?> _normalizeTheme(Map<String, Object?> theme) {
  final t = Map<String, Object?>.from(theme);
  if (t['accent'] case final String accent) {
    t['accent'] = _accentNames[accent.toLowerCase()] ?? accent;
  }
  if (t['gray'] case final String gray) {
    t['gray'] = _grayNames[gray.toLowerCase()] ?? gray;
  }
  if (t['brightness'] case final String brightness) {
    t['brightness'] = _brightnessNames[brightness.toLowerCase()] ?? brightness;
  }
  return t;
}

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// RemixComponentPreview catalog component for component selection.
final remixComponentPreview = CatalogItem(
  name: 'RemixComponentPreview',
  dataSchema: _remixComponentPreviewSchema.toJsonSchemaBuilder(),
  exampleData: remixComponentPreviewExamples,
  widgetBuilder: (context) {
    final rawData = context.data as Map<String, Object?>;
    final normalized = _normalizePreviewData(rawData);
    final data = RemixComponentPreviewType.parse(normalized);
    return _RemixComponentPreviewContent(data: data, itemContext: context);
  },
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
    rawAction: widget.data.action,
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
