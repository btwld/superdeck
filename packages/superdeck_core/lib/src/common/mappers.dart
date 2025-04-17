import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

class FileMapper extends SimpleMapper<File> {
  const FileMapper();

  @override
  File decode(Object value) {
    return File(value as String);
  }

  @override
  String encode(File self) {
    return self.path;
  }
}

class DirectoryMapper extends SimpleMapper<Directory> {
  const DirectoryMapper();

  @override
  Directory decode(Object value) {
    return Directory(value as String);
  }

  @override
  String encode(Directory self) {
    return self.path;
  }
}

class DurationMapper extends SimpleMapper<Duration> {
  const DurationMapper();

  @override
  Duration decode(Object value) {
    return Duration(milliseconds: value as int);
  }

  @override
  int encode(Duration self) {
    return self.inMilliseconds;
  }
}

/// A custom mapper that handles null values for empty blocks
///
/// This is needed because the mapper will by default resolve null
/// values to an empty list, but we want to keep null values
/// for empty blocks
class NullIfEmptyBlock extends SimpleMapper<BaseBlock> {
  const NullIfEmptyBlock();

  @override
  BaseBlock decode(dynamic value) {
    return BaseBlockMapper.fromMap(value);
  }

  @override
  dynamic encode(BaseBlock self) {
    if (self is SectionBlock) {
      if (self.blocks.isEmpty) {
        final Map<String, dynamic> data = self.toMap();
        data.remove('blocks');
        return data;
      }
    }

    return self.toMap();
  }
}
