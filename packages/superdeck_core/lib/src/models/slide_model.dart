import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'slide_model.mapper.dart';

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

  static final schema = Ok.object(
    {
      "key": Ok.string(),
      'options': SlideOptions.schema.nullable(),
      'sections': SectionBlock.schema.list(),
      'comments': Ok.string.list(),
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

  static final schema = Ok.object(
    {
      "title": Ok.string.nullable(),
      "style": Ok.string.nullable(),
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
              ColumnBlock('''
> [!CAUTION]
> $title
> $message


```dart
${error.toString()}
```
'''),
              ColumnBlock('')
            ]),
          ],
        );
}
