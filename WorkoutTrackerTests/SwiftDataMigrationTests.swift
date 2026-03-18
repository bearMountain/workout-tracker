import XCTest
import SwiftData
@testable import WorkoutTracker

@MainActor
final class SwiftDataMigrationTests: XCTestCase {
    private var storeURL: URL?

    override func tearDown() async throws {
        guard let storeURL else { return }

        let fileManager = FileManager.default
        let companionURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in companionURLs where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }

        self.storeURL = nil
    }

    func testV1StoreMigratesExerciseMachineFlagToFalse() throws {
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("migration_\(UUID().uuidString).store")
        self.storeURL = storeURL

        let v1Schema = Schema(versionedSchema: WorkoutTrackerSchemaV1.self)
        let v1Configuration = ModelConfiguration(schema: v1Schema, url: storeURL)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Configuration])
        let v1Context = v1Container.mainContext

        let legacyExercise = WorkoutTrackerSchemaV1.Exercise(
            name: "Leg Extensions",
            targetWeight: 60,
            targetReps: 8,
            notes: "",
            workoutType: .a,
            orderIndex: 0
        )
        v1Context.insert(legacyExercise)
        try v1Context.save()

        let migratedContainer = try WorkoutTrackerModelContainerFactory.makeContainer(url: storeURL)
        let migratedContext = migratedContainer.mainContext
        let migratedExercises = try migratedContext.fetch(FetchDescriptor<Exercise>())

        XCTAssertEqual(migratedExercises.count, 1)
        XCTAssertEqual(migratedExercises.first?.name, "Leg Extensions")
        XCTAssertEqual(migratedExercises.first?.targetWeight, 60)
        XCTAssertEqual(migratedExercises.first?.targetReps, 8)
        XCTAssertEqual(migratedExercises.first?.isMachine, false)
    }
}
