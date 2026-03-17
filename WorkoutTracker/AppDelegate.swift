import BackgroundTasks
import UIKit

final class WorkoutTrackerAppDelegate: NSObject, UIApplicationDelegate {
    static let syncTaskIdentifier = "com.gizmo.workouttracker.sync"
    
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard !isRunningTests else {
            return true
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.syncTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            
            Task { @MainActor in
                SyncEngine.shared?.handleBackgroundProcessingTask(processingTask)
            }
        }
        
        return true
    }
}
