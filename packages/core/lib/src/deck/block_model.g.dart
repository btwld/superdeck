// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_model.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

ContentBlock _$ContentBlockFromJson(Map<String, dynamic> json) => ContentBlock(
  _ackContentBlockFromRuntimeContent(json['content']),
  align: _ackContentBlockFromRuntimeAlign(json['align']),
  flex: _ackContentBlockFromRuntimeFlex(json['flex']) ?? 1,
  margin: _ackContentBlockFromRuntimeMargin(json['margin']),
  padding: _ackContentBlockFromRuntimePadding(json['padding']),
  scrollable:
      _ackContentBlockFromRuntimeScrollable(json['scrollable']) ?? false,
);

Map<String, dynamic> _$ContentBlockToJson(ContentBlock instance) =>
    <String, dynamic>{
      'align': ?_ackContentBlockToRuntimeAlign(instance.align),
      'flex': _ackContentBlockToRuntimeFlex(instance.flex),
      'margin': ?_ackContentBlockToRuntimeMargin(instance.margin),
      'padding': ?_ackContentBlockToRuntimePadding(instance.padding),
      'scrollable': _ackContentBlockToRuntimeScrollable(instance.scrollable),
      'content': _ackContentBlockToRuntimeContent(instance.content),
    };

WidgetBlock _$WidgetBlockFromJson(Map<String, dynamic> json) => WidgetBlock(
  name: _ackWidgetBlockFromRuntimeName(json['name']),
  args: _ackWidgetBlockFromRuntimeArgs(json['args']),
  align: _ackWidgetBlockFromRuntimeAlign(json['align']),
  flex: _ackWidgetBlockFromRuntimeFlex(json['flex']) ?? 1,
  margin: _ackWidgetBlockFromRuntimeMargin(json['margin']),
  padding: _ackWidgetBlockFromRuntimePadding(json['padding']),
  scrollable: _ackWidgetBlockFromRuntimeScrollable(json['scrollable']) ?? false,
);

Map<String, dynamic> _$WidgetBlockToJson(WidgetBlock instance) =>
    <String, dynamic>{
      'align': ?_ackWidgetBlockToRuntimeAlign(instance.align),
      'flex': _ackWidgetBlockToRuntimeFlex(instance.flex),
      'margin': ?_ackWidgetBlockToRuntimeMargin(instance.margin),
      'padding': ?_ackWidgetBlockToRuntimePadding(instance.padding),
      'scrollable': _ackWidgetBlockToRuntimeScrollable(instance.scrollable),
      'args': _ackWidgetBlockToRuntimeArgs(instance.args),
      'name': _ackWidgetBlockToRuntimeName(instance.name),
    };

SectionBlock _$SectionBlockFromJson(Map<String, dynamic> json) => SectionBlock(
  _ackSectionBlockFromRuntimeBlocks(json['blocks']),
  align: _ackSectionBlockFromRuntimeAlign(json['align']),
  flex: _ackSectionBlockFromRuntimeFlex(json['flex']) ?? 1,
  spacing: _ackSectionBlockFromRuntimeSpacing(json['spacing']) ?? 0,
  type: _ackSectionBlockFromRuntimeType(json['type']) ?? 'section',
);

Map<String, dynamic> _$SectionBlockToJson(SectionBlock instance) =>
    <String, dynamic>{
      'blocks': _ackSectionBlockToRuntimeBlocks(instance.blocks),
      'align': ?_ackSectionBlockToRuntimeAlign(instance.align),
      'flex': _ackSectionBlockToRuntimeFlex(instance.flex),
      'spacing': _ackSectionBlockToRuntimeSpacing(instance.spacing),
      'type': _ackSectionBlockToRuntimeType(instance.type),
    };
