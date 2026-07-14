#version 460 core
#include <flutter/runtime_effect.glsl>

// Slot table — keep in sync with _VolumetricSmokePainter:
uniform vec2 uSize;       // setFloat 0, 1
uniform float uTime;      // setFloat 2
uniform float uIntensity; // setFloat 3
uniform float uQuality;   // setFloat 4 (0.0 = 12 steps, 1.0 = 24 steps)
out vec4 fragColor;

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash31(vec3 p) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise31(vec3 p) {
  vec3 cell = floor(p);
  vec3 local = fract(p);
  local = local * local * (3.0 - 2.0 * local);

  float n000 = hash31(cell);
  float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
  float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
  float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));
  float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
  float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
  float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
  float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));

  return mix(
    mix(mix(n000, n100, local.x), mix(n010, n110, local.x), local.y),
    mix(mix(n001, n101, local.x), mix(n011, n111, local.x), local.y),
    local.z
  );
}

vec2 rotate2d(vec2 p, float angle) {
  float sine = sin(angle);
  float cosine = cos(angle);
  return vec2(
    cosine * p.x - sine * p.y,
    sine * p.x + cosine * p.y
  );
}

// Four spatial scales with a time cascade: small wisps evolve faster than
// broad billows, and every octave advects through a different velocity field.
float turbulentFbm(vec3 p, float time) {
  float value = 0.0;
  float amplitude = 0.5;
  float rate = 1.0;
  for (int i = 0; i < 4; i++) {
    vec3 drift = vec3(0.021, 0.055, -0.016) * time * rate;
    value += amplitude * noise31(p + drift);
    p = vec3(
      0.80 * p.y + 0.60 * p.z,
      -0.80 * p.x + 0.36 * p.y - 0.48 * p.z,
      -0.60 * p.x - 0.48 * p.y + 0.64 * p.z
    ) * 2.03 + vec3(1.7, 9.2, 3.1);
    amplitude *= 0.5;
    rate *= 1.62;
  }
  return value;
}

// The light tap only needs the broad density. Scaling the two-octave sum to
// the same range as turbulentFbm keeps its extinction estimate unbiased.
float coarseFbm(vec3 p, float time) {
  float value = 0.0;
  float amplitude = 0.5;
  float rate = 1.0;
  for (int i = 0; i < 2; i++) {
    vec3 drift = vec3(0.021, 0.055, -0.016) * time * rate;
    value += amplitude * noise31(p + drift);
    p = vec3(
      0.80 * p.y + 0.60 * p.z,
      -0.80 * p.x + 0.36 * p.y - 0.48 * p.z,
      -0.60 * p.x - 0.48 * p.y + 0.64 * p.z
    ) * 2.03 + vec3(1.7, 9.2, 3.1);
    amplitude *= 0.5;
    rate *= 1.62;
  }
  return value * 1.25;
}

vec3 aces(vec3 color) {
  return clamp(
    (color * (2.51 * color + 0.03)) /
        (color * (2.43 * color + 0.59) + 0.14),
    0.0,
    1.0
  );
}

// The unnormalized form evaluates to 1.0 for isotropic scattering. A strong
// forward lobe plus a weak backward lobe gives smoke its characteristic bright
// rim while keeping the camera-facing side readable.
float henyeyGreenstein(float cosineTheta, float anisotropy) {
  float anisotropySquared = anisotropy * anisotropy;
  float denominator = max(
    1.0 + anisotropySquared - 2.0 * anisotropy * cosineTheta,
    0.001
  );
  return (1.0 - anisotropySquared) / pow(denominator, 1.5);
}

float smokePhase(float cosineTheta) {
  float forward = henyeyGreenstein(cosineTheta, 0.52);
  float backward = henyeyGreenstein(cosineTheta, -0.20);
  return clamp(mix(backward, forward, 0.72), 0.32, 2.40);
}

// Wider scattering orders return a controlled amount of cool light to dense
// cores. This mimics multiple scattering without another shadow march.
float multipleScattering(float opticalDepth) {
  return
      exp(-opticalDepth) * 0.62 +
      exp(-opticalDepth * 0.35) * 0.28 +
      exp(-opticalDepth * 0.12) * 0.10;
}

