import SwiftUI
import Charts

struct ScoreDistributionChart: View {
    let scoresheets: [Scoresheet]

    private var distributionData: [ScoreRange] {
        // Use ranges that accommodate both standard (50 max) and Level 1 (46 max)
        let ranges: [(String, ClosedRange<Double>)] = [
            ("< 30", 0...29.99),
            ("30-34", 30...34.99),
            ("35-39", 35...39.99),
            ("40-44", 40...44.99),
            ("45-46", 45...46.99),
            ("47-50", 47...100)
        ]

        return ranges.map { label, range in
            let count = scoresheets.filter { range.contains($0.finalScore) }.count
            return ScoreRange(label: label, count: count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart(distributionData) { data in
                BarMark(
                    x: .value("Range", data.label),
                    y: .value("Count", data.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.scoreBinCyan, .scoreBinEmerald],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .annotation(position: .top) {
                    if data.count > 0 {
                        Text("\(data.count)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }

            // Summary stats
            HStack(spacing: 20) {
                if !scoresheets.isEmpty {
                    let avg = scoresheets.reduce(0) { $0 + $1.finalScore } / Double(scoresheets.count)
                    let high = scoresheets.map { $0.finalScore }.max() ?? 0
                    let low = scoresheets.map { $0.finalScore }.min() ?? 0

                    StatLabel(title: "Average", value: avg.scoreFormatted)
                    StatLabel(title: "High", value: high.scoreFormatted)
                    StatLabel(title: "Low", value: low.scoreFormatted)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ScoreRange: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

struct StatLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.scoreBinCyan)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ScoreDistributionChart(scoresheets: [])
        .frame(height: 250)
        .padding()
        .background(Color.scoreBinBackground)
}
