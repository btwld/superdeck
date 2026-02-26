/// Barrel file for AI generation services.
///
/// Provides centralized access to all AI-related services:
/// - [DeckGeneratorService] - Generates presentations from prompts
/// - [ImageGeneratorService] - Generates images using Gemini
/// - [ErrorClassifier] - Classifies AI errors for user messages
/// - Generation progress types for UI updates
library;

export 'deck_generator_service.dart';
export 'error_classifier.dart';
export 'generation_progress.dart';
export 'image_generator_service.dart';
export 'prompt_builder.dart';
export 'retry_policy.dart';
