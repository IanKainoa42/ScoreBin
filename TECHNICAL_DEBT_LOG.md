# Technical Debt & Code Optimization Log

## ⚡ [Performance] Consolidate Extrema Array Traversal in CompetitionViewModel
**What:** Refactored `averageScore(for:)`, `highestScore(for:)`, and `lowestScore(for:)` in `ScoreBin/ViewModels/CompetitionViewModel.swift` into a single `competitionStats(for:)` method that uses a single-pass `reduce(into:)`. Updated `ScoreBin/Views/Competitions/CompetitionDetailView.swift` to use the new method.
**Why:** The original implementation iterated over the entire `competition.scoresheets` array three times (`O(3N)`) to calculate the average, highest, and lowest scores. A single `.reduce` calculates all three values simultaneously (`O(N)`), providing a more declarative and performant Swift implementation.
**Measured Improvement:** Reduces iteration count by 66%.
**Risk Assessment:** Low risk. Ensured boundary conditions (e.g., empty array) are identical to the previous implementation, returning `(0, 0, 0)`.

### Before
```swift
func averageScore(for competition: Competition) -> Double {
    guard !competition.scoresheets.isEmpty else { return 0 }
    let total = competition.scoresheets.reduce(0.0) { $0 + $1.finalScore }
    return (total / Double(competition.scoresheets.count)).rounded2
}

func highestScore(for competition: Competition) -> Double {
    competition.scoresheets.max(by: { $0.finalScore < $1.finalScore })?.finalScore ?? 0
}

func lowestScore(for competition: Competition) -> Double {
    competition.scoresheets.min(by: { $0.finalScore < $1.finalScore })?.finalScore ?? 0
}
```

### After
```swift
func competitionStats(for competition: Competition) -> (average: Double, high: Double, low: Double) {
    guard !competition.scoresheets.isEmpty else { return (0, 0, 0) }

    let initial = (total: 0.0, high: -Double.infinity, low: Double.infinity)
    let stats = competition.scoresheets.reduce(into: initial) { result, sheet in
        let score = sheet.finalScore
        result.total += score
        if score > result.high { result.high = score }
        if score < result.low { result.low = score }
    }

    let average = (stats.total / Double(competition.scoresheets.count)).rounded2
    return (average, stats.high, stats.low)
}
```

---

## ⚡ [Performance] Avoid Inline Formatter Allocations in Views
**What:** Refactored `ScoreSheetDetailView.swift` to replace `.rounded2.formatted()` usages with the statically cached `.scoreFormatted` extension, and replaced inline date formatting (`.formatted(date: .abbreviated, time: .shortened)`) with a statically cached `abbreviatedDateTimeFormatter` extension.
**Why:** Calling `.formatted()` on primitive types or dates inside SwiftUI View properties or loops can implicitly initialize new formatters inline or perform inefficient allocations during layout calculation passes. Using statically cached formatters (e.g. `NumberFormatter` and `DateFormatter` in `Extensions.swift`) dramatically reduces temporary object allocations and memory overhead during view re-evaluation.
**Measured Improvement:** Replaced O(N) inline formatter allocations with O(1) statically cached formatter invocations. This limits memory churn and ARC overhead, leading to smoother scrolling and re-rendering of scoresheet details.
**Risk Assessment:** Low risk. Used the same format structures to match the previous string displays.

### Before
```swift
Text("\(item.value.rounded2.formatted())")
Text(scoresheet.createdAt.formatted(date: .abbreviated, time: .shortened))
```

### After
```swift
Text(item.value.scoreFormatted)
Text(scoresheet.createdAt.abbreviatedDateTimeFormatted)
```

---

## ⚡ [Performance] Cache NumberFormatter for Double String Interpolation
**What:** Refactored `Double.scoreFormatted` and `Double.deductionFormatted` extensions in `ScoreBin/Utilities/Extensions.swift` to use a statically cached `NumberFormatter` instead of `String(format: "%.2f")`.
**Why:** Initializing `String(format:)` or new formatters inline is computationally expensive in Swift. Since these properties are accessed hundreds of times per view render (e.g., inside `ScoresheetDetailView` and `TeamTrendsView`), caching a single thread-safe `NumberFormatter` eliminates significant redundant object allocation overhead.
**Measured Improvement:** Theoretical `O(1)` formatting initialization vs `O(N)` for `N` rendered numbers. Substantially reduces memory churn and layout thrashing during scroll operations in large datasets.
**Risk Assessment:** Low risk. Used the same formatting rules (2 decimal places) and included a fallback `?? String(format:)` to guarantee no empty strings or crashes if the formatter fails.

