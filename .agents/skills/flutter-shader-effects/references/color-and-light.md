# Color and Light for Presentation Shaders

Cinematic color treatment and lighting for effects that live *behind slide content*. The constraint that shapes everything: white/light text must stay legible on top.

## The Contrast Budget

Presentation backgrounds must leave headroom for text. Enforce these limits in `main()`:

- Keep the background's **average luminance below ~0.25** and its brightest sustained regions below ~0.55. Momentary highlights (glints, edge light) can spike higher if they are small and moving.
- The existing intensity mix is the enforcement point — keep it:
  ```glsl
  float strength = clamp(uIntensity, 0.0, 1.5);
  color = mix(vec3(0.006, 0.009, 0.025), color, strength);
  ```
- Avoid large saturated mid-luminance fields (pure `vec3(0.5, 0.0, 0.5)`-style) — they fight text worse than either dark or bright areas.
- Test every effect with sample slide text on top before shipping it.

## Cosine Palettes (Inigo Quilez)

The most powerful color tool per instruction. One expression yields an entire coordinated palette indexed by a scalar `t`:

```glsl
vec3 palette(float t, vec3 base, vec3 amp, vec3 freq, vec3 phase) {
  return base + amp * cos(6.28318 * (freq * t + phase));
}
```

Curated presets that fit the demo's dark aesthetic:

```glsl
// Deep-space (nebula, cosmic): teal → magenta → indigo
palette(t, vec3(0.20, 0.15, 0.30), vec3(0.35, 0.25, 0.35),
           vec3(1.0, 1.0, 1.0),  vec3(0.60, 0.25, 0.75));
// Ember (fire, embers): near-black → deep red → orange → pale yellow
palette(t, vec3(0.28, 0.12, 0.06), vec3(0.45, 0.30, 0.15),
           vec3(1.0, 1.0, 1.0),  vec3(0.05, 0.15, 0.30));
// Iridescent (holographic): full-spectrum sheen — keep amplitude low
palette(t, vec3(0.50, 0.50, 0.50), vec3(0.18, 0.18, 0.18),
           vec3(1.0, 1.0, 1.0),  vec3(0.00, 0.33, 0.67));
```

Where the shared shader's `uColorA`/`uColorB` two-color scheme feels flat, drive a cosine palette with `t = density` or `t = warp byproduct` and use the two uniforms as `base`-tint multipliers to keep per-effect theming.

## Mixing Colors Without Mud

Linear `mix(colorA, colorB, t)` between saturated complements passes through gray ("mud"). Two cheap fixes:

```glsl
// 1. Square-mix: approximates linear-light blending, keeps midpoints vivid
vec3 mix2(vec3 a, vec3 b, float t) { return sqrt(mix(a * a, b * b, t)); }

// 2. Route through a third color: A → bridge → B
vec3 bridge = normalize(a + b + 0.15) * max(length(a), length(b));
```

Prefer palette-driven color over two-point mixing for any effect where color *is* the subject (plasma, holographic, ink).

## Value Structure Before Hue

Cinematic effects read through **luminance shape** first — squint-test the effect in grayscale. The pattern that works on dark slides:

1. Near-black base (`vec3(0.002–0.01)` with a slight blue/violet bias — pure black looks dead).
2. Mid-density body carrying the hue at low luminance.
3. Small bright accents (edges, cores, glints) carrying the highest luminance and lowest saturation — bright areas desaturate toward white in real light.

```glsl
// Desaturate toward white as luminance rises (filmic highlight rolloff)
float lum = dot(color, vec3(0.299, 0.587, 0.114));
color = mix(color, vec3(lum), smoothstep(0.5, 1.0, lum) * 0.4);
```

## Lighting Models for Density Fields

**Edge/silhouette light** (already used in smoke) — peaks where density transitions, i.e., exactly at visual edges:

