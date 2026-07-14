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

// 3D value noise lets haze and mist evolve instead of scrolling like textures.
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

// Time-cascaded turbulence: fine detail evolves faster than broad motion.
float turbulentFbm(vec2 p, float t) {
  float value = 0.0;
  float amplitude = 0.5;
  float rate = 1.0;
  for (int i = 0; i < 4; i++) {
    vec2 drift = vec2(
      sin(t * 0.17 * rate),
      t * 0.11 * rate
    );
    value += amplitude * noise21(p + drift);
    p = vec2(1.6 * p.x - 1.2 * p.y, 1.2 * p.x + 1.6 * p.y) + 13.1;
    amplitude *= 0.5;
    rate *= 1.7;
  }
  return value;
}

float thermalPower() {
  return clamp(uIntensity, 0.0, 1.0);
}

// ACES filmic tone map — compress additive light stages instead of clipping.
vec3 aces(vec3 x) {
  return clamp(
    (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14),
    0.0,
    1.0
  );
}

// Keeps the temperature readout legible while allowing the flow to wrap around
// it. The mask never reaches zero, so the display still feels embedded in air.
float airflowDisplayMask(vec2 p) {
  vec2 displayPoint = vec2(p.x / 0.35, (p.y + 0.01) / 0.24);
  float outsideDisplay = smoothstep(0.72, 1.18, length(displayPoint));
  return mix(0.14, 1.0, outsideDisplay);
}

