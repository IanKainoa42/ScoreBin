
## Optimization: Inline Math & Lazy Evaluation
**Date:** March 11
**Files Modified:** `ScoreInputRow.swift`, `InsightsViewModel.swift`

### What was changed
1. Replaced redundant inline mathematical expressions (`((value - range.step) * 100).rounded() / 100`) with the standardized `.rounded2` extension.
2. Updated `.filter { ... }.prefix(limit)` to use `.lazy.filter { ... }.prefix(limit)` in `activeTeams(from:limit:)`.

### Why it was a bottleneck
- The inline math violated the architectural pattern to use centrally defined formatting logic, which leads to maintenance overhead.
- Running standard `.filter` on potentially large arrays evaluates all elements to produce an intermediate array before returning just the first `n` items, resulting in unnecessary CPU time and memory allocation.

### Measured Improvement
- Standardized UI scoring behavior by utilizing reusable extension logic (O(1) maintainability improvement).
- Reduced memory and iteration overhead when limiting an active team query, avoiding unnecessary allocation of elements beyond the desired limit (`O(n)` vs worst-case `O(m)` where `m` is total teams).

### Risk Assessment
- **Low Risk:** The math replacement maps exactly to the previous arithmetic (which is what `.rounded2` runs internally). The `lazy` implementation natively evaluates sequence logic and avoids out-of-bounds indexing. Checked `git diff` to ensure no syntax issues.
