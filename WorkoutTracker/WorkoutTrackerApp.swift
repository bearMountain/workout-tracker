import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    @UIApplicationDelegateAdaptor(WorkoutTrackerAppDelegate.self) private var appDelegate
    let sharedModelContainer: ModelContainer
    let syncEngine: SyncEngine

    init() {
        let schema = Schema([
            Exercise.self,
            WorkoutLog.self,
            ContentNote.self,
            BodyWeightEntry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            SyncMetadataMigration.backfill(context: container.mainContext)
            self.sharedModelContainer = container
            self.syncEngine = SyncEngine(modelContext: container.mainContext)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(syncEngine)
                .task {
                    KeyboardPreloader.preload()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
