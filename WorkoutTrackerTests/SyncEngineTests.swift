import XCTest
import SwiftData
@testable import WorkoutTracker

actor MockAPIClient: APIClientProtocol {
    var exercises: [APIExercise] = []
    var logs: [APIWorkoutLog] = []
    var bodyWeights: [APIBodyWeight] = []

    var createdExercises: [CreateExerciseRequest] = []
    var createdLogs: [CreateWorkoutLogRequest] = []
    var createdBodyWeights: [CreateBodyWeightRequest] = []
    var deletedExerciseIds: [String] = []
    var deletedLogIds: [String] = []
    var deletedBodyWeightIds: [String] = []

    func setExercises(_ exercises: [APIExercise]) {
        self.exercises = exercises
    }

    func setLogs(_ logs: [APIWorkoutLog]) {
        self.logs = logs
    }

    func setBodyWeights(_ bodyWeights: [APIBodyWeight]) {
        self.bodyWeights = bodyWeights
    }

    func fetchExercises(workoutType: String?) async throws -> [APIExercise] { exercises }
    func fetchLogs(exerciseId: String?, limit: Int) async throws -> [APIWorkoutLog] { logs }
    func fetchBodyWeights(limit: Int) async throws -> [APIBodyWeight] { bodyWeights }

    func createExercise(_ input: CreateExerciseRequest) async throws -> APIExercise {
        createdExercises.append(input)
        return APIExercise(
            id: input.id ?? UUID().uuidString,
            name: input.name,
            targetWeight: input.targetWeight,
            targetReps: input.targetReps,
            notes: input.notes,
            workoutType: input.workoutType,
            orderIndex: input.orderIndex,
            createdAt: "", updatedAt: ""
        )
    }

    func createLog(_ input: CreateWorkoutLogRequest) async throws -> APIWorkoutLog {
        createdLogs.append(input)
        return APIWorkoutLog(
            id: input.id ?? UUID().uuidString,
            exerciseId: input.exerciseId,
            date: input.date ?? "",
            actualWeight: input.actualWeight,
            actualReps: input.actualReps,
            feeling: input.feeling,
            notes: input.notes ?? "",
            createdAt: "", exerciseName: nil, workoutType: nil
        )
    }

    func createBodyWeight(_ input: CreateBodyWeightRequest) async throws -> APIBodyWeight {
        createdBodyWeights.append(input)
        return APIBodyWeight(
            id: input.id ?? UUID().uuidString,
            date: input.date ?? "",
            weight: input.weight,
            notes: input.notes ?? "",
            createdAt: ""
        )
    }

    func updateExercise(id: String, _ input: UpdateExerciseRequest) async throws -> APIExercise {
        exercises.first { $0.id == id }!
    }

    func updateLog(id: String, _ input: UpdateWorkoutLogRequest) async throws -> APIWorkoutLog {
        logs.first { $0.id == id }!
    }

    func updateBodyWeight(id: String, _ input: UpdateBodyWeightRequest) async throws -> APIBodyWeight {
        bodyWeights.first { $0.id == id }!
    }

    func deleteExercise(id: String) async throws { deletedExerciseIds.append(id) }
    func deleteLog(id: String) async throws { deletedLogIds.append(id) }
    func deleteBodyWeight(id: String) async throws { deletedBodyWeightIds.append(id) }
}

@MainActor
final class SyncEngineTests: XCTestCase {
    
    private var testContainer: ModelContainer?
    
