import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'widget_block.mapper.dart';

@MappableClass(
  discriminatorValue: WidgetBlock.key,
  hook: UnmappedPropertiesHook('props'),
)
class WidgetBlock extends BaseBlock with WidgetBlockMappable {
  static const key = 'widget'; // Keep original key or change?
  final String id;
  final Map<String, dynamic>? props;

  WidgetBlock({
    required this.id,
    this.props,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  static final schema = BaseBlock.schema.extend(
    {
      'id': Ack.string,
    },
    required: [
      'id',
    ],
    additionalProperties: true,
  );
}
