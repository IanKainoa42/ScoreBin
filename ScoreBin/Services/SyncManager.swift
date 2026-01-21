import Foundation
import SwiftData
import Network

/// Manages offline-first sync between local SwiftData and Supabase
@Observable
class SyncManager {
    static let shared = SyncManager()

    private let supabase = SupabaseService.shared
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    var isOnline: Bool = true
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var pendingChanges: Int = 0

    private init() {
        setupNetworkMonitoring()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied

                // Auto-sync when coming online
                if path.status == .satisfied {
                    Task {
                        await self?.syncPendingChanges()
                    }
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Sync Operations

    func syncAll(context: ModelContext) async {
        guard isOnline && !isSyncing else { return }

        await MainActor.run {
            isSyncing = true
        }

        defer {
            Task { @MainActor in
                isSyncing = false
                lastSyncDate = Date()
            }
        }

        do {
            // Sync gyms
            try await syncGyms(context: context)

            // Sync teams
            try await syncTeams(context: context)

            // Sync competitions
            try await syncCompetitions(context: context)

            // Sync scoresheets
            try await syncScoresheets(context: context)

            await MainActor.run {
                pendingChanges = 0
            }
        } catch {
            print("Sync failed: \(error)")
        }
    }

    func syncPendingChanges() async {
        // Sync any items marked as pending
        // This would be called when coming back online
    }

    // MARK: - Individual Sync Methods

    private func syncGyms(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<Gym>()
        let gyms = try context.fetch(descriptor)

        for gym in gyms {
            try await supabase.uploadGym(gym)
        }
    }

    private func syncTeams(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<Team>()
        let teams = try context.fetch(descriptor)

        for team in teams {
            try await supabase.uploadTeam(team)
        }
    }

    private func syncCompetitions(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<Competition>()
        let competitions = try context.fetch(descriptor)

        for competition in competitions {
            try await supabase.uploadCompetition(competition)
        }
    }

    private func syncScoresheets(context: ModelContext) async throws {
        // Fetch all scoresheets and filter for pending
        let descriptor = FetchDescriptor<Scoresheet>()
        let allScoresheets = try context.fetch(descriptor)
        let pendingScoresheets = allScoresheets.filter { $0.syncStatus == SyncStatus.pending }

        for scoresheet in pendingScoresheets {
            try await supabase.uploadScoresheet(scoresheet)
            scoresheet.syncStatus = SyncStatus.synced
        }

        try context.save()
    }

    // MARK: - Pull from Remote

    func pullRemoteChanges(context: ModelContext) async {
        guard isOnline else { return }

        do {
            // Pull gyms
            let remoteGyms = try await supabase.fetchGyms()
            // Process and merge with local data...

            // Pull teams
            let remoteTeams = try await supabase.fetchTeams()
            // Process and merge with local data...

            // Pull competitions
            let remoteCompetitions = try await supabase.fetchCompetitions()
            // Process and merge with local data...

            // Pull scoresheets
            let remoteScoresheets = try await supabase.fetchScoresheets()
            // Process and merge with local data...

            print("Pulled \(remoteGyms.count) gyms, \(remoteTeams.count) teams, \(remoteCompetitions.count) competitions, \(remoteScoresheets.count) scoresheets")
        } catch {
            print("Failed to pull remote changes: \(error)")
        }
    }

    // MARK: - Conflict Resolution

    /// Last-write-wins conflict resolution based on timestamp
    private func resolveConflict<T>(local: T, remote: T, localTimestamp: Date, remoteTimestamp: Date) -> T {
        return remoteTimestamp > localTimestamp ? remote : local
    }

    // MARK: - Mark for Sync

    func markForSync(_ scoresheet: Scoresheet) {
        scoresheet.syncStatus = SyncStatus.pending
        pendingChanges += 1
    }
}
