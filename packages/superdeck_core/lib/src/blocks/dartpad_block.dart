import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'dartpad_block.mapper.dart';

@MappableClass(discriminatorValue: DartPadBlock.key)
class DartPadBlock extends BaseBlock with DartPadBlockMappable {
  final String id;
  final DartPadTheme? theme;
  final bool? embed;
  final bool? run;

  static const key = 'dartpad';

  DartPadBlock({
    required this.id,
    this.theme,
    this.embed,
    this.run,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  String getDartPadUrl() {
    return 'https://dartpad.dev/?id=$id&theme=$theme&embed=$embed&run=$run';
  }

  static final schema = BaseBlock.schema.extend(
    {
      'id': Ack.string,
      'theme': DartPadTheme.schema.nullable(),
      'embed': Ack.boolean.nullable(),
      'run': Ack.boolean.nullable(),
    },
    required: [
      "id",
    ],
  );
}
