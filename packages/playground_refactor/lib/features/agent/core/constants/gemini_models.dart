/// All Gemini model API path strings.
///
/// Contains both chat models (used in [GeminiModels] enum for UI selection)
/// and specialized models (e.g., image generation) for internal service use.
///
/// Chat models displayed in selector: [gemini25Pro], [gemini25Flash],
/// [gemini25FlashLite], [gemini3FlashPreview]
///
/// Specialized models (internal use only): [gemini31FlashImage],
/// [gemini3ProImage]
abstract final class GeminiModelNames {
  // -- Chat models (appear in GeminiModels enum / UI selector) --
  static const gemini25Pro = 'models/gemini-2.5-pro';
  static const gemini25Flash = 'models/gemini-2.5-flash';
  static const gemini25FlashLite = 'models/gemini-2.5-flash-lite';
  static const gemini3FlashPreview = 'models/gemini-3-flash-preview';

  // -- Specialized models (internal service use only) --
  static const gemini31FlashImage = 'gemini-3.1-flash-image';
  static const gemini3ProImage = 'gemini-3-pro-image';
}
