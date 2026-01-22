import Foundation

/// Supabase configuration and service for cloud sync
/// Note: Requires Supabase Swift SDK to be added via SPM
/// Add package: https://github.com/supabase/supabase-swift
class SupabaseService {
    static let shared = SupabaseService()

    private let supabaseURL = AppConfig.Supabase.url
    private let supabaseKey = AppConfig.Supabase.key

    private static let iso8601Formatter = ISO8601DateFormatter()

    private init() {
        // Initialize Supabase client here when SDK is added
        // client = SupabaseClient(supabaseURL: URL(string: supabaseURL)!, supabaseKey: supabaseKey)
    }

    // MARK: - Scoresheet Operations

    func uploadScoresheet(_ scoresheet: Scoresheet) async throws {
        let data = scoresheet.exportForDatabase()

        // When Supabase SDK is integrated:
        // try await client.from("scoresheets").insert(data).execute()

        print("Would upload scoresheet: \(data)")
    }

    func fetchScoresheets() async throws -> [[String: Any]] {
        // When Supabase SDK is integrated:
        // let response = try await client.from("scoresheets").select().execute()
        // return response.value

        return []
    }

    // MARK: - Team Operations

    func uploadTeam(_ team: Team) async throws {
        let data: [String: Any] = [
            "id": team.id.uuidString,
            "name": team.name,
            "gym_id": team.gym?.id.uuidString ?? NSNull(),
            "level": team.level,
            "age_division": team.ageDivision,
            "tier": team.tier,
            "athlete_count": team.athleteCount,
            "created_at": Self.iso8601Formatter.string(from: team.createdAt),
        ]

        // When Supabase SDK is integrated:
        // try await client.from("teams").insert(data).execute()

        print("Would upload team: \(data)")
    }

    func fetchTeams() async throws -> [[String: Any]] {
        // When Supabase SDK is integrated:
        // let response = try await client.from("teams").select().execute()
        // return response.value

        return []
    }

    // MARK: - Competition Operations

    func uploadCompetition(_ competition: Competition) async throws {
        let data: [String: Any] = [
            "id": competition.id.uuidString,
            "name": competition.name,
            "date": Self.iso8601Formatter.string(from: competition.date),
            "location": competition.location,
            "notes": competition.notes,
            "created_at": Self.iso8601Formatter.string(from: competition.createdAt),
        ]

        // When Supabase SDK is integrated:
        // try await client.from("competitions").insert(data).execute()

        print("Would upload competition: \(data)")
    }

    func fetchCompetitions() async throws -> [[String: Any]] {
        // When Supabase SDK is integrated:
        // let response = try await client.from("competitions").select().execute()
        // return response.value

        return []
    }

    // MARK: - Gym Operations

    func uploadGym(_ gym: Gym) async throws {
        let data: [String: Any] = [
            "id": gym.id.uuidString,
            "name": gym.name,
            "location": gym.location,
            "created_at": Self.iso8601Formatter.string(from: gym.createdAt),
        ]

        // When Supabase SDK is integrated:
        // try await client.from("gyms").insert(data).execute()

        print("Would upload gym: \(data)")
    }

    func fetchGyms() async throws -> [[String: Any]] {
        // When Supabase SDK is integrated:
        // let response = try await client.from("gyms").select().execute()
        // return response.value

        return []
    }
}

// MARK: - Supabase Table Schemas (for reference)

/*
 CREATE TABLE gyms (
     id UUID PRIMARY KEY,
     name TEXT NOT NULL,
     location TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );

 CREATE TABLE teams (
     id UUID PRIMARY KEY,
     name TEXT NOT NULL,
     gym_id UUID REFERENCES gyms(id),
     level TEXT NOT NULL,
     age_division TEXT NOT NULL,
     tier TEXT NOT NULL,
     athlete_count INTEGER NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );

 CREATE TABLE competitions (
     id UUID PRIMARY KEY,
     name TEXT NOT NULL,
     date DATE NOT NULL,
     location TEXT,
     notes TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );

 CREATE TABLE scoresheets (
     id UUID PRIMARY KEY,
     team_id UUID REFERENCES teams(id),
     competition_id UUID REFERENCES competitions(id),
     round TEXT NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

     -- Building scores
     stunt_difficulty DECIMAL(3,2),
     stunt_execution DECIMAL(3,2),
     stunt_driver_degree DECIMAL(3,2),
     stunt_driver_max_part DECIMAL(3,2),
     pyramid_difficulty DECIMAL(3,2),
     pyramid_execution DECIMAL(3,2),
     pyramid_drivers DECIMAL(3,2),
     toss_difficulty DECIMAL(3,2),
     toss_execution DECIMAL(3,2),
     building_creativity DECIMAL(3,2),
     building_showmanship DECIMAL(3,2),

     -- Tumbling scores
     standing_difficulty DECIMAL(3,2),
     standing_execution DECIMAL(3,2),
     standing_drivers DECIMAL(3,2),
     running_difficulty DECIMAL(3,2),
     running_execution DECIMAL(3,2),
     running_drivers DECIMAL(3,2),
     jumps_difficulty DECIMAL(3,2),
     jumps_execution DECIMAL(3,2),
     tumbling_creativity DECIMAL(3,2),
     tumbling_showmanship DECIMAL(3,2),

     -- Overall scores
     dance_difficulty DECIMAL(3,2),
     dance_execution DECIMAL(3,2),
     formations DECIMAL(3,2),
     overall_creativity DECIMAL(3,2),
     overall_showmanship DECIMAL(3,2),

     -- Deductions
     athlete_falls INTEGER DEFAULT 0,
     major_athlete_falls INTEGER DEFAULT 0,
     building_bobbles INTEGER DEFAULT 0,
     building_falls INTEGER DEFAULT 0,
     major_building_falls INTEGER DEFAULT 0,
     boundary_violations INTEGER DEFAULT 0,
     time_limit_violations INTEGER DEFAULT 0,

     -- Computed scores (for querying)
     raw_score DECIMAL(4,2),
     total_deductions DECIMAL(4,2),
     final_score DECIMAL(4,2),

     -- Sync
     sync_status TEXT DEFAULT 'synced'
 );

 CREATE INDEX idx_scoresheets_team ON scoresheets(team_id);
 CREATE INDEX idx_scoresheets_competition ON scoresheets(competition_id);
 CREATE INDEX idx_teams_gym ON teams(gym_id);
 */
