import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'markdown_block.mapper.dart';

@MappableClass(discriminatorValue: MarkdownBlock.key)
class MarkdownBlock extends BaseBlock with MarkdownBlockMappable {
  static const key = 'column'; // Keep original key or change?
  late final String content;

  MarkdownBlock(
    String? content, {
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key) {
    this.content = content ?? '';
  }

  static final schema = BaseBlock.schema.extend(
    {
      'content': Ack.string,
    },
    required: [
      "content",
    ],
  );
}
