import Foundation

public enum SyncStatus: String, Codable {
    case pending
    case synced
    case failed
}
