import SwiftUI
import SwiftData
import Charts

struct InsightsDashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = InsightsViewModel()
    @State private var dashboard = InsightsViewModel.DashboardSnapshot.empty

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .center, spacing: 16) {
                    // Overview Stats
                    overviewSection

                    // Recent Activity
                    recentActivitySection

                    // Score Distribution Chart
                    if dashboard.scoresheetCount > 0 {
                        scoreDistributionSection
                    }

                    // Team Performance
                    if dashboard.teamCount > 0 {
                        teamPerformanceSection
                        compareTeamsLink
                    }
                }
                .padding()
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Insights")
            .refreshable {
                reloadDashboard()
            }
            .onAppear {
                viewModel.modelContext = modelContext
                reloadDashboard()
            }
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 16) {
                OverviewStatCard(
                    title: "Teams",
                    value: "\(dashboard.teamCount)",
                    icon: "person.3.fill",
                    color: .scoreBinCyan
                )

                OverviewStatCard(
                    title: "Scoresheets",
                    value: "\(dashboard.scoresheetCount)",
                    icon: "doc.text.fill",
                    color: .scoreBinEmerald
                )

                OverviewStatCard(
                    title: "Competitions",
                    value: "\(dashboard.competitionCount)",
                    icon: "trophy.fill",
                    color: .overallYellow
                )
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.white)

            if dashboard.recentActivity.isEmpty {
                VStack(spacing: 8) {
                    Text("No scoresheets yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Go to the Scoresheet tab to enter your first scores")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ForEach(dashboard.recentActivity) { item in
                    RecentActivityRow(item: item)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Score Distribution Section

    private var scoreDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score Distribution")
                .font(.headline)
                .foregroundColor(.white)

            ScoreDistributionChart(scores: dashboard.distributionScores)
                .frame(height: 200)
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Team Performance Section

    private var teamPerformanceSection: some View {
        return VStack(alignment: .leading, spacing: 12) {
            Text("Team Performance")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(dashboard.teamSummaries, id: \.team.id) { summary in
                NavigationLink(destination: TeamTrendsView(team: summary.team)) {
                    TeamPerformanceRow(summary: summary)
                }
            }

            if dashboard.teamSummaries.isEmpty {
                VStack(spacing: 8) {
                    Text("No team performance data yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Score a team's routine to see their performance trends here")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .cardStyle()
    }

    private var compareTeamsLink: some View {
        NavigationLink(destination: TeamComparisonView()) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.scoreBinCyan)
                Text("Compare Teams")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .cardStyle()
        }
    }

    private func reloadDashboard() {
        do {
            dashboard = try viewModel.dashboardSnapshot(context: modelContext)
        } catch {
            print("Failed to load dashboard snapshot: \(error)")
            dashboard = .empty
        }
    }
}

// MARK: - Supporting Views

struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RecentActivityRow: View {
    let item: InsightsViewModel.RecentActivitySummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.teamName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    if let competitionName = item.competitionName {
                        Text(competitionName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(item.createdAt.shortFormatted)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(item.finalScore.scoreFormatted)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.scoreBinEmerald)
        }
        .padding(.vertical, 8)
    }
}

struct TeamPerformanceRow: View {
    let summary: InsightsViewModel.TeamSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.team.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text("\(summary.totalScoresheets) scoresheets")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(summary.averageScore.scoreFormatted)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.scoreBinCyan)

                if summary.scoreImprovement != 0 {
                    Text((summary.scoreImprovement >= 0 ? "+" : "") + summary.scoreImprovement.scoreFormatted)
                        .font(.caption)
                        .foregroundColor(summary.scoreImprovement >= 0 ? .green : .red)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    InsightsDashboardView()
        .modelContainer(for: [Team.self, Scoresheet.self, Competition.self, Gym.self], inMemory: true)
}
