import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

class _TestWidgetDefinition extends WidgetDefinition<Map<String, Object?>> {
  const _TestWidgetDefinition();

  @override
  Map<String, Object?> parse(Map<String, Object?> args) => args;

  @override
  Widget build(BuildContext context, Map<String, Object?> args) {
    return const SizedBox.shrink();
  }
}

class _TestExtension extends DeckExtension {
  const _TestExtension(this.name);

  @override
  final String name;
}

void main() {
  group('DeckPresentation', () {
    group('equality', () {
      test('equivalent collection wrappers are equal', () {
        final baseStyle = SlideStyle();
        final widgetDefinition = const _TestWidgetDefinition();
        final template = SlideTemplate(styles: {'hero': SlideStyle()});
        final extension = const _TestExtension('presenter-tools');

        final first = DeckPresentation(
          baseStyle: baseStyle,
          styles: {'deck': SlideStyle()},
          widgets: {'custom': widgetDefinition},
          parts: const SlideParts(),
          debug: true,
          templates: {'main': template},
          defaultTemplate: template,
          extensions: [extension],
        );

        final second = DeckPresentation(
          baseStyle: baseStyle,
          styles: {'deck': SlideStyle()},
          widgets: {'custom': widgetDefinition},
          parts: const SlideParts(),
          debug: true,
          templates: {
            'main': SlideTemplate(styles: {'hero': SlideStyle()}),
          },
          defaultTemplate: template,
          extensions: [extension],
        );

        expect(first, equals(second));
        expect(first.hashCode, equals(second.hashCode));
      });
    });
  });
}
