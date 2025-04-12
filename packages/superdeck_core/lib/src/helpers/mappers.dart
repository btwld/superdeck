import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

import '../models/slide_element.dart';

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

class NullIfEmptyBlock extends SimpleMapper<SlideElement> {
  const NullIfEmptyBlock();

  @override
  SlideElement decode(dynamic value) {
    return SlideElementMapper.fromMap(value);
  }

  @override
  dynamic encode(SlideElement self) {
    final map = self.toMap();
    if (map.isEmpty) {
      return null;
    }
    return map;
  }
}
