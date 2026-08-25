import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'genui_action_schema.ack.dart';
part 'genui_action_schema.ack.g.dart';

@AckInfer(name: 'ActionContextValue')
final _actionContextValueSchema = Ack.object({
  'path': Ack.string().optional().describe('Data model path binding'),
  'literalString': Ack.string().optional().describe('Literal string value'),
  'literalNumber': Ack.double().optional().describe('Literal number value'),
  'literalBoolean': Ack.boolean().optional().describe('Literal boolean value'),
}).describe('Context value - use path or one of the literal types');

@AckInfer(name: 'ActionContextEntry')
final _actionContextEntrySchema = Ack.object({
  'key': Ack.string().describe('Context key'),
  'value': _actionContextValueSchema,
}).describe('Context entry with key and value');

/// Shared GenUI action schema for catalog components.
///
/// This schema defines the structure for user actions dispatched by GenUI
/// components. It's defined with @AckInfer() for code generation support.
///
/// Usage:
/// ```dart
/// // Reference in other schemas (same file):
/// 'action': actionSchema,
///
/// // Parse action data:
/// final action = GenUiAction.parse(data.action);
/// final name = action.name;
/// ```
@AckInfer(name: 'GenUiAction')
final actionSchema = Ack.object({
  'name': Ack.string().describe('Action name to dispatch'),
  'context': Ack.list(
    _actionContextEntrySchema,
  ).optional().describe('List of context data to include with the action'),
}).describe('GenUI action with name and context binding');
