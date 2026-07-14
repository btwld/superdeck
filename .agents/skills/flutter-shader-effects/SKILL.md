---
name: flutter-shader-effects
description: This skill should be used when the user asks to "create a shader", "add a shader effect", "make a shader more realistic or dramatic", "improve shader physics", "add a new background effect", "make smoke/fire/water/ink/nebula shaders", "tune shader colors", or mentions GLSL, fragment shaders, FragmentProgram, uniforms, FBM, domain warping, ray marching, volumetrics, or the shader showcase. Provides advanced GLSL authoring (noise, physics-based motion, volumetric lighting, cinematic color) plus the SuperDeck demo integration workflow.
version: 0.1.0
---

# Flutter Shader Effects

Author advanced, presentation-quality fragment shaders for the SuperDeck demo: procedural backgrounds and effects with believable physics, volumetric depth, and cinematic color, integrated as `@`-block widgets in `slides.md`.

## Where Things Live

| File | Role |
|---|---|
| `demo/shaders/shader_showcase.frag` | Multi-effect GLSL program (one function per effect, `uEffect` dispatch) |
| `demo/lib/src/widgets/shader_showcase.dart` | `ShaderEffect` enum + `ShaderShowcase` widget + `_ShaderPainter` |
| `demo/lib/src/widgets/demo_widgets.dart` | `@`-block registry (`'shader-showcase': ShaderShowcase.fromArgs`) |
| `demo/pubspec.yaml` | `flutter: shaders:` asset declarations |
| `demo/slides.md` | Presentation usage (`@shader-showcase { effect: smoke ... }`) |
| `demo/test/shader_showcase_test.dart` | Widget tests |

## Two Integration Paths

**Path A — add a variant to the shared shader** (default for effects of comparable cost):
1. Add a value to `ShaderEffect` in `shader_showcase.dart` with label, `ShaderMood`, description, and two theme colors.
2. Add a `vec3 effectName(vec2 p)` function in `shader_showcase.frag`.
3. Add the dispatch branch in `main()`. **Invariant: branch order must match `ShaderEffect` enum order** — the Dart side passes `effect.index` as `uEffect`. Verify both lists line up after any insertion.
4. Update `slides.md` if the effect should be demoed, then run verification.

Design decision (keep): one shared program means one compile and instant effect switching. Uniform branches (`uEffect` is the same for all pixels) cost almost nothing on GPU.

**Path B — standalone shader file** (for effects needing a much larger instruction budget, extra uniforms, or ray marching):
1. Create `demo/shaders/<name>.frag` from `examples/effect_template.frag`.
2. Declare it under `flutter: shaders:` in `demo/pubspec.yaml`.
3. Create a widget from `examples/standalone_shader_widget.dart`, register it in `demoWidgets` with a `fromArgs` factory.
4. Add a mirrored test under `demo/test/`.

Design decision (keep): the demo stays dependency-free — no `flutter_shaders` package. Cached `FragmentProgram` + `CustomPainter` covers every current need.

## Flutter GLSL Constraints (Non-Negotiable)

- Start every shader with `#version 460 core` and `#include <flutter/runtime_effect.glsl>`; read coordinates via `FlutterFragCoord()`, never `gl_FragCoord`.
- **No derivatives**: `fwidth`, `dFdx`, `dFdy` are unavailable. Anti-alias with `smoothstep` scaled by a manual pixel size: `float px = 1.5 / uSize.y;`.
- **Constant loop bounds only.** Dynamic bounds fail on the SkSL (web) backend. Ray-march with `for (int i = 0; i < 24; i++)` and `break`/early-out inside.
- Use `mod()`, never integer `%`. Avoid `switch`, arrays of non-constant index, and `while` loops for SkSL portability.
- **Premultiplied alpha**: Flutter expects `fragColor` premultiplied. For opaque output (`alpha = 1.0`) this is moot; for translucent overlays multiply rgb by alpha before writing.
- No vertex stage, no multi-pass, no feedback buffers. Textures are possible via `setImageSampler`, but current effects are fully procedural — keep it that way unless sampling is essential.
- `uTime` grows to ~3600s before the controller wraps. Keep `uTime * frequency` products modest in high-frequency terms, or `mod()` time locally, to avoid float-precision shimmer.

