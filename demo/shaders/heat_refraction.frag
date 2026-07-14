#version 460 core
#include <flutter/runtime_effect.glsl>

// ImageFilter.shader sets uSize and uInput. Dart owns the animated values.
// Float slots: uSize 0-1, uTime 2, uStrength 3.
uniform vec2 uSize;
uniform float uTime;
uniform float uStrength;
uniform sampler2D uInput;
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

vec2 clampUv(vec2 uv) {
  vec2 inset = 1.5 / uSize;
  return clamp(uv, inset, vec2(1.0) - inset);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  float strength = clamp(uStrength, 0.0, 1.5);
  float power = min(strength, 1.0);
  float energy = power * power * (3.0 - 2.0 * power);
  // Dart integrates a forward-only clock whose rate follows the temperature
  // differential. Keeping phase separate from strength prevents a slider
  // change from rewinding the refraction field.
  float t = mod(uTime, 600.0);
  vec2 p = uv - 0.5;
  p.x *= uSize.x / uSize.y;

  // Refraction is strongest near the warm lower outlet and along the two
  // rising side plumes. A little remains in the middle so the air feels alive.
  float lowerHeat = smoothstep(0.08, 0.96, uv.y);
  float plumeCenter = mix(0.10, 0.46, 1.0 - uv.y);
  float sidePlumes = exp(-pow((abs(p.x) - plumeCenter) / 0.24, 2.0));
  float sourcePlume = exp(-p.x * p.x * 5.0) * lowerHeat;
  float heatMask = clamp(
    sidePlumes * (0.48 + lowerHeat * 0.52) + sourcePlume * 0.42,
    0.0,
    1.0
  );

  // Two independently advected scales keep the lensing from reading as a
  // single scrolling texture. Fine cells travel faster than broad billows.
  vec2 broadDomain = vec2(
    p.x * 4.2 + sin(p.y * 4.0 - t * 0.21) * 0.35,
    p.y * 3.0 + t * 0.24
  );
  vec2 fineDomain = vec2(
    p.x * 11.0 - t * 0.13,
    p.y * 8.5 + t * 0.72
  );
  float broad = noise21(broadDomain);
  float broadOffset = noise21(broadDomain + vec2(5.2, 1.3));
  float fine = noise21(fineDomain + vec2(broad, broadOffset) * 1.4);
  float shimmer = sin(
    p.y * 31.0 - t * 2.1 + broad * 5.5 + p.x * 3.0
  );

  float amplitude = mix(0.0002, 0.0140, energy);
  amplitude *= heatMask * (0.62 + lowerHeat * 0.38);
  vec2 displacement = vec2(
    (broad - 0.5) * 1.55 + shimmer * 0.34 + (fine - 0.5) * 0.30,
    (broadOffset - 0.5) * 0.34 + (fine - 0.5) * 0.18
  );
  displacement *= amplitude;

  vec2 warpedUv = clampUv(uv + displacement);
  // Nine anisotropic samples soften the rising vapor like a turbulent lens.
  // The kernel expands with output so high heat visibly blooms and blurs.
  vec2 blurStep = vec2(
    mix(1.0, 7.2, energy) / uSize.x,
    mix(0.8, 5.4, energy) / uSize.y
  );
  vec4 warped = texture(uInput, warpedUv);
  vec4 softened = warped * 0.28;
  softened += texture(uInput, clampUv(warpedUv + vec2(blurStep.x, 0.0))) * 0.11;
  softened += texture(uInput, clampUv(warpedUv - vec2(blurStep.x, 0.0))) * 0.11;
  softened += texture(uInput, clampUv(warpedUv + vec2(0.0, blurStep.y))) * 0.11;
  softened += texture(uInput, clampUv(warpedUv - vec2(0.0, blurStep.y))) * 0.11;
  softened += texture(uInput, clampUv(warpedUv + blurStep)) * 0.07;
  softened += texture(uInput, clampUv(warpedUv - blurStep)) * 0.07;
  softened += texture(
    uInput,
    clampUv(warpedUv + vec2(blurStep.x, -blurStep.y))
  ) * 0.07;
  softened += texture(
    uInput,
    clampUv(warpedUv + vec2(-blurStep.x, blurStep.y))
  ) * 0.07;

  float blurVariation = mix(0.82, 1.12, broad);
  float blurAmount = heatMask * mix(0.015, 0.64, energy) * blurVariation;
  vec4 color = mix(warped, softened, blurAmount);

  // Tiny wavelength separation sells a hot optical lens without turning the
  // result into a chromatic-aberration effect.
  float fringe = heatMask * energy * 0.12;
  float red = texture(uInput, clampUv(uv + displacement * 1.10)).r;
  float blue = texture(uInput, clampUv(uv + displacement * 0.88)).b;
  color.r = mix(color.r, red, fringe);
  color.b = mix(color.b, blue, fringe * 0.65);
  fragColor = color;
}
