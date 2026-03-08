import SwiftUI

struct BuildingJudgeSection: View {
    @Binding var scoresheet: Scoresheet
    @State private var isExpanded = true

    var stuntTotal: Double {
        (scoresheet.stuntDifficulty + scoresheet.stuntExecution +
         scoresheet.stuntDriverDegree + scoresheet.stuntDriverMaxPart).rounded2
    }

    var pyramidTotal: Double {
        (scoresheet.pyramidDifficulty + scoresheet.pyramidExecution).rounded2
    }

    var tossTotal: Double {
        (scoresheet.tossDifficulty + scoresheet.tossExecution).rounded2
    }

    /// Level 1 teams cannot perform tosses
    var showTosses: Bool {
        ScoringRules.isTossAllowed(forLevel: scoresheet.team?.level)
    }

    private var sectionTotal: Double {
        (stuntTotal + pyramidTotal + (showTosses ? tossTotal : 0)).rounded2
    }

    private var maxTotal: Double {
        showTosses
            ? ScoringRules.Maximums.stuntTotal + ScoringRules.Maximums.pyramidTotal + ScoringRules.Maximums.tossTotal
            : ScoringRules.Maximums.stuntTotal + ScoringRules.Maximums.pyramidTotal
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsible Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "building.2.fill")
                    Text("BUILDING JUDGE")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    if !isExpanded {
                        Text("\(sectionTotal.scoreFormatted) / \(maxTotal.scoreFormatted)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.buildingRed.opacity(0.8))
                            .padding(.trailing, 4)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.buildingRed)
            }
            .buttonStyle(.plain)
            .judgeHeaderStyle(color: .buildingRed)

            if isExpanded {
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
                            label: "DoD",
                            value: $scoresheet.stuntDriverDegree,
                            range: ScoringRules.stuntDriverDegreeRange
                        )
                        ScoreInputRow(
                            label: "MPD",
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
                        SectionTotalRow(
                            label: "Pyramid Total",
                            value: pyramidTotal,
                            maxValue: ScoringRules.Maximums.pyramidTotal,
                            color: .buildingRed
                        )
                    }

                    // TOSSES Section (not shown for Level 1)
                    if showTosses {
                        Divider()
                            .background(Color.scoreBinBorder)

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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle(borderColor: .buildingRed)
    }
}

#Preview {
    BuildingJudgeSection(scoresheet: .constant(Scoresheet()))
        .padding()
        .background(Color.scoreBinBackground)
}