vec3 heatAirflow(vec2 p) {
  float power = thermalPower();
  float energy = power * power * (3.0 - 2.0 * power);
  float t = mod(uTime, 600.0);
  float height = clamp(0.5 - p.y, 0.0, 1.0);
  // Output changes the energy, not the direction or footprint. A low setting
  // still reaches through the display; it is simply fainter, slower, cooler,
  // and less turbulent than the high setting.
  float reachLimit = 1.08;
  float reach = 1.0 - smoothstep(
    reachLimit - 0.12,
    reachLimit + 0.04,
    height
  );
  float sourceFade = smoothstep(0.0, 0.045, height);
  float topDissipation = 1.0 - smoothstep(0.86, 1.06, height);
  float displayMask = airflowDisplayMask(p);
  float aspect = uSize.x / uSize.y;
  float span = min(0.78, max(0.42, aspect * 0.43));

  vec3 color = mix(
    vec3(0.007, 0.003, 0.004),
    uColorB * 0.045,
    (1.0 - height) * (0.42 + power * 0.24)
  );

  // A broad, slowly rolling vapor layer gives the filaments a soft volume.
  // Its advection rate and density rise non-linearly with thermal energy, so
  // higher output reads as genuinely stronger convection instead of scaling
  // the same drawing upward.
  float vaporSpeed = 0.155;
  vec2 vaporPoint = vec2(
    p.x * (1.68 + power * 0.30),
    (p.y + t * vaporSpeed) * 1.42
  );
  float vaporBroad = fbm3(vec3(
    vaporPoint,
    t * 0.125
  ));
  float vaporDetail = fbm3(vec3(
    vaporPoint * 2.13 + vec2(vaporBroad * 1.7, -vaporBroad),
    t * 0.285 + 7.3
  ));
  float vaporField = vaporBroad * 0.72 + vaporDetail * 0.28;
  // Strength opens up more occupied pockets rather than uniformly fading the
  // same cloud. Low output keeps a few legible billows; high output fills the
  // gaps and creates the denser overlapping vapor body.
  float softBillows = smoothstep(
    mix(0.62, 0.30, energy),
    0.70,
    vaporBroad
  );
  float denseBillows = smoothstep(
    mix(0.66, 0.42, energy),
    0.74,
    vaporField
  );
  float vaporCenter = span * (
    0.10 + height * mix(0.16, 0.34, energy)
  );
  float vaporWidth = span * (
    mix(0.30, 0.40, energy) + height * mix(0.13, 0.27, energy)
  );
  float sideVapor = exp(-pow(
    (abs(p.x) - vaporCenter) / max(vaporWidth, 0.001),
    2.0
  ));
  float sourceVapor = exp(-pow(p.x / max(span * 0.66, 0.001), 2.0));
  sourceVapor *= 1.0 - smoothstep(0.10, 0.58, height);
  float vaporEnvelope = clamp(sideVapor + sourceVapor * 0.46, 0.0, 1.0);
  float vaporPulse = 0.72 + 0.28 * sin(
    height * 12.0 - t * 1.52 + vaporBroad * 6.2
  );
  float vapor = mix(softBillows * 0.52, denseBillows, 0.64 + energy * 0.18);
  vapor *= vaporEnvelope * vaporPulse;
  vapor *= reach * sourceFade * topDissipation * displayMask;
  vec3 vaporColor = mix(
    uColorB * 0.16,
    uColorA * 0.38,
    clamp(vaporField + height * 0.12, 0.0, 1.0)
  );
  color += vaporColor * vapor * (0.34 + energy * 0.52);
  color += uColorA * vapor * vapor * (0.016 + energy * 0.060);

  // Two nested bundles on each side rise buoyantly, expand, and curl around
  // the readout. Each bundle contains many fine, independently moving lines.
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    float side = i < 2 ? -1.0 : 1.0;
    float lane = i < 2 ? fi : 3.0 - fi;
    float bundlePresence = lane < 0.5
      ? smoothstep(0.02, 0.30, power)
      : smoothstep(0.38, 0.78, power);
    float depth = 0.72 + (1.0 - lane) * 0.18;
    float origin = side * span * (0.10 + lane * 0.25);
    float expansion = span * (
      mix(0.20, 0.43, energy) * pow(height, 0.72) +
      lane * 0.17 * height
    );
    float speed = 0.15 * (0.92 + lane * 0.12);
    vec2 samplePoint = vec2(
      p.x * (2.35 + lane * 0.22),
      (p.y + t * speed) * (1.72 + lane * 0.12)
    );
    float warp = turbulentFbm(
      samplePoint + vec2(fi * 5.17, fi * 2.31),
      t * (0.325 + lane * 0.035)
    );
    float sway = sin(
      height * (5.0 + lane * 0.85) -
      t * 0.32 +
      lane * 2.4
    );
    sway *= 0.012 + height * mix(0.030, 0.078, energy);
    sway += sin(
      height * 10.5 + t * 0.19 + fi * 1.7
    ) * 0.010;
    float center = origin + side * expansion + sway;
    center += (warp - 0.48) * (
      0.012 + height * mix(0.032, 0.075, power)
    );
    float width = span * (
      mix(0.032, 0.055, energy) +
      height * mix(0.066, 0.125, energy)
    );
    width *= 1.0 + lane * 0.14;
    float lateral = (p.x - center) / max(width, 0.001);
    float envelope = exp(-lateral * lateral * 1.28);
    // Build heat wisps from moving noise contours rather than repeated cosine
    // bands. Their local spacing, thickness, and continuity all drift, which
    // avoids the parallel "cloth" pattern of evenly spaced streamlines.
    float organicLateral = lateral + (warp - 0.48) * (1.10 + energy * 0.55);
    organicLateral += sin(
      height * (6.2 + lane) - t * 0.39 + fi * 2.1
    ) * (0.14 + energy * 0.12);
    float broadWispField = noise21(vec2(
      organicLateral * 0.72 + fi * 4.73,
      height * 2.7 - t * 0.44
    ));
    float fineWispField = noise21(vec2(
      organicLateral * 1.85 - fi * 3.17,
      height * 5.4 - t * 0.92 + warp * 1.8
    ));
    float broadWisps = exp(-pow((broadWispField - 0.52) / 0.105, 2.0));
    float fineWisps = exp(-pow((fineWispField - 0.48) / 0.060, 2.0));
    float breakup = noise21(vec2(
      height * 4.3 - t * 0.60 + fi * 5.9,
      organicLateral * 0.27 + warp * 1.6
    ));
    float wispPresence = smoothstep(
      mix(0.60, 0.22, energy),
      mix(0.88, 0.76, energy),
      breakup
    );
    float upwardPulse = 0.62 + 0.38 * sin(
      height * (19.0 + lane * 2.0) -
      t * 1.58 +
      fi * 1.4
    );
    float flowMask = reach * sourceFade * topDissipation * displayMask;
    flowMask *= bundlePresence;
    float body = envelope * (0.16 + warp * 0.24) * flowMask;
    float volumeHalo = exp(-lateral * lateral * 0.38) * flowMask;
    float filaments = envelope * (
      broadWisps * 0.74 + fineWisps * 0.22
    );
    filaments *= mix(0.18, 1.0, wispPresence);
    filaments *= (0.82 + upwardPulse * 0.18) * flowMask;
    float density = clamp(body * 1.65 + filaments * 0.68, 0.0, 1.0);
    float edgeLight = 4.0 * density * (1.0 - density);
    vec3 bodyColor = mix(
      uColorB * 0.22,
      uColorA * 0.42,
      clamp(warp + height * 0.18, 0.0, 1.0)
    );
    vec3 filamentColor = mix(
      uColorA * 0.72,
      vec3(1.0, 0.84, 0.58),
      0.30 + upwardPulse * 0.20
    );
    color += bodyColor * volumeHalo * depth * (0.14 + energy * 0.17);
    color += bodyColor * body * depth * (0.84 + energy * 0.56);
    color += filamentColor * filaments * depth * (0.22 + energy * 0.16);
    color += uColorA * edgeLight * body * depth * (0.040 + energy * 0.040);
  }

  float sourceSpan = 1.0 - smoothstep(span * 0.72, span, abs(p.x));
  float sourceGlow = exp(-abs(p.y - 0.485) * 48.0) * sourceSpan;
  color += mix(uColorB, uColorA, 0.42) * sourceGlow * (
    0.060 + energy * 0.080
  );
  return aces(color * 1.06);
}

