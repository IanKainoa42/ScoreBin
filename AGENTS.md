# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

ScoreBin is a cheerleading scoresheet entry application implementing the **United Scoring System 2025-2026**. It provides an interactive form for judges to enter scores that auto-calculates totals and exports data for database storage.

The project has two implementations:
1. **Web version** - React/HTML for browser use
2. **iOS app** - Native SwiftUI app with SwiftData persistence

## Project Structure

```
ScoreBin/
├── scoresheet_form.html      # Standalone HTML/React version
├── ScoresheetForm.jsx        # React component (requires bundler)
├── ScoreBin.xcodeproj/       # Xcode project
└── ScoreBin/                 # iOS app source
    ├── ScoreBinApp.swift     # App entry point
    ├── Models/               # SwiftData models
    │   ├── Gym.swift
    │   ├── Team.swift
    │   ├── Competition.swift
    │   └── Scoresheet.swift
    ├── Views/
    │   ├── MainTabView.swift
    │   ├── Scoresheet/       # Score entry UI
    │   ├── Competitions/     # Competition management
    │   ├── Teams/            # Team/gym management
    │   └── Insights/         # Analytics & charts
    ├── ViewModels/
    │   ├── ScoresheetViewModel.swift
    │   ├── CompetitionViewModel.swift
    │   └── InsightsViewModel.swift
    ├── Services/
    │   ├── SupabaseService.swift
    │   └── SyncManager.swift
    └── Utilities/
        ├── ScoringRules.swift
        └── Extensions.swift
```

## Running the Application

**Web version (no build):**
```bash
open scoresheet_form.html
```

**iOS app:**
```bash
open ScoreBin.xcodeproj
# Then Cmd+R to build and run in Xcode
```
Requires iOS 17.0+ deployment target (uses SwiftData).

## iOS App Architecture

### Data Models (SwiftData)
- `Gym` - Program/gym entity with teams relationship
- `Team` - Team with level, division, athlete count
- `Competition` - Competition events with date/location
- `Scoresheet` - Core scoring data with all judge scores and deductions
  - Includes computed properties for all totals (stunt, pyramid, building, tumbling, etc.)
  - `exportForDatabase()` method formats data for Supabase upload

### Navigation
Four-tab structure:
1. **Scoresheet** - Main score entry form
2. **Competitions** - List/manage competitions
3. **Teams** - Manage teams and gyms
4. **Insights** - Analytics dashboard with Swift Charts

### Key Files
- `ScoringRules.swift` - All scoring constants, ranges, deduction values, level-specific maximums
- `Extensions.swift` - Color theme (dark mode), view modifiers
- `ScoresheetViewModel.swift` - Score calculation logic with level-aware maximums
- `AppConfig.swift` - Supabase configuration (URL and anon key)

## Known Fragile Areas

These files have been touched in 12+ agent PRs. **Do not submit new optimization tasks
targeting these files without a concrete failing test or user-visible bug as the
acceptance criterion.** Agents loop on them indefinitely otherwise.

