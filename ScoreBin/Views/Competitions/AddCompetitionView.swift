import SwiftData
import SwiftUI

struct AddCompetitionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var notes = ""
    @State private var saveError: IdentifiableError?

    var isValid: Bool {
        !name.isBlank
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Competition Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Competition Name", text: $name)
                        Text("(required)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Location", text: $location)
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Competition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addCompetition()
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

    private func addCompetition() {
        let competition = Competition(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        modelContext.insert(competition)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = IdentifiableError(message: error.localizedDescription)
            print("Failed to save new competition: \(error)")
        }
    }
}

#Preview {
    AddCompetitionView()
        .modelContainer(for: Competition.self, inMemory: true)
}
