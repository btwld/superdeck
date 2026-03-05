# SuperDeck V2 Parser Semantics

## Purpose
This document turns the current authoring/parser behavior into an explicit v2 contract.

It exists to answer three questions before any rewrite code starts:
- what the current parser actually does
- which behaviors v2 must preserve
- which v1 quirks are incidental and should not become the new contract

This is the parser-level companion to:
- `.planning/rewrite-v2-full-plan.md`
- `.planning/rewrite-v2-feature-matrix.md`

## Evidence Base
Code, tests, and docs used to derive this spec:

- implementation:
  - `packages/builder/lib/src/parsers/markdown_parser.dart`
  - `packages/builder/lib/src/parsers/front_matter_parser.dart`
  - `packages/builder/lib/src/parsers/section_parser.dart`
  - `packages/builder/lib/src/parsers/block_parser.dart`
  - `packages/builder/lib/src/parsers/comment_parser.dart`
  - `packages/builder/lib/src/parsers/fenced_code_parser.dart`
  - `packages/builder/lib/src/slide_processor.dart`
  - `packages/builder/lib/src/tasks/dart_formatter_task.dart`
  - `packages/core/lib/src/tag_tokenizer.dart`
  - `packages/core/lib/src/utils/code_fence.dart`
  - `packages/core/lib/src/utils/yaml_utils.dart`
  - `packages/core/lib/src/models/block_model.dart`
  - `packages/core/lib/src/models/slide_model.dart`
- direct tests:
  - `packages/builder/test/src/parsers/*.dart`
  - `packages/builder/test/src/slide_processor_test.dart`
  - `packages/builder/test/src/markdown_utils_test.dart`
  - `packages/core/test/src/tag_tokenizer_test.dart`
  - `packages/core/test/src/utils/code_fence_test.dart`
  - `packages/core/test/src/utils/yaml_utils_test.dart`
  - `packages/core/test/src/models/block_model_test.dart`
  - `packages/core/test/src/models/deck_model_test.dart`
  - `packages/core/test/src/models/slide_model_test.dart`
