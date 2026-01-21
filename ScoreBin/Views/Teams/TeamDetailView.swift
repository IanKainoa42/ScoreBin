import SwiftUI
import SwiftData

struct TeamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var team: Team

    @State private var insightsVM = InsightsViewModel()
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Team Info Card
                teamInfoCard

                // Statistics Card
                if !team.scoresheets.isEmpty {
                    statsCard
                }

                // Category Breakdown
                if !team.scoresheets.isEmpty {
                    categoryBreakdownCard
                }

                // Recent Scoresheets
                recentScoresheets
            }
            .padding()
        }
        .background(Color.scoreBinBackground)
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTeamView(team: team)
        }
        .onAppear {
            insightsVM.modelContext = modelContext
        }
    }

    private var teamInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let gym = team.gym {
                        Text(gym.name)
                            .font(.subheadline)
                            .foregroundColor(.scoreBinCyan)
                    }

                    Text(team.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(team.level)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.scoreBinCyan)

                    Text("\(team.ageDivision.capitalized) • \(team.tier.capitalized)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Divider()
                .background(Color.scoreBinBorder)

            HStack {
                VStack(spacing: 4) {
                    Text("\(team.athleteCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Athletes")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                let chart = ScoringRules.QuantityChart.forAthleteCount(team.athleteCount)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantity Chart")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(chart.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.scoreBinCyan)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                StatItem(
                    title: "Average",
                    value: insightsVM.averageScore(for: team).scoreFormatted
                )
                StatItem(
                    title: "Best",
                    value: insightsVM.bestScore(for: team).scoreFormatted
                )
                StatItem(
                    title: "Trend",
                    value: (insightsVM.scoreImprovement(for: team) >= 0 ? "+" : "") +
                           insightsVM.scoreImprovement(for: team).scoreFormatted
                )
                StatItem(
                    title: "Sheets",
                    value: "\(team.scoresheets.count)"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Category Scores")
                .font(.headline)
                .foregroundColor(.white)

            let breakdown = insightsVM.averageCategoryBreakdown(for: team)
            ForEach(breakdown) { category in
                HStack {
                    Text(category.category)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Spacer()

                    Text("\(category.score.scoreFormatted) / \(category.maxScore.scoreFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text("(\(Int(category.percentage))%)")
                        .font(.caption)
                        .foregroundColor(.scoreBinCyan)
                }

                ProgressView(value: category.score, total: category.maxScore)
                    .tint(colorForCategory(category.category))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }

    private var recentScoresheets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Scoresheets")
                .font(.headline)
                .foregroundColor(.white)

            if team.scoresheets.isEmpty {
                Text("No scoresheets yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(team.scoresheets.sorted { $0.createdAt > $1.createdAt }.prefix(5)) { sheet in
                    ScoresheetRowView(scoresheet: sheet)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct EditTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Gym.name) private var gyms: [Gym]
    @Bindable var team: Team

    var body: some View {
        NavigationStack {
            Form {
                Section("Team Info") {
                    TextField("Team Name", text: $team.name)

                    Picker("Gym", selection: $team.gym) {
                        Text("No Gym").tag(nil as Gym?)
                        ForEach(gyms) { gym in
                            Text(gym.name).tag(gym as Gym?)
                        }
                    }

                    Picker("Level", selection: $team.level) {
                        ForEach(Team.levels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                }

                Section("Division") {
                    Picker("Age Division", selection: $team.ageDivision) {
                        ForEach(Team.ageDivisions, id: \.self) { div in
                            Text(div.capitalized).tag(div)
                        }
                    }

                    Picker("Tier", selection: $team.tier) {
                        ForEach(Team.tiers, id: \.self) { tier in
                            Text(tier.capitalized).tag(tier)
                        }
                    }
                }

                Section("Roster") {
                    Stepper("Athletes: \(team.athleteCount)", value: $team.athleteCount, in: 5...38)
                }
            }
            .navigationTitle("Edit Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(team: Team(name: "Senior Black", level: "L6", athleteCount: 24))
    }
    .modelContainer(for: [Team.self, Gym.self, Scoresheet.self], inMemory: true)
}
