# Gemini Structured Output & Schema Descriptors Research

## Overview

Google's Gemini API supports **structured output** that guarantees JSON responses conform to a provided schema. This feature enables predictable, parsable results with format/type safety.

## Schema Specification

Gemini's structured output uses a **subset of the OpenAPI 3.0 Schema specification**. Two schema formats are supported:

| Format | Use Case |
|--------|----------|
| `responseSchema` | OpenAPI-based, simpler schemas |
| `responseJsonSchema` | Full JSON Schema with `$ref`, `anyOf`, advanced validation |

### Supported Schema Fields

```json
{
  "type": "OBJECT | STRING | NUMBER | INTEGER | BOOLEAN | ARRAY | NULL",
  "format": "date | date-time | duration | time | int64 | double",
  "title": "Short property description",
  "description": "Detailed guidance for the model",
  "nullable": true,
  "enum": ["option1", "option2"],
  "pattern": "regex-pattern",
  "minimum": 0,
  "maximum": 100,
  "minLength": 1,
  "maxLength": 255,
  "properties": { "key": { /* nested schema */ } },
  "required": ["field1", "field2"],
  "propertyOrdering": ["field1", "field2"],
  "items": { /* schema for array elements */ },
  "minItems": 1,
  "maxItems": 10,
  "anyOf": [{ /* alternative schemas */ }],
  "example": "example value",
  "default": "default value"
}
```

### Type Values

| Type | Description |
|------|-------------|
| `STRING` | Text content |
| `NUMBER` | Floating-point values |
| `INTEGER` | Whole numbers |
| `BOOLEAN` | True/false values |
| `OBJECT` | Key-value structures |
| `ARRAY` | Lists of items |
| `NULL` | Null values (use with nullable: true) |

---

## Three Layers of Output Control

Understanding the distinction between constraints, descriptions, and prompt guidance is critical for optimal results.

### Layer 1: Schema Constraints (Hard - Enforced)

These are **strictly enforced** by Gemini's constrained decoding:

| Constraint | Effect | Example |
|------------|--------|---------|
| `type` | Enforces data type | `Schema.string()`, `Schema.integer()` |
| `enum` | Restricts to specific values | `enumValues: ['block', 'widget']` |
| `required` | Ensures field presence | `required: ['key', 'sections']` |
| `minimum/maximum` | Enforces numeric bounds | `minimum: 1, maximum: 20` |
| `minItems/maxItems` | Enforces array length | `minItems: 1, maxItems: 10` |
| `pattern` | Enforces regex pattern | `pattern: '^#[0-9A-Fa-f]{6}$'` |

### Layer 2: Schema Descriptions (Soft - Semantic Hints)

The `description` field provides **semantic hints** to help the model understand field purpose. These are **not enforced** - the model interprets them as guidance.

> **Research Finding**: Studies show that relying heavily on `description` for examples yields "poor and inconsistent results" compared to prompt-based guidance.

**Best Practice**: Keep descriptions **lean** - explain WHAT the field is, not HOW to use it.

### Layer 3: Prompt Guidance (Soft - Behavioral Context)

Examples and contextual usage belong in the **prompt**, not the schema. This approach:
- Provides richer context for the model
- Avoids schema complexity limits
- Follows Google's guidance: "Don't duplicate schema in prompt"
- Allows dynamic examples based on user context

---

## Description Best Practices

### Purpose of Descriptions

The `description` field tells Gemini **what the field represents**:
1. **What** the field is (semantic meaning)
2. **Format** expectations (hex, kebab-case, etc.)
3. **Relationships** between fields (conditional requirements)

> **Note**: Examples belong in prompt guidance, not descriptions.

### Writing Effective Descriptions

#### DO:

```dart
// Brief, explains what it is + format
Schema.string(
  description: 'Primary hex color for headings',
)

// Explains format expectation
Schema.string(
  description: 'Unique slide identifier using kebab-case',
)

// Documents conditional requirement
Schema.string(
  description: 'Markdown content (required when type is "block")',
)

// Explains purpose clearly
Schema.integer(
  description: 'Flex weight for proportional sizing. Higher values take more space.',
)
```

