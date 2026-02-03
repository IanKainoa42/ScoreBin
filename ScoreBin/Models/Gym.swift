import Foundation
import SwiftData

@Model
final class Gym {
    var id: UUID
    var name: String
    var location: String
    var createdAt: Date
    var syncStatus: SyncStatus

    @Relationship(deleteRule: .cascade, inverse: \Team.gym)
    var teams: [Team]

    init(
        id: UUID = UUID(),
        name: String,
        location: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.createdAt = createdAt
        self.syncStatus = .pending
        self.teams = []
    }

    // MARK: - Export

    private static let iso8601Formatter = ISO8601DateFormatter()

    func exportForDatabase() -> [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "location": location,
            "created_at": Self.iso8601Formatter.string(from: createdAt)
        ]
    }
}
