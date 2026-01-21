import SwiftUI

struct ScoreInputRow: View {
    let label: String
    @Binding var value: Double
    let range: ScoringRules.ScoreRange

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if value > range.min {
                        value = max(range.min, value - range.step)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                TextField("", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(Color.scoreBinBackground)
                    .cornerRadius(6)
                    .foregroundColor(.white)

                Button {
                    if value < range.max {
                        value = min(range.max, value + range.step)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.scoreBinCyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SectionTotalRow: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)

            Spacer()

            HStack(spacing: 4) {
                Text(value.scoreFormatted)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text("/ \(maxValue.scoreFormatted)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.scoreBinBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        ScoreInputRow(
            label: "Difficulty",
            value: .constant(3.5),
            range: ScoringRules.stuntDifficultyRange
        )

        SectionTotalRow(
            label: "Stunt Total",
            value: 8.5,
            maxValue: 10.0,
            color: .scoreBinCyan
        )
    }
    .padding()
    .background(Color.scoreBinCardBackground)
}
