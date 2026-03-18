import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    @UIApplicationDelegateAdaptor(WorkoutTrackerAppDelegate.self) private var appDelegate
    let sharedModelContainer: ModelContainer
    let syncEngine: SyncEngine

    init() {
        do {
            let container = try WorkoutTrackerModelContainerFactory.makeSharedContainer()
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
