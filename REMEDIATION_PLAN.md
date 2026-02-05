# SuperDeck AI Slop Remediation Plan

**Generated**: 2026-02-05
**Based on**: SLOP_REPORT.md analysis
**Total Issues**: 47 across 5 categories

---

## Priority Matrix

| Priority | Criteria | Timeline | Issues |
|----------|----------|----------|--------|
| **P0** | Critical - Crash risk or blocking | Immediate | 3 |
| **P1** | High - Major quality/security | This sprint | 11 |
| **P2** | Medium - Moderate impact | Next sprint | 22 |
| **P3** | Low - Nice to have | Backlog | 8 |
| **P4** | Optional - Stylistic | When touched | 3 |

---

## P0: Critical Fixes (Immediate - Before Any Release)

### P0-1: Fix setState After Async Without mounted Check
**File**: `packages/superdeck/lib/src/ui/widgets/webview_wrapper.dart`
**Lines**: 54-66
**Effort**: 15 minutes
**Risk**: HIGH (causes crashes)

**Current Code**:
```dart
Future<void> _showDartPad() async {
  await Future.delayed(const Duration(milliseconds: 500));
  setState(() { _hide = false; });  // CRASH RISK
}

Future<void> _reloadDartPad() async {
  setState(() { _hide = true; });  // CRASH RISK
  await Future.delayed(const Duration(milliseconds: 150));
  await _controller.reload();
}
```

**Fixed Code**:
```dart
Future<void> _showDartPad() async {
  await Future.delayed(const Duration(milliseconds: 500));
  if (mounted) {
    setState(() { _hide = false; });
  }
}

Future<void> _reloadDartPad() async {
  if (mounted) {
    setState(() { _hide = true; });
  }
  await Future.delayed(const Duration(milliseconds: 150));
  if (mounted) {
    await _controller.reload();
  }
}
```

---

### P0-2: Add Assertion to Zero-Assertion Test
**File**: `packages/superdeck/test/styling/schema/style_schemas_test.dart`
**Lines**: 1361-1367
**Effort**: 5 minutes
**Risk**: HIGH (fake coverage)

**Current Code**:
```dart
test('handles null values gracefully', () {
  StyleSchemas.styleConfigSchema.safeParse({
    'base': null,
    'styles': null,
  });
});
```

**Fixed Code**:
```dart
test('handles null values gracefully', () {
  final result = StyleSchemas.styleConfigSchema.safeParse({
    'base': null,
    'styles': null,
  });
  expect(result.isOk, isTrue,
    reason: 'Schema should accept null values for optional fields');
  // Or if it should fail:
  // expect(result.isFail, isTrue);
  // expect(result.error, contains('required'));
});
```

---

### P0-3: Refactor PublishCommand.run() (246 lines)
**File**: `packages/cli/lib/src/commands/publish_command.dart`
**Lines**: 403-649
**Effort**: 2-3 hours
**Risk**: MEDIUM (behavior change possible)

**Extraction Plan**:

1. **Extract `_validateAndPrepare()`** (lines 403-450)
   - Pre-publish validation
   - Dry-run checking
   - Return validated config or throw

2. **Extract `_buildForPublish()`** (lines 451-510)
   - Call _buildWebApp
   - Handle build failures
   - Return build path

3. **Extract `_setupGitWorktree()`** (lines 511-570)
   - Create temp directory
   - Initialize worktree
   - Handle branch creation

4. **Extract `_publishToWorktree()`** (lines 571-620)
   - Copy build artifacts
   - Git add/commit/push

5. **Extract `_cleanup()`** (lines 621-649)
   - Remove worktree
   - Delete temp directory

**Refactored run()**:
```dart
@override
Future<int> run() async {
  final config = await _validateAndPrepare();
  if (config == null) return 1;

  final buildPath = await _buildForPublish(config);
  if (buildPath == null) return 1;

  final worktree = await _setupGitWorktree(config);
  if (worktree == null) return 1;

  try {
    await _publishToWorktree(buildPath, worktree);
    return 0;
  } finally {
    await _cleanup(worktree);
  }
}
```

---

## P1: High Priority Fixes (This Sprint)

### P1-1: Refactor _generateMermaidImage() (136 lines)
**File**: `packages/builder/lib/src/assets/mermaid_generator.dart`
**Lines**: 408-544
**Effort**: 1.5 hours

**Extraction Plan**:
1. `_prepareHtmlContent(config)` - Build HTML template
2. `_captureScreenshot(page, html)` - Browser page interaction
3. `_extractDiagramConfig(config)` - Parse configuration

---

