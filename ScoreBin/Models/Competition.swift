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
    var syncStatus: SyncStatus = .pending

    @Relationship(deleteRule: .cascade, inverse: \Scoresheet.competition)
    var scoresheets: [Scoresheet]

    init(
        id: UUID = UUID(),
        name: String,
        date: Date = Date(),
        location: String = "",
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.location = location
        self.notes = notes
        self.createdAt = createdAt
        self.syncStatus = .pending
        self.scoresheets = []
    }

    // Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
