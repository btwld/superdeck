## Unreleased

* **New package `superdeck_deploy`** with a standalone `superdeck-deploy` executable that publishes a built deck to GitHub Pages (`github-pages`) or Firebase Hosting (`firebase`).
* **Breaking:** deployment is no longer part of the `superdeck` CLI. Install and run `superdeck-deploy` separately (`dart pub global activate superdeck_deploy`).

## 1.0.0

* First stable release of SuperDeck
* Roll back experimental setext-heading hero parsing; ATX headers continue to use the shared helper
* Fix image hero-tag parsing to avoid inline parser overruns and keep Flutter/core paths aligned
* Document the shared `{.hero}` helper and scope so future contributions stay consistent

### 0.0.4

* Fix: Better error handling when external asset tooling is not installed
* Enhancement: Improved asset generation pipeline

### 0.0.3

* Cleaned up dependencies
* Updated example code
* Improved logging
* Fixed and improved asset generation

## 0.0.2

* Added demo and example code

## 0.0.1

* Initial version