### P1-2: Decompose SlideStyle/SlideSpec God Classes
**File**: `packages/superdeck/lib/src/styling/components/slide.dart`
**Effort**: 3-4 hours

**Extraction Plan**:
1. Create `HeadingStyles` (h1-h6 properties)
2. Create `InlineTextStyles` (p, a, em, strong, code)
3. Create `BlockStyles` (blockquote, codeblock, table)
4. Use composition in SlideSpec

---

### P1-3: Extract DeckController Concerns
**File**: `packages/superdeck/lib/src/deck/deck_controller.dart`
**Effort**: 2-3 hours

**Extraction Plan**:
1. Create `ThumbnailController` - thumbnail generation/caching
2. Create `DeckStreamController` - stream management
3. Keep `DeckController` for navigation/UI state

---

### P1-4: Split StyleSchemas Utility Class
**File**: `packages/superdeck/lib/src/styling/schema/style_schemas.dart`
**Effort**: 2 hours

**Extraction Plan**:
1. Create `PaddingSchemaBuilder`
2. Create `EdgeSchemaBuilder`
3. Create `TypographySchemaBuilder`
4. Keep `StyleSchemas` as facade

---

### P1-5: Parameterize Duplicate Alert Tests
**File**: `packages/core/test/markdown_json_test.dart`
**Lines**: 400-493
**Effort**: 30 minutes

**Current** (5 identical tests):
```dart
test('validates NOTE alert structure', () { ... });
test('validates TIP alert structure', () { ... });
test('validates IMPORTANT alert structure', () { ... });
test('validates WARNING alert structure', () { ... });
test('validates CAUTION alert structure', () { ... });
```

**Refactored**:
```dart
for (final type in ['NOTE', 'TIP', 'IMPORTANT', 'WARNING', 'CAUTION']) {
  test('validates $type alert structure', () {
    final markdown = '> [!$type]\n> Alert content\n';
    final map = _converter.toMap(markdown, extensionSet: md.ExtensionSet.gitHubWeb);
    final alertDiv = (map['children'] as List)[0] as Map;
    expect(alertDiv['tag'], equals('div'));
    expect(alertDiv['attributes']?['class'], contains('markdown-alert'));
    expect(alertDiv['attributes']?['class'], contains('markdown-alert-${type.toLowerCase()}'));
  });
}
```

---

### P1-6: Add Value Assertions to Weak Tests
**File**: `packages/superdeck/test/styling/schema/style_schemas_test.dart`
**Lines**: Various (28 instances)
**Effort**: 1 hour

**Example Enhancement**:
```dart
// Before
test('accepts lowercase hex color', () {
  final result = StyleSchemas.colorSchema.safeParse('#ff0000');
  expect(result.isOk, isTrue);
});

// After
test('accepts lowercase hex color', () {
  final result = StyleSchemas.colorSchema.safeParse('#ff0000');
  expect(result.isOk, isTrue);
  final color = result.getOrThrow();
  expect(color.r, equals(1.0));
  expect(color.g, equals(0.0));
  expect(color.b, equals(0.0));
});
```

---

### P1-7: Add CSP to WebView
**File**: `packages/superdeck/lib/src/ui/widgets/webview_wrapper.dart`
**Line**: 31
**Effort**: 30 minutes

Add Content Security Policy headers to restrict JavaScript execution scope.

---

### P1-8: Document Browser Sandbox Bypass
**File**: `packages/cli/lib/src/commands/build_command.dart`
**Lines**: 29-34
**Effort**: 15 minutes

Add security documentation explaining the CI sandbox bypass and its implications:
```dart
// SECURITY NOTE: Chromium sandbox is disabled in CI environments because:
// 1. Docker/container environments don't support the sandbox
// 2. This is only used for Mermaid diagram rendering (trusted input)
// 3. CI environment is already isolated
// Consider: --enable-features=IsolatedWebApps for additional security
final browserLaunchOptions = _isCI() ? ...
```

---

### P1-9 to P1-11: Additional Structure Refactors
- Refactor `_buildWebApp()` - 69 lines → <40 lines
- Refactor `_getBrowser()` - 43 lines → <30 lines
- Eliminate Block model serialization duplication

---

## P2: Medium Priority Fixes (Next Sprint)

### Test Quality (4 items)
| ID | Task | File | Effort |
|----|------|------|--------|
| P2-1 | Add value assertions to padding tests | style_schemas_test.dart:281-340 | 30 min |
| P2-2 | Replace .any() checks with explicit validation | markdown_json_test.dart | 45 min |
| P2-3 | Add content validation to reference generator | markdown_reference_generator_test.dart | 1 hr |
| P2-4 | Replace isNotNull with specific assertions | Various | 1 hr |

