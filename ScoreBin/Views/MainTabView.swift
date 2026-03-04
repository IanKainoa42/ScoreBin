import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ScoresheetEntryView()
                .tabItem {
                    Label("Scoresheet", systemImage: "doc.text.fill")
                }

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
        }
        .tint(.scoreBinCyan)
        .overlay(alignment: .topTrailing) {
            SyncStatusBadge()
                .padding(.trailing, 16)
                .padding(.top, 4)
        }
    }
}

// MARK: - Sync Status Badge

/// Compact sync indicator shown at the top of the tab bar interface.
/// Tapping triggers a manual sync.
struct SyncStatusBadge: View {
    private var syncManager = SyncManager.shared
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            Task {
                await syncManager.syncAll(context: modelContext)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: syncIcon)
                    .font(.system(size: 10, weight: .semibold))
                    .rotationEffect(.degrees(syncManager.isSyncing ? 360 : 0))
                    .animation(
                        syncManager.isSyncing
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: syncManager.isSyncing
                    )

                if syncManager.pendingChanges > 0 {
                    Text("\(syncManager.pendingChanges)")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundColor(syncColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(syncColor.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(syncAccessibilityLabel)
    }

    private var syncIcon: String {
        if syncManager.isSyncing { return "arrow.triangle.2.circlepath" }
        if !syncManager.isOnline { return "wifi.slash" }
        if syncManager.pendingChanges > 0 { return "arrow.up.circle" }
        return "checkmark.icloud"
    }

    private var syncColor: Color {
        if !syncManager.isOnline { return .red }
        if syncManager.isSyncing { return .orange }
        if syncManager.pendingChanges > 0 { return .overallYellow }
        return .scoreBinEmerald
    }

    private var syncAccessibilityLabel: String {
        if syncManager.isSyncing { return "Syncing" }
        if !syncManager.isOnline { return "Offline" }
        if syncManager.pendingChanges > 0 {
            return "\(syncManager.pendingChanges) pending changes. Tap to sync."
        }
        return "All synced"
    }
}

#Preview {
    MainTabView()
        .modelContainer(
            for: [Scoresheet.self, Team.self, Competition.self, Gym.self], inMemory: true)
}
