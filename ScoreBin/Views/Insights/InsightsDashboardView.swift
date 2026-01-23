import SwiftUI
import SwiftData
import Charts

struct InsightsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    @Query private var scoresheets: [Scoresheet]
    @Query private var competitions: [Competition]

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Overview Stats
                    overviewSection

                    // Recent Activity
                    recentActivitySection

                    // Score Distribution Chart
                    if !scoresheets.isEmpty {
                        scoreDistributionSection
                    }

                    // Team Performance
                    if !teams.isEmpty {
                        teamPerformanceSection
                    }
                }
                .padding()
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Insights")
            .onAppear {
                viewModel.modelContext = modelContext
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
                    value: "\(teams.count)",
                    icon: "person.3.fill",
                    color: .scoreBinCyan
                )

                OverviewStatCard(
                    title: "Scoresheets",
                    value: "\(scoresheets.count)",
                    icon: "doc.text.fill",
                    color: .scoreBinEmerald
                )

                OverviewStatCard(
                    title: "Competitions",
                    value: "\(competitions.count)",
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

            if scoresheets.isEmpty {
                Text("No scoresheets yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentScoresheets(from: scoresheets)) { sheet in
                    RecentActivityRow(scoresheet: sheet)
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

            ScoreDistributionChart(scoresheets: scoresheets)
                .frame(height: 200)
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Team Performance Section

    private var teamPerformanceSection: some View {
        let activeTeams = viewModel.activeTeams(from: teams)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Team Performance")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(activeTeams) { team in
                NavigationLink(destination: TeamTrendsView(team: team)) {
                    TeamPerformanceRow(team: team, viewModel: viewModel)
                }
            }

            if activeTeams.isEmpty {
                Text("Add scoresheets to teams to see performance data")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .cardStyle()
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
    let scoresheet: Scoresheet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(scoresheet.team?.name ?? "Unknown Team")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    if let competition = scoresheet.competition {
                        Text(competition.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(scoresheet.createdAt.shortFormatted)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(scoresheet.finalScore.scoreFormatted)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.scoreBinEmerald)
        }
        .padding(.vertical, 8)
    }
}

struct TeamPerformanceRow: View {
    let team: Team
    var viewModel: InsightsViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text("\(team.scoresheets.count) scoresheets")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.averageScore(for: team).scoreFormatted)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.scoreBinCyan)

                let improvement = viewModel.scoreImprovement(for: team)
                if improvement != 0 {
                    Text((improvement >= 0 ? "+" : "") + improvement.scoreFormatted)
                        .font(.caption)
                        .foregroundColor(improvement >= 0 ? .green : .red)
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