- user docs:
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`
  - `docs/reference/block-types.mdx`
  - `docs/guides/custom-widgets.mdx`
  - `docs/guides/superdeck-overview.mdx`
  - `docs/examples.mdx`
  - `docs/getting-started.mdx`
  - `docs/tutorials/block-layouts.mdx`

Code wins over docs if they disagree.

## Validation Standard
For this document, a parser feature is considered:

- `validated` when current code and a direct characterization test agree, and docs do not contradict them
- `validated with docs drift` when current code and a direct characterization test agree but user docs still teach something narrower, broader, or older
- `implemented with test gap` when code exists but the behavior still lacks a direct characterization test
- `implemented with docs gap` when code and a direct characterization test exist but a user-facing authoring feature still has no user documentation

This is a strict-proof document, not a best-effort audit:

- no current-behavior claim is allowed to remain inference-only
- `implemented with test gap` is a temporary state and must be zero for sign-off
- every v2 decision must be tagged as `preserve current`, `intentional tighten`, `intentional rename`, or `intentional cleanup`

## Decision Tags
- `preserve current`: v2 keeps the current behavior as-is
- `intentional tighten`: v2 rejects or narrows currently accepted behavior
- `intentional rename`: v2 keeps the semantic behavior but changes its canonical name
- `intentional cleanup`: v2 removes an incidental quirk or hidden duplication without changing the core authoring capability

## Current Feature Validation Audit

| Stage | Feature | Implementation ref | Direct test ref | User docs ref | Status | Notes |
|---|---|---|---|---|---|---|
| slide splitting | Plain top-level `---` creates slide boundaries | `markdown_parser.dart` | `slide_parser_test.dart` | `docs/examples.mdx` | validated | Includes repeated separators and empty-slide dropping |
| slide splitting | Frontmatter delimiter pairs stay attached to the slide they configure | `markdown_parser.dart` | `slide_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Handles mixed frontmatter and plain separators |
| slide splitting | Directive-looking content is not misclassified as frontmatter | `markdown_parser.dart` | `slide_parser_test.dart` | none | validated | `@section` slide content remains normal markdown |
| slide splitting | Plain markdown with colons is not misclassified as frontmatter | `markdown_parser.dart` | `slide_parser_test.dart` | none | validated | Heuristic is tested against `API: Overview` style content |
| slide splitting | `---` inside active backtick or tilde fences does not split slides | `markdown_parser.dart`, `code_fence.dart` | `slide_parser_test.dart`, `code_fence_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Includes longer same-marker closers and unclosed fences |
| slide splitting | Blank lines inside frontmatter do not split slides | `markdown_parser.dart` | `slide_parser_test.dart` | none | validated | Current parser keeps YAML body intact |
| slide splitting | Empty input returns no slides | `markdown_parser.dart` | `slide_parser_test.dart` | none | validated | Internal behavior |
| slide splitting | Duplicate raw slides receive deterministic key suffixes | `markdown_parser.dart` | `slide_parser_test.dart` | none | validated | Internal contract, not author-authored syntax |
| frontmatter | No frontmatter leaves markdown content untouched | `front_matter_parser.dart` | `front_matter_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Normal markdown passthrough |
| frontmatter | Empty frontmatter block yields `{}` | `front_matter_parser.dart` | `front_matter_parser_test.dart`, `slide_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | `---` followed immediately by `---` |
| frontmatter | YAML maps with nested maps and lists are preserved as plain values | `front_matter_parser.dart` | `front_matter_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Docs describe passthrough YAML but not deep nested examples |
| frontmatter | Null-valued YAML keys are preserved | `front_matter_parser.dart` | `slide_parser_test.dart` | none | validated | Example: `title:` becomes `null` |
| frontmatter | `title`, `style`, and passthrough args are supported | `slide_processor.dart`, `slide_model.dart` | `slide_processor_test.dart`, `slide_model_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Current authoring docs match runtime contract |
| frontmatter | `template` and `template: none` are supported | `slide_model.dart` | `slide_model_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | User docs now describe this explicitly |
| frontmatter | Malformed YAML is a hard error | `front_matter_parser.dart` | `front_matter_parser_test.dart`, `slide_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Current code throws `FormatException` |
| frontmatter | Non-map YAML is a hard error | `front_matter_parser.dart` | `front_matter_parser_test.dart`, `slide_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | YAML lists are rejected by the parser |
| frontmatter | Missing closing delimiter silently falls back to markdown | `front_matter_parser.dart` | `front_matter_parser_test.dart` | none | validated | Real v1 quirk; v2 should not preserve it |
| frontmatter | Inline `---title:` is plain markdown, not frontmatter | `front_matter_parser.dart` | `front_matter_parser_test.dart` | none | validated | Current parser requires delimiter line semantics |
| frontmatter | Remaining markdown content is trim-normalized after frontmatter extraction | `front_matter_parser.dart`, `markdown_parser.dart` | `front_matter_parser_test.dart` | none | validated | Leading/trailing blank lines are dropped before later parser stages |
| directive tokenization | Directives only match at line start after optional indentation | `tag_tokenizer.dart` | `tag_tokenizer_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Emails and inline `@` text stay plain markdown |
| directive tokenization | Directive names support letters, digits, underscores, and hyphens | `tag_tokenizer.dart` | `tag_tokenizer_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Docs imply this via examples rather than explicit grammar |
| directive tokenization | Options may start inline, with no space, or after arbitrary whitespace/newlines | `tag_tokenizer.dart` | `tag_tokenizer_test.dart`, `packages/builder/test/src/parsers/tag_tokenizer_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | The lexer skips all intervening whitespace before `{` |
| directive tokenization | YAML options support strings, numbers, booleans, lists, and nested maps | `tag_tokenizer.dart` | `tag_tokenizer_test.dart`, `block_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Authoring examples cover the common forms |
| directive tokenization | Non-map top-level option payloads currently collapse to `{}` instead of throwing | `tag_tokenizer.dart`, `yaml_utils.dart` | `tag_tokenizer_test.dart` | none | validated | Shared YAML utility quirk; v2 should reject this explicitly |
| directive tokenization | Brace balancing is quote-aware | `tag_tokenizer.dart` | `tag_tokenizer_test.dart`, `block_parser_test.dart` | none | validated | Tested for quoted brace content |
| directive tokenization | Invalid option YAML reports a structured parse error | `tag_tokenizer.dart` | `tag_tokenizer_test.dart`, `block_parser_test.dart` | none | validated | Current tests pin tag name, source, and offset behavior |
| directive tokenization | Directives inside fenced code are ignored | `tag_tokenizer.dart`, `code_fence.dart` | `tag_tokenizer_test.dart`, `packages/builder/test/src/parsers/tag_tokenizer_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Includes language-tagged and unclosed fences |
| directive tokenization | Unclosed fences suppress later directive matches until EOF | `tag_tokenizer.dart`, `code_fence.dart` | `tag_tokenizer_test.dart` | none | validated | Important shared fence rule |
| directive tokenization | CRLF line endings are accepted | `tag_tokenizer.dart`, `markdown_parser.dart` | `tag_tokenizer_test.dart` | none | validated | Internal robustness behavior |
| section aggregation | Directive-free content becomes one implicit section with one markdown block | `section_parser.dart` | `section_parser_test.dart`, `slide_processor_test.dart` | `docs/examples.mdx`, `docs/guides/markdown-authoring.mdx` | validated | Empty content still yields a section/block container in the current parser |
| section aggregation | Free markdown before the first directive is preserved in an implicit first section | `section_parser.dart` | `section_parser_test.dart` | `docs/examples.mdx` | validated | Source order is preserved across section boundaries |
| section aggregation | `@section` starts a new section and later content attaches to that section | `section_parser.dart` | `section_parser_test.dart`, `slide_processor_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Current section structure tests cover multi-section layouts |
| section aggregation | Typed block options like `flex`, `align`, and `scrollable` fail during typed block parsing when invalid | `section_parser.dart`, `block_model.dart` | `section_parser_test.dart`, `block_model_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx`, `docs/reference/block-types.mdx` | validated | Tokenization accepts raw YAML; typed parsing enforces valid values and defaults |
| section aggregation | Trailing markdown after the last directive is trim-normalized before aggregation | `section_parser.dart` | `section_parser_test.dart` | none | validated | Current parser trims the final span only; intermediate spans keep surrounding whitespace |
| block normalization | `@section` creates section containers | `block_parser.dart`, `section_parser.dart` | `slide_processor_test.dart`, `block_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Parser and docs agree |
| block normalization | `@column` and `@block` both normalize to content blocks | `block_parser.dart`, `block_model.dart` | `block_parser_test.dart` | `docs/examples.mdx`, `docs/getting-started.mdx`, `docs/tutorials/block-layouts.mdx`, `docs/reference/block-types.mdx` | validated | Docs now lead with canonical `@block` while still documenting `@column` as a compatibility alias |
| block normalization | Unknown directive names normalize to widget shorthand blocks | `block_parser.dart` | `block_parser_test.dart` | `docs/guides/custom-widgets.mdx`, `docs/reference/block-types.mdx` | validated | Direct parser fixture now proves custom widget shorthand normalization |
| block normalization | Explicit `@widget { name: ... }` is accepted | `block_parser.dart` | `block_parser_test.dart` | `docs/guides/custom-widgets.mdx`, `docs/reference/block-types.mdx` | validated | Direct parser fixture now proves explicit widget parsing |
| block normalization | Escaped directives via `_@` are restored to literal markdown text | `section_parser.dart` | `section_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Direct parser fixture proves literal restoration before later real directives |
| comments | HTML comments parse as note/comment strings | `comment_parser.dart` | `comment_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Single, multiple, empty, and multiline comments are covered |
| comments | Comment text is trimmed and multiline comments are normalized | `comment_parser.dart` | `comment_parser_test.dart` | none | validated | Parser collapses internal whitespace |
| comments | Invalid HTML comment forms are ignored | `comment_parser.dart` | `comment_parser_test.dart` | none | validated | Current parser is intentionally selective |
| comments | Extracted comments land in `Slide.comments` | `slide_processor.dart`, `slide_model.dart` | `slide_processor_test.dart`, `slide_model_test.dart` | `docs/guides/slide-parts.mdx` | validated | Serialized contract still uses `comments` today |
| fenced-code transforms | Fenced code parsing supports backticks, tildes, options, indices, and longer closers | `fenced_code_parser.dart`, `code_fence.dart` | `fenced_code_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Shared fence behavior is well tested |
| fenced-code transforms | Brace-free YAML map options are accepted after the language token | `fenced_code_parser.dart`, `yaml_utils.dart` | `fenced_code_parser_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Docs now describe brace-free headers as legacy compatibility while keeping the braced form canonical |
| fenced-code transforms | Non-map top-level fenced-code option payloads currently collapse to `{}` instead of throwing | `fenced_code_parser.dart`, `yaml_utils.dart` | `fenced_code_parser_test.dart` | none | validated | Shared YAML utility quirk; v2 should reject this explicitly |
| fenced-code transforms | Parsed fenced-code content is trim-normalized before task consumers receive it | `fenced_code_parser.dart` | `fenced_code_parser_test.dart` | none | validated | Leading/trailing blank lines inside the fence are discarded today |
| fenced-code transforms | Unclosed fenced code blocks are not transformed | `fenced_code_parser.dart` | `fenced_code_parser_test.dart` | none | validated | Parser returns no match |
| fenced-code transforms | Mermaid blocks are transformed by the asset-generation build task | `asset_generation_pipeline.dart`, `build_command.dart` | `asset_generation_pipeline_test.dart`, mermaid generator tests | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Standard CLI/runtime build flows wire this task in by default |
| fenced-code transforms | Dart fenced blocks can be reformatted by the Dart-formatting build task | `dart_formatter_task.dart`, `build_command.dart` | `markdown_utils_test.dart` | `docs/guides/markdown-authoring.mdx`, `docs/reference/markdown-syntax.mdx` | validated | Standard CLI/runtime build flows enable this and user docs now mention it |

## Current Documentation Alignment Notes
Current parser-facing docs are now aligned with the intended v2 teaching surface:

1. Docs now lead with canonical `@block` examples and keep `@column` positioned as a compatibility alias.
2. Docs now note that brace-free fenced-code option headers still parse today as legacy compatibility, while the braced form remains the canonical syntax.

## Parser Pipeline
The current build path is effectively:

1. Split the deck markdown into raw slide buffers.
2. Extract per-slide frontmatter from each raw slide.
3. Run zero or more configured slide tasks against the slide content.
4. In standard CLI/runtime build flows, those tasks currently include Dart fenced-code formatting and Mermaid asset generation.
5. Parse the task-updated content into sections and blocks.
6. Extract HTML comments from that same final content buffer into slide notes/comments.
7. Build the typed slide contract.

This document is intentionally feature-first. Package ownership and future module boundaries belong in the full rewrite plan, not in the parser semantics contract.

## Shared Line Grammar
These rules are used by multiple parser stages and must be shared rather than reimplemented.

### Fence opener
A code fence opener is any line that matches:

- up to 3 leading spaces
- then either backticks or tildes
- with marker length >= 3

Examples:

- ```` ``` ````
- ```` ```dart ````
- `~~~`
- `  ~~~js`

### Fence closer
A code fence closer must:

- use the same marker character as the opener
- have marker length >= opener length
- have no non-whitespace trailing text after the closing marker

Examples:

- opening ```` ``` ```` can close with ```` ``` ```` or ```` ```` ````
- opening `~~~` can close with `~~~` or `~~~~`
- opening ```` ```dart ```` cannot close with ```` ```not-closing ````
- opening ```` ``` ```` cannot close with `~~~`

### Fence scope
Any parser scanning for slide delimiters or directives must ignore content while a fence is open.

Unclosed fences remain active until end-of-file. v2 should preserve that behavior so later `---` or `@tag` lines are ignored after an unclosed fence.

## Stage 1: Slide Splitting

### Proof refs
- implementation:
  - `packages/builder/lib/src/parsers/markdown_parser.dart`
  - `packages/core/lib/src/utils/code_fence.dart`
- direct tests:
  - `packages/builder/test/src/parsers/slide_parser_test.dart`
  - `packages/core/test/src/utils/code_fence_test.dart`
- user docs:
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`
  - `docs/examples.mdx`

### Observed v1 behavior
- The deck buffer is trimmed before any splitting.
- Line endings are normalized by removing `\r` during scanning.
- A slide delimiter is a line whose trimmed text is exactly `---`, as long as the parser is not inside a fenced code block.
- Empty slide buffers are dropped.
- Content before the first delimiter becomes slide 1.
- Repeated identical raw slides receive deterministic key suffixes: base hash, then `__2`, `__3`, and so on.
- When a delimiter pair looks like frontmatter, the opening delimiter, YAML body, and closing delimiter stay attached to the slide they configure.
- Directive-looking content such as `@section` and plain markdown with colons are not misclassified as frontmatter candidates.

### V2 decision
1. `[preserve current]` Normalize line endings to `\n` for parsing, and treat a line whose trimmed text is exactly `---` as a slide boundary only when no fenced code block is active.
2. `[preserve current]` Do not create empty slides from repeated separators or leading/trailing whitespace.
3. `[preserve current]` Preserve slide order exactly as authored and keep deterministic duplicate-key suffixing after splitting.
4. `[preserve current]` Keep delimiter-paired frontmatter attached to the slide it configures, flushing any buffered prior content first when needed.
5. `[preserve current]` Never treat directive-looking content or arbitrary colon-bearing markdown as frontmatter unless the raw slide starts with a real frontmatter candidate.

## Stage 2: Frontmatter Extraction

### Proof refs
- implementation:
  - `packages/builder/lib/src/parsers/front_matter_parser.dart`
  - `packages/builder/lib/src/parsers/markdown_parser.dart`
  - `packages/builder/lib/src/slide_processor.dart`
  - `packages/core/lib/src/models/slide_model.dart`
- direct tests:
  - `packages/builder/test/src/parsers/front_matter_parser_test.dart`
  - `packages/builder/test/src/parsers/slide_parser_test.dart`
  - `packages/builder/test/src/slide_processor_test.dart`
  - `packages/core/test/src/models/slide_model_test.dart`
- user docs:
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`

### Observed v1 behavior
- Frontmatter is only extracted when a raw slide starts with `---`.
- The closing delimiter is the next line whose trimmed text is `---`.
- Empty frontmatter becomes `{}`.
- Valid YAML maps are converted recursively into plain Dart maps/lists/scalars.
- YAML lists are currently recognized as frontmatter candidates during slide splitting, but the actual frontmatter parser rejects them later because frontmatter must be a map.
- Invalid YAML and non-map YAML throw `FormatException`.
- A missing closing delimiter currently degrades silently: the leading `---` is discarded and the remaining text becomes markdown content with empty frontmatter.
- The remaining markdown body is `trim()`-normalized after frontmatter removal, so leading/trailing blank lines are dropped before later parser stages.
- `title`, `style`, and `template` are first-class keys today; additional keys are passthrough slide arguments.

### V2 decision
1. `[preserve current]` Frontmatter is valid only at the start of a raw slide and is exactly an opening `---`, a YAML body, and a closing `---`.
2. `[preserve current]` Empty frontmatter means an empty map, and nested maps/lists remain allowed as values.
3. `[preserve current]` Invalid YAML and non-map YAML remain hard authoring errors.
4. `[preserve current]` `title`, `style`, and `template` remain first-class keys; other keys remain passthrough slide arguments unless a later contract layer reserves them explicitly.
5. `[intentional tighten]` A starting frontmatter delimiter without a matching closing delimiter is a hard authoring error. Reason: current fallback silently discards the opening delimiter and makes an incomplete frontmatter block parse as unrelated markdown.
6. `[intentional cleanup]` Frontmatter extraction must not `trim()`-normalize the remaining markdown body. Reason: current normalization changes authored leading/trailing whitespace before later parser stages and is not part of the authoring contract.

## Stage 3: Directive Tokenization

### Proof refs
- implementation:
  - `packages/core/lib/src/tag_tokenizer.dart`
  - `packages/core/lib/src/utils/code_fence.dart`
  - `packages/core/lib/src/utils/yaml_utils.dart`
- direct tests:
  - `packages/core/test/src/tag_tokenizer_test.dart`
  - `packages/builder/test/src/parsers/tag_tokenizer_test.dart`
  - `packages/builder/test/src/parsers/block_parser_test.dart`
- user docs:
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`

### Observed v1 behavior
- A directive match must start at the beginning of a line, allowing leading whitespace.
- The directive name pattern is `[\w-]+`.
- Options are optional.
- Option braces may begin immediately after the tag or after arbitrary intervening whitespace, including newlines.
- Directive option payloads are run through the shared YAML-to-map utility.
- Map-shaped YAML becomes a Dart map.
- Non-map top-level YAML currently degrades to `{}` instead of throwing.
- Nested braces are supported.
- Braces inside quoted strings are ignored for balance tracking.
- Tags inside fenced code blocks are ignored.
- Unclosed fenced code suppresses later directive matches until EOF.
- Invalid option YAML throws `DeckFormatException` with a source offset.
- Unclosed option braces throw `DeckFormatException` with a source offset.
- CRLF line endings are accepted.

### V2 decision
1. `[preserve current]` Recognize directives only at line start after optional indentation; mid-paragraph `@foo` text remains plain markdown.
2. `[preserve current]` Directive names may contain letters, digits, underscores, and hyphens.
3. `[preserve current]` Options remain optional, and when present the opening brace may appear after arbitrary whitespace or newlines following the directive name.
4. `[preserve current]` Brace balancing remains quote-aware.
5. `[preserve current]` Directive scanning must ignore all lines inside fenced code blocks, including the rest of the file after an unclosed fence.
6. `[preserve current]` Parse failures must report the directive name, source buffer, and failure offset.
7. `[intentional tighten]` Non-map top-level option payloads become hard parse errors instead of silent `{}`. Reason: the current shared YAML utility hides invalid scalar/list author intent by converting it to an empty map.

### Directive forms to preserve
1. `[preserve current]` `@section` and `@section { ... }` create section containers.
2. `[intentional rename]` Canonical markdown block syntax is `@block`, while `@column` remains an accepted migration alias. Reason: v1 already normalizes both to the same block type, so the rename simplifies the public contract without losing capability.
3. `[preserve current]` `@widget { name: foo, ... }` remains the explicit widget form.
4. `[preserve current]` Any directive name other than `section`, `block`, `column`, or `widget` remains widget shorthand and normalizes to a widget block whose `name` is the directive name and whose `args` are the parsed options.

## Stage 4: Block Normalization And Escapes

### Proof refs
- implementation:
  - `packages/builder/lib/src/parsers/block_parser.dart`
  - `packages/builder/lib/src/parsers/section_parser.dart`
  - `packages/core/lib/src/models/block_model.dart`
- direct tests:
  - `packages/builder/test/src/parsers/block_parser_test.dart`
  - `packages/builder/test/src/parsers/section_parser_test.dart`
  - `packages/builder/test/src/slide_processor_test.dart`
  - `packages/core/test/src/models/block_model_test.dart`
- user docs:
  - `docs/guides/custom-widgets.mdx`
  - `docs/reference/block-types.mdx`
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`

### Observed v1 behavior
- `@section` creates section containers.
- `@block` and `@column` both normalize to markdown-content blocks.
- Explicit `@widget { name: ... }` blocks are accepted.
- Any unknown directive name normalizes to widget shorthand, with the directive name becoming the widget name.
- A line whose trimmed text starts with `_@` is rewritten to start with `@` after tokenization so authors can render literal directive-looking text.

### V2 decision
1. `[preserve current]` `@section` remains the section directive.
2. `[intentional rename]` Canonical markdown block syntax is `@block`, with `@column` preserved only as a migration alias. Reason: the current implementation already treats both forms as the same normalized block.
3. `[preserve current]` Explicit `@widget { name: ... }` remains supported.
4. `[preserve current]` Widget shorthand remains supported for unknown directive names.
5. `[preserve current]` `_@foo` at the start of a logical line means literal markdown text `@foo` and must never tokenize as a real directive.
6. `[intentional cleanup]` Escape handling must happen before or during lexing rather than via later string mutation. Reason: the current post-tokenization rewrite makes offsets harder to reason about when escaped lines appear before real directives.

## Stage 5: Section Aggregation

### Proof refs
- implementation:
  - `packages/builder/lib/src/parsers/section_parser.dart`
  - `packages/builder/lib/src/parsers/block_parser.dart`
  - `packages/core/lib/src/models/block_model.dart`
- direct tests:
  - `packages/builder/test/src/parsers/section_parser_test.dart`
  - `packages/builder/test/src/parsers/block_parser_test.dart`
  - `packages/builder/test/src/slide_processor_test.dart`
  - `packages/core/test/src/models/block_model_test.dart`
- user docs:
  - `docs/examples.mdx`
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`
  - `docs/reference/block-types.mdx`

### Observed v1 behavior
- If no directives are present, the slide becomes one implicit section with one markdown block containing the whole content.
- Markdown before the first directive becomes content in an implicit first section.
- `@section` starts a new section.
- `@block` and `@column` create markdown blocks within the current section.
- Widget directives create widget blocks within the current section.
- Free markdown before, between, and after directives is preserved and attached to the nearest current section.
- Consecutive free markdown spans are merged into a single markdown block.
- Whitespace-only spans are dropped.
- Block/section option parsing is validated later by the typed block parsers, so invalid `flex`, `align`, or `scrollable` values fail there.
- The trailing free-markdown span after the last directive is currently `trim()`-normalized before aggregation, unlike earlier spans.

### V2 decision
1. `[preserve current]` Every slide yields at least one section with an ordered list of blocks.
2. `[preserve current]` Free markdown before any directive becomes a markdown block in an implicit first section.
3. `[preserve current]` Each `@section` starts a fresh section boundary, and later blocks/content attach to the current section in source order.
4. `[preserve current]` Free markdown between directives is retained in source order, adjacent markdown spans in the same section are merged, and whitespace-only spans produced by structural parsing are discarded.
5. `[preserve current]` Typed block-option validation for fields such as `flex`, `align`, and `scrollable` remains a hard error in the typed block layer.
6. `[intentional cleanup]` Remove the current trailing-span-only `trim()` normalization. Reason: v1 trims only the final free-markdown span after the last directive, which makes content preservation asymmetric for otherwise equivalent spans.
7. `[intentional cleanup]` Preserve markdown text exactly apart from line-ending normalization, escaped-directive unescaping, and removal of empty structural spans. Reason: current frontmatter and section stages apply selective `trim()` calls that are incidental, not author intent.

## Stage 6: Notes Extraction

### Proof refs
- implementation:
  - `packages/builder/lib/src/parsers/comment_parser.dart`
  - `packages/builder/lib/src/slide_processor.dart`
  - `packages/core/lib/src/models/slide_model.dart`
- direct tests:
  - `packages/builder/test/src/parsers/comment_parser_test.dart`
  - `packages/builder/test/src/slide_processor_test.dart`
  - `packages/core/test/src/models/slide_model_test.dart`
- user docs:
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`
  - `docs/guides/slide-parts.mdx`

### Observed v1 behavior
- HTML comments `<!-- ... -->` are extracted into slide comments.
- Multi-line comments are normalized by trimming each line, dropping empty lines, and joining the remaining lines with a single space.
- Empty comments are preserved as empty strings.
- Invalid comment-like text is ignored.
- Comments are extracted from slide content after build tasks run.
- The comment markup remains present in the markdown content buffer used for section parsing.

### V2 decision
1. `[intentional rename]` The canonical semantic field is `notes` rather than `comments`. Reason: HTML comments are authoring notes, not public markdown content semantics.
2. `[preserve current]` `<!-- ... -->` inside slide source produces ordered note entries.
3. `[preserve current]` Multi-line note text is normalized to a single-space-joined string, empty notes remain allowed, and invalid comment-like sequences are ignored.
4. `[preserve current]` Note extraction remains part of build-time authoring parsing rather than a runtime concern.
5. `[intentional cleanup]` Remove note comments from markdown content after extraction. Reason: v1 duplicates the same semantic note in both extracted metadata and the markdown buffer.

## Stage 7: Fenced Code Block Parsing For Build Tasks
Build tasks still need direct fenced-code parsing after slide splitting, so the fence contract must be explicit.

### Proof refs
- implementation:
  - `packages/builder/lib/src/parsers/fenced_code_parser.dart`
  - `packages/builder/lib/src/tasks/dart_formatter_task.dart`
  - `packages/builder/lib/src/build/asset_generation_pipeline.dart`
  - `packages/cli/lib/src/commands/build_command.dart`
  - `packages/core/lib/src/utils/code_fence.dart`
  - `packages/core/lib/src/utils/yaml_utils.dart`
- direct tests:
  - `packages/builder/test/src/parsers/fenced_code_parser_test.dart`
  - `packages/builder/test/src/markdown_utils_test.dart`
  - `packages/builder/test/src/build/asset_generation_pipeline_test.dart`
  - mermaid generator tests
- user docs:
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`

### Observed v1 behavior
- Both backtick and tilde fences are supported.
- The opening header is parsed as a first-token language plus a rest-of-line option string.
- Fenced-code option payloads are run through the shared YAML-to-map utility.
- Map-shaped YAML becomes a Dart map.
- Brace-free YAML map options are accepted after the language token.
- Non-map top-level YAML currently degrades to `{}` instead of throwing.
- Empty options are allowed.
- Invalid option YAML throws.
- Unclosed fences produce no parsed block result.
- Parsed fenced-code content is `trim()`-normalized before build tasks receive it, so leading/trailing blank lines inside the fence are discarded.
- Standard CLI/runtime build flows currently use these parsed blocks for Mermaid asset generation and Dart code formatting.

### V2 decision
1. `[preserve current]` Support backtick and tilde fences, longer matching closing fences, optional language, and no match for unclosed fences.
2. `[preserve current]` Continue using YAML map options for build-task metadata and keep invalid option YAML as a hard failure.
3. `[intentional tighten]` Canonical fenced-code headers require the explicit braced map form when options are present, for example ```` ```dart {lineLength: 80} ````. Reason: v1 also accepts brace-free rest-of-line YAML maps after the language token, but that widens the grammar beyond what docs teach and is not needed for a stable contract.
4. `[intentional tighten]` Non-map top-level option payloads are hard errors instead of silent `{}`. Reason: the current shared YAML utility hides invalid scalar/list option payloads by converting them to empty maps.
5. `[intentional cleanup]` Do not `trim()`-normalize fenced-code bodies at parser level. Reason: current normalization drops authored leading/trailing blank lines before build tasks can decide whether that whitespace matters.
6. `[preserve current]` Standard build flows may continue to consume parsed fenced-code blocks for Mermaid asset generation and Dart code formatting; the parser contract stops at normalized fenced-code extraction.

## Stage 8: Documentation Sync

### Proof refs
- user docs:
  - `docs/guides/markdown-authoring.mdx`
  - `docs/reference/markdown-syntax.mdx`
  - `docs/reference/block-types.mdx`
  - `docs/guides/custom-widgets.mdx`
  - `docs/examples.mdx`
  - `docs/getting-started.mdx`
  - `docs/tutorials/block-layouts.mdx`

### Observed v1 behavior
- User docs now cover frontmatter, escaped directives, HTML-comment speaker notes, `template`, `@block` as an accepted alias, and Dart fenced-code formatting in standard build flows.
- Docs now lead with canonical `@block` while still documenting `@column` as a compatibility alias.
- Fenced-code docs now mention brace-free option headers only as legacy compatibility, while teaching the braced form as canonical.

### V2 decision
1. `[intentional cleanup]` Docs should teach the stable v2 contract rather than every incidental permissive v1 parsing path. Reason: the docs are the user-facing grammar, so they should lead with canonical forms even when v1 currently accepts looser input.
2. `[preserve current]` User docs should continue to describe implemented authoring behavior where that behavior is part of the supported surface today, including frontmatter, comments-as-notes authoring, widget forms, and Dart fenced-code formatting in standard build flows.

## Typed Output Contract
This is the normalized v2 handoff shape implied by the stage decisions above.

### Decision status
- `[intentional rename]` The canonical slide note field is `notes`, even though the current serialized/runtime surface still uses `comments`. Reason: the normalized parser contract should use the semantic name before migration wiring decides final artifact-field compatibility.
- `[intentional rename]` The canonical markdown block type is `block`, with `@column` preserved only as a migration alias. Reason: the current parser already normalizes both forms to the same semantic block.
- `[preserve current]` Section and block layout fields remain `align`, `flex`, and `scrollable`.

The parser pipeline should hand off a normalized authoring result with these semantics:

- deck
  - ordered slides
- slide
  - `key`
  - `options`
  - `sections`
  - `notes`
- section
  - `align?`
  - `flex`
  - `scrollable`
  - `blocks`
- markdown block
  - canonical type `block`
  - `align?`
  - `flex`
  - `scrollable`
  - source markdown content
- widget block
  - canonical type `widget`
  - `align?`
  - `flex`
  - `scrollable`
  - widget name
  - typed/raw args

The contract migration doc can define final serialized field names and artifact filenames, but parser semantics should already assume canonical `notes` and canonical `block`.

## V1 Incidental Behaviors To Avoid Carrying Forward
These behaviors exist today but should be treated as implementation quirks, not v2 contract:

1. Frontmatter candidate detection is separate from frontmatter validation and currently accepts some shapes that are rejected later.
2. A missing frontmatter closing delimiter silently degrades to plain markdown.
3. Raw slide markdown content is trim-normalized during frontmatter extraction/materialization.
4. Escaped directive handling mutates content after directive positions were computed.
5. Notes remain duplicated in both extracted metadata and markdown content.
6. Section aggregation trims the trailing post-last-directive span differently from earlier spans.
7. Shared YAML option parsing currently collapses non-map top-level option payloads to `{}` instead of failing.
8. Fenced-code parsing accepts brace-free YAML map options after the language token as legacy compatibility, even though the braced form is the canonical contract.
9. Fenced-code content is trim-normalized before build tasks receive it.

## Required Parser Fixture Coverage Before Implementation
V2 should not start without parser fixtures for all of the following:

1. Slide splitting with top-level `---` and fenced-code exceptions for both backticks and tildes.
2. Frontmatter map parsing, empty frontmatter, invalid YAML, non-map YAML, and missing closing delimiter.
3. Deterministic slide key collision suffixing.
4. Directive tokenization with:
   - same-line options
   - next-line options
   - nested maps/lists
   - non-map top-level option payload rejection
   - quoted braces
   - source-located failures
5. Ignoring directives inside fenced code blocks, including unclosed fences.
6. `@block` canonicalization and `@column` compatibility behavior.
7. Widget shorthand normalization and explicit `@widget` handling.
8. Escaped directives before later real directives.
9. Mixed free markdown before, between, and after directives.
10. Note extraction, multiline normalization, invalid comment-like text, and note removal from markdown content.
11. Fenced-code option parsing with braced headers, current brace-free header acceptance, invalid YAML, non-map top-level option payload rejection, and unclosed fences.

## Strict-Proof Sign-Off Status
- Zero `implemented with test gap` rows remain in the feature validation audit.
- Every stage section now separates observed v1 behavior from tagged v2 decisions and includes explicit proof refs.
- No unintentional user-facing parser-semantics drift remains; docs now distinguish canonical syntax from legacy compatibility explicitly.
- The focused parser validation set across `packages/builder` and `packages/core` is green as of 2026-03-05.

## Decisions Frozen By This Document
This document freezes the following parser-level v2 decisions:

- frontmatter is YAML-map-only and invalid frontmatter is a hard error
- a missing frontmatter closing delimiter is a hard error
- canonical markdown block syntax is `@block`
- `@column` remains a migration alias, not the canonical name
- canonical semantic note field is `notes`
- HTML comments are authoring notes, not renderable markdown content
- fence handling is shared across slide splitting, directive tokenization, and fenced-code parsing

Remaining migration details such as artifact renames and public API naming belong in `.planning/rewrite-v2-contract-migration-matrix.md`.
