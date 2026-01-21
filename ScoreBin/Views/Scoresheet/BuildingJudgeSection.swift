import SwiftUI

struct BuildingJudgeSection: View {
    @Binding var scoresheet: Scoresheet

    var stuntTotal: Double {
        (scoresheet.stuntDifficulty + scoresheet.stuntExecution +
         scoresheet.stuntDriverDegree + scoresheet.stuntDriverMaxPart).rounded2
    }

    var pyramidTotal: Double {
        (scoresheet.pyramidDifficulty + scoresheet.pyramidExecution +
         scoresheet.pyramidDrivers).rounded2
    }

    var tossTotal: Double {
        (scoresheet.tossDifficulty + scoresheet.tossExecution).rounded2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "building.2.fill")
                Text("BUILDING JUDGE")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.buildingRed)
            .judgeHeaderStyle(color: .buildingRed)

            VStack(spacing: 16) {
                // STUNT Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("STUNT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)

                    ScoreInputRow(
                        label: "Difficulty",
                        value: $scoresheet.stuntDifficulty,
                        range: ScoringRules.stuntDifficultyRange
                    )
                    ScoreInputRow(
                        label: "Execution",
                        value: $scoresheet.stuntExecution,
                        range: ScoringRules.stuntExecutionRange
                    )
                    ScoreInputRow(
                        label: "Driver: Degree",
                        value: $scoresheet.stuntDriverDegree,
                        range: ScoringRules.stuntDriverDegreeRange
                    )
                    ScoreInputRow(
                        label: "Driver: Max Part",
                        value: $scoresheet.stuntDriverMaxPart,
                        range: ScoringRules.stuntDriverMaxPartRange
                    )

                    SectionTotalRow(
                        label: "Stunt Total",
                        value: stuntTotal,
                        maxValue: ScoringRules.Maximums.stuntTotal,
                        color: .buildingRed
                    )
                }

                Divider()
                    .background(Color.scoreBinBorder)

                // PYRAMID Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("PYRAMID")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)

                    ScoreInputRow(
                        label: "Difficulty",
                        value: $scoresheet.pyramidDifficulty,
                        range: ScoringRules.pyramidDifficultyRange
                    )
                    ScoreInputRow(
                        label: "Execution",
                        value: $scoresheet.pyramidExecution,
                        range: ScoringRules.pyramidExecutionRange
                    )
                    ScoreInputRow(
                        label: "Drivers",
                        value: $scoresheet.pyramidDrivers,
                        range: ScoringRules.pyramidDriversRange
                    )

                    SectionTotalRow(
                        label: "Pyramid Total",
                        value: pyramidTotal,
                        maxValue: ScoringRules.Maximums.pyramidTotal,
                        color: .buildingRed
                    )
                }

                Divider()
                    .background(Color.scoreBinBorder)

                // TOSSES Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOSSES")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)

                    ScoreInputRow(
                        label: "Difficulty",
                        value: $scoresheet.tossDifficulty,
                        range: ScoringRules.tossDifficultyRange
                    )
                    ScoreInputRow(
                        label: "Execution",
                        value: $scoresheet.tossExecution,
                        range: ScoringRules.tossExecutionRange
                    )

                    SectionTotalRow(
                        label: "Toss Total",
                        value: tossTotal,
                        maxValue: ScoringRules.Maximums.tossTotal,
                        color: .buildingRed
                    )
                }

                Divider()
                    .background(Color.scoreBinBorder)

                // Creativity & Showmanship
                VStack(alignment: .leading, spacing: 8) {
                    ScoreInputRow(
                        label: "Creativity",
                        value: $scoresheet.buildingCreativity,
                        range: ScoringRules.creativityRange
                    )
                    ScoreInputRow(
                        label: "Showmanship",
                        value: $scoresheet.buildingShowmanship,
                        range: ScoringRules.showmanshipRange
                    )
                }
            }
            .padding()
        }
        .cardStyle(borderColor: .buildingRed)
    }
}

#Preview {
    BuildingJudgeSection(scoresheet: .constant(Scoresheet()))
        .padding()
        .background(Color.scoreBinBackground)
}
