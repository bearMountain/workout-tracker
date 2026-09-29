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
        XCTAssertEqual(migratedExercises.first?.progressiveOverload, false)
    }

    func testV2StoreMigratesProgressiveOverloadFlagToFalse() throws {
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("migration_\(UUID().uuidString).store")
        self.storeURL = storeURL

        let v2Schema = Schema(versionedSchema: WorkoutTrackerSchemaV2.self)
        let v2Configuration = ModelConfiguration(schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(for: v2Schema, configurations: [v2Configuration])
        let v2Context = v2Container.mainContext
        v2Context.insert(WorkoutTrackerSchemaV2.Exercise(
            name: "Squats",
            targetWeight: 225,
            targetReps: 8,
            notes: "",
            workoutType: .a,
            orderIndex: 0
        ))
        try v2Context.save()

        let migratedContainer = try WorkoutTrackerModelContainerFactory.makeContainer(url: storeURL)
        let migrated = try migratedContainer.mainContext.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(migrated.first?.progressiveOverload, false)
    }

    func testProgressiveOverloadSeedTurnsOnExactLiveNamesOnce() throws {
        let container = try WorkoutTrackerModelContainerFactory.makeInMemoryContainer()
        let context = container.mainContext
        let names = [
            "Squats",
            "Dead Lift",
            "Leg Extensions",
            "Pec Deck",
            "Bench Press",
            "Pull-ups",
            "Chin-ups",
            "Abs",
            "Squat"
        ]
        for (index, name) in names.enumerated() {
            context.insert(Exercise(name: name, targetWeight: 0, targetReps: 8, workoutType: .a, orderIndex: index))
        }
        let removed = Exercise(name: "Squats", targetWeight: 0, targetReps: 8, workoutType: .b, orderIndex: 0)
        removed.markDeleted()
        context.insert(removed)
        try context.save()

        let suiteName = "progressive-overload-seed-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        XCTAssertTrue(ProgressiveOverloadSeed.applyIfNeeded(in: context, defaults: defaults))

        let stored = try context.fetch(FetchDescriptor<Exercise>())
        let enabled = Set(stored.filter(\.progressiveOverload).map(\.name))
        XCTAssertEqual(
            enabled,
            Set(["Squats", "Dead Lift", "Leg Extensions", "Pec Deck", "Bench Press"])
        )
        XCTAssertFalse(stored.contains { $0.isSoftDeleted && $0.progressiveOverload })

        if let squats = stored.first(where: { $0.name == "Squats" && !$0.isSoftDeleted }) {
            squats.progressiveOverload = false
        }
        try context.save()

        XCTAssertFalse(ProgressiveOverloadSeed.applyIfNeeded(in: context, defaults: defaults))
        let after = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertFalse(after.contains { $0.name == "Squats" && !$0.isSoftDeleted && $0.progressiveOverload })
        defaults.removePersistentDomain(forName: suiteName)
    }
}
