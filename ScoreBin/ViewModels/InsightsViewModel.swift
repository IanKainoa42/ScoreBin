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

    func activeTeams(from teams: [Team]) -> [Team] {
        teams.filter { !$0.scoresheets.isEmpty }
    }

    func scoreHistory(for team: Team) -> [ScoreDataPoint] {
        team.scoresheets
            .sorted { $0.createdAt < $1.createdAt }
            .map { sheet in
                ScoreDataPoint(
                    date: sheet.createdAt,
                    score: sheet.finalScore,
                    label: sheet.competition?.name ?? "Practice"
                )
            }
    }

    func averageScore(for team: Team) -> Double {
        guard !team.scoresheets.isEmpty else { return 0 }
        let total = team.scoresheets.reduce(0) { $0 + $1.finalScore }
        return (total / Double(team.scoresheets.count)).rounded2
    }

    func bestScore(for team: Team) -> Double {
        team.scoresheets.max(by: { $0.finalScore < $1.finalScore })?.finalScore ?? 0
    }

    func scoreImprovement(for team: Team) -> Double {
        guard team.scoresheets.count >= 2 else { return 0 }

        // Find earliest and latest scoresheets without sorting the entire array (O(N) vs O(N log N))
        guard let first = team.scoresheets.min(by: { $0.createdAt < $1.createdAt }),
              let last = team.scoresheets.max(by: { $0.createdAt < $1.createdAt })
        else {
            return 0
        }

        return (last.finalScore - first.finalScore).rounded2
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
        let teamsByLevel = Dictionary(grouping: gym.teams) { $0.level }

        return teamsByLevel.map { level, teams in
            var totalScore: Double = 0
            var scoresheetCount: Int = 0

            for team in teams {
                for scoresheet in team.scoresheets {
                    totalScore += scoresheet.finalScore
                    scoresheetCount += 1
                }
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
        let (totalBuilding, totalTumbling, totalOverall) = team.scoresheets.reduce((0.0, 0.0, 0.0)) { result, sheet in
            (result.0 + sheet.buildingTotal, result.1 + sheet.tumblingTotal, result.2 + sheet.overallTotal)
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

    func recentScoresheets(from scoresheets: [Scoresheet], limit: Int = 5) -> [Scoresheet] {
        scoresheets
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }

    func activeTeams(from teams: [Team], limit: Int = 5) -> [Team] {
        teams
            .filter { !$0.scoresheets.isEmpty }
            .prefix(limit)
            .map { $0 }
    }
}
