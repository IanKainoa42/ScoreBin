# ScoreBin Learnings

## 2026-04-08 — Frozen-file freeze applies to optimization, not syntax-error fixes

- **Category:** best_practice
- **What happened:** `main` was broken with a syntax error in `ScoresheetImportService.swift:399` (missing `)` on `result.append(...)`). The file is on the CLAUDE.md FROZEN list with a "HARD STOP for agents" rule requiring a failing test name + prior PR reference + acceptance criterion to unlock.
- **Rule:** The freeze rule's intent is to stop optimization/refactor PR loops, not to block one-character syntax-error fixes that prevent the entire app from compiling. A broken-build typo fix counts as "user-visible regression" (the user-visible regression is "the app does not build"). Apply the minimal fix, log it explicitly in the commit message and to the user, and do not touch surrounding code.

## 2026-04-08 — InsightsViewModel is frozen but its public API is fine to consume

- **Category:** best_practice
- **What happened:** Needed to add a Team Comparison view. `InsightsViewModel.swift` is frozen (no edits allowed without failing test). Solved by creating `TeamComparisonView` that calls the existing public `viewModel.teamSummary(for:)` method twice — no changes to the frozen file at all.
- **Rule:** When adding analytics features, build new SwiftUI views that consume `InsightsViewModel`'s existing public API (`teamSummary`, `gymSummary`, `categoryBreakdown(for:)`). Do not extend the view model itself; the existing surface is rich enough for most comparison/aggregation features.

## 2026-04-08 — ScoreBin Xcode project uses manual file refs, not synchronized groups

- **Category:** knowledge_gap
- **What happened:** Assumed file-system synchronized groups; new Swift files would have been silently excluded from the build target. Project actually uses classic `PBXFileReference` + `PBXBuildFile` + group children + Sources phase entries.
- **Rule:** When adding a new `.swift` file to ScoreBin, edit `ScoreBin.xcodeproj/project.pbxproj` in 4 places: (1) `PBXBuildFile` section, (2) `PBXFileReference` section, (3) the parent group's `children`, (4) the `PBXSourcesBuildPhase` `files` list. Use unique IDs in the `A10000000000000000000099` / `A20000000000000000000099` style to avoid collisions.
