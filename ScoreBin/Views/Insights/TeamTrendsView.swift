import SwiftUI
import SwiftData
import Charts

struct TeamTrendsView: View {
    @Environment(\.modelContext) private var modelContext
    let team: Team

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Score Over Time Chart
                scoreOverTimeSection

                // Category Breakdown
                categoryBreakdownSection

                // Deduction Patterns
                deductionPatternsSection

                // All Scoresheets
                allScoresheetsSection
            }
            .padding()
        }
        .background(Color.scoreBinBackground)
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }

    // MARK: - Score Over Time

    private var scoreOverTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score Progression")
                .font(.headline)
                .foregroundColor(.white)

            if team.scoresheets.isEmpty {
                Text("No scoresheets yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                let dataPoints = viewModel.scoreHistory(for: team)

                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Color.scoreBinCyan)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Color.scoreBinCyan)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
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
                .frame(height: 200)
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Category Scores")
                .font(.headline)
                .foregroundColor(.white)

            let breakdown = viewModel.averageCategoryBreakdown(for: team)

            Chart(breakdown) { category in
                BarMark(
                    x: .value("Category", category.category),
                    y: .value("Percentage", category.percentage)
                )
                .foregroundStyle(colorForCategory(category.category))
                .annotation(position: .top) {
                    Text("\(Int(category.percentage))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                ForEach(breakdown) { category in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForCategory(category.category))
                            .frame(width: 8, height: 8)
                        Text("\(category.score.scoreFormatted)/\(category.maxScore.scoreFormatted)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Deduction Patterns

    private var deductionPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deduction Patterns")
                .font(.headline)
                .foregroundColor(.white)

            let patterns = viewModel.deductionPatterns(for: team)

            if patterns.isEmpty {
                Text("No deductions recorded")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(patterns) { pattern in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pattern.category)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("\(pattern.totalCount) occurrences")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text("-\(pattern.totalPoints.scoreFormatted)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - All Scoresheets

    private var allScoresheetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Scoresheets")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(team.scoresheets.sorted { $0.createdAt > $1.createdAt }) { sheet in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sheet.competition?.name ?? "Practice")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)

                        HStack {
                            Text(sheet.round)
                                .font(.caption)
                                .foregroundColor(.scoreBinCyan)
                            Text("•")
                                .foregroundColor(.gray)
                            Text(sheet.createdAt.shortFormatted)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    Text(sheet.finalScore.scoreFormatted)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.scoreBinEmerald)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.scoreBinBackground.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .cardStyle()
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Building": return .buildingRed
        case "Tumbling": return .tumblingTeal
        case "Overall": return .overallYellow
        default: return .scoreBinCyan
        }
    }
}

#Preview {
    NavigationStack {
        TeamTrendsView(team: Team(name: "Senior Black", level: "L6"))
    }
    .modelContainer(for: [Team.self, Scoresheet.self], inMemory: true)
}
