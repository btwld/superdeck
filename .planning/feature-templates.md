# Templates Feature – Implementation Plan

## Executive Summary

Templates provide reusable **chrome configurations** (background, header, footer) bundled with **isolated style systems** for consistent slide presentation. Templates are like Keynote master slides - they define the visual frame and default styling, while users continue writing markdown content using `@section`/`@column` directives normally.

**Key Principle:** Templates control the **decorative layer** (chrome + styling), not the content layout. The existing `@section`/`@column` system remains unchanged.

---

## Decisions Made

### 1. Template Scope: Chrome Only
- **Chrome Elements:** Background, header, footer (via `SlideParts`)
- **NOT in scope:** Slot definitions, layout restructuring, replacing `@section`/`@column`
- **Rationale:** Keep templates simple, focused, and non-invasive to existing markdown authoring

### 2. Isolated Style Systems
- Templates bundle their own style hierarchy: `baseStyle` + `Map<String, SlideStyle> styles`
- When a template is used, deck-level styles are ignored for that slide
- Style resolution: `defaultSlideStyle → template.baseStyle → template.styles[slide.style]`
- **Rationale:** Templates provide complete visual control without style conflicts

### 3. Mutual Exclusivity
- `template:` and `style:` in frontmatter are mutually exclusive at the top level
- **Exception:** When using a template, `style:` can reference a named style within that template
- Example: `template: corporate` + `style: emphasis` → uses `corporate.styles['emphasis']`

### 4. Default Template Support
- `DeckOptions.defaultTemplate` allows applying a template to all slides by default
- Individual slides can opt-out by specifying a different template or no template
- **Backward Compatibility:** Without `defaultTemplate`, existing slides render unchanged

### 5. Build-Time Validation
- Unknown template name → build error with available templates listed
- Unknown style within template → build error with available styles listed
- Clear, actionable error messages guide developers

### 6. Architecture: Clean Separation
- **SlideTemplate:** Data class bundling parts + styles
- **TemplateResolver:** Service class handling resolution logic and validation
- **TemplateException:** Dedicated exception type for template errors
- **SlideConfigurationBuilder:** Delegates to resolver for style/parts resolution

---

## Core Data Models

### SlideTemplate
```dart
/// A reusable slide template bundling chrome and styles.
///
/// Templates are isolated style systems that provide complete visual
/// control over slides. They include:
/// - Chrome elements (header, footer, background)
/// - Base styling applied to all slides using this template
/// - Named style variants for different slide types
final class SlideTemplate {
  /// Chrome elements for this template.
  final SlideParts parts;

  /// Base style applied to all slides using this template.
  /// Merged after defaultSlideStyle but before named styles.
  final SlideStyle? baseStyle;

  /// Named style variants available within this template.
  /// Keys match the `style:` field in slide frontmatter.
  final Map<String, SlideStyle> styles;

  const SlideTemplate({
    this.parts = const SlideParts(),
    this.baseStyle,
    this.styles = const {},
  });

  SlideTemplate copyWith({...});
}
```

### Enhanced DeckOptions
```dart
class DeckOptions {
  // Existing fields
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetBlockBuilder> widgets;
  final SlideParts parts;
  final bool debug;

  // NEW: Template support
  /// Registry of available templates.
  /// Keys are template names referenced in frontmatter.
  final Map<String, SlideTemplate> templates;

  /// Default template applied to slides without explicit template.
  /// Optional - without this, slides use deck-level styles/parts.
  final SlideTemplate? defaultTemplate;
}
```

### Enhanced SlideOptions
```dart
class SlideOptions {
  final String? title;

  /// Style name - references deck styles OR template styles.
  /// - Without template: looks in DeckOptions.styles
  /// - With template: looks in template.styles
  final String? style;

  /// Template name - references DeckOptions.templates.
  /// Mutually exclusive with using deck-level styles.
  final String? template;

  final Map<String, Object?> args;
}
```

---

## Architecture Components

### Layer 1: Resolution Service (NEW)

**File:** `packages/superdeck/lib/src/deck/template_resolver.dart`

**Responsibilities:**
- Validate template existence
- Validate style existence (within template or deck)
- Enforce mutual exclusivity rules
- Compute final merged style
- Resolve parts (template or deck)
- Generate actionable error messages