vec3 heatHaze(vec2 p) {
  float power = thermalPower();
  float t = mod(uTime, 600.0) * mix(0.08, 0.22, power);
  vec2 q = p * vec2(3.8, 1.55);
  float slowField = fbm3(vec3(q * 0.55, t * 0.16));
  vec2 warped = q;
  warped.x += (slowField - 0.5) * mix(0.08, 0.36, power);
  warped.y += t * 0.30;
  float fineField = fbm3(vec3(warped * 1.28, t * 0.34));
  float offsetField = fbm3(
    vec3((warped + vec2(0.022, 0.0)) * 1.28, t * 0.34)
  );
  float lens = clamp(abs(fineField - offsetField) * 11.0, 0.0, 1.0);
  float filamentPhase = warped.x * 3.2 + (fineField - 0.5) * 3.0;
  filamentPhase += sin(warped.y * 1.4 - t * 0.55) * 0.9;
  float filaments = pow(
    max(0.0, 1.0 - abs(sin(filamentPhase))),
    9.0
  );
  float lowerHeat = clamp(p.y + 0.72, 0.0, 1.0);
  float shimmer = lens * 0.35 + filaments * 0.42;
  shimmer *= (0.36 + power * 0.64) * (0.48 + lowerHeat * 0.52);

  vec3 color = mix(
    vec3(0.014, 0.004, 0.002),
    uColorB * 0.055,
    lowerHeat * (0.45 + slowField * 0.35)
  );
  color += uColorB * fineField * lowerHeat * power * 0.045;
  color += uColorA * shimmer * (0.14 + power * 0.12);
  color += vec3(1.0, 0.82, 0.55) * pow(lens, 3.0) * power * 0.06;
  return aces(color * 1.02);
}

