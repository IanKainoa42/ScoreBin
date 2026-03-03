import Foundation
import SwiftData

@Model
final class Team {
    var id: UUID
    var name: String
    var gym: Gym?
    var level: String  // L1-L7
    var ageDivision: String  // youth, junior, senior
    var tier: String  // elite, etc.
    var athleteCount: Int
    var createdAt: Date
    var syncStatus: SyncStatus

    @Relationship(deleteRule: .cascade, inverse: \Scoresheet.team)
    var scoresheets: [Scoresheet]

    init(
        id: UUID = UUID(),
        name: String,
        gym: Gym? = nil,
        level: String = "L2",
        ageDivision: String = "senior",
        tier: String = "elite",
        athleteCount: Int = 20,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.gym = gym
        self.level = level
        self.ageDivision = ageDivision
        self.tier = tier
        self.athleteCount = athleteCount
        self.createdAt = createdAt
        self.syncStatus = .pending
        self.scoresheets = []
    }

    // Available levels
    static let levels = ["L1", "L2", "L3", "L4", "L4.2", "L5", "L6", "L7"]

    // Available age divisions
    static let ageDivisions = ["youth", "junior", "senior", "open"]

    // Available tiers
    static let tiers = ["elite", "premier", "recreation"]

    // MARK: - Update from Database

    private static let iso8601Formatter = ISO8601DateFormatter()

    func update(from data: [String: Any]) {
        if let name = data["name"] as? String { self.name = name }
        if let level = data["level"] as? String { self.level = level }
        if let ageDivision = data["age_division"] as? String { self.ageDivision = ageDivision }
        if let tier = data["tier"] as? String { self.tier = tier }
        if let athleteCount = data["athlete_count"] as? Int { self.athleteCount = athleteCount }

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
            "gym_id": gym?.id.uuidString ?? NSNull(),
            "level": level,
            "age_division": ageDivision,
            "tier": tier,
            "athlete_count": athleteCount,
            "created_at": Self.iso8601Formatter.string(from: createdAt)
        ]
    }
}
