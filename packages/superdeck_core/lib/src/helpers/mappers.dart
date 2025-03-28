import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

import '../models/block_model.dart';

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

class NullIfEmptyBlock extends SimpleMapper<Block> {
  const NullIfEmptyBlock();

  @override
  Block decode(dynamic value) {
    return BlockMapper.fromMap(value);
  }

  @override
  dynamic encode(Block self) {
    final map = self.toMap();
    if (map.isEmpty) {
      return null;
    }
    return map;
  }
}
