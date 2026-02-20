import Foundation
import SwiftData

enum RoundType: String, Codable, CaseIterable {
    case day1 = "Day 1"
    case day2 = "Day 2"
    case finals = "Finals"
    case exhibition = "Exhibition"
}

// Local, unambiguous sync status for Scoresheet
enum ScoresheetSyncStatus: String, Codable {
    case pending
    case syncing
    case synced
    case failed
}

@Model
final class Scoresheet {
    var id: UUID
    var createdAt: Date
    var team: Team?
    var competition: Competition?
    var round: String

    // MARK: - Building Judge Scores
    var stuntDifficulty: Double
    var stuntExecution: Double
    var stuntDriverDegree: Double
    var stuntDriverMaxPart: Double
    var pyramidDifficulty: Double
    var pyramidExecution: Double
    var pyramidDrivers: Double
    var tossDifficulty: Double
    var tossExecution: Double
    var buildingCreativity: Double
    var buildingShowmanship: Double

    // MARK: - Tumbling Judge Scores
    var standingDifficulty: Double
    var standingExecution: Double
    var standingDrivers: Double
    var runningDifficulty: Double
    var runningExecution: Double
    var runningDrivers: Double
    var runningDriverMaxPart: Double
    var jumpsDifficulty: Double
    var jumpsExecution: Double
    var tumblingCreativity: Double
    var tumblingShowmanship: Double

    // MARK: - Overall Judge Scores
    var danceDifficulty: Double
    var danceExecution: Double
    var formations: Double
    var overallCreativity: Double
    var overallShowmanship: Double

    // MARK: - Deductions (stored as counts)
    var athleteFalls: Int
    var majorAthleteFalls: Int
    var buildingBobbles: Int
    var buildingFalls: Int
    var majorBuildingFalls: Int
    var boundaryViolations: Int
    var timeLimitViolations: Int

