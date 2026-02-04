import Foundation
import Network
import SwiftData

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

    private var modelContainer: ModelContainer?

    private init() {
        setupNetworkMonitoring()
    }

    func configure(container: ModelContainer) {
        self.modelContainer = container
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

    @MainActor
    func syncAll(context: ModelContext) async {
        guard isOnline && !isSyncing else { return }

        isSyncing = true

        defer {
            isSyncing = false
            lastSyncDate = Date()
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

    @MainActor
    func syncPendingChanges() async {
        guard let container = modelContainer else { return }
        await syncAll(context: container.mainContext)
    }

    // MARK: - Helper

    private func performUploads(
        data: [(UUID, [String: Any])],
        type: String,
        uploadAction: @escaping ([String: Any]) async throws -> Void
    ) async -> Set<UUID> {
        let successIDs = await withTaskGroup(of: UUID?.self) { group in
            for (id, itemData) in data {
                group.addTask {
                    do {
                        try await uploadAction(itemData)
                        return id
                    } catch {
                        print("Failed to upload \(type) \(id): \(error)")
                        return nil
                    }
                }
            }

            var results: [UUID] = []
            for await result in group {
                if let id = result { results.append(id) }
            }
            return results
        }
        return Set(successIDs)
    }

    // MARK: - Individual Sync Methods

    @MainActor
    private func syncGyms(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Gym>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingGyms = try context.fetch(descriptor)

        guard !pendingGyms.isEmpty else { return }

        let uploadData = pendingGyms.map { ($0.id, $0.exportForDatabase()) }
        let supabase = self.supabase

        let successSet = await performUploads(data: uploadData, type: "gym") { data in
            try await supabase.uploadGym(data)
        }

        for gym in pendingGyms {
            if successSet.contains(gym.id) {
                gym.syncStatus = .synced
            }
        }

        if !successSet.isEmpty {
            try context.save()
        }
    }

    @MainActor
    private func syncTeams(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Team>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingTeams = try context.fetch(descriptor)

        guard !pendingTeams.isEmpty else { return }

        let uploadData = pendingTeams.map { ($0.id, $0.exportForDatabase()) }
        let supabase = self.supabase

        let successSet = await performUploads(data: uploadData, type: "team") { data in
            try await supabase.uploadTeam(data)
        }

        for team in pendingTeams {
            if successSet.contains(team.id) {
                team.syncStatus = .synced
            }
        }

        if !successSet.isEmpty {
            try context.save()
        }
    }

    @MainActor
    private func syncCompetitions(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Competition>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingCompetitions = try context.fetch(descriptor)

        guard !pendingCompetitions.isEmpty else { return }

        let uploadData = pendingCompetitions.map { ($0.id, $0.exportForDatabase()) }
        let supabase = self.supabase

        let successSet = await performUploads(data: uploadData, type: "competition") { data in
            try await supabase.uploadCompetition(data)
        }

        for competition in pendingCompetitions {
            if successSet.contains(competition.id) {
                competition.syncStatus = .synced
            }
        }

        if !successSet.isEmpty {
            try context.save()
        }
    }

    @MainActor
    private func syncScoresheets(context: ModelContext) async throws {
        let pending = ScoresheetSyncStatus.pending
        let descriptor = FetchDescriptor<Scoresheet>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingScoresheets = try context.fetch(descriptor)

        guard !pendingScoresheets.isEmpty else { return }

        let uploadData = pendingScoresheets.map { ($0.id, $0.exportForDatabase()) }
        let supabase = self.supabase

        let successSet = await performUploads(data: uploadData, type: "scoresheet") { data in
            try await supabase.uploadScoresheet(data)
        }

        for scoresheet in pendingScoresheets {
            if successSet.contains(scoresheet.id) {
                scoresheet.syncStatus = .synced
            }
        }

        if !successSet.isEmpty {
            try context.save()
        }
    }

    // MARK: - Pull from Remote

    @MainActor
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

            print(
                "Pulled \(remoteGyms.count) gyms, \(remoteTeams.count) teams, \(remoteCompetitions.count) competitions, \(remoteScoresheets.count) scoresheets"
            )
        } catch {
            print("Failed to pull remote changes: \(error)")
        }
    }

    // MARK: - Conflict Resolution

    /// Last-write-wins conflict resolution based on timestamp
    private func resolveConflict<T>(
        local: T, remote: T, localTimestamp: Date, remoteTimestamp: Date
    ) -> T {
        return remoteTimestamp > localTimestamp ? remote : local
    }

    // MARK: - Mark for Sync

    func markForSync(_ scoresheet: Scoresheet) {
        scoresheet.syncStatus = .pending
        pendingChanges += 1
    }
}
