# Theme qualification goldens

These three contact sheets are the reviewed 1280×720 renderer baselines for the
featured editorial, technical, and bold theme directions. The opt-in live test
loads each theme's declared Google fonts, renders the deterministic ten-slide
fixture, and compares every decoded RGBA byte with these files.

Run the gate from `packages/playground`:

```bash
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define=LIVE_THEME_QUALIFICATION=true \
  --reporter expanded
```

When an intentional theme change produces a mismatch, inspect all generated
full-size slides and the new contact sheets under
`test_live/ai_generation/artifacts/`. Replace a baseline only after that visual
review; do not update it solely to make the test pass.
