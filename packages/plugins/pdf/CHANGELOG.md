## 1.0.0

- Extract PDF export support from `superdeck` into `superdeck_pdf`.
- Provide the `pdfActions()` and `pdfExportAction()` runtime plugin entrypoints,
  plus `PdfSaver` for custom save behavior.
- Depend on public SuperDeck rendering and capture APIs instead of internal
  `superdeck/src` imports.
