import Foundation

/// Represents the cloud synchronization state of a local entity.
public enum SyncStatus: String, Codable {
    /// Awaiting sync to the remote server.
    case pending
    /// Successfully synchronized with the remote server.
    case synced
    /// Synchronization failed; eligible for retry.
    case failed
}
