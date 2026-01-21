import Foundation

/// United Scoring System 2025-2026 Rules and Constants
enum ScoringRules {

    // MARK: - Deduction Values
    enum Deductions {
        static let athleteFall: Double = 0.15
        static let majorAthleteFall: Double = 0.25
        static let buildingBobble: Double = 0.25
        static let buildingFall: Double = 0.75
        static let majorBuildingFall: Double = 1.25
        static let boundaryViolation: Double = 0.05
        static let timeLimitViolation: Double = 0.05
    }

    // MARK: - Score Maximums
    enum Maximums {
        // Building
        static let stuntDifficulty: Double = 4.5
        static let stuntExecution: Double = 4.0
        static let stuntDriverDegree: Double = 0.8
        static let stuntDriverMaxPart: Double = 0.7
        static let stuntTotal: Double = 10.0

        static let pyramidDifficulty: Double = 4.0
        static let pyramidExecution: Double = 4.0
        static let pyramidTotal: Double = 8.0

        static let tossDifficulty: Double = 2.0
        static let tossExecution: Double = 2.0
        static let tossTotal: Double = 4.0

        static let buildingTotal: Double = 22.0

        // Tumbling
        static let standingDifficulty: Double = 3.0
        static let standingExecution: Double = 4.0
        static let standingDrivers: Double = 1.0
        static let standingTotal: Double = 8.0

        static let runningDifficulty: Double = 3.0
        static let runningExecution: Double = 4.0
        static let runningDrivers: Double = 0.5
        static let runningDriverMaxPart: Double = 0.5
        static let runningTotal: Double = 8.0

        static let jumpsDifficulty: Double = 2.0
        static let jumpsExecution: Double = 2.0
        static let jumpsTotal: Double = 4.0

        static let tumblingTotal: Double = 20.0

        // Overall
        static let danceDifficulty: Double = 1.0
        static let danceExecution: Double = 1.0
        static let danceTotal: Double = 2.0

        static let formations: Double = 2.0
        static let creativity: Double = 2.0
        static let showmanship: Double = 2.0

        static let overallTotal: Double = 8.0

        // Grand total
        static let maxScore: Double = 50.0

        // Level 1 specific (no tosses)
        static let level1BuildingTotal: Double = 18.0  // No toss (22 - 4)
        static let level1MaxScore: Double = 46.0       // 18 + 20 + 8
    }

    // MARK: - Score Minimums
    enum Minimums {
        static let stuntDifficulty: Double = 2.5
        static let stuntExecution: Double = 2.8
        static let pyramidDifficulty: Double = 2.0
        static let pyramidExecution: Double = 2.8
        static let tossDifficulty: Double = 0.5
        static let tossExecution: Double = 1.3
        static let jumpsDifficulty: Double = 0.5
        static let jumpsExecution: Double = 1.3
        static let standingDifficulty: Double = 1.5
        static let standingExecution: Double = 2.8
        static let runningDifficulty: Double = 1.5
        static let runningExecution: Double = 2.8
        static let danceDifficulty: Double = 0.5
        static let danceExecution: Double = 0.5
        static let formations: Double = 1.0
        static let creativity: Double = 1.5
        static let showmanship: Double = 1.0
    }

    // MARK: - Quantity Chart
    struct QuantityChart {
        let majority: Int
        let most: Int
        let max: Int

        static func forAthleteCount(_ count: Int) -> QuantityChart {
            if count >= 31 {
                return QuantityChart(majority: 5, most: 6, max: 7)
            } else if count >= 23 {
                return QuantityChart(majority: 4, most: 5, max: 6)
            } else if count >= 18 {
                return QuantityChart(majority: 3, most: 4, max: 5)
            } else if count >= 12 {
                return QuantityChart(majority: 2, most: 3, max: 4)
            } else {
                return QuantityChart(majority: 1, most: 2, max: 3)
            }
        }

        var description: String {
            "MAJ: \(majority)  MOST: \(most)  MAX: \(max)"
        }
    }

    // MARK: - Score Ranges for Input Validation
    struct ScoreRange {
        let min: Double
        let max: Double
        let step: Double

        func isValid(_ value: Double) -> Bool {
            value >= min && value <= max
        }
    }

    static let stuntDifficultyRange = ScoreRange(min: 2.5, max: 4.5, step: 0.5)
    static let stuntExecutionRange = ScoreRange(min: 2.8, max: 4.0, step: 0.1)
    static let stuntDriverDegreeRange = ScoreRange(min: 0, max: 0.8, step: 0.1)
    static let stuntDriverMaxPartRange = ScoreRange(min: 0, max: 0.7, step: 0.1)

    static let pyramidDifficultyRange = ScoreRange(min: 2.0, max: 4.0, step: 0.1)
    static let pyramidExecutionRange = ScoreRange(min: 2.8, max: 4.0, step: 0.1)

    static let tossDifficultyRange = ScoreRange(min: 1.0, max: 2.0, step: 0.5)
    static let tossExecutionRange = ScoreRange(min: 1.3, max: 2.0, step: 0.1)

    static let standingDifficultyRange = ScoreRange(min: 1.5, max: 3.0, step: 0.5)
    static let standingExecutionRange = ScoreRange(min: 2.8, max: 4.0, step: 0.1)
    static let standingDriversRange = ScoreRange(min: 0, max: 1.0, step: 0.1)

    static let runningDifficultyRange = ScoreRange(min: 1.5, max: 3.0, step: 0.5)
    static let runningExecutionRange = ScoreRange(min: 2.8, max: 4.0, step: 0.1)
    static let runningDriversRange = ScoreRange(min: 0, max: 0.5, step: 0.1)
    static let runningDriverMaxPartRange = ScoreRange(min: 0, max: 0.5, step: 0.1)

    static let jumpsDifficultyRange = ScoreRange(min: 0.5, max: 2.0, step: 0.5)
    static let jumpsExecutionRange = ScoreRange(min: 1.3, max: 2.0, step: 0.1)

    static let danceDifficultyRange = ScoreRange(min: 0.5, max: 1.0, step: 0.1)
    static let danceExecutionRange = ScoreRange(min: 0.5, max: 1.0, step: 0.1)
    static let formationsRange = ScoreRange(min: 1.0, max: 2.0, step: 0.1)

    static let creativityRange = ScoreRange(min: 1.5, max: 2.0, step: 0.01)
    static let showmanshipRange = ScoreRange(min: 1.0, max: 2.0, step: 0.01)

    // MARK: - Level-Aware Maximums

    /// Returns the maximum building score for a given level
    static func buildingMax(forLevel level: String?) -> Double {
        level == "L1" ? Maximums.level1BuildingTotal : Maximums.buildingTotal
    }

    /// Returns the maximum total score for a given level
    static func maxScore(forLevel level: String?) -> Double {
        level == "L1" ? Maximums.level1MaxScore : Maximums.maxScore
    }
}
