import XCTest
import SwiftData
@testable import WorkoutTracker

actor MockAPIClient: APIClientProtocol {
    var exercises: [APIExercise] = []
    var logs: [APIWorkoutLog] = []
    var bodyWeights: [APIBodyWeight] = []
    var notes: [APIContentNote] = []
    
    var createdExercises: [CreateExerciseRequest] = []
    var createdLogs: [CreateWorkoutLogRequest] = []
    var createdBodyWeights: [CreateBodyWeightRequest] = []
    var createdNotes: [CreateContentNoteRequest] = []
    
    var shouldFailExercisePush = false

    func setExercises(_ exercises: [APIExercise]) {
        self.exercises = exercises
    }

    func setLogs(_ logs: [APIWorkoutLog]) {
        self.logs = logs
    }

    func setBodyWeights(_ bodyWeights: [APIBodyWeight]) {
        self.bodyWeights = bodyWeights
    }
    
    func setNotes(_ notes: [APIContentNote]) {
        self.notes = notes
    }
    
    func setShouldFailExercisePush(_ shouldFail: Bool) {
        self.shouldFailExercisePush = shouldFail
    }

    func fetchExercises(workoutType: String?, since: String?) async throws -> [APIExercise] { exercises }
    func fetchLogs(exerciseId: String?, limit: Int, since: String?) async throws -> [APIWorkoutLog] { logs }
    func fetchBodyWeights(limit: Int, since: String?) async throws -> [APIBodyWeight] { bodyWeights }
    func fetchNotes(limit: Int, since: String?) async throws -> [APIContentNote] { notes }

    func createExercise(_ input: CreateExerciseRequest) async throws -> APIExercise {
        if shouldFailExercisePush {
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }
        createdExercises.append(input)
        return APIExercise(
            id: input.id ?? UUID().uuidString,
            name: input.name,
            targetWeight: input.targetWeight,
            targetReps: input.targetReps,
            isMachine: input.isMachine,
            notes: input.notes,
            workoutType: input.workoutType,
            orderIndex: input.orderIndex,
            clientUpdatedAt: input.clientUpdatedAt,
            createdAt: input.clientUpdatedAt,
            updatedAt: input.clientUpdatedAt,
            deletedAt: input.deletedAt,
            serverVersion: 1,
            lastIdempotencyKey: input.idempotencyKey
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
            isMachine: input.isMachine,
            feeling: input.feeling,
            notes: input.notes ?? "",
            clientUpdatedAt: input.clientUpdatedAt,
            createdAt: input.clientUpdatedAt,
            updatedAt: input.clientUpdatedAt,
            deletedAt: input.deletedAt,
            serverVersion: 1,
            lastIdempotencyKey: input.idempotencyKey,
            exerciseName: nil,
            workoutType: nil
        )
    }

    func createBodyWeight(_ input: CreateBodyWeightRequest) async throws -> APIBodyWeight {
        createdBodyWeights.append(input)
        return APIBodyWeight(
            id: input.id ?? UUID().uuidString,
            date: input.date ?? "",
            weight: input.weight,
            notes: input.notes ?? "",
            clientUpdatedAt: input.clientUpdatedAt,
            createdAt: input.clientUpdatedAt,
            updatedAt: input.clientUpdatedAt,
            deletedAt: input.deletedAt,
            serverVersion: 1,
            lastIdempotencyKey: input.idempotencyKey
        )
    }
    
    func createNote(_ input: CreateContentNoteRequest) async throws -> APIContentNote {
        createdNotes.append(input)
        return APIContentNote(
            id: input.id ?? UUID().uuidString,
            title: input.title,
            body: input.body ?? "",
            url: input.url ?? "",
            clientUpdatedAt: input.clientUpdatedAt,
            createdAt: input.clientUpdatedAt,
            updatedAt: input.clientUpdatedAt,
            deletedAt: input.deletedAt,
            serverVersion: 1,
            lastIdempotencyKey: input.idempotencyKey
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
    
    func updateNote(id: String, _ input: UpdateContentNoteRequest) async throws -> APIContentNote {
        notes.first { $0.id == id }!
    }

    func deleteExercise(id: String) async throws { }
    func deleteLog(id: String) async throws { }
    func deleteBodyWeight(id: String) async throws { }
    func deleteNote(id: String) async throws { }
}

@MainActor
final class SyncEngineTests: XCTestCase {
    
    private var testContainer: ModelContainer?
    
    private func makeTestContext() throws -> ModelContext {
        let tempDir = FileManager.default.temporaryDirectory
        let storeURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).store")
        let container = try WorkoutTrackerModelContainerFactory.makeContainer(url: storeURL)
        testContainer = container
        return container.mainContext
    }
    
    override func tearDown() async throws {
        testContainer = nil
    }
    
    private func makeEngine(context: ModelContext, mock: MockAPIClient, online: Bool = true) -> SyncEngine {
        SyncEngine(
            modelContext: context,
            apiClient: mock,
            enablePathMonitoring: false,
            initialOnlineState: online,
            enableBackgroundScheduling: false
        )
    }
    
    private func isoString(_ date: Date) -> String {
        APIClient.dateFormatter.string(from: date)
    }

    func testPullLatestInsertsExercises() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let id = UUID()
        await mock.setExercises([
            APIExercise(
                id: id.uuidString, name: "Squat", targetWeight: 200, targetReps: 5,
                isMachine: false,
                notes: "", workoutType: "A", orderIndex: 0,
                clientUpdatedAt: "2026-01-01T00:00:00.000Z",
                createdAt: "2026-01-01T00:00:00.000Z",
                updatedAt: "2026-01-01T00:00:00.000Z",
                deletedAt: nil,
                serverVersion: 2,
                lastIdempotencyKey: nil
            )
        ])

        let engine = makeEngine(context: context, mock: mock)
        await engine.syncAll()

        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.name, "Squat")
        XCTAssertEqual(exercises.first?.remoteID, id.uuidString)
        XCTAssertFalse(exercises.first?.isDirty ?? true)
    }
    
    func testQueueForSyncMarksExercisePending() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let engine = makeEngine(context: context, mock: mock, online: false)
        let exercise = Exercise(name: "Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        context.insert(exercise)
        try context.save()
        
        exercise.name = "Back Squat"
        engine.queueForSync(exercise)
        
        XCTAssertTrue(exercise.isDirty)
        XCTAssertEqual(engine.pendingChangesCount, 1)
    }
    
    func testProcessPendingChangesClearsDirtyState() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let engine = makeEngine(context: context, mock: mock, online: false)
        
        let exercise = Exercise(name: "Row", targetWeight: 100, targetReps: 8, workoutType: .a, orderIndex: 0)
        context.insert(exercise)
        try context.save()
        
        engine.queueForSync(exercise)
        try await engine.processPendingChanges()
        
        let created = await mock.createdExercises
        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created.first?.id, exercise.localID.uuidString)
        XCTAssertFalse(exercise.isDirty)
        XCTAssertEqual(exercise.remoteID, exercise.localID.uuidString)
    }
    
    func testPushFailureIncrementsRetryCount() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        await mock.setShouldFailExercisePush(true)
        let engine = makeEngine(context: context, mock: mock, online: false)
        
        let exercise = Exercise(name: "Deadlift", targetWeight: 225, targetReps: 5, workoutType: .b, orderIndex: 0)
        context.insert(exercise)
        try context.save()
        
        engine.queueForSync(exercise)
        try await engine.processPendingChanges()
        
        XCTAssertTrue(exercise.isDirty)
        XCTAssertEqual(exercise.retryCount, 1)
        XCTAssertNotNil(exercise.syncError)
    }
    
    func testPersistentBannerAppearsAfterMaxRetries() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        await mock.setShouldFailExercisePush(true)
        let engine = makeEngine(context: context, mock: mock, online: false)
        
        let exercise = Exercise(name: "Press", targetWeight: 95, targetReps: 8, workoutType: .b, orderIndex: 1)
        context.insert(exercise)
        try context.save()
        engine.queueForSync(exercise)
        
        for _ in 0..<5 {
            exercise.lastSyncAttempt = .distantPast
            try await engine.processPendingChanges()
        }
        
        XCTAssertEqual(exercise.retryCount, 5)
        XCTAssertEqual(engine.persistentBannerMessage, "Sync failed - will retry")
    }
    
    func testPullLatestInsertsWorkoutLogAndLinksExercise() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let exercise = Exercise(name: "Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        exercise.remoteID = exercise.localID.uuidString
        exercise.markSynced(remoteID: exercise.localID.uuidString, serverVersion: 1)
        context.insert(exercise)
        try context.save()
        
        await mock.setLogs([
            APIWorkoutLog(
                id: UUID().uuidString,
                exerciseId: exercise.remoteID ?? "",
                date: "2026-03-05T12:00:00.000Z",
                actualWeight: 205,
                actualReps: 5,
                isMachine: false,
                feeling: 4,
                notes: "",
                clientUpdatedAt: "2026-03-05T12:00:00.000Z",
                createdAt: "2026-03-05T12:00:00.000Z",
                updatedAt: "2026-03-05T12:00:00.000Z",
                deletedAt: nil,
                serverVersion: 2,
                lastIdempotencyKey: nil,
                exerciseName: "Squat",
                workoutType: "A"
            )
        ])
        
        let engine = makeEngine(context: context, mock: mock)
        await engine.syncAll()
        
        let logs = try context.fetch(FetchDescriptor<WorkoutLog>())
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.actualWeight, 205)
        XCTAssertEqual(logs.first?.exercise?.name, "Squat")
    }
    
    func testPullKeepsNewerDirtyLocalChanges() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let exercise = Exercise(name: "Local Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        exercise.remoteID = exercise.localID.uuidString
        exercise.lastModifiedAt = Date().addingTimeInterval(3600)
        exercise.isDirty = true
        context.insert(exercise)
        try context.save()
        
        await mock.setExercises([
            APIExercise(
                id: exercise.remoteID ?? "",
                name: "Remote Squat",
                targetWeight: 225,
                targetReps: 5,
                isMachine: nil,
                notes: "",
                workoutType: "A",
                orderIndex: 0,
                clientUpdatedAt: isoString(Date().addingTimeInterval(-3600)),
                createdAt: isoString(Date().addingTimeInterval(-7200)),
                updatedAt: isoString(Date().addingTimeInterval(-1800)),
                deletedAt: nil,
                serverVersion: 2,
                lastIdempotencyKey: nil
            )
        ])
        
        let engine = makeEngine(context: context, mock: mock)
        try await engine.pullLatestFromServer()
        
        XCTAssertEqual(exercise.name, "Local Squat")
        XCTAssertTrue(exercise.isDirty)
    }

    func testPullPreservesLocalMachineFlagWhenRemotePayloadOmitsIt() async throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let exercise = Exercise(
            name: "Leg Extensions",
            targetWeight: 60,
            targetReps: 8,
            isMachine: true,
            workoutType: .a,
            orderIndex: 0
        )
        exercise.remoteID = exercise.localID.uuidString
        exercise.markSynced(remoteID: exercise.localID.uuidString, serverVersion: 1)
        context.insert(exercise)
        try context.save()

        await mock.setExercises([
            APIExercise(
                id: exercise.remoteID ?? "",
                name: "Leg Extensions",
                targetWeight: 60,
                targetReps: 8,
                isMachine: nil,
                notes: "",
                workoutType: "A",
                orderIndex: 0,
                clientUpdatedAt: isoString(Date()),
                createdAt: isoString(Date().addingTimeInterval(-3600)),
                updatedAt: isoString(Date()),
                deletedAt: nil,
                serverVersion: 2,
                lastIdempotencyKey: nil
            )
        ])

        let engine = makeEngine(context: context, mock: mock)
        try await engine.pullLatestFromServer()

        XCTAssertTrue(exercise.isMachine)
    }

    func testBestLogUsesHighestWeightThenRepsInsteadOfLatest() throws {
        let context = try makeTestContext()
        let exercise = Exercise(name: "Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        context.insert(exercise)

        let calendar = Calendar(identifier: .gregorian)
        let lowerLatest = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 3))!,
            actualWeight: 185,
            actualReps: 12,
            exercise: exercise
        )
        let heavierFewerReps = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!,
            actualWeight: 225,
            actualReps: 5,
            exercise: exercise
        )
        let bestLog = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 2))!,
            actualWeight: 225,
            actualReps: 6,
            exercise: exercise
        )
        let deletedHigherLog = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 4))!,
            actualWeight: 250,
            actualReps: 1,
            exercise: exercise
        )
        deletedHigherLog.markDeleted()

        [lowerLatest, heavierFewerReps, bestLog, deletedHigherLog].forEach(context.insert)
        try context.save()

        XCTAssertEqual(exercise.bestLog?.id, bestLog.id)
    }

    func testBestLogFromLastWorkoutDayIgnoresLaterLowerSetOnSameDay() throws {
        let context = try makeTestContext()
        let exercise = Exercise(name: "Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        context.insert(exercise)

        let calendar = Calendar(identifier: .gregorian)
        let olderAllTimeBest = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 12))!,
            actualWeight: 250,
            actualReps: 3,
            exercise: exercise
        )
        let lastDayBest = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12))!,
            actualWeight: 225,
            actualReps: 6,
            exercise: exercise
        )
        let lastDayLowerLaterSet = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12, minute: 5))!,
            actualWeight: 185,
            actualReps: 10,
            exercise: exercise
        )
        let todayLog = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 14, hour: 12))!,
            actualWeight: 135,
            actualReps: 12,
            exercise: exercise
        )

        [olderAllTimeBest, lastDayBest, lastDayLowerLaterSet, todayLog].forEach(context.insert)
        try context.save()

        let selectedLog = Exercise.bestLogFromLastWorkoutDay(
            in: exercise.activeLogs,
            before: calendar.date(from: DateComponents(year: 2026, month: 4, day: 14, hour: 12))!,
            calendar: calendar
        )

        XCTAssertEqual(selectedLog?.id, lastDayBest.id)
    }

    func testPlannedSetUsesLastWorkoutDayBestInsteadOfStoredTarget() throws {
        let context = try makeTestContext()
        let exercise = Exercise(name: "Calf Raises", targetWeight: 150, targetReps: 12, workoutType: .a, orderIndex: 0)
        context.insert(exercise)

        let calendar = Calendar(identifier: .gregorian)
        let olderHeavier = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 12))!,
            actualWeight: 160,
            actualReps: 8,
            exercise: exercise
        )
        let lastSessionBest = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 8, hour: 12))!,
            actualWeight: 130,
            actualReps: 10,
            exercise: exercise
        )
        let lastSessionLighter = WorkoutLog(
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 8, hour: 12, minute: 5))!,
            actualWeight: 110,
            actualReps: 12,
            exercise: exercise
        )

        [olderHeavier, lastSessionBest, lastSessionLighter].forEach(context.insert)
        try context.save()

        let plan = Exercise.plannedSet(
            in: exercise.activeLogs,
            fallbackWeight: exercise.targetWeight,
            fallbackReps: exercise.targetReps,
            fallbackIsMachine: exercise.isMachine,
            before: calendar.date(from: DateComponents(year: 2026, month: 4, day: 15, hour: 12))!,
            calendar: calendar
        )

        XCTAssertEqual(plan.weight, 130)
        XCTAssertEqual(plan.reps, 10)
        XCTAssertFalse(plan.isMachine)
    }

    func testPlannedSetFallsBackToStoredTargetWhenThereIsNoPreviousSession() throws {
        let context = try makeTestContext()
        let exercise = Exercise(
            name: "Calf Raises",
            targetWeight: 150,
            targetReps: 12,
            isMachine: true,
            workoutType: .a,
            orderIndex: 0
        )
        context.insert(exercise)
        try context.save()

        XCTAssertEqual(exercise.plannedSet, Exercise.PlannedSet(weight: 150, reps: 12, isMachine: true))
    }

    func testMarkSyncedDoesNotClearDeletedAt() throws {
        let context = try makeTestContext()
        let exercise = Exercise(name: "Squat", targetWeight: 200, targetReps: 5, workoutType: .a, orderIndex: 0)
        context.insert(exercise)
        exercise.markDeleted()

        XCTAssertTrue(exercise.isSoftDeleted)
        XCTAssertNotNil(exercise.deletedAt)

        exercise.markSynced(remoteID: exercise.localID.uuidString, serverVersion: 1)

        XCTAssertTrue(exercise.isSoftDeleted)
        XCTAssertNotNil(exercise.deletedAt)
    }

    func testDeleteExerciseRemovesFromWorkoutButKeepsLogs() throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let engine = makeEngine(context: context, mock: mock, online: false)
        let viewModel = WorkoutViewModel(modelContext: context, syncEngine: engine)

        let exercise = Exercise(name: "Glute Box Step-down", targetWeight: 0, targetReps: 6, workoutType: .a, orderIndex: 0)
        context.insert(exercise)
        let log = WorkoutLog(actualWeight: 0, actualReps: 6, exercise: exercise)
        context.insert(log)
        try context.save()
        viewModel.fetchExercises()
        viewModel.fetchRecentLogs()

        XCTAssertEqual(viewModel.exercises(for: .a).count, 1)

        viewModel.deleteExercise(exercise)

        XCTAssertTrue(viewModel.exercises(for: .a).isEmpty)
        XCTAssertTrue(exercise.isSoftDeleted)
        XCTAssertFalse(log.isSoftDeleted)
        XCTAssertEqual(exercise.activeLogs.count, 1)
    }

    func testProgressKeepsSoftDeletedExerciseWithLogs() throws {
        let context = try makeTestContext()
        let mock = MockAPIClient()
        let engine = makeEngine(context: context, mock: mock, online: false)

        let kept = Exercise(name: "Squat", targetWeight: 225, targetReps: 5, workoutType: .a, orderIndex: 0)
        let removedWithHistory = Exercise(name: "Glute Box Step-down", targetWeight: 0, targetReps: 6, workoutType: .a, orderIndex: 1)
        let removedWithoutHistory = Exercise(name: "Unused", targetWeight: 50, targetReps: 8, workoutType: .a, orderIndex: 2)
        [kept, removedWithHistory, removedWithoutHistory].forEach(context.insert)

        context.insert(WorkoutLog(actualWeight: 0, actualReps: 6, exercise: removedWithHistory))
        removedWithHistory.markDeleted()
        removedWithoutHistory.markDeleted()
        try context.save()

        let progress = ProgressViewModel(modelContext: context, syncEngine: engine)
        let names = Set(progress.exercises(for: .a).map(\.name))

        XCTAssertEqual(names, ["Squat", "Glute Box Step-down"])
    }
}
