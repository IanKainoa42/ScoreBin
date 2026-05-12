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
    @State private var saveError: IdentifiableError?

    var isValid: Bool {
        !name.isBlank
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team Info") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Team Name", text: $name)
                        Text("(required)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

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
            .alert("Error Saving", item: $saveError) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.message)
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
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = IdentifiableError(message: error.localizedDescription)
            print("Failed to save new team: \(error)")
        }
    }
}

struct AddGymView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var location = ""
    @State private var saveError: IdentifiableError?

    var isValid: Bool {
        !name.isBlank
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
            .alert("Error Saving", item: $saveError) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.message)
            }
        }
    }

    private func addGym() {
        let gym = Gym(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        modelContext.insert(gym)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = IdentifiableError(message: error.localizedDescription)
            print("Failed to save new gym: \(error)")
        }
    }
}

#Preview {
    AddTeamView(gyms: [])
        .modelContainer(for: [Team.self, Gym.self], inMemory: true)
}
