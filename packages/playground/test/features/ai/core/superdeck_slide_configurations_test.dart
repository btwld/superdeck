import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/superdeck_slide_configurations.dart';

void main() {
  test(
    'buildRuntimeSlideConfigurations preserves SuperDeck built-in widgets',
    () async {
      final configurations = await buildRuntimeSlideConfigurations(
        slides: [
          Slide(
            key: 'slide-1',
            sections: [
              SectionBlock([
                WidgetBlock(name: 'image', args: {'src': 'asset.png'}),
              ]),
            ],
          ),
        ],
        options: DeckOptions(),
      );

      expect(configurations, hasLength(1));
      expect(
        configurations.single.widgets.keys,
        containsAll(['image', 'dartpad', 'qrcode']),
      );
    },
  );
}