#### DON'T:

```dart
// Too vague - no semantic meaning
Schema.string(description: 'The color')

// Examples in description - put these in prompt guidance instead
Schema.string(description: 'Primary color (e.g., "#8B5CF6", "#3B82F6")')

// Too verbose - keep it concise
Schema.string(description: 'This is the title that will be displayed on the card and should be short')
```

### Description Guidelines

1. **Be specific**: Include format expectations (hex, kebab-case, etc.)
2. **Explain purpose**: What does this field represent?
3. **Document relationships**: Note conditional requirements between fields
4. **Keep it concise**: Brief but complete - no examples needed
5. **Use clear field names**: Names are semantic signals to the model

---

## Prompt Guidance

### Why Prompt Guidance?

Research shows that **schema + prompt guidance** outperforms schema alone:

> "JSON-Schema alone (constrained decoding) performance drops compared to unstructured outputs. NL (natural language) + JSON-Prompt performed better."

### Implementation Pattern

Create a `getPromptGuidance()` function alongside schemas that:
- References actual field names from the schema
- Provides contextual examples
- Guides behavioral choices without duplicating structure

```dart
/// Prompt guidance for slide generation.
/// Reference field names to maintain single source of truth.
String getSlideGenerationGuidance() {
  return '''
Field guidance:
- `key`: Use kebab-case like "slide-intro", "slide-conclusion"
- `colors.background`: Use appropriate background colors for slide backgrounds
- `colors.heading`: Use contrasting hex colors for heading text readability
- `colors.body`: Use readable hex colors for body text content
- `fonts.headline`: Choose Google Fonts like "Poppins" for modern, "Playfair Display" for elegant
- `flex`: Use 1 for equal sizing, 2-3 for emphasis. Range: 1-3.
''';
}
```

### When to Use Each Layer

| Need | Use | Example |
|------|-----|---------|
| Enforce specific values | Schema `enum` | `enumValues: ['block', 'widget']` |
| Enforce data type | Schema `type` | `Schema.integer()` |
| Explain what field is | Schema `description` | `'Hex color for headings'` |
| Provide usage examples | Prompt guidance | `"Use colors like #8B5CF6"` |
| Guide behavioral choices | Prompt guidance | `"For children, use bright colors"` |

---

## Property Ordering

### Why It Matters

Gemini generates properties **alphabetically by default**, not in schema definition order. This can cause issues when:
- Examples in prompts have different ordering than schema
- Logical flow of generation matters (dependencies between fields)

### Using `propertyOrdering`

> **Note**: `propertyOrdering` is a **Gemini-specific extension** not part of standard JSON Schema.
> The `json_schema_builder` package may not expose this directly. See implementation options below.

**Option 1: Gemini 2.5+ (Recommended)**
Gemini 2.5+ models automatically preserve the key order as defined in your schema's `properties` map. If using Dart's `Map` with insertion-order preservation, simply define properties in your desired order.

**Option 2: Manual Schema Extension**
If using older Gemini models, add `propertyOrdering` to the serialized JSON:

```dart
// After building schema with json_schema_builder
final schemaJson = schema.toJson();
schemaJson['propertyOrdering'] = ['title', 'description', 'content'];
```

**Option 3: REST API Direct**
When calling the API directly, include in the schema:

```json
{
  "type": "object",
  "properties": { ... },
  "propertyOrdering": ["title", "description", "content"]
}
```

### Ordering Rules

1. Properties in `propertyOrdering` are generated **first**, in specified order
2. Remaining properties generated in **alphabetical order**
3. **Gemini 2.5+ models** preserve schema key order automatically (no `propertyOrdering` needed)
4. Examples in prompts **must match** schema property ordering

---

## Enum Definitions

### When to Use Enums

- Limited set of valid values
- Classification tasks
- Type discriminators

### Enum Patterns

```dart
// String enum
Schema.string(
  description: 'Block type',
  enumValues: ['block', 'widget'],
)

// Alignment enum with many values
Schema.string(
  description: 'Content alignment',
  enumValues: [
    'topLeft', 'topCenter', 'topRight',
    'centerLeft', 'center', 'centerRight',
    'bottomLeft', 'bottomCenter', 'bottomRight',
  ],
)
```

