import SwiftData
import SwiftUI

struct ScoresheetEntryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = ScoresheetViewModel()
    @State private var showingExportAlert = false
    @State private var showingSaveAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Info Bar
                    ScoresheetHeaderView(viewModel: viewModel)

                    // Judge Panels
                    judgeGridSection

                    // Deductions
                    DeductionsSection(scoresheet: $viewModel.scoresheet)

                    // Score Summary
                    ScoreSummaryView(viewModel: viewModel)
                }
                .padding()
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Scoresheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        viewModel.reset()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.modelContext = modelContext
                        viewModel.save()
                        showingSaveAlert = true
                    }
                }
            }
            .alert("Saved", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {
                    viewModel.reset()
                }
            } message: {
                Text("Scoresheet saved successfully!")
            }
            .alert("Copied", isPresented: $showingExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Data copied to clipboard!")
            }
            .onAppear {
                viewModel.modelContext = modelContext
            }
        }
    }

    // MARK: - Judge Grid Section

    private var judgeGridSection: some View {
        VStack(spacing: 12) {
            BuildingJudgeSection(scoresheet: $viewModel.scoresheet)
            TumblingJudgeSection(scoresheet: $viewModel.scoresheet)
            OverallJudgeSection(scoresheet: $viewModel.scoresheet, viewModel: viewModel)
        }
    }
}

// MARK: - Header Subview

struct ScoresheetHeaderView: View {
    @Bindable var viewModel: ScoresheetViewModel

    @Query(sort: \Team.name) private var teams: [Team]
    @Query(sort: \Competition.date, order: .reverse) private var competitions: [Competition]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Team Picker
                Menu {
                    Button("No Team") {
                        viewModel.selectedTeam = nil
                    }
                    ForEach(teams) { team in
                        Button(team.name) {
                            viewModel.selectedTeam = team
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedTeam?.name ?? "Select Team")
                            .foregroundColor(viewModel.selectedTeam == nil ? .gray : .white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }

                // Competition Picker
                Menu {
                    Button("No Competition") {
                        viewModel.selectedCompetition = nil
                    }
                    ForEach(competitions) { competition in
                        Button(competition.name) {
                            viewModel.selectedCompetition = competition
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedCompetition?.name ?? "Select Competition")
                            .foregroundColor(viewModel.selectedCompetition == nil ? .gray : .white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }
            }

            HStack(spacing: 12) {
                // Round Picker
                Menu {
                    ForEach(RoundType.allCases, id: \.self) { round in
                        Button(round.rawValue) {
                            viewModel.scoresheet.round = round.rawValue
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.scoresheet.round)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }

                // Quantity Chart Display
                if let team = viewModel.selectedTeam {
                    HStack(spacing: 4) {
                        Text("\(team.athleteCount)")
                            .font(.headline)
                            .foregroundColor(.scoreBinCyan)
                        Text("athletes")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(viewModel.quantityChart.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, 4)
    }
}

#Preview {
    ScoresheetEntryView()
        .modelContainer(
            for: [Scoresheet.self, Team.self, Competition.self, Gym.self], inMemory: true)
}
