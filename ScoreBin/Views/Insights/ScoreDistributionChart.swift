import SwiftUI
import Charts

struct ScoreDistributionChart: View {
    let scoresheets: [Scoresheet]

    private var distributionData: [ScoreRange] {
        var counts = [Int](repeating: 0, count: 6)

        for sheet in scoresheets {
            let score = sheet.finalScore
            if score < 30 { counts[0] += 1 }
            else if score < 35 { counts[1] += 1 }
            else if score < 40 { counts[2] += 1 }
            else if score < 45 { counts[3] += 1 }
            else if score < 47 { counts[4] += 1 }
            else { counts[5] += 1 }
        }

        return [
            ScoreRange(label: "< 30", count: counts[0]),
            ScoreRange(label: "30-34", count: counts[1]),
            ScoreRange(label: "35-39", count: counts[2]),
            ScoreRange(label: "40-44", count: counts[3]),
            ScoreRange(label: "45-46", count: counts[4]),
            ScoreRange(label: "47-50", count: counts[5])
        ]
    }

    private var stats: (avg: Double, high: Double, low: Double)? {
        guard !scoresheets.isEmpty else { return nil }

        var total = 0.0
        var high = -Double.infinity
        var low = Double.infinity

        for sheet in scoresheets {
            let score = sheet.finalScore
            total += score
            if score > high { high = score }
            if score < low { low = score }
        }

        return (total / Double(scoresheets.count), high, low)
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
                if let stats = stats {
                    StatLabel(title: "Average", value: stats.avg.scoreFormatted)
                    StatLabel(title: "High", value: stats.high.scoreFormatted)
                    StatLabel(title: "Low", value: stats.low.scoreFormatted)
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
