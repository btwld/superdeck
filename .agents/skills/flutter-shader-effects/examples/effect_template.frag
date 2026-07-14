#version 460 core
#include <flutter/runtime_effect.glsl>

// Standalone SuperDeck effect shader template.
// Slot table — keep in sync with the painter (each float = 1 slot, in order):
uniform vec2 uSize;      // setFloat 0, 1
uniform float uTime;     // setFloat 2  (seconds x speed; wraps at 3600)
uniform float uIntensity; // setFloat 3 (0.0-1.5)
uniform vec3 uColorA;    // setFloat 4, 5, 6
uniform vec3 uColorB;    // setFloat 7, 8, 9
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

vec3 effect(vec2 p) {
  // TODO: build the effect here. Advect the domain, not the pattern:
  vec2 q = vec2(fbm(p + uTime * 0.03), fbm(p + vec2(5.2, 1.3)));
  float density = fbm(p * 2.0 + q * 1.2);
  vec3 base = vec3(0.004, 0.006, 0.02);
  return base + mix(uColorB, uColorA, density) * density * 0.6;
}

void main() {
  vec2 p = FlutterFragCoord().xy / uSize - 0.5;  // centered
  p.x *= uSize.x / uSize.y;                       // aspect-corrected (y is down)

  vec3 color = effect(p);

  // Finishing pass: intensity floor mix, then dither (always last).
  float strength = clamp(uIntensity, 0.0, 1.5);
  color = mix(vec3(0.006, 0.009, 0.025), color, strength);
  color += (hash21(FlutterFragCoord().xy) - 0.5) / 255.0;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
