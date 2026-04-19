# TODO

## Deferred: test.yml workflow update

The workflow change in `.github/workflows/test.yml` was deferred from commit `d30419c` because the current push token lacks GitHub `workflow` scope.

**To apply later:**
1. Refresh auth with workflow scope: `gh auth refresh -s workflow`
2. Re-apply the diff below to `.github/workflows/test.yml`
3. Commit and push separately

**Deferred diff:**

```diff
diff --git a/.github/workflows/test.yml b/.github/workflows/test.yml
index 0a9a0a4..55f4ac4 100644
--- a/.github/workflows/test.yml
+++ b/.github/workflows/test.yml
@@ -56,6 +56,9 @@ jobs:
       - name: Run Unit Tests
         run: melos run test --no-select
 
+      - name: Run Golden Tests
+        run: fvm flutter test packages/superdeck/test/goldens/slide_goldens_test.dart
+
   integration-test:
     runs-on: ubuntu-latest
     name: Integration Tests
@@ -174,10 +177,10 @@ jobs:
           cd demo/e2e
           npm ci
 
-      - name: Install Playwright browser
+      - name: Install Playwright browsers
         run: |
           cd demo/e2e
-          npx playwright install --with-deps chromium
+          npx playwright install --with-deps chromium webkit
 
       - name: Run Playwright smoke tests
         run: |
```
