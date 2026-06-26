import 'package:flutter/material.dart';
import 'package:remix/remix.dart';
import 'package:signals/signals_flutter.dart';
import '../../chat/view/widgets/chat_genui_panels.dart';
import '../../chat/view/widgets/chat_input.dart';
import '../../chat/view/widgets/chat_scaffold.dart';
import '../../chat/view/widgets/model_select.dart';
import '../../core/ui/ui.dart';
import '../../core/viewmodel_scope.dart';
import '../remix_viewmodel.dart';

/// Standalone Remix component builder screen.
class RemixScreen extends StatelessWidget {
  const RemixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<RemixViewModel>(
      create: () => RemixViewModel(),
      child: const _RemixScreenScaffold(),
    );
  }
}

class _RemixScreenScaffold extends StatefulWidget {
  const _RemixScreenScaffold();

  @override
  State<_RemixScreenScaffold> createState() => _RemixScreenScaffoldState();
}

class _RemixScreenScaffoldState extends State<_RemixScreenScaffold> {
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

  void _handleSubmit(String value) {
    final viewModel = context.read<RemixViewModel>();
    viewModel.sendMessage(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<RemixViewModel>();

    return Watch((context) {
      final showChat = viewModel.showChat.value;
      final isThinking = viewModel.isThinking.value;

      final inputWidget = ChatInput(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !isThinking,
        onSubmitted: _handleSubmit,
      );

      return ChatScaffold(
        showChat: showChat,
        appBar: _buildHeader(
          context: context,
          viewModel: viewModel,
          showChat: showChat,
        ),
        leadingWidget: AiSurfacesPanel(
          host: viewModel.host,
          surfaceIds: viewModel.surfaceIds,
          isThinking: viewModel.isThinking,
          messages: viewModel.messages,
          inputWidget: showChat ? null : inputWidget,
        ),
        trailingWidget: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ChatBodyPanel(
            messages: viewModel.messages,
            isThinking: viewModel.isThinking,
            emptyState: _RemixEmptyState(onSuggestionTap: _handleSubmit),
            inputWidget: showChat ? inputWidget : null,
          ),
        ),
      );
    });
  }

  PreferredSizeWidget _buildHeader({
    required BuildContext context,
    required RemixViewModel viewModel,
    required bool showChat,
  }) {
    return SdHeader(
      leading: Row(
        spacing: 16,
        children: [
          Watch((context) {
            final hasConversationStarted =
                viewModel.hasConversationStarted.value;
            return ModelsSelect(
              enabled: !hasConversationStarted,
              selectedValue: viewModel.model.value,
              onChanged: (value) {
                viewModel.model.set(value);
              },
            );
          }),
        ],
      ),
      trailing: Row(
        spacing: 8,
        children: [
          SdIconButton(
            icon: Icons.forum_outlined,
            semanticLabel: 'Back to chat',
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          Watch((context) {
            final debugMode = viewModel.debugMode.value;
            return Row(
              spacing: 8,
              children: [
                GestureDetector(
                  onTap: () => viewModel.debugMode.set(!debugMode),
                  child: SdCaption(
                    'Show logs',
                    style: TextStyler()
                        .color(FortalTokens.gray11())
                        .fontSize(13),
                  ),
                ),
                SdSwitch(
                  selected: debugMode,
                  semanticLabel: 'Show debug logs',
                  onChanged: (value) {
                    viewModel.debugMode.set(value);
                  },
                ),
              ],
            );
          }),
          SdIconButton(
            icon: showChat ? Icons.chat : Icons.chat_outlined,
            semanticLabel: showChat ? 'Hide chat panel' : 'Show chat panel',
            onPressed: () {
              viewModel.showChat.set(!showChat);
            },
          ),
          SdButton(
            label: 'Restart',
            icon: Icons.replay_rounded,
            semanticLabel: 'Restart conversation',
            onPressed: () {
              viewModel.restartConversation();
            },
          ),
        ],
      ),
    );
  }
}

class _RemixEmptyState extends StatelessWidget {
  const _RemixEmptyState({this.onSuggestionTap});

  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TextStyler()
        .style(FortalTokens.text3.mix())
        .color(FortalTokens.gray10());

    final suggestionsContainer = FlexBoxStyler()
        .column()
        .crossAxisAlignment(.start)
        .spacing(12);

    final suggestionChip = BoxStyler()
        .padding(.symmetric(horizontal: 16, vertical: 10))
        .color(FortalTokens.gray2())
        .borderAll(color: FortalTokens.grayA3())
        .borderRadiusAll(.circular(12));

    final suggestionText = TextStyler()
        .style(FortalTokens.text2.mix())
        .color(FortalTokens.gray11());

    final suggestions = [
      'Settings panel with dark mode',
      'Dashboard with stats',
      'User profile card',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 72,
              color: FortalTokens.gray11.resolve(context),
            ),
            const SizedBox(height: 24),
            SdHeadline('Build Remix components live'),
            const SizedBox(height: 8),
            subtitleStyle(
              'Describe a UI and I\'ll generate multiple themed component options',
            ),
            const SizedBox(height: 40),
            suggestionsContainer(
              children: [
                SdHint('Try asking something like:'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in suggestions)
                      GestureDetector(
                        onTap: () => onSuggestionTap?.call(suggestion),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: suggestionChip(
                            child: suggestionText('"$suggestion"'),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
