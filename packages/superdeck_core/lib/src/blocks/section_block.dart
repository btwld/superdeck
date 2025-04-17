import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'section_block.mapper.dart';

// TODO: Resolve NullIfEmptyBlock or remove if not needed in dart_mappable v5+
// @MappableClass(includeCustomMappers: [NullIfEmptyBlock()])
@MappableClass(discriminatorValue: SectionBlock.key)
class SectionBlock extends BaseBlock with SectionBlockMappable {
  late final List<BaseBlock> blocks;

  static const key = 'section';

  SectionBlock(
    List<BaseBlock>? blocks, {
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key) {
    this.blocks = blocks ?? [];
  }

  int get totalBlockFlex {
    return blocks.fold(0, (total, block) => total + (block.flex ?? 1));
  }

  static SectionBlock parse(Map<String, dynamic> map) {
    // Use BaseBlock schema for validation, actual parsing handled by mapper
    // schema.validateOrThrow(map); // Need to adjust schema validation approach
    return SectionBlockMapper.fromMap(map);
  }

  static SectionBlock text(String content) {
    // Ensure this creates the correct block type now (MarkdownBlock)
    return SectionBlock([MarkdownBlock(content)]);
  }

  // Schema definition might need adjustment based on how NullIfEmptyBlock worked
  static final schema = BaseBlock.schema.extend(
    {
      'blocks': BaseBlock.discriminatedSchema.list.nullable(),
    },
  );
}
