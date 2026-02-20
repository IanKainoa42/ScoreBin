import Foundation
import SwiftData

@Model
final class Competition {
    var id: UUID
    var name: String
    var date: Date
    var location: String
    var notes: String
    var createdAt: Date
    var syncStatus: SyncStatus

    @Relationship(deleteRule: .cascade, inverse: \Scoresheet.competition)
    var scoresheets: [Scoresheet]

    init(
        id: UUID = UUID(),
        name: String,
        date: Date = Date(),
        location: String = "",
        notes: String = "",
        createdAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.location = location
        self.notes = notes
        self.createdAt = createdAt
        self.syncStatus = syncStatus
        self.scoresheets = []
    }

    // Static formatter for reuse
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // Format date for display
    var formattedDate: String {
        return Self.dateFormatter.string(from: date)
    }

    // MARK: - Export

    func exportForDatabase() -> [String: Any] {
        [
            DatabaseSchema.Competition.id: id.uuidString,
            DatabaseSchema.Competition.name: name,
            DatabaseSchema.Competition.date: ISO8601DateFormatter.shared.string(from: date),
            DatabaseSchema.Competition.location: location,
            DatabaseSchema.Competition.notes: notes,
            DatabaseSchema.Competition.createdAt: ISO8601DateFormatter.shared.string(from: createdAt)
        ]
    }

    // MARK: - Import

    func update(from dictionary: [String: Any]) {
        if let name = dictionary[DatabaseSchema.Competition.name] as? String {
            self.name = name
        }
        if let dateString = dictionary[DatabaseSchema.Competition.date] as? String,
           let date = ISO8601DateFormatter.shared.date(from: dateString) {
            self.date = date
        }
        if let location = dictionary[DatabaseSchema.Competition.location] as? String {
            self.location = location
        }
        if let notes = dictionary[DatabaseSchema.Competition.notes] as? String {
            self.notes = notes
        }
    }
}
