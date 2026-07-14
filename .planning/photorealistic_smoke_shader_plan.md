# Volumetric Smoke Shader Plan

> Add a new **Volumetric Smoke** option to the fullscreen shader showcase and
> prove its visual quality and frame cost before making it the demo default.

## Review verdict

**Refine and simplify.** The original plan chose the right core architecture—a
separate ray-marched shader program—but it overcomplicated selector dispatch,
carried uniforms the effect does not need, treated `FittedBox` as a guaranteed
resolution cap, and postponed the performance decision until after integration.

This revision keeps the standalone program and Beer–Lambert volume model, uses
the existing showcase widget as the host, appends one special-case enum value,
and moves profiling ahead of the default-slide cutover.

## Problem reframed

- Required outcome: add a selector option whose smoke reads as a lit 3D volume,
  not scrolling 2D noise, and show it fullscreen if it performs well enough.
- Hard constraints: Flutter runtime-effect GLSL, one procedural fragment pass,
  macOS/Impeller and Chrome/SkSL support, reduced-motion support, and no extra
  visible UI beyond the existing selector.
- External commitments: none. This is demo-only code and the user explicitly
  does not require backward compatibility.
- Success limit: “photorealistic” means the closest convincing cinematic smoke
  available within those constraints; it does not mean a full fluid simulation,
  temporal accumulation, multipass lighting, or sampled footage.

## Verified context

- `demo/shaders/shader_showcase.frag` contains twelve effects in one program.
  Its `smoke(vec2)` function has good plume width, sway, source fade, turbulence,
  and edge light, but no view-ray depth, transmittance, or self-shadowing.
- `demo/lib/src/widgets/shader_showcase.dart` owns the effect enum, selector,
  animation clock, reduced-motion gating, cached shared `FragmentShader`, and
  `_ShaderPainter`. The painter passes `ShaderEffect.index` to `uEffect`.
- `demo/test/shader_showcase_test.dart` pins the twelve enum values to the GLSL
  dispatch order. Appending a standalone thirteenth value preserves indices
  0–11; inserting it among shared effects would break the invariant.
- `demo/slides.md` already makes the showcase the first fullscreen slide, with
  `smoke` selected. `demo/pubspec.yaml` currently declares only the shared
  shader program.
- Flutter 3.44 documents `FragmentShader` as reusable and explicitly disposable.
  The new shader and the existing shared shader should both be disposed by the
  owning state.
- Flutter 3.44's RenderFittedBox paints its child through a transform layer.
  A smaller logical child can change shader coordinates, but this is not a
  render-to-texture stage and must not be treated as proof that fewer device
  fragments run. Performance must be measured at the real presentation size.

## Recommended design

Create `demo/shaders/volumetric_smoke.frag` as a second program, then let the
existing `ShaderShowcase` choose between its current `_ShaderPainter` and a new
private painter dedicated to Volumetric Smoke. Do not add a second Markdown
widget or renderer abstraction: there is one demonstrated consumer and one
exceptional effect.

Append Volumetric Smoke to `ShaderEffect.values`. Shared effects continue using
their existing enum indices; the new value is intercepted before `_ShaderPainter`
is built, so index 12 is never sent to `shader_showcase.frag`.

Keep the current Cinematic Smoke option as an inexpensive visual baseline. Make
Volumetric Smoke the first-slide default only after it passes the compile,
visual, and profile checkpoints below.

### Shader model

- Uniforms: `uSize` at slots 0–1, `uTime` at slot 2, and `uIntensity` at slot 3.
  Smoke colors, light direction, absorption, and exposure are fixed scene
  constants; no color or quality controls are needed.
- Camera and bounds: intersect each view ray with a bounded plume volume. Return
  the background immediately for rays that miss it, then distribute a constant
  sixteen steps between entry and exit for rays that hit.
- Density: use an analytic rising-plume envelope before noise work, then a
  four-octave 3D FBM density field. The domain must expand and accelerate with
  height, sway at large scale, and advect through at least two time scales so
  fine wisps evolve faster than large billows.
- Lighting: use one coarse two-octave density tap toward a fixed key light for
  occupied samples. Integrate view transmittance and light attenuation with
  Beer–Lambert exponentials; stop when transmittance falls below 0.03.
- Sampling finish: jitter the first ray step per pixel to hide slice bands,
  wrap local time with `mod(uTime, 120.0)`, apply ACES only after light
  accumulation, then vignette, highlight desaturation, intensity floor mix,
  and 1/255 dithering as the final color operation.
- Portability: constant loop bounds only; `FlutterFragCoord`; no derivatives,
  `%`, `switch`, dynamic array indexing, `while`, textures, or translucent
  output.

At the starting budget, occupied pixels perform at most sixteen samples ×
(four primary-noise octaves + two shadow-noise octaves) = 96 `noise31` calls,
with whole-ray and per-sample analytic rejection reducing typical cost.

## Work breakdown

