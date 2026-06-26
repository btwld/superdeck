import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../stores/deck_customization_store.dart';
import '../../../stores/editor_state.dart';
import '../../../utils/memory_deck_loader.dart';
import '../../../utils/text_editor_controller.dart';
import '../../editor/preview_sidebar.dart';
import '../../editor/thumbnail_refresher.dart';
import '../chat/view/widgets/chat_genui_panels.dart';
import '../chat/view/widgets/chat_input.dart';
import '../core/ai/prompts/prompt_registry.dart';
import '../core/tools/deck_tools_adapter.dart';
import '../core/tools/deck_tools_runtime.dart';
import '../core/tools/deck_tools_service.dart';
import '../core/tools/errors.dart';
import '../core/tools/in_memory_deck_store.dart';
import 'deck_edit_viewmodel.dart';

class DeckEditScreen extends StatefulWidget {
  const DeckEditScreen({super.key});

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> {
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SlideCaptureService _captureService = SlideCaptureService();

  bool _started = false;
  bool _boundaryRunning = false;
  String? _entryError;
  String? _baselineCanonicalMarkdown;
  DeckCustomizationSnapshot? _baselineCustomizationSnapshot;
  InMemoryDeckStore? _store;
  DeckToolsService? _service;
  DeckToolsAdapter? _adapter;
  DeckEditViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    _adapter?.dispose();
    _service
      ?..closeSession()
      ..dispose();
    _chatController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final deckController = context.read<DeckController>();
    final loader = context.read<MemoryDeckLoader>();
    final customizationStore = context.read<DeckCustomizationStore>();
    final textEditorController = context.read<TextEditorController>();
    final args = ModalRoute.of(context)?.settings.arguments;
    final capturedSource = args is String ? args : null;

    final store = InMemoryDeckStore(
      loader: loader,
      slidesProvider: () => _liveSlides(deckController),
    );
    String? canonicalForAbort;

    try {
      canonicalForAbort = await _writeEntryMarkdown(
        store: store,
        deckController: deckController,
        textEditorController: textEditorController,
        capturedSource: capturedSource,
      );

      if (!PromptRegistry.instance.isLoaded) {
        await PromptRegistry.instance.load();
      }

      if (!mounted) return;

      final runtime = DeckToolsRuntime(
        slideConfigurationsProvider: () => deckController.slides.value,
        applyStyle: customizationStore.applyFromAiStyle,
        isAvailable: () => mounted,
        captureSlide: _captureSlide,
      );
      final service = DeckToolsService(documentStore: store, runtime: runtime);
      final adapter = DeckToolsAdapter(service);
      final viewModel = DeckEditViewModel(toolsAdapter: adapter);
      final baselineMarkdown = _serializeLiveSlides(deckController);

      setState(() {
        _store = store;
        _service = service;
        _adapter = adapter;
        _viewModel = viewModel;
        _baselineCanonicalMarkdown = baselineMarkdown;
        _baselineCustomizationSnapshot = customizationStore.captureSnapshot();
      });
    } catch (error) {
      final handoff = canonicalForAbort ?? capturedSource ?? '';
      _abortToEditor(
        textEditorController: textEditorController,
        markdown: handoff,
        message: 'Unable to start AI deck editing: $error',
      );
    }
  }

  Future<String> _writeEntryMarkdown({
    required InMemoryDeckStore store,
    required DeckController deckController,
    required TextEditorController textEditorController,
    required String? capturedSource,
  }) {
    if (capturedSource != null) {
      if (!textEditorController.outboundWritesSuspended) {
        throw DeckToolException.contextUnavailable();
      }
      return store.writeCanonicalMarkdown(capturedSource);
    }

    return store.writeCanonicalMarkdown(_serializeLiveSlides(deckController));
  }

  String _serializeLiveSlides(DeckController deckController) {
    return const SlideSerializer().serialize(_liveSlides(deckController));
  }

  List<Slide> _liveSlides(DeckController deckController) {
    return deckController.slides.value
        .map((configuration) => configuration.slide)
        .toList();
  }

  Future<Uint8List> _captureSlide(SlideConfiguration configuration) {
    if (!mounted) throw DeckToolException.contextUnavailable();
    return _captureService.capture(
      quality: SlideCaptureQuality.thumbnail,
      slide: configuration,
      context: context,
    );
  }

