import Foundation
import SwiftData

@Model
final class Gym {
    var id: UUID
    var name: String
    var location: String
    var createdAt: Date

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
        self.teams = []
    }
}
