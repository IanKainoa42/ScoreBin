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

    func exportForDatabase() -> [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "location": location,
            "created_at": ISO8601DateFormatter.shared.string(from: createdAt)
        ]
    }

    // MARK: - Update

    func update(from data: [String: Any]) {
        if let name = data["name"] as? String { self.name = name }
        if let location = data["location"] as? String { self.location = location }
    }
}
