import 'package:flutter/material.dart';
import 'package:remix/remix.dart';
import '../../chat/view/widgets/conversation_screen_shell.dart';
import '../../core/ai/services/ai_conversation_viewmodel.dart';
import '../../core/ui/ui.dart';
import '../../core/viewmodel_scope.dart';
import '../remix_conversation_profile.dart';

/// Standalone Remix component builder screen.
class RemixScreen extends StatelessWidget {
  const RemixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<AiConversationViewModel>(
      create: () =>
          AiConversationViewModel(profile: remixConversationProfile()),
      child: const _RemixScreenScaffold(),
    );
  }
}

class _RemixScreenScaffold extends StatelessWidget {
  const _RemixScreenScaffold();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AiConversationViewModel>();
    return ConversationScreenShell(
      viewModel: viewModel,
      emptyStateBuilder: (onSuggestionTap) =>
          _RemixEmptyState(onSuggestionTap: onSuggestionTap),
      headerActionsBuilder: (context, viewModel) {
        return [
          SdIconButton(
            icon: Icons.forum_outlined,
            semanticLabel: 'Back to chat',
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
        ];
      },
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