vec3 heatRadiance(vec2 p) {
  float power = thermalPower();
  float t = mod(uTime, 600.0) * mix(0.08, 0.20, power);
  vec2 q = (p - vec2(0.0, 0.20)) * vec2(0.88, 1.0);
  float warp = fbm3(vec3(q * 2.8, t * 0.13));
  float radius = length(q) + (warp - 0.5) * (0.025 + power * 0.045);
  float halo = exp(-radius * radius * 10.0);
  float pulse = 0.78 + 0.22 * sin(t * 3.2);
  float centerClear = smoothstep(0.12, 0.22, radius);

  vec3 color = mix(
    vec3(0.012, 0.003, 0.001),
    uColorB * 0.045,
    clamp(p.y + 0.62, 0.0, 1.0)
  );
  color += uColorB * halo * pulse * (0.04 + power * 0.04);

  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float phase = fract(t + fi * 0.3333);
    float front = phase * 1.10;
    float width = mix(0.012, 0.032, power) * (1.0 + fi * 0.08);
    float wave = exp(-pow((radius - front) / width, 2.0));
    wave *= (1.0 - phase) * exp(-radius * 0.82) * centerClear;
    vec3 waveColor = mix(uColorB, uColorA, 0.62 + fi * 0.12);
    color += waveColor * wave * (0.20 + power * 0.30);
    color += vec3(1.0, 0.83, 0.58) * pow(wave, 3.0) * power * 0.05;
  }

  return aces(color * 1.03);
}

// Fine condensation crystals advect downward at independent depths. Their
// circular footprint stays below snowflake scale even on a 720p slide.
float microCrystalLayer(
  vec2 p,
  float t,
  vec2 scale,
  float speed,
  float seed,
  float threshold
) {
  vec2 advected = p + vec2(
    sin(p.y * 9.0 - t * 0.34 + seed) * 0.0045,
    -t * speed
  );
  vec2 grid = (advected + vec2(1.2, 1.0)) * scale;
  vec2 cell = floor(grid);
  vec2 local = fract(grid) - 0.5;
  float id = hash21(cell + seed);
  vec2 site = vec2(
    hash21(cell + seed + 17.17),
    hash21(cell + seed + 43.71)
  );
  site = (site - 0.5) * 0.62;
  float radius = mix(0.085, 0.155, hash21(cell + seed + 71.3));
  float point = 1.0 - smoothstep(
    radius * 0.42,
    radius,
    length(local - site)
  );
  float glint = mix(0.68, 1.0, hash21(cell + seed + 91.7));
  glint *= 0.88 + 0.12 * sin(t * 1.7 + id * 6.2831);
  return step(threshold, id) * point * glint;
}

