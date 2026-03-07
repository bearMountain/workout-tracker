import Foundation
import SwiftData

protocol APIClientProtocol: Sendable {
    func fetchExercises(workoutType: String?) async throws -> [APIExercise]
    func fetchLogs(exerciseId: String?, limit: Int) async throws -> [APIWorkoutLog]
    func fetchBodyWeights(limit: Int) async throws -> [APIBodyWeight]

    func createExercise(_ input: CreateExerciseRequest) async throws -> APIExercise
    func createLog(_ input: CreateWorkoutLogRequest) async throws -> APIWorkoutLog
    func createBodyWeight(_ input: CreateBodyWeightRequest) async throws -> APIBodyWeight

    func updateExercise(id: String, _ input: UpdateExerciseRequest) async throws -> APIExercise
    func updateLog(id: String, _ input: UpdateWorkoutLogRequest) async throws -> APIWorkoutLog
    func updateBodyWeight(id: String, _ input: UpdateBodyWeightRequest) async throws -> APIBodyWeight

    func deleteExercise(id: String) async throws
    func deleteLog(id: String) async throws
    func deleteBodyWeight(id: String) async throws
}

extension APIClient: APIClientProtocol {}

@Observable
@MainActor
final class SyncEngine {
    private let modelContext: ModelContext
    private let apiClient: any APIClientProtocol

    private(set) var isSyncing = false
    private(set) var syncError: String?
    var lastSyncDate: Date?

    init(modelContext: ModelContext, apiClient: any APIClientProtocol = APIClient.shared) {
        self.modelContext = modelContext
        self.apiClient = apiClient
    }

    // MARK: - Pull (API -> Local)

    func syncAll() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil

        do {
            try await syncExercises()
            try await syncWorkoutLogs()
            try await syncBodyWeights()
            lastSyncDate = Date()
        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
    }

    func syncExercises() async throws {
        let apiExercises = try await apiClient.fetchExercises(workoutType: nil)

        for apiExercise in apiExercises {
            guard let uuid = UUID(uuidString: apiExercise.id) else { continue }

            if let existing = fetchExercise(id: uuid) {
                existing.name = apiExercise.name
                existing.targetWeight = apiExercise.targetWeight
                existing.targetReps = apiExercise.targetReps
                existing.notes = apiExercise.notes
                existing.workoutType = WorkoutType(rawValue: apiExercise.workoutType) ?? .a
                existing.orderIndex = apiExercise.orderIndex
            } else {
                let exercise = Exercise(
                    name: apiExercise.name,
                    targetWeight: apiExercise.targetWeight,
                    targetReps: apiExercise.targetReps,
                    notes: apiExercise.notes,
                    workoutType: WorkoutType(rawValue: apiExercise.workoutType) ?? .a,
                    orderIndex: apiExercise.orderIndex
                )
                exercise.id = uuid
                modelContext.insert(exercise)
            }
        }

        try modelContext.save()
    }

    func syncWorkoutLogs() async throws {
        let apiLogs = try await apiClient.fetchLogs(exerciseId: nil, limit: 100)

        for apiLog in apiLogs {
            guard let uuid = UUID(uuidString: apiLog.id) else { continue }

            if let existing = fetchWorkoutLog(id: uuid) {
                existing.actualWeight = apiLog.actualWeight
                existing.actualReps = apiLog.actualReps
                existing.feeling = apiLog.feeling
                existing.notes = apiLog.notes
                existing.date = APIClient.dateFormatter.date(from: apiLog.date) ?? existing.date
            } else {
                let exerciseUUID = UUID(uuidString: apiLog.exerciseId)
                let exercise: Exercise? = exerciseUUID.flatMap { fetchExercise(id: $0) }
                let date = APIClient.dateFormatter.date(from: apiLog.date) ?? Date()

                let log = WorkoutLog(
                    date: date,
                    actualWeight: apiLog.actualWeight,
                    actualReps: apiLog.actualReps,
                    feeling: apiLog.feeling,
                    notes: apiLog.notes,
                    exercise: exercise
                )
                log.id = uuid
                modelContext.insert(log)
            }
        }

        try modelContext.save()
    }

