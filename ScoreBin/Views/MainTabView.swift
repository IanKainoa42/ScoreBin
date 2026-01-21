import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ScoresheetEntryView()
                .tabItem {
                    Label("Scoresheet", systemImage: "doc.text.fill")
                }

            CompetitionListView()
                .tabItem {
                    Label("Competitions", systemImage: "trophy.fill")
                }

            TeamListView()
                .tabItem {
                    Label("Teams", systemImage: "person.3.fill")
                }

            InsightsDashboardView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(.scoreBinCyan)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Scoresheet.self, Team.self, Competition.self, Gym.self], inMemory: true)
}