vec3 coldAirflow(vec2 p) {
  float power = thermalPower();
  float energy = power * power * (3.0 - 2.0 * power);
  float t = mod(uTime, 600.0);
  float fall = clamp(p.y + 0.5, 0.0, 1.0);
  // Strength opens more vents and lowers the condensation threshold. It never
  // changes the direction or shortens a current that is already active.
  float reachLimit = 1.08;
  float reach = 1.0 - smoothstep(
    reachLimit - 0.12,
    reachLimit + 0.04,
    fall
  );
  float sourceFade = smoothstep(0.0, 0.045, fall);
  float bottomDissipation = 1.0 - smoothstep(0.86, 1.06, fall);
  float displayMask = airflowDisplayMask(p);
  float aspect = uSize.x / uSize.y;
  float span = min(0.78, max(0.42, aspect * 0.43));

  vec3 color = mix(
    uColorB * 0.052,
    vec3(0.002, 0.008, 0.022),
    smoothstep(0.02, 0.94, fall) * (0.66 + power * 0.12)
  );
  float ceilingChill = exp(-fall * 6.4);
  color += uColorB * ceilingChill * (0.018 + energy * 0.026);

  float condensationGuide = 0.0;
  float sourceSlots = 0.0;

  // Each vent combines three speeds: a fast pressure core, a medium white
  // condensation body, and a slow mixing sheath. This mirrors refrigerated air
  // curtains and aircraft cabin fog, where ambient moisture becomes visible
  // only after it is entrained downstream.
  for (int i = 0; i < 5; i++) {
    float fi = float(i);
    float lane = (fi - 2.0) * 0.5;
    float edgeLane = abs(lane);
    float laneVariation = hash21(vec2(fi + 2.3, 19.7));
    float lanePhase = 6.2831 * hash21(vec2(fi + 7.1, 3.9));
    float laneRate = mix(0.82, 1.18, laneVariation);
    float fanPulse = 0.84 + 0.16 * sin(
      t * mix(0.42, 0.60, laneVariation) + lanePhase
    );
    float jetPresence = smoothstep(
      0.02 + edgeLane * 0.24,
      0.22 + edgeLane * 0.34,
      power
    );
    float depth = 0.72 + (1.0 - edgeLane) * 0.18;
    float origin = lane * span * 0.62;
    float fan = lane * span * fall * mix(0.055, 0.14, energy);
    fan += lane * span * sin(fall * 3.14159) * (0.025 + energy * 0.050);
    float speed = 0.19 * laneRate * (0.96 + edgeLane * 0.06);
    vec2 samplePoint = vec2(
      p.x * (2.26 + edgeLane * 0.14),
      (p.y - t * speed) * (1.72 + edgeLane * 0.08)
    );
    float warp = turbulentFbm(
      samplePoint + vec2(fi * 4.73, fi * 1.83),
      t * (0.20 + laneVariation * 0.060)
    );
    float center = origin + fan;
    center += sin(
      fall * (3.6 + edgeLane * 0.6) -
      t * 0.18 * laneRate +
      lanePhase
    ) * (0.004 + fall * mix(0.008, 0.020, energy));
    center += (warp - 0.48) * (
      0.005 + fall * mix(0.012, 0.030, energy)
    );
    float width = span * (
      mix(0.019, 0.027, energy) +
      fall * mix(0.028, 0.052, energy)
    );
    width *= 0.94 + edgeLane * 0.12;
    float lateral = (p.x - center) / max(width, 0.001);
    float sheath = exp(-lateral * lateral * 0.40);
    float bodyEnvelope = exp(-lateral * lateral * 1.18);

    float broadMist = fbm3(vec3(
      lateral * 0.34 + fi * 2.7,
      fall * 3.15 - t * 0.47 * laneRate,
      t * 0.12 + fi * 4.1
    ));
    float mistDetail = noise31(vec3(
      lateral * 0.82 - fi * 3.3,
      fall * 7.6 - t * 0.92 * laneRate,
      t * 0.24 + warp * 2.1
    ));
    float mistField = broadMist * 0.70 + mistDetail * 0.30;
    float mistPockets = smoothstep(
      mix(0.54, 0.31, energy),
      mix(0.77, 0.67, energy),
      mistField
    );
    float interfacePosition = mix(0.76, 1.02, broadMist);
    float interfaceBand = exp(-pow(
      (abs(lateral) - interfacePosition) / 0.25,
      2.0
    ));
    float contactField = broadMist * 0.55 + mistDetail * 0.45;
    float contactPatches = smoothstep(
      mix(0.62, 0.43, energy),
      mix(0.78, 0.70, energy),
      contactField
    );

    // A slower, wider field lags behind the main condensation body. Its broad
    // pockets curl around each jet instead of sharing the same silhouette or
    // speed, producing the rolling fog seen below cold industrial vents.
    float mixingCenter = center;
    mixingCenter += sin(
      fall * (4.1 + laneVariation * 1.2) -
      t * 0.19 * laneRate +
      lanePhase * 0.7
    ) * fall * mix(0.018, 0.060, energy);
    mixingCenter += (warp - 0.48) * fall * mix(0.020, 0.070, energy);
    float mixingWidth = width * (
      1.52 + fall * mix(0.28, 0.68, energy)
    );
    float mixingLateral = (p.x - mixingCenter) / max(mixingWidth, 0.001);
    float mixingEnvelope = exp(-mixingLateral * mixingLateral * 0.36);
    float slowBroad = fbm3(vec3(
      mixingLateral * 0.31 + fi * 5.27,
      fall * 2.55 - t * 0.21 * laneRate,
      t * 0.070 + lanePhase
    ));
    float slowDetail = noise31(vec3(
      mixingLateral * 0.88 - fi * 2.81,
      fall * 6.3 - t * 0.53 * laneRate,
      t * 0.15 + broadMist * 2.4
    ));
    float slowField = slowBroad * 0.68 + slowDetail * 0.32;
    float slowPockets = smoothstep(
      mix(0.66, 0.48, energy),
      mix(0.84, 0.75, energy),
      slowField
    );
    float condensationOnset = smoothstep(
      0.045 + laneVariation * 0.018,
      0.16 + laneVariation * 0.025,
      fall
    );
    float mixingOnset = smoothstep(
      0.11 + laneVariation * 0.025,
      0.29 + laneVariation * 0.035,
      fall
    );

    float ribbonDrift = noise31(vec3(
      fall * 3.8 - t * 0.29 * laneRate,
      fi * 5.3,
      t * 0.11
    )) - 0.5;
    float primaryCore = exp(-pow(
      (lateral - ribbonDrift * 0.54) / 0.14,
      2.0
    ));
    float secondaryDrift = noise31(vec3(
      fall * 4.7 - t * 0.36 * laneRate + 8.2,
      fi * 3.7 + 11.0,
      t * 0.16
    )) - 0.5;
    float secondaryCore = exp(-pow(
      (lateral + 0.48 + secondaryDrift * 0.50) / 0.11,
      2.0
    ));
    secondaryCore *= smoothstep(0.30 + edgeLane * 0.12, 0.76, power);
    float coreBreakup = noise31(vec3(
      fall * 9.4 - t * 1.15 * laneRate,
      fi * 5.9 + lateral * 0.12,
      t * 0.19
    ));
    float coreContinuity = mix(
      0.06,
      1.0,
      smoothstep(0.30, 0.68, coreBreakup)
    );
    float fallingPocket = noise31(vec3(
      fall * 6.2 - t * 1.34 * laneRate,
      fi * 4.4,
      t * 0.15 + lateral * 0.18
    ));
    fallingPocket = 0.62 + 0.38 * smoothstep(0.18, 0.82, fallingPocket);

    float flowMask = reach * sourceFade * bottomDissipation * displayMask;
    flowMask *= jetPresence;
    float clearSheath = sheath * (0.015 + mistPockets * 0.14);
    clearSheath *= fallingPocket * condensationOnset * flowMask;
    float body = bodyEnvelope * (
      0.025 + mistPockets * 0.34 + contactPatches * 0.12
    );
    body *= fallingPocket * condensationOnset * flowMask;
    body *= 0.82 + fanPulse * 0.18;
    float contactCondensation = interfaceBand;
    contactCondensation *= mix(0.015, 1.0, contactPatches);
    contactCondensation *= fallingPocket * condensationOnset * flowMask;
    float cores = primaryCore + secondaryCore * 0.58;
    cores *= coreContinuity * bodyEnvelope * fallingPocket * flowMask;
    cores *= fanPulse;
    float cloudDensity = clamp(bodyEnvelope * mistPockets, 0.0, 1.0);
    float rim = 4.0 * cloudDensity * (1.0 - cloudDensity);
    rim *= condensationOnset * flowMask;
    float slowMixing = mixingEnvelope * slowPockets * mixingOnset;
    slowMixing *= flowMask * (0.88 + fanPulse * 0.12);
    vec3 bodyColor = mix(
      uColorB * 0.14,
      vec3(0.70, 0.92, 0.96),
      clamp(0.32 + mistField * 0.46 + fall * 0.06, 0.0, 1.0)
    );
    vec3 coreColor = mix(
      vec3(0.52, 0.88, 0.98),
      vec3(0.95, 1.0, 1.0),
      0.58 + coreBreakup * 0.24
    );
    vec3 condensationColor = mix(
      vec3(0.52, 0.84, 0.92),
      vec3(0.98, 1.0, 1.0),
      0.62 + mistDetail * 0.28
    );
    vec3 mixingColor = mix(
      uColorB * 0.11,
      vec3(0.56, 0.82, 0.88),
      0.30 + slowField * 0.38
    );
    color += mixingColor * slowMixing * depth * (0.18 + energy * 0.34);
    color += bodyColor * clearSheath * depth * (0.24 + energy * 0.34);
    color += bodyColor * body * depth * (0.62 + energy * 0.72);
    color += condensationColor * contactCondensation * depth *
      (0.18 + energy * 0.36);
    color += coreColor * cores * depth * (0.12 + energy * 0.18);
    color += vec3(0.90, 0.99, 1.0) * rim * depth *
      (0.045 + energy * 0.090);

    condensationGuide = max(
      condensationGuide,
      clamp(
        sheath * mistPockets * 0.62 +
        interfaceBand * 0.20 +
        mixingEnvelope * slowPockets * 0.28,
        0.0,
        1.0
      ) * jetPresence
    );
    float slot = exp(-pow(
      (p.x - origin) / max(span * 0.050, 0.001),
      2.0
    ));
    sourceSlots = max(sourceSlots, slot * jetPresence);
  }

  float ventSpan = 1.0 - smoothstep(span * 0.70, span * 0.90, abs(p.x));
  float ventGlow = exp(-pow((fall - 0.012) / 0.013, 2.0)) * ventSpan;
  color += uColorB * ventGlow * (0.035 + energy * 0.055);
  color += uColorA * ventGlow * sourceSlots * (0.035 + energy * 0.065);

  // Dense refrigerated air settles and spreads after the falling curtains
  // reach the lower cabin or fridge volume. This remains a secondary layer so
  // it does not turn the entire scene into undirected smoke.
  float poolField = fbm3(vec3(
    p.x * 1.85 - t * 0.045,
    fall * 4.2 - t * 0.12,
    t * 0.075
  ));
  float coldPool = smoothstep(0.69, 1.0, fall);
  coldPool *= smoothstep(mix(0.73, 0.50, energy), 0.82, poolField);
  coldPool *= smoothstep(0.34, 0.88, power) * displayMask;
  color += mix(
    uColorB * 0.12,
    vec3(0.58, 0.84, 0.90),
    poolField
  ) * coldPool * (0.055 + energy * 0.12);

  // Two independently advected layers of sub-pixel-to-one-pixel aerosol dots
  // ride at different speeds. They visualize condensed moisture without
  // becoming decorative snowflakes.
  float fineCrystals = microCrystalLayer(
    p,
    t,
    vec2(118.0, 108.0),
    0.150,
    17.0,
    mix(0.9850, 0.9550, energy)
  );
  float nearCrystals = microCrystalLayer(
    p,
    t,
    vec2(88.0, 80.0),
    0.190,
    51.0,
    mix(0.9930, 0.9775, energy)
  );
  float particles = fineCrystals * 0.72 + nearCrystals;
  particles *= smoothstep(0.06, 0.42, condensationGuide);
  particles *= reach * sourceFade * bottomDissipation * displayMask;
  color += vec3(0.94, 0.995, 1.0) * particles * (0.30 + energy * 0.40);
  return aces(color * 1.06);
}

