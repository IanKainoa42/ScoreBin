import SwiftUI
import SwiftData
import Charts

struct TeamTrendsView: View {
    @Environment(\.modelContext) private var modelContext
    let team: Team

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        let summary = viewModel.teamSummary(for: team)

        ScrollView {
            LazyVStack(alignment: .center, spacing: 16) {
                // Score Over Time Chart
                scoreOverTimeSection(summary: summary)

                // Category Breakdown
                categoryBreakdownSection(summary: summary)

                // Deduction Patterns
                deductionPatternsSection(summary: summary)

                // All Scoresheets
                allScoresheetsSection(summary: summary)
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

    private func scoreOverTimeSection(summary: InsightsViewModel.TeamSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score Progression")
                .font(.headline)
                .foregroundColor(.white)

            if summary.scoreHistory.isEmpty {
                Text("No scoresheets yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(summary.scoreHistory) { point in
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

    private func categoryBreakdownSection(summary: InsightsViewModel.TeamSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Category Scores")
                .font(.headline)
                .foregroundColor(.white)

            Chart(summary.categoryBreakdown) { category in
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
                ForEach(summary.categoryBreakdown) { category in
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

    private func deductionPatternsSection(summary: InsightsViewModel.TeamSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deduction Patterns")
                .font(.headline)
                .foregroundColor(.white)

            if summary.deductionPatterns.isEmpty {
                Text("No deductions recorded")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(summary.deductionPatterns) { pattern in
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

    private func allScoresheetsSection(summary: InsightsViewModel.TeamSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Scoresheets")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(summary.sortedScoresheets) { sheet in
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
