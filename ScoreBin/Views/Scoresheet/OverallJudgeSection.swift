import SwiftUI

struct OverallJudgeSection: View {
    @Binding var scoresheet: Scoresheet
    var viewModel: ScoresheetViewModel
    @State private var isExpanded = true

    var danceTotal: Double {
        (scoresheet.danceDifficulty + scoresheet.danceExecution).rounded2
    }

    private var sectionTotal: Double {
        viewModel.overallTotal
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
                    Image(systemName: "star.fill")
                    Text("OVERALL JUDGE")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    if !isExpanded {
                        Text("\(sectionTotal.scoreFormatted) / \(ScoringRules.Maximums.overallTotal.scoreFormatted)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.overallYellow.opacity(0.8))
                            .padding(.trailing, 4)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.overallYellow)
            }
            .buttonStyle(.plain)
            .judgeHeaderStyle(color: .overallYellow)

            if isExpanded {
                VStack(spacing: 16) {
                    // DANCE Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DANCE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        ScoreInputRow(
                            label: "Difficulty",
                            value: $scoresheet.danceDifficulty,
                            range: ScoringRules.danceDifficultyRange
                        )
                        ScoreInputRow(
                            label: "Execution",
                            value: $scoresheet.danceExecution,
                            range: ScoringRules.danceExecutionRange
                        )

                        SectionTotalRow(
                            label: "Dance Total",
                            value: danceTotal,
                            maxValue: ScoringRules.Maximums.danceTotal,
                            color: .overallYellow
                        )
                    }

                    Divider()
                        .background(Color.scoreBinBorder)

                    // FORMATIONS Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FORMATIONS & TRANSITIONS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        ScoreInputRow(
                            label: "Score",
                            value: $scoresheet.formations,
                            range: ScoringRules.formationsRange
                        )

                        SectionTotalRow(
                            label: "Formations",
                            value: scoresheet.formations,
                            maxValue: ScoringRules.Maximums.formations,
                            color: .overallYellow
                        )
                    }

                    Divider()
                        .background(Color.scoreBinBorder)

                    // Creativity & Showmanship
                    VStack(alignment: .leading, spacing: 8) {
                        ScoreInputRow(
                            label: "Creativity",
                            value: $scoresheet.overallCreativity,
                            range: ScoringRules.creativityRange
                        )
                        ScoreInputRow(
                            label: "Showmanship",
                            value: $scoresheet.overallShowmanship,
                            range: ScoringRules.showmanshipRange
                        )
                    }

                    Divider()
                        .background(Color.scoreBinBorder)

                    // Averaged Scores Display
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("AVERAGED (3 Judges)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.scoreBinPurple)

                        HStack {
                            Text("Creativity Avg")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(viewModel.creativityAvg.scoreFormatted)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.scoreBinPurple)
                        }
                        .padding(.vertical, 4)

                        HStack {
                            Text("Showmanship Avg")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(viewModel.showmanshipAvg.scoreFormatted)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.scoreBinPurple)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle(borderColor: .overallYellow)
    }
}

#Preview {
    OverallJudgeSection(
        scoresheet: .constant(Scoresheet()),
        viewModel: ScoresheetViewModel()
    )
    .padding()
    .background(Color.scoreBinBackground)
}
