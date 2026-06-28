import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:signals/signals_flutter.dart';

import 'deck_tools_schemas.dart';
import 'deck_tools_service.dart';
import 'errors.dart';

class _DeckToolValidationException implements Exception {
  const _DeckToolValidationException(this.message);

  final String message;
}

/// Maps each [DeckToolsService] operation to a Dartantic tool.
class DeckToolsAdapter {
  DeckToolsAdapter(this._service);

  final DeckToolsService _service;
  final Signal<int> _activeInvocations = signal<int>(0);
  var _disposed = false;

  late final Computed<bool> isIdle = computed(() {
    return _activeInvocations.value == 0;
  });

  List<dartantic.Tool<Map<String, dynamic>>> get tools => [
    _getDeckTool,
    _createSlideTool,
    _updateSlideTool,
    _deleteSlideTool,
    _moveSlideTool,
    _readSlideTool,
    _updateStyleTool,
  ];

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    if (_activeInvocations.value == 0) {
      _disposeSignals();
    }
  }

  late final dartantic.Tool<Map<String, dynamic>> _getDeckTool = dartantic.Tool(
    name: 'getDeck',
    description:
        'Returns the current deck slide count and ordered slide summaries.',
    onCall: (_) => _invoke(() async {
      final snapshot = await _service.getDeck();
      return Map<String, dynamic>.from(deckSnapshotSchema.encode(snapshot)!);
    }),
  );

  late final dartantic.Tool<Map<String, dynamic>>
  _createSlideTool = dartantic.Tool(
    name: 'createSlide',
    description:
        'Creates a keyless slide at atIndex, or appends it when atIndex is omitted.',
    inputSchema: createSlideRequestSchema.toJsonSchemaBuilder(),
    onCall: (args) => _invoke(() async {
      final request = _parse(() => CreateSlideRequestType.parse(args));
      final result = await _service.createSlide(request);
      return Map<String, dynamic>.from(
        slideMutationResultSchema.encode(result)!,
      );
    }),
  );

  late final dartantic.Tool<Map<String, dynamic>> _updateSlideTool =
      dartantic.Tool(
        name: 'updateSlide',
        description: 'Replaces the keyless slide at a zero-based index.',
        inputSchema: updateSlideRequestSchema.toJsonSchemaBuilder(),
        onCall: (args) => _invoke(() async {
          final request = _parse(() => UpdateSlideRequestType.parse(args));
          final result = await _service.updateSlide(request);
          return Map<String, dynamic>.from(
            slideMutationResultSchema.encode(result)!,
          );
        }),
      );

  late final dartantic.Tool<Map<String, dynamic>> _deleteSlideTool =
      dartantic.Tool(
        name: 'deleteSlide',
        description: 'Deletes the slide at a zero-based index.',
        inputSchema: deleteSlideRequestSchema.toJsonSchemaBuilder(),
        onCall: (args) => _invoke(() async {
          final request = _parse(() => DeleteSlideRequestType.parse(args));
          final snapshot = await _service.deleteSlide(request);
          return Map<String, dynamic>.from(
            deckSnapshotSchema.encode(snapshot)!,
          );
        }),
      );

  late final dartantic.Tool<Map<String, dynamic>> _moveSlideTool =
      dartantic.Tool(
        name: 'moveSlide',
        description: 'Moves a slide from one zero-based index to another.',
        inputSchema: moveSlideRequestSchema.toJsonSchemaBuilder(),
        onCall: (args) => _invoke(() async {
          final request = _parse(() => MoveSlideRequestType.parse(args));
          final result = await _service.moveSlide(request);
          return Map<String, dynamic>.from(
            slideMoveResultSchema.encode(result)!,
          );
        }),
      );

  late final dartantic.Tool<Map<String, dynamic>>
  _readSlideTool = dartantic.Tool(
    name: 'readSlide',
    description:
        'Reads a keyless slide and returns a base64 PNG thumbnail rendered at thumbnail quality.',
    inputSchema: readSlideRequestSchema.toJsonSchemaBuilder(),
    onCall: (args) => _invoke(() async {
      final request = _parse(() => ReadSlideRequestType.parse(args));
      final result = await _service.readSlide(request);
      return Map<String, dynamic>.from(readSlideResultSchema.encode(result)!);
    }),
  );

  late final dartantic.Tool<Map<String, dynamic>> _updateStyleTool =
      dartantic.Tool(
        name: 'updateStyle',
        description: 'Applies a new global style to the live deck preview.',
        inputSchema: updateStyleRequestSchema.toJsonSchemaBuilder(),
        onCall: (args) => _invoke(() async {
          final request = _parse(() => UpdateStyleRequestType.parse(args));
          final result = await _service.updateStyle(request);
          return Map<String, dynamic>.from(
            styleUpdateResultSchema.encode(result)!,
          );
        }),
      );

  Future<Map<String, dynamic>> _invoke(
    Future<Map<String, dynamic>> Function() body,
  ) async {
    if (_disposed || _service.isClosed) {
      return _error(
        DeckToolErrorCode.contextUnavailable,
        DeckToolException.contextUnavailable().message,
      );
    }

    _activeInvocations.value++;
    try {
      return await body();
    } on _DeckToolValidationException catch (error) {
      return _error('validation_failed', error.message);
    } on DeckToolException catch (error) {
      return _error(error.code, error.message);
    } finally {
      _activeInvocations.value--;
      if (_disposed && _activeInvocations.value == 0) {
        _disposeSignals();
      }
    }
  }

  void _disposeSignals() {
    isIdle.dispose();
    _activeInvocations.dispose();
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } catch (error) {
      throw _DeckToolValidationException('$error');
    }
  }

  Map<String, dynamic> _error(String code, String message) {
    return {
      'error': {'code': code, 'message': message},
    };
  }
}
