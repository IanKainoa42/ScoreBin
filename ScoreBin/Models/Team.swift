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

    /// Human-readable level name (e.g., "L2" → "Level 2")
    static func humanizedLevel(_ level: String) -> String {
        switch level {
        case "L1": return "Level 1"
        case "L2": return "Level 2"
        case "L3": return "Level 3"
        case "L4": return "Level 4"
        case "L4.2": return "Level 4.2"
        case "L5": return "Level 5"
        case "L6": return "Level 6"
        case "L7": return "Level 7"
        default: return level
        }
    }

    /// Humanized level for this team
    var humanizedLevel: String {
        Team.humanizedLevel(level)
    }

    // Available age divisions
    static let ageDivisions = ["youth", "junior", "senior", "open"]

    // Available tiers
    static let tiers = ["elite", "premier", "recreation"]

    // MARK: - Update from Database

    func update(from data: [String: Any]) {
        if let name = data["name"] as? String { self.name = name }
        if let level = data["level"] as? String { self.level = level }
        if let ageDivision = data["age_division"] as? String { self.ageDivision = ageDivision }
        if let tier = data["tier"] as? String { self.tier = tier }
        if let athleteCount = data["athlete_count"] as? Int { self.athleteCount = athleteCount }

        if let createdAtString = data["created_at"] as? String,
            let date = ISO8601DateFormatter.shared.date(from: createdAtString)
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
            "created_at": ISO8601DateFormatter.shared.string(from: createdAt)
        ]
    }
}