- [ ] **1. Build the shader and painter as a selectable prototype** —
  `demo/shaders/volumetric_smoke.frag`,
  `demo/lib/src/widgets/shader_showcase.dart`, `demo/pubspec.yaml`
  - Add the shader with the four-slot uniform table and the bounded volume model
    above.
  - Add a cached program future, one state-owned shader instance, and a private
    Volumetric Smoke painter; reuse the existing animation controller and
    reduced-motion behavior.
  - Append Volumetric Smoke to `ShaderEffect` and special-case only that value
    in the canvas branch. Leave `_ShaderPainter` and the first twelve enum
    indices unchanged.
  - Dispose both state-owned `FragmentShader` instances in `dispose()` after
    they are no longer paintable.
  - Declare `shaders/volumetric_smoke.frag` under `flutter.shaders`.
  - Remove the showcase's 24 px outer `ClipRRect` so the already-fullscreen
    slide is genuinely edge-to-edge; keep the selector panel's rounded shape.

- [ ] **2. Lock the selector invariants with tests** —
  `demo/test/shader_showcase_test.dart`
  - Update the catalog expectations to thirteen total effects, six subtle and
    seven dramatic.
  - Assert that `ShaderEffect.values.take(12)` still matches the exact shared
    GLSL order and that Volumetric Smoke is the final standalone value.
  - Cover parsing/from-args for the new name, direct startup on the new effect,
    its shader-canvas key, navigation into and out of it, and the new
    previous-from-Aurora wrap destination.
  - Keep the existing arrow-control semantics assertions.

- Checkpoint: run analysis, the targeted widget tests, and macOS/web release
  builds. Do not change the first slide's default yet.

- [ ] **3. Pass the visual and performance gate** — `demo/`
  - Run the macOS app in profile mode at the actual presentation window size
    and device-pixel ratio. Ignore the first two warm-up seconds, then observe
    at least ten seconds on both Cinematic Smoke and Volumetric Smoke.
  - Target a steady-state p95 raster frame time at or below 16.7 ms and no
    recurring frames above 33.3 ms on the current target Mac.
  - Inspect Chrome visually and for recurring frame misses using the same
    ten-second loop.
  - Verify live motion and a frozen reduced-motion frame. The plume must show a
    consistent light direction, dense self-occluding cores, dissolving edges,
    at least three spatial detail scales, and silhouettes that split and merge
    without uniform scrolling or visible ray slices.
  - If the budget misses, tune in this order: strengthen analytic bounds and
    early-outs; reduce the shadow field from two octaves to one; reduce march
    steps from sixteen to fourteen, then twelve. Re-run the gate after each
    change.
  - If twelve steps plus one shadow octave still misses or visibly bands, stop
    and replace the ray marcher with a four-layer 2.5D volume. A `FittedBox`
    alone is not an accepted performance fix because it is not a true
    low-resolution render target.

- [ ] **4. Make the proven effect the fullscreen default** —
  `demo/slides.md`, generated `demo/.superdeck/*`
  - Change the first slide to `effect: volumetricSmoke`, retaining `speed: 0.8`
    and `intensity: 1.0` as the initial presentation tuning.
  - Regenerate committed deck output with
    `fvm dart run superdeck_cli:main build` from `demo/`; do not edit generated
    JSON by hand.
  - Reopen the macOS release app and confirm it starts on Volumetric Smoke with
    only the selector over the shader.

- [ ] **5. Run final cross-backend verification** — `demo/`
  - Re-run the full demo test suite and both release builds after final tuning
    and generated-deck changes.
  - Recheck a ten-second live loop on macOS/Impeller and Chrome/SkSL; shader
    compilation alone is not visual verification.

## Verification commands

```bash
cd demo
fvm flutter analyze
fvm flutter test test/shader_showcase_test.dart
fvm flutter test
fvm flutter build macos --release
fvm flutter build web --release
fvm flutter run -d macos --profile
fvm flutter run -d chrome --profile
fvm dart run superdeck_cli:main build
```

Run the SuperDeck build when Task 4 changes `slides.md`, then repeat analysis,
tests, and release builds so generated output is part of final verification.

## Acceptance criteria

- Volumetric Smoke is the thirteenth selector option; all twelve shared effects
  still dispatch correctly and the old Cinematic Smoke remains available.
- The first fullscreen slide opens on Volumetric Smoke only after the effect
  passes the profile gate.
- Both macOS/Impeller and Chrome/SkSL compile and display the effect correctly.
- Reduced motion freezes on an intentional frame; leaving the slide stops
  animation work through the existing `TickerMode` behavior.
- The effect meets the measured frame target or deliberately falls back to the
  specified 2.5D design. No unmeasured “resolution cap” is used as evidence.
- All created `FragmentShader` instances are reused while mounted and disposed
  with their owning state.

## Risks and stop conditions

- **Full-screen fragment cost:** the ray marcher may be too expensive at Retina
  resolution. Analytic ray/volume rejection is the primary mitigation; the
  measurable fallback is fewer samples, then 2.5D.
- **Synthetic-looking noise:** FBM can still look procedural. The ten-second
  motion review and frozen-frame review are release gates, not optional polish.
- **Dispatch regression:** the shared shader still depends on enum order. The
  standalone value must remain after the twelve shared values, pinned by test.
- **Resource lifetime:** reusable shaders hold native resources. Every created
  instance must have one owner and one `dispose()` call.
- **Stop condition:** do not make the effect the default if either backend fails,
  if the visual checklist fails, or if the current Mac misses the profile target
  after the defined tuning ladder. Use the 2.5D fallback instead.
