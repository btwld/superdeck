#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uEffect;
uniform float uIntensity;
uniform vec3 uColorA;
uniform vec3 uColorB;
out vec4 fragColor;

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise21(vec2 p) {
  vec2 cell = floor(p);
  vec2 local = fract(p);
  local = local * local * (3.0 - 2.0 * local);
  float a = hash21(cell);
  float b = hash21(cell + vec2(1.0, 0.0));
  float c = hash21(cell + vec2(0.0, 1.0));
  float d = hash21(cell + vec2(1.0, 1.0));
  return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

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

vec2 rotate2d(vec2 p, float angle) {
  float sine = sin(angle);
  float cosine = cos(angle);
  return vec2(cosine * p.x - sine * p.y, sine * p.x + cosine * p.y);
}

float softBlob(vec2 p, vec2 center, float radius) {
  vec2 delta = p - center;
  return exp(-dot(delta, delta) / (radius * radius));
}

// Ridged FBM — sharp creases for energy filaments (plasma).
float ridgedFbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 5; i++) {
    float ridge = 1.0 - abs(2.0 * noise21(p) - 1.0);
    value += amplitude * ridge * ridge;
    p = vec2(1.6 * p.x - 1.2 * p.y, 1.2 * p.x + 1.6 * p.y) + 13.1;
    amplitude *= 0.5;
  }
  return value;
}

// 3D value noise — lets a 2D pattern evolve over time instead of scroll (nebula).
float hash31(vec3 p) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise31(vec3 p) {
  vec3 cell = floor(p);
  vec3 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float n000 = hash31(cell);
  float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
  float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
  float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));
  float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
  float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
  float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
  float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));
  return mix(
    mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
    mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
    f.z
  );
}

float fbm3(vec3 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 4; i++) {
    value += amplitude * noise31(p);
    p = p * 2.03 + vec3(1.7, 9.2, 3.1);
    amplitude *= 0.5;
  }
  return value;
}

// ACES filmic tone map — compress additive light stages instead of clipping.
vec3 aces(vec3 x) {
  return clamp(
    (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14),
    0.0,
    1.0
  );
}

vec3 aurora(vec2 p) {
  vec3 color = mix(
    vec3(0.004, 0.008, 0.04),
    uColorB * 0.16,
    clamp(p.y + 0.55, 0.0, 1.0)
  );
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float wave = sin(
      p.x * (2.1 + fi * 0.4) +
      uTime * (0.22 + fi * 0.05) +
      fi * 2.2
    ) * (0.11 + fi * 0.025);
    float light = exp(-abs(p.y - wave + fi * 0.045) * (18.0 - fi * 3.0));
    color += mix(uColorA, uColorB, fi * 0.35) *
      light *
      (0.85 - fi * 0.16);
  }
  float starSeed = hash21(floor((p + 2.0) * 140.0));
  float stars = step(0.994, starSeed);
  float twinkle = 0.6 + 0.4 * sin(uTime * 2.0 + starSeed * 6.2831);
  return aces(color + stars * twinkle * 0.6);
}

vec3 silk(vec2 p) {
  vec2 q = rotate2d(p, -0.18) * vec2(2.2, 2.8);
  float phase = q.x * 2.25;
  phase += sin(q.y * 1.35 + uTime * 0.16) * 0.95;
  phase += sin(q.x * 1.4 - q.y * 0.55 - uTime * 0.10) * 0.32;
  float facing = 0.5 + 0.5 * cos(phase);
  float broadFold = 0.5 + 0.5 * cos(phase * 0.48 + q.y * 0.65);
  float highlight = pow(facing, 4.0);
  vec3 color = mix(vec3(0.008, 0.010, 0.03), uColorB * 0.30, broadFold);
  color += mix(uColorB, uColorA, facing) * (facing * 0.12 + highlight * 0.58);
  return color;
}

