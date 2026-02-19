# ScoreBin UX Friction Audit
**Date:** 2026-02-03
**Method:** Code Review (app won't launch in simulator)
**Tabs Reviewed:** Teams, Competitions, Insights, Scoresheet

---

## Tab Order Issue

### Critical
- **Scoresheet is last tab** — Core action buried in 4th position. Users open app to enter scores, not browse teams. → Move Scoresheet to first tab position.

### High
- **No clear primary CTA** — All 4 tabs have equal weight. Where should a new user start? → Consider onboarding flow or prominent "Start Scoring" button.

---

## Scoresheet Entry View

### Critical
- **Team/Competition selection in header, not form** — "Select Team" and "Select Competition" are dropdowns in header. If user forgets to select, scores are orphaned. → Make selection required before enabling score fields, or add validation.
- **Reset button is destructive, positioned left** — "Reset" in red on top-left toolbar. One tap clears all scores. → Add confirmation dialog.

### High
- **Quantity Chart display is passive** — Shows "Majority=4, Most=5, Max=6" but what does that mean? → Link to explanation or show contextually during score entry.
- **Round picker defaults to... what?** — `viewModel.scoresheet.round` shown but unclear initial state. → Default to "Day 1" or most common.
- **Save flow loses context** — Save → Alert "Saved" → OK → Auto-reset. User may not expect reset after save. → Offer "Save & Continue" vs "Save & New".

### Medium
- **Three separate judge sections (Building/Tumbling/Overall)** — Logical but scrolling-heavy. Each section has multiple score rows. → Consider collapsible sections or tabs within scoresheet.
- **Score Summary at bottom** — User must scroll to see totals while entering scores in top sections. → Sticky summary bar or floating total display.

### Low
- **Deductions Section** — Well-structured with counters. Could add quick-tap increment buttons.

---

## Insights Dashboard

### High
- **Empty state messaging weak** — "No scoresheets yet", "Add scoresheets to teams to see performance data" — passive. → Add CTA: "Enter your first scoresheet →".
- **Score Distribution chart without context** — What's a "good" distribution? No benchmarks. → Add league average or target zones.

### Medium
- **Recent Activity shows "Unknown Team"** — Fallback when team association missing. This shouldn't happen in production. → Require team selection on scoresheet.
- **Team Performance limited to 5** — `.prefix(5)` hardcoded. No way to see all teams. → Add "See All" link or pagination.

### Low
- **Chart height fixed at 200** — `.frame(height: 200)` may be cramped on iPad, wasteful on iPhone SE. → Use responsive sizing.

---

## Teams Tab

### High
- **No search/filter** — Team list grows unbounded. Scrolling to find "Chaos" among 18 teams is painful. → Add search bar.
- **Gym is optional** — "No Gym" option allows orphan teams. Fine for flexibility, but could lead to messy data. → Consider requiring gym or showing "Independent" label.

### Medium
- **Level picker shows "L2" as raw string** — Matches data but "Level 2" would be clearer to new users. → Humanize labels.
- **Athlete count stepper (5-38)** — Good range limits. But why these numbers? → Add help text explaining quantity chart.

### Low
- **Division/Tier pickers** — Well-structured. ".capitalized" formatting is clean.

---

## Add Team Flow

### Medium
- **Required vs Optional unclear** — Name is required (validated), Gym is optional, but visual distinction is subtle. → Add "(required)" label or asterisk.
- **Quantity Chart preview is nice** — Shows chart result as user adjusts athlete count. Good UX.

### Low
- **Cancel/Add buttons follow iOS conventions** — Correct placement.

---

## Cross-Screen Issues

### High
- **Dark theme throughout** — `.scoreBinBackground`, `.scoreBinCardBackground` suggest custom dark theme. Ensure contrast ratios meet WCAG AA. → Audit color contrast.
- **No onboarding** — New user sees 4 tabs, no guidance. → Add first-run walkthrough or contextual hints.
- **Sync status invisible** — Models have `syncStatus` but no UI indicator. User doesn't know if data is backed up. → Add sync indicator in settings or header.

### Medium
- **Navigation patterns inconsistent** — Some views use NavigationStack, some use NavigationLink. Audit for back button behavior.
- **Error handling absent in UI** — Code shows `try? modelContext.save()` — errors silently swallowed. → Show error toasts.

---

## Priority Matrix

| Fix | Impact | Effort | Priority |
|-----|--------|--------|----------|
| Move Scoresheet to first tab | High | Trivial | **P0** |
| Add Reset confirmation | High | Low | **P0** |
| Require team selection before scoring | High | Medium | **P1** |
| Add search to Teams tab | Medium | Medium | **P1** |
| Add first-run onboarding | Medium | Medium | **P2** |
| Sticky score summary | Medium | Medium | **P2** |
| Actionable empty states | Low | Low | **P3** |
| Sync status indicator | Low | Medium | **P3** |

---

## Quick Wins (< 1 hour each)

1. Reorder tabs: Scoresheet → Teams → Competitions → Insights
2. Add alert confirmation to Reset button
3. Add search bar to TeamListView
4. Change empty state text to include CTA buttons
5. Add "(required)" to team name field
6. Default round to "Day 1"

---

## Related
- [[Universal-Inbox-App]] - Another app in pipeline
- [[CheerCenter]] - Sister app for team management
