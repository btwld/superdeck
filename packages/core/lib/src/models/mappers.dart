import 'package:dart_mappable/dart_mappable.dart';

/// Normalizes the legacy `column` discriminator to `block`.
class BlockDiscriminatorHook extends MappingHook {
  const BlockDiscriminatorHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value case {'type': 'column'}) {
      return {...value, 'type': 'block'};
    }

    return value;
  }
}
