# First-principles report: what was done with each finding

Source: the September 2026 first-principles review of `main` at `e719d66b`,
findings F1–F6 and the hardening questions in its §6. Status as of 2026-09-21.

Two of the six describe defects in a component that no longer exists. The
playground's file-backed editor was removed in favour of the Wizard, which
generates a deck, presents it, and writes it only when the reader asks. Those
findings are recorded as retired, with what replaced them, rather than quietly
dropped.

## F1–F6

| ID | The report's finding | Status | Where |
| --- | --- | --- | --- |
| **F1** | Saved Markdown does not retain generated image bytes across restart. | **Applicable — addressed** | A save writes `<name>.md`, `<name>.assets/` and `<name>.deck.json` together. Reopening in a fresh run with an empty memory cache resolves the artwork off disk. `deck_library_durability_test.dart` |
| **F2** | Generation cleanup is not scoped to the saved deck that owns the artwork. | **Applicable — structurally prevented** | Nothing evicts artwork by key any more. Every save creates a new deck ("My talk", then "My talk 2"), so no save can touch an earlier deck's files. A→B→A ownership is asserted over a real filesystem. `deck_library_durability_test.dart`, `mac_os_deck_library_test.dart` |
| **F3** | Undo during an active autosave can leave the latest document unsaved. | **Retired** | Nothing auto-saves. The deck is written from the in-memory document when the reader saves it. The fix and its regression tests remain on `fix/playground-save-safety`, which is not in the review stack. |
| **F4** | A bullet-only slide can be consumed as frontmatter. | **Applicable — fixed** | `fix/front-matter-recognition`: a `- ` line is no longer YAML evidence on its own, and a recognized block that is not a YAML map is reported instead of silently emptied. |
| **F5** | PDF capture does not wait for asynchronous content readiness. | **Applicable — fixed** | `fix/pdf-export-readiness`: one readiness scope per slide, a bounded wait, one more frame, and a failure that names the slide and the asset. Mermaid diagrams participate: a diagram that cannot render fails the wait. |
| **F6** | Route-backed rendering and controller navigation can diverge after deck resizing. | **Applicable — fixed** | `fix/slide-route-authority`: the route is the single authority; `pageBuilder` no longer repairs state; mounted tests assert route, rendered slide, counter and actions together. |

## The report's §6 hardening questions

| Question | Status |
| --- | --- |
| **Crash-safe saving** | Addressed for the only writer left. The deck library writes Markdown, artwork and manifest each through a temporary sibling and a rename, and a failed save removes only what that save created. |
| **External-edit conflicts** | **Retired.** Nothing watches a file, and no file outside the SuperDeck folder is opened, so there is no conflict to have a policy about. |
| **Theme persistence** | Addressed. `<name>.deck.json` carries the theme's catalog id, version and density; reopening resolves it through the catalog and restores it. A selection the catalog no longer offers is reported rather than silently replaced. |
| **Platform support and CI** | Partly. CI now runs the same Dart analysis maintainers run. DCM in CI and the macOS native checks are blocked; see `analysis-parity.md` and "Platform evidence" below. |
| **Resource limits and PDF scope** | Open. Unchanged by this work: the PDF controller still holds every captured image in memory, and raster output is still the only format. |
| **AI release model and security** | Open. Unchanged: compile-time key injection, image generation on for debug and opt-in for release. |

## Platform evidence

**What ran here:** package tests on the pinned SDK (macOS host), the
deterministic generation checkpoint, and the browser smoke suite on Chromium.

**What could not run, and why — not "not run", but blocked:**

- **Any macOS app build.** `packages/playground/macos` and `demo/macos` pin
  `MACOSX_DEPLOYMENT_TARGET = 10.15` (`Podfile`: `platform :osx, '10.15'`)
  while the Xcode on this machine supports 12.0–27.0. Every macOS target fails
  the same way:

  > The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 10.15,
  > but the range of supported deployment target versions is 12.0 to 27.0.x.

  This blocks `melos run test:integration:macos` and any manual run of the
  Wizard, so the **sandbox and security-scoped bookmark behaviour of saving
  and reopening is unproven**. Everything below that layer is proven: the deck
  library tests write, list, reopen and resolve artwork on the real macOS
  filesystem, faking only the picker and bookmark calls, which cannot run
  headless anyway.

  Raising the deployment target is a supported-OS decision, deliberately left
  as an isolated follow-up rather than changed inside this work.

- **WebKit browser smoke.** `npx playwright install webkit` downloads
  `webkit-mac-15-arm64` (Playwright 1.51's build for macOS 15) and fails to
  install on this macOS 27.0 arm64 host. Chromium runs and passes; WebKit
  needs either a newer Playwright whose WebKit build supports this OS, or a
  CI runner on a supported macOS version.

- **Known intermittent check.** `the address bar follows the active slide`
  failed once in four Chromium runs at this head (and once before, on the
  previous stack, with identical routing code). When it fails, the browser URL
  never leaves `/?enable-flutter-web-semantics=true` even though the deck
  advanced, which points at Flutter web's route reporting not being installed
  yet at the moment of the first navigation, rather than at SuperDeck's route
  authority. It is not caused by the Mermaid change, and the test was left
  strict. Worth a deliberate wait-for-first-report in the harness.
