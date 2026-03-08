import SwiftUI

struct TumblingJudgeSection: View {
    @Binding var scoresheet: Scoresheet
    @State private var isExpanded = true

    var standingTotal: Double {
        (scoresheet.standingDifficulty + scoresheet.standingExecution + scoresheet.standingDrivers)
            .rounded2
    }

    var runningTotal: Double {
        (scoresheet.runningDifficulty + scoresheet.runningExecution + scoresheet.runningDrivers + scoresheet.runningDriverMaxPart)
            .rounded2
    }

    var jumpsTotal: Double {
        (scoresheet.jumpsDifficulty + scoresheet.jumpsExecution).rounded2
    }

    private var sectionTotal: Double {
        (standingTotal + runningTotal + jumpsTotal).rounded2
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
                    Image(systemName: "figure.gymnastics")
                    Text("TUMBLING JUDGE")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    if !isExpanded {
                        Text("\(sectionTotal.scoreFormatted) / \(ScoringRules.Maximums.tumblingTotal.scoreFormatted)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.tumblingTeal.opacity(0.8))
                            .padding(.trailing, 4)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.tumblingTeal)
            }
            .buttonStyle(.plain)
            .judgeHeaderStyle(color: .tumblingTeal)

            if isExpanded {
                VStack(spacing: 16) {
                    // STANDING Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STANDING")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        ScoreInputRow(
                            label: "Difficulty",
                            value: $scoresheet.standingDifficulty,
                            range: ScoringRules.standingDifficultyRange
                        )
                        ScoreInputRow(
                            label: "Execution",
                            value: $scoresheet.standingExecution,
                            range: ScoringRules.standingExecutionRange
                        )
                        ScoreInputRow(
                            label: "DoD",
                            value: $scoresheet.standingDrivers,
                            range: ScoringRules.standingDriversRange
                        )

                        SectionTotalRow(
                            label: "Standing Total",
                            value: standingTotal,
                            maxValue: ScoringRules.Maximums.standingTotal,
                            color: .tumblingTeal
                        )
                    }

                    Divider()
                        .background(Color.scoreBinBorder)

                    // RUNNING Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RUNNING")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        ScoreInputRow(
                            label: "Difficulty",
                            value: $scoresheet.runningDifficulty,
                            range: ScoringRules.runningDifficultyRange
                        )
                        ScoreInputRow(
                            label: "Execution",
                            value: $scoresheet.runningExecution,
                            range: ScoringRules.runningExecutionRange
                        )
                        ScoreInputRow(
                            label: "DoD",
                            value: $scoresheet.runningDrivers,
                            range: ScoringRules.runningDriversRange
                        )
                        ScoreInputRow(
                            label: "MPD",
                            value: $scoresheet.runningDriverMaxPart,
                            range: ScoringRules.runningDriverMaxPartRange
                        )
                        SectionTotalRow(
                            label: "Running Total",
                            value: runningTotal,
                            maxValue: ScoringRules.Maximums.runningTotal,
                            color: .tumblingTeal
                        )
                    }

                    Divider()
                        .background(Color.scoreBinBorder)

                    // JUMPS Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JUMPS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        ScoreInputRow(
                            label: "Difficulty",
                            value: $scoresheet.jumpsDifficulty,
                            range: ScoringRules.jumpsDifficultyRange
                        )
                        ScoreInputRow(
                            label: "Execution",
                            value: $scoresheet.jumpsExecution,
                            range: ScoringRules.jumpsExecutionRange
                        )

                        SectionTotalRow(
                            label: "Jumps Total",
                            value: jumpsTotal,
                            maxValue: ScoringRules.Maximums.jumpsTotal,
                            color: .tumblingTeal
                        )
                    }

                    Divider()
                        .background(Color.scoreBinBorder)

                    // Creativity & Showmanship
                    VStack(alignment: .leading, spacing: 8) {
                        ScoreInputRow(
                            label: "Creativity",
                            value: $scoresheet.tumblingCreativity,
                            range: ScoringRules.creativityRange
                        )
                        ScoreInputRow(
                            label: "Showmanship",
                            value: $scoresheet.tumblingShowmanship,
                            range: ScoringRules.showmanshipRange
                        )
                    }
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle(borderColor: .tumblingTeal)
    }
}

#Preview {
    TumblingJudgeSection(scoresheet: .constant(Scoresheet()))
        .padding()
        .background(Color.scoreBinBackground)
}
