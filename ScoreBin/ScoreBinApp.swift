import SwiftUI
import SwiftData

@main
struct ScoreBinApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Scoresheet.self,
                Team.self,
                Competition.self,
                Gym.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .onAppear {
                    SyncManager.shared.configure(container: modelContainer)
                }
        }
        .modelContainer(modelContainer)
    }
}
