import 'catalog_data_normalizer.dart';
import 'remix_component_schema.dart';

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

Map<String, Object?> normalizeRemixComponentPreviewData(
  Map<String, Object?> data,
) {
  final result = Map<String, Object?>.from(data);

  if (result['theme'] case final Map<String, Object?> theme) {
    result['theme'] = _normalizeTheme(theme);
  }

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

  return normalizeCatalogData(result) as Map<String, Object?>;
}

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
  if (n['value'] case final int value) {
    n['value'] = value.toDouble();
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
