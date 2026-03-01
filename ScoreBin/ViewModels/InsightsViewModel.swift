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
        let active = teams.lazy.filter { !$0.scoresheets.isEmpty }
        if let limit {
            return Array(active.prefix(limit))
        }
        return Array(active)
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
        let teamsByLevel = Dictionary(grouping: gym.teams, by: { $0.level })

        return teamsByLevel.map { level, teams in
            let stats = teams.reduce(into: (totalScore: 0.0, scoresheetCount: 0)) { result, team in
                result.scoresheetCount += team.scoresheets.count
                result.totalScore += team.scoresheets.reduce(0.0) { $0 + $1.finalScore }
            }

            let avgScore = stats.scoresheetCount == 0 ? 0 : stats.totalScore / Double(stats.scoresheetCount)

            return GymLevelStats(
                level: level,
                averageScore: avgScore.rounded2,
                teamCount: teams.count,
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

        let count = Double(team.scoresheets.count)
        let totals = team.scoresheets.reduce(into: (building: 0.0, tumbling: 0.0, overall: 0.0)) { result, sheet in
            result.building += sheet.buildingTotal
            result.tumbling += sheet.tumblingTotal
            result.overall += sheet.overallTotal
        }

        let avgBuilding = totals.building / count
        let avgTumbling = totals.tumbling / count
        let avgOverall = totals.overall / count

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
        let stats = team.scoresheets.reduce(into: (athleteFalls: 0, majorAthleteFalls: 0, buildingBobbles: 0, buildingFalls: 0, majorBuildingFalls: 0)) { result, sheet in
            result.athleteFalls += sheet.athleteFalls
            result.majorAthleteFalls += sheet.majorAthleteFalls
            result.buildingBobbles += sheet.buildingBobbles
            result.buildingFalls += sheet.buildingFalls
            result.majorBuildingFalls += sheet.majorBuildingFalls
        }

        var patterns: [DeductionPattern] = []

        if stats.athleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.athleteFalls,
                totalCount: stats.athleteFalls,
                totalPoints: Double(stats.athleteFalls) * ScoringRules.Deductions.athleteFall
            ))
        }

        if stats.majorAthleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.majorAthleteFalls,
                totalCount: stats.majorAthleteFalls,
                totalPoints: Double(stats.majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall
            ))
        }

        if stats.buildingBobbles > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.buildingBobbles,
                totalCount: stats.buildingBobbles,
                totalPoints: Double(stats.buildingBobbles) * ScoringRules.Deductions.buildingBobble
            ))
        }

        if stats.buildingFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.buildingFalls,
                totalCount: stats.buildingFalls,
                totalPoints: Double(stats.buildingFalls) * ScoringRules.Deductions.buildingFall
            ))
        }

        if stats.majorBuildingFalls > 0 {
            patterns.append(DeductionPattern(
                category: ScoringRules.DeductionLabels.majorBuildingFalls,
                totalCount: stats.majorBuildingFalls,
                totalPoints: Double(stats.majorBuildingFalls) * ScoringRules.Deductions.majorBuildingFall
            ))
        }

        return patterns.sorted { $0.totalPoints > $1.totalPoints }
    }

    // MARK: - View Helpers
}
