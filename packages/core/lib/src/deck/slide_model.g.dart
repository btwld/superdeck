// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slide_model.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

Slide _$SlideFromJson(Map<String, dynamic> json) => Slide(
  key: _ackSlideFromRuntimeKey(json['key']),
  options: _ackSlideFromRuntimeOptions(json['options']),
  sections: _ackSlideFromRuntimeSections(json['sections']) ?? const [],
  comments: _ackSlideFromRuntimeComments(json['comments']) ?? const [],
);

Map<String, dynamic> _$SlideToJson(Slide instance) => <String, dynamic>{
  'key': _ackSlideToRuntimeKey(instance.key),
  'options': ?_ackSlideToRuntimeOptions(instance.options),
  'sections': _ackSlideToRuntimeSections(instance.sections),
  'comments': _ackSlideToRuntimeComments(instance.comments),
};

SlideOptions _$SlideOptionsFromJson(Map<String, dynamic> json) => SlideOptions(
  title: _ackSlideOptionsFromRuntimeTitle(json['title']),
  style: _ackSlideOptionsFromRuntimeStyle(json['style']),
  layout: _ackSlideOptionsFromRuntimeLayout(json['layout']),
  template: _ackSlideOptionsFromRuntimeTemplate(json['template']),
  args: _ackSlideOptionsFromRuntimeArgs(json['args']) ?? const {},
);

Map<String, dynamic> _$SlideOptionsToJson(SlideOptions instance) =>
    <String, dynamic>{
      'title': ?_ackSlideOptionsToRuntimeTitle(instance.title),
      'style': ?_ackSlideOptionsToRuntimeStyle(instance.style),
      'layout': ?_ackSlideOptionsToRuntimeLayout(instance.layout),
      'template': ?_ackSlideOptionsToRuntimeTemplate(instance.template),
      'args': _ackSlideOptionsToRuntimeArgs(instance.args),
    };
