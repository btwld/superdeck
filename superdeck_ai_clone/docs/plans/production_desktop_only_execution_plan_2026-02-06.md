# Desktop-Only Execution Plan v3 (Trimmed)

Date: 2026-02-06  
Repository: `/Users/leofarias/Concepta/superdeck_ai`

## Summary

This version keeps only desktop-release execution items.  
Web re-enable work and SuperDeck package web work stay deferred in:
`/Users/leofarias/Concepta/superdeck_ai/docs/plans/future_superdeck_web_support_plan_2026-02-06.md`

Release scope for this plan: **macOS/Linux/Windows only**.

## What Is Already Done

1. Web runtime is blocked at startup with a dedicated unsupported screen in `lib/main.dart`.
2. README declares web unsupported and desktop-only support.
3. Default chat model remains `models/gemini-3-flash-preview` by product decision.

## Required Work (Desktop-Only)

### Workstream A: Reproducible Build Inputs

1. Stop requiring runtime/local files as Flutter assets in `pubspec.yaml`:
- remove `.env`
- remove `.superdeck/`
- remove `.superdeck/assets/`
- remove `.superdeck/examples/`
2. Add static examples under `assets/examples/` and include that path in `pubspec.yaml`.
3. Update example lookup constants/loaders:
- `lib/core/constants/paths.dart`
- `lib/core/ai/prompts/examples_loader.dart`
4. Keep runtime-generated `.superdeck/*` as filesystem output only (not bundled assets).

### Workstream B: CI Cleanup for Desktop

1. Remove placeholder fabrication in `.github/workflows/test.yml`:
- `touch .env`
- `mkdir -p .superdeck/assets/`
2. Keep required blocking checks:
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
3. Add a desktop smoke build check (Linux):
- install Linux desktop prerequisites
- run `flutter build linux --debug`

### Workstream C: Release Verification

1. Clean clone passes without manual file creation:
- `flutter pub get`
- `flutter analyze`
- `flutter test`
2. Desktop smoke build passes in CI.
3. App boots and core generation flow works on desktop target(s).

## Explicitly Deferred (Not Needed for This Desktop Cut)

1. Any web runtime enablement work.
2. Any SuperDeck/SuperDeck Core upstream package API changes.
3. Chat fallback redesign/replay semantics.
4. Retry policy expansion beyond current behavior.
5. Security gate expansion (`gitleaks`, `osv-scanner`) for this cut.
6. Ops/legal documentation package as a release blocker for this cut.

## Public Interface Impact

1. No public API changes.
2. No SuperDeck package changes in this cycle.
3. Asset contract for examples changes from `.superdeck/examples/` to `assets/examples/`.

## Acceptance Criteria

1. Desktop-only scope is preserved (web remains intentionally unsupported).
2. CI no longer fabricates `.env` or `.superdeck/assets/`.
3. Repository builds/tests from clean clone without hidden local files.
4. Desktop smoke build is green in CI.
5. Existing unit tests remain green.

## Assumptions

1. Product keeps preview model as default for now (`models/gemini-3-flash-preview`).
2. Desktop release speed is prioritized over broader production hardening.
3. Deferred items can be planned as a follow-up hardening pass.
