# GLSL Building Blocks

Core procedural toolkit for SuperDeck shaders. Everything here is portable across Skia (SkSL) and Impeller: constant loop bounds, no derivatives, no textures.

## Hash and Noise

The project standard (already in `shader_showcase.frag`):

```glsl
float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise21(vec2 p) {          // value noise, smoothed
  vec2 cell = floor(p);
  vec2 local = fract(p);
  local = local * local * (3.0 - 2.0 * local);
  float a = hash21(cell);
  float b = hash21(cell + vec2(1.0, 0.0));
  float c = hash21(cell + vec2(0.0, 1.0));
  float d = hash21(cell + vec2(1.0, 1.0));
  return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}
```

For 3D fields (volumetrics, evolving-over-time noise):

```glsl
float hash31(vec3 p) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise31(vec3 p) {
  vec3 cell = floor(p);
  vec3 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float n000 = hash31(cell);
  float n100 = hash31(cell + vec3(1, 0, 0));
  float n010 = hash31(cell + vec3(0, 1, 0));
  float n110 = hash31(cell + vec3(1, 1, 0));
  float n001 = hash31(cell + vec3(0, 0, 1));
  float n101 = hash31(cell + vec3(1, 0, 1));
  float n011 = hash31(cell + vec3(0, 1, 1));
  float n111 = hash31(cell + vec3(1, 1, 1));
  return mix(
    mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
    mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
    f.z);
}
```

Using `noise31(vec3(p * scale, uTime * rate))` makes a 2D pattern *evolve* instead of *scroll* — essential for smoke, nebula, and liquid effects. Scrolling 2D noise is the single biggest realism killer.

## FBM Variants

Standard FBM (in the shared shader) rotates the domain each octave to hide axis alignment:

```glsl
float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 5; i++) {
    value += amplitude * noise21(p);
    p = vec2(1.6 * p.x - 1.2 * p.y, 1.2 * p.x + 1.6 * p.y) + 13.1;
    amplitude *= 0.5;
  }
  return value;
}
```

**Ridged FBM** — sharp creases, good for lightning, canyon lines, energy filaments:

```glsl
float ridgedFbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 5; i++) {
    float n = 1.0 - abs(2.0 * noise21(p) - 1.0);  // ridge
    value += amplitude * n * n;
    p = vec2(1.6 * p.x - 1.2 * p.y, 1.2 * p.x + 1.6 * p.y) + 13.1;
    amplitude *= 0.5;
  }
  return value;
}
```

**Billowed FBM** — puffy cumulus look: replace the ridge line with `abs(2.0 * noise21(p) - 1.0)` (no inversion).

**Time-cascaded FBM** — real turbulence moves faster at small scales. Advance each octave's phase at increasing rate:

```glsl
float turbFbm(vec2 p, float t) {
  float value = 0.0;
  float amplitude = 0.5;
  float rate = 1.0;
  for (int i = 0; i < 5; i++) {
    value += amplitude * noise21(p + vec2(0.0, t * 0.15 * rate));
    p = vec2(1.6 * p.x - 1.2 * p.y, 1.2 * p.x + 1.6 * p.y) + 13.1;
    amplitude *= 0.5;
    rate *= 1.8;
  }
  return value;
}
```

## Domain Warping

