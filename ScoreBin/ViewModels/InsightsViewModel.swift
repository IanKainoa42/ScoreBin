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

    struct TeamSummary {
        let team: Team
        let totalScoresheets: Int
        let sortedScoresheets: [Scoresheet]
        let recentScoresheets: [Scoresheet]
        let scoreHistory: [ScoreDataPoint]
        let averageScore: Double
        let bestScore: Double
        let scoreImprovement: Double
        let categoryBreakdown: [CategoryBreakdown]
        let deductionPatterns: [DeductionPattern]
    }

    struct RecentActivitySummary: Identifiable {
        let id: UUID
        let teamName: String
        let competitionName: String?
        let createdAt: Date
        let finalScore: Double
    }

    struct DashboardSnapshot {
        let teamCount: Int
        let scoresheetCount: Int
        let competitionCount: Int
        let recentActivity: [RecentActivitySummary]
        let distributionScores: [Double]
        let teamSummaries: [TeamSummary]

        static let empty = DashboardSnapshot(
            teamCount: 0,
            scoresheetCount: 0,
            competitionCount: 0,
            recentActivity: [],
            distributionScores: [],
            teamSummaries: []
        )
    }

    func activeTeams(from teams: [Team], limit: Int? = nil) -> [Team] {
        guard !teams.isEmpty else { return [] }
        let active = teams.lazy.filter { !$0.scoresheets.isEmpty }
        if let limit {
            return Array(active.prefix(limit))
        }
        return Array(active)
    }

    @MainActor
    func dashboardSnapshot(context: ModelContext) throws -> DashboardSnapshot {
        let teamCount = try context.fetchCount(FetchDescriptor<Team>())
        let competitionCount = try context.fetchCount(FetchDescriptor<Competition>())

        let scoresheetDescriptor = FetchDescriptor<Scoresheet>(
            sortBy: [SortDescriptor(\Scoresheet.createdAt, order: .reverse)]
        )
        let scoresheets = try context.fetch(scoresheetDescriptor)

        let recentActivity = scoresheets.prefix(5).map { sheet in
            RecentActivitySummary(
                id: sheet.id,
                teamName: sheet.team?.name ?? "Unknown Team",
                competitionName: sheet.competition?.name,
                createdAt: sheet.createdAt,
                finalScore: sheet.finalScore
            )
        }

        let teamDescriptor = FetchDescriptor<Team>(
            sortBy: [SortDescriptor(\Team.name)]
        )
        let activeTeamSummaries = try context.fetch(teamDescriptor)
            .lazy
            .filter { !$0.scoresheets.isEmpty }
            .prefix(5)
            .map { self.teamSummary(for: $0) }

        return DashboardSnapshot(
            teamCount: teamCount,
            scoresheetCount: scoresheets.count,
            competitionCount: competitionCount,
            recentActivity: Array(recentActivity),
            distributionScores: scoresheets.map(\.finalScore),
            teamSummaries: Array(activeTeamSummaries)
        )
    }

    func teamSummary(for team: Team, recentLimit: Int? = nil) -> TeamSummary {
        let sortedScoresheets = team.scoresheets.sorted { $0.createdAt > $1.createdAt }
        let totalScoresheets = sortedScoresheets.count
        let buildingMax = ScoringRules.buildingMax(forLevel: team.level)

        guard totalScoresheets > 0 else {
            return TeamSummary(
                team: team,
                totalScoresheets: 0,
                sortedScoresheets: [],
                recentScoresheets: [],
                scoreHistory: [],
                averageScore: 0,
                bestScore: 0,
                scoreImprovement: 0,
                categoryBreakdown: emptyCategoryBreakdown(buildingMax: buildingMax),
                deductionPatterns: []
            )
        }

        let history = sortedScoresheets.reversed().map { sheet in
            ScoreDataPoint(
                id: sheet.id,
                date: sheet.createdAt,
                score: sheet.finalScore,
                label: sheet.competition?.name ?? "Practice"
            )
        }

        let totals = sortedScoresheets.reduce(
            into: (
                finalScore: 0.0,
                building: 0.0,
                tumbling: 0.0,
                overall: 0.0,
                athleteFalls: 0,
                majorAthleteFalls: 0,
                buildingBobbles: 0,
                buildingFalls: 0,
                majorBuildingFalls: 0,
                bestScore: -Double.infinity
            )
        ) { result, sheet in
            result.finalScore += sheet.finalScore
            result.building += sheet.buildingTotal
            result.tumbling += sheet.tumblingTotal
            result.overall += sheet.overallTotal
            result.athleteFalls += sheet.athleteFalls
            result.majorAthleteFalls += sheet.majorAthleteFalls
            result.buildingBobbles += sheet.buildingBobbles
            result.buildingFalls += sheet.buildingFalls
            result.majorBuildingFalls += sheet.majorBuildingFalls
            result.bestScore = max(result.bestScore, sheet.finalScore)
        }

        let count = Double(totalScoresheets)
        let recentScoresheets = recentLimit.map { Array(sortedScoresheets.prefix($0)) } ?? sortedScoresheets
        let scoreImprovement: Double = {
            guard totalScoresheets >= 2,
                  let firstScore = sortedScoresheets.first?.finalScore,
                  let lastScore = sortedScoresheets.last?.finalScore else {
                return 0.0
            }
            return (firstScore - lastScore).rounded2
        }()

        return TeamSummary(
            team: team,
            totalScoresheets: totalScoresheets,
            sortedScoresheets: sortedScoresheets,
            recentScoresheets: recentScoresheets,
            scoreHistory: history,
            averageScore: (totals.finalScore / count).rounded2,
            bestScore: totals.bestScore.rounded2,
            scoreImprovement: scoreImprovement,
            categoryBreakdown: categoryBreakdown(
                building: totals.building / count,
                tumbling: totals.tumbling / count,
                overall: totals.overall / count,
                buildingMax: buildingMax
            ),
            deductionPatterns: deductionPatterns(
                athleteFalls: totals.athleteFalls,
                majorAthleteFalls: totals.majorAthleteFalls,
                buildingBobbles: totals.buildingBobbles,
                buildingFalls: totals.buildingFalls,
                majorBuildingFalls: totals.majorBuildingFalls
            )
        )
    }

    func scoreHistory(for team: Team) -> [ScoreDataPoint] {
        teamSummary(for: team).scoreHistory
    }

    func averageScore(for team: Team) -> Double {
        teamSummary(for: team).averageScore
    }

    func bestScore(for team: Team) -> Double {
        teamSummary(for: team).bestScore
    }

    func scoreImprovement(for team: Team) -> Double {
        teamSummary(for: team).scoreImprovement
    }

    // MARK: - Gym Analytics

    struct GymLevelStats: Identifiable {
        var id: String { level }
        let level: String
        let averageScore: Double
        let teamCount: Int
        let scoresheetCount: Int
    }

    struct GymSummary {
        let teamCount: Int
        let totalScoresheets: Int
        let totalAthletes: Int
        let levelStats: [GymLevelStats]
        let sortedTeams: [Team]
    }

    func gymSummary(for gym: Gym) -> GymSummary {
        let sortedTeams = gym.teams.sorted {
            if $0.level == $1.level {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.level.localizedCaseInsensitiveCompare($1.level) == .orderedAscending
        }

        let aggregates = sortedTeams.reduce(
            into: (
                scoresheets: 0,
                athletes: 0,
                statsByLevel: [String: (totalScore: Double, scoresheetCount: Int, teamCount: Int)]()
            )
        ) { result, team in
            let count = team.scoresheets.count
            let sum = team.scoresheets.reduce(0.0) { $0 + $1.finalScore }

            result.scoresheets += count
            result.athletes += team.athleteCount

            var current = result.statsByLevel[team.level] ?? (0.0, 0, 0)
            current.totalScore += sum
            current.scoresheetCount += count
            current.teamCount += 1
            result.statsByLevel[team.level] = current
        }

        let levelStats = aggregates.statsByLevel.map { level, stats in
            let averageScore =
                stats.scoresheetCount == 0 ? 0 : stats.totalScore / Double(stats.scoresheetCount)

            return GymLevelStats(
                level: level,
                averageScore: averageScore.rounded2,
                teamCount: stats.teamCount,
                scoresheetCount: stats.scoresheetCount
            )
        }
        .sorted { (lhs: GymLevelStats, rhs: GymLevelStats) in
            lhs.level.localizedCaseInsensitiveCompare(rhs.level) == .orderedAscending
        }

        return GymSummary(
            teamCount: sortedTeams.count,
            totalScoresheets: aggregates.scoresheets,
            totalAthletes: aggregates.athletes,
            levelStats: levelStats,
            sortedTeams: sortedTeams
        )
    }

    func statsPerLevel(for gym: Gym) -> [GymLevelStats] {
        gymSummary(for: gym).levelStats
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
        teamSummary(for: team).categoryBreakdown
    }

    // MARK: - Deduction Patterns

    struct DeductionPattern: Identifiable {
        var id: String { category }
        let category: String
        let totalCount: Int
        let totalPoints: Double
    }

    func deductionPatterns(for team: Team) -> [DeductionPattern] {
        teamSummary(for: team).deductionPatterns
    }

    // MARK: - View Helpers

    private func emptyCategoryBreakdown(buildingMax: Double) -> [CategoryBreakdown] {
        [
            CategoryBreakdown(category: "Building", score: 0, maxScore: buildingMax, percentage: 0),
            CategoryBreakdown(
                category: "Tumbling",
                score: 0,
                maxScore: ScoringRules.Maximums.tumblingTotal,
                percentage: 0
            ),
            CategoryBreakdown(
                category: "Overall",
                score: 0,
                maxScore: ScoringRules.Maximums.overallTotal,
                percentage: 0
            ),
        ]
    }

    private func categoryBreakdown(
        building: Double,
        tumbling: Double,
        overall: Double,
        buildingMax: Double
    ) -> [CategoryBreakdown] {
        [
            CategoryBreakdown(
                category: "Building",
                score: building.rounded2,
                maxScore: buildingMax,
                percentage: (building / buildingMax * 100).rounded2
            ),
            CategoryBreakdown(
                category: "Tumbling",
                score: tumbling.rounded2,
                maxScore: ScoringRules.Maximums.tumblingTotal,
                percentage: (tumbling / ScoringRules.Maximums.tumblingTotal * 100).rounded2
            ),
            CategoryBreakdown(
                category: "Overall",
                score: overall.rounded2,
                maxScore: ScoringRules.Maximums.overallTotal,
                percentage: (overall / ScoringRules.Maximums.overallTotal * 100).rounded2
            ),
        ]
    }

    private func deductionPatterns(
        athleteFalls: Int,
        majorAthleteFalls: Int,
        buildingBobbles: Int,
        buildingFalls: Int,
        majorBuildingFalls: Int
    ) -> [DeductionPattern] {
        let possiblePatterns = [
            DeductionPattern(
                category: ScoringRules.DeductionLabels.athleteFalls,
                totalCount: athleteFalls,
                totalPoints: Double(athleteFalls) * ScoringRules.Deductions.athleteFall
            ),
            DeductionPattern(
                category: ScoringRules.DeductionLabels.majorAthleteFalls,
                totalCount: majorAthleteFalls,
                totalPoints: Double(majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall
            ),
            DeductionPattern(
                category: ScoringRules.DeductionLabels.buildingBobbles,
                totalCount: buildingBobbles,
                totalPoints: Double(buildingBobbles) * ScoringRules.Deductions.buildingBobble
            ),
            DeductionPattern(
                category: ScoringRules.DeductionLabels.buildingFalls,
                totalCount: buildingFalls,
                totalPoints: Double(buildingFalls) * ScoringRules.Deductions.buildingFall
            ),
            DeductionPattern(
                category: ScoringRules.DeductionLabels.majorBuildingFalls,
                totalCount: majorBuildingFalls,
                totalPoints: Double(majorBuildingFalls) * ScoringRules.Deductions.majorBuildingFall
            )
        ]

        return possiblePatterns
            .filter { $0.totalCount > 0 }
            .sorted { $0.totalPoints > $1.totalPoints }
    }
}