**Key Methods:**
```dart
class TemplateResolver {
  final DeckOptions options;

  const TemplateResolver(this.options);

  /// Resolves template and computes final style/parts for a slide.
  ///
  /// Throws [TemplateException] if:
  /// - Template name not found
  /// - Style name not found (in template or deck)
  /// - Both template and deck style specified (mutual exclusivity)
  TemplateResolutionResult resolve(SlideOptions? slideOptions);
}

class TemplateResolutionResult {
  final SlideStyle style;      // Fully merged style
  final SlideParts parts;      // Resolved parts (template or deck)
  final bool usingTemplate;    // True if template was applied
}
```

**Style Resolution Logic:**
```dart
// WITH TEMPLATE:
defaultSlideStyle
  .merge(template.baseStyle)
  .merge(template.styles[slide.style])  // If slide.style specified

// WITHOUT TEMPLATE (existing behavior):
defaultSlideStyle
  .merge(deckOptions.baseStyle)
  .merge(deckOptions.styles[slide.style])  // If slide.style specified
```

### Layer 2: Configuration Builder (MODIFIED)

**File:** `packages/superdeck/lib/src/deck/slide_configuration_builder.dart`

**Changes:**
- Create `TemplateResolver` instance
- Delegate style/parts resolution to resolver
- Use resolved values in `SlideConfiguration`

**Modified Logic:**
```dart
SlideConfiguration _buildConfiguration(
  int index,
  Slide slide,
  DeckOptions options,
  TemplateResolver resolver,  // NEW parameter
) {
  // ... existing widget collection ...

  // NEW: Delegate to resolver
  final resolution = resolver.resolve(slide.options);

  return SlideConfiguration(
    slideIndex: index,
    style: resolution.style,      // From resolver
    slide: slide,
    widgets: widgets,
    thumbnailFile: thumbnailPath,
    parts: resolution.parts,      // From resolver
    debug: options.debug,
  );
}
```

### Layer 3: Exception Handling (NEW)

**File:** `packages/superdeck/lib/src/deck/template_exception.dart`

```dart
/// Exception thrown when template resolution fails.
class TemplateException implements Exception {
  final String message;

  const TemplateException(this.message);

  @override
  String toString() => 'TemplateException: $message';
}
```

---

## Data Flow

### Build-Time Flow
```
1. slides.md
   ---
   template: corporate
   style: title
   ---
   # My Slide

2. MarkdownParser → RawSlideMarkdown
   frontmatter: {template: "corporate", style: "title"}

3. SlideProcessor → Slide
   options: SlideOptions(template: "corporate", style: "title")

4. SlideConfigurationBuilder.buildConfigurations()
   ├─ Create TemplateResolver(options)
   └─ For each slide:
      ├─ resolver.resolve(slide.options)
      │  ├─ Validate template "corporate" exists
      │  ├─ Validate style "title" exists in template
      │  ├─ Merge: defaultSlideStyle → corporate.baseStyle → corporate.styles['title']
      │  └─ Return TemplateResolutionResult
      └─ Create SlideConfiguration with resolved style + parts

5. SlideConfiguration → SlideView → Render
```

### Runtime Rendering (No Changes)
```
SlideConfiguration
  ↓
SlideView
  ├─ config.parts.background (from template or deck)
  ├─ config.parts.header (from template or deck)
  ├─ @section/@column content (styled with config.style)
  └─ config.parts.footer (from template or deck)
```

---

## Validation Strategy

### Build-Time Checks (via TemplateResolver)

**1. Unknown Template**
```markdown
---
template: corporat  # Typo
---
```
**Error:**
```
TemplateException: Template "corporat" not found.
Available templates: corporate, minimal, announcement
```

**2. Unknown Style in Template**
```markdown
---
template: corporate
style: titl  # Typo
---
```
**Error:**
```
TemplateException: Style "titl" not found in template "corporate".
Available styles: title, content, closing
```

**3. Unknown Style in Deck (no template)**
```markdown
---
style: announement  # Typo
---
```
**Error:**
```
TemplateException: Style "announement" not found in deck.
Available styles: announcement, quote, emphasis
```

### Schema Validation (optional, can be added later)

Templates can optionally define argument schemas:
```dart
final template = SlideTemplate(
  // ... parts and styles ...
  argsSchema: {
    'background_image': 'string?',
    'show_logo': 'bool',
  },
);
```

---

## Implementation Plan

### Phase 1: Core Infrastructure (2-3 hours)

