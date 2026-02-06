# SuperDeck documentation process

## Purpose

This document is the source of truth for how SuperDeck documentation is written, organized, and reviewed.

Goals:

- Keep docs aligned with the codebase and CLI behavior.
- Organize docs by user need (tutorials, how-to, reference, explanation).
- Apply consistent technical writing style based on the Google developer style guide.
- Enforce quality with CI checks.

## Source standards

- Diataxis: https://diataxis.fr/
- Google developer documentation style guide: https://developers.google.com/style/highlights

## Information architecture

SuperDeck docs are grouped by intent, not by implementation details.

### Tutorials

Use tutorials to teach by doing. Tutorials are linear and outcome-driven.

- `docs/getting-started.mdx`
- `docs/tutorials/first-presentation.mdx`

### How-to guides

Use how-to guides to help users complete specific tasks.

- `docs/tutorials/block-layouts.mdx`
- `docs/guides/custom-widgets.mdx`
- `docs/guides/markdown-authoring.mdx`
- `docs/guides/mermaid-diagrams.mdx`
- `docs/guides/slide-parts.mdx`
- `docs/guides/widget-size-guide.mdx`

### Reference

Use reference docs for exact, complete, declarative information.

- `docs/reference/block-types.mdx`
- `docs/reference/deck-options.mdx`
- `docs/reference/markdown-syntax.mdx`
- `docs/guides/cli-reference.mdx` (legacy path, reference intent)

### Explanation

Use explanation docs to build understanding and context.

- `docs/index.mdx`
- `docs/guides/superdeck-overview.mdx`
- `docs/examples.mdx`

## Writing rules (Google style, adapted)

### Voice and tense

- Use active voice.
- Use present tense.
- Use second person (`you`) for instructional content.

### Headings

- Use sentence case headings.
- Do not encode step numbers in headings.
- Keep exactly one H1 per page.

### Procedures

- Start each step with an imperative verb.
- Use numbered lists for procedures, not numbered headings.
- Keep prerequisites explicit.

### Timelessness

- Avoid fragile time words like “currently”, “new”, “soon”.
- If time context is required, provide a concrete date.

### Reference writing

- Keep reference pages declarative and complete.
- Avoid procedural language (`Step 1`, “follow these steps”).

## Review checklist (required for docs PRs)

- [ ] Each changed page has a single clear intent.
- [ ] Headings are sentence case.
- [ ] No numbered headings.
- [ ] Internal absolute links resolve.
- [ ] Reference pages do not contain `Step N` walkthrough language.
- [ ] `npx @docs.page/cli check` passes.
- [ ] `node tools/docs/check-docs.mjs` passes.

## CI quality gates

Docs CI validates:

- docs.page structure (`npx @docs.page/cli check`)
- SuperDeck docs quality rules (`node tools/docs/check-docs.mjs`)

## Change management

When adding a new docs page:

1. Choose the page intent first (tutorial/how-to/reference/explanation).
2. Add frontmatter keys required by docs.page (`title`, `description`).
3. Place the page in the matching sidebar group in `docs.json`.
4. Link from at least one related page.
5. Run docs checks locally before opening a PR.
