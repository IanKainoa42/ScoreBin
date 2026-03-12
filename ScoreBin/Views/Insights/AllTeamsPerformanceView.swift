import SwiftUI
import SwiftData

struct AllTeamsPerformanceView: View {
    @Query(sort: \Team.name) private var teams: [Team]

    @State private var viewModel = InsightsViewModel()
    @State private var sortOption: SortOption = .name

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case average = "Avg Score"
        case count = "# Sheets"
    }

    private var sortedTeams: [Team] {
        let activeTeams = teams.filter { !$0.scoresheets.isEmpty }
        switch sortOption {
        case .name:
            return activeTeams.sorted { $0.name < $1.name }
        case .average:
            return activeTeams.sorted { viewModel.averageScore(for: $0) > viewModel.averageScore(for: $1) }
        case .count:
            return activeTeams.sorted { $0.scoresheets.count > $1.scoresheets.count }
        }
    }

    var body: some View {
        List {
            if sortedTeams.isEmpty {
                Text("No teams with scoresheets yet")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.scoreBinCardBackground)
            } else {
                ForEach(sortedTeams) { team in
                    NavigationLink(destination: TeamTrendsView(team: team)) {
                        TeamPerformanceRow(team: team, viewModel: viewModel)
                    }
                    .listRowBackground(Color.scoreBinCardBackground)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.scoreBinBackground)
        .navigationTitle("All Teams")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AllTeamsPerformanceView()
    }
    .modelContainer(for: [Team.self, Scoresheet.self], inMemory: true)
}
