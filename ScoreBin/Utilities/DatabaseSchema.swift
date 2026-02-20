import Foundation

/// Centralized database schema constants to avoid hardcoded strings
struct DatabaseSchema {

    // MARK: - Gym Table
    struct Gym {
        static let table = "gyms"
        static let id = "id"
        static let name = "name"
        static let location = "location"
        static let createdAt = "created_at"
    }

    // MARK: - Team Table
    struct Team {
        static let table = "teams"
        static let id = "id"
        static let name = "name"
        static let gymId = "gym_id"
        static let level = "level"
        static let ageDivision = "age_division"
        static let tier = "tier"
        static let athleteCount = "athlete_count"
        static let createdAt = "created_at"
    }

    // MARK: - Competition Table
    struct Competition {
        static let table = "competitions"
        static let id = "id"
        static let name = "name"
        static let date = "date"
        static let location = "location"
        static let notes = "notes"
        static let createdAt = "created_at"
    }

    // MARK: - Scoresheet Table
    struct Scoresheet {
        static let table = "scoresheets"
        static let id = "id"
        static let teamId = "team_id"
        static let competitionId = "competition_id"
        static let round = "round"
        static let createdAt = "created_at"

        // Building Scores
        static let stuntDifficulty = "stunt_difficulty"
        static let stuntExecution = "stunt_execution"
        static let stuntDriverDegree = "stunt_driver_degree"
        static let stuntDriverMaxPart = "stunt_driver_max_part"
        static let pyramidDifficulty = "pyramid_difficulty"
        static let pyramidExecution = "pyramid_execution"
        static let pyramidDrivers = "pyramid_drivers"
        static let tossDifficulty = "toss_difficulty"
        static let tossExecution = "toss_execution"
        static let buildingCreativity = "building_creativity"
        static let buildingShowmanship = "building_showmanship"

        // Tumbling Scores
        static let standingDifficulty = "standing_difficulty"
        static let standingExecution = "standing_execution"
        static let standingDrivers = "standing_drivers"
        static let runningDifficulty = "running_difficulty"
        static let runningExecution = "running_execution"
        static let runningDrivers = "running_drivers"
        static let runningDriverMaxPart = "running_driver_max_part"
        static let jumpsDifficulty = "jumps_difficulty"
        static let jumpsExecution = "jumps_execution"
        static let tumblingCreativity = "tumbling_creativity"
        static let tumblingShowmanship = "tumbling_showmanship"

        // Overall Scores
        static let danceDifficulty = "dance_difficulty"
        static let danceExecution = "dance_execution"
        static let formations = "formations"
        static let overallCreativity = "overall_creativity"
        static let overallShowmanship = "overall_showmanship"

        // Deductions
        static let athleteFalls = "athlete_falls"
        static let majorAthleteFalls = "major_athlete_falls"
        static let buildingBobbles = "building_bobbles"
        static let buildingFalls = "building_falls"
        static let majorBuildingFalls = "major_building_falls"
        static let boundaryViolations = "boundary_violations"
        static let timeLimitViolations = "time_limit_violations"

        // Computed Scores (read-only usually, but exported for query)
        static let rawScore = "raw_score"
        static let totalDeductions = "total_deductions"
        static let finalScore = "final_score"

        // Sync
        static let syncStatus = "sync_status"
    }
}