    // MARK: - Sync
    var syncStatus: ScoresheetSyncStatus
    var supabaseId: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        team: Team? = nil,
        competition: Competition? = nil,
        round: String = RoundType.day1.rawValue
    ) {
        self.id = id
        self.createdAt = createdAt
        self.team = team
        self.competition = competition
        self.round = round

        // Building defaults (start at max)
        self.stuntDifficulty = ScoringRules.Maximums.stuntDifficulty
        self.stuntExecution = ScoringRules.Maximums.stuntExecution
        self.stuntDriverDegree = ScoringRules.Maximums.stuntDriverDegree
        self.stuntDriverMaxPart = ScoringRules.Maximums.stuntDriverMaxPart
        self.pyramidDifficulty = ScoringRules.Maximums.pyramidDifficulty
        self.pyramidExecution = ScoringRules.Maximums.pyramidExecution
        self.pyramidDrivers = 0  // Not used in scoring system
        self.tossDifficulty = ScoringRules.Maximums.tossDifficulty
        self.tossExecution = ScoringRules.Maximums.tossExecution
        self.buildingCreativity = ScoringRules.Maximums.creativity
        self.buildingShowmanship = ScoringRules.Maximums.showmanship

        // Tumbling defaults (start at max)
        self.standingDifficulty = ScoringRules.Maximums.standingDifficulty
        self.standingExecution = ScoringRules.Maximums.standingExecution
        self.standingDrivers = ScoringRules.Maximums.standingDrivers
        self.runningDifficulty = ScoringRules.Maximums.runningDifficulty
        self.runningExecution = ScoringRules.Maximums.runningExecution
        self.runningDrivers = ScoringRules.Maximums.runningDrivers
        self.runningDriverMaxPart = ScoringRules.Maximums.runningDriverMaxPart
        self.jumpsDifficulty = ScoringRules.Maximums.jumpsDifficulty
        self.jumpsExecution = ScoringRules.Maximums.jumpsExecution
        self.tumblingCreativity = ScoringRules.Maximums.creativity
        self.tumblingShowmanship = ScoringRules.Maximums.showmanship

        // Overall defaults (start at max)
        self.danceDifficulty = ScoringRules.Maximums.danceDifficulty
        self.danceExecution = ScoringRules.Maximums.danceExecution
        self.formations = ScoringRules.Maximums.formations
        self.overallCreativity = ScoringRules.Maximums.creativity
        self.overallShowmanship = ScoringRules.Maximums.showmanship

        // Deductions
        self.athleteFalls = 0
        self.majorAthleteFalls = 0
        self.buildingBobbles = 0
        self.buildingFalls = 0
        self.majorBuildingFalls = 0
        self.boundaryViolations = 0
        self.timeLimitViolations = 0

        // Sync
        self.syncStatus = ScoresheetSyncStatus.pending
        self.supabaseId = nil
    }

    // MARK: - Computed Totals

    var stuntTotal: Double {
        stuntDifficulty + stuntExecution + stuntDriverDegree + stuntDriverMaxPart
    }

    var pyramidTotal: Double {
        pyramidDifficulty + pyramidExecution
    }

    var tossTotal: Double {
        tossDifficulty + tossExecution
    }

    var buildingTotal: Double {
        stuntTotal + pyramidTotal + tossTotal
    }

    var standingTotal: Double {
        standingDifficulty + standingExecution + standingDrivers
    }

    var runningTotal: Double {
        runningDifficulty + runningExecution + runningDrivers + runningDriverMaxPart
    }

    var jumpsTotal: Double {
        jumpsDifficulty + jumpsExecution
    }

    var tumblingTotal: Double {
        standingTotal + runningTotal + jumpsTotal
    }

    var danceTotal: Double {
        danceDifficulty + danceExecution
    }

    var creativityAverage: Double {
        (buildingCreativity + tumblingCreativity + overallCreativity) / 3.0
    }

    var showmanshipAverage: Double {
        (buildingShowmanship + tumblingShowmanship + overallShowmanship) / 3.0
    }

    var overallTotal: Double {
        danceTotal + formations + creativityAverage + showmanshipAverage
    }

    var totalDeductions: Double {
        Double(athleteFalls) * ScoringRules.Deductions.athleteFall + Double(majorAthleteFalls)
            * ScoringRules.Deductions.majorAthleteFall + Double(buildingBobbles)
            * ScoringRules.Deductions.buildingBobble + Double(buildingFalls)
            * ScoringRules.Deductions.buildingFall + Double(majorBuildingFalls)
            * ScoringRules.Deductions.majorBuildingFall + Double(boundaryViolations)
            * ScoringRules.Deductions.boundaryViolation + Double(timeLimitViolations)
            * ScoringRules.Deductions.timeLimitViolation
    }

    var rawScore: Double {
        buildingTotal + tumblingTotal + overallTotal
    }

    var maxScore: Double {
        ScoringRules.maxScore(forLevel: team?.level)
    }

    var percentPerfection: Double {
        guard maxScore > 0 else { return 0 }
        return (rawScore / maxScore) * 100.0
    }

    var finalScore: Double {
        max(0, percentPerfection - totalDeductions)
    }

    // MARK: - Export for Database

    func exportForDatabase() -> [String: Any] {
        return [
            DatabaseSchema.Scoresheet.id: id.uuidString,
            DatabaseSchema.Scoresheet.teamId: team?.id.uuidString ?? NSNull(),
            DatabaseSchema.Scoresheet.competitionId: competition?.id.uuidString ?? NSNull(),
            DatabaseSchema.Scoresheet.round: round,
            DatabaseSchema.Scoresheet.createdAt: ISO8601DateFormatter.shared.string(from: createdAt),

            // Building scores
            DatabaseSchema.Scoresheet.stuntDifficulty: stuntDifficulty,
            DatabaseSchema.Scoresheet.stuntExecution: stuntExecution,
            DatabaseSchema.Scoresheet.stuntDriverDegree: stuntDriverDegree,
            DatabaseSchema.Scoresheet.stuntDriverMaxPart: stuntDriverMaxPart,
            DatabaseSchema.Scoresheet.pyramidDifficulty: pyramidDifficulty,
            DatabaseSchema.Scoresheet.pyramidExecution: pyramidExecution,
            DatabaseSchema.Scoresheet.pyramidDrivers: pyramidDrivers,
            DatabaseSchema.Scoresheet.tossDifficulty: tossDifficulty,
            DatabaseSchema.Scoresheet.tossExecution: tossExecution,
            DatabaseSchema.Scoresheet.buildingCreativity: buildingCreativity,
            DatabaseSchema.Scoresheet.buildingShowmanship: buildingShowmanship,

            // Tumbling scores
            DatabaseSchema.Scoresheet.standingDifficulty: standingDifficulty,
            DatabaseSchema.Scoresheet.standingExecution: standingExecution,
            DatabaseSchema.Scoresheet.standingDrivers: standingDrivers,
            DatabaseSchema.Scoresheet.runningDifficulty: runningDifficulty,
            DatabaseSchema.Scoresheet.runningExecution: runningExecution,
            DatabaseSchema.Scoresheet.runningDrivers: runningDrivers,
            DatabaseSchema.Scoresheet.runningDriverMaxPart: runningDriverMaxPart,
            DatabaseSchema.Scoresheet.jumpsDifficulty: jumpsDifficulty,
            DatabaseSchema.Scoresheet.jumpsExecution: jumpsExecution,
            DatabaseSchema.Scoresheet.tumblingCreativity: tumblingCreativity,
            DatabaseSchema.Scoresheet.tumblingShowmanship: tumblingShowmanship,

            // Overall scores
            DatabaseSchema.Scoresheet.danceDifficulty: danceDifficulty,
            DatabaseSchema.Scoresheet.danceExecution: danceExecution,
            DatabaseSchema.Scoresheet.formations: formations,
            DatabaseSchema.Scoresheet.overallCreativity: overallCreativity,
            DatabaseSchema.Scoresheet.overallShowmanship: overallShowmanship,

            // Deductions
            DatabaseSchema.Scoresheet.athleteFalls: athleteFalls,
            DatabaseSchema.Scoresheet.majorAthleteFalls: majorAthleteFalls,
            DatabaseSchema.Scoresheet.buildingBobbles: buildingBobbles,
            DatabaseSchema.Scoresheet.buildingFalls: buildingFalls,
            DatabaseSchema.Scoresheet.majorBuildingFalls: majorBuildingFalls,
            DatabaseSchema.Scoresheet.boundaryViolations: boundaryViolations,
            DatabaseSchema.Scoresheet.timeLimitViolations: timeLimitViolations,

            // Computed scores
            DatabaseSchema.Scoresheet.rawScore: rawScore.rounded2,
            DatabaseSchema.Scoresheet.totalDeductions: totalDeductions.rounded2,
            DatabaseSchema.Scoresheet.finalScore: finalScore.rounded2,

            // Sync
            DatabaseSchema.Scoresheet.syncStatus: "synced"
        ]
    }

    // MARK: - Import

    func update(from dictionary: [String: Any]) {
        if let round = dictionary[DatabaseSchema.Scoresheet.round] as? String { self.round = round }

        // Building
        if let val = dictionary[DatabaseSchema.Scoresheet.stuntDifficulty] as? Double { self.stuntDifficulty = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.stuntExecution] as? Double { self.stuntExecution = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.stuntDriverDegree] as? Double { self.stuntDriverDegree = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.stuntDriverMaxPart] as? Double { self.stuntDriverMaxPart = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.pyramidDifficulty] as? Double { self.pyramidDifficulty = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.pyramidExecution] as? Double { self.pyramidExecution = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.pyramidDrivers] as? Double { self.pyramidDrivers = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.tossDifficulty] as? Double { self.tossDifficulty = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.tossExecution] as? Double { self.tossExecution = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.buildingCreativity] as? Double { self.buildingCreativity = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.buildingShowmanship] as? Double { self.buildingShowmanship = val }

        // Tumbling
        if let val = dictionary[DatabaseSchema.Scoresheet.standingDifficulty] as? Double { self.standingDifficulty = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.standingExecution] as? Double { self.standingExecution = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.standingDrivers] as? Double { self.standingDrivers = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.runningDifficulty] as? Double { self.runningDifficulty = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.runningExecution] as? Double { self.runningExecution = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.runningDrivers] as? Double { self.runningDrivers = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.runningDriverMaxPart] as? Double { self.runningDriverMaxPart = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.jumpsDifficulty] as? Double { self.jumpsDifficulty = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.jumpsExecution] as? Double { self.jumpsExecution = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.tumblingCreativity] as? Double { self.tumblingCreativity = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.tumblingShowmanship] as? Double { self.tumblingShowmanship = val }

        // Overall
        if let val = dictionary[DatabaseSchema.Scoresheet.danceDifficulty] as? Double { self.danceDifficulty = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.danceExecution] as? Double { self.danceExecution = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.formations] as? Double { self.formations = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.overallCreativity] as? Double { self.overallCreativity = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.overallShowmanship] as? Double { self.overallShowmanship = val }

        // Deductions
        if let val = dictionary[DatabaseSchema.Scoresheet.athleteFalls] as? Int { self.athleteFalls = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.majorAthleteFalls] as? Int { self.majorAthleteFalls = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.buildingBobbles] as? Int { self.buildingBobbles = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.buildingFalls] as? Int { self.buildingFalls = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.majorBuildingFalls] as? Int { self.majorBuildingFalls = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.boundaryViolations] as? Int { self.boundaryViolations = val }
        if let val = dictionary[DatabaseSchema.Scoresheet.timeLimitViolations] as? Int { self.timeLimitViolations = val }
    }
}
