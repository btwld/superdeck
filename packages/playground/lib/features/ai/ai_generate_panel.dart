import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../stores/ai_store.dart';
import 'core/ai/services/generation_progress.dart';

/// Opens the AI generation panel as a modal dialog.
///
/// [aiStore] must be captured from a context that has the provider in scope
/// (the dialog route does not inherit the editor's provider scope reliably).
Future<void> showAiGeneratePanel(BuildContext context, AiStore aiStore) {
  return showRemixDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AiGeneratePanel(aiStore: aiStore),
  );
}

class _AiGeneratePanel extends StatefulWidget {
  const _AiGeneratePanel({required this.aiStore});

  final AiStore aiStore;

  @override
  State<_AiGeneratePanel> createState() => _AiGeneratePanelState();
}

class _AiGeneratePanelState extends State<_AiGeneratePanel> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.aiStore.prompt.peek());
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await widget.aiStore.generate(text);
    if (!mounted) return;
    // Close on success; keep open to show the error otherwise.
    if (widget.aiStore.error.value == null) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HeroCard(
        style: RemixCardStyle().maxWidth(520).paddingAll(24),
        child: ColumnBox(
          style: FlexBoxStyler()
              .mainAxisSize(.min)
              .spacing(12)
              .crossAxisAlignment(.end),
          children: [
            _Header(onClose: () => Navigator.of(context).maybePop()),
            HeroTextField(
              fullWidth: true,
              controller: _controller,
              focusNode: _focusNode,
              style: RemixTextFieldStyle().backgroundColor($surfaceSecondary()),
              hintText:
                  'Describe your presentation — topic, audience, tone, length…',
            ),
            Watch((context) {
              final store = widget.aiStore;
              if (store.isGenerating.value) {
                return _ProgressRow(
                  label: store.phase.value.label,
                  imageProgress: store.imageProgress.value,
                );
              }
              final error = store.error.value;
              if (error != null) {
                return _ErrorRow(message: error);
              }
              return const SizedBox.shrink();
            }),
            Watch((context) {
              final generating = widget.aiStore.isGenerating.value;
              return HeroButton(
                label: 'Generate',
                iconLeft: CupertinoIcons.sparkles,
                onPressed: generating ? null : _generate,
                loading: generating,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler().mainAxisAlignment(.spaceBetween),
      children: [
        StyledText(
          'Generate with AI',
          style: TextStyler().color($foreground()).style($labelMedium.mix()),
        ),
        SizedBox(
          width: 36,
          child: HeroIconButton(
            icon: CupertinoIcons.xmark,
            size: .sm,
            variant: .ghost,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, this.imageProgress});

  final String label;
  final ImageGenerationProgress? imageProgress;

  @override
  Widget build(BuildContext context) {
    final progress = imageProgress;
    final suffix = progress != null
        ? ' (${progress.completed}/${progress.total})'
        : '';
    return RowBox(
      style: FlexBoxStyler().spacing(12),
      children: [
        const CupertinoActivityIndicator(),
        StyledText(
          '$label$suffix',
          style: TextStyler().color($muted()).style($labelSmall.mix()),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler()
          .color($danger().withValues(alpha: 0.1))
          .borderRounded(8)
          .paddingAll(12),
      child: StyledText(
        message,
        style: TextStyler().color($danger()).style($labelSmall.mix()),
      ),
    );
  }
}
