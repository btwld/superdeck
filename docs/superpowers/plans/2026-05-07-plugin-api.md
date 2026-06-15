# SuperDeck Plugin API Plan

> **Purpose:** Define the plugin API and integration model before implementation. This document focuses on what the API does, how plugins hook into SuperDeck, and how PDF/Mermaid should use it. It intentionally avoids task-level implementation details.

## Goal

SuperDeck should support optional packages that add behavior without making every SuperDeck app depend on PDF export, Puppeteer, Mermaid, or future extension packages.

The extension model should stay small:

- Runtime deck actions for shell commands.
- Build plugins for compile-time transforms.
- No plugin auto-discovery.
- No plugin widget-factory registration in the first version.
- Apps opt in explicitly at the hook point that can use the extension.

## Core Decision

Use two explicit hook points instead of a shared plugin family. PDF and Mermaid
run in different environments, so sharing a base type adds dependency and naming
weight without giving callers a useful API.

```dart
final class DeckAction {
  final String id;
  final IconData icon;
  final String label;
  final FutureOr<void> Function(BuildContext context, DeckController deck)
      onPressed;
}

final class DeckBuildPlugin {
  final String id;
  // Build-time transform hooks.
}
```

This keeps the API honest: runtime packages contribute actions, and build-time
packages contribute build plugins.

For example:

```dart
List<DeckAction> pdfActions() => [pdfExportAction()];
```

And:

```dart
DeckBuildPlugin mermaidBuildPlugin() {
  return DeckBuildPlugin(
    id: 'superdeck.mermaid',
    transformContentBlock: mermaidTransform,
  );
}
```

## Why Two Plugin Types

PDF and Mermaid hook into different parts of SuperDeck.

PDF is runtime behavior:

- It needs Flutter.
- It needs a button/action in the SuperDeck shell.
- It opens a dialog, screen, or widget flow.
- It uses the current deck controller and rendered slides.

Mermaid is build-time behavior:

- It scans markdown content.
- It finds fenced `mermaid` code blocks.
- It renders generated images.
- It rewrites the compiled deck before Flutter loads it.
- It must keep Puppeteer out of the Flutter runtime dependency path.

A single generic hook would either be too vague or would couple runtime and build-time dependencies. The sealed union gives us one plugin vocabulary while keeping the two execution environments separate.

## Runtime Deck Actions

Runtime actions are passed to `SuperDeckApp`.

```dart
SuperDeckApp(
  options: DeckOptions(),
  actions: [
    ...pdfActions(),
  ],
);
```

`SuperDeckApp` should accept runtime actions only:

```dart
class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({
    required this.options,
    this.actions = const <DeckAction>[],
  });
}
```

This avoids passing build-time plugins into Flutter runtime by accident and
keeps PDF as a command contribution rather than a broad runtime plugin system.

### Action Plugin Shape

Conceptually, an action is a command shown by the SuperDeck shell:

```dart
final class DeckAction {
  const DeckAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String id;
  final IconData icon;
  final String label;
  final FutureOr<void> Function(BuildContext context, DeckController deck)
      onPressed;
}
```

The callback receives:

- `BuildContext`, so it can open a widget, dialog, sheet, or route.
- `DeckController`, so it can read slides and presentation state.

This is enough for a plugin to open any UI it owns:

```dart
DeckAction(
  id: 'superdeck.pdf.export',
  icon: Icons.picture_as_pdf,
  label: 'Export PDF',
  onPressed: (context, deck) {
    PdfExportDialogScreen.show(context);
  },
);
```

### Screens And Widgets

Do not add a separate screen plugin yet.

An action can open a screen or widget directly:

- `showDialog`
- `showModalBottomSheet`
- `Navigator.of(context).push(...)`
- `deck.presentation.router.push(...)` if SuperDeck later exposes route support

This keeps the API flexible without adding route registration before we need it.

If route registration becomes necessary later, add a third sealed type:

```dart
final class DeckRouteExtension {
  final List<DeckRoute> routes;
}
```

Do not add this in the first version.

### Where Actions Render

Initial hook: `DeckBottomBar`.

The bottom bar already owns presentation controls like notes, thumbnails, navigation, page counter, and close. Plugin actions should render in the existing control strip, near utility controls.

Recommended placement:

1. notes toggle
2. regenerate thumbnails
3. plugin actions
4. previous/next
5. page counter
6. close

This gives PDF a natural button without inventing a separate toolbar.

## No Widget Factory Plugin Hook

Do not include widget factory registration in the action or build plugin APIs.