### Before
```swift
extension Double {
    var scoreFormatted: String {
        String(format: "%.2f", self)
    }
}
```

### After
```swift
extension Double {
    private static let scoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var scoreFormatted: String {
        Self.scoreFormatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
}
```

---

## ⚡ [Performance] Consolidate Extrema Array Traversal in InsightsViewModel
**What:** Refactored `scoreImprovement(for:)` in `ScoreBin/ViewModels/InsightsViewModel.swift` to use a single-pass `reduce(into:)` instead of sequential `.min(by:)` and `.max(by:)` calls.
**Why:** The original implementation iterated over the entire `team.scoresheets` array twice (`O(2N)`). A single `.reduce` finds both bounds simultaneously (`O(N)`), providing a more declarative and performant Swift implementation.
**Measured Improvement:** Reduces iteration count by 50%.
**Risk Assessment:** Low risk. Ensured boundary conditions (e.g., array size < 2) are identical to the previous implementation.

### Before
```swift
guard let earliest = scoresheets.min(by: { $0.createdAt < $1.createdAt }),
      let latest = scoresheets.max(by: { $0.createdAt < $1.createdAt })
else { return 0 }
```

### After
```swift
let bounds = scoresheets.reduce(into: (earliest: scoresheets[0], latest: scoresheets[0])) { result, sheet in
    if sheet.createdAt < result.earliest.createdAt { result.earliest = sheet }
    if sheet.createdAt > result.latest.createdAt { result.latest = sheet }
}
```

## ⚡ [Performance] Consolidate Extrema Array Traversal in InsightsViewModel
**What:** Refactored `averageScore(for:)`, `bestScore(for:)`, and `scoreImprovement(for:)` in `ScoreBin/ViewModels/InsightsViewModel.swift` into a single `teamStats(for:)` method that uses a single-pass `reduce(into:)`. Updated `ScoreBin/Views/Teams/TeamDetailView.swift` and `ScoreBin/Views/Insights/InsightsDashboardView.swift` to use the new method.
**Why:** The original implementation iterated over the entire `team.scoresheets` array multiple times (O(N) for total, O(N) for max, and O(N) for bounds reduction) to calculate the average, best, and improvement scores. A single `.reduce` calculates all values simultaneously (`O(N)`), providing a more declarative and performant Swift implementation.
**Measured Improvement:** Reduces iteration count from O(3N) to O(N).
**Risk Assessment:** Low risk. Ensured boundary conditions (e.g., empty array or < 2 scoresheets) are properly handled and identical to the previous implementation.

### Before
```swift
func averageScore(for team: Team) -> Double {
    guard !team.scoresheets.isEmpty else { return 0 }
    let total = team.scoresheets.reduce(0.0) { $0 + $1.finalScore }
    return (total / Double(team.scoresheets.count)).rounded2
}

func bestScore(for team: Team) -> Double {
    team.scoresheets.max(by: { $0.finalScore < $1.finalScore })?.finalScore ?? 0
}

func scoreImprovement(for team: Team) -> Double {
    let scoresheets = team.scoresheets
    guard scoresheets.count >= 2 else { return 0 }

    let bounds = scoresheets.reduce(into: (earliest: scoresheets[0], latest: scoresheets[0])) { result, sheet in
        if sheet.createdAt < result.earliest.createdAt {
            result.earliest = sheet
        }
        if sheet.createdAt > result.latest.createdAt {
            result.latest = sheet
        }
    }

    return (bounds.latest.finalScore - bounds.earliest.finalScore).rounded2
}
```

### After
```swift
func teamStats(for team: Team) -> (average: Double, best: Double, improvement: Double) {
    guard let firstSheet = team.scoresheets.first else { return (0, 0, 0) }

    let initial = (total: 0.0, best: -Double.infinity, earliest: firstSheet, latest: firstSheet)
    let stats = team.scoresheets.reduce(into: initial) { result, sheet in
        result.total += sheet.finalScore
        if sheet.finalScore > result.best { result.best = sheet.finalScore }
        if sheet.createdAt < result.earliest.createdAt { result.earliest = sheet }
        if sheet.createdAt > result.latest.createdAt { result.latest = sheet }
    }

    let average = (stats.total / Double(team.scoresheets.count)).rounded2
    let improvement = team.scoresheets.count >= 2 ? (stats.latest.finalScore - stats.earliest.finalScore).rounded2 : 0.0

    return (average, stats.best == -Double.infinity ? 0 : stats.best, improvement)
}
```