float plumeEnvelope(vec3 position, float time) {
  float height = (position.y + 0.78) / 1.82;
  if (height <= 0.0 || height >= 1.0) return 0.0;

  // Staggered buoyant parcels rise, expand, drift, and dissolve. Their compact
  // ellipsoid fields overlap into one plume but leave readable rolling lobes;
  // unlike a tapered cylinder, the silhouette is not a flat cone.
  float field = 0.0;
  for (int i = 0; i < 5; i++) {
    float parcel = float(i);
    float age = fract(parcel * 0.20 + time * 0.018);
    float expansion = pow(age, 0.72);
    float centerY = -0.70 + age * 1.58;
    float sway = sin(age * 5.4 - time * 0.095 + parcel * 1.7) *
        (0.035 + expansion * 0.15);
    sway += sin(age * 11.0 + time * 0.045 + parcel) *
        expansion * 0.035;
    float depthSway = cos(age * 6.2 + time * 0.060 + parcel * 2.1) *
        expansion * 0.085;
    vec3 radius = vec3(
      0.10 + expansion * 0.40,
      0.17 + expansion * 0.17,
      0.09 + expansion * 0.29
    );
    vec3 delta = (position - vec3(sway, centerY, depthSway)) / radius;
    float compactField = max(0.0, 1.0 - dot(delta, delta));
    float life = smoothstep(0.0, 0.08, age) *
        (1.0 - smoothstep(0.76, 1.0, age));
    field += compactField * compactField * life;
  }

  // Keep freshly emitted smoke connected to the first rising parcel.
  float sourceHeight = smoothstep(-0.78, -0.68, position.y) *
      (1.0 - smoothstep(-0.43, -0.28, position.y));
  float sourceRadius = length(position.xz / vec2(0.095, 0.080));
  float source = sourceHeight * (1.0 - smoothstep(0.48, 1.10, sourceRadius));
  return clamp(
    max(smoothstep(0.045, 0.38, field), source * 0.72),
    0.0,
    1.0
  );
}

vec3 smokeDomain(vec3 position, float time) {
  float height = clamp((position.y + 0.78) / 1.82, 0.0, 1.0);
  float riseSpeed = 0.05 + height * 0.13;
  float expansion = 1.0 + height * 0.62;
  vec3 domain = position;

  // Buoyancy accelerates with height. Paired lateral eddies roll the density
  // field as it rises, so material curls rather than scrolling as a texture.
  domain.y += time * riseSpeed;
  domain.x += sin(position.y * 4.6 + time * 0.075) *
      (0.025 + height * 0.075);
  domain.z += sin(position.y * 3.7 - time * 0.058) *
      (0.020 + height * 0.060);
  float roll = sin(position.y * 3.1 - time * 0.065) *
      (0.08 + height * 0.16);
  domain.xz = rotate2d(domain.xz, roll);
  domain.xz /= expansion;
  return domain;
}

float shapeDensity(float field, float envelope, float height) {
  float threshold = mix(0.46, 0.51, height);
  float signedDensity = field + envelope * 0.20 - threshold;
  float billows = smoothstep(-0.055, 0.155, signedDensity);
  float core = smoothstep(0.065, 0.255, signedDensity);
  return clamp((billows * 0.76 + core * 0.24) * envelope, 0.0, 1.0);
}

float smokeDensity(vec3 position, float time) {
  float envelope = plumeEnvelope(position, time);
  if (envelope <= 0.008) return 0.0;

  float height = clamp((position.y + 0.78) / 1.82, 0.0, 1.0);
  vec3 domain = smokeDomain(position, time);
  float field = turbulentFbm(domain * 1.92, time);
  float erosion = noise31(
    domain * 5.2 + vec3(time * 0.035, -time * 0.052, time * 0.024)
  );
  field -= (erosion - 0.46) * mix(0.15, 0.045, envelope);
  return shapeDensity(field, envelope, height);
}

float shadowDensity(vec3 position, float time) {
  float envelope = plumeEnvelope(position, time);
  if (envelope <= 0.008) return 0.0;

  float height = clamp((position.y + 0.78) / 1.82, 0.0, 1.0);
  vec3 domain = smokeDomain(position, time);
  return shapeDensity(coarseFbm(domain * 1.92, time), envelope, height);
}

vec2 intersectBox(vec3 rayOrigin, vec3 rayDirection) {
  vec3 boundsMin = vec3(-1.02, -0.82, -0.72);
  vec3 boundsMax = vec3(1.02, 1.08, 0.72);
  vec3 safeDirection = mix(
    vec3(0.0001),
    rayDirection,
    step(vec3(0.0001), abs(rayDirection))
  );
  vec3 nearTimes = (boundsMin - rayOrigin) / safeDirection;
  vec3 farTimes = (boundsMax - rayOrigin) / safeDirection;
  vec3 entry = min(nearTimes, farTimes);
  vec3 exit = max(nearTimes, farTimes);
  return vec2(
    max(max(entry.x, entry.y), entry.z),
    min(min(exit.x, exit.y), exit.z)
  );
}

