import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:remix/remix.dart';
import '../../../ui/ui.dart';

/// Type of chat message bubble for styling differentiation.
///
/// - [user]: Right-aligned with accent color background
/// - [ai]: Left-aligned with transparent background and border
/// - [debug]: Left-aligned with muted styling for debug output
enum TextBubbleType { user, ai, debug }

/// Renders a chat message bubble with markdown support.
///
/// Uses [TextBubbleType] to determine bubble alignment and color:
/// - [TextBubbleType.user] - Right-aligned, accent color background
/// - [TextBubbleType.ai] - Left-aligned, transparent with border
/// - [TextBubbleType.debug] - Left-aligned, muted gray styling
///
/// Supports rendering markdown content via [GptMarkdown] with custom
/// code block styling.
class TextBubble extends StatelessWidget {
  final String text;
  final TextBubbleType type;

  const TextBubble({super.key, required this.text, required this.type});

  BoxStyler get _userStyle => .new()
      .borderRadiusAll(Radius.circular(SdTokens.cardRadius))
      .paddingAll(12)
      .color(FortalTokens.accentA3())
      .wrap(
        WidgetModifierConfig //
            .align(alignment: .centerRight)
            .defaultTextStyle(style: FortalTokens.text3.mix())
            .defaultTextStyle(
              style: TextStyleMix(color: FortalTokens.gray11()),
            ),
      );

  BoxStyler get _aiStyle => _userStyle
      .color(Colors.transparent)
      .borderAll(color: FortalTokens.gray3())
      .wrap(
        WidgetModifierConfig //
            .align(alignment: .centerLeft)
            .defaultTextStyle(
              style: FortalTokens.text3.mix(),
              textHeightBehavior: TextHeightBehaviorMix()
                  .applyHeightToLastDescent(false)
                  .applyHeightToFirstAscent(false),
            ),
      );

  BoxStyler get _debugStyle => _aiStyle
      .color(FortalTokens.gray3())
      .borderAll(color: FortalTokens.gray4())
      .wrap(
        WidgetModifierConfig //
            .defaultTextStyle(style: FortalTokens.text2.mix())
            .defaultTextStyle(
              style: TextStyleMix(color: FortalTokens.gray10()),
            ),
      );

  @override
  Widget build(BuildContext context) {
    final container = switch (type) {
      TextBubbleType.user => _userStyle,
      TextBubbleType.ai => _aiStyle,
      TextBubbleType.debug => _debugStyle,
    };

    return container(
      child: GptMarkdown(
        text,
        codeBuilder: (context, _, code, _) {
          return _CodeBlock(code: code);
        },
      ),
    );
  }
}

/// Code block widget with monospace font, padding, and horizontal scroll.
class _CodeBlock extends StatelessWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    final codeContainer = BoxStyler()
        .color(FortalTokens.gray2())
        .borderRadiusAll(Radius.circular(8))
        .borderAll(color: FortalTokens.gray4())
        .paddingAll(12);

    return codeContainer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: FortalTokens.gray11.resolve(context),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
