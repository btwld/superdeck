# Physics-Based Motion and Volumetrics

How to make effects *move like matter* instead of scrolling patterns, and how to fake volume convincingly in a single fragment pass.

## The Cardinal Rule: Advect the Domain, Not the Pattern

Translating a finished pattern (`fbm(p)` then shifting the result) reads as a printed texture on a conveyor belt. Physical motion moves the **sampling coordinates** through a velocity field before pattern evaluation:

```glsl
vec2 velocity = vec2(drift, -riseSpeed);          // y-down: negative = rising
vec2 sp = p + velocity * uTime;                    // bulk advection
sp += vec2(fbm(sp + t1) - 0.5, fbm(sp + t2) - 0.5) * warp;  // turbulent advection
float density = fbm(sp * detailScale);
```

Layer at least three motion frequencies with different directions and rates. Uniform motion in one direction at one speed is the second-biggest realism killer (after 2D scrolling noise).

## Plume Physics (Smoke, Fire, Steam)

A believable rising plume encodes real buoyancy behavior:

1. **Acceleration with height** — hot gas rises faster as it entrains: scale vertical sampling rate by height, `sp.y += uTime * (base + height * gain)`.
2. **Expansion with height** — the column widens as it rises: `width = w0 + height * spread` (the existing smoke uses `0.045 + height * 0.23`).
3. **Sway** — large-scale sinuous instability, lower frequency near the source: `sway = sin(height * 4.2 - t * 0.7) * 0.075 + sin(height * 9.0 + t * 0.4) * 0.025`.
4. **Source fade** — density is emitted at the base and dissipates upward; multiply by a smoothstep band at the source and let turbulence eat the top.
5. **Detail speeds up as it shrinks** — use time-cascaded FBM (see glsl-techniques) so wisps flicker faster than the bulk billows. This single change adds more life than any other.
6. **Split and merge silhouettes** — threshold the density with `smoothstep(lo, hi, d)` where `lo/hi` are themselves modulated by a slow noise, so the outline continuously breaks apart and reconnects.

Fire is the same skeleton with: faster rise, ridged FBM for licking tongues, density remapped through a sharp curve (`pow(d, 3.0)`), and a black-body-ish gradient (deep red → orange → yellow → white toward the core).

## Vortex and Swirl Dynamics

Angular velocity in a real vortex falls off with radius (a Rankine-like profile). Encode it by rotating the sampling domain by a radius-dependent angle:

```glsl
float swirl = strength / (0.2 + radius * radius);   // fast core, slow rim
vec2 sp = rotate2d(p, swirl + uTime * 0.3);
```

Add curl-noise advection (glsl-techniques) on top for secondary eddies. For "ink dropped in water," combine a radial expansion `radius - uTime * bloomRate` with curl advection so tendrils curl back on themselves as they spread.

## Waves and Interference

Physical waves disperse: frequency and speed are linked, amplitude decays with distance.

```glsl
float wave(vec2 p, vec2 source, float freq, float t) {
  float d = length(p - source);
  float amplitude = exp(-d * 2.2);                 // radial decay
  float envelope = smoothstep(0.0, 0.25, t * 0.4 - d);  // finite propagation front
  return sin(d * freq - t * 3.0) * amplitude * envelope;
}
```

Sum 2–4 sources with different frequencies for interference. The propagation-front envelope (waves that visibly *start* somewhere) reads far more physical than infinite standing rings.

## Layered 2.5D Volumetrics (the workhorse)

Full ray marching is rarely needed. Sampling the same density field at 3–5 depth offsets with parallax, opacity, and per-layer lighting delivers most of the volume illusion at a fraction of the cost:

```glsl
vec3 color = backgroundColor;
for (int i = 0; i < 4; i++) {
  float layer = float(i);
  float depth = 1.0 - layer * 0.22;                 // 1.0 = nearest
  vec2 sp = p * (1.0 + layer * 0.35);               // deeper = smaller (parallax)
  sp += vec2(layer * 7.31, layer * 3.77);           // decorrelate layers
  float d = plumeDensity(sp, uTime * (0.8 + layer * 0.15));
  float a = d * depth * 0.55;                        // nearer layers more opaque
  vec3 layerColor = mix(shadowColor, litColor, d * depth + edgeLight(d));
  color = mix(color, layerColor, a);                 // back-to-front composite
}
```

