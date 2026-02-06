## Summary

- 

## Changes

- 

## Validation

- [ ] `npx @docs.page/cli check`
- [ ] `node tools/docs/check-docs.mjs`
- [ ] `dart analyze` / `melos run analyze:dart` (if code changed)
- [ ] `flutter test` / `melos exec -- flutter test` (if code changed)

## Docs checklist (required when docs changed)

- [ ] Every changed docs page includes frontmatter: `title`, `description`
- [ ] Each changed page has a single clear intent (`tutorial`, `how-to`, `reference`, or `explanation`)
- [ ] Headings use sentence case
- [ ] No numbered headings (for example, `## Step 1`)
- [ ] Internal links were verified
- [ ] Reference pages do not include procedural `Step N` walkthrough language
- [ ] Sidebar organization in `docs.json` still matches Diataxis grouping
