// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'remix_component_preview.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for UiNode
extension type UiNodeType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UiNodeType parse(Object? data) {
    return _uiNodeSchema.parseAs(
      data,
      (validated) => UiNodeType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<UiNodeType> safeParse(Object? data) {
    return _uiNodeSchema.safeParseAs(
      data,
      (validated) => UiNodeType(validated as Map<String, Object?>),
    );
  }

  String get id => _data['id'] as String;

  UiComponentType get type => _data['type'] as UiComponentType;

  String? get label => _data['label'] as String?;

  String? get description => _data['description'] as String?;

  UiNodeIcon? get icon => _data['icon'] as UiNodeIcon?;

  String? get color => _data['color'] as String?;

  double? get value => _data['value'] as double?;

  bool? get selected => _data['selected'] as bool?;

  List<String>? get children => _data['children'] != null
      ? _$ackListCast<String>(_data['children'])
      : null;
}

/// Extension type for UiTheme
extension type UiThemeType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UiThemeType parse(Object? data) {
    return _uiThemeSchema.parseAs(
      data,
      (validated) => UiThemeType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<UiThemeType> safeParse(Object? data) {
    return _uiThemeSchema.safeParseAs(
      data,
      (validated) => UiThemeType(validated as Map<String, Object?>),
    );
  }

  UiAccentColor? get accent => _data['accent'] as UiAccentColor?;

  UiGrayColor? get gray => _data['gray'] as UiGrayColor?;

  UiBrightness? get brightness => _data['brightness'] as UiBrightness?;
}

/// Extension type for ComponentOption
extension type ComponentOptionType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ComponentOptionType parse(Object? data) {
    return _componentOptionSchema.parseAs(
      data,
      (validated) => ComponentOptionType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ComponentOptionType> safeParse(Object? data) {
    return _componentOptionSchema.safeParseAs(
      data,
      (validated) => ComponentOptionType(validated as Map<String, Object?>),
    );
  }

  String get id => _data['id'] as String;

  String get title => _data['title'] as String;

  String get description => _data['description'] as String;

  String get rootNodeId => _data['rootNodeId'] as String;

  List<UiNodeType> get nodes => (_data['nodes'] as List)
      .map((e) => UiNodeType(e as Map<String, Object?>))
      .toList();
}

/// Extension type for RemixComponentPreview
extension type RemixComponentPreviewType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static RemixComponentPreviewType parse(Object? data) {
    return _remixComponentPreviewSchema.parseAs(
      data,
      (validated) =>
          RemixComponentPreviewType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<RemixComponentPreviewType> safeParse(Object? data) {
    return _remixComponentPreviewSchema.safeParseAs(
      data,
      (validated) =>
          RemixComponentPreviewType(validated as Map<String, Object?>),
    );
  }

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  List<ComponentOptionType> get componentOptions =>
      (_data['componentOptions'] as List)
          .map((e) => ComponentOptionType(e as Map<String, Object?>))
          .toList();

  UiThemeType? get theme => _data['theme'] != null
      ? UiThemeType(_data['theme'] as Map<String, Object?>)
      : null;

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);
}