Reason:

- `DeckOptions.widgets` already handles slide widget registration.
- Slide widgets are authoring/runtime content, not plugin shell behavior.
- Mixing widget factories into plugins would blur two concepts:
  - slide content widgets
  - deck extension behavior

Apps should keep doing this for slide widgets:

```dart
SuperDeckApp(
  options: DeckOptions(
    widgets: {
      'chart': (args) => MyChart(args),
    },
  ),
);
```

Plugins should only provide shell/build behavior in the first version.

If a future plugin package wants to ship reusable slide widgets, it can expose a plain widget map helper outside the plugin system:

```dart
DeckOptions(
  widgets: {
    ...chartWidgets(),
  },
);
```

That keeps widget registration explicit and separate.

## PDF Plugin API

PDF should contribute runtime deck actions.

Target usage:

```dart
SuperDeckApp(
  options: DeckOptions(),
  actions: [
    ...pdfActions(),
  ],
);
```

With custom save behavior:

```dart
SuperDeckApp(
  options: DeckOptions(),
  actions: [
    ...pdfActions(
      pdfSaver: (bytes) async {
        return true;
      },
    ),
  ],
);
```

### PDF Exports

`superdeck_pdf` should expose:

- `pdfActions()`: returns `List<DeckAction>`.
- `pdfExportAction()`: returns `DeckAction`.
- Existing `PdfExportDialogScreen`.
- Existing `PdfController`.

The plugin contributes one action:

- action ID: `superdeck.pdf.export`
- label: `Export PDF`
- icon: `Icons.picture_as_pdf`
- behavior: open `PdfExportDialogScreen.show(context)`

### PDF Flow

1. App registers `pdfActions()` with `SuperDeckApp`.
2. SuperDeck shell reads registered `DeckAction`s.
3. Bottom bar renders the PDF action.
4. User taps Export PDF.
5. Action opens the PDF export dialog/screen.
6. PDF package owns the export UI and export controller.
7. PDF package captures slides and saves the PDF.

The action is only the hook and trigger. The PDF package keeps its internal controller and export flow.

## Build Plugins

Build plugins are passed to the builder/CLI layer.

Programmatic builder usage:

```dart
final builder = DeckBuilder(
  workspace: workspace,
  store: store,
  plugins: [
    mermaidBuildPlugin(),
  ],
);
```

CLI runner usage:

```dart
final runner = SuperDeckRunner(
  plugins: [
    mermaidBuildPlugin(),
  ],
);
```

The parameter can be called `plugins`, as long as the type is `List<DeckBuildPlugin>`. That gives a clean API without mixing runtime plugins into the build runner.

### Build Plugin Shape

Conceptually:

```dart
final class DeckBuildPlugin {
  const DeckBuildPlugin({
    required this.id,
    required this.transformContentBlock,
  });

  final FutureOr<ContentBlock> Function(
    ContentBlock block,
    DeckBuildContext context,
  ) transformContentBlock;
}
```

`DeckBuildContext` should include:

- `DeckWorkspace workspace`
- current slide key
- `sectionIndex`
- `blockIndex`

That gives a build plugin enough context to:

- write generated assets under `.superdeck/`
- build stable cache paths
- produce useful errors
- avoid global state

### Build Hook Point

Build plugins run after parsing and before saving.

Current flow:

1. Read `slides.md`.
2. Split raw markdown into slides.
3. Parse frontmatter.
4. Parse sections and blocks.
5. Save `superdeck.json`.

Plugin flow:

1. Read `slides.md`.
2. Split raw markdown into slides.
3. Parse frontmatter.
4. Parse sections and blocks.
5. Run build plugins over parsed content blocks.
6. Save `superdeck.json`.

This hook is clean because:

- slide splitting already respects fenced code blocks
- directive parsing already ignores tags inside fenced code blocks
- Mermaid can work on `ContentBlock.content`
- runtime rendering does not need Mermaid-specific logic

### Build Plugin Scope

The first build plugin hook should only transform `ContentBlock`s.

It should not initially:

- add slides
- delete slides
- reorder sections
- mutate deck options
- add runtime widgets
- add routes

Those are separate capabilities and should only be added when a real plugin needs them.

## Mermaid Build Plugin API

Mermaid should be a build plugin.

Target usage:

```dart
final runner = SuperDeckRunner(
  plugins: [
    mermaidBuildPlugin(),
  ],
);
```

Optional configuration:

```dart
final runner = SuperDeckRunner(
  plugins: [
    mermaidBuildPlugin(
      configuration: {
        'theme': 'base',
        'viewportWidth': 1280,
        'viewportHeight': 780,
      },
    ),
  ],
);
```

