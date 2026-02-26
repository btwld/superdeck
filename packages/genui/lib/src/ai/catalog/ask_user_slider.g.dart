// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ask_user_slider.dart';

/// Extension type for AskUserSlider
extension type AskUserSliderType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AskUserSliderType parse(Object? data) {
    return _askUserSliderSchema.parseAs(
      data,
      (validated) => AskUserSliderType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AskUserSliderType> safeParse(Object? data) {
    return _askUserSliderSchema.safeParseAs(
      data,
      (validated) => AskUserSliderType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get question => _data['question'] as String;

  String? get description => _data['description'] as String?;

  int get minValue => _data['minValue'] as int;

  int get maxValue => _data['maxValue'] as int;

  int get defaultValue => _data['defaultValue'] as int;

  String? get unit => _data['unit'] as String?;

  ActionType get action => ActionType(_data['action'] as Map<String, Object?>);

  AskUserSliderType copyWith({
    String? question,
    String? description,
    int? minValue,
    int? maxValue,
    int? defaultValue,
    String? unit,
    Map<String, dynamic>? action,
  }) {
    return AskUserSliderType.parse({
      'question': question ?? this.question,
      'description': description ?? this.description,
      'minValue': minValue ?? this.minValue,
      'maxValue': maxValue ?? this.maxValue,
      'defaultValue': defaultValue ?? this.defaultValue,
      'unit': unit ?? this.unit,
      'action': action ?? this.action,
    });
  }
}
