import Foundation
import SwiftData

enum SyncStatus: String, Codable {
    case pending
    case synced
    case failed
}

enum RoundType: String, Codable, CaseIterable {
    case day1 = "Day 1"
    case day2 = "Day 2"
    case finals = "Finals"
    case exhibition = "Exhibition"
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
    var syncStatus: SyncStatus
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

        // Building defaults
        self.stuntDifficulty = 3.0
        self.stuntExecution = 4.0
        self.stuntDriverDegree = 0
        self.stuntDriverMaxPart = 0
        self.pyramidDifficulty = 2.5
        self.pyramidExecution = 4.0
        self.pyramidDrivers = 0
        self.tossDifficulty = 1.0
        self.tossExecution = 2.0
        self.buildingCreativity = 1.75
        self.buildingShowmanship = 1.5

        // Tumbling defaults
        self.standingDifficulty = 1.5
        self.standingExecution = 4.0
        self.standingDrivers = 0
        self.runningDifficulty = 1.5
        self.runningExecution = 4.0
        self.runningDrivers = 0
        self.jumpsDifficulty = 1.0
        self.jumpsExecution = 2.0
        self.tumblingCreativity = 1.75
        self.tumblingShowmanship = 1.5

        // Overall defaults
        self.danceDifficulty = 0.75
        self.danceExecution = 0.75
        self.formations = 2.0
        self.overallCreativity = 1.75
        self.overallShowmanship = 1.5

        // Deductions
        self.athleteFalls = 0
        self.majorAthleteFalls = 0
        self.buildingBobbles = 0
        self.buildingFalls = 0
        self.majorBuildingFalls = 0
        self.boundaryViolations = 0
        self.timeLimitViolations = 0

        // Sync
        self.syncStatus = .pending
        self.supabaseId = nil
    }

    // MARK: - Computed Totals

    var stuntTotal: Double {
        stuntDifficulty + stuntExecution + stuntDriverDegree + stuntDriverMaxPart
    }

    var pyramidTotal: Double {
        pyramidDifficulty + pyramidExecution + pyramidDrivers
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
        runningDifficulty + runningExecution + runningDrivers
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
        Double(athleteFalls) * ScoringRules.Deductions.athleteFall +
        Double(majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall +
        Double(buildingBobbles) * ScoringRules.Deductions.buildingBobble +
        Double(buildingFalls) * ScoringRules.Deductions.buildingFall +
        Double(majorBuildingFalls) * ScoringRules.Deductions.majorBuildingFall +
        Double(boundaryViolations) * ScoringRules.Deductions.boundaryViolation +
        Double(timeLimitViolations) * ScoringRules.Deductions.timeLimitViolation
    }

    var rawScore: Double {
        buildingTotal + tumblingTotal + overallTotal
    }

    var finalScore: Double {
        rawScore - totalDeductions
    }

    // MARK: - Export for Database

    func exportForDatabase() -> [String: Any] {
        return [
            "team_info": [
                "name": team?.name ?? "",
                "program": team?.gym?.name ?? "",
                "level": team?.level ?? "",
                "age_division": team?.ageDivision ?? "",
                "tier": team?.tier ?? "",
                "athlete_count": team?.athleteCount ?? 0
            ],
            "performance": [
                "competition_name": competition?.name ?? "",
                "round": round,
                "raw_score": rawScore.rounded2,
                "total_deductions": totalDeductions.rounded2,
                "final_score": finalScore.rounded2
            ],
            "scores_building": [
                "stunt_difficulty": stuntDifficulty,
                "stunt_execution": stuntExecution,
                "stunt_driver_degree": stuntDriverDegree,
                "stunt_driver_max_part": stuntDriverMaxPart,
                "pyramid_difficulty": pyramidDifficulty,
                "pyramid_execution": pyramidExecution,
                "pyramid_drivers": pyramidDrivers,
                "toss_difficulty": tossDifficulty,
                "toss_execution": tossExecution,
                "creativity_score": buildingCreativity,
                "showmanship_score": buildingShowmanship
            ],
            "scores_tumbling": [
                "standing_difficulty": standingDifficulty,
                "standing_execution": standingExecution,
                "standing_drivers": standingDrivers,
                "running_difficulty": runningDifficulty,
                "running_execution": runningExecution,
                "running_drivers": runningDrivers,
                "jumps_difficulty": jumpsDifficulty,
                "jumps_execution": jumpsExecution,
                "creativity_score": tumblingCreativity,
                "showmanship_score": tumblingShowmanship
            ],
            "scores_overall": [
                "dance_difficulty": danceDifficulty,
                "dance_execution": danceExecution,
                "formations_score": formations,
                "creativity_score": overallCreativity,
                "showmanship_score": overallShowmanship
            ],
            "deductions": buildDeductionsArray()
        ]
    }

    private func buildDeductionsArray() -> [[String: Any]] {
        var result: [[String: Any]] = []

        if athleteFalls > 0 {
            result.append(["category": "athlete_fall", "count": athleteFalls])
        }
        if majorAthleteFalls > 0 {
            result.append(["category": "major_athlete_fall", "count": majorAthleteFalls])
        }
        if buildingBobbles > 0 {
            result.append(["category": "building_bobble", "count": buildingBobbles])
        }
        if buildingFalls > 0 {
            result.append(["category": "building_fall", "count": buildingFalls])
        }
        if majorBuildingFalls > 0 {
            result.append(["category": "major_building_fall", "count": majorBuildingFalls])
        }
        if boundaryViolations > 0 {
            result.append(["category": "boundary_violation", "count": boundaryViolations])
        }
        if timeLimitViolations > 0 {
            result.append(["category": "time_limit_violation", "count": timeLimitViolations])
        }

        return result
    }
}

// MARK: - Double Extension for Rounding

extension Double {
    var rounded2: Double {
        (self * 100).rounded() / 100
    }
}
