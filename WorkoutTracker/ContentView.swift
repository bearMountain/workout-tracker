import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncEngine.self) private var syncEngine: SyncEngine?
    @State private var selectedTab = 0
    @State private var hasInitialSynced = false

    var body: some View {
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
        .tint(AppTheme.accent)
        .onAppear {
            seedDataIfNeeded()
        }
        .task {
            if !hasInitialSynced, let syncEngine {
                hasInitialSynced = true
                await syncEngine.syncAll()
            }
        }
    }

    private func seedDataIfNeeded() {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        if existingCount == 0 {
            SampleData.seedExercises(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, ContentNote.self, BodyWeightEntry.self], inMemory: true)
}
