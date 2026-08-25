// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_workspace.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

DeckWorkspace _$DeckWorkspaceFromJson(Map<String, dynamic> json) =>
    DeckWorkspace(
      projectDir: _ackDeckWorkspaceFromRuntimeProjectDir(json['projectDir']),
      slidesPath: _ackDeckWorkspaceFromRuntimeSlidesPath(json['slidesPath']),
      outputDir: _ackDeckWorkspaceFromRuntimeOutputDir(json['outputDir']),
    );

Map<String, dynamic> _$DeckWorkspaceToJson(DeckWorkspace instance) =>
    <String, dynamic>{
      'projectDir': _ackDeckWorkspaceToRuntimeProjectDir(instance.projectDir),
      'slidesPath': _ackDeckWorkspaceToRuntimeSlidesPath(instance.slidesPath),
      'outputDir': _ackDeckWorkspaceToRuntimeOutputDir(instance.outputDir),
    };
