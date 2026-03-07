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

    // MARK: - Update from Database

    func update(from data: [String: Any]) {
        if let round = data["round"] as? String { self.round = round }

        if let createdAtString = data["created_at"] as? String,
            let date = ISO8601DateFormatter.shared.date(from: createdAtString)
        {
            self.createdAt = date
        }

        func updateDouble(_ key: String, _ path: ReferenceWritableKeyPath<Scoresheet, Double>) {
            if let val = data[key] as? Double { self[keyPath: path] = val }
        }

        func updateInt(_ key: String, _ path: ReferenceWritableKeyPath<Scoresheet, Int>) {
            if let val = data[key] as? Int { self[keyPath: path] = val }
        }

        // Building
        updateDouble("stunt_difficulty", \.stuntDifficulty)
        updateDouble("stunt_execution", \.stuntExecution)
        updateDouble("stunt_driver_degree", \.stuntDriverDegree)
        updateDouble("stunt_driver_max_part", \.stuntDriverMaxPart)
        updateDouble("pyramid_difficulty", \.pyramidDifficulty)
        updateDouble("pyramid_execution", \.pyramidExecution)
        updateDouble("pyramid_drivers", \.pyramidDrivers)
        updateDouble("toss_difficulty", \.tossDifficulty)
        updateDouble("toss_execution", \.tossExecution)
        updateDouble("building_creativity", \.buildingCreativity)
        updateDouble("building_showmanship", \.buildingShowmanship)

        // Tumbling
        updateDouble("standing_difficulty", \.standingDifficulty)
        updateDouble("standing_execution", \.standingExecution)
        updateDouble("standing_drivers", \.standingDrivers)
        updateDouble("running_difficulty", \.runningDifficulty)
        updateDouble("running_execution", \.runningExecution)
        updateDouble("running_drivers", \.runningDrivers)
        updateDouble("running_driver_max_part", \.runningDriverMaxPart)
        updateDouble("jumps_difficulty", \.jumpsDifficulty)
        updateDouble("jumps_execution", \.jumpsExecution)
        updateDouble("tumbling_creativity", \.tumblingCreativity)
        updateDouble("tumbling_showmanship", \.tumblingShowmanship)

        // Overall
        updateDouble("dance_difficulty", \.danceDifficulty)
        updateDouble("dance_execution", \.danceExecution)
        updateDouble("formations", \.formations)
        updateDouble("overall_creativity", \.overallCreativity)
        updateDouble("overall_showmanship", \.overallShowmanship)

        // Deductions
        updateInt("athlete_falls", \.athleteFalls)
        updateInt("major_athlete_falls", \.majorAthleteFalls)
        updateInt("building_bobbles", \.buildingBobbles)
        updateInt("building_falls", \.buildingFalls)
        updateInt("major_building_falls", \.majorBuildingFalls)
        updateInt("boundary_violations", \.boundaryViolations)
        updateInt("time_limit_violations", \.timeLimitViolations)
    }

    // MARK: - Export for Database

    func exportForDatabase() -> [String: Any] {
        return [
            "id": id.uuidString,
            "team_id": team?.id.uuidString ?? NSNull(),
            "competition_id": competition?.id.uuidString ?? NSNull(),
            "round": round,
            "created_at": ISO8601DateFormatter.shared.string(from: createdAt),

            // Building scores
            "stunt_difficulty": stuntDifficulty,
            "stunt_execution": stuntExecution,
            "stunt_driver_degree": stuntDriverDegree,
            "stunt_driver_max_part": stuntDriverMaxPart,
            "pyramid_difficulty": pyramidDifficulty,
            "pyramid_execution": pyramidExecution,
            "pyramid_drivers": pyramidDrivers,
            "toss_difficulty": tossDifficulty,
            "toss_execution": tossExecution,
            "building_creativity": buildingCreativity,
            "building_showmanship": buildingShowmanship,

            // Tumbling scores
            "standing_difficulty": standingDifficulty,
            "standing_execution": standingExecution,
            "standing_drivers": standingDrivers,
            "running_difficulty": runningDifficulty,
            "running_execution": runningExecution,
            "running_drivers": runningDrivers,
            "running_driver_max_part": runningDriverMaxPart, // Note: Not in schema comment but likely needed if in model
            "jumps_difficulty": jumpsDifficulty,
            "jumps_execution": jumpsExecution,
            "tumbling_creativity": tumblingCreativity,
            "tumbling_showmanship": tumblingShowmanship,

            // Overall scores
            "dance_difficulty": danceDifficulty,
            "dance_execution": danceExecution,
            "formations": formations,
            "overall_creativity": overallCreativity,
            "overall_showmanship": overallShowmanship,

            // Deductions
            "athlete_falls": athleteFalls,
            "major_athlete_falls": majorAthleteFalls,
            "building_bobbles": buildingBobbles,
            "building_falls": buildingFalls,
            "major_building_falls": majorBuildingFalls,
            "boundary_violations": boundaryViolations,
            "time_limit_violations": timeLimitViolations,

            // Computed scores
            "raw_score": rawScore.rounded2,
            "total_deductions": totalDeductions.rounded2,
            "final_score": finalScore.rounded2,

            // Sync
            "sync_status": "synced" // We are exporting to sync, so status on remote should be synced? Or we just send data? Usually we send data.
        ]
    }
}