```glsl
float edgeLight = 4.0 * density * (1.0 - density);   // parabola, max at d=0.5
color += keyColor * edgeLight * density * strength;
```

**Directional shading from the density gradient** — gives billows a lit side and shadow side (see physics reference for the offset-sample version):

```glsl
vec2 grad = vec2(
  densityAt(sp + vec2(e, 0.0)) - densityAt(sp - vec2(e, 0.0)),
  densityAt(sp + vec2(0.0, e)) - densityAt(sp - vec2(0.0, e)));
float lit = clamp(0.5 - dot(normalize(grad + 1e-5), lightDir) * 0.8, 0.0, 1.0);
```

**Rim/fresnel for shapes** — for SDF-based effects, brighten where the field grazes zero:

```glsl
float rim = 1.0 - smoothstep(0.0, 0.10, abs(sdf));
```

**Glow/bloom fake** — real bloom needs multi-pass; fake it by adding a wider, dimmer copy of any bright term:

```glsl
color += glowColor * (sharp * 0.8 + pow(sharp, 0.4) * 0.15);  // core + halo
```

## Tone Mapping

Additive effects (multiple light layers) overflow 1.0 and clip to flat white patches. Compress instead of clamping:

```glsl
// Reinhard — cheap, softens everything
color = color / (1.0 + color);
// ACES approximation — filmic contrast, keeps darks rich (preferred)
vec3 aces(vec3 x) {
  return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}
```

Apply tone mapping *before* the intensity mix and dithering. For dim effects that never approach 1.0, skip it — tone mapping dim content just gray-washes it.

## Aerial Perspective (Depth Cue)

In layered/volumetric effects, push deeper layers toward the background color and desaturate them — the atmosphere trick that makes 4 flat layers read as deep space:

```glsl
vec3 layerColor = mix(baseColor, atmosphereTint, (1.0 - depth) * 0.6);
```

Warm-near/cool-far is the classical cinematic depth grade: bias near layers toward `uColorA` (warm accent) and far layers toward desaturated `uColorB`.

## Filmic Finishing Pass

Order matters. Final composite pipeline for a polished effect:

```glsl
vec3 color = effect(p);                       // 1. scene, additive light stages
color = aces(color * exposure);               // 2. tone map (if bright/additive)
color *= 1.0 - smoothstep(0.55, 1.35, length(p)) * 0.35;   // 3. vignette
float lum = dot(color, vec3(0.299, 0.587, 0.114));          // 4. highlight desat
color = mix(color, vec3(lum), smoothstep(0.5, 1.0, lum) * 0.3);
color = mix(fallbackBase, color, clamp(uIntensity, 0.0, 1.5)); // 5. intensity
color += (hash21(FlutterFragCoord().xy) - 0.5) / 255.0;       // 6. dither, always last
fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
```

Optional grain for cinematic texture (stronger than dither, animated):

```glsl
color += (hash21(FlutterFragCoord().xy + fract(uTime) * 100.0) - 0.5) * 0.015;
```

Keep grain ≤ 0.02 amplitude — it must be felt, not seen.

## Per-Mood Recipes

**Subtle effects** (aurora, silk, mesh): luminance range 0.01–0.30, one hue family plus one accent, motion periods > 8s, no hard edges. The effect should be *discoverable*, not noticed immediately.

**Dramatic effects** (smoke, nebula, vortex): full value structure (deep shadow → lit body → hot accents), clear key-light direction, motion periods 2–6s, and one "hero" element the eye tracks (plume core, vortex center, ink front). Still respect the 0.55 sustained-luminance ceiling — drama comes from contrast and motion, not brightness.

## Premultiplied Alpha (Overlay Shaders)

Flutter expects premultiplied output. Opaque backgrounds (`alpha = 1.0`) are unaffected, but any translucent overlay effect must multiply:

```glsl
fragColor = vec4(color * alpha, alpha);   // NOT vec4(color, alpha)
```

Getting this wrong shows as bright fringes at soft edges.
