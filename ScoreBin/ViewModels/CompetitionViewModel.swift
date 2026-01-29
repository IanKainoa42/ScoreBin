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

    func averageScore(for competition: Competition) -> Double {
        guard !competition.scoresheets.isEmpty else { return 0 }
        let total = competition.scoresheets.reduce(0) { $0 + $1.finalScore }
        return (total / Double(competition.scoresheets.count)).rounded2
    }

    func highestScore(for competition: Competition) -> Double {
        competition.scoresheets.max(by: { $0.finalScore < $1.finalScore })?.finalScore ?? 0
    }

    func lowestScore(for competition: Competition) -> Double {
        competition.scoresheets.min(by: { $0.finalScore < $1.finalScore })?.finalScore ?? 0
    }

    func scoresheetsByRound(for competition: Competition) -> [String: [Scoresheet]] {
        Dictionary(grouping: competition.scoresheets) { $0.round }
    }
}