**1.1 Create SlideTemplate Class**
- [ ] File: `packages/superdeck/lib/src/deck/slide_template.dart`
- [ ] Define class with `parts`, `baseStyle`, `styles`
- [ ] Implement `copyWith()`, equality, hashCode
- [ ] Add comprehensive dartdoc

**1.2 Create TemplateResolver Service**
- [ ] File: `packages/superdeck/lib/src/deck/template_resolver.dart`
- [ ] Define `TemplateResolver` class
- [ ] Define `TemplateResolutionResult` class
- [ ] Implement `resolve()` method with validation
- [ ] Add error message generation

**1.3 Create TemplateException**
- [ ] File: `packages/superdeck/lib/src/deck/template_exception.dart`
- [ ] Define exception class with message

**1.4 Update DeckOptions**
- [ ] File: `packages/superdeck/lib/src/deck/deck_options.dart`
- [ ] Add `templates` field
- [ ] Add `defaultTemplate` field
- [ ] Update constructor, copyWith, equality, hashCode

**1.5 Update SlideOptions**
- [ ] File: `packages/core/lib/src/models/slide_model.dart`
- [ ] Add `template` field
- [ ] Update schema (optional: add mutual exclusion validation)
- [ ] Update fromMap, toMap, copyWith, equality, hashCode

**1.6 Export New Classes**
- [ ] File: `packages/superdeck/lib/superdeck.dart`
- [ ] Export `SlideTemplate`
- [ ] Export `TemplateException`
- [ ] Keep `TemplateResolver` internal (not exported)

**Checkpoint:**
- [ ] Run `melos run analyze` - no errors
- [ ] Run `melos run test` - existing tests pass
- [ ] All new classes compile

---

### Phase 2: Integration (1-2 hours)

**2.1 Update SlideConfigurationBuilder**
- [ ] File: `packages/superdeck/lib/src/deck/slide_configuration_builder.dart`
- [ ] Import `TemplateResolver`
- [ ] Instantiate resolver in `buildConfigurations()`
- [ ] Pass resolver to `_buildConfiguration()`
- [ ] Replace style merging logic with `resolver.resolve()`
- [ ] Use resolved `style` and `parts` in SlideConfiguration

**Checkpoint:**
- [ ] Run `melos run analyze` - no errors
- [ ] Manual test with demo app (add a simple template)
- [ ] Verify slides render with template

---

### Phase 3: Testing (2-3 hours)

**3.1 Unit Tests for TemplateResolver**
- [ ] File: `packages/superdeck/test/deck/template_resolver_test.dart`
- [ ] Test template resolution with valid template
- [ ] Test template resolution with defaultTemplate
- [ ] Test deck style resolution (no template)
- [ ] Test unknown template error
- [ ] Test unknown style in template error
- [ ] Test unknown style in deck error
- [ ] Test style merging order

**3.2 Unit Tests for SlideTemplate**
- [ ] File: `packages/superdeck/test/deck/slide_template_test.dart`
- [ ] Test construction
- [ ] Test copyWith
- [ ] Test equality

**3.3 Integration Tests**
- [ ] File: `packages/superdeck/test/deck/slide_configuration_builder_test.dart`
- [ ] Test builder with templates
- [ ] Test builder with defaultTemplate
- [ ] Test builder without templates (backward compatibility)
- [ ] Test parts resolution from template

**3.4 Update Existing Tests**
- [ ] File: `packages/core/test/src/models/slide_model_test.dart`
- [ ] Test SlideOptions with template field
- [ ] Test schema validation

**Checkpoint:**
- [ ] Run `melos run test` - all tests pass
- [ ] Run `melos run test:coverage` - check coverage

---

### Phase 4: Demo & Documentation (1-2 hours)

**4.1 Create Demo Templates**
- [ ] File: `demo/lib/src/templates.dart` (NEW)
- [ ] Create `corporateTemplate` with custom parts and styles
- [ ] Create `minimalTemplate` with simple styling
- [ ] Create `titleSlideTemplate` (no header/footer)

**4.2 Update Demo App**
- [ ] File: `demo/lib/main.dart`
- [ ] Register templates in `DeckOptions`
- [ ] Optionally set `defaultTemplate`

**4.3 Update Demo Slides**
- [ ] File: `demo/slides.md`
- [ ] Add slides using different templates
- [ ] Show template + style combinations
- [ ] Show slide without template (backward compatibility)

**4.4 Update Documentation**
- [ ] This file: Complete implementation details
- [ ] Add usage examples
- [ ] Add troubleshooting section
- [ ] Add best practices