The core technique behind smoke, nebula, silk, marble. Warp the *input coordinates* with noise before sampling the pattern (Inigo Quilez's `f(p + f(p))` construction):

```glsl
// Single warp: organic wobble
vec2 q = vec2(fbm(p + vec2(0.0, 0.0)), fbm(p + vec2(5.2, 1.3)));
float pattern = fbm(p + 1.2 * q);

// Double warp: fluid, marbled structure
vec2 r = vec2(fbm(p + 2.0 * q + vec2(1.7, 9.2)),
              fbm(p + 2.0 * q + vec2(8.3, 2.8)));
float pattern2 = fbm(p + 1.5 * r);
```

Rules of thumb:
- Warp strength 0.8–1.6 for fluids; above ~2.0 the structure dissolves into mush.
- Animate the warp offsets at *different* rates and directions — never one global scroll.
- `q` and `r` are free byproducts: use them for color variation and pseudo-lighting (see color reference).

## Curl Noise (Divergence-Free Flow)

For motion that swirls like a real fluid, compute the curl of a noise potential — flow follows iso-lines, never sinks or sources. Without derivatives, use finite differences:

```glsl
vec2 curl(vec2 p) {
  float e = 0.01;
  float dx = noise21(p + vec2(e, 0.0)) - noise21(p - vec2(e, 0.0));
  float dy = noise21(p + vec2(0.0, e)) - noise21(p - vec2(0.0, e));
  return vec2(dy, -dx) / (2.0 * e);   // perpendicular to gradient
}
```

Use it to advect a sampling point a few steps (constant loop) for streaky, vortical motion:

```glsl
vec2 sp = p;
for (int i = 0; i < 3; i++) {
  sp += curl(sp * 1.5 + uTime * 0.05) * 0.04;
}
float density = fbm(sp * 3.0);
```

Cost warning: each `curl` call is 4 noise evaluations. Budget accordingly (drop FBM octaves to 4 when combining).

## SDFs and Shape Fields

Signed distance functions give crisp, controllable shapes to combine with noise:

```glsl
float sdCircle(vec2 p, float r) { return length(p) - r; }
float sdBox(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}
// Smooth union — organic blob merging (metaballs)
float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}
```

Perturb an SDF boundary with FBM for organic silhouettes (the ink-bloom pattern):

```glsl
float d = sdCircle(p, 0.35) + (fbm(p * 4.0 + uTime * 0.05) - 0.5) * 0.2;
float shape = 1.0 - smoothstep(0.0, 0.08, d);
```

## Voronoi / Cellular

For crystalline, cell, stained-glass, and caustic-grid structures:

```glsl
vec2 voronoi(vec2 p) {           // returns (min distance, cell id-ish)
  vec2 cell = floor(p);
  float minDist = 8.0;
  float id = 0.0;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 offset = vec2(float(x), float(y));
      vec2 site = offset + vec2(
        hash21(cell + offset),
        hash21(cell + offset + 19.19));
      site += 0.4 * sin(uTime * 0.3 + 6.2831 * site);  // animate sites
      float d = length(site - fract(p));
      if (d < minDist) { minDist = d; id = hash21(cell + offset); }
    }
  }
  return vec2(minDist, id);
}
```

Edge lines: run a second pass keeping the two smallest distances and shade `d2 - d1` (thin where cells meet).

## Polar and Domain Tricks

```glsl
float radius = length(p);
float angle = atan(p.y, p.x);
// Spiral field (vortex effect uses this):
float spiral = sin(angle * 7.0 - radius * 28.0 + uTime * 1.8);
// Log-polar: self-similar infinite zoom
vec2 lp = vec2(log(max(radius, 1e-4)), angle);
// Kaleidoscope: fold angle into a wedge
float wedge = 6.2831 / 8.0;
angle = abs(mod(angle, wedge) - wedge * 0.5);
vec2 folded = vec2(cos(angle), sin(angle)) * radius;
```

Rotation helper (already in the shared shader): `rotate2d(p, angle)`.

## Anti-Aliasing Without Derivatives

`fwidth` is unavailable. Estimate pixel size from `uSize` and feather every hard edge through `smoothstep`:

```glsl
float px = 1.5 / uSize.y;                       // ~1.5 pixels in p-space
float line = 1.0 - smoothstep(0.0, px * 2.0, abs(d));   // crisp AA line
```

For frequency-dependent patterns (contour lines, rings), widen the feather proportionally to the pattern frequency: a ring field `sin(radius * 34.0)` needs feathering ~`px * 34.0` in field-space.

## Dithering (Mandatory for Dark Backgrounds)

8-bit displays band visibly in the 0.00–0.10 luminance range where presentation backgrounds live. Add sub-quantization noise as the *last* step before output:

```glsl
color += (hash21(FlutterFragCoord().xy) - 0.5) / 255.0;
fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
```

## Stars / Sparkle Points

```glsl
float stars = step(0.996, hash21(floor((p + 2.0) * 180.0)));
stars *= 0.6 + 0.4 * sin(uTime * 2.0 + hash21(floor(p * 90.0)) * 6.2831); // twinkle
```

The `+ 2.0` offset keeps `floor` away from the mirror seam at 0.
