// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_insets.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

BlockInsets _$BlockInsetsFromJson(Map<String, dynamic> json) => BlockInsets(
  top: _ackBlockInsetsFromRuntimeTop(json['top']) ?? 0,
  right: _ackBlockInsetsFromRuntimeRight(json['right']) ?? 0,
  bottom: _ackBlockInsetsFromRuntimeBottom(json['bottom']) ?? 0,
  left: _ackBlockInsetsFromRuntimeLeft(json['left']) ?? 0,
);

Map<String, dynamic> _$BlockInsetsToJson(BlockInsets instance) =>
    <String, dynamic>{
      'top': _ackBlockInsetsToRuntimeTop(instance.top),
      'right': _ackBlockInsetsToRuntimeRight(instance.right),
      'bottom': _ackBlockInsetsToRuntimeBottom(instance.bottom),
      'left': _ackBlockInsetsToRuntimeLeft(instance.left),
    };