vec3 meshGradient(vec2 p) {
  float t = uTime * 0.12;
  vec2 a = vec2(-0.38 + sin(t) * 0.16, -0.22 + cos(t * 0.8) * 0.13);
  vec2 b = vec2(0.34 + cos(t * 0.7) * 0.18, 0.18 + sin(t * 1.1) * 0.16);
  vec2 c = vec2(sin(t * 0.45) * 0.24, 0.35 + cos(t * 0.6) * 0.12);
  float blobA = softBlob(p, a, 0.52);
  float blobB = softBlob(p, b, 0.58);
  float blobC = softBlob(p, c, 0.46);
  vec3 color = vec3(0.006, 0.008, 0.022);
  color += uColorA * blobA * 0.62;
  color += uColorB * blobB * 0.58;
  color += mix(uColorA, uColorB, 0.5) * blobC * 0.42;
  return color * (0.9 - length(p) * 0.16);
}

vec3 caustics(vec2 p) {
  float t = uTime * 0.32;
  vec2 q = p * 6.0;
  q += vec2(sin(q.y + t), cos(q.x - t * 0.8)) * 0.72;
  float field = sin(q.x + sin(q.y * 1.3 + t));
  field += sin(q.y * 1.7 + cos(q.x * 0.8 - t * 0.9));
  float light = pow(1.0 - abs(sin(field * 1.35)), 9.0);
  float depth = clamp(0.72 - p.y, 0.0, 1.0);
  vec3 color = mix(vec3(0.002, 0.025, 0.065), uColorB * 0.32, depth);
  return color + uColorA * light * (0.34 + depth * 0.38);
}

vec3 topography(vec2 p) {
  // Widen the contour feather at low resolution so lines soften instead of
  // aliasing (no derivatives available; px approximates 1.5px in p-space).
  float px = 1.5 / uSize.y;
  float height = fbm(p * 3.2 + vec2(uTime * 0.018, -uTime * 0.012));
  float fineDistance = abs(fract(height * 9.0) - 0.5);
  float majorDistance = abs(fract(height * 3.0) - 0.5);
  float fineFeather = max(0.04, px * 24.0);
  float majorFeather = max(0.025, px * 16.0);
  float fineLine = 1.0 - smoothstep(0.02, 0.02 + fineFeather, fineDistance);
  float majorLine = 1.0 - smoothstep(0.015, 0.015 + majorFeather, majorDistance);
  vec3 color = mix(vec3(0.004, 0.018, 0.022), uColorB * 0.12, height);
  color += mix(uColorB, uColorA, height) * (fineLine * 0.38 + majorLine * 0.48);
  return color;
}

vec3 holographic(vec2 p) {
  vec2 q = rotate2d(p, 0.28);
  float noise = fbm(q * 2.3 + vec2(uTime * 0.025, -uTime * 0.018));
  float phase = q.x * 1.15 - q.y * 0.48 + noise * 0.48 + uTime * 0.025;
  vec3 spectrum = 0.5 + 0.5 * cos(
    6.28318 * (phase + vec3(0.0, 0.33, 0.67))
  );
  float sheen = pow(0.5 + 0.5 * sin(phase * 2.7), 2.0);
  float glint = pow(max(0.0, cos(phase * 4.0 - q.y * 2.8)), 20.0);
  vec3 color = mix(
    vec3(0.018, 0.015, 0.05),
    mix(uColorA, uColorB, noise),
    0.20
  );
  return color + spectrum * (0.07 + sheen * 0.22) + glint * 0.14;
}

