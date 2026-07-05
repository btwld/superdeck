import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

import '../../../../core/result.dart';
import '../../core/engine/services/generation_progress.dart';
import '../../domain/commands/generate_deck_command.dart';

/// Opens the agent generation panel as a modal dialog.
///
/// [command] must be captured from a context that has the provider in scope
/// (the dialog route does not inherit the editor's provider scope reliably).
Future<void> showAgentGeneratePanel(
  BuildContext context,
  GenerateDeckCommand command,
) {
  return showRemixDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AgentGeneratePanel(command: command),
  );
}

class _AgentGeneratePanel extends StatefulWidget {
  const _AgentGeneratePanel({required this.command});

  final GenerateDeckCommand command;

  @override
  State<_AgentGeneratePanel> createState() => _AgentGeneratePanelState();
}

class _AgentGeneratePanelState extends State<_AgentGeneratePanel> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
    await widget.command(text);
    if (!mounted) return;
    // Close on success; keep open to show the error otherwise.
    if (widget.command.completed) {
      widget.command.clearResult();
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
              minLines: 1,
              maxLines: 10,
              style: RemixTextFieldStyle().backgroundColor($surfaceSecondary()),
              hintText:
                  'Describe your presentation — topic, audience, tone, length…',
            ),
            RowBox(
              style: FlexBoxStyler().mainAxisAlignment(.spaceBetween),
              children: [
                ListenableBuilder(
                  listenable: widget.command,
                  builder: (context, _) {
                    final command = widget.command;
                    if (command.running) {
                      return _ProgressRow(label: command.phase.label);
                    }
                    final result = command.result;
                    if (result is Failure) {
                      return _ErrorRow(message: result.error.toString());
                    }
                    return const SizedBox.shrink();
                  },
                ),
                ListenableBuilder(
                  listenable: widget.command,
                  builder: (context, _) {
                    final generating = widget.command.running;
                    return HeroButton(
                      label: 'Generate',
                      iconLeft: CupertinoIcons.sparkles,
                      onPressed: generating ? null : _generate,
                      loading: generating,
                    );
                  },
                ),
              ],
            ),
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
  const _ProgressRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler().spacing(12),
      children: [
        const CupertinoActivityIndicator(),
        StyledText(
          label,
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
