import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutLog.self,
            ContentNote.self,
            BodyWeightEntry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var syncEngine: SyncEngine?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    if syncEngine == nil {
                        let context = sharedModelContainer.mainContext
                        syncEngine = SyncEngine(modelContext: context)
                    }
                }
                .environment(syncEngine)
        }
        .modelContainer(sharedModelContainer)
    }
}
