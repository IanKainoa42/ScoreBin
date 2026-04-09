import Foundation
import SwiftUI
import SwiftData

@Observable
class CompetitionViewModel {
    var modelContext: ModelContext?

    struct CompetitionSummary {
        let totalScoresheets: Int
        let averageScore: Double
        let highestScore: Double
        let lowestScore: Double
        let scoresheetsByRound: [String: [Scoresheet]]
        let sortedRounds: [String]
    }

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    func createCompetition(name: String, date: Date, location: String, notes: String = "") -> Competition {
        let competition = Competition(
            name: name,
            date: date,
            location: location,
            notes: notes
        )

        if let context = modelContext {
            context.insert(competition)
            try? context.save()
        }

        return competition
    }

    func deleteCompetition(_ competition: Competition) {
        guard let context = modelContext else { return }
        context.delete(competition)
        try? context.save()
    }

    func updateCompetition(_ competition: Competition, name: String, date: Date, location: String, notes: String) {
        competition.name = name
        competition.date = date
        competition.location = location
        competition.notes = notes

        try? modelContext?.save()
    }

    // MARK: - Statistics

    func summary(for competition: Competition) -> CompetitionSummary {
        let scoresheets = competition.scoresheets

        guard !scoresheets.isEmpty else {
            return CompetitionSummary(
                totalScoresheets: 0,
                averageScore: 0,
                highestScore: 0,
                lowestScore: 0,
                scoresheetsByRound: [:],
                sortedRounds: []
            )
        }

        let aggregates = scoresheets.reduce(
            into: (
                count: 0,
                totalScore: 0.0,
                highest: -Double.infinity,
                lowest: Double.infinity,
                byRound: [String: [Scoresheet]]()
            )
        ) { result, sheet in
            result.count += 1
            result.totalScore += sheet.finalScore
            result.highest = max(result.highest, sheet.finalScore)
            result.lowest = min(result.lowest, sheet.finalScore)
            result.byRound[sheet.round, default: []].append(sheet)
        }

        let scoresheetsByRound = aggregates.byRound.mapValues {
            $0.sorted { $0.createdAt > $1.createdAt }
        }
        let sortedRounds = scoresheetsByRound.keys.sorted { lhs, rhs in
            let lhsIndex = roundSortIndex(lhs)
            let rhsIndex = roundSortIndex(rhs)
            if lhsIndex == rhsIndex {
                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
            return lhsIndex < rhsIndex
        }

        return CompetitionSummary(
            totalScoresheets: aggregates.count,
            averageScore: (aggregates.totalScore / Double(aggregates.count)).rounded2,
            highestScore: aggregates.highest.rounded2,
            lowestScore: aggregates.lowest.rounded2,
            scoresheetsByRound: scoresheetsByRound,
            sortedRounds: sortedRounds
        )
    }

    private func roundSortIndex(_ round: String) -> Int {
        if let index = RoundType.allCases.firstIndex(where: { $0.rawValue == round }) {
            return index
        }

        return RoundType.allCases.count
    }
}