vec3 coldMist(vec2 p) {
  float power = thermalPower();
  float t = mod(uTime, 600.0) * mix(0.08, 0.19, power);
  float fall = clamp(p.y + 0.5, 0.0, 1.0);
  float reachLimit = mix(0.30, 1.12, power);
  float reach = 1.0 - smoothstep(reachLimit - 0.18, reachLimit, fall);
  float sourceFade = smoothstep(-0.56, -0.42, p.y);
  vec3 color = mix(
    uColorB * 0.05,
    vec3(0.002, 0.008, 0.024),
    clamp(p.y + 0.5, 0.0, 1.0)
  );

  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    float depth = 1.0 - fi * 0.17;
    vec2 q = p * (1.0 + fi * 0.18);
    q += vec2((fi - 1.5) * 1.87, fi * 2.43);
    q.y -= t * (0.11 + fi * 0.022);
    q += vec2(
      sin(q.y * 1.5 + t * 0.37 + fi),
      cos(q.x * 1.2 - t * 0.28 + fi)
    ) * (0.055 + power * 0.055);
    float broad = fbm3(vec3(q * 0.82, t * 0.09 + fi * 1.9));
    q += vec2(broad - 0.5, 0.5 - broad) * (0.35 + power * 0.35);
    float cloud = fbm3(vec3(q * 1.58, t * 0.15 + fi * 3.7));
    float density = smoothstep(0.44, 0.80, cloud + broad * 0.17);
    density *= reach * sourceFade;
    float edgeLight = 4.0 * density * (1.0 - density);
    vec3 layerColor = mix(
      uColorB * (0.14 + fi * 0.018),
      uColorA * (0.34 + depth * 0.10),
      clamp(cloud + edgeLight * 0.22, 0.0, 1.0)
    );
    color = mix(color, layerColor, density * depth * (0.09 + power * 0.11));
    color += uColorA * edgeLight * density * depth * 0.025;
  }

  float poolNoise = fbm(vec2(p.x * 1.9 - t * 0.04, p.y * 5.2 + t * 0.07));
  float pool = smoothstep(0.43, 0.76, poolNoise);
  pool *= smoothstep(0.02, 0.50, p.y) * power;
  color = mix(color, uColorB * 0.18 + uColorA * 0.10, pool * 0.14);
  return aces(color * 1.04);
}

