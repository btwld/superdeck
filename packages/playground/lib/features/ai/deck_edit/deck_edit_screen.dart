import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../../stores/deck_customization_store.dart';
import '../../../stores/editor_state.dart';
import '../../../utils/memory_deck_loader.dart';
import '../../../utils/text_editor_controller.dart';
import '../../editor/preview_sidebar.dart';
import '../../editor/thumbnail_refresher.dart';
import '../chat/view/widgets/chat_genui_panels.dart';
import '../chat/view/widgets/chat_input.dart';
import '../core/tools/errors.dart';
import 'deck_edit_coordinator.dart';

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
  DeckEditCoordinator? _coordinator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _coordinator?.dispose();
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

    final coordinator = DeckEditCoordinator(
      deckController: deckController,
      loader: loader,
      customizationStore: customizationStore,
      textEditorController: textEditorController,
      captureSlide: _captureSlide,
      isAvailable: () => mounted,
      capturedSource: capturedSource,
    );

    setState(() => _coordinator = coordinator);
    final result = await coordinator.initialize();
    if (!mounted) return;

    switch (result.disposition) {
      case DeckEditStartupDisposition.ready:
        setState(() {});
      case DeckEditStartupDisposition.abort:
        _abortToEditor(
          textEditorController: textEditorController,
          markdown: result.markdown ?? capturedSource ?? '',
          message: result.message ?? 'Unable to start AI deck editing.',
        );
      case DeckEditStartupDisposition.cancelled:
        coordinator.dispose();
    }
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
    textEditorController.stageMarkdownForNextEditorMount(markdown);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _handleSubmit(String value) {
    final viewModel = _coordinator?.viewModel;
    if (viewModel == null) return;
    unawaited(viewModel.sendMessage(value));
    _chatController.clear();
  }

  Future<void> _apply() async {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    final navigator = Navigator.of(context);

    final result = await coordinator.apply();
    if (!mounted) return;
    switch (result.disposition) {
      case DeckEditBoundaryDisposition.success:
        navigator.pushReplacementNamed('/');
      case DeckEditBoundaryDisposition.failure:
        _showBoundaryError(result.message);
      case DeckEditBoundaryDisposition.ignored:
        return;
    }
  }

  Future<void> _discard() async {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    final navigator = Navigator.of(context);

    final result = await coordinator.discard();
    if (!mounted) return;
    switch (result.disposition) {
      case DeckEditBoundaryDisposition.success:
        navigator.pushReplacementNamed('/');
      case DeckEditBoundaryDisposition.failure:
        _showBoundaryError(result.message);
      case DeckEditBoundaryDisposition.ignored:
        return;
    }
  }

  void _showBoundaryError(String? message) {
    final text = message ?? 'Unable to update AI deck edit state.';
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  bool get _isCompositeIdle {
    return _coordinator?.isCompositeIdle ?? false;
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
    final coordinator = _coordinator;
    if (coordinator == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Deck Edit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Watch((context) {
      final status = coordinator.status.value;
      final error = coordinator.errorMessage.value;
      final viewModel = coordinator.viewModel;

      if (status == DeckEditStatus.error) {
        return Scaffold(
          appBar: AppBar(title: const Text('AI Deck Edit')),
          body: Center(
            child: Text(error ?? 'Unable to start AI deck editing.'),
          ),
        );
      }

      if (status == DeckEditStatus.initializing || viewModel == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('AI Deck Edit')),
          body: const Center(child: CircularProgressIndicator()),
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
    });
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
