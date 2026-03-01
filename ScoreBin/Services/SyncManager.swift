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
    private let iso8601Formatter = ISO8601DateFormatter()

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

    @MainActor
    private func mergeGyms(_ remoteData: [[String: Any]], context: ModelContext) async throws {
        let parsedData: [(UUID, [String: Any])] = remoteData.compactMap { data in
            guard let idString = data["id"] as? String,
                let id = UUID(uuidString: idString)
            else { return nil }
            return (id, data)
        }
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Gym>(predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        for (id, data) in parsedData {
            if let existing = existingMap[id] {
                if let name = data["name"] as? String { existing.name = name }
                if let location = data["location"] as? String { existing.location = location }
            } else {
                if let name = data["name"] as? String {
                    let gym = Gym(id: id, name: name)
                    if let location = data["location"] as? String { gym.location = location }
                    context.insert(gym)
                }
            }
        }
    }

    @MainActor
    private func mergeTeams(_ remoteData: [[String: Any]], context: ModelContext) async throws {
        let parsedData: [(UUID, [String: Any])] = remoteData.compactMap { data in
            guard let idString = data["id"] as? String,
                let id = UUID(uuidString: idString)
            else { return nil }
            return (id, data)
        }
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Team>(predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        for (id, data) in parsedData {
            if let existing = existingMap[id] {
                if let name = data["name"] as? String { existing.name = name }
                if let level = data["level"] as? String { existing.level = level }
                if let count = data["athlete_count"] as? Int { existing.athleteCount = count }
            } else {
                if let name = data["name"] as? String {
                    let team = Team(id: id, name: name)
                    if let level = data["level"] as? String { team.level = level }
                    if let count = data["athlete_count"] as? Int { team.athleteCount = count }
                    context.insert(team)
                }
            }
        }
    }

    @MainActor
    private func mergeCompetitions(_ remoteData: [[String: Any]], context: ModelContext)
        async throws
    {
        let parsedData: [(UUID, [String: Any])] = remoteData.compactMap { data in
            guard let idString = data["id"] as? String,
                let id = UUID(uuidString: idString)
            else { return nil }
            return (id, data)
        }
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Competition>(
            predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        for (id, data) in parsedData {
            let dateString = data["date"] as? String
            let parsedDate = dateString.flatMap { iso8601Formatter.date(from: $0) }
            let date = parsedDate ?? Date()
            let location = data["location"] as? String ?? ""
            let notes = data["notes"] as? String ?? ""

            if let existing = existingMap[id] {
                if let name = data["name"] as? String { existing.name = name }
                if let d = parsedDate { existing.date = d }
                if let loc = data["location"] as? String { existing.location = loc }
                if let n = data["notes"] as? String { existing.notes = n }
            } else {
                if let name = data["name"] as? String {
                    let competition = Competition(
                        id: id, name: name, date: date, location: location, notes: notes)
                    competition.syncStatus = .synced
                    context.insert(competition)
                }
            }
        }
    }

    @MainActor
    private func mergeScoresheets(_ remoteData: [[String: Any]], context: ModelContext) async throws
    {
        let parsedData: [(UUID, [String: Any])] = remoteData.compactMap { data in
            guard let idString = data["id"] as? String,
                let id = UUID(uuidString: idString)
            else { return nil }
            return (id, data)
        }
        guard !parsedData.isEmpty else { return }

        let remoteIDs = parsedData.map { $0.0 }
        let descriptor = FetchDescriptor<Scoresheet>(
            predicate: #Predicate { remoteIDs.contains($0.id) })
        let existingRecords = try context.fetch(descriptor)
        let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

        // Collect referenced Team and Competition IDs
        var teamIDs = Set<UUID>()
        var compIDs = Set<UUID>()

        for (_, data) in parsedData {
            if let teamIDStr = data["team_id"] as? String, let tid = UUID(uuidString: teamIDStr) {
                teamIDs.insert(tid)
            }
            if let compIDStr = data["competition_id"] as? String,
                let cid = UUID(uuidString: compIDStr)
            {
                compIDs.insert(cid)
            }
        }

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
            update(scoresheet, with: data)

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

    @MainActor
    private func update(_ scoresheet: Scoresheet, with data: [String: Any]) {
        if let round = data["round"] as? String { scoresheet.round = round }
        if let createdAtString = data["created_at"] as? String,
            let date = iso8601Formatter.date(from: createdAtString)
        {
            scoresheet.createdAt = date
        }

        // Building
        if let val = data["stunt_difficulty"] as? Double { scoresheet.stuntDifficulty = val }
        if let val = data["stunt_execution"] as? Double { scoresheet.stuntExecution = val }
        if let val = data["stunt_driver_degree"] as? Double { scoresheet.stuntDriverDegree = val }
        if let val = data["stunt_driver_max_part"] as? Double { scoresheet.stuntDriverMaxPart = val }
        if let val = data["pyramid_difficulty"] as? Double { scoresheet.pyramidDifficulty = val }
        if let val = data["pyramid_execution"] as? Double { scoresheet.pyramidExecution = val }
        if let val = data["pyramid_drivers"] as? Double { scoresheet.pyramidDrivers = val }
        if let val = data["toss_difficulty"] as? Double { scoresheet.tossDifficulty = val }
        if let val = data["toss_execution"] as? Double { scoresheet.tossExecution = val }
        if let val = data["building_creativity"] as? Double { scoresheet.buildingCreativity = val }
        if let val = data["building_showmanship"] as? Double {
            scoresheet.buildingShowmanship = val
        }

        // Tumbling
        if let val = data["standing_difficulty"] as? Double { scoresheet.standingDifficulty = val }
        if let val = data["standing_execution"] as? Double { scoresheet.standingExecution = val }
        if let val = data["standing_drivers"] as? Double { scoresheet.standingDrivers = val }
        if let val = data["running_difficulty"] as? Double { scoresheet.runningDifficulty = val }
        if let val = data["running_execution"] as? Double { scoresheet.runningExecution = val }
        if let val = data["running_drivers"] as? Double { scoresheet.runningDrivers = val }
        if let val = data["running_driver_max_part"] as? Double {
            scoresheet.runningDriverMaxPart = val
        }
        if let val = data["jumps_difficulty"] as? Double { scoresheet.jumpsDifficulty = val }
        if let val = data["jumps_execution"] as? Double { scoresheet.jumpsExecution = val }
        if let val = data["tumbling_creativity"] as? Double { scoresheet.tumblingCreativity = val }
        if let val = data["tumbling_showmanship"] as? Double {
            scoresheet.tumblingShowmanship = val
        }

        // Overall
        if let val = data["dance_difficulty"] as? Double { scoresheet.danceDifficulty = val }
        if let val = data["dance_execution"] as? Double { scoresheet.danceExecution = val }
        if let val = data["formations"] as? Double { scoresheet.formations = val }
        if let val = data["overall_creativity"] as? Double { scoresheet.overallCreativity = val }
        if let val = data["overall_showmanship"] as? Double { scoresheet.overallShowmanship = val }

        // Deductions
        if let val = data["athlete_falls"] as? Int { scoresheet.athleteFalls = val }
        if let val = data["major_athlete_falls"] as? Int { scoresheet.majorAthleteFalls = val }
        if let val = data["building_bobbles"] as? Int { scoresheet.buildingBobbles = val }
        if let val = data["building_falls"] as? Int { scoresheet.buildingFalls = val }
        if let val = data["major_building_falls"] as? Int { scoresheet.majorBuildingFalls = val }
        if let val = data["boundary_violations"] as? Int { scoresheet.boundaryViolations = val }
        if let val = data["time_limit_violations"] as? Int { scoresheet.timeLimitViolations = val }
    }
}
