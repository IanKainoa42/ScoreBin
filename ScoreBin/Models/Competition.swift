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

    private static let iso8601Formatter = ISO8601DateFormatter()

    // Format date for display
    var formattedDate: String {
        return Self.dateFormatter.string(from: date)
    }

    // MARK: - Update from Database

    func update(from data: [String: Any]) {
        if let name = data["name"] as? String { self.name = name }
        if let location = data["location"] as? String { self.location = location }
        if let notes = data["notes"] as? String { self.notes = notes }

        if let dateString = data["date"] as? String,
            let date = Self.iso8601Formatter.date(from: dateString)
        {
            self.date = date
        }

        if let createdAtString = data["created_at"] as? String,
            let date = Self.iso8601Formatter.date(from: createdAtString)
        {
            self.createdAt = date
        }
    }

    // MARK: - Export

    func exportForDatabase() -> [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "date": Self.iso8601Formatter.string(from: date),
            "location": location,
            "notes": notes,
            "created_at": Self.iso8601Formatter.string(from: createdAt)
        ]
    }
}