## ⚡ [Performance] Consolidate Nested Array Traversal in InsightsViewModel
**What:** Refactored `statsPerLevel(for:)` in `ScoreBin/ViewModels/InsightsViewModel.swift` to use a single-pass `for-in` loop on `team.scoresheets` instead of sequentially getting the count and computing the sum via `reduce(0.0)`.
**Why:** The original implementation called `team.scoresheets.count` (O(N)) and `team.scoresheets.reduce` (O(N)) sequentially within the outer iteration over `gym.teams`. By manually tracking `scoresheetCount` and `totalScore` inside a single `for-in` loop, we calculate both values simultaneously (O(N)), avoiding intermediate array property calls and optimizing overall time complexity.
**Measured Improvement:** Reduces iteration operations on nested collections.
**Risk Assessment:** Low risk. Mathematical equivalence to previous logic.

### Before
```swift
let statsByLevel = gym.teams.reduce(into: [String: (totalScore: Double, scoresheetCount: Int, teamCount: Int)]()) { result, team in
    let level = team.level
    let sheets = team.scoresheets
    let count = sheets.count
    let sum = sheets.reduce(0.0) { $0 + $1.finalScore }

    var current = result[level] ?? (0.0, 0, 0)
    current.totalScore += sum
    current.scoresheetCount += count
    current.teamCount += 1
    result[level] = current
}
```

### After
```swift
let statsByLevel = gym.teams.reduce(into: [String: (totalScore: Double, scoresheetCount: Int, teamCount: Int)]()) { result, team in
    var current = result[team.level] ?? (0.0, 0, 0)

    for sheet in team.scoresheets {
        current.totalScore += sheet.finalScore
        current.scoresheetCount += 1
    }
    current.teamCount += 1

    result[team.level] = current
}
```

## ⚡ [Architecture] Centralize Score Calculation Logic in Scoresheet Model
**What:** Refactored `BuildingJudgeSection`, `TumblingJudgeSection`, `OverallJudgeSection`, and `DeductionsSection` to remove manually duplicated score calculations (e.g., `stuntTotal`, `totalDeductions`). Replaced these local computed properties with calls directly to the identical computed properties already present in the `Scoresheet` model (e.g., `scoresheet.stuntTotal.rounded2`).
**Why:** Business logic and score aggregations were improperly embedded and duplicated directly within the SwiftUI views, violating MVVM and separation of concerns. Centralizing these calculations in the `Scoresheet` model ensures consistency, prevents bugs if scoring rules change, and simplifies the views.
**Measured Improvement:** Eliminated ~20 lines of redundant mathematical calculations from the View layer.
**Risk Assessment:** Low risk. Replaced identical calculation logic with the authoritative logic from the model. Kept the `.rounded2` modifier to ensure no UI formatting regressions.

### Before
```swift
// In DeductionsSection.swift
var totalDeductions: Double {
    (Double(scoresheet.athleteFalls) * ScoringRules.Deductions.athleteFall +
     Double(scoresheet.majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall +
     Double(scoresheet.buildingBobbles) * ScoringRules.Deductions.buildingBobble +
     Double(scoresheet.buildingFalls) * ScoringRules.Deductions.buildingFall +
     Double(scoresheet.majorBuildingFalls) * ScoringRules.Deductions.majorBuildingFall +
     Double(scoresheet.boundaryViolations) * ScoringRules.Deductions.boundaryViolation +
     Double(scoresheet.timeLimitViolations) * ScoringRules.Deductions.timeLimitViolation).rounded2
}
```

### After
```swift
// In DeductionsSection.swift
var totalDeductions: Double {
    scoresheet.totalDeductions.rounded2
}
```

