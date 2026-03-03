import Foundation
import SwiftUI
import SwiftData

@Observable
class InsightsViewModel {
    var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Team Trends

    struct ScoreDataPoint: Identifiable {
        let id: UUID
        let date: Date
        let score: Double
        let label: String
    }

    func activeTeams(from teams: [Team], limit: Int? = nil) -> [Team] {
        guard !teams.isEmpty else { return [] }
        // Note: Removed .lazy as we're converting back to Array immediately anyway
        let active = teams.filter { !$0.scoresheets.isEmpty }
        if let limit {
            return Array(active.prefix(limit))
        }
        return active
    }

    func scoreHistory(for team: Team) -> [ScoreDataPoint] {
        team.scoresheets
            .map { sheet in
                ScoreDataPoint(
                    id: sheet.id,
                    date: sheet.createdAt,
                    score: sheet.finalScore,
                    label: sheet.competition?.name ?? "Practice"
                )
            }
            .sorted { $0.date < $1.date }
    }

    func averageScore(for team: Team) -> Double {
        guard !team.scoresheets.isEmpty else { return 0 }
        let total = team.scoresheets.reduce(0.0) { $0 + $1.finalScore }
        return (total / Double(team.scoresheets.count)).rounded2
    }

    func bestScore(for team: Team) -> Double {
        team.scoresheets.map(\.finalScore).max() ?? 0
    }

    func scoreImprovement(for team: Team) -> Double {
        let scoresheets = team.scoresheets
        guard scoresheets.count >= 2 else { return 0 }

        guard let earliest = scoresheets.min(by: { $0.createdAt < $1.createdAt }),
              let latest = scoresheets.max(by: { $0.createdAt < $1.createdAt })
        else { return 0 }

        return (latest.finalScore - earliest.finalScore).rounded2
    }

    // MARK: - Gym Analytics

    struct GymLevelStats: Identifiable {
        var id: String { level }
        let level: String
        let averageScore: Double
        let teamCount: Int
        let scoresheetCount: Int
    }

    func statsPerLevel(for gym: Gym) -> [GymLevelStats] {
        var statsByLevel: [String: (totalScore: Double, scoresheetCount: Int, teamCount: Int)] = [:]

        for team in gym.teams {
            let level = team.level
            let sheets = team.scoresheets
            let count = sheets.count
            let sum = sheets.reduce(0.0) { $0 + $1.finalScore }

            var current = statsByLevel[level] ?? (0.0, 0, 0)
            current.totalScore += sum
            current.scoresheetCount += count
            current.teamCount += 1
            statsByLevel[level] = current
        }

        return statsByLevel.map { level, stats in
            let avgScore =
                stats.scoresheetCount == 0 ? 0 : stats.totalScore / Double(stats.scoresheetCount)

            return GymLevelStats(
                level: level,
                averageScore: avgScore.rounded2,
                teamCount: stats.teamCount,
                scoresheetCount: stats.scoresheetCount
            )
        }.sorted { $0.level < $1.level }
    }

    // MARK: - Category Breakdown

    struct CategoryBreakdown: Identifiable {
        var id: String { category }
        let category: String
        let score: Double
        let maxScore: Double
        let percentage: Double
    }

    func categoryBreakdown(for scoresheet: Scoresheet) -> [CategoryBreakdown] {
        let level = scoresheet.team?.level
        let buildingMax = ScoringRules.buildingMax(forLevel: level)

        return [
            CategoryBreakdown(
                category: "Building",
                score: scoresheet.buildingTotal.rounded2,
                maxScore: buildingMax,
                percentage: (scoresheet.buildingTotal / buildingMax * 100).rounded2
            ),
            CategoryBreakdown(
                category: "Tumbling",
                score: scoresheet.tumblingTotal.rounded2,
                maxScore: ScoringRules.Maximums.tumblingTotal,
                percentage: (scoresheet.tumblingTotal / ScoringRules.Maximums.tumblingTotal * 100).rounded2
            ),
            CategoryBreakdown(
                category: "Overall",
                score: scoresheet.overallTotal.rounded2,
                maxScore: ScoringRules.Maximums.overallTotal,
                percentage: (scoresheet.overallTotal / ScoringRules.Maximums.overallTotal * 100).rounded2
            )
        ]
    }