vec3 background(vec2 p) {
  float vertical = smoothstep(-0.52, 0.52, p.y);
  return mix(
    vec3(0.003, 0.005, 0.011),
    vec3(0.009, 0.014, 0.024),
    vertical
  );
}

vec3 renderSmoke(vec2 p, float time) {
  vec3 rayOrigin = vec3(0.0, -0.18, -2.85);
  vec3 rayDirection = normalize(vec3(p.x, -(p.y - 0.07) * 0.95, 1.52));
  vec2 hit = intersectBox(rayOrigin, rayDirection);
  vec3 sceneBackground = background(p);
  float entry = max(hit.x, 0.0);
  if (hit.y <= entry) return sceneBackground;

  // Quality changes occupied-sample cost without changing the physical light
  // integration. Spatially interleaved, slightly irregular spacing prevents
  // the lower tiers from lining up as visible depth slices.
  float marchSteps = floor(mix(12.0, 24.0, clamp(uQuality, 0.0, 1.0)) + 0.5);
  float stepSize = (hit.y - entry) / marchSteps;
  float rayJitter = hash21(FlutterFragCoord().xy + vec2(19.1, 7.7));
  float distance = entry +
      rayJitter * stepSize;
  // A high, slightly rearward key light exposes extinction through the plume
  // and gives thin edges the forward-scattered silver lining seen in smoke.
  vec3 lightDirection = normalize(vec3(-0.58, 0.68, 0.42));
  float phase = smokePhase(dot(rayDirection, lightDirection));
  vec3 scatteredLight = vec3(0.0);
  float transmittance = 1.0;

  for (int i = 0; i < 24; i++) {
    if (float(i) >= marchSteps || distance >= hit.y) break;
    vec3 position = rayOrigin + rayDirection * distance;
    float density = smokeDensity(position, time);
    if (density > 0.008) {
      // One sample toward the key light supplies both a directional density
      // gradient (the visible billow face) and an extinction estimate.
      float densityTowardLight = shadowDensity(
        position + lightDirection * 0.24,
        time
      );
      float facingLight = smoothstep(
        -0.08,
        0.24,
        density - densityTowardLight
      );
      float lightOpticalDepth = densityTowardLight * 4.8 + density * 0.75;
      float lightVisibility = multipleScattering(lightOpticalDepth);
      float powder = 1.0 - exp(-density * 3.2);
      float rim = facingLight * (1.0 - smoothstep(0.48, 0.92, density));
      float height = clamp((position.y + 0.78) / 1.82, 0.0, 1.0);
      float depth = clamp(
        (distance - entry) / max(hit.y - entry, 0.001),
        0.0,
        1.0
      );

      vec3 coolAmbient = mix(
        vec3(0.028, 0.045, 0.072),
        vec3(0.075, 0.105, 0.145),
        height
      );
      vec3 warmKey = mix(
        vec3(0.86, 0.80, 0.70),
        vec3(0.70, 0.75, 0.80),
        depth * 0.42
      );
      float direct = lightVisibility * phase *
          mix(0.18, 1.0, facingLight) *
          mix(0.38, 1.0, powder);
      vec3 incidentLight = coolAmbient * (0.72 + lightVisibility * 0.28);
      incidentLight += warmKey * direct;
      incidentLight += vec3(0.38, 0.46, 0.58) *
          rim * lightVisibility * 0.26;

      // Beer-Lambert extinction and the closed-form integral over this ray
      // segment make brightness independent of the chosen march step length.
      float opticalDepth = density * stepSize * 2.35;
      float segmentTransmittance = exp(-opticalDepth);
      float segmentScatter = (1.0 - segmentTransmittance) * 0.94;
      scatteredLight += transmittance * segmentScatter * incidentLight;
      transmittance *= segmentTransmittance;
      if (transmittance < 0.025) break;
    }
    float spacingJitter = fract(rayJitter + float(i) * 0.6180339);
    distance += stepSize * mix(0.88, 1.12, spacingJitter);
  }

  return sceneBackground * transmittance + scatteredLight;
}

void main() {
  vec2 p = FlutterFragCoord().xy / uSize - 0.5;
  p.x *= uSize.x / uSize.y;
  float time = mod(uTime, 120.0);

  vec3 color = aces(renderSmoke(p, time) * 1.34);
  color *= 1.0 - smoothstep(0.56, 1.36, length(p)) * 0.34;
  float luminance = dot(color, vec3(0.299, 0.587, 0.114));
  color = mix(
    color,
    vec3(luminance),
    smoothstep(0.48, 1.0, luminance) * 0.30
  );
  color = mix(
    vec3(0.006, 0.009, 0.025),
    color,
    clamp(uIntensity, 0.0, 1.5)
  );
  color += (hash21(FlutterFragCoord().xy) - 0.5) / 255.0;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