    func syncBodyWeights() async throws {
        let apiWeights = try await apiClient.fetchBodyWeights(limit: 100)

        for apiWeight in apiWeights {
            guard let uuid = UUID(uuidString: apiWeight.id) else { continue }

            if let existing = fetchBodyWeightEntry(id: uuid) {
                existing.weight = apiWeight.weight
                existing.notes = apiWeight.notes
                existing.date = APIClient.dateFormatter.date(from: apiWeight.date) ?? existing.date
            } else {
                let date = APIClient.dateFormatter.date(from: apiWeight.date) ?? Date()
                let entry = BodyWeightEntry(date: date, weight: apiWeight.weight, notes: apiWeight.notes)
                entry.id = uuid
                modelContext.insert(entry)
            }
        }

        try modelContext.save()
    }

    // MARK: - Push (Local -> API)

    func pushExercise(_ exercise: Exercise) async {
        let request = CreateExerciseRequest(
            id: exercise.id.uuidString,
            name: exercise.name,
            targetWeight: exercise.targetWeight,
            targetReps: exercise.targetReps,
            notes: exercise.notes,
            workoutType: exercise.workoutType.rawValue,
            orderIndex: exercise.orderIndex
        )
        do {
            _ = try await apiClient.createExercise(request)
        } catch {
            print("Failed to push exercise: \(error.localizedDescription)")
        }
    }

    func pushExerciseUpdate(_ exercise: Exercise) async {
        let request = UpdateExerciseRequest(
            name: exercise.name,
            targetWeight: exercise.targetWeight,
            targetReps: exercise.targetReps,
            notes: exercise.notes,
            workoutType: exercise.workoutType.rawValue,
            orderIndex: exercise.orderIndex
        )
        do {
            _ = try await apiClient.updateExercise(id: exercise.id.uuidString, request)
        } catch {
            print("Failed to update exercise: \(error.localizedDescription)")
        }
    }

    func pushWorkoutLog(_ log: WorkoutLog) async {
        guard let exercise = log.exercise else { return }
        let request = CreateWorkoutLogRequest(
            id: log.id.uuidString,
            exerciseId: exercise.id.uuidString,
            date: APIClient.dateFormatter.string(from: log.date),
            actualWeight: log.actualWeight,
            actualReps: log.actualReps,
            feeling: log.feeling,
            notes: log.notes
        )
        do {
            _ = try await apiClient.createLog(request)
        } catch {
            print("Failed to push workout log: \(error.localizedDescription)")
        }
    }

    func pushBodyWeight(_ entry: BodyWeightEntry) async {
        let request = CreateBodyWeightRequest(
            id: entry.id.uuidString,
            date: APIClient.dateFormatter.string(from: entry.date),
            weight: entry.weight,
            notes: entry.notes.isEmpty ? nil : entry.notes
        )
        do {
            _ = try await apiClient.createBodyWeight(request)
        } catch {
            print("Failed to push body weight: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete (Local + API)

    func deleteExercise(id: String) async {
        do {
            try await apiClient.deleteExercise(id: id)
        } catch {
            print("Failed to delete exercise from API: \(error.localizedDescription)")
        }
    }

    func deleteWorkoutLog(id: String) async {
        do {
            try await apiClient.deleteLog(id: id)
        } catch {
            print("Failed to delete log from API: \(error.localizedDescription)")
        }
    }

    func deleteBodyWeight(id: String) async {
        do {
            try await apiClient.deleteBodyWeight(id: id)
        } catch {
            print("Failed to delete body weight from API: \(error.localizedDescription)")
        }
    }

    // MARK: - Database Lookup

    private func fetchExercise(id: UUID) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchWorkoutLog(id: UUID) -> WorkoutLog? {
        let descriptor = FetchDescriptor<WorkoutLog>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchBodyWeightEntry(id: UUID) -> BodyWeightEntry? {
        let descriptor = FetchDescriptor<BodyWeightEntry>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }
}
