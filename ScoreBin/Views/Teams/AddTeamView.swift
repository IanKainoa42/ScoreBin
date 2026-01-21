import SwiftUI
import SwiftData

struct AddTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let gyms: [Gym]

    @State private var name = ""
    @State private var selectedGym: Gym?
    @State private var level = "L2"
    @State private var ageDivision = "senior"
    @State private var tier = "elite"
    @State private var athleteCount = 20

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team Info") {
                    TextField("Team Name", text: $name)

                    Picker("Gym (Optional)", selection: $selectedGym) {
                        Text("No Gym").tag(nil as Gym?)
                        ForEach(gyms) { gym in
                            Text(gym.name).tag(gym as Gym?)
                        }
                    }

                    Picker("Level", selection: $level) {
                        ForEach(Team.levels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                }

                Section("Division") {
                    Picker("Age Division", selection: $ageDivision) {
                        ForEach(Team.ageDivisions, id: \.self) { div in
                            Text(div.capitalized).tag(div)
                        }
                    }

                    Picker("Tier", selection: $tier) {
                        ForEach(Team.tiers, id: \.self) { tier in
                            Text(tier.capitalized).tag(tier)
                        }
                    }
                }

                Section("Roster") {
                    Stepper("Athletes: \(athleteCount)", value: $athleteCount, in: 5...38)

                    let chart = ScoringRules.QuantityChart.forAthleteCount(athleteCount)
                    HStack {
                        Text("Quantity Chart")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(chart.description)
                            .foregroundColor(.scoreBinCyan)
                    }
                }
            }
            .navigationTitle("New Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addTeam()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addTeam() {
        let team = Team(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            gym: selectedGym,
            level: level,
            ageDivision: ageDivision,
            tier: tier,
            athleteCount: athleteCount
        )

        modelContext.insert(team)
        try? modelContext.save()
        dismiss()
    }
}

struct AddGymView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var location = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gym Info") {
                    TextField("Gym Name", text: $name)
                    TextField("Location (Optional)", text: $location)
                }
            }
            .navigationTitle("New Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addGym()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addGym() {
        let gym = Gym(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        modelContext.insert(gym)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddTeamView(gyms: [])
        .modelContainer(for: [Team.self, Gym.self], inMemory: true)
}
