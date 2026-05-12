import Foundation
import SwiftData
import SwiftUI

@Observable
class ScoresheetViewModel {
    var scoresheet: Scoresheet
    var modelContext: ModelContext?

    // Team selection
    var selectedTeam: Team? {
        didSet {
            scoresheet.team = selectedTeam
            applyLevelRestrictions()
        }
    }

    /// Returns true if tosses are allowed for the current team
    var areTossesAllowed: Bool {
        ScoringRules.isTossAllowed(forLevel: selectedTeam?.level)
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

    // MARK: - Level-Aware Maximums

    /// Maximum building score for current team's level (18 for L1, 22 for others)
    var maxBuildingScore: Double {
        ScoringRules.buildingMax(forLevel: selectedTeam?.level)
    }

    /// Maximum tumbling score (always 20)
    var maxTumblingScore: Double {
        ScoringRules.Maximums.tumblingTotal
    }

    /// Maximum overall score (always 8)
    var maxOverallScore: Double {
        ScoringRules.Maximums.overallTotal
    }

    /// Maximum total score for current team's level (46 for L1, 50 for others)
    var maxTotalScore: Double {
        ScoringRules.maxScore(forLevel: selectedTeam?.level)
    }

    // MARK: - Save/Load

    func save() {
        guard let context = modelContext else { return }
        guard let selectedTeam else {
            // Prevent orphan scoresheets; UI should already block this.
            print("Cannot save scoresheet without a selected team")
            return
        }

        scoresheet.team = selectedTeam
        if scoresheet.competition == nil {
            scoresheet.competition = selectedCompetition
        }

        context.insert(scoresheet)

        do {
            try context.save()
            Task { @MainActor in
                SyncManager.shared.markForSync(scoresheet)
            }
        } catch {
            print("Failed to save scoresheet: \(error)")
        }
    }

    func reset() {
        scoresheet = Scoresheet()
        scoresheet.team = selectedTeam
        scoresheet.competition = selectedCompetition
        applyLevelRestrictions()
    }

    /// Applies level-specific restrictions (e.g., no tosses for L1)
    func applyLevelRestrictions() {
        if !areTossesAllowed {
            scoresheet.tossDifficulty = 0
            scoresheet.tossExecution = 0
        }
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

    // MARK: - Import

    func applyImportDraft(_ draft: ScoresheetImportDraft) {
        let importedScoresheet = Scoresheet(
            id: draft.id,
            createdAt: draft.createdAt,
            team: selectedTeam,
            competition: selectedCompetition,
            round: draft.round
        )

        for fieldID in ScoresheetFieldID.allCases {
            if let value = draft.parsedFields[fieldID]?.candidateValue {
                fieldID.apply(value, to: importedScoresheet)
            }
        }

        if !ScoringRules.isTossAllowed(forLevel: selectedTeam?.level) {
            importedScoresheet.tossDifficulty = 0
            importedScoresheet.tossExecution = 0
        }

        importedScoresheet.importedAt = draft.createdAt
        importedScoresheet.importSourceType = draft.sourceType.rawValue
        importedScoresheet.importSourceRelativePath = draft.sourceRelativePath
        importedScoresheet.importPreviewRelativePath = draft.previewRelativePath
        importedScoresheet.parserVersion = draft.parserVersion
        importedScoresheet.syncStatus = .pending

        scoresheet = importedScoresheet
        scoresheet.team = selectedTeam
        scoresheet.competition = selectedCompetition
    }
}
