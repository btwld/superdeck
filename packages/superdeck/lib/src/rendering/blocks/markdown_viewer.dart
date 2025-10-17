import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../markdown/markdown_element_builders_registry.dart';
import '../../styling/styles.dart';
import 'markdown_render_scope.dart';

/// Tween for interpolating between SlideSpec values
class SlideSpecTween extends Tween<SlideSpec> {
  SlideSpecTween({super.begin, super.end});

  @override
  SlideSpec lerp(double t) {
    if (begin == null && end == null) return const SlideSpec();
    if (begin == null) return end!;
    if (end == null) return begin!;
    return begin!.lerp(end!, t);
  }
}

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
    _styleTween =
        visitor(
              _styleTween,
              widget.spec,
              (dynamic value) => SlideSpecTween(begin: value),
            )
            as SlideSpecTween?;
  }

  @override
  Widget build(BuildContext context) {
    final spec = _styleTween!.evaluate(animation);
    return _MarkdownBuilder(content: widget.content, spec: spec);
  }
}

class _MarkdownBuilder extends StatelessWidget {
  final String content;
  final SlideSpec spec;

  const _MarkdownBuilder({required this.content, required this.spec});

  @override
  Widget build(BuildContext context) {
    final registry = SpecMarkdownBuilders(spec);
    final styleSheet = spec.toStyle();
    final extensionSet = md.ExtensionSet.gitHubWeb;

    return MarkdownRenderScope(
      registry: registry,
      styleSheet: styleSheet,
      extensionSet: extensionSet,
      child: MarkdownBody(
        data: content,
        extensionSet: extensionSet,
        builders: registry.builders,
        paddingBuilders: registry.paddingBuilders,
        checkboxBuilder: registry.checkboxBuilder,
        bulletBuilder: registry.bulletBuilder,
        blockSyntaxes: registry.blockSyntaxes,
        inlineSyntaxes: registry.inlineSyntaxes,
        styleSheet: styleSheet,
      ),
    );
  }
}
