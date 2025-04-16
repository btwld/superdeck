# Generation Tasks

This directory contains tasks that generate external assets or files from slide content.

## Available Tasks

### MermaidConverterTask

Generates PNG images from Mermaid diagram code blocks.

```dart
MermaidConverterTask({
  required BrowserService browserService,
  required AssetStorage assetStorage,
  Map<String, dynamic> configuration = const {},
})
```

**Configuration Options:**
- `theme`: Mermaid theme name (default: 'base')
- `themeVariables`: Theme variables to customize appearance
- `viewportWidth`: Width for rendered diagram (default: 1280)
- `viewportHeight`: Height for rendered diagram (default: 780)
- `deviceScaleFactor`: Scale factor for rendering (default: 2)
- `timeout`: Timeout in seconds for rendering (default: 5)
- `cacheInvalidationMinutes`: Cache invalidation time in minutes (default: 60)

**Behavior:**
1. Identifies code blocks with `mermaid` language identifier
2. Renders each diagram to SVG using Puppeteer
3. Converts SVG to PNG image
4. Saves the image as an asset
5. Replaces the code block with a reference to the generated image
6. Cleans up unused assets on completion

This task cannot run in parallel with other tasks due to its use of Puppeteer.

## Creating New Generation Tasks

When creating new generation tasks:

1. Focus on generating external assets
2. Consider caching and invalidation strategies
3. Implement cleanup logic to remove stale assets
4. Document all configuration options clearly
5. Consider resource usage (memory, CPU) during generation 