import SwiftUI

struct StickyScoreBar: View {
    var viewModel: ScoresheetViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Building
            miniScore(label: "BLD", value: viewModel.scoresheet.buildingTotal, color: .buildingRed)

            divider

            // Tumbling
            miniScore(label: "TUM", value: viewModel.scoresheet.tumblingTotal, color: .tumblingTeal)

            divider

            // Overall
            miniScore(label: "OVR", value: viewModel.scoresheet.overallTotal, color: .overallYellow)

            divider

            // Deductions
            miniScore(label: "DED", value: -viewModel.scoresheet.totalDeductions, color: .red)

            divider

            // Final Score - prominent
            VStack(spacing: 2) {
                Text("FINAL")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
                Text(viewModel.scoresheet.finalScore.scoreFormatted)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.scoreBinGradient)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            Color.scoreBinCardBackground
                .shadow(color: .black.opacity(0.4), radius: 8, y: -4)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.scoreBinGradient),
            alignment: .top
        )
    }

    private func miniScore(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.gray)
            Text(value.scoreFormatted)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.scoreBinBorder)
            .frame(width: 1, height: 30)
    }
}

#Preview {
    VStack {
        Spacer()
        StickyScoreBar(viewModel: ScoresheetViewModel())
    }
    .background(Color.scoreBinBackground)
}
