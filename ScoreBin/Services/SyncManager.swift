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
    private(set) var pendingChanges: Int = 0

    private var modelContainer: ModelContainer?

    private init() {
        setupNetworkMonitoring()
    }

    @MainActor
    func configure(container: ModelContainer) {
        self.modelContainer = container
        updatePendingCount()
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

    // MARK: - Pending Count

    @MainActor
    func updatePendingCount() {
        guard let context = modelContainer?.mainContext else { return }

        do {
            let pendingGyms = try context.fetchCount(FetchDescriptor<Gym>(predicate: #Predicate { $0.syncStatus == SyncStatus.pending }))
            let pendingTeams = try context.fetchCount(FetchDescriptor<Team>(predicate: #Predicate { $0.syncStatus == SyncStatus.pending }))
            let pendingCompetitions = try context.fetchCount(FetchDescriptor<Competition>(predicate: #Predicate { $0.syncStatus == SyncStatus.pending }))
            let pendingScoresheets = try context.fetchCount(FetchDescriptor<Scoresheet>(predicate: #Predicate { $0.syncStatus == ScoresheetSyncStatus.pending }))

            self.pendingChanges = pendingGyms + pendingTeams + pendingCompetitions + pendingScoresheets
        } catch {
            print("Failed to update pending count: \(error)")
        }
    }

    // MARK: - Sync Operations

    @MainActor
    func syncAll(context: ModelContext) async {
        guard isOnline && !isSyncing else { return }

        isSyncing = true

        defer {
            isSyncing = false
            lastSyncDate = Date()
            updatePendingCount()
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

            // pendingChanges is updated in defer block
        } catch {
            print("Sync failed: \(error)")
        }
    }

    @MainActor
    func syncPendingChanges() async {
        guard let container = modelContainer else { return }
        await syncAll(context: container.mainContext)
    }

    // MARK: - Sync Batch Helper

    @MainActor
    private func syncBatch<T: PersistentModel>(
        items: [T],
        idProvider: (T) -> UUID,
        dataProvider: (T) -> [String: Any],
        uploadAction: @escaping ([String: Any]) async throws -> Void,
        updateStatus: (T) -> Void
    ) async {
        guard !items.isEmpty else { return }

        // Extract data on MainActor
        let uploadData = items.map { (idProvider($0), dataProvider($0)) }
        let maxConcurrent = 5

        let successIDs = await withTaskGroup(of: UUID?.self) { group in
            var activeTasks = 0
            var results: [UUID] = []
            var dataIterator = uploadData.makeIterator()

            // Helper to collect results
            func collectResult() async {
                if let result = await group.next() {
                    if let id = result { results.append(id) }
                    activeTasks -= 1
                }
            }

            // Initial fill
            while activeTasks < maxConcurrent, let (id, data) = dataIterator.next() {
                group.addTask {
                    do {
                        try await uploadAction(data)
                        return id
                    } catch {
                        print("Failed to upload item \(id): \(error)")
                        return nil
                    }
                }
                activeTasks += 1
            }

            // Process remaining
            while let (id, data) = dataIterator.next() {
                await collectResult()

                group.addTask {
                    do {
                        try await uploadAction(data)
                        return id
                    } catch {
                        print("Failed to upload item \(id): \(error)")
                        return nil
                    }
                }
                activeTasks += 1
            }

            // Drain
            while activeTasks > 0 {
                await collectResult()
            }

            return results
        }

        let successSet = Set(successIDs)
        items.filter { successSet.contains(idProvider($0)) }
             .forEach { updateStatus($0) }
    }

    // MARK: - Individual Sync Methods

    @MainActor
    private func syncGyms(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Gym>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingGyms = try context.fetch(descriptor)

        await syncBatch(
            items: pendingGyms,
            idProvider: { $0.id },
            dataProvider: { $0.exportForDatabase() },
            uploadAction: { [supabase] data in try await supabase.uploadGym(data) },
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

        await syncBatch(
            items: pendingTeams,
            idProvider: { $0.id },
            dataProvider: { $0.exportForDatabase() },
            uploadAction: { [supabase] data in try await supabase.uploadTeam(data) },
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

        await syncBatch(
            items: pendingCompetitions,
            idProvider: { $0.id },
            dataProvider: { $0.exportForDatabase() },
            uploadAction: { [supabase] data in try await supabase.uploadCompetition(data) },
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

        await syncBatch(
            items: pendingScoresheets,
            idProvider: { $0.id },
            dataProvider: { $0.exportForDatabase() },
            uploadAction: { [supabase] data in try await supabase.uploadScoresheet(data) },
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

    @MainActor
    func markForSync(_ scoresheet: Scoresheet) {
        scoresheet.syncStatus = .pending
        // Ensure changes are detected
        updatePendingCount()
    }
}
