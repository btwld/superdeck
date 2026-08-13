import 'package:ack/ack.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../domain/deck_tool_error.dart';
import '../domain/deck_tools_service.dart';
import 'deck_tool_schemas.dart';

/// Adapts the typed deck service to the current Dartantic tool API.
final class DeckToolsAdapter {
  late final List<dartantic.Tool<Map<String, dynamic>>> tools;

  final DeckToolsService _service;

  DeckToolsAdapter(DeckToolsService service) : _service = service {
    tools = List<dartantic.Tool<Map<String, dynamic>>>.unmodifiable([
      _tool(
        name: 'getDeck',
        description: 'Return the current slide count and slide titles.',
        schema: getDeckArgumentsSchema,
        call: (_) => _service.getDeck(),
      ),
      _tool(
        name: 'createSlide',
        description:
            'Insert a keyless slide, appending when atIndex is omitted.',
        schema: createSlideArgumentsSchema,
        call: (input) => _service.createSlide(
          parseKeylessSlide(input['slide']),
          atIndex: input['atIndex'] as int?,
        ),
      ),
      _tool(
        name: 'updateSlide',
        description: 'Replace the slide at a zero-based index.',
        schema: updateSlideArgumentsSchema,
        call: (input) => _service.updateSlide(
          input['index'] as int,
          parseKeylessSlide(input['slide']),
        ),
      ),
      _tool(
        name: 'deleteSlide',
        description: 'Delete the slide at a zero-based index.',
        schema: deleteSlideArgumentsSchema,
        call: (input) => _service.deleteSlide(input['index'] as int),
      ),
      _tool(
        name: 'moveSlide',
        description: 'Move a slide so it ends at the requested final index.',
        schema: moveSlideArgumentsSchema,
        call: (input) => _service.moveSlide(
          input['fromIndex'] as int,
          input['toIndex'] as int,
        ),
      ),
      _tool(
        name: 'readSlide',
        description: 'Return one keyless slide and a rendered PNG thumbnail.',
        schema: readSlideArgumentsSchema,
        call: (input) => _service.readSlide(input['index'] as int),
      ),
      // updateStyle is not registered yet: its schema and applier targeted the
      // pre-#102 style contract. The service keeps the seam
      // (DeckToolsService.updateStyle); the tool returns with the deck-edit UI
      // once it is rebuilt on the brand/theme contract.
    ]);
  }

  dartantic.Tool<Map<String, dynamic>> _tool({
    required String name,
    required String description,
    required AckSchema schema,
    required Future<Map<String, Object?>> Function(Map<String, dynamic> input)
    call,
  }) {
    return dartantic.Tool(
      name: name,
      description: description,
      onCall: (input) => _invoke(schema, input, call),
      inputSchema: schema.toJsonSchemaBuilder(),
    );
  }

  Future<Map<String, Object?>> _invoke(
    AckSchema schema,
    Map<String, dynamic> input,
    Future<Map<String, Object?>> Function(Map<String, dynamic>) call,
  ) async {
    try {
      schema.parse(input);

      return await call(input);
    } on AckException {
      return _error(.validationFailed, 'The tool arguments are invalid.');
    } on DeckToolError catch (error) {
      return _error(error.code, error.message);
    } catch (_) {
      return _error(
        .internalError,
        'The deck tool could not complete the request.',
      );
    }
  }

  Map<String, Object?> _error(DeckToolErrorCode code, String message) {
    return {
      'error': {'code': code.wireName, 'message': message},
    };
  }
}
