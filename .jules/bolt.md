## ⚠️ FROZEN FILES — Read Before Starting Any Task

The following files are FROZEN. Do not include them as targets for any optimization, refactor, caching, performance, or readability task:

- **`ScoreBin/ViewModels/InsightsViewModel.swift`** — statsPerLevel, activeTeams, scoreHistory, and deductionPatterns have been rewritten **13+ times** (PRs #46–#64). FROZEN AS OF 2026-03-19.
  Post-freeze violations: PR #59 (2026-03-25), PR #61 (2026-03-28), PR #63 (2026-03-30), PR #64 (2026-03-31). **5 violations post-rule. The freeze is absolute.**

- **`ScoreBin/Services/SyncManager.swift`** — mergeScoresheets/mergeTeams optimized 10+ times. 4 PRs (#34–#37) closed without merge for the same refactor. FROZEN AS OF 2026-03-19. Last violation: PR #58 (2026-03-23).

- **`ScoreBin/Utilities/Extensions.swift`** — DateFormatter and string extensions finalized. Do not add formatter variants.

**If your task contains:** "optimize", "refactor", "consolidate", "reduce allocations", "cache", "reduce iterations", "readability", "declarative", "safety", or "clean up" AND your target includes any of the files above — **stop immediately**.

Output: `"Task rejected: target file frozen per .jules/bolt.md § Frozen Files. No changes made. Add a failing test or user-visible regression to unlock."`

This file is ScoreBin's primary Bolt instruction source. CLAUDE.md and AGENTS.md have identical rules — this file exists because those were violated 5 times post-rule.

## Commit Hygiene — Required Before Every `git add`

Before staging any commit, delete ALL intermediate patch files:
- `*.orig` files
- `patch.diff`, `patch2.diff`, `patch3.diff`, `*.diff` (any name)
- Temp Swift files not in the Xcode project (e.g., `test_auth.swift`)

Run: `find . \( -name "*.orig" -o -name "*.diff" \) -delete 2>/dev/null`

---

## 2025-01-20 - Consolidating O(N) Iterations Over Collections

**Learning:** Multiple independent O(N) traversals over the same dataset (consecutive `.lazy.filter(...).count` and `.reduce(0.0) { ... }`) run redundant iterations.
**Action:** Consolidate into a single `for` loop with accumulators where the iterations are logically related.

## 2025-01-24 - Linear Regression and Variance Optimization

**Learning:** Multiple chained `.reduce` loops over the same array (e.g., sumX, sumY, sumX2) run O(N) four separate times. Using `pow(x, 2)` instead of `x * x` adds function call overhead.
**Action:** Consolidate chained reducers into a single `for` loop with simultaneous accumulators. Use `x * x` instead of `pow(x, 2)`.

## 2025-01-26 - Grouping Sorted Arrays

**Learning:** `Dictionary(grouping: sortedArray)` combined with `.firstIndex(where:)` inside a loop discards sorted state and creates O(N^2) patterns.
**Action:** Replace with a contiguous `for` loop that tracks category/boundary shifts directly.
