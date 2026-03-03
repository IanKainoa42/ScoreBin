import SwiftData
import SwiftUI

struct AddCompetitionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var notes = ""
    @State private var saveError: String?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            .saveErrorAlert($saveError)
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
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    AddCompetitionView()
        .modelContainer(for: Competition.self, inMemory: true)
}
