import 'package:flutter/material.dart';
import 'package:playground/features/ai/core/constants/gemini_models.dart';
import 'package:playground/features/ai/core/ui/ui.dart';

/// Chat models available for user selection in the UI.
///
/// Each value maps to a [GeminiModelNames] constant. Only chat-capable models
/// are included here; specialized models (e.g., image generation) are not
/// user-selectable and are used internally by services.
enum GeminiModels {
  gemini25Pro(GeminiModelNames.gemini25Pro),
  gemini25Flash(GeminiModelNames.gemini25Flash),
  gemini25FlashLite(GeminiModelNames.gemini25FlashLite),
  gemini3FlashPreview(GeminiModelNames.gemini3FlashPreview);

  const GeminiModels(this.modelPath);

  /// The API model path string (e.g., 'models/gemini-2.5-pro').
  final String modelPath;

  /// The default model for the app.
  static const defaultValue = GeminiModels.gemini3FlashPreview;

  String get formattedName => switch (this) {
    GeminiModels.gemini25Pro => 'Gemini 2.5 Pro',
    GeminiModels.gemini25Flash => 'Gemini 2.5 Flash',
    GeminiModels.gemini25FlashLite => 'Gemini 2.5 Lite',
    GeminiModels.gemini3FlashPreview => 'Gemini 3 Flash',
  };
}

/// Dropdown selector for choosing the Gemini model.
///
/// Displays available models with formatted names and allows selection.
/// Can be disabled during active conversations.
class ModelsSelect extends StatelessWidget {
  final GeminiModels selectedValue;
  final Function(GeminiModels) onChanged;
  final bool enabled;

  const ModelsSelect({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SdSelect<GeminiModels>(
      enabled: enabled,
      selectedValue: selectedValue,
      onChanged: (value) => onChanged(value!),
      placeholder: 'Select a model',
      icon: enabled ? null : Icons.lock_outline,
      items: GeminiModels.values
          .map((e) => SdSelectItem(label: e.formattedName, value: e))
          .toList(),
    );
  }
}
