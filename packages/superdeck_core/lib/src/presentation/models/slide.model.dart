import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'slide.model.mapper.dart';

@MappableClass()
class Slide with SlideMappable {
  final String key;
  final SlideOptions? options;
  final List<SectionBlock> sections;
  final List<String> comments;

  const Slide({
    required this.key,
    this.options,
    this.sections = const [],
    this.comments = const [],
  });

  static final schema = Ack.object(
    {
      "key": Ack.string,
      'options': SlideOptions.schema.nullable(),
      'sections': SectionBlock.schema.list,
      'comments': Ack.string.list,
    },
    required: ['key'],
    additionalProperties: true,
  );

  static Slide parse(Map<String, dynamic> map) {
    schema.validateOrThrow(map);
    return SlideMapper.fromMap(map);
  }
}

@MappableClass(
  hook: UnmappedPropertiesHook('args'),
)
class SlideOptions with SlideOptionsMappable {
  final String? title;
  final String? style;
  final Map<String, Object?> args;

  const SlideOptions({
    this.title,
    this.style,
    this.args = const {},
  });

  static SlideOptions parse(Map<String, dynamic> map) {
    schema.validateOrThrow(map);
    return SlideOptionsMapper.fromMap(map);
  }

  static final schema = Ack.object(
    {
      "title": Ack.string.nullable(),
      "style": Ack.string.nullable(),
    },
    additionalProperties: true,
  );
}

class ErrorSlide extends Slide {
  ErrorSlide({
    required String title,
    required String message,
    required Exception error,
  }) : super(
          key: 'error',
          sections: [
            SectionBlock([
              MarkdownBlock('''
> [!CAUTION]
> $title
> $message


```dart
${error.toString()}
```
'''),
              MarkdownBlock('')
            ]),
          ],
        );
}
