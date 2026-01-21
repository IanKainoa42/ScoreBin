# ScoreBin iOS App Setup

## Creating the Xcode Project

Since Xcode projects have a complex binary format, follow these steps to set up your project:

### Step 1: Create New Xcode Project

1. Open Xcode
2. File > New > Project
3. Select **iOS > App**
4. Configure the project:
   - Product Name: `ScoreBin`
   - Organization Identifier: `com.yourcompany` (or your preferred identifier)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (check this option)
5. Save the project in the `ScoreBin` folder (replacing the existing `ScoreBin` folder)

### Step 2: Add Existing Files

1. In Xcode, right-click on the `ScoreBin` folder in the navigator
2. Select "Add Files to ScoreBin..."
3. Navigate to the `ScoreBin/ScoreBin` folder we created
4. Select all the folders and files:
   - `Models/`
   - `Views/`
   - `ViewModels/`
   - `Services/`
   - `Utilities/`
   - `ScoreBinApp.swift`
5. Make sure "Copy items if needed" is **unchecked** (files are already in place)
6. Make sure "Create groups" is selected
7. Click "Add"

### Step 3: Delete Generated Files

Xcode will have generated some default files. Delete these:
- `ContentView.swift` (we have our own views)
- The auto-generated `Item.swift` model (we have our own models)

### Step 4: Update App Entry Point

The generated `ScoreBinApp.swift` should be replaced with our version. If Xcode created one, delete it and ensure our `ScoreBinApp.swift` is used.

### Step 5: Add Required Frameworks

The app uses Swift Charts. This is included in iOS 16+ SDK.

Ensure your deployment target is set to:
- **iOS 17.0** or later (for SwiftData)

### Step 6: Optional - Add Supabase SDK

If you want cloud sync functionality:

1. File > Add Package Dependencies
2. Enter URL: `https://github.com/supabase/supabase-swift`
3. Add the `Supabase` product to your target
4. Update `SupabaseService.swift` with your Supabase project credentials

## Project Structure

After setup, your project should have this structure:

```
ScoreBin/
├── ScoreBinApp.swift
├── Models/
│   ├── Gym.swift
│   ├── Team.swift
│   ├── Competition.swift
│   └── Scoresheet.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Scoresheet/
│   │   ├── ScoresheetEntryView.swift
│   │   ├── ScoreInputRow.swift
│   │   ├── BuildingJudgeSection.swift
│   │   ├── TumblingJudgeSection.swift
│   │   ├── OverallJudgeSection.swift
│   │   ├── DeductionsSection.swift
│   │   └── ScoreSummaryView.swift
│   ├── Competitions/
│   │   ├── CompetitionListView.swift
│   │   ├── CompetitionDetailView.swift
│   │   └── AddCompetitionView.swift
│   ├── Teams/
│   │   ├── TeamListView.swift
│   │   ├── TeamDetailView.swift
│   │   └── AddTeamView.swift
│   └── Insights/
│       ├── InsightsDashboardView.swift
│       ├── TeamTrendsView.swift
│       ├── GymAnalyticsView.swift
│       └── ScoreDistributionChart.swift
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

## Running the App

1. Select an iOS Simulator (iPhone 15 Pro recommended)
2. Press Cmd+R to build and run
3. The app should launch with four tabs:
   - **Scoresheet**: Enter scores
   - **Competitions**: Manage competitions
   - **Teams**: Manage teams and gyms
   - **Insights**: View analytics and trends

## Testing the Scoring Calculation

1. Go to the Scoresheet tab
2. Enter scores in each section
3. Verify the totals match the React version:
   - Building Total should max at 23.0
   - Tumbling Total should max at 20.0
   - Overall Total should max at 8.0 (includes averaged creativity/showmanship)
   - Final Score = Raw Score - Deductions

## Supabase Setup (Optional)

To enable cloud sync:

1. Create a Supabase project at https://supabase.com
2. Run the SQL schema from `SupabaseService.swift` comments in the SQL Editor
3. Get your project URL and anon key from Settings > API
4. Update `SupabaseService.swift` with your credentials
5. Add the Supabase Swift package to your project

## Features

- **Scoresheet Entry**: Full implementation of United Scoring System 2025-2026
- **Local Persistence**: All data saved with SwiftData
- **Competition Tracking**: Organize scoresheets by competition
- **Team Management**: Track teams by gym/program
- **Analytics**: Score trends, category breakdowns, deduction patterns
- **Cloud Sync** (when configured): Offline-first sync with Supabase