vec3 smoke(vec2 p) {
  float t = uTime * 0.16;
  float height = clamp(0.52 - p.y, 0.0, 1.15);
  float sway = sin(height * 4.2 - t * 0.7) * 0.075;
  sway += sin(height * 9.0 + t * 0.4) * 0.025;
  float width = 0.045 + height * 0.23;
  float sourceFade = 1.0 - smoothstep(0.38, 0.58, p.y);

  vec2 samplePoint = vec2(p.x * 2.4, (p.y + t * 0.24) * 1.7);
  float warpA = fbm(samplePoint * 1.10 + vec2(0.0, t * 0.10));
  float warpB = fbm(samplePoint * 1.35 + vec2(4.7, -t * 0.08));
  float edgeNoise = (warpA - 0.5) * 0.13 + (warpB - 0.5) * 0.08;
  float plume = 1.0 - smoothstep(
    width,
    width + 0.13,
    abs(p.x - sway) + edgeNoise
  );
  samplePoint += vec2(warpA - 0.5, warpB - 0.5) * 1.15;
  float detail = fbm(samplePoint * 2.1 + vec2(-t * 0.06, t * 0.28));
  float density = smoothstep(0.42, 0.72, detail + (plume - 0.5) * 0.26);
  density *= plume * sourceFade;
  float wisps = smoothstep(0.64, 0.84, fbm(samplePoint * 3.1));
  density = clamp(density + wisps * plume * 0.20, 0.0, 1.0);

  float edgeLight = 4.0 * density * (1.0 - density);
  vec3 background = mix(vec3(0.002, 0.004, 0.009), uColorB * 0.045, height);
  vec3 smokeBody = mix(
    uColorB * 0.28,
    uColorA * 0.78,
    clamp(detail * 0.95 + edgeLight * 0.28, 0.0, 1.0)
  );
  vec3 color = background + smokeBody * density * (0.52 + detail * 0.52);
  return color + uColorA * edgeLight * density * 0.16;
}

vec3 nebula(vec2 p) {
  float t = uTime * 0.055;
  vec2 q = p * 2.2;
  float warpA = fbm(q * 0.9 + vec2(t, -t * 0.6));
  float warpB = fbm(q * 1.1 + vec2(-t * 0.5, 4.2 + t));
  q += vec2(warpA - 0.5, warpB - 0.5) * 1.2;
  float cloud = fbm3(vec3(q * 1.55, t * 0.6));  // evolves in time, not scrolling
  float density = smoothstep(0.34, 0.82, cloud);
  float core = pow(smoothstep(0.48, 0.9, cloud), 2.0);
  float stars = step(0.996, hash21(floor((p + 2.0) * 180.0)));
  vec3 color = vec3(0.003, 0.004, 0.018);
  color += uColorA * density * 0.52;
  color += uColorB * core * 0.78;
  color += stars * (0.65 + hash21(floor(p * 90.0)) * 0.35);
  return aces(color);
}

vec3 inkBloom(vec2 p) {
  vec2 q = p - vec2(0.0, 0.04);
  float radius = length(q * vec2(0.88, 1.0));
  float angle = atan(q.y, q.x);
  float tendrils = fbm(
    vec2(angle * 1.25 + uTime * 0.025, radius * 7.0 - uTime * 0.07)
  );
  float pulse = 0.34 + sin(uTime * 0.11) * 0.035;
  float boundary = radius + (tendrils - 0.5) * 0.30;
  boundary += sin(angle * 9.0 - uTime * 0.18) * 0.025;
  float ink = 1.0 - smoothstep(pulse - 0.07, pulse + 0.11, boundary);
  float rim = 1.0 - smoothstep(0.015, 0.075, abs(boundary - pulse));
  vec3 background = mix(uColorA * 0.15, uColorB * 0.18, p.y + 0.5);
  background += vec3(0.006, 0.004, 0.018);
  vec3 color = mix(background, vec3(0.002, 0.002, 0.008), ink * 0.92);
  return color + mix(uColorA, uColorB, tendrils) * rim * 0.82;
}

