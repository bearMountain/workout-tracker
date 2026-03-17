import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
class WorkoutViewModel {
    private var modelContext: ModelContext
    private var syncEngine: SyncEngine

    var exercises: [Exercise] = []
    var recentLogs: [WorkoutLog] = []

    init(modelContext: ModelContext, syncEngine: SyncEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
        fetchExercises()
        fetchRecentLogs()
    }

    var isSyncing: Bool { syncEngine.isSyncing }
    var syncError: String? { syncEngine.syncError }

    func fetchExercises() {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        exercises = ((try? modelContext.fetch(descriptor)) ?? []).filter { !$0.isDeleted }
    }

    func fetchRecentLogs() {
        let descriptor = FetchDescriptor<WorkoutLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        recentLogs = ((try? modelContext.fetch(descriptor)) ?? []).filter { !$0.isDeleted }
    }

    func exercises(for workoutType: WorkoutType) -> [Exercise] {
        exercises.filter { $0.workoutType == workoutType }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    var lastWorkoutDate: Date? {
        recentLogs.first?.date
    }

    var lastWorkoutType: WorkoutType? {
        guard let lastLog = recentLogs.first,
              let exercise = lastLog.exercise else { return nil }
        return exercise.workoutType
    }

    var nextWorkoutType: WorkoutType {
        lastWorkoutType?.next ?? .a
    }

    var daysSinceLastWorkout: Int? {
        guard let lastDate = lastWorkoutDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }

    var nextWorkoutDate: Date? {
        guard let lastDate = lastWorkoutDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: 7, to: lastDate)
    }

    var isWorkoutDue: Bool {
        guard let days = daysSinceLastWorkout else { return true }
        return days >= 7
    }

    func logWorkout(for exercise: Exercise, weight: Double, reps: Int, feeling: Int, notes: String, isMachine: Bool = false) {
        let log = WorkoutLog(
            actualWeight: weight,
            actualReps: reps,
            isMachine: isMachine,
            feeling: feeling,
            notes: notes,
            exercise: exercise
        )
        modelContext.insert(log)
        try? modelContext.save()
        fetchRecentLogs()
        syncEngine.queueForSync(log)
    }

    func updateExerciseTarget(exercise: Exercise, weight: Double, reps: Int) {
        exercise.targetWeight = weight
        exercise.targetReps = reps
        exercise.markDirty()
        try? modelContext.save()
        fetchExercises()
        syncEngine.queueForSync(exercise)
    }

    // MARK: - Exercise CRUD

    func addExercise(name: String, targetWeight: Double, targetReps: Int, notes: String, workoutType: WorkoutType) {
        let maxIndex = exercises.filter { $0.workoutType == workoutType }.map { $0.orderIndex }.max() ?? -1
        let exercise = Exercise(
            name: name,
            targetWeight: targetWeight,
            targetReps: targetReps,
            notes: notes,
            workoutType: workoutType,
            orderIndex: maxIndex + 1
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        fetchExercises()
        syncEngine.queueForSync(exercise)
    }

    func updateExercise(_ exercise: Exercise, name: String, targetWeight: Double, targetReps: Int, notes: String) {
        exercise.name = name
        exercise.targetWeight = targetWeight
        exercise.targetReps = targetReps
        exercise.notes = notes
        exercise.markDirty()
        try? modelContext.save()
        fetchExercises()
        syncEngine.queueForSync(exercise)
    }

    func deleteExercise(_ exercise: Exercise) {
        exercise.markDeleted()
        exercise.logs?.forEach { $0.markDeleted() }
        try? modelContext.save()
        fetchExercises()
        fetchRecentLogs()
        syncEngine.queueForSync(exercise)
        exercise.logs?.forEach { syncEngine.queueForSync($0) }
    }
}