## Uniform Convention

Slots are assigned by declaration order; each float consumes one index (`vec2` = 2, `vec3` = 3). Current layout — extend, never reorder:

```glsl
uniform vec2  uSize;      // setFloat 0, 1
uniform float uTime;      // setFloat 2   (seconds × speed)
uniform float uEffect;    // setFloat 3   (ShaderEffect.index)
uniform float uIntensity; // setFloat 4   (0.0–1.5)
uniform vec3  uColorA;    // setFloat 5, 6, 7
uniform vec3  uColorB;    // setFloat 8, 9, 10
```

When adding uniforms in a standalone shader, write the slot table as a comment block in both the `.frag` and the painter, and set static uniforms once in the painter constructor, per-frame uniforms in `paint()` (see `_ShaderPainter`).

## Standard Coordinate Frame

```glsl
vec2 p = FlutterFragCoord().xy / uSize - 0.5;  // centered
p.x *= uSize.x / uSize.y;                       // aspect-corrected
```

All effect functions receive this frame. Y grows downward — "rising" motion means `p.y + uTime * rate` in the sampling domain.

## Performance Rules

- Cost = pixels × instructions. FBM octave count and march step count are the budget knobs. Baseline: 5-octave FBM, 2 domain warps ≈ current smoke effect. Ray marching: ≤ 24 main steps, ≤ 4 FBM octaves per density sample, one shadow tap per step (not a second march), and always behind a density early-out.
- Keep the widget's existing structure: cached static `FragmentProgram.fromAsset` future, one reused `FragmentShader`, `CustomPainter` with `super(repaint: animation)` (no `setState` per tick), double `RepaintBoundary`.
- Respect reduced motion: `MediaQuery.disableAnimations` and `TickerMode` already gate the controller — an idle shader must still render a good static frame at `uTime` frozen.
- For very expensive effects, cap resolution: paint into a fixed-size `SizedBox` inside a `FittedBox` so the GPU fills fewer pixels and scaling smooths the result.
- Always dither dark gradients: `color += (hash21(FlutterFragCoord().xy) - 0.5) / 255.0;` before output — banding is the #1 giveaway of a cheap shader on projector-dark backgrounds.

## Quality Bar for Presentation Backgrounds

An effect earns its place when it has: motion that reads as physical (advection, buoyancy, turbulence — not pattern-scrolling), at least three spatial scales of detail, lighting (edges, cores, or directional shading — not flat density), and a color treatment that survives white text on top. Derive each from the references below; do not ship "scrolling cloudy noise."

## Verification Workflow

Run from `demo/` after every shader change:

```bash
fvm flutter analyze                          # static analysis
fvm flutter test                             # includes shader_showcase_test.dart
fvm flutter build macos --release            # compiles shaders for Impeller
```

Shader compile errors surface at build/test time with GLSL line numbers. For visual verification, build and open the macOS app, or run on Chrome to check the Skia/SkSL backend — an effect must be checked on **both** backends before calling it done.

## Additional Resources

### Reference Files

- **`references/glsl-techniques.md`** — noise/FBM variants, domain warping, curl noise, SDFs, Voronoi, polar tricks, anti-aliasing and dithering without derivatives.
- **`references/physics-and-volumetrics.md`** — advection, buoyancy and plume shaping, turbulence cascades, vortex dynamics, layered 2.5D volumetrics, ray-marched density with self-shadowing, interactive disturbance.
- **`references/color-and-light.md`** — cosine palettes, perceptual color mixing, tone mapping, edge/rim lighting, gradient-based shading, filmic finishing, text-legibility contrast budget.

### Example Files

- **`examples/effect_template.frag`** — standalone shader skeleton with standard header, helpers, and coordinate frame.
- **`examples/standalone_shader_widget.dart`** — widget + painter template mirroring `ShaderShowcase` conventions.
