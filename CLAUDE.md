# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

### Navigation
Four-tab structure:
1. **Scoresheet** - Main score entry form
2. **Competitions** - List/manage competitions
3. **Teams** - Manage teams and gyms
4. **Insights** - Analytics dashboard with Swift Charts

### Key Files
- `ScoringRules.swift` - All scoring constants, ranges, deduction values
- `Extensions.swift` - Color theme (dark mode), view modifiers
- `ScoresheetViewModel.swift` - Score calculation logic (mirrors React version)

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

### Maximum Scores
- Building Total: 23.0 (Stunt 10 + Pyramid 9 + Toss 4)
- Tumbling Total: 20.0 (Standing 8 + Running 8 + Jumps 4)
- Overall Total: 8.0 (Dance 2 + Formations 2 + Creativity 2 + Showmanship 2)
- **Max Score: 51.0**

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

## Database Export Format

Both versions export JSON structured for Supabase:
- `team_info`: Team metadata
- `performance`: Competition details and final scores
- `scores_building`, `scores_tumbling`, `scores_overall`: Category breakdowns
- `deductions`: Array of non-zero deductions with counts

## Supabase Integration (iOS)

The iOS app includes infrastructure for cloud sync:
- `SupabaseService.swift` - API wrapper (add Supabase Swift SDK)
- `SyncManager.swift` - Offline-first sync with conflict resolution
- SQL schema included in comments for table creation

To enable:
1. Add Supabase Swift package
2. Configure URL and anon key in `SupabaseService.swift`

## Tech Stack

**Web:**
- React 18 with hooks (useState, useEffect)
- Tailwind CSS for styling

**iOS:**
- SwiftUI with @Observable
- SwiftData for persistence
- Swift Charts for analytics
- iOS 17.0+ required