### Mermaid Responsibilities

The plugin scans `ContentBlock.content` for fenced code blocks whose first info-string token is `mermaid`:

````markdown
```mermaid
graph TD
  A --> B
```
````

It renders each diagram to PNG and replaces the fenced block with normal image markdown:

```markdown
![Mermaid diagram](.superdeck/mermaid/mermaid_<hash>.png)
```

Runtime then uses the existing markdown image rendering path. No Mermaid runtime renderer is needed.

### Mermaid Caching

Cache key should include:

- Mermaid source
- resolved generator configuration

Generated file path:

```text
.superdeck/mermaid/mermaid_<hash>.png
```

Compiled markdown reference:

```text
.superdeck/mermaid/mermaid_<hash>.png
```

On rebuild:

- if the file exists and is non-empty, skip rendering
- if the source or config changes, hash changes and a new image is generated

### Mermaid Error Behavior

If Mermaid rendering fails, the build should fail.

That is better than silently rendering code or broken images because the author sees the problem during build, and SuperDeck already has build failure reporting through `build_status.json`.

The error should include:

- Mermaid/Puppeteer error message
- slide key
- section index
- block index

## CLI Registration

The default `superdeck` executable should not auto-discover plugins.

For build plugins, apps create a custom runner:

```dart
import 'dart:io';

import 'package:superdeck_cli/runner.dart';
import 'package:superdeck_mermaid/superdeck_mermaid.dart';

Future<void> main(List<String> args) async {
  final exitCode = await SuperDeckRunner(
    plugins: [
      mermaidBuildPlugin(),
    ],
  ).run(args);

  exit(exitCode);
}
```

Run it with:

```bash
dart run tool/superdeck.dart build --watch
```

This keeps dependencies explicit and avoids reflection, manifests, or hidden package loading.

## Package Layout

Melos must include nested plugin packages:

```yaml
packages:
  - packages/*
  - packages/plugins/*
  - demo
```

This makes `superdeck_pdf` and `superdeck_mermaid` part of normal bootstrap, analyze, and test workflows.

## API Summary

Runtime app:

```dart
SuperDeckApp(
  options: DeckOptions(),
  actions: [
    ...pdfActions(),
  ],
);
```

Build runner:

```dart
SuperDeckRunner(
  plugins: [
    mermaidBuildPlugin(),
  ],
);
```

PDF factory:

```dart
List<DeckAction> pdfActions({PdfSaver? pdfSaver});
```

Mermaid factory:

```dart
DeckBuildPlugin mermaidBuildPlugin({
  Map<String, Object?> configuration = const {},
  MermaidGenerator? generator,
});
```

## What This Does Not Add Yet

Do not add these in the first version:

- plugin auto-discovery
- plugin manifests
- slide widget registration through plugins
- route registration
- plugin dependency injection container
- runtime Markdown renderer plugins
- async runtime content transforms
- broad deck mutation hooks

These may be useful later, but PDF and Mermaid do not require them.

## Acceptance Criteria

- The extension API has two explicit hook points: runtime `DeckAction`s and build `DeckBuildPlugin`s.
- `SuperDeckApp` accepts runtime deck actions.
- `DeckBuilder` and `SuperDeckRunner` accept build plugins.
- PDF exposes `pdfActions()` and `pdfExportAction()`.
- PDF action appears in the existing bottom bar.
- Tapping the PDF action opens the existing PDF export dialog/screen.
- Mermaid exposes `mermaidBuildPlugin()` as a `DeckBuildPlugin`.
- Mermaid build plugin replaces fenced `mermaid` code blocks with generated image markdown.
- Mermaid images are generated under `.superdeck/mermaid/`.
- Mermaid rebuilds reuse cached image files for unchanged source/config.
- Plugin API does not include widget factory registration.
- Slide widget registration remains in `DeckOptions.widgets`.
- The default Flutter runtime does not depend on Puppeteer.
- `packages/plugins/pdf` and `packages/plugins/mermaid` are included in Melos commands.

## Review Summary

The API should be two small explicit hook points:

- `DeckAction` for runtime shell commands that can open dialogs, screens, or widgets.
- `DeckBuildPlugin` for build-time content transforms.
- `pdfActions()` returns deck actions.
- `mermaidBuildPlugin()` returns a build plugin.
- Slide widget registration stays out of the plugin API.

This gives PDF and Mermaid clear hook points without turning plugins into a broad framework.
