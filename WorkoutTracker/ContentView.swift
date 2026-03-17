import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SyncEngine.self) private var syncEngine: SyncEngine?
    @State private var selectedTab = 0
    @State private var hasInitialSynced = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "calendar")
                    }
                    .tag(1)

                NotesView()
                    .tabItem {
                        Label("Notes", systemImage: "note.text")
                    }
                    .tag(2)

                ProgressTabView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(3)
            }
            
            SyncStatusBanner()
        }
        .tint(AppTheme.accent)
        .task {
            if !hasInitialSynced, let syncEngine {
                hasInitialSynced = true
                await syncEngine.handleSceneDidBecomeActive()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard let syncEngine else { return }
            switch newPhase {
            case .active:
                Task {
                    await syncEngine.handleSceneDidBecomeActive()
                }
            case .background:
                syncEngine.scheduleBackgroundSync()
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, ContentNote.self, BodyWeightEntry.self], inMemory: true)
}
