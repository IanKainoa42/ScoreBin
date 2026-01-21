import SwiftUI

struct ScoreSummaryView: View {
    var viewModel: ScoresheetViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Category Totals Grid
            HStack(spacing: 12) {
                CategoryTotalCard(
                    title: "Building",
                    score: viewModel.buildingTotal,
                    maxScore: ScoringRules.Maximums.buildingTotal,
                    color: .buildingRed
                )

                CategoryTotalCard(
                    title: "Tumbling",
                    score: viewModel.tumblingTotal,
                    maxScore: ScoringRules.Maximums.tumblingTotal,
                    color: .tumblingTeal
                )

                CategoryTotalCard(
                    title: "Overall",
                    score: viewModel.overallTotal,
                    maxScore: ScoringRules.Maximums.overallTotal,
                    color: .overallYellow
                )

                CategoryTotalCard(
                    title: "Deductions",
                    score: -viewModel.totalDeductions,
                    maxScore: 0,
                    color: .red,
                    isDeduction: true
                )
            }

            Divider()
                .background(Color.scoreBinBorder)

            // Final Score Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Raw Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.rawScore.scoreFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("FINAL SCORE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Text(viewModel.finalScore.scoreFormatted)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.scoreBinGradient)
                }

                Spacer()

                Button {
                    viewModel.copyToClipboard()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.scoreBinGradient)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.scoreBinCyan.opacity(0.1), Color.scoreBinEmerald.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cardStyle(borderColor: .scoreBinCyan)
    }
}

struct CategoryTotalCard: View {
    let title: String
    let score: Double
    let maxScore: Double
    let color: Color
    var isDeduction: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(isDeduction ? score.scoreFormatted : score.scoreFormatted)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            if !isDeduction {
                Text("/ \(maxScore.scoreFormatted)")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScoreSummaryView(viewModel: ScoresheetViewModel())
        .padding()
        .background(Color.scoreBinBackground)
}
