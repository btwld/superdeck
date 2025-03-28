import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../superdeck.dart';
import '../../modules/common/markdown/markdown_element_builders.dart';

class MarkdownViewer extends ImplicitlyAnimatedWidget {
  final String content;
  final SlideSpec spec;

  const MarkdownViewer({
    super.key,
    required this.content,
    required this.spec,
    super.duration = Durations.medium1,
    super.curve = Curves.linear,
  });

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _MarkdownViewerState();
}

class _MarkdownViewerState extends AnimatedWidgetBaseState<MarkdownViewer> {
  SlideSpecTween? _styleTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _styleTween = visitor(
      _styleTween,
      widget.spec,
      (dynamic value) => SlideSpecTween(begin: value),
    ) as SlideSpecTween?;
  }

  @override
  Widget build(BuildContext context) {
    final spec = _styleTween!.evaluate(animation) ?? const SlideSpec();
    return _MarkdownBuilder(
      content: widget.content,
      spec: spec,
    );
  }
}

class _MarkdownBuilder extends StatelessWidget {
  final String content;
  final SlideSpec spec;

  const _MarkdownBuilder({
    required this.content,
    required this.spec,
  });

  @override
  Widget build(BuildContext context) {
    final builders = SpecMarkdownBuilders(spec);
    return MarkdownBody(
      data: content,
      extensionSet: md.ExtensionSet.gitHubWeb,
      builders: builders.builders,
      paddingBuilders: builders.paddingBuilders,
      checkboxBuilder: builders.checkboxBuilder,
      bulletBuilder: builders.bulletBuilder,
      blockSyntaxes: builders.blockSyntaxes,
      inlineSyntaxes: builders.inlineSyntaxes,
      styleSheet: spec.toStyle(),
    );
  }
}
