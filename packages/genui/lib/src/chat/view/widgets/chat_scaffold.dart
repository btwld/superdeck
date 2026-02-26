import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

/// Two-panel scaffold for chat interface with collapsible trailing panel.
///
/// Displays a leading widget (typically AI surfaces) and an optional trailing
/// widget (typically chat messages) separated by a divider. The trailing panel
/// can be hidden via [showChat] for fullscreen mode.
class ChatScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget leadingWidget;
  final Widget trailingWidget;
  final bool showChat;

  const ChatScaffold({
    super.key,
    this.appBar,
    required this.leadingWidget,
    required this.trailingWidget,
    this.showChat = true,
  });

  @override
  Widget build(BuildContext context) {
    final divider = BoxStyler().width(1).color(FortalTokens.gray3());

    return Scaffold(
      appBar: appBar,
      backgroundColor: FortalTokens.gray1.resolve(context),
      body: FlexBox(
        children: [
          Expanded(child: leadingWidget),
          if (showChat) ...[divider(), Expanded(child: trailingWidget)],
        ],
      ),
    );
  }
}
