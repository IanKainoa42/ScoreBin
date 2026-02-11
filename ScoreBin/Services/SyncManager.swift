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
        Task {
            await updatePendingCount()
        }
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
            Task { @MainActor in
                await self.updatePendingCount()
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

            await updatePendingCount()
        } catch {
            print("Sync failed: \(error)")
        }
    }

    @MainActor
    func syncPendingChanges() async {
        guard let container = modelContainer else { return }
        await syncAll(context: container.mainContext)
    }

    @MainActor
    func updatePendingCount() async {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        do {
            let pendingScoresheets = try context.fetchCount(FetchDescriptor<Scoresheet>(predicate: #Predicate { $0.syncStatus == ScoresheetSyncStatus.pending }))
            let pendingTeams = try context.fetchCount(FetchDescriptor<Team>(predicate: #Predicate { $0.syncStatus == SyncStatus.pending }))
            let pendingCompetitions = try context.fetchCount(FetchDescriptor<Competition>(predicate: #Predicate { $0.syncStatus == SyncStatus.pending }))
            let pendingGyms = try context.fetchCount(FetchDescriptor<Gym>(predicate: #Predicate { $0.syncStatus == SyncStatus.pending }))

            self.pendingChanges = pendingScoresheets + pendingTeams + pendingCompetitions + pendingGyms
        } catch {
            print("Failed to update pending count: \(error)")
        }
    }

    // MARK: - Sync Batch Helper

    @MainActor
    private func syncBulk<T: PersistentModel>(
        items: [T],
        dataProvider: (T) -> [String: Any],
        bulkUploadAction: @escaping ([[String: Any]]) async throws -> Void,
        updateStatus: (T) -> Void
    ) async {
        guard !items.isEmpty else { return }

        let batchData = items.map { dataProvider($0) }

        do {
            try await bulkUploadAction(batchData)
            items.forEach { updateStatus($0) }
        } catch {
            print("Bulk sync failed: \(error)")
        }
    }

    // MARK: - Individual Sync Methods

    @MainActor
    private func syncGyms(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Gym>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingGyms = try context.fetch(descriptor)

        await syncBulk(
            items: pendingGyms,
            dataProvider: { $0.exportForDatabase() },
            bulkUploadAction: { [supabase] data in try await supabase.uploadGyms(data) },
            updateStatus: { $0.syncStatus = .synced }
        )

        try context.save()
    }

    @MainActor
    private func syncTeams(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Team>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingTeams = try context.fetch(descriptor)

        await syncBulk(
            items: pendingTeams,
            dataProvider: { $0.exportForDatabase() },
            bulkUploadAction: { [supabase] data in try await supabase.uploadTeams(data) },
            updateStatus: { $0.syncStatus = .synced }
        )

        try context.save()
    }

    @MainActor
    private func syncCompetitions(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Competition>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingCompetitions = try context.fetch(descriptor)

        await syncBulk(
            items: pendingCompetitions,
            dataProvider: { $0.exportForDatabase() },
            bulkUploadAction: { [supabase] data in try await supabase.uploadCompetitions(data) },
            updateStatus: { $0.syncStatus = .synced }
        )

        try context.save()
    }

    @MainActor
    private func syncScoresheets(context: ModelContext) async throws {
        let pending = ScoresheetSyncStatus.pending
        let descriptor = FetchDescriptor<Scoresheet>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingScoresheets = try context.fetch(descriptor)

        await syncBulk(
            items: pendingScoresheets,
            dataProvider: { $0.exportForDatabase() },
            bulkUploadAction: { [supabase] data in try await supabase.uploadScoresheets(data) },
            updateStatus: { $0.syncStatus = .synced }
        )

        try context.save()
    }

    // MARK: - Pull from Remote

    @MainActor
    func pullRemoteChanges(context: ModelContext) async {
        guard isOnline else { return }

        do {
            // Pull gyms
            let remoteGyms = try await supabase.fetchGyms()
            for gymData in remoteGyms {
                // Here we would match local gyms by ID or Supabase ID and update/insert.
                // Since SupabaseService is mocked to return empty, we just iterate.
                // Implementation hint:
                // if let idStr = gymData["id"] as? String, let id = UUID(uuidString: idStr) {
                //     let descriptor = FetchDescriptor<Gym>(predicate: #Predicate { $0.id == id })
                //     if let localGym = try? context.fetch(descriptor).first {
                //         // Update localGym from gymData
                //     } else {
                //         // Insert new Gym
                //     }
                // }
                _ = gymData // Suppress unused warning
            }

            // Pull teams
            let remoteTeams = try await supabase.fetchTeams()
             for teamData in remoteTeams {
                 _ = teamData
             }

            // Pull competitions
            let remoteCompetitions = try await supabase.fetchCompetitions()
            for compData in remoteCompetitions {
                _ = compData
            }

            // Pull scoresheets
            let remoteScoresheets = try await supabase.fetchScoresheets()
            for sheetData in remoteScoresheets {
                _ = sheetData
            }

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
        Task {
            await updatePendingCount()
        }
    }

    @MainActor
    func updatePendingCount() {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let gymPending = SyncStatus.pending
        let scorePending = ScoresheetSyncStatus.pending

        let gymDescriptor = FetchDescriptor<Gym>(predicate: #Predicate { $0.syncStatus == gymPending })
        let teamDescriptor = FetchDescriptor<Team>(predicate: #Predicate { $0.syncStatus == gymPending })
        let compDescriptor = FetchDescriptor<Competition>(predicate: #Predicate { $0.syncStatus == gymPending })
        let scoreDescriptor = FetchDescriptor<Scoresheet>(predicate: #Predicate { $0.syncStatus == scorePending })

        do {
            let gymCount = try context.fetchCount(gymDescriptor)
            let teamCount = try context.fetchCount(teamDescriptor)
            let compCount = try context.fetchCount(compDescriptor)
            let scoreCount = try context.fetchCount(scoreDescriptor)

            self.pendingChanges = gymCount + teamCount + compCount + scoreCount
        } catch {
            print("Failed to update pending count: \(error)")
        }
    }
}
