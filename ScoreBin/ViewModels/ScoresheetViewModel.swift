import Foundation
import SwiftUI
import SwiftData

@Observable
class ScoresheetViewModel {
    var scoresheet: Scoresheet
    var modelContext: ModelContext?

    // Team selection
    var selectedTeam: Team? {
        didSet {
            scoresheet.team = selectedTeam
        }
    }

    // Competition selection
    var selectedCompetition: Competition? {
        didSet {
            scoresheet.competition = selectedCompetition
        }
    }

    init(scoresheet: Scoresheet? = nil, modelContext: ModelContext? = nil) {
        self.scoresheet = scoresheet ?? Scoresheet()
        self.modelContext = modelContext
        self.selectedTeam = self.scoresheet.team
        self.selectedCompetition = self.scoresheet.competition
    }

    // MARK: - Computed Properties

    var quantityChart: ScoringRules.QuantityChart {
        ScoringRules.QuantityChart.forAthleteCount(selectedTeam?.athleteCount ?? 20)
    }

    // MARK: - Building Judge Totals

    var stuntTotal: Double {
        scoresheet.stuntTotal.rounded2
    }

    var pyramidTotal: Double {
        scoresheet.pyramidTotal.rounded2
    }

    var tossTotal: Double {
        scoresheet.tossTotal.rounded2
    }

    var buildingTotal: Double {
        scoresheet.buildingTotal.rounded2
    }

    // MARK: - Tumbling Judge Totals

    var standingTotal: Double {
        scoresheet.standingTotal.rounded2
    }

    var runningTotal: Double {
        scoresheet.runningTotal.rounded2
    }

    var jumpsTotal: Double {
        scoresheet.jumpsTotal.rounded2
    }

    var tumblingTotal: Double {
        scoresheet.tumblingTotal.rounded2
    }

    // MARK: - Overall Judge Totals

    var danceTotal: Double {
        scoresheet.danceTotal.rounded2
    }

    var creativityAvg: Double {
        scoresheet.creativityAverage.rounded2
    }

    var showmanshipAvg: Double {
        scoresheet.showmanshipAverage.rounded2
    }

    var overallTotal: Double {
        scoresheet.overallTotal.rounded2
    }

    // MARK: - Final Scores

    var totalDeductions: Double {
        scoresheet.totalDeductions.rounded2
    }

    var rawScore: Double {
        scoresheet.rawScore.rounded2
    }

    var finalScore: Double {
        scoresheet.finalScore.rounded2
    }

    // MARK: - Save/Load

    func save() {
        guard let context = modelContext else { return }

        if scoresheet.team == nil {
            scoresheet.team = selectedTeam
        }
        if scoresheet.competition == nil {
            scoresheet.competition = selectedCompetition
        }

        context.insert(scoresheet)

        do {
            try context.save()
        } catch {
            print("Failed to save scoresheet: \(error)")
        }
    }

    func reset() {
        scoresheet = Scoresheet()
        scoresheet.team = selectedTeam
        scoresheet.competition = selectedCompetition
    }

    // MARK: - Export

    func exportJSON() -> String? {
        let data = scoresheet.exportForDatabase()

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to export JSON: \(error)")
            return nil
        }
    }

    func copyToClipboard() {
        if let json = exportJSON() {
            UIPasteboard.general.string = json
        }
    }
}
