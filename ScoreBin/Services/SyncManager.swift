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
        Task {
            updatePendingCount()
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied

                // Auto-sync when coming online
                if path.status == .satisfied {
                    await self?.syncPendingChanges()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Pending Count

    @MainActor
    func updatePendingCount(context: ModelContext? = nil) {
        guard let context = context ?? modelContainer?.mainContext else { return }
        updatePendingCount(context: context)
    }

    @MainActor
    private func updatePendingCount(context: ModelContext) {
        do {
            let pending = SyncStatus.pending
            let sheetPending = ScoresheetSyncStatus.pending

            let pendingGyms = try context.fetchCount(
                FetchDescriptor<Gym>(predicate: #Predicate { $0.syncStatus == pending }))
            let pendingTeams = try context.fetchCount(
                FetchDescriptor<Team>(predicate: #Predicate { $0.syncStatus == pending }))
            let pendingComps = try context.fetchCount(
                FetchDescriptor<Competition>(
                    predicate: #Predicate {
                        $0.syncStatus == pending
                    }))
            let pendingSheets = try context.fetchCount(
                FetchDescriptor<Scoresheet>(
                    predicate: #Predicate {
                        $0.syncStatus == sheetPending
                    }))

            self.pendingChanges = pendingGyms + pendingTeams + pendingComps + pendingSheets
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
            updatePendingCount(context: context)
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
    private func syncBulk<T: PersistentModel>(
        items: [T],
        dataProvider: (T) -> [String: Any],
        bulkUploadAction: @escaping ([[String: Any]]) async throws -> Void,
        updateStatus: (T) -> Void
    ) async throws {
        guard !items.isEmpty else { return }

        let batchData = items.map { dataProvider($0) }

        try await bulkUploadAction(batchData)
        items.forEach { updateStatus($0) }
    }

    // MARK: - Individual Sync Methods

    @MainActor
    private func syncGyms(context: ModelContext) async throws {
        let pending = SyncStatus.pending
        let descriptor = FetchDescriptor<Gym>(
            predicate: #Predicate { $0.syncStatus == pending })
        let pendingGyms = try context.fetch(descriptor)
        guard !pendingGyms.isEmpty else { return }

        try await syncBulk(
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
        guard !pendingTeams.isEmpty else { return }

        try await syncBulk(
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
        guard !pendingCompetitions.isEmpty else { return }

        try await syncBulk(
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
        guard !pendingScoresheets.isEmpty else { return }

        try await syncBulk(
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
            try await mergeGyms(remoteGyms, context: context)

            // Pull teams
            let remoteTeams = try await supabase.fetchTeams()
            try await mergeTeams(remoteTeams, context: context)

            // Pull competitions
            let remoteCompetitions = try await supabase.fetchCompetitions()
            try await mergeCompetitions(remoteCompetitions, context: context)

            // Pull scoresheets
            let remoteScoresheets = try await supabase.fetchScoresheets()
            try await mergeScoresheets(remoteScoresheets, context: context)

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
        Task {
            updatePendingCount()
        }
    }

    // MARK: - Merge Helpers

    private func parseRemoteData(_ remoteData: [[String: Any]]) -> [(UUID, [String: Any])] {
        return remoteData.compactMap { data in
            guard let idString = data["id"] as? String,
                let id = UUID(uuidString: idString)
            else { return nil }
            return (id, data)
        }
    }

    @MainActor
    private func mergeGyms(_ remoteData: [[String: Any]], context: ModelContext) async throws {
        let parsedData = parseRemoteData(remoteData)
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Gym>(predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        for (id, data) in parsedData {
            if let existing = existingMap[id] {
                existing.update(from: data)
            } else {
                if let name = data["name"] as? String {
                    let gym = Gym(id: id, name: name)
                    gym.update(from: data)
                    context.insert(gym)
                }
            }
        }
    }

    @MainActor
    private func mergeTeams(_ remoteData: [[String: Any]], context: ModelContext) async throws {
        let parsedData = parseRemoteData(remoteData)
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Team>(predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        for (id, data) in parsedData {
            if let existing = existingMap[id] {
                existing.update(from: data)
            } else {
                if let name = data["name"] as? String {
                    let team = Team(id: id, name: name)
                    team.update(from: data)
                    context.insert(team)
                }
            }
        }
    }

    @MainActor
    private func mergeCompetitions(_ remoteData: [[String: Any]], context: ModelContext)
        async throws
    {
        let parsedData = parseRemoteData(remoteData)
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Competition>(
            predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        for (id, data) in parsedData {
            if let existing = existingMap[id] {
                existing.update(from: data)
            } else {
                if let name = data["name"] as? String {
                    let competition = Competition(id: id, name: name)
                    competition.syncStatus = .synced
                    competition.update(from: data)
                    context.insert(competition)
                }
            }
        }
    }

    @MainActor
    private func mergeScoresheets(_ remoteData: [[String: Any]], context: ModelContext) async throws
    {
        let parsedData = parseRemoteData(remoteData)
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Scoresheet>(
            predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        // Collect referenced Team and Competition IDs declaratively
        let teamIDs = Set(parsedData.compactMap { _, data -> UUID? in
            guard let teamIDStr = data["team_id"] as? String else { return nil }
            return UUID(uuidString: teamIDStr)
        })

        let compIDs = Set(parsedData.compactMap { _, data -> UUID? in
            guard let compIDStr = data["competition_id"] as? String else { return nil }
            return UUID(uuidString: compIDStr)
        })

        // Fetch Teams
        let teamsMap: [UUID: Team]
        if !teamIDs.isEmpty {
            let tidArray = Array(teamIDs)
            let teamDesc = FetchDescriptor<Team>(predicate: #Predicate { tidArray.contains($0.id) })
            let teams = try context.fetch(teamDesc)
            teamsMap = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0) })
        } else {
            teamsMap = [:]
        }

        // Fetch Competitions
        let compsMap: [UUID: Competition]
        if !compIDs.isEmpty {
            let cidArray = Array(compIDs)
            let compDesc = FetchDescriptor<Competition>(
                predicate: #Predicate { cidArray.contains($0.id) })
            let comps = try context.fetch(compDesc)
            compsMap = Dictionary(uniqueKeysWithValues: comps.map { ($0.id, $0) })
        } else {
            compsMap = [:]
        }

        for (id, data) in parsedData {
            let scoresheet: Scoresheet
            if let existing = existingMap[id] {
                scoresheet = existing
            } else {
                scoresheet = Scoresheet(id: id)
                context.insert(scoresheet)
            }

            // Server wins, so mark as synced
            scoresheet.syncStatus = .synced
            scoresheet.update(from: data)

            // Link relationships
            if let teamIDStr = data["team_id"] as? String,
                let tid = UUID(uuidString: teamIDStr),
                let team = teamsMap[tid]
            {
                scoresheet.team = team
            }

            if let compIDStr = data["competition_id"] as? String,
                let cid = UUID(uuidString: compIDStr),
                let comp = compsMap[cid]
            {
                scoresheet.competition = comp
            }
        }
    }
}