    func averageCategoryBreakdown(for team: Team) -> [CategoryBreakdown] {
        let buildingMax = ScoringRules.buildingMax(forLevel: team.level)

        guard !team.scoresheets.isEmpty else {
            return [
                CategoryBreakdown(category: "Building", score: 0, maxScore: buildingMax, percentage: 0),
                CategoryBreakdown(category: "Tumbling", score: 0, maxScore: ScoringRules.Maximums.tumblingTotal, percentage: 0),
                CategoryBreakdown(category: "Overall", score: 0, maxScore: ScoringRules.Maximums.overallTotal, percentage: 0)
            ]
        }

        let (totalBuilding, totalTumbling, totalOverall) = team.scoresheets.reduce((0.0, 0.0, 0.0)) { result, sheet in
            (result.0 + sheet.buildingTotal, result.1 + sheet.tumblingTotal, result.2 + sheet.overallTotal)
        }

        let count = Double(team.scoresheets.count)
        let avgBuilding = totalBuilding / count
        let avgTumbling = totalTumbling / count
        let avgOverall = totalOverall / count

        return [
            CategoryBreakdown(
                category: "Building",
                score: avgBuilding.rounded2,
                maxScore: buildingMax,
                percentage: (avgBuilding / buildingMax * 100).rounded2
            ),
            CategoryBreakdown(
                category: "Tumbling",
                score: avgTumbling.rounded2,
                maxScore: ScoringRules.Maximums.tumblingTotal,
                percentage: (avgTumbling / ScoringRules.Maximums.tumblingTotal * 100).rounded2
            ),
            CategoryBreakdown(
                category: "Overall",
                score: avgOverall.rounded2,
                maxScore: ScoringRules.Maximums.overallTotal,
                percentage: (avgOverall / ScoringRules.Maximums.overallTotal * 100).rounded2
            )
        ]
    }

    // MARK: - Deduction Patterns

    struct DeductionPattern: Identifiable {
        var id: String { category }
        let category: String
        let totalCount: Int
        let totalPoints: Double
    }

    func deductionPatterns(for team: Team) -> [DeductionPattern] {
        var athleteFalls = 0
        var majorAthleteFalls = 0
        var buildingBobbles = 0
        var buildingFalls = 0
        var majorBuildingFalls = 0

        for sheet in team.scoresheets {
            athleteFalls += sheet.athleteFalls
            majorAthleteFalls += sheet.majorAthleteFalls
            buildingBobbles += sheet.buildingBobbles
            buildingFalls += sheet.buildingFalls
            majorBuildingFalls += sheet.majorBuildingFalls
        }

        var patterns: [DeductionPattern] = []

        if athleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.athleteFalls,
                totalCount: athleteFalls,
                totalPoints: Double(athleteFalls) * ScoringRules.Deductions.athleteFall
            ))
        }

        if majorAthleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.majorAthleteFalls,
                totalCount: majorAthleteFalls,
                totalPoints: Double(majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall
            ))
        }

        if buildingBobbles > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.buildingBobbles,
                totalCount: buildingBobbles,
                totalPoints: Double(buildingBobbles) * ScoringRules.Deductions.buildingBobble
            ))
        }

        if buildingFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.buildingFalls,
                totalCount: buildingFalls,
                totalPoints: Double(buildingFalls) * ScoringRules.Deductions.buildingFall
            ))
        }

        if majorBuildingFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.majorBuildingFalls,
                totalCount: majorBuildingFalls,
                totalPoints: Double(majorBuildingFalls) * ScoringRules.Deductions.majorBuildingFall
            ))
        }

        return patterns.sorted { $0.totalPoints > $1.totalPoints }
    }

    // MARK: - View Helpers
}
