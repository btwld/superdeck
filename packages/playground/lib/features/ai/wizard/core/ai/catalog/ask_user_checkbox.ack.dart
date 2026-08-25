// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ask_user_checkbox.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

/// Immutable model generated from `_askUserCheckboxSchema`.
/// A question with checkbox items. User selects one or more items.
@AckInfer.jsonSerializable
final class AskUserCheckbox {
  AskUserCheckbox({
    required this.question,
    this.description,
    required List<String> items,
    List<String>? selectedItems,
    this.minSelections,
    this.maxSelections,
    required this.action,
  }) : items = List<String>.unmodifiable(items.map((item) => item)),
       selectedItems = switch (selectedItems) {
         null => null,
         final fieldValue => List<String>.unmodifiable(
           fieldValue.map((item) => item),
         ),
       };

  factory AskUserCheckbox.parse(Object? input) {
    return $ack.parse(input);
  }

  factory AskUserCheckbox.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// The question to display to the user
  final String question;

  /// Additional context or instructions
  final String? description;

  /// Checkbox items as strings for multiple selection
  final List<String> items;

  /// Initially selected items
  final List<String>? selectedItems;

  /// Minimum selections required, default 1
  final int? minSelections;

  /// Maximum selections allowed
  final int? maxSelections;

  final GenUiAction action;

  static final $ack = AckModelAdapter(
    schema: () => _askUserCheckboxSchema,
    fromRuntime: AskUserCheckbox._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<AskUserCheckbox> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  AskUserCheckbox copyWith({
    String? question,
    String? description,
    List<String>? items,
    List<String>? selectedItems,
    int? minSelections,
    int? maxSelections,
    GenUiAction? action,
  }) => AskUserCheckbox(
    question: question ?? this.question,
    description: description ?? this.description,
    items: items ?? this.items,
    selectedItems: selectedItems ?? this.selectedItems,
    minSelections: minSelections ?? this.minSelections,
    maxSelections: maxSelections ?? this.maxSelections,
    action: action ?? this.action,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AskUserCheckbox &&
          runtimeType == other.runtimeType &&
          deepEquals(question, other.question) &&
          deepEquals(description, other.description) &&
          deepEquals(items, other.items) &&
          deepEquals(selectedItems, other.selectedItems) &&
          deepEquals(minSelections, other.minSelections) &&
          deepEquals(maxSelections, other.maxSelections) &&
          deepEquals(action, other.action));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(question),
    deepHashCode(description),
    deepHashCode(items),
    deepHashCode(selectedItems),
    deepHashCode(minSelections),
    deepHashCode(maxSelections),
    deepHashCode(action),
  ]);

  @override
  String toString() =>
      'AskUserCheckbox(question: $question, description: $description, items: $items, selectedItems: $selectedItems, minSelections: $minSelections, maxSelections: $maxSelections, action: $action)';

  static AskUserCheckbox _fromAckRuntime(Map<String, Object?> value) =>
      _$AskUserCheckboxFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$AskUserCheckboxToJson(this),
  };

  static String _ackFromRuntimeQuestion(Object? value) => value as String;

  static Object? _ackToRuntimeQuestion(String value) => value;

  static String? _ackFromRuntimeDescription(Object? value) => value as String?;

  static Object? _ackToRuntimeDescription(String? value) => value;

  static List<String> _ackFromRuntimeItems(Object? value) =>
      (value as List).map((item) => item as String).toList();

  static Object? _ackToRuntimeItems(List<String> value) =>
      value.map((item) => item).toList(growable: false);

  static List<String>? _ackFromRuntimeSelectedItems(Object? value) =>
      switch (value) {
        null => null,
        final fieldValue =>
          (fieldValue as List).map((item) => item as String).toList(),
      };

  static Object? _ackToRuntimeSelectedItems(List<String>? value) =>
      switch (value) {
        null => null,
        final fieldValue =>
          fieldValue.map((item) => item).toList(growable: false),
      };

  static int? _ackFromRuntimeMinSelections(Object? value) => value as int?;

  static Object? _ackToRuntimeMinSelections(int? value) => value;

  static int? _ackFromRuntimeMaxSelections(Object? value) => value as int?;

  static Object? _ackToRuntimeMaxSelections(int? value) => value;

  static GenUiAction _ackFromRuntimeAction(Object? value) =>
      GenUiAction.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeAction(GenUiAction value) =>
      GenUiAction.$ack.toRuntime(value);
}
