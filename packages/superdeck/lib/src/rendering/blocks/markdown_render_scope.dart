import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../markdown/markdown_element_builders_registry.dart';

/// Provides access to the shared markdown rendering configuration for a slide.
///
/// The scope bundles the computed [SpecMarkdownBuilders], the resolved
/// [MarkdownStyleSheet], and the active markdown extension set so nested
/// builders (alerts, callouts, etc.) can reuse them without rebuilding new
/// registries.
class MarkdownRenderScope extends InheritedWidget {
  const MarkdownRenderScope({
    super.key,
    required this.registry,
    required this.styleSheet,
    required this.extensionSet,
    required super.child,
  });

  final SpecMarkdownBuilders registry;
  final MarkdownStyleSheet styleSheet;
  final md.ExtensionSet extensionSet;

  static MarkdownRenderScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw FlutterError('MarkdownRenderScope not found in the widget tree.');
    }
    return scope;
  }

  static MarkdownRenderScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MarkdownRenderScope>();
  }

  @override
  bool updateShouldNotify(MarkdownRenderScope oldWidget) {
    return registry != oldWidget.registry ||
        styleSheet != oldWidget.styleSheet ||
        extensionSet != oldWidget.extensionSet;
  }
}