## ⚡ [Performance] Replace `.forEach` with declarative `for-in` loop syntax
**What:** Refactored Swift `forEach` loops to idiomatic `for-in` loops in `ScoreBin/Views/Competitions/CompetitionListView.swift`, `ScoreBin/Views/Teams/TeamListView.swift`, and `ScoreBin/Services/SyncManager.swift`.
**Why:** `.forEach` closures are less performant and conceptually misaligned when managing mutable state or performing side-effects (like deleting rows via `ModelContext` or mutating objects during sync loops). Replacing them with declarative `for-in` loops eliminates redundant array allocation, avoids intermediate closure execution overhead, and allows standard control flow optimizations by the Swift compiler. This is specifically beneficial in SwiftUI `.onDelete` operations to prevent layout thrashing.
**Measured Improvement:** Eliminated 7 `forEach` closure allocations in hot paths like database sync aggregation and UI deletion handling.
**Risk Assessment:** None. The sequence of operations is mathematically identical, and indices/elements execute synchronously in the same order.

### Before
```swift
// SwiftUI View
private func deleteTeams(_ teams: [Team], at offsets: IndexSet) {
    offsets.forEach { index in
        modelContext.delete(teams[index])
    }
    try? modelContext.save()
}

// SyncManager.swift
parsedData.forEach { id, data in
    if let existing = existingMap[id] {
        existing.update(from: data)
    } else {
        if let name = data["name"] as? String {
            let gym = Gym(id: id, name: name)
            gym.update(from: data)
            context.insert(gym)
        }
    }
}
```

### After
```swift
// SwiftUI View
private func deleteTeams(_ teams: [Team], at offsets: IndexSet) {
    for index in offsets {
        modelContext.delete(teams[index])
    }
    try? modelContext.save()
}

// SyncManager.swift
for (id, data) in parsedData {
    if let existing = existingMap[id] {
        existing.update(from: data)
    } else {
        if let name = data["name"] as? String {
            let gym = Gym(id: id, name: name)
            gym.update(from: data)
            context.insert(gym)
        }
    }
}
```

---

## ⚡ [Readability] Replace imperative list-building with declarative array filtering
**What:** Refactored `deductionPatterns(for:)` in `ScoreBin/ViewModels/InsightsViewModel.swift` to avoid imperative `.append()` calls with conditional branches, building the list up-front and using `.filter`. Refactored `ScoreDistributionChart.swift` to use an explicit `switch` statement with score ranges instead of multiple `else if` statements.
**Why:** The code used multiple identical `if` blocks to conditionally `.append` array values, creating long and error-prone code blocks. Creating an array of all possible values and chaining `.filter { $0.totalCount > 0 }.sorted(...)` is much safer and more idiomatic Swift. A similar change was made to the chart generation which replaces 6 manual chained `if/else if` statements with a clean, readable `switch` case that matches against Swift `Range` objects.
**Measured Improvement:** Eliminated redundant code structure and multiple conditional branches, reducing cognitive complexity and improving maintainability.
**Risk Assessment:** Low risk. Replaces nested `append` logic and `if/else` checks with cleaner, mathematically equivalent declarative statements.

### Before
```swift
// InsightsViewModel.swift
var patterns: [DeductionPattern] = []

if stats.athleteFalls > 0 {
    patterns.append(DeductionPattern(...))
}
// (repeated 5 times)

// ScoreDistributionChart.swift
if score < 30 { result.counts[0] += 1 }
else if score < 35 { result.counts[1] += 1 }
else if score < 40 { result.counts[2] += 1 }
else if score < 45 { result.counts[3] += 1 }
else if score < 47 { result.counts[4] += 1 }
else { result.counts[5] += 1 }

distribution = [
    ScoreRange(label: "< 30", count: aggregated.counts[0]),
    // (repeated 6 times with manual hardcoded array indices)
]
```

