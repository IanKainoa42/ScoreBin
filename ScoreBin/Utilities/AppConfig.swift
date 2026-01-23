import Foundation

/// Configuration constants for the application
public struct AppConfig {
    struct Supabase {
        // For security, these should ideally be loaded from a secure source or environment variables in a real app.
        // We attempt to load from Info.plist first, then fall back to placeholders.
        static var url: String {
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "YOUR_SUPABASE_URL"
        }

        static var key: String {
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "YOUR_SUPABASE_ANON_KEY"
        }
    }
}
