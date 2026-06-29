import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

import '../schemas/genui_action_schema.dart';

part 'remix_component_schema.g.dart';

/// Component types available for UI node rendering.
enum UiComponentType {
  row,
  column,
  text,
  card,
  badge,
  callout,
  divider,
  progress,
  spinner,
  avatar,
  button,
  iconButton,
  checkbox,
  switchToggle,
  radio,
  slider,
  textField,
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

/// Gray neutral families for theming.
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

@AckType(name: 'UiNode')
final uiNodeSchema = Ack.object({
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

@AckType(name: 'UiTheme')
final uiThemeSchema = Ack.object({
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

@AckType(name: 'ComponentOption')
final componentOptionSchema = Ack.object({
  'id': Ack.string().describe('Unique identifier using snake_case'),
  'title': Ack.string().describe('Display name for this component composition'),
  'description': Ack.string().describe(
    'Brief explanation of what this component does',
  ),
  'rootNodeId': Ack.string().describe(
    'ID of the root node to start rendering from',
  ),
  'nodes': Ack.list(
    uiNodeSchema,
  ).describe('All UI nodes that form the component tree'),
}).describe('A component composition option with its UI tree');

@AckType(name: 'RemixComponentPreview')
final remixComponentPreviewSchema =
    Ack.object({
      'question': Ack.string().describe('The question to display to the user'),
      'description': Ack.string().optional().describe(
        'Additional context or instructions',
      ),
      'componentOptions': Ack.list(
        componentOptionSchema,
      ).describe('Component options to preview and select'),
      'theme': uiThemeSchema.optional().describe(
        'Fortal theme applied to all component options. '
        'One shared theme for consistent preview.',
      ),
      'action': actionSchema,
    }).describe(
      'A question with live Remix component previews. '
      'User selects one component composition.',
    );
