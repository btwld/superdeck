/// All Gemini model API path strings.
///
/// Chat models displayed in selector: [gemini25Pro], [gemini25Flash],
/// [gemini25FlashLite], [gemini31FlashLite], [gemini3FlashPreview],
/// [gemini35Flash]
abstract final class GeminiModelNames {
  // -- Chat models (appear in GeminiModels enum / UI selector) --
  static const gemini25Pro = 'models/gemini-2.5-pro';
  static const gemini25Flash = 'models/gemini-2.5-flash';
  static const gemini25FlashLite = 'models/gemini-2.5-flash-lite';
  static const gemini31FlashLite = 'models/gemini-3.1-flash-lite';
  static const gemini3FlashPreview = 'models/gemini-3-flash-preview';
  static const gemini35Flash = 'models/gemini-3.5-flash';
}
