import SwiftUI

struct DeductionsSection: View {
    @Binding var scoresheet: Scoresheet

    var totalDeductions: Double {
        (Double(scoresheet.athleteFalls) * ScoringRules.Deductions.athleteFall +
         Double(scoresheet.majorAthleteFalls) * ScoringRules.Deductions.majorAthleteFall +
         Double(scoresheet.buildingBobbles) * ScoringRules.Deductions.buildingBobble +
         Double(scoresheet.buildingFalls) * ScoringRules.Deductions.buildingFall +
         Double(scoresheet.majorBuildingFalls) * ScoringRules.Deductions.majorBuildingFall +
         Double(scoresheet.boundaryViolations) * ScoringRules.Deductions.boundaryViolation +
         Double(scoresheet.timeLimitViolations) * ScoringRules.Deductions.timeLimitViolation).rounded2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("DEDUCTIONS")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if totalDeductions > 0 {
                    Text("-\(totalDeductions.scoreFormatted)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))

            VStack(spacing: 0) {
                DeductionCounterRow(
                    label: "Athlete Fall",
                    count: $scoresheet.athleteFalls,
                    pointsPer: ScoringRules.Deductions.athleteFall
                )

                DeductionCounterRow(
                    label: "Major Athlete Fall",
                    count: $scoresheet.majorAthleteFalls,
                    pointsPer: ScoringRules.Deductions.majorAthleteFall
                )

                DeductionCounterRow(
                    label: "Building Bobble",
                    count: $scoresheet.buildingBobbles,
                    pointsPer: ScoringRules.Deductions.buildingBobble
                )

                DeductionCounterRow(
                    label: "Building Fall",
                    count: $scoresheet.buildingFalls,
                    pointsPer: ScoringRules.Deductions.buildingFall
                )

                DeductionCounterRow(
                    label: "Major Building Fall",
                    count: $scoresheet.majorBuildingFalls,
                    pointsPer: ScoringRules.Deductions.majorBuildingFall
                )

                DeductionCounterRow(
                    label: "Boundary Violation",
                    count: $scoresheet.boundaryViolations,
                    pointsPer: ScoringRules.Deductions.boundaryViolation
                )

                DeductionCounterRow(
                    label: "Time Limit Violation",
                    count: $scoresheet.timeLimitViolations,
                    pointsPer: ScoringRules.Deductions.timeLimitViolation
                )
            }
            .padding()
        }
        .cardStyle(borderColor: .red)
    }
}

struct DeductionCounterRow: View {
    let label: String
    @Binding var count: Int
    let pointsPer: Double

    var totalPoints: Double {
        Double(count) * pointsPer
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("-\(pointsPer.scoreFormatted) each")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    if count > 0 {
                        count -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .frame(width: 32, height: 32)
                        .background(Color.scoreBinCardBackground)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: 32)
                    .foregroundColor(.white)

                Button {
                    count += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 32, height: 32)
                        .background(Color.scoreBinCardBackground)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                if count > 0 {
                    Text("-\(totalPoints.scoreFormatted)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(width: 50, alignment: .trailing)
                } else {
                    Color.clear
                        .frame(width: 50)
                }
            }
        }
        .padding(.vertical, 10)
        .overlay(
            Divider()
                .background(Color.scoreBinBorder),
            alignment: .bottom
        )
    }
}

#Preview {
    DeductionsSection(scoresheet: .constant(Scoresheet()))
        .padding()
        .background(Color.scoreBinBackground)
}