Key details:
- **Decorrelate** each layer (offset + scale + speed) or they read as one flat sheet.
- Nearer layers: larger features, faster motion, higher contrast. Deeper layers: dimmer, bluer/desaturated (aerial perspective).
- Composite back-to-front with `mix` — this is alpha-over, the same math as ray-march accumulation.

## Ray-Marched Volume (when it must be real)

For a hero effect (dense volumetric smoke, god rays), march a 3D FBM density field. Keep bounds constant and small; early-out aggressively:

```glsl
float density3(vec3 q) {
  float d = 0.0, a = 0.5;
  for (int i = 0; i < 4; i++) {                     // 4 octaves max in a march
    d += a * noise31(q);
    q = q * 2.03 + vec3(1.7, 9.2, 3.1);
    a *= 0.5;
  }
  return d;
}

vec3 rayDir = normalize(vec3(p, 1.4));
vec3 lightDir = normalize(vec3(-0.6, -0.4, 0.3));
vec3 pos = vec3(0.0, 0.0, -1.5);
vec3 color = vec3(0.0);
float transmittance = 1.0;
for (int i = 0; i < 20; i++) {                       // constant bound
  pos += rayDir * 0.16;
  float d = density3(pos * 1.8 + vec3(0.0, uTime * 0.2, 0.0)) - 0.42;
  if (d <= 0.0) continue;
  // 2-tap self-shadow toward the light
  float shadow = density3(pos * 1.8 + lightDir * 0.35) - 0.42;
  float lit = exp(-max(shadow, 0.0) * 4.0);          // Beer–Lambert
  vec3 sample_ = mix(shadowTint, lightTint, lit) * d;
  color += sample_ * transmittance * 0.5;
  transmittance *= exp(-d * 1.4);                     // absorption
  if (transmittance < 0.02) break;                    // early out
}
```

Cost math before committing: `20 steps × (4 + 4) noise = 160 noise calls/pixel`. That is ~8× the current smoke effect (4 five-octave FBM calls = 20 noise calls). Only use full-screen with a resolution cap (`FittedBox` trick in SKILL.md), or confine the march to a masked region.

**Beer–Lambert** (`exp(-density * absorption)`) is the one law to keep exact — both for transmittance along the view ray and for the light tap. It is what makes cores read dense and edges read airy.

## Self-Shadowing Without a March

For 2D/2.5D effects, fake the light tap: sample density once more, offset *toward* the light, and darken where the offset sample is denser:

```glsl
vec2 lightDir = normalize(vec2(-0.7, -0.5));         // upper-left key light
float dHere = plumeDensity(sp, t);
float dToward = plumeDensity(sp + lightDir * 0.06, t);
float shading = clamp(0.5 + (dHere - dToward) * 2.5, 0.0, 1.0);  // lit vs shadowed side
vec3 bodyColor = mix(shadowColor, litColor, shading);
```

This gives directional form — billows have a bright side and a dark side — for one extra density evaluation. Combine with the edge glow `4.0 * d * (1.0 - d)` (peaks at half density, i.e., at silhouette edges) already used in the smoke effect.

## Springs and Damping (Dart side)

Interactive parameters (pointer influence, intensity changes) must not snap. Integrate a damped spring in the widget per frame and pass the smoothed value as a uniform:

```dart
// In the painter's tick or a listener: critically damped spring
velocity += (target - value) * stiffness * dt;
velocity *= math.exp(-damping * dt);
value += velocity * dt;
```

Rough starting point: `stiffness = 120`, `damping = 14`. Pass `value`, never `target`, to the shader.

## Pointer Disturbance

Feed pointer position and velocity as uniforms (`uPointer`, `uPointerVel`); inject a local impulse into the advection field:

```glsl
vec2 toPointer = p - uPointer;
float influence = exp(-dot(toPointer, toPointer) * 30.0);
sp += uPointerVel * influence * 0.15;                 // push density along pointer motion
```

Decay the Dart-side velocity uniform with the spring above so disturbances relax naturally after the pointer stops.

## Physical-Realism Checklist

Before calling a "physics" effect done, verify:
- [ ] Nothing scrolls uniformly; the domain is advected through ≥ 2 velocity scales.
- [ ] Small details move faster than large ones (time cascade).
- [ ] Density has cores and dissipating edges, not uniform opacity.
- [ ] There is a light direction — a viewer can point to where the light comes from.
- [ ] Silhouettes split and merge over a 10-second watch.
- [ ] The effect still looks intentional as a *frozen frame* (reduced-motion users see this).