vec3 coldCrystal(vec2 p) {
  float power = thermalPower();
  float t = mod(uTime, 600.0);
  float aspect = uSize.x / uSize.y;
  vec2 screenPoint = vec2(p.x / aspect, p.y);
  float edgeDistance = 0.5 - max(abs(screenPoint.x), abs(screenPoint.y));
  float organicEdge = fbm(
    screenPoint * 3.0 + vec2(t * 0.008, -t * 0.006)
  );
  float growthDepth = mix(0.035, 0.30, power);
  float growth = 1.0 - smoothstep(
    growthDepth,
    growthDepth + 0.12,
    edgeDistance + (organicEdge - 0.5) * 0.07
  );

  vec2 q = p * mix(4.6, 7.0, power);
  vec2 cell = floor(q);
  vec2 local = fract(q);
  float minimumDistance = 8.0;
  float secondDistance = 8.0;
  float cellId = 0.0;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 offset = vec2(float(x), float(y));
      vec2 id = cell + offset;
      vec2 site = offset + vec2(hash21(id), hash21(id + 19.19));
      site += 0.055 * sin(t * 0.22 + 6.2831 * site);
      float distanceToSite = length(site - local);
      if (distanceToSite < minimumDistance) {
        secondDistance = minimumDistance;
        minimumDistance = distanceToSite;
        cellId = hash21(id + 7.31);
      } else if (distanceToSite < secondDistance) {
        secondDistance = distanceToSite;
      }
    }
  }

  float boundaryGap = secondDistance - minimumDistance;
  float crystalVein = 1.0 - smoothstep(0.018, 0.075, boundaryGap);
  float facet = clamp(1.0 - minimumDistance * 0.82, 0.0, 1.0);
  float sparkle = pow(max(0.0, 1.0 - minimumDistance), 10.0);
  sparkle *= 0.68 + 0.32 * sin(t * 0.55 + cellId * 6.2831);
  float edgeBand = exp(-max(edgeDistance, 0.0) * 18.0);

  vec3 color = mix(
    vec3(0.002, 0.010, 0.025),
    uColorB * 0.075,
    growth
  );
  color += uColorB * growth * facet * (0.055 + power * 0.055);
  color += uColorA * growth * crystalVein * (0.18 + power * 0.28);
  color += uColorA * growth * sparkle * power * 0.16;
  color += uColorB * edgeBand * (0.05 + power * 0.08);
  return aces(color * 1.08);
}

void main() {
  vec2 p = FlutterFragCoord().xy / uSize - 0.5;
  p.x *= uSize.x / uSize.y;
  vec3 color;
  if (uEffect < 0.5) {
    color = heatAirflow(p);
  } else if (uEffect < 1.5) {
    color = heatHaze(p);
  } else if (uEffect < 2.5) {
    color = heatRadiance(p);
  } else if (uEffect < 3.5) {
    color = coldAirflow(p);
  } else if (uEffect < 4.5) {
    color = coldMist(p);
  } else {
    color = coldCrystal(p);
  }
  float strength = clamp(uIntensity, 0.0, 1.5);
  if (uEffect < 0.5 || (uEffect > 2.5 && uEffect < 3.5)) {
    // Airflow strength is modeled inside each effect through occupied bundles,
    // local density, and overlap. Only preserve a short fade near zero so the
    // display can reach a visually clean off state.
    float flowOn = smoothstep(0.0, 0.12, strength);
    color = mix(vec3(0.006, 0.009, 0.025), color, flowOn);
  } else {
    color = mix(vec3(0.006, 0.009, 0.025), color, strength);
  }
  color += (hash21(FlutterFragCoord().xy) - 0.5) / 255.0;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
