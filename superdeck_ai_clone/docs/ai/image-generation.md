# Image Generation Guidance

## Service Contract

- Service: `ImageGeneratorService`
- Default model: `gemini-2.5-flash-image`
- Supported aspect ratios: `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `9:16`, `16:9`, `21:9`
- Output:
  - success: image bytes
  - failure: user-safe error message

## Prompting Guidelines

1. Use narrative descriptions, not keyword bags.
2. Be concrete about color, texture, lighting, mood, and composition.
3. Prefer artistic language ("soft diffused light", "layered transparency").
4. Keep prompts compatible with slide backgrounds:
   - abstract composition
   - clean visual hierarchy
   - no text, logos, or people

## Examples

- Better:
  - `Soft watercolor painting with flowing organic shapes and gentle color bleeding. Dreamy atmospheric quality with muted pastels.`
- Worse:
  - `watercolor, soft, pastel, dreamy`

## Typical Usage

```dart
final service = ImageGeneratorService(apiKey: apiKey);
final prompt = ImageGeneratorService.buildPrompt(stylePrompt);
final result = await service.generateImage(prompt);
if (result.success) {
  // use result.bytes
} else {
  // handle result.error
}
service.dispose();
```
