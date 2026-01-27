import SwiftData
import SwiftUI

struct CompetitionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var competition: Competition

    @State private var viewModel = CompetitionViewModel()
    @State private var showingEditSheet = false
    @State private var selectedScoresheet: Scoresheet?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Competition Info Card
                infoCard

                // Statistics Card
                if !competition.scoresheets.isEmpty {
                    statsCard
                }

                // Scoresheets by Round
                scoresheetsByRound
            }
            .padding()
        }
        .background(Color.scoreBinBackground)
        .navigationTitle(competition.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCompetitionView(competition: competition)
        }
        .sheet(item: $selectedScoresheet) { scoresheet in
            ScoreSheetDetailView(scoresheet: scoresheet)
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.scoreBinCyan)
                Text(competition.formattedDate)
                    .foregroundColor(.white)
            }

            if !competition.location.isEmpty {
                HStack {
                    Image(systemName: "mappin.circle")
                        .foregroundColor(.scoreBinCyan)
                    Text(competition.location)
                        .foregroundColor(.white)
                }
            }

            if !competition.notes.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .foregroundColor(.scoreBinCyan)
                    Text(competition.notes)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                StatItem(title: "Total", value: "\(competition.scoresheets.count)")
                StatItem(
                    title: "Average", value: viewModel.averageScore(for: competition).scoreFormatted
                )
                StatItem(
                    title: "High", value: viewModel.highestScore(for: competition).scoreFormatted)
                StatItem(
                    title: "Low", value: viewModel.lowestScore(for: competition).scoreFormatted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }

    private var scoresheetsByRound: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scoresheets")
                .font(.headline)
                .foregroundColor(.white)

            if competition.scoresheets.isEmpty {
                Text("No scoresheets for this competition yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                let byRound = viewModel.scoresheetsByRound(for: competition)
                ForEach(Array(byRound.keys.sorted()), id: \.self) { round in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(round)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.scoreBinCyan)

                        ForEach(byRound[round] ?? []) { sheet in
                            Button {
                                selectedScoresheet = sheet
                            } label: {
                                ScoresheetRowView(scoresheet: sheet)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.scoreBinCyan)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ScoresheetRowView: View {
    let scoresheet: Scoresheet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(scoresheet.team?.name ?? "Unknown Team")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(scoresheet.createdAt.shortFormatted)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(scoresheet.finalScore.scoreFormatted)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.scoreBinEmerald)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.scoreBinBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

struct EditCompetitionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var competition: Competition

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $competition.name)
                    DatePicker("Date", selection: $competition.date, displayedComponents: .date)
                    TextField("Location", text: $competition.location)
                }

                Section("Notes") {
                    TextEditor(text: $competition.notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Competition")
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
        CompetitionDetailView(
            competition: Competition(name: "NCA All-Star", date: Date(), location: "Dallas, TX"))
    }
    .modelContainer(for: [Competition.self, Scoresheet.self, Team.self], inMemory: true)
}
