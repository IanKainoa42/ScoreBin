import SwiftUI
import SwiftData
import Charts

struct InsightsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    @Query(sort: \Scoresheet.createdAt, order: .reverse) private var scoresheets: [Scoresheet]
    @Query private var competitions: [Competition]

    @State private var viewModel = InsightsViewModel()
    @State private var selectedTab: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .center, spacing: 16) {
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
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No scoresheets yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    NavigationLink {
                        ScoresheetEntryView()
                    } label: {
                        Text("Enter Your First Scoresheet →")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.scoreBinCyan)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ForEach(scoresheets.prefix(5)) { sheet in
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
                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 300 : 200)
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Team Performance Section

    @State private var showAllTeams = false

    private var teamPerformanceSection: some View {
        let allActive = viewModel.activeTeams(from: teams)
        let displayedTeams = showAllTeams ? allActive : Array(allActive.prefix(5))

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Team Performance")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if allActive.count > 5 {
                    Button(showAllTeams ? "Show Less" : "See All (\(allActive.count))") {
                        withAnimation { showAllTeams.toggle() }
                    }
                    .font(.caption)
                    .foregroundColor(.scoreBinCyan)
                }
            }

            ForEach(displayedTeams) { team in
                NavigationLink(destination: TeamTrendsView(team: team)) {
                    TeamPerformanceRow(team: team, viewModel: viewModel)
                }
            }

            if allActive.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
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
