import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../wizard/chat/view/widgets/chat_genui_panels.dart';
import '../../wizard/chat/view/widgets/chat_input.dart';
import '../routes/routes.dart';
import '../data/deck_slide_reader.dart';
import 'deck_edit_session_controller.dart';

class DeckEditScreen extends StatefulWidget {
  const DeckEditScreen({
    required this.args,
    this.conversationFactory,
    this.capture,
    super.key,
  });

  final DeckEditRouteArgs args;
  final DeckEditConversationFactory? conversationFactory;
  final SlideCaptureCallback? capture;

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

enum _ExitChoice { apply, discard }

class _DeckEditScreenState extends State<DeckEditScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  DeckEditSessionController? _session;
  bool _allowPop = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session != null) return;
    final session = DeckEditSessionController(
      args: widget.args,
      deckController: context.read<DeckController>(),
      customizationStore: context.read<DeckCustomizationStore>(),
      routeContext: context,
      conversationFactory: widget.conversationFactory,
      capture: widget.capture,
    );
    _session = session;
    unawaited(session.initialize());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _session?.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final session = _session!;
    if (!session.ready || session.requestInFlight || value.trim().isEmpty) {
      return;
    }
    _textController.clear();
    unawaited(session.sendMessage(value));
  }

  Future<void> _apply() async {
    if (await _session!.apply() && mounted) _exitRoute();
  }

  Future<void> _discard() async {
    if (await _session!.discard() && mounted) _exitRoute();
  }

  void _exitRoute() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _handleBlockedPop(bool didPop, Object? result) async {
    if (didPop || !mounted) return;
    final session = _session!;
    if (session.requestInFlight) return;
    if (!session.dirty) {
      context.pop();
      return;
    }

    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keep AI deck changes?'),
        content: const Text(
          'Apply the live changes, or discard them and restore the deck from '
          'before this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('deck-edit-back-discard'),
            onPressed: () => context.pop(_ExitChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            key: const Key('deck-edit-back-apply'),
            onPressed: () => context.pop(_ExitChoice.apply),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _ExitChoice.apply:
        await _apply();
      case _ExitChoice.discard:
        await _discard();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session!;
    return ChangeNotifierProvider.value(
      value: session,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          return PopScope<Object?>(
            canPop: _allowPop || (!session.requestInFlight && !session.dirty),
            onPopInvokedWithResult: _handleBlockedPop,
            child: Scaffold(
              backgroundColor: $background.resolve(context),
              appBar: AppBar(
                title: const Text('Edit deck with AI'),
                actions: [
                  TextButton(
                    key: const Key('deck-edit-discard'),
                    onPressed: session.requestInFlight ? null : _discard,
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('deck-edit-apply'),
                    onPressed: session.requestInFlight ? null : _apply,
                    child: const Text('Apply'),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: _body(session),
            ),
          );
        },
      ),
    );
  }

  Widget _body(DeckEditSessionController session) {
    if (session.entryError case final error?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: session.requestInFlight
                      ? null
                      : () => unawaited(session.initialize()),
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final viewModel = session.viewModel;
    return SignalBuilder(
      builder: (context) {
        final input = IgnorePointer(
          key: const Key('deck-edit-input-gate'),
          ignoring: !session.ready || session.requestInFlight,
          child: ChatInput(
            controller: _textController,
            focusNode: _focusNode,
            enabled: session.ready && !session.requestInFlight,
            onSubmitted: _submit,
          ),
        );

        return Column(
          children: [
            if (!session.ready)
              const LinearProgressIndicator(key: Key('deck-edit-readiness')),
            if (session.restoreError case final error?)
              MaterialBanner(
                content: Text(error),
                actions: [
                  TextButton(onPressed: _discard, child: const Text('Retry')),
                  TextButton(
                    onPressed: _apply,
                    child: const Text('Keep Changes'),
                  ),
                ],
              ),
            Expanded(
              child: AiSurfacesPanel(
                controller: viewModel.controller,
                surfaceIds: viewModel.surfaceIds,
                isThinking: viewModel.isThinking,
                messages: viewModel.messages,
                inputWidget: input,
              ),
            ),
          ],
        );
      },
    );
  }
}
