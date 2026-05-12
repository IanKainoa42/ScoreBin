import Foundation
import CheerRulesKit

/// Bridge to CheerRulesKit's ScoresheetConstants.
/// All 160+ call sites (ScoringRules.Deductions, ScoringRules.Maximums, etc.) continue working.
typealias ScoringRules = ScoresheetConstants

// MARK: - Extra Deduction Labels

extension ScoresheetConstants.DeductionLabels {
    static let boundaryViolation = "Boundary Violation"
    static let boundaryViolations = "Boundary Violations"
    static let timeLimitViolation = "Time Limit Violation"
    static let timeLimitViolations = "Time Limit Violations"
}

// MARK: - Quantity Chart (bridges to UnitedBuildingRubric)

extension ScoresheetConstants {
    struct QuantityChart {
        let majority: Int
        let most: Int
        let max: Int

        static func forAthleteCount(_ count: Int) -> QuantityChart {
            guard let row = UnitedBuildingRubric.row(forAthleteCount: count) else {
                return QuantityChart(majority: 1, most: 2, max: 3)
            }
            return QuantityChart(
                majority: row.majorityGroups,
                most: row.mostGroups,
                max: row.maxGroups
            )
        }

        var description: String {
            "MAJ: \(majority)  MOST: \(most)  MAX: \(max)"
        }
    }
}
