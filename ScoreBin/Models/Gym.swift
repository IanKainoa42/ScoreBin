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
            DatabaseSchema.Gym.id: id.uuidString,
            DatabaseSchema.Gym.name: name,
            DatabaseSchema.Gym.location: location,
            DatabaseSchema.Gym.createdAt: ISO8601DateFormatter.shared.string(from: createdAt)
        ]
    }

    // MARK: - Import

    func update(from dictionary: [String: Any]) {
        if let name = dictionary[DatabaseSchema.Gym.name] as? String {
            self.name = name
        }
        if let location = dictionary[DatabaseSchema.Gym.location] as? String {
            self.location = location
        }
    }
}