    private func makeTestContext() throws -> ModelContext {
        let schema = Schema([Exercise.self, WorkoutLog.self, ContentNote.self, BodyWeightEntry.self])
        let tempDir = FileManager.default.temporaryDirectory
        let storeURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).store")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [config])
        testContainer = container
        return container.mainContext
    }
    
    override func tearDown() async throws {
        testContainer = nil
    }

    func testInsertNewExercises() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let id = UUID()
        await mock.setExercises([
            APIExercise(
                id: id.uuidString, name: "Squat", targetWeight: 200, targetReps: 5,
                notes: "", workoutType: "A", orderIndex: 0,
                createdAt: "2026-01-01T00:00:00.000Z", updatedAt: "2026-01-01T00:00:00.000Z"
            )
        ])

        let engine = SyncEngine(modelContext: context, apiClient: mock)
        await engine.syncAll()

        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.name, "Squat")
        XCTAssertEqual(exercises.first?.id, id)
    }

    func testUpdateExistingExercise() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let id = UUID()

        let exercise = Exercise(id: id, name: "Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        context.insert(exercise)
        try context.save()

        await mock.setExercises([
            APIExercise(
                id: id.uuidString, name: "Back Squat", targetWeight: 225, targetReps: 5,
                notes: "updated", workoutType: "A", orderIndex: 0,
                createdAt: "", updatedAt: ""
            )
        ])

        let engine = SyncEngine(modelContext: context, apiClient: mock)
        await engine.syncAll()

        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.name, "Back Squat")
        XCTAssertEqual(exercises.first?.targetWeight, 225)
    }

    func testNoDuplicatesOnRepeatedSync() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let id = UUID()
        await mock.setExercises([
            APIExercise(
                id: id.uuidString, name: "Bench", targetWeight: 150, targetReps: 8,
                notes: "", workoutType: "B", orderIndex: 0,
                createdAt: "", updatedAt: ""
            )
        ])

        let engine = SyncEngine(modelContext: context, apiClient: mock)

        await engine.syncAll()
        await engine.syncAll()
        await engine.syncAll()

        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        XCTAssertEqual(exercises.count, 1)
    }

    func testInsertNewBodyWeights() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let id = UUID()
        await mock.setBodyWeights([
            APIBodyWeight(
                id: id.uuidString,
                date: "2026-03-05T12:00:00.000Z",
                weight: 225.6, notes: "",
                createdAt: "2026-03-05T12:00:00.000Z"
            )
        ])

        let engine = SyncEngine(modelContext: context, apiClient: mock)
        await engine.syncAll()

        let descriptor = FetchDescriptor<BodyWeightEntry>()
        let entries = try context.fetch(descriptor)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.weight, 225.6)
        XCTAssertEqual(entries.first?.id, id)
    }

    func testNoDuplicateBodyWeights() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let id = UUID()
        await mock.setBodyWeights([
            APIBodyWeight(
                id: id.uuidString,
                date: "2026-03-05T12:00:00.000Z",
                weight: 225, notes: "",
                createdAt: ""
            )
        ])

        let engine = SyncEngine(modelContext: context, apiClient: mock)

        await engine.syncAll()
        await engine.syncAll()
        await engine.syncAll()

        let descriptor = FetchDescriptor<BodyWeightEntry>()
        let entries = try context.fetch(descriptor)
        XCTAssertEqual(entries.count, 1)
    }

    func testPushSendsClientUUID() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let engine = SyncEngine(modelContext: context, apiClient: mock)

        let exercise = Exercise(name: "Row", targetWeight: 100, targetReps: 8, workoutType: .a, orderIndex: 0)
        context.insert(exercise)
        try context.save()

        await engine.pushExercise(exercise)

        let created = await mock.createdExercises
        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created.first?.id, exercise.id.uuidString)
        XCTAssertEqual(created.first?.name, "Row")
    }

    func testPushSendsClientUUIDBodyWeight() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let engine = SyncEngine(modelContext: context, apiClient: mock)

        let entry = BodyWeightEntry(date: Date(), weight: 180, notes: "test")
        context.insert(entry)
        try context.save()

        await engine.pushBodyWeight(entry)

        let created = await mock.createdBodyWeights
        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created.first?.id, entry.id.uuidString)
        XCTAssertEqual(created.first?.weight, 180)
    }

    func testConcurrentSyncGuard() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let engine = SyncEngine(modelContext: context, apiClient: mock)

        async let sync1: () = engine.syncAll()
        async let sync2: () = engine.syncAll()
        _ = await (sync1, sync2)

        XCTAssertFalse(engine.isSyncing)
    }

    func testInsertNewWorkoutLogs() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()

        let exerciseId = UUID()
        let exercise = Exercise(id: exerciseId, name: "Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        context.insert(exercise)
        try context.save()

        let logId = UUID()
        await mock.setLogs([
            APIWorkoutLog(
                id: logId.uuidString,
                exerciseId: exerciseId.uuidString,
                date: "2026-03-05T12:00:00.000Z",
                actualWeight: 205, actualReps: 5, feeling: 4, notes: "",
                createdAt: "", exerciseName: "Squat", workoutType: "A"
            )
        ])

        let engine = SyncEngine(modelContext: context, apiClient: mock)
        await engine.syncAll()

        let descriptor = FetchDescriptor<WorkoutLog>()
        let logs = try context.fetch(descriptor)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.actualWeight, 205)
        XCTAssertEqual(logs.first?.exercise?.id, exerciseId)
    }

    func testLocalThenSyncNoDuplicate() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()

        let id = UUID()
        let entry = BodyWeightEntry(id: id, date: Date(), weight: 180, notes: "")
        context.insert(entry)
        try context.save()

        await mock.setBodyWeights([
            APIBodyWeight(
                id: id.uuidString,
                date: APIClient.dateFormatter.string(from: entry.date),
                weight: 180, notes: "",
                createdAt: ""
            )
        ])

        let engine = SyncEngine(modelContext: context, apiClient: mock)
        await engine.syncAll()

        let descriptor = FetchDescriptor<BodyWeightEntry>()
        let entries = try context.fetch(descriptor)
        XCTAssertEqual(entries.count, 1)
    }
}