**Checkpoint:**
- [ ] Demo app runs with templates
- [ ] All template variations render correctly
- [ ] Documentation is clear and complete

---

### Phase 5: Quality Assurance (1 hour)

**5.1 Code Quality**
- [ ] Run `melos run analyze` - no warnings
- [ ] Run `melos run custom_lint_analyze` - no issues
- [ ] Run `melos run format` - code formatted

**5.2 Integration Testing**
- [ ] Test template with custom background
- [ ] Test template with custom header/footer
- [ ] Test defaultTemplate behavior
- [ ] Test error messages (unknown template, unknown style)
- [ ] Test backward compatibility (slides without templates)

**5.3 Performance Check**
- [ ] Verify build time is not impacted
- [ ] Verify rendering performance is unchanged
- [ ] No memory leaks or excessive allocations

**Final Checkpoint:**
- [ ] All tests pass
- [ ] Demo works perfectly
- [ ] Documentation complete
- [ ] Ready for PR

---

## Usage Examples

### Define a Template

```dart
// In your app (e.g., lib/src/templates.dart)
final corporateTemplate = SlideTemplate(
  parts: SlideParts(
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
        ),
      ),
    ),
    header: PreferredSize(
      preferredSize: Size.fromHeight(80),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            Spacer(),
            Text('Q1 2024 Review', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    ),
    footer: PreferredSize(
      preferredSize: Size.fromHeight(60),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Confidential'),
            Text('Page ${SlideConfiguration.of(context).slideIndex + 1}'),
          ],
        ),
      ),
    ),
  ),
  baseStyle: SlideStyle(
    h1: TextStyler().style(
      TextStyleMix(fontSize: 64, color: Colors.blue[900]!),
    ),
    p: TextStyler().style(
      TextStyleMix(fontSize: 24, height: 1.6),
    ),
  ),
  styles: {
    'title': SlideStyle(
      h1: TextStyler().style(
        TextStyleMix(fontSize: 96, fontWeight: FontWeight.bold),
      ),
    ),
    'emphasis': SlideStyle(
      slideContainer: BoxStyler(
        decoration: BoxDecorationMix(
          border: BorderMix.all(BorderSideMix(color: Colors.blue, width: 8)),
        ),
      ),
    ),
  },
);
```

### Register Templates

```dart
// In main.dart
SuperDeckApp(
  options: DeckOptions(
    templates: {
      'corporate': corporateTemplate,
      'minimal': minimalTemplate,
    },
    defaultTemplate: corporateTemplate,  // Optional: apply to all slides
  ),
  // ... other options
)
```

### Use Templates in Markdown

**Simple template usage:**
```markdown
---
template: corporate
---
# Quarterly Results

Our Q1 performance exceeded expectations.
```

**Template with named style:**
```markdown
---
template: corporate
style: title
---
# Q1 2024 Review

Welcome to our quarterly review.
```

**Override default template:**
```markdown
---
template: minimal
---
# Closing Remarks

Thank you for your attention.
```

**No template (uses deck styles):**
```markdown
---
style: announcement
---
# Important Update
```

---

## Error Messages Reference

### Unknown Template
```
TemplateException: Template "corporat" not found.
Available templates: corporate, minimal, announcement
```
**Fix:** Check template name spelling, ensure template is registered in `DeckOptions.templates`

### Unknown Style in Template
```
TemplateException: Style "titl" not found in template "corporate".
Available styles: title, emphasis, closing
```
**Fix:** Check style name spelling, ensure style is defined in `template.styles`

### Unknown Style in Deck
```
TemplateException: Style "announement" not found in deck.
Available styles: announcement, quote, emphasis
```
**Fix:** Check style name spelling, ensure style is defined in `DeckOptions.styles`

---

## Best Practices

### Template Design

**1. Keep Templates Focused**
- Templates should define chrome (visual frame)
- Let content flow naturally using `@section`/`@column`
- Don't try to control content layout from templates

**2. Provide Sensible Defaults**
- Template's `baseStyle` should work for most slides
- Named styles (`template.styles`) for special cases only

**3. Consider Reusability**
- Design templates for a category of slides (e.g., "title slides", "content slides")
- Avoid overly specific templates (e.g., "slide-3-only")

**4. Test Without Template First**
- Ensure your content works with standard styling
- Add template as enhancement, not requirement

### Template Usage

