import SwiftUI
import SwiftData
import Charts

struct GymAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    let gym: Gym

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        let summary = viewModel.gymSummary(for: gym)

        ScrollView {
            LazyVStack(alignment: .center, spacing: 16) {
                // Gym Overview
                gymOverviewSection(summary: summary)

                // Level Statistics
                levelStatsSection(summary: summary)

                // Teams List
                teamsListSection(summary: summary)
            }
            .padding()
        }
        .background(Color.scoreBinBackground)
        .navigationTitle(gym.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }

    // MARK: - Gym Overview

    private func gymOverviewSection(summary: InsightsViewModel.GymSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(summary.teamCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.scoreBinCyan)
                    Text("Teams")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 4) {
                    Text("\(summary.totalScoresheets)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.scoreBinEmerald)
                    Text("Scoresheets")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 4) {
                    Text("\(summary.totalAthletes)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.overallYellow)
                    Text("Athletes")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Level Stats

    private func levelStatsSection(summary: InsightsViewModel.GymSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Score by Level")
                .font(.headline)
                .foregroundColor(.white)

            if summary.levelStats.isEmpty || summary.levelStats.allSatisfy({ $0.scoresheetCount == 0 }) {
                Text("No scoresheets recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Chart(summary.levelStats.filter { $0.scoresheetCount > 0 }) { stat in
                    BarMark(
                        x: .value("Level", stat.level),
                        y: .value("Score", stat.averageScore)
                    )
                    .foregroundStyle(Color.scoreBinGradient)
                    .annotation(position: .top) {
                        Text(stat.averageScore.scoreFormatted)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .chartYScale(domain: 0...50)
                .frame(height: 200)

                // Stats table
                ForEach(summary.levelStats) { stat in
                    HStack {
                        Text(stat.level)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(width: 50, alignment: .leading)

                        Text("\(stat.teamCount) teams")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        if stat.scoresheetCount > 0 {
                            Text(stat.averageScore.scoreFormatted)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.scoreBinCyan)
                        } else {
                            Text("No data")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Teams List

    private func teamsListSection(summary: InsightsViewModel.GymSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teams")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(summary.sortedTeams) { team in
                NavigationLink(destination: TeamTrendsView(team: team)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(team.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)

                            Text("\(team.athleteCount) athletes • \(team.scoresheets.count) sheets")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text(team.level)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.scoreBinCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.scoreBinCyan.opacity(0.2))
                            .cornerRadius(4)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        GymAnalyticsView(gym: Gym(name: "Champion Cheer"))
    }
    .modelContainer(for: [Gym.self, Team.self, Scoresheet.self], inMemory: true)
}
