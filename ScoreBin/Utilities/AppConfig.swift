import Foundation

/// Configuration constants for the application
struct AppConfig {
    struct Supabase {
        // TODO: Replace with your actual Supabase project URL and Anon Key
        // For security, these should ideally be loaded from a secure source or environment variables in a real app.
        static let url = "YOUR_SUPABASE_URL"
        static let key = "YOUR_SUPABASE_ANON_KEY"
    }
}