vec3 plasma(vec2 p) {
  // Domain-warp then drive ridged FBM so structure is filamentary, not a
  // scrolling sine grid; hot cores read as electric discharge.
  vec2 q = p * 2.4;
  q += vec2(
    sin(q.y * 1.6 + uTime * 0.6),
    cos(q.x * 1.4 - uTime * 0.5)
  ) * 0.6;
  float filament = ridgedFbm(q * 1.3 + vec2(uTime * 0.04, -uTime * 0.03));
  float field = sin(filament * 6.0 + uTime * 1.2);
  float glow = 0.5 + 0.5 * field;
  float hot = pow(glow, 6.0);
  vec3 color = mix(uColorA * 0.10, uColorB * 0.7, glow);
  color += uColorA * hot * 0.5;
  return aces(color * (0.5 + glow * 0.6));
}

vec3 ripples(vec2 p) {
  // Two drifting emitters; each wavefront decays radially (exp) so rings read
  // as propagating disturbances rather than infinite standing waves.
  vec2 s1 = vec2(sin(uTime * 0.35), cos(uTime * 0.29)) * 0.18;
  vec2 s2 = vec2(cos(uTime * 0.23), sin(uTime * 0.31)) * 0.26;
  float d1 = length(p - s1);
  float d2 = length(p - s2);
  float w1 = sin(d1 * 34.0 - uTime * 3.0) * exp(-d1 * 2.4);
  float w2 = sin(d2 * 28.0 - uTime * 2.4) * exp(-d2 * 2.0);
  float wave = w1 + w2;
  float rings = clamp(pow(0.5 + 0.5 * wave, 3.0), 0.0, 1.0);
  float crest = smoothstep(0.55, 1.0, 0.5 + 0.5 * wave);  // constructive peaks
  vec3 color = mix(vec3(0.003, 0.022, 0.06), mix(uColorB, uColorA, rings), rings);
  return color + uColorA * crest * 0.25;
}

vec3 vortex(vec2 p) {
  float radius = length(p);
  // Rankine-like profile: angular velocity high in the core, decaying at the
  // rim. Rotate the sampling domain by it, then sample arms + fbm eddies.
  float swirl = 2.4 / (0.25 + radius * radius);
  vec2 sp = rotate2d(p, swirl + uTime * 0.6);
  float arms = 0.5 + 0.5 * sin(atan(sp.y, sp.x) * 5.0 - radius * 22.0);
  float eddies = fbm(sp * 3.0 + vec2(uTime * 0.05, 0.0));
  float spiral = mix(arms, eddies, 0.35);
  float core = exp(-radius * radius * 42.0);  // bounded glow, no 1/r blowout
  vec3 body = mix(
    uColorB * 0.08,
    mix(uColorA, uColorB, spiral),
    smoothstep(0.8, 0.05, radius)
  );
  return body + uColorA * core * 0.6;
}

void main() {
  vec2 p = FlutterFragCoord().xy / uSize - 0.5;
  p.x *= uSize.x / uSize.y;
  vec3 color;
  if (uEffect < 0.5) {
    color = aurora(p);
  } else if (uEffect < 1.5) {
    color = silk(p);
  } else if (uEffect < 2.5) {
    color = meshGradient(p);
  } else if (uEffect < 3.5) {
    color = caustics(p);
  } else if (uEffect < 4.5) {
    color = topography(p);
  } else if (uEffect < 5.5) {
    color = holographic(p);
  } else if (uEffect < 6.5) {
    color = smoke(p);
  } else if (uEffect < 7.5) {
    color = nebula(p);
  } else if (uEffect < 8.5) {
    color = inkBloom(p);
  } else if (uEffect < 9.5) {
    color = plasma(p);
  } else if (uEffect < 10.5) {
    color = ripples(p);
  } else {
    color = vortex(p);
  }
  float strength = clamp(uIntensity, 0.0, 1.5);
  color = mix(vec3(0.006, 0.009, 0.025), color, strength);
  color += (hash21(FlutterFragCoord().xy) - 0.5) / 255.0;  // dither, always last
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
