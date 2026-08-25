## 1.0.0

- **Breaking:** require `superdeck` and `superdeck_core` 1.0.0 as part of the
  coordinated Ack 1.2 migration.

- Capture PDF slide images with good quality on all platforms.
- Use `FileSaver.saveFile` for default PDF saves on web and Linux, and surface
  unexpected save failures as export failures.

- Extract PDF export support from `superdeck` into `superdeck_pdf`.
- Provide the `PdfPlugin` runtime plugin entrypoint, plus `PdfExportOptions`
  and `PdfSaver` for custom save behavior.
- Depend on public SuperDeck rendering and capture APIs instead of internal
  `superdeck/src` imports.
