import SwiftUI
import SwiftData

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Team.name) private var teams: [Team]
    @Query(sort: \Gym.name) private var gyms: [Gym]

    @State private var showingAddSheet = false
    @State private var showingAddGymSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if teams.isEmpty {
                    emptyStateView
                } else {
                    teamsList
                }
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingAddGymSheet = true
                        } label: {
                            Label("Add Gym", systemImage: "building.2")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTeamView(gyms: gyms)
            }
            .sheet(isPresented: $showingAddGymSheet) {
                AddGymView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Teams Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Add your first team to start tracking their scores")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                showingAddSheet = true
            } label: {
                Text("Add Team")
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

    private var teamsList: some View {
        List {
            // Teams grouped by Gym
            let teamsByGym = Dictionary(grouping: teams) { $0.gym?.name ?? "No Gym" }
            let sortedGyms = teamsByGym.keys.sorted()

            ForEach(sortedGyms, id: \.self) { gymName in
                Section(header: Text(gymName).foregroundColor(.scoreBinCyan)) {
                    ForEach(teamsByGym[gymName] ?? []) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            TeamRowView(team: team)
                        }
                        .listRowBackground(Color.scoreBinCardBackground)
                    }
                    .onDelete { indexSet in
                        deleteTeams(teamsByGym[gymName] ?? [], at: indexSet)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func deleteTeams(_ teams: [Team], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(teams[index])
        }
        try? modelContext.save()
    }
}

struct TeamRowView: View {
    let team: Team

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(team.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(team.level)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.scoreBinCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.scoreBinCyan.opacity(0.2))
                    .cornerRadius(4)
            }

            HStack {
                Text("\(team.athleteCount) athletes")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                Text("\(team.scoresheets.count) scoresheets")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TeamListView()
        .modelContainer(for: [Team.self, Gym.self, Scoresheet.self], inMemory: true)
}
