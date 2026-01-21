import SwiftUI

struct OverallJudgeSection: View {
    @Binding var scoresheet: Scoresheet
    var viewModel: ScoresheetViewModel

    var danceTotal: Double {
        (scoresheet.danceDifficulty + scoresheet.danceExecution).rounded2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                Text("OVERALL JUDGE")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.overallYellow)
            .judgeHeaderStyle(color: .overallYellow)

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
