import Foundation
import SwiftUI
import SwiftData

@Observable
class CompetitionViewModel {
    var modelContext: ModelContext?

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

    func scoresheetsByRound(for competition: Competition) -> [String: [Scoresheet]] {
        Dictionary(grouping: competition.scoresheets) { $0.round }
    }
}
