import SwiftUI
import SwiftData
import Charts

struct TeamComparisonView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Team.name) private var allTeams: [Team]

    @State private var viewModel = InsightsViewModel()
    @State private var teamAID: PersistentIdentifier?
    @State private var teamBID: PersistentIdentifier?

    private var activeTeams: [Team] {
        allTeams.filter { !$0.scoresheets.isEmpty }
    }

    private var teamA: Team? {
        activeTeams.first { $0.persistentModelID == teamAID }
    }

    private var teamB: Team? {
        activeTeams.first { $0.persistentModelID == teamBID }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, spacing: 16) {
                pickerSection

                if activeTeams.count < 2 {
                    emptyState
                } else if let teamA, let teamB {
                    let summaryA = viewModel.teamSummary(for: teamA)
                    let summaryB = viewModel.teamSummary(for: teamB)

                    headlineStatsSection(a: summaryA, b: summaryB)
                    categoryComparisonSection(a: summaryA, b: summaryB)
                    deductionComparisonSection(a: summaryA, b: summaryB)
                } else {
                    Text("Pick two teams to compare")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
            .padding()
        }
        .background(Color.scoreBinBackground)
        .navigationTitle("Compare Teams")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.modelContext = modelContext
            if teamAID == nil, activeTeams.count >= 1 {
                teamAID = activeTeams[0].persistentModelID
            }
            if teamBID == nil, activeTeams.count >= 2 {
                teamBID = activeTeams[1].persistentModelID
            }
        }
    }

    // MARK: - Picker Section

    private var pickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teams")
                .font(.headline)
                .foregroundColor(.white)

            teamPicker(label: "Team A", selection: $teamAID, accent: .scoreBinCyan)
            teamPicker(label: "Team B", selection: $teamBID, accent: .scoreBinEmerald)
        }
        .padding()
        .cardStyle()
    }

    private func teamPicker(
        label: String,
        selection: Binding<PersistentIdentifier?>,
        accent: Color
    ) -> some View {
        HStack {
            Circle()
                .fill(accent)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Menu {
                ForEach(activeTeams) { team in
                    Button(team.name) {
                        selection.wrappedValue = team.persistentModelID
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(activeTeams.first { $0.persistentModelID == selection.wrappedValue }?.name ?? "Select")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Need at least 2 teams with scoresheets")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Score routines for two teams to compare them here")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Headline Stats

    private func headlineStatsSection(
        a: InsightsViewModel.TeamSummary,
        b: InsightsViewModel.TeamSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Head to Head")
                .font(.headline)
                .foregroundColor(.white)

            statRow(
                label: "Average",
                aValue: a.averageScore,
                bValue: b.averageScore,
                format: .score
            )
            statRow(
                label: "Best",
                aValue: a.bestScore,
                bValue: b.bestScore,
                format: .score
            )
            statRow(
                label: "Improvement",
                aValue: a.scoreImprovement,
                bValue: b.scoreImprovement,
                format: .signedScore
            )
            statRow(
                label: "Scoresheets",
                aValue: Double(a.totalScoresheets),
                bValue: Double(b.totalScoresheets),
                format: .integer
            )
        }
        .padding()
        .cardStyle()
    }

    private enum StatFormat { case score, signedScore, integer }

    private func statRow(
        label: String,
        aValue: Double,
        bValue: Double,
        format: StatFormat
    ) -> some View {
        let aWins = aValue > bValue
        let bWins = bValue > aValue

        return HStack {
            Text(formatted(aValue, format: format))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(aWins ? .scoreBinCyan : .white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(formatted(bValue, format: format))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(bWins ? .scoreBinEmerald : .white)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }

    private func formatted(_ value: Double, format: StatFormat) -> String {
        switch format {
        case .score:
            return value.scoreFormatted
        case .signedScore:
            return (value >= 0 ? "+" : "") + value.scoreFormatted
        case .integer:
            return "\(Int(value))"
        }
    }

    // MARK: - Category Comparison

    private func categoryComparisonSection(
        a: InsightsViewModel.TeamSummary,
        b: InsightsViewModel.TeamSummary
    ) -> some View {
        struct CategoryBar: Identifiable {
            let id = UUID()
            let category: String
            let team: String
            let percentage: Double
        }

        let bars: [CategoryBar] = zip(a.categoryBreakdown, b.categoryBreakdown).flatMap { catA, catB in
            [
                CategoryBar(category: catA.category, team: a.team.name, percentage: catA.percentage),
                CategoryBar(category: catB.category, team: b.team.name, percentage: catB.percentage)
            ]
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
                .foregroundColor(.white)

            Chart(bars) { bar in
                BarMark(
                    x: .value("Category", bar.category),
                    y: .value("Percentage", bar.percentage)
                )
                .foregroundStyle(by: .value("Team", bar.team))
                .position(by: .value("Team", bar.team))
            }
            .chartForegroundStyleScale([
                a.team.name: Color.scoreBinCyan,
                b.team.name: Color.scoreBinEmerald
            ])
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine().foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%").foregroundStyle(.gray)
                        }
                    }
                }
            }
            .frame(height: 220)

            HStack(spacing: 16) {
                legendDot(color: .scoreBinCyan, label: a.team.name)
                legendDot(color: .scoreBinEmerald, label: b.team.name)
            }
        }
        .padding()
        .cardStyle()
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Deduction Comparison

    private func deductionComparisonSection(
        a: InsightsViewModel.TeamSummary,
        b: InsightsViewModel.TeamSummary
    ) -> some View {
        let allCategories = Array(Set(a.deductionPatterns.map(\.category) + b.deductionPatterns.map(\.category))).sorted()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Deduction Patterns")
                .font(.headline)
                .foregroundColor(.white)

            if allCategories.isEmpty {
                Text("No deductions recorded for either team")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(allCategories, id: \.self) { category in
                    let aPattern = a.deductionPatterns.first { $0.category == category }
                    let bPattern = b.deductionPatterns.first { $0.category == category }
                    deductionRow(category: category, aPattern: aPattern, bPattern: bPattern)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private func deductionRow(
        category: String,
        aPattern: InsightsViewModel.DeductionPattern?,
        bPattern: InsightsViewModel.DeductionPattern?
    ) -> some View {
        let aCount = aPattern?.totalCount ?? 0
        let bCount = bPattern?.totalCount ?? 0
        let aPoints = aPattern?.totalPoints ?? 0
        let bPoints = bPattern?.totalPoints ?? 0

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("-\(aPoints.scoreFormatted)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                Text("\(aCount)x")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(category)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 2) {
                Text("-\(bPoints.scoreFormatted)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                Text("\(bCount)x")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        TeamComparisonView()
    }
    .modelContainer(for: [Team.self, Scoresheet.self, Competition.self, Gym.self], inMemory: true)
}
