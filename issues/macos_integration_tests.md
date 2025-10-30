# macOS Integration Tests - SemanticsHandle Disposal Issue

## Status
**Active Issue** - Affects main branch and all PRs

## Description
Integration tests fail on macOS with `SemanticsHandle` disposal errors when using `IntegrationTestWidgetsFlutterBinding`.

## Error Message
```
A SemanticsHandle was active at the end of the test.
All SemanticsHandle instances must be disposed by calling dispose() on the SemanticsHandle.
```

## Affected Tests
- `demo/integration_test/app_test.dart` - All tests
- `demo/integration_test/navigation_test.dart` - All tests
- `demo/integration_test/semantics_test.dart` - Removed due to this issue

## Platform Specificity
- ✅ **Web** - Tests pass
- ❌ **macOS** - Tests fail with SemanticsHandle errors

## Evidence
- Main branch run: https://github.com/btwld/superdeck/actions/runs/18800075703 - FAILED
- PR #16 runs: Multiple failures with same error pattern

## Root Cause
`IntegrationTestWidgetsFlutterBinding` on macOS appears to create `SemanticsHandle` instances that are not properly cleaned up between test runs. This may be related to:
1. Platform-specific semantics implementation in Flutter
2. Integration test framework behavior on desktop platforms
3. Timing issues with app lifecycle on macOS

## Attempted Solutions
1. ❌ Removed `semanticsEnabled: true` flag from tests
2. ❌ Removed dedicated semantics test file
3. ❌ Updated test assertions to be more flexible

None of these resolved the macOS-specific issue.

## Impact
- Blocks CI/CD pipeline for all PRs
- Does not affect actual application functionality
- Web platform tests pass successfully
- Unit tests pass successfully

## Next Steps
1. Research Flutter integration test semantics handling on macOS
2. Check if this is a known Flutter SDK issue
3. Consider disabling macOS integration tests temporarily
4. Investigate if running tests in isolation helps
5. Look into manual SemanticsHandle management in test teardown

## Workaround
Currently no workaround available. Teams may need to:
- Merge PRs with failing macOS integration tests if other checks pass
- Rely on Web integration tests and unit tests for coverage
- Test macOS builds manually

## Related Issues
- Flutter SDK: TBD (needs research)
- SuperDeck: This is the initial documentation

## Timeline
- **Discovered**: 2025-10-29 (PR #16 custom widgets feature)
- **Confirmed on main**: 2025-10-29
- **Status**: Open