  void _abortToEditor({
    required TextEditorController textEditorController,
    required String markdown,
    required String message,
  }) {
    if (!mounted) return;
    setState(() => _entryError = message);
    textEditorController.stageMarkdownForNextEditorMount(markdown);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _handleSubmit(String value) {
    final viewModel = _viewModel;
    if (viewModel == null) return;
    viewModel.sendMessage(value);
    _chatController.clear();
  }

  Future<void> _apply() async {
    final service = _service;
    if (service == null || !_isCompositeIdle) return;

    final deckController = context.read<DeckController>();
    final textEditorController = context.read<TextEditorController>();
    final navigator = Navigator.of(context);
    final finalMarkdown = _serializeLiveSlides(deckController);

    setState(() => _boundaryRunning = true);
    service.closeSession();
    textEditorController.loadMarkdown(finalMarkdown);
    if (!mounted) return;
    navigator.pushReplacementNamed('/');
  }

  Future<void> _discard() async {
    final service = _service;
    final store = _store;
    final baselineMarkdown = _baselineCanonicalMarkdown;
    final baselineSnapshot = _baselineCustomizationSnapshot;
    if (service == null ||
        store == null ||
        baselineMarkdown == null ||
        baselineSnapshot == null ||
        !_isCompositeIdle) {
      return;
    }

    final customizationStore = context.read<DeckCustomizationStore>();
    final textEditorController = context.read<TextEditorController>();
    final navigator = Navigator.of(context);

    setState(() => _boundaryRunning = true);
    service.closeSession();
    try {
      await store.writeCanonicalMarkdown(baselineMarkdown);
      customizationStore.restoreSnapshot(baselineSnapshot);
      textEditorController.loadMarkdown(baselineMarkdown);
      if (!mounted) return;
      navigator.pushReplacementNamed('/');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _boundaryRunning = false;
        _entryError = 'Unable to discard AI edits: $error';
      });
    }
  }

  bool get _isCompositeIdle {
    final viewModel = _viewModel;
    final adapter = _adapter;
    final service = _service;
    if (viewModel == null || adapter == null || service == null) return false;
    return !_boundaryRunning &&
        !viewModel.isThinking.value &&
        adapter.isIdle.value &&
        service.isSideEffectQueueIdle.value;
  }

  Future<void> _promptExit() async {
    if (!_isCompositeIdle) return;
    final action = await showDialog<_BoundaryAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave AI edit mode?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_BoundaryAction.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_BoundaryAction.discard),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_BoundaryAction.apply),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    switch (action) {
      case _BoundaryAction.apply:
        await _apply();
      case _BoundaryAction.discard:
        await _discard();
      case _BoundaryAction.cancel || null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Deck Edit')),
        body: Center(
          child: _entryError == null
              ? const CircularProgressIndicator()
              : Text(_entryError!),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_promptExit());
      },
      child: ThumbnailRefresher(
        child: Watch((context) {
          final busy = !_isCompositeIdle;
          return Scaffold(
            appBar: AppBar(
              title: const Text('AI Deck Edit'),
              actions: [
                TextButton(
                  onPressed: busy ? null : _discard,
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : _apply,
                  child: const Text('Apply'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Row(
              children: [
                const PreviewSidebar(),
                const Expanded(child: _ActiveSlideStage()),
                SizedBox(
                  width: 440,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ChatBodyPanel(
                      messages: viewModel.messages,
                      isThinking: viewModel.isThinking,
                      emptyState: const _DeckEditEmptyState(),
                      inputWidget: ChatInput(
                        controller: _chatController,
                        focusNode: _focusNode,
                        enabled: !busy,
                        onSubmitted: _handleSubmit,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

enum _BoundaryAction { apply, discard, cancel }

class _ActiveSlideStage extends StatelessWidget {
  const _ActiveSlideStage();

  @override
  Widget build(BuildContext context) {
    final deckController = context.read<DeckController>();
    final editorState = context.read<EditorState>();

    return Watch((context) {
      final slides = deckController.slides.value;
      if (slides.isEmpty) return const Center(child: Text('No slides'));

      final activeIndex = editorState.activeSlideIndex.value.clamp(
        0,
        slides.length - 1,
      );
      final configuration = slides[activeIndex];

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SlideRenderView(configuration),
            ),
          ),
        ),
      );
    });
  }
}

class _DeckEditEmptyState extends StatelessWidget {
  const _DeckEditEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Ask for a deck edit to begin.'),
      ),
    );
  }
}