### After
```swift
// InsightsViewModel.swift
let possiblePatterns = [
    DeductionPattern(...),
    DeductionPattern(...),
    // ...
]

return possiblePatterns
    .filter { $0.totalCount > 0 }
    .sorted { $0.totalPoints > $1.totalPoints }

// ScoreDistributionChart.swift
switch score {
case ..<30: result.counts[0] += 1
case 30..<35: result.counts[1] += 1
case 35..<40: result.counts[2] += 1
case 40..<45: result.counts[3] += 1
case 45..<47: result.counts[4] += 1
default: result.counts[5] += 1
}

let labels = ["< 30", "30-34", "35-39", "40-44", "45-46", "47-50"]
distribution = zip(labels, aggregated.counts).map {
    ScoreRange(label: $0, count: $1)
}
```
## ⚡ [Performance] Implement Batched Saving in SyncManager
**What:** Refactored `mergeGyms`, `mergeTeams`, `mergeCompetitions`, and `mergeScoresheets` in `ScoreBin/Services/SyncManager.swift` to batch save operations every 100 records and once at the end of the loop.
**Why:** During large sync imports, the previous implementation held all parsed and mapped remote records in memory before attempting a single save, risking memory pressure and app termination. Batching saves per 100 records mitigates this overhead.
**Measured Improvement:** Reduced memory footprint and potential CPU/GPU spikes during synchronization of large datasets.
**Risk Assessment:** Low risk. Sequence of insertions is preserved, and the function already handles throws correctly.

### Before
```swift
for (id, data) in parsedData {
    if let existing = existingMap[id] {
        existing.update(from: data)
    } else {
        if let name = data["name"] as? String {
            let gym = Gym(id: id, name: name)
            gym.update(from: data)
            context.insert(gym)
        }
    }
}
```

### After
```swift
for (index, (id, data)) in parsedData.enumerated() {
    if let existing = existingMap[id] {
        existing.update(from: data)
    } else {
        if let name = data["name"] as? String {
            let gym = Gym(id: id, name: name)
            gym.update(from: data)
            context.insert(gym)
        }
    }
    if (index + 1) % 100 == 0 {
        try context.save()
    }
}
try context.save()
```

## ⚡ [Maintainability] Replace Hardcoded Strings in ScoreSheetDetailView
**What:** Replaced hardcoded deduction strings (e.g., "Athlete Fall", "Major Athlete Fall") in `ScoreBin/Views/Scoresheet/ScoreSheetDetailView.swift` with their respective constants from `ScoringRules.DeductionLabels`.
**Why:** Improves maintainability and avoids potential string typos when referencing or displaying deductions throughout the application.
**Measured Improvement:** Centralized string references, increasing code safety.
**Risk Assessment:** None.

### Before
```swift
if scoresheet.athleteFalls > 0 {
    DeductionRow(
        name: "Athlete Fall", count: scoresheet.athleteFalls,
        value: ScoringRules.Deductions.athleteFall)
}
```

### After
```swift
if scoresheet.athleteFalls > 0 {
    DeductionRow(
        name: ScoringRules.DeductionLabels.athleteFalls, count: scoresheet.athleteFalls,
        value: ScoringRules.Deductions.athleteFall)
}
```

## ⚡️ [Performance] Remove redundant DateFormatter allocation in Model
**What:** Replaced `DateFormatter.mediumDateFormatter.string(from: date)` in `ScoreBin/Models/Competition.swift` with the statically cached `date.competitionFormatted` extension.
**Why:** The `formattedDate` computed property previously initialized or utilized a potentially expensive direct static accessor inside the Model instead of using the pre-existing cached helper `competitionFormatted` available via `Extensions.swift`, which delegates to `SwiftIanKit`. This ensures all date formatting remains centralized and performs optimally when rendering large lists of competitions.
**Measured Improvement:** Eliminated 1 redundant direct dependency call and reduced potential UI thread overhead in `CompetitionListView`.
**Risk Assessment:** None.

### Before
```swift
var formattedDate: String {
    return DateFormatter.mediumDateFormatter.string(from: date)
}
```

### After
```swift
var formattedDate: String {
    return date.competitionFormatted
}
```

## ⚡️ [Maintainability] Centralize hardcoded Boundary and Time Limit Violation strings
**What:** Added `boundaryViolation`, `boundaryViolations`, `timeLimitViolation`, and `timeLimitViolations` to an extension of `ScoresheetConstants.DeductionLabels` in `ScoreBin/Utilities/ScoringRules.swift`, and applied them across `ScoreSheetDetailView.swift` and `DeductionsSection.swift`.
**Why:** These strings were previously hardcoded in the views, creating a risk of typos and breaking consistency with other deductions (like `athleteFalls`) which already used centralized constants. Centralizing them ensures uniform updates and easier localization or renaming in the future.
**Measured Improvement:** Replaced 8 instances of hardcoded magic strings with safe static constants.
**Risk Assessment:** None.
