import Foundation

/// Configuration constants for the application
public struct AppConfig {
    struct Supabase {
        static var url: String {
            if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty {
                return url
            }
            // Fallback for development or if keys are missing
            return "YOUR_SUPABASE_URL"
        }

        static var key: String {
            if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
                return key
            }
            // Fallback for development or if keys are missing
            return "YOUR_SUPABASE_ANON_KEY"
        }
    }
}
