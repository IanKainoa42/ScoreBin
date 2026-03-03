import SwiftUI
import Charts

struct ScoreDistributionChart: View {
    let scoresheets: [Scoresheet]

    private var chartData: (distribution: [ScoreRange], stats: (avg: Double, high: Double, low: Double)?) {
        guard !scoresheets.isEmpty else {
            return ([], nil)
        }

        let initialData: (counts: [Int], total: Double, high: Double, low: Double) = (
            counts: [Int](repeating: 0, count: 6),
            total: 0.0,
            high: -Double.infinity,
            low: Double.infinity
        )

        let aggregated = scoresheets.reduce(into: initialData) { result, sheet in
            let score = sheet.finalScore

            if score < 30 { result.counts[0] += 1 }
            else if score < 35 { result.counts[1] += 1 }
            else if score < 40 { result.counts[2] += 1 }
            else if score < 45 { result.counts[3] += 1 }
            else if score < 47 { result.counts[4] += 1 }
            else { result.counts[5] += 1 }

            result.total += score
            if score > result.high { result.high = score }
            if score < result.low { result.low = score }
        }

        let distribution = [
            ScoreRange(label: "< 30", count: aggregated.counts[0]),
            ScoreRange(label: "30-34", count: aggregated.counts[1]),
            ScoreRange(label: "35-39", count: aggregated.counts[2]),
            ScoreRange(label: "40-44", count: aggregated.counts[3]),
            ScoreRange(label: "45-46", count: aggregated.counts[4]),
            ScoreRange(label: "47-50", count: aggregated.counts[5])
        ]

        let stats = (aggregated.total / Double(scoresheets.count), aggregated.high, aggregated.low)
        return (distribution, stats)
    }

    var body: some View {
        let data = chartData

        VStack(alignment: .leading, spacing: 8) {
            Chart(data.distribution) { item in
                BarMark(
                    x: .value("Range", item.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.scoreBinCyan, .scoreBinEmerald],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .annotation(position: .top) {
                    if item.count > 0 {
                        Text("\(item.count)")
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
                if let stats = data.stats {
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
    var id: String { label }
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
