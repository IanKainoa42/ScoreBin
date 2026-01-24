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
        team.scoresheets.map { $0.finalScore }.max() ?? 0
    }

    func scoreImprovement(for team: Team) -> Double {
        let sorted = team.scoresheets.sorted { $0.createdAt < $1.createdAt }
        guard sorted.count >= 2 else { return 0 }

        let firstScore = sorted.first!.finalScore
        let lastScore = sorted.last!.finalScore

        return (lastScore - firstScore).rounded2
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
            let allScoresheets = teams.flatMap { $0.scoresheets }
            let avgScore = allScoresheets.isEmpty ? 0 :
                allScoresheets.reduce(0) { $0 + $1.finalScore } / Double(allScoresheets.count)

            return GymLevelStats(
                level: level,
                averageScore: avgScore.rounded2,
                teamCount: teams.count,
                scoresheetCount: allScoresheets.count
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
        let avgBuilding = team.scoresheets.reduce(0) { $0 + $1.buildingTotal } / count
        let avgTumbling = team.scoresheets.reduce(0) { $0 + $1.tumblingTotal } / count
        let avgOverall = team.scoresheets.reduce(0) { $0 + $1.overallTotal } / count

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
        var patterns: [DeductionPattern] = []

        let athleteFalls = team.scoresheets.reduce(0) { $0 + $1.athleteFalls }
        if athleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: "Athlete Falls",
                totalCount: athleteFalls,
                totalPoints: Double(athleteFalls) * ScoringRules.Deductions.athleteFall
            ))
        }

        let majorAthleteFalls = team.scoresheets.reduce(0) { $0 + $1.majorAthleteFalls }
        if majorAthleteFalls > 0 {
            patterns.append(DeductionPattern(
                category: "Major Athlete Falls",
                totalCount: majorAthleteFalls,
                totalPoints: Double(majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall
            ))
        }

        let buildingBobbles = team.scoresheets.reduce(0) { $0 + $1.buildingBobbles }
        if buildingBobbles > 0 {
            patterns.append(DeductionPattern(
                category: "Building Bobbles",
                totalCount: buildingBobbles,
                totalPoints: Double(buildingBobbles) * ScoringRules.Deductions.buildingBobble
            ))
        }

        let buildingFalls = team.scoresheets.reduce(0) { $0 + $1.buildingFalls }
        if buildingFalls > 0 {
            patterns.append(DeductionPattern(
                category: "Building Falls",
                totalCount: buildingFalls,
                totalPoints: Double(buildingFalls) * ScoringRules.Deductions.buildingFall
            ))
        }

        let majorBuildingFalls = team.scoresheets.reduce(0) { $0 + $1.majorBuildingFalls }
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
