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
        let id = UUID()
        let date: Date
        let score: Double
        let label: String
    }

    func activeTeams(from teams: [Team], limit: Int? = nil) -> [Team] {
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
        guard team.scoresheets.count >= 2 else { return 0 }

        // Find earliest and latest scoresheets in a single pass
        var earliest = team.scoresheets[0]
        var latest = team.scoresheets[0]

        for sheet in team.scoresheets.dropFirst() {
            if sheet.createdAt < earliest.createdAt {
                earliest = sheet
            }
            if sheet.createdAt > latest.createdAt {
                latest = sheet
            }
        }

        return (latest.finalScore - earliest.finalScore).rounded2
    }

    // MARK: - Gym Analytics

    struct GymLevelStats: Identifiable {
        let id = UUID()
        let level: String
        let averageScore: Double
        let teamCount: Int
        let scoresheetCount: Int
    }

    func statsPerLevel(for gym: Gym) -> [GymLevelStats] {
        let teamsByLevel = Dictionary(grouping: gym.teams, by: { $0.level })

        return teamsByLevel.map { level, teams in
            var totalScore: Double = 0
            var scoresheetCount = 0

            for team in teams {
                scoresheetCount += team.scoresheets.count
                totalScore += team.scoresheets.reduce(0) { $0 + $1.finalScore }
            }

            let avgScore = scoresheetCount == 0 ? 0 : totalScore / Double(scoresheetCount)

            return GymLevelStats(
                level: level,
                averageScore: avgScore.rounded2,
                teamCount: teams.count,
                scoresheetCount: scoresheetCount
            )
        }.sorted { $0.level < $1.level }
    }

    // MARK: - Category Breakdown

    struct CategoryBreakdown: Identifiable {
        let id = UUID()
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
        var totalBuilding = 0.0
        var totalTumbling = 0.0
        var totalOverall = 0.0

        for sheet in team.scoresheets {
            totalBuilding += sheet.buildingTotal
            totalTumbling += sheet.tumblingTotal
            totalOverall += sheet.overallTotal
        }

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
        let id = UUID()
        let category: String
        let totalCount: Int
        let totalPoints: Double
    }

    func deductionPatterns(for team: Team) -> [DeductionPattern] {
        let totals = team.scoresheets.reduce(into: (0, 0, 0, 0, 0)) { result, sheet in
            result.0 += sheet.athleteFalls
            result.1 += sheet.majorAthleteFalls
            result.2 += sheet.buildingBobbles
            result.3 += sheet.buildingFalls
            result.4 += sheet.majorBuildingFalls
        }

        let (athleteFalls, majorAthleteFalls, buildingBobbles, buildingFalls, majorBuildingFalls) = totals

        var patterns: [DeductionPattern] = []

        if athleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: "Athlete Falls",
                totalCount: athleteFalls,
                totalPoints: Double(athleteFalls) * ScoringRules.Deductions.athleteFall
            ))
        }

        if majorAthleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: "Major Athlete Falls",
                totalCount: majorAthleteFalls,
                totalPoints: Double(majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall
            ))
        }

        if buildingBobbles > 0 {
            patterns.append(DeductionPattern(
                category: "Building Bobbles",
                totalCount: buildingBobbles,
                totalPoints: Double(buildingBobbles) * ScoringRules.Deductions.buildingBobble
            ))
        }

        if buildingFalls > 0 {
            patterns.append(DeductionPattern(
                category: "Building Falls",
                totalCount: buildingFalls,
                totalPoints: Double(buildingFalls) * ScoringRules.Deductions.buildingFall
            ))
        }

        if majorBuildingFalls > 0 {
            patterns.append(DeductionPattern(
                category: "Major Building Falls",
                totalCount: majorBuildingFalls,
                totalPoints: Double(majorBuildingFalls) * ScoringRules.Deductions.majorBuildingFall
            ))
        }

        return patterns.sorted { $0.totalPoints > $1.totalPoints }
    }

    // MARK: - View Helpers
}
