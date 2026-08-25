// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'outline_schema.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

DeckPlanSection _$DeckPlanSectionFromJson(Map<String, dynamic> json) =>
    DeckPlanSection(
      key: DeckPlanSection._ackFromRuntimeKey(json['key']),
      title: DeckPlanSection._ackFromRuntimeTitle(json['title']),
      purpose: DeckPlanSection._ackFromRuntimePurpose(json['purpose']),
      transition: DeckPlanSection._ackFromRuntimeTransition(json['transition']),
      slideKeys: DeckPlanSection._ackFromRuntimeSlideKeys(json['slideKeys']),
    );

Map<String, dynamic> _$DeckPlanSectionToJson(
  DeckPlanSection instance,
) => <String, dynamic>{
  'key': DeckPlanSection._ackToRuntimeKey(instance.key),
  'title': DeckPlanSection._ackToRuntimeTitle(instance.title),
  'purpose': DeckPlanSection._ackToRuntimePurpose(instance.purpose),
  'transition': DeckPlanSection._ackToRuntimeTransition(instance.transition),
  'slideKeys': DeckPlanSection._ackToRuntimeSlideKeys(instance.slideKeys),
};

DeckPlanElement _$DeckPlanElementFromJson(Map<String, dynamic> json) =>
    DeckPlanElement(
      type: DeckPlanElement._ackFromRuntimeType(json['type']),
      purpose: DeckPlanElement._ackFromRuntimePurpose(json['purpose']),
      source: DeckPlanElement._ackFromRuntimeSource(json['source']),
      generationPrompt: DeckPlanElement._ackFromRuntimeGenerationPrompt(
        json['generationPrompt'],
      ),
      widgetName: DeckPlanElement._ackFromRuntimeWidgetName(json['widgetName']),
    );

Map<String, dynamic> _$DeckPlanElementToJson(
  DeckPlanElement instance,
) => <String, dynamic>{
  'type': DeckPlanElement._ackToRuntimeType(instance.type),
  'purpose': DeckPlanElement._ackToRuntimePurpose(instance.purpose),
  'source': ?DeckPlanElement._ackToRuntimeSource(instance.source),
  'generationPrompt': ?DeckPlanElement._ackToRuntimeGenerationPrompt(
    instance.generationPrompt,
  ),
  'widgetName': ?DeckPlanElement._ackToRuntimeWidgetName(instance.widgetName),
};

DeckPlanSlide _$DeckPlanSlideFromJson(
  Map<String, dynamic> json,
) => DeckPlanSlide(
  key: DeckPlanSlide._ackFromRuntimeKey(json['key']),
  title: DeckPlanSlide._ackFromRuntimeTitle(json['title']),
  purpose: DeckPlanSlide._ackFromRuntimePurpose(json['purpose']),
  sectionKey: DeckPlanSlide._ackFromRuntimeSectionKey(json['sectionKey']),
  assertion: DeckPlanSlide._ackFromRuntimeAssertion(json['assertion']),
  contentUnits: DeckPlanSlide._ackFromRuntimeContentUnits(json['contentUnits']),
  narrativeRole: DeckPlanSlide._ackFromRuntimeNarrativeRole(
    json['narrativeRole'],
  ),
  contentBrief: DeckPlanSlide._ackFromRuntimeContentBrief(json['contentBrief']),
  continuity: DeckPlanSlide._ackFromRuntimeContinuity(json['continuity']),
  composition: DeckPlanSlide._ackFromRuntimeComposition(json['composition']),
  treatment: DeckPlanSlide._ackFromRuntimeTreatment(json['treatment']),
  density: DeckPlanSlide._ackFromRuntimeDensity(json['density']),
  elements: DeckPlanSlide._ackFromRuntimeElements(json['elements']),
);

Map<String, dynamic> _$DeckPlanSlideToJson(
  DeckPlanSlide instance,
) => <String, dynamic>{
  'key': DeckPlanSlide._ackToRuntimeKey(instance.key),
  'title': DeckPlanSlide._ackToRuntimeTitle(instance.title),
  'purpose': DeckPlanSlide._ackToRuntimePurpose(instance.purpose),
  'sectionKey': DeckPlanSlide._ackToRuntimeSectionKey(instance.sectionKey),
  'assertion': DeckPlanSlide._ackToRuntimeAssertion(instance.assertion),
  'contentUnits': DeckPlanSlide._ackToRuntimeContentUnits(
    instance.contentUnits,
  ),
  'narrativeRole': DeckPlanSlide._ackToRuntimeNarrativeRole(
    instance.narrativeRole,
  ),
  'contentBrief': DeckPlanSlide._ackToRuntimeContentBrief(
    instance.contentBrief,
  ),
  'continuity': DeckPlanSlide._ackToRuntimeContinuity(instance.continuity),
  'composition': DeckPlanSlide._ackToRuntimeComposition(instance.composition),
  'treatment': DeckPlanSlide._ackToRuntimeTreatment(instance.treatment),
  'density': DeckPlanSlide._ackToRuntimeDensity(instance.density),
  'elements': ?DeckPlanSlide._ackToRuntimeElements(instance.elements),
};

DeckPlan _$DeckPlanFromJson(Map<String, dynamic> json) => DeckPlan(
  topic: DeckPlan._ackFromRuntimeTopic(json['topic']),
  story: DeckPlan._ackFromRuntimeStory(json['story']),
  theme: DeckPlan._ackFromRuntimeTheme(json['theme']),
  sections: DeckPlan._ackFromRuntimeSections(json['sections']),
  slides: DeckPlan._ackFromRuntimeSlides(json['slides']),
);

Map<String, dynamic> _$DeckPlanToJson(DeckPlan instance) => <String, dynamic>{
  'topic': DeckPlan._ackToRuntimeTopic(instance.topic),
  'story': DeckPlan._ackToRuntimeStory(instance.story),
  'theme': DeckPlan._ackToRuntimeTheme(instance.theme),
  'sections': DeckPlan._ackToRuntimeSections(instance.sections),
  'slides': DeckPlan._ackToRuntimeSlides(instance.slides),
};
