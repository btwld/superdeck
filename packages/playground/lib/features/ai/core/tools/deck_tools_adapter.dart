import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:playground/features/ai/core/tools/deck_tools_schemas.dart';
import 'package:playground/features/ai/core/tools/deck_tools_service.dart';

// TODO(phase5): wire the [tools] list into GenUiConversation.additionalTools
// inside GenUiConversationViewModel.buildConversation() once the chat viewmodel
// is given a DeckToolsService dependency.
//
// Example wiring in genui_conversation_viewmodel.dart:
//   final contentGenerator = GoogleGenerativeAiContentGenerator(
//     ...
//     additionalTools: [...deckToolsAdapter.tools],
//   );

/// Maps each [DeckToolsService] operation to a genui [AiTool].
///
/// The adapter is a thin, compiling scaffold — each tool's invoke function
/// calls the corresponding [DeckToolsService] method and returns a JSON-safe
/// result map. The schema for each tool is derived from the Ack schemas already
/// defined in deck_tools_schemas.dart / deck_schemas.dart.
class DeckToolsAdapter {
  DeckToolsAdapter(this._service);

  final DeckToolsService _service;

  /// All deck-editing tools ready to pass to [GoogleGenerativeAiContentGenerator].
  List<AiTool<Map<String, dynamic>>> get tools => [
    _getDeckTool,
    _createSlideTool,
    _updateSlideTool,
    _deleteSlideTool,
    _moveSlideTool,
    _updateStyleTool,
  ];

  // ---------------------------------------------------------------------------
  // Tool: getDeck
  // ---------------------------------------------------------------------------

  late final AiTool<Map<String, dynamic>> _getDeckTool = DynamicAiTool(
    name: 'getDeck',
    description:
        'Returns a snapshot of the current deck, including slide count, '
        'ordered slide summaries, and the active style.',
    invokeFunction: (_) async {
      final snapshot = await _service.getDeck();
      return Map<String, dynamic>.from(deckSnapshotSchema.encode(snapshot)!);
    },
  );

  // ---------------------------------------------------------------------------
  // Tool: createSlide
  // ---------------------------------------------------------------------------

  late final AiTool<Map<String, dynamic>> _createSlideTool = DynamicAiTool(
    name: 'createSlide',
    description:
        'Creates a new slide. Supply a slide schema payload and an optional '
        'insertion index (defaults to appending at the end).',
    parameters: createSlideRequestSchema.toJsonSchemaBuilder(),
    invokeFunction: (args) async {
      final request = CreateSlideRequestType.parse(args);
      final result = await _service.createSlide(request);
      return Map<String, dynamic>.from(
        slideMutationResultSchema.encode(result)!,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Tool: updateSlide
  // ---------------------------------------------------------------------------

  late final AiTool<Map<String, dynamic>> _updateSlideTool = DynamicAiTool(
    name: 'updateSlide',
    description:
        'Replaces the content of an existing slide at the given zero-based '
        'index. The slide key is preserved automatically.',
    parameters: updateSlideRequestSchema.toJsonSchemaBuilder(),
    invokeFunction: (args) async {
      final request = UpdateSlideRequestType.parse(args);
      final result = await _service.updateSlide(request);
      return Map<String, dynamic>.from(
        slideMutationResultSchema.encode(result)!,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Tool: deleteSlide
  // ---------------------------------------------------------------------------

  late final AiTool<Map<String, dynamic>> _deleteSlideTool = DynamicAiTool(
    name: 'deleteSlide',
    description: 'Deletes the slide at the given zero-based index.',
    parameters: deleteSlideRequestSchema.toJsonSchemaBuilder(),
    invokeFunction: (args) async {
      final request = DeleteSlideRequestType.parse(args);
      final snapshot = await _service.deleteSlide(request);
      return Map<String, dynamic>.from(deckSnapshotSchema.encode(snapshot)!);
    },
  );

  // ---------------------------------------------------------------------------
  // Tool: moveSlide
  // ---------------------------------------------------------------------------

  late final AiTool<Map<String, dynamic>> _moveSlideTool = DynamicAiTool(
    name: 'moveSlide',
    description:
        'Moves a slide from one position to another within the deck.',
    parameters: moveSlideRequestSchema.toJsonSchemaBuilder(),
    invokeFunction: (args) async {
      final request = MoveSlideRequestType.parse(args);
      final result = await _service.moveSlide(request);
      return Map<String, dynamic>.from(
        slideMoveResultSchema.encode(result)!,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Tool: updateStyle
  // ---------------------------------------------------------------------------

  late final AiTool<Map<String, dynamic>> _updateStyleTool = DynamicAiTool(
    name: 'updateStyle',
    description:
        'Applies a new global style (colors, fonts) to the entire deck.',
    parameters: updateStyleRequestSchema.toJsonSchemaBuilder(),
    invokeFunction: (args) async {
      final request = UpdateStyleRequestType.parse(args);
      final result = await _service.updateStyle(request);
      return Map<String, dynamic>.from(
        styleUpdateResultSchema.encode(result)!,
      );
    },
  );
}