### Enum Best Practices

1. Use **descriptive values** that the model can understand
2. Keep enum lists **reasonably sized** (complexity limit)
3. Document meaning in `description` if values aren't self-explanatory

---

## Required vs Optional Fields

### Default Behavior

Fields are **optional by default**. The model may skip them if:
- Insufficient context in prompt
- Field seems unnecessary for the response

### Making Fields Required

```dart
Schema.object(
  properties: {
    'key': Schema.string(...),
    'sections': Schema.list(...),
    'options': slideOptionsSchema(),  // optional
  },
  required: ['key', 'sections'],  // Only key and sections are required
)
```

### When to Use Nullable

Use `nullable: true` when:
- Field may legitimately have no value
- Reduces hallucinations (model can return null vs. making up data)

---

## Schema Complexity Limits

### Error: `InvalidArgument: 400`

Complex schemas may be rejected. Complexity factors:
- Long property names
- Long enum lists
- Deep nesting
- Many optional properties
- Array length constraints

### Solutions

1. **Shorten names**: Use concise property and enum names
2. **Flatten structures**: Reduce nesting depth
3. **Reduce constraints**: Fewer optional properties
4. **Split schemas**: Break into smaller, focused schemas

---

## Best Practices Summary

### Schema Design (Layer 1 & 2)

| Practice | Reason |
|----------|--------|
| Clear field names | Semantic signal to model |
| Lean descriptions (no examples) | Explain what, not how |
| Use enums for constrained values | Prevents invalid outputs (enforced) |
| Mark truly required fields | Ensures essential data (enforced) |
| Use pattern for format validation | Enforces format like hex colors |
| Specify propertyOrdering | Consistent output (Gemini 2.5+ auto-preserves) |

### Prompt Guidance (Layer 3)

| Practice | Reason |
|----------|--------|
| Put examples in prompt, not schema | Better model performance |
| Reference field names from schema | Single source of truth |
| Provide behavioral context | Guide choices based on user input |
| **Don't** duplicate schema structure | Reduces output quality |

### Validation

| Practice | Reason |
|----------|--------|
| Always validate output | Syntax valid ≠ semantically correct |
| Handle null values | Optional fields may be null |
| Verify enum values | Model might still deviate |

---

## Current Codebase Analysis

### Architecture

The codebase separates concerns into three layers:

1. **Schemas** (`lib/core/ai/schemas/`) - Structure + constraints + lean descriptions
2. **Prompt Guidance** - Field-specific examples and behavioral context
3. **Catalog Items** - UI components with `exampleData` for GenUI

### Good Practices in Use

```dart
// Good: Lean description explaining what it is
Schema.string(
  description: 'Primary hex color for headings',
)

// Good: Enum constraint (enforced)
Schema.string(
  description: 'Block type: content or widget reference',
  enumValues: ['block', 'widget'],
)

// Good: Conditional requirements documented
Schema.string(
  description: 'Markdown content (required when type is "block")',
)

// Good: Clear purpose with format hint
Schema.integer(
  description: 'Flex weight for proportional sizing. Higher values take more space.',
)
```

### Prompt Guidance Pattern

Each schema file includes a `getPromptGuidance()` function:

```dart
/// Prompt guidance for slide generation.
String getSlideGenerationGuidance() {
  return '''
Field examples:
- `key`: "slide-intro", "slide-summary", "slide-conclusion"
- `colors.background`: "#F5F3FF" (light), "#0F172A" (dark)
- `colors.heading`: "#5B21B6" (playful), "#1E3A8A" (professional)
- `fonts.headline`: "Poppins", "Montserrat", "Playfair Display"
- `flex`: 1 (equal), 2 (emphasis), 3 (dominant)
''';
}
```

### Key Principles

1. **Schemas are lean**: Descriptions explain WHAT, not HOW
2. **Examples in prompts**: Better model performance than schema descriptions
3. **Single source of truth**: Prompt guidance references schema field names
4. **Property ordering**: Gemini 2.5+ preserves map insertion order automatically

