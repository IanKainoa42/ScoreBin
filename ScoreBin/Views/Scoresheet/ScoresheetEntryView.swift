import SwiftData
import SwiftUI

struct ScoresheetEntryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = ScoresheetViewModel()
    @State private var showingExportAlert = false
    @State private var showingSaveAlert = false
    @State private var showingResetConfirmation = false

    /// Team must be selected before scoring and saving are allowed
    private var canEnterScores: Bool {
        viewModel.selectedTeam != nil
    }

    private var canSave: Bool {
        canEnterScores
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Info Bar
                        ScoresheetHeaderView(viewModel: viewModel)

                        // Validation: team required before scoring
                        if viewModel.selectedTeam == nil {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.overallYellow)
                                Text("Select a team above to enable score entry")
                                    .font(.subheadline)
                                    .foregroundColor(.overallYellow)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.overallYellow.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Judge Panels
                        judgeGridSection
                            .disabled(!canEnterScores)
                            .opacity(canEnterScores ? 1 : 0.45)

                        // Deductions
                        DeductionsSection(scoresheet: $viewModel.scoresheet)
                            .disabled(!canEnterScores)
                            .opacity(canEnterScores ? 1 : 0.45)

                        // Score Summary
                        ScoreSummaryView(viewModel: viewModel)
                            .opacity(canEnterScores ? 1 : 0.6)

                        // Bottom spacer so content isn't hidden behind sticky bar
                        Color.clear.frame(height: 60)
                    }
                    .padding()
                }

                // Sticky score bar - always visible at bottom
                StickyScoreBar(viewModel: viewModel)
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Scoresheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.modelContext = modelContext
                        viewModel.save()
                        showingSaveAlert = true
                    }
                    .disabled(!canSave)
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
            .alert("Reset Scoresheet", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.reset()
                }
            } message: {
                Text("Are you sure you want to reset all scores?")
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

    @State private var showingQuantityChartHelp = false

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
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(viewModel.selectedTeam?.name ?? "Select Team")
                                .foregroundColor(viewModel.selectedTeam == nil ? .gray : .white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        if viewModel.selectedTeam == nil {
                            Text("(required)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                        Button {
                            showingQuantityChartHelp = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.scoreBinCyan)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                    .alert("Quantity Chart", isPresented: $showingQuantityChartHelp) {
                        Button("Got it", role: .cancel) {}
                    } message: {
                        Text(ScoringRules.QuantityChart.helpText)
                    }
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
