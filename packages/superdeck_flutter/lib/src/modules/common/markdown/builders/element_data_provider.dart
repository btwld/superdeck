import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

import '../../styles/style_spec.dart';

abstract class ElementDataProvider extends InheritedWidget {
  final Size size;
  const ElementDataProvider({
    super.key,
    required super.child,
    required this.size,
  });

  static ElementDataProvider ofAny(BuildContext context) {
    final result = ImageElementDataProvider.maybeOf(context) ??
        CodeElementDataProvider.maybeOf(context) ??
        TextElementDataProvider.maybeOf(context);

    if (result == null) {
      throw FlutterError('No ElementDataProvider found in context');
    }
    return result;
  }

  static T? maybeOf<T extends ElementDataProvider>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<T>();
  }

  static T of<T extends ElementDataProvider>(BuildContext context) {
    final result = maybeOf<T>(context);
    if (result == null) {
      throw FlutterError('No $T found in context');
    }
    return result;
  }
}

class CodeElementDataProvider extends ElementDataProvider {
  final String text;
  final String language;
  final MarkdownCodeblockSpec spec;

  const CodeElementDataProvider({
    super.key,
    required super.child,
    required this.text,
    required this.language,
    required this.spec,
    required super.size,
  });

  static CodeElementDataProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CodeElementDataProvider>();
  }

  @override
  bool updateShouldNotify(
    CodeElementDataProvider oldWidget,
  ) {
    return oldWidget.text != text ||
        oldWidget.language != language ||
        oldWidget.spec != spec ||
        oldWidget.size != size;
  }
}

class ImageElementDataProvider extends ElementDataProvider {
  final ImageSpec spec;
  final Uri uri;
  const ImageElementDataProvider({
    super.key,
    required super.child,
    required super.size,
    required this.spec,
    required this.uri,
  });

  static ImageElementDataProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ImageElementDataProvider>();
  }

  @override
  bool updateShouldNotify(
    ImageElementDataProvider oldWidget,
  ) {
    return oldWidget.size != size ||
        oldWidget.spec != spec ||
        oldWidget.uri != uri;
  }
}

class TextElementDataProvider extends ElementDataProvider {
  final String text;
  final TextSpec spec;

  const TextElementDataProvider({
    super.key,
    required super.child,
    required this.text,
    required this.spec,
    required super.size,
  });

  static TextElementDataProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TextElementDataProvider>();
  }

  @override
  bool updateShouldNotify(
    TextElementDataProvider oldWidget,
  ) {
    return oldWidget.text != text ||
        oldWidget.spec != spec ||
        oldWidget.size != size;
  }
}