### Security Hardening (4 items)
| ID | Task | File | Effort |
|----|------|------|--------|
| P2-5 | Use secure temp directory creation | publish_command.dart:508-511 | 15 min |
| P2-6 | Implement atomic file writes | setup_command.dart, publish_command.dart | 30 min |
| P2-7 | Monitor ack stable release | core/pubspec.yaml | Track |
| P2-8 | Add UriValidator to _parseUri | image_widget.dart:73-80 | 15 min |

### Maintainability (4 items)
| ID | Task | File | Effort |
|----|------|------|--------|
| P2-9 | Create duration constants | Multiple files | 30 min |
| P2-10 | Fix "teh" typo | scaled_app.dart:66 | 1 min |
| P2-11 | Rename isDirty to needsRender | slide_capture_service.dart:140 | 10 min |
| P2-12 | Document maxAttempts = 3 | pdf_controller.dart:122 | 5 min |

### Dart/Flutter (6 items)
| ID | Task | File | Effort |
|----|------|------|--------|
| P2-13 | Fix createState return type | loading_indicator.dart:28 | 5 min |
| P2-14 | Add const to IsometricLoading | slide_page_content.dart:65 | 5 min |
| P2-15 | Add const to SDButton/SDIconButton | Multiple files (15+) | 30 min |

---

## P3: Low Priority (Backlog)

| ID | Task | Effort |
|----|------|--------|
| P3-1 | Extract Mermaid HTML template to file | 30 min |
| P3-2 | Code-gen for SlideStyle.merge() boilerplate | 2 hrs |
| P3-3 | Remove comment pollution in pdf_controller.dart | 15 min |
| P3-4 | Remove obvious comments ("// Get the size") | 10 min |
| P3-5 | Standardize loop variable naming (idx → i) | 10 min |
| P3-6 | Add YAML injection documentation | 15 min |

---

## Sprint Planning

### Sprint 1 (Immediate)
**Effort**: ~8-10 hours

1. **P0-1**: Fix setState mounted check (15 min)
2. **P0-2**: Add test assertion (5 min)
3. **P0-3**: Refactor PublishCommand.run() (3 hrs)
4. **P1-5**: Parameterize alert tests (30 min)
5. **P1-6**: Add value assertions (1 hr)
6. **P1-7**: Add CSP to WebView (30 min)
7. **P1-8**: Document sandbox bypass (15 min)
8. **P2-10**: Fix typo (1 min)
9. **P2-13**: Fix createState type (5 min)

### Sprint 2
**Effort**: ~12-15 hours

1. **P1-1**: Refactor _generateMermaidImage() (1.5 hrs)
2. **P1-2**: Decompose SlideStyle/SlideSpec (4 hrs)
3. **P1-3**: Extract DeckController concerns (3 hrs)
4. **P1-4**: Split StyleSchemas (2 hrs)
5. **P2-5 to P2-8**: Security hardening (1 hr)
6. **P2-14 to P2-15**: Add const keywords (35 min)

### Sprint 3
**Effort**: ~5-8 hours

1. **P1-9 to P1-11**: Remaining structure refactors (3 hrs)
2. **P2-1 to P2-4**: Remaining test quality (3 hrs)
3. **P2-9, P2-11, P2-12**: Maintainability fixes (45 min)

### Backlog (As Time Permits)
- All P3 items
- Additional test quality improvements
- Documentation updates

---

## Dependency Graph

```
P0-3 (PublishCommand refactor)
  └── P1-9 (_buildWebApp refactor) - can be done together

P1-2 (SlideStyle decomposition)
  └── P1-4 (StyleSchemas split) - related, do together

P1-3 (DeckController extraction)
  └── Independent - can be done anytime

P1-5 (Alert test parameterization)
  └── P1-6 (Value assertions) - related test work

P0-1 (mounted check)
  └── P1-7 (CSP) - same file, do together
```

---

## Verification Checklist

After each fix, verify:

- [ ] `melos run analyze` passes with no new warnings
- [ ] `melos run test` passes (all 1290 tests)
- [ ] No regressions in affected functionality
- [ ] Code review completed
- [ ] Commit follows conventional format

---

## Success Criteria

After completing all P0 and P1 items:

| Metric | Before | Target |
|--------|--------|--------|
| Methods >40 lines | 8 | 0 |
| Critical issues | 3 | 0 |
| High issues | 14 | 0 |
| Weak test assertions | 47+ | <10 |
| setState without mounted | 2 | 0 |
| God classes (>20 props) | 2 | 0 |

---

*Plan generated by AI Slop Review Multi-Agent System*
*Associated report: SLOP_REPORT.md*
