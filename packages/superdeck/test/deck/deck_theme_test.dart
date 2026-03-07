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

void main() {
  group('DeckTheme', () {
    group('equality', () {
      test('equivalent collection wrappers are equal', () {
        final baseStyle = SlideStyle();
        final widgetDefinition = const _TestWidgetDefinition();
        final template = SlideTemplate(styles: {'hero': SlideStyle()});

        final first = DeckTheme(
          baseStyle: baseStyle,
          styles: {'deck': SlideStyle()},
          widgets: {'custom': widgetDefinition},
          frame: const SlideFrame(),
          debug: true,
          templates: {'main': template},
          defaultTemplate: template,
        );

        final second = DeckTheme(
          baseStyle: baseStyle,
          styles: {'deck': SlideStyle()},
          widgets: {'custom': widgetDefinition},
          frame: const SlideFrame(),
          debug: true,
          templates: {
            'main': SlideTemplate(styles: {'hero': SlideStyle()}),
          },
          defaultTemplate: template,
        );

        expect(first, equals(second));
        expect(first.hashCode, equals(second.hashCode));
      });
    });
  });
}
