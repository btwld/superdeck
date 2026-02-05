# SuperDeck Remediation Plan (Revised)

**Generated**: 2026-02-05
**Revision**: v2 - Simplified after architect review

---

## Summary

| Priority | Count | Work |
|----------|-------|------|
| **Critical** | 1 | 15 min |
| **Medium** | 3 | 2-3 hrs (review) |
| **Low** | 8 | Fix when touched |
| **Removed** | 35 | Skip - over-engineered |

**Total effort: ~2-3 hours** (down from 20+ hours)

---

## Critical - Fix Today

### Fix setState Crash Bug

**File**: `packages/superdeck/lib/src/ui/widgets/webview_wrapper.dart`

```dart
// Line 54-56: Add mounted check
Future<void> _showDartPad() async {
  await Future.delayed(const Duration(milliseconds: 500));
  if (mounted) {  // ADD THIS
    setState(() { _hide = false; });
  }
}

// Line 62-66: Add mounted check
Future<void> _reloadDartPad() async {
  if (mounted) {  // ADD THIS
    setState(() { _hide = true; });
  }
  await Future.delayed(const Duration(milliseconds: 150));
  if (mounted) {  // ADD THIS
    await _controller.reload();
  }
}
```

**Time**: 15 minutes
**Verification**: `melos run test`

---

## Medium - Review This Week

### 1. Security Review: _parseUri

**File**: `packages/superdeck/lib/src/widgets/image_widget.dart:73-80`
**Task**: Check if path traversal is possible through this code path
**Time**: 30 minutes

### 2. Snapshot Test Review

**File**: `packages/core/test/markdown_reference_generator_test.dart`
**Task**: Confirm snapshot validates meaningful behavior
**Time**: 1 hour

### 3. Selective Test Strengthening

**Task**: Review tests for critical schemas only (not all 47 instances)
**Focus on**: Auth-related, data validation schemas
**Time**: 1-2 hours

---

## Low - Fix When Touching Files

| File | Fix |
|------|-----|
| `scaled_app.dart:66` | "teh" → "the" |
| `loading_indicator.dart:28` | `State` → `State<IsometricLoading>` |
| `slide_page_content.dart:65` | Add `const` to `IsometricLoading()` |
| Various widgets (15) | Add `const` where eligible |

Don't create dedicated PRs for these. Fix when editing files for other reasons.

---

## Removed - Don't Do These

The following were removed as over-engineered:

| Original Recommendation | Why Removed |
|------------------------|-------------|
| Split PublishCommand.run() (246 lines) | Cohesive deployment workflow |
| Split _generateMermaidImage() (136 lines) | Cohesive build sequence |
| Decompose SlideStyle/SlideSpec | Domain complexity, Mix framework |
| Extract DeckController | Already well-organized |
| Split StyleSchemas | Declarative data, not code |
| Add CSP to WebView | Would break DartPad |
| Parameterize alert tests | Explicit tests more debuggable |
| Extract Duration constants | Single-use, adds indirection |
| Rename isDirty, idx | Common patterns |
| "Predictable temp dirs" | CLI tool, no attack vector |
| "Non-atomic file ops" | CLI tool, not a server |
| Comment pollution fixes | Subjective preference |

**Principle**: Don't split cohesive code to hit arbitrary line limits.

---

## Verification

After critical fix:

```bash
melos run analyze   # Should pass
melos run test      # All 1290 tests pass
```

---

*Simplified plan - focus on the one actual bug*