- `ScoreBin/ViewModels/InsightsViewModel.swift` — statsPerLevel, activeTeams, and
  scoreHistory have been rewritten 9+ times (PRs #46–#61).
  **FROZEN AS OF 2026-03-19. Last violations: PR #59 (2026-03-25), PR #61 (2026-03-28), PR #63 (2026-03-30), PR #64 (2026-03-31).**
  Do not refactor without a specific failing assertion. This file has violated the freeze **5 times post-rule** and is now also covered by `.jules/bolt.md` (Bolt's primary instruction source).
- `ScoreBin/Services/SyncManager.swift` — mergeScoresheets/mergeTeams, updatePendingCount,
  and DateFormatter usage have been optimized 10+ times. 4 PRs (#34–#37) were closed
  without merging — all attempted the same refactor and were rejected. ISO8601DateFormatter
  is a shared static (confirmed). **FROZEN AS OF 2026-03-19. Last violations: PR #58
  (2026-03-23), PR #60 (2026-03-26 — "batched saving + magic strings").** Do not consolidate again.
- `ScoreBin/Utilities/Extensions.swift` — DateFormatter and string extensions are finalized.
  Do not add new formatter variants without a documented reason.
- `ScoreBin/Services/ScoresheetImportService.swift` — OCR parsing and candidate scoring logic.
  Touched 4 times in 5 days (PRs #67, #68, #69, #71 — Apr 3–7 2026) converting loops to `compactMap`,
  `reduce(into:)`, and `flatMap`. The declarative refactor is complete as of PR #69.
  **FROZEN AS OF 2026-04-05. Post-freeze violation: PR #71 (2026-04-07 — "Optimize OCR parsing iterations").**
  Do not submit further loop/declarative/compactMap/reduce optimization tasks.
  This is the same escalation trajectory as InsightsViewModel (9+ rewrites) — stopping it here.
  Unlock condition: specific failing OCR parse test with a sample PDF that reproduces it.
- `ScoreBin/ViewModels/ScoresheetViewModel.swift` — intermediate computed property removal
  complete (PRs #65, #76 — Apr 2–12 2026). Formatters cached, redundant getters removed,
  concurrency modernized. **FROZEN for "redundant property" / "remove getters" /
  "consolidate computed" / "cache formatter" tasks AS OF 2026-04-13.**
  Unlock condition: user-visible calculation bug or a failing XCTest assertion.
- `ScoreBin/ViewModels/CompetitionViewModel.swift` — iteration optimizations complete
  (PRs #70, #73 — Apr 6–9 2026). `.count` consolidations and `.reduce(into:)` refactors done.
  **FROZEN for iteration/allocation optimization tasks AS OF 2026-04-13.**
  Unlock condition: Instruments trace showing this function as a measurable hot path.
- `ScoreBin/Views/Scoresheet/OverallJudgeSection.swift`, `ScoreSummaryView.swift`, `StickyScoreBar.swift` — scoresheet presentation views hit in 3 consecutive optimization PRs (#75, #81, #82 — Apr 11–18 2026) each removing "redundant `.rounded2`" calls. **FROZEN for `.rounded2`/`scoreFormatted`/computed property removal AS OF 2026-04-20.** Unlock condition: a specific double-formatting bug with incorrect output, verified by unit test.
- `ScoreBin/Views/Insights/TeamComparisonView.swift` — touched in 4 consecutive PRs (#74, #77, #79, #80 — Apr 10–16 2026). **FROZEN for all "optimization"/"refactor"/"consolidate" tasks AS OF 2026-04-20.** Additionally: the swallowed-save-errors fix from PR #78 was re-applied in PR #83 to the same Competition/Team views — confirmed duplicate fix. Views in `Competitions/` and `Teams/` are also locked for save-error refactors until a user-visible save failure or failing XCTest is cited.
  Unlock condition: user-visible save failure or a failing XCTest.

**HARD STOP for agents:** Do NOT modify these files unless your issue description
contains **all three** of:
1. A specific failing test name or user-visible regression (e.g., "InsightsView crashes
   with 100+ teams on iPhone 13 Pro — reproducible at Analytics > Gym tab")
2. A reference to which prior PR attempted this fix and why it's insufficient
3. An acceptance criterion that a human reviewer can verify in 60 seconds

If your task says "optimize", "refactor", "consolidate", "reduce allocations", "clean
up", "cache", or "reduce iterations" without a failing assertion, **stop immediately**.
This includes automated sessions (Daily Optimization Workflow, Bolt agent, Sentinel).
Post a comment: "Task rejected: [file] is locked per Known Fragile Areas. No changes
made. Add a failing test or user-visible regression to unlock."

Dispatch system will block re-dispatch if the same file was touched for the same
stated reason in the last 14 PRs.

## Scoring System Architecture

### Judge Panels
Three judges each provide scores that contribute to the final total:
- **Building Judge**: Stunt, Pyramid, Tosses + Creativity/Showmanship
- **Tumbling Judge**: Standing, Running, Jumps + Creativity/Showmanship
- **Overall Judge**: Dance, Formations + Creativity/Showmanship

### Score Calculation Flow
1. Each category has Difficulty + Execution + optional Drivers
2. Creativity and Showmanship are averaged across all 3 judges
3. Raw Score = sum of all category totals
4. Final Score = Raw Score - Deductions
5. **Level 1 Restriction**: Toss scores are zeroed out (no tosses allowed)

### Maximum Scores
- Building Total: 22.0 (Stunt 10 + Pyramid 8 + Toss 4)
  - **Level 1 Building Total: 18.0** (no tosses allowed)
- Tumbling Total: 20.0 (Standing 8 + Running 8 + Jumps 4)
- Overall Total: 8.0 (Dance 2 + Formations 2 + Creativity 2 + Showmanship 2)
- **Max Score: 50.0** (46.0 for Level 1)

### Deduction Values
- Athlete Fall: 0.15
- Major Athlete Fall: 0.25
- Building Bobble: 0.25
- Building Fall: 0.75
- Major Building Fall: 1.25
- Boundary/Time Violations: 0.05

### Quantity Chart
Group requirements scale with athlete count (5-38 athletes):
- 31+: majority=5, most=6, max=7
- 23-30: majority=4, most=5, max=6
- 18-22: majority=3, most=4, max=5
- 12-17: majority=2, most=3, max=4
- <12: majority=1, most=2, max=3

## Round Types

Competitions track multiple rounds per team:
- Day 1
- Day 2
- Finals
- Exhibition

## Database Export Format

Both versions export JSON structured for Supabase:
- `team_info`: Team metadata (name, program, level, age division, tier, athlete count)
- `performance`: Competition details and final scores (competition name, round, raw score, total deductions, final score)
- `scores_building`, `scores_tumbling`, `scores_overall`: Category breakdowns with individual judge scores
- `deductions`: Array of non-zero deductions with counts (only includes deductions that occurred)

## Supabase Integration (iOS)

The iOS app includes infrastructure for cloud sync:
- `SupabaseService.swift` - API wrapper (add Supabase Swift SDK)
- `SyncManager.swift` - Offline-first sync with network monitoring and auto-retry
- `AppConfig.swift` - Configuration loader (reads from Info.plist or fallback values)
- SQL schema included in comments for table creation

### Sync Status
Each model has a `syncStatus` field:
- `SyncStatus` enum: `.pending`, `.syncing`, `.synced`, `.failed` (for Gym, Team, Competition)
- `ScoresheetSyncStatus` enum: same values, separate type for Scoresheet

To enable:
1. Add Supabase Swift package: `https://github.com/supabase/supabase-swift`
2. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to Info.plist, or
3. Update fallback values in `AppConfig.swift`

## Tech Stack

**Web:**
- React 18 with hooks (useState, useEffect)
- Tailwind CSS for styling

**iOS:**
- SwiftUI with @Observable
- SwiftData for persistence
- Swift Charts for analytics
- iOS 17.0+ required

## Important Implementation Notes

### Score Initialization

Scoresheets initialize with **maximum scores** (not zeros). This reflects the judging workflow where judges start at max and deduct points. See `Scoresheet.init()` in Models/Scoresheet.swift:86-117.

### Level-Aware Scoring

The app enforces level restrictions through the `ScoringRules` utility:

- `ScoringRules.buildingMax(forLevel:)` returns 18.0 for L1, 22.0 for others
- `ScoringRules.maxScore(forLevel:)` returns 46.0 for L1, 50.0 for others
- `ScoresheetViewModel.applyLevelRestrictions()` zeros out toss scores for L1 teams

### Computed Properties Pattern

Both implementations use computed properties for score totals (not stored values):

- **iOS**: Computed properties on `Scoresheet` model (lines 135-199)
- **Web**: `useEffect` recalculates totals when dependencies change

### Rounding Convention

All scores use 2-decimal precision via `.rounded2` extension (Scoresheet.swift:298-301).

### Sync Architecture

Models follow an offline-first pattern:

1. All changes saved locally to SwiftData immediately
2. `SyncManager` monitors network status with `NWPathMonitor`
3. Auto-syncs when connection restored
4. Each model tracks its own `syncStatus` independently

## Commit Hygiene

Before staging any commit, delete all intermediate patch artifacts from the working directory:
- `*.orig` files (e.g., `InsightsViewModel.swift.orig` — committed in PR #67)
- `patch.diff` or any `*.diff` files
- Temp Swift files not in the official Xcode target (e.g., `test_auth.swift`)
- `TECHNICAL_DEBT_LOG.md` — agent planning file committed 20+ times (PRs #58–#83). **HARD STOP — NEVER commit this file.** In `.gitignore` since 2026-04-09, untracked on 2026-04-12, **re-committed in every PR from #73–#83 via `git add -f` or `git add .`**. If it appears in staging: run `git reset HEAD TECHNICAL_DEBT_LOG.md && git rm --cached TECHNICAL_DEBT_LOG.md`. Stage files by explicit path only.
- `plan.md`, `test_plan.md` — planning artifacts committed in PRs #65–#66. **Never commit them.**
- `*.bak` files (e.g., `CLAUDE.md.bak` — committed in PR #76). **Never commit backup files.**

These are tools, not source code. All are now in `.gitignore`. Do not use `git add -f` or `git add .` to bypass gitignore — stage specific files by path only.
