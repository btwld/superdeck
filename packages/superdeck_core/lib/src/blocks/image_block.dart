import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'image_block.mapper.dart';

@MappableClass(discriminatorValue: ImageBlock.key)
class ImageBlock extends BaseBlock with ImageBlockMappable {
  static const key = 'image';
  final Asset asset;
  final ImageFit? fit;
  final double? width;
  final double? height;

  ImageBlock({
    required this.asset,
    this.fit,
    this.width,
    this.height,
    super.align,
    super.flex,
    super.scrollable,
  }) : super(type: key);

  static final schema = BaseBlock.schema.extend(
    {
      "fit": ImageFit.schema.nullable(),
      "asset": Asset.schema,
      "width": Ack.double.nullable(),
      "height": Ack.double.nullable(),
    },
    required: [
      "asset",
    ],
  );
}
