# ScoreBin Subagents

Custom subagents for common problems in the ScoreBin cheerleading scoring app.

## Quick Reference

| Subagent | Purpose | Priority Issue |
|----------|---------|----------------|
| **scoring-validator** | Validate scoring logic and business rules | 🔴 High - Invalid data risk |
| **test-generator** | Create unit tests for critical paths | 🔴 High - No test coverage |
| **sync-debugger** | Debug and improve sync infrastructure | 🔴 High - Data loss risk |
| **error-handler** | Replace silent failures with proper handling | 🔴 High - Invisible failures |
| **platform-parity-checker** | Find iOS/web inconsistencies | 🟠 Medium - UX confusion |
| **analytics-optimizer** | Improve dashboard performance | 🟠 Medium - Slow at scale |
| **rules-engine-builder** | Make scoring rules configurable | 🟠 Medium - Inflexible |
| **export-import-builder** | Add CSV export and data import | 🟡 Low - Feature request |

## How to Use

Each subagent has:
1. **Purpose** - What problem it solves
2. **When to Use** - Triggering scenarios
3. **Prompt Template** - Copy and customize for your task
4. **Example Invocation** - Ready-to-use Task call

### Basic Pattern

```javascript
Task({
  description: "Short description (3-5 words)",
  subagent_type: "general-purpose",  // or "Explore", "Bash", "Plan"
  prompt: `[Paste template, fill in TASK section]`
})
```

### Running Multiple Subagents in Parallel

For independent tasks, launch multiple subagents simultaneously:

```javascript
// Single message with multiple Task calls
Task({
  description: "Validate scoring logic",
  subagent_type: "general-purpose",
  prompt: "..."
})

Task({
  description: "Check platform parity",
  subagent_type: "Explore",
  prompt: "..."
})
```

## Subagent Types

- **general-purpose**: Full tool access - use for implementation tasks
- **Explore**: Fast codebase exploration - use for research/discovery
- **Bash**: Command execution - use for git, build, test commands
- **Plan**: Architecture planning - use for design decisions

## Project Context

**ScoreBin** implements the United Scoring System 2025-2026 for cheerleading judges.

**Tech Stack:**
- iOS: SwiftUI + SwiftData (iOS 17+)
- Web: React 18 + Tailwind CSS

**Key Files:**
- Scoring: `Scoresheet.swift`, `ScoringRules.swift`, `ScoresheetForm.jsx`
- Sync: `SyncManager.swift`, `SupabaseService.swift`
- Analytics: `InsightsViewModel.swift`, `InsightsDashboardView.swift`

**Scoring Panels:**
- Building: Stunt (10) + Pyramid (8) + Tosses (4) = 22 max
- Tumbling: Standing (8) + Running (8) + Jumps (4) = 20 max
- Overall: Dance (2) + Formations (2) + Creativity (4) = 8 max
- **Level 1 Restriction:** Tosses = 0, building max = 18, total max = 46
