import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TeamListView()
                .tabItem {
                    Label("Teams", systemImage: "person.3.fill")
                }

            CompetitionListView()
                .tabItem {
                    Label("Competitions", systemImage: "trophy.fill")
                }

            InsightsDashboardView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }

            ScoresheetEntryView()
                .tabItem {
                    Label("Scoresheet", systemImage: "doc.text.fill")
                }
        }
        .tint(.scoreBinCyan)
    }
}

#Preview {
    MainTabView()
        .modelContainer(
            for: [Scoresheet.self, Team.self, Competition.self, Gym.self], inMemory: true)
}
