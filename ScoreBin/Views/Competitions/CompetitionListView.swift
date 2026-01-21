import SwiftUI
import SwiftData

struct CompetitionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Competition.date, order: .reverse) private var competitions: [Competition]

    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if competitions.isEmpty {
                    emptyStateView
                } else {
                    competitionsList
                }
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Competitions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCompetitionView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Competitions Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Add your first competition to start tracking scores")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                showingAddSheet = true
            } label: {
                Text("Add Competition")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.scoreBinGradient)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    private var competitionsList: some View {
        List {
            ForEach(competitions) { competition in
                NavigationLink(destination: CompetitionDetailView(competition: competition)) {
                    CompetitionRowView(competition: competition)
                }
                .listRowBackground(Color.scoreBinCardBackground)
            }
            .onDelete(perform: deleteCompetitions)
        }
        .scrollContentBackground(.hidden)
    }

    private func deleteCompetitions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(competitions[index])
        }
        try? modelContext.save()
    }
}

struct CompetitionRowView: View {
    let competition: Competition

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(competition.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(competition.scoresheets.count) sheets")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.scoreBinCyan)
                Text(competition.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                if !competition.location.isEmpty {
                    Spacer()
                    Image(systemName: "mappin")
                        .foregroundColor(.scoreBinCyan)
                    Text(competition.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CompetitionListView()
        .modelContainer(for: [Competition.self, Scoresheet.self], inMemory: true)
}
