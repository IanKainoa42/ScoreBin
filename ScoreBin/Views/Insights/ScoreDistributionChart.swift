import SwiftUI
import Charts

// MARK: - Performance Tier

/// Defines benchmark zones for USS score ranges.
enum PerformanceTier: String {
    case below = "Below Avg"
    case developing = "Developing"
    case competitive = "Competitive"
    case strong = "Strong"
    case elite = "Elite"
    case peak = "Peak"

    var color: Color {
        switch self {
        case .below: return .red.opacity(0.75)
        case .developing: return .orange
        case .competitive: return .overallYellow
        case .strong: return .scoreBinCyan
        case .elite: return .scoreBinEmerald
        case .peak: return .purple
        }
    }
}

// MARK: - Score Distribution Chart

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
            ScoreRange(label: "< 30", count: aggregated.counts[0], tier: .below),
            ScoreRange(label: "30–34", count: aggregated.counts[1], tier: .developing),
            ScoreRange(label: "35–39", count: aggregated.counts[2], tier: .competitive),
            ScoreRange(label: "40–44", count: aggregated.counts[3], tier: .strong),
            ScoreRange(label: "45–46", count: aggregated.counts[4], tier: .elite),
            ScoreRange(label: "47–50", count: aggregated.counts[5], tier: .peak)
        ]

        let stats = (aggregated.total / Double(scoresheets.count), aggregated.high, aggregated.low)
        return (distribution, stats)
    }

    var body: some View {
        let data = chartData

        VStack(alignment: .leading, spacing: 12) {
            // Tier legend
            benchmarkLegend

            // Bar chart — bars colored by performance tier
            Chart(data.distribution) { item in
                BarMark(
                    x: .value("Range", item.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.tier.color)
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
            if let stats = data.stats {
                HStack(spacing: 20) {
                    StatLabel(title: "Average", value: stats.avg.scoreFormatted)
                    StatLabel(title: "High", value: stats.high.scoreFormatted)
                    StatLabel(title: "Low", value: stats.low.scoreFormatted)

                    Spacer()

                    // Show which tier the average falls in
                    if let avgTier = tier(for: stats.avg) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(avgTier.color)
                                .frame(width: 8, height: 8)
                            Text(avgTier.rawValue)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Benchmark Legend

    private var benchmarkLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([
                    PerformanceTier.below,
                    .developing,
                    .competitive,
                    .strong,
                    .elite,
                    .peak
                ], id: \.rawValue) { t in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(t.color)
                            .frame(width: 10, height: 10)
                        Text(t.rawValue)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private func tier(for score: Double) -> PerformanceTier? {
        if score < 30 { return .below }
        if score < 35 { return .developing }
        if score < 40 { return .competitive }
        if score < 45 { return .strong }
        if score < 47 { return .elite }
        return .peak
    }
}

// MARK: - Supporting Types

struct ScoreRange: Identifiable {
    var id: String { label }
    let label: String
    let count: Int
    let tier: PerformanceTier
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