**1. Use defaultTemplate Sparingly**
- Without default: slides opt-in to templates
- With default: all slides use template unless overridden
- Recommendation: start without default, add later if needed

**2. Be Consistent Within Deck**
- Use 2-3 templates max per presentation
- Reserve template switching for major section changes

**3. Leverage Named Styles**
- Create variations within a template (title, emphasis, closing)
- Keeps deck cohesive while allowing variety

---

## Backward Compatibility

### Existing Slides Without Templates
- **Status:** ✅ Fully compatible, no changes required
- **Behavior:** Render exactly as before using deck-level styles and parts

### Existing Code Using SlideOptions
- **Status:** ✅ Compatible, `template` field is optional
- **Migration:** None required, existing code continues to work

### Existing Style System
- **Status:** ✅ Unchanged, deck-level styles work as before
- **Note:** Templates provide alternative, not replacement

---

## File Changes Summary

### New Files (3)
1. `packages/superdeck/lib/src/deck/slide_template.dart` - Template data class
2. `packages/superdeck/lib/src/deck/template_resolver.dart` - Resolution service
3. `packages/superdeck/lib/src/deck/template_exception.dart` - Exception class

### Modified Files (4)
1. `packages/superdeck/lib/src/deck/deck_options.dart` - Add template fields
2. `packages/core/lib/src/models/slide_model.dart` - Add template to SlideOptions
3. `packages/superdeck/lib/src/deck/slide_configuration_builder.dart` - Use resolver
4. `packages/superdeck/lib/superdeck.dart` - Export new classes

### Test Files (4 new)
1. `packages/superdeck/test/deck/slide_template_test.dart`
2. `packages/superdeck/test/deck/template_resolver_test.dart`
3. `packages/superdeck/test/deck/slide_configuration_builder_test.dart`
4. `packages/core/test/src/models/slide_model_test.dart`

### Demo Files (2 new, 1 modified)
1. `demo/lib/src/templates.dart` - Demo template definitions
2. `demo/lib/main.dart` - Register templates
3. `demo/slides.md` - Use templates

**Total:** 7 core files, 4 test files, 3 demo files = **14 files**

---

## Timeline Estimate

- **Phase 1 (Core Infrastructure):** 2-3 hours
- **Phase 2 (Integration):** 1-2 hours
- **Phase 3 (Testing):** 2-3 hours
- **Phase 4 (Demo & Docs):** 1-2 hours
- **Phase 5 (QA):** 1 hour

**Total:** 7-11 hours for complete implementation with tests and documentation

---

## Success Criteria

- [ ] All existing tests pass (backward compatibility verified)
- [ ] New tests cover all resolution paths and error cases
- [ ] Demo app showcases 3+ different templates
- [ ] Error messages are clear and actionable
- [ ] Documentation explains usage with examples
- [ ] Code passes all quality checks (analyze, lint, format)
- [ ] No performance regression in build or render time

---

## Open Questions (Resolved)

### ~~Q1: Slot mapping strategy?~~
**Resolved:** Templates do NOT define slots. Users continue using `@section`/`@column` normally. Templates only affect chrome (background, header, footer).

### ~~Q2: Template helper return type?~~
**Resolved:** Not applicable - templates are simple data classes, not helpers/builders.

### ~~Q3: YAML template syntax?~~
**Resolved:** Dart-only for V1. YAML support can be added later if needed.

---

## Future Enhancements (Out of Scope for V1)

### Template Inheritance
```dart
final extendedTemplate = SlideTemplate(
  inheritsFrom: 'corporate',  // Extend another template
  baseStyle: SlideStyle(...),  // Override specific styles
);
```

### Conditional Template Selection
```dart
DeckOptions(
  templateSelector: (slideOptions) {
    if (slideOptions.args['isTitle'] == true) return 'title';
    return 'content';
  },
);
```

### Custom Chrome Elements
```dart
class SlideParts {
  final Widget? watermark;
  final Widget? logo;
  // ... existing parts
}
```

### YAML Template Definitions
```yaml
# templates/corporate.yaml
baseStyle:
  h1:
    fontSize: 64
    color: blue
parts:
  background: assets/bg.png
```

---

## Notes

This document represents the complete, final plan for implementing templates in Superdeck based on:
- Chrome-focused scope (not layout control)
- Isolated style systems (templates don't merge with deck styles)
- Clean architecture (TemplateResolver service for separation of concerns)
- Flutter developer ergonomics (simple API, clear errors, familiar patterns)

Last updated: 2025-10-23