---

## json_schema_builder Package Notes

The codebase uses [`json_schema_builder`](https://pub.dev/packages/json_schema_builder) for schema definition. Key considerations:

### Supported Features (via json_schema_builder)

| Feature | Supported | Usage |
|---------|-----------|-------|
| `type` | Yes | `Schema.string()`, `Schema.object()`, etc. |
| `description` | Yes | Pass as named parameter |
| `enum` | Yes | `enumValues: [...]` parameter |
| `required` | Yes | `required: [...]` parameter |
| `properties` | Yes | `properties: {...}` map |
| `items` | Yes | `items: Schema.xxx()` for lists |
| `minimum/maximum` | Yes | Named parameters |
| `minLength/maxLength` | Yes | Named parameters |
| `pattern` | Yes | Regex string parameter |

### Gemini-Specific Fields (may need manual addition)

| Feature | Status | Notes |
|---------|--------|-------|
| `propertyOrdering` | Not in package | Add to serialized JSON manually |
| `nullable` | Supported | Use with `anyOf` for union types |
| `anyOf` | Supported | Added in November 2025 update |
| `$ref` | Gemini 2.5+ | For recursive schemas |

### Codebase Schema Pattern

The codebase uses a **flat discriminated union pattern** for AskUserQuestion:
- Single `input` object with `type` enum discriminator
- All input-specific fields optional in one schema
- Cleaner than separate schemas for AI to understand

---

## SDK Integration Examples

### Dart with json_schema_builder (Current Approach)

```dart
// Schema: lean descriptions, no examples
final schema = Schema.object(
  description: 'Slide presentation data',
  properties: {
    'title': Schema.string(
      description: 'Slide title for navigation display',
    ),
    'layout': Schema.string(
      description: 'Slide layout type',
      enumValues: ['single', 'two-column', 'title-only'],
    ),
    'content': Schema.string(
      description: 'Markdown content for the slide body',
    ),
  },
  required: ['title', 'content'],
);

// Prompt guidance: examples and behavioral context
String getSlideGuidance() {
  return '''
- `title`: Use concise titles like "Introduction", "Key Findings", "Summary"
- `layout`: Use "two-column" for comparisons, "title-only" for section breaks
- `content`: Use markdown with headers, bullets, and emphasis
''';
}
```

### Python with Pydantic

```python
from pydantic import BaseModel, Field
from typing import Literal

class Slide(BaseModel):
    title: str = Field(description="Slide title for navigation display")
    content: str = Field(description="Markdown content for slide body")
    layout: Literal["single", "two-column", "title-only"] = Field(
        description="Slide layout type"
    )

# Prompt guidance function
def get_slide_guidance() -> str:
    return """
- `title`: Use concise titles like "Introduction", "Key Findings"
- `layout`: Use "two-column" for comparisons, "title-only" for breaks
"""
```

### JavaScript with Zod

```javascript
// Schema: lean descriptions
const slideSchema = z.object({
  title: z.string().describe("Slide title for navigation display"),
  content: z.string().describe("Markdown content for slide body"),
  layout: z.enum(["single", "two-column", "title-only"])
    .describe("Slide layout type"),
});

// Prompt guidance
const getSlideGuidance = () => `
- title: Use concise titles like "Introduction", "Summary"
- layout: Use "two-column" for comparisons
`;
```

---

## Sources

- [Structured Outputs | Gemini API](https://ai.google.dev/gemini-api/docs/structured-output)
- [Structured Output | Vertex AI](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/control-generated-output)
- [Firebase AI Logic - Generate Structured Output](https://firebase.google.com/docs/ai-logic/generate-structured-output)
- [Gemini API Structured Outputs Announcement](https://blog.google/technology/developers/gemini-api-structured-outputs/)
- [Mastering Controlled Generation with Gemini 1.5](https://developers.googleblog.com/en/mastering-controlled-generation-with-gemini-15-schema-adherence/)
- [Google GenAI SDK Documentation](https://googleapis.github.io/python-genai/)
