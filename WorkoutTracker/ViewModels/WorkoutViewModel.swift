import Foundation
import SwiftData
import SwiftUI

@Observable
class WorkoutViewModel {
    private var modelContext: ModelContext
    
    var exercises: [Exercise] = []
    var recentLogs: [WorkoutLog] = []
    var isSyncing = false
    var syncError: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExercises()
        fetchRecentLogs()
    }
    
    // MARK: - API Sync
    
    @MainActor
    func syncFromAPI() async {
        isSyncing = true
        syncError = nil
        
        do {
            let apiExercises = try await APIClient.shared.fetchExercises()
            
            for apiExercise in apiExercises {
                if let existingExercise = exercises.first(where: { $0.id.uuidString == apiExercise.id }) {
                    existingExercise.name = apiExercise.name
                    existingExercise.targetWeight = apiExercise.targetWeight
                    existingExercise.targetReps = apiExercise.targetReps
                    existingExercise.notes = apiExercise.notes
                    existingExercise.orderIndex = apiExercise.orderIndex
                } else if let uuid = UUID(uuidString: apiExercise.id) {
                    let workoutType = WorkoutType(rawValue: apiExercise.workoutType) ?? .a
                    let newExercise = Exercise(
                        name: apiExercise.name,
                        targetWeight: apiExercise.targetWeight,
                        targetReps: apiExercise.targetReps,
                        notes: apiExercise.notes,
                        workoutType: workoutType,
                        orderIndex: apiExercise.orderIndex
                    )
                    newExercise.id = uuid
                    modelContext.insert(newExercise)
                }
            }
            
            try? modelContext.save()
            fetchExercises()
        } catch {
            syncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func fetchExercises() {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        exercises = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchRecentLogs() {
        let descriptor = FetchDescriptor<WorkoutLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        recentLogs = (try? modelContext.fetch(descriptor)) ?? []
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
    
    func logWorkout(for exercise: Exercise, weight: Double, reps: Int, feeling: Int, notes: String) {
        let log = WorkoutLog(
            actualWeight: weight,
            actualReps: reps,
            feeling: feeling,
            notes: notes,
            exercise: exercise
        )
        modelContext.insert(log)
        try? modelContext.save()
        fetchRecentLogs()
        
        Task {
            await pushLogToAPI(log, exerciseId: exercise.id.uuidString)
        }
    }
    
    @MainActor
    private func pushLogToAPI(_ log: WorkoutLog, exerciseId: String) async {
        let request = CreateWorkoutLogRequest(
            id: log.id.uuidString,
            exerciseId: exerciseId,
            date: ISO8601DateFormatter().string(from: log.date),
            actualWeight: log.actualWeight,
            actualReps: log.actualReps,
            feeling: log.feeling,
            notes: log.notes
        )
        
        do {
            _ = try await APIClient.shared.createLog(request)
        } catch {
            print("Failed to sync log to API: \(error.localizedDescription)")
        }
    }
    
    func updateExerciseTarget(exercise: Exercise, weight: Double, reps: Int) {
        exercise.targetWeight = weight
        exercise.targetReps = reps
        try? modelContext.save()
        fetchExercises()
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
        
        Task {
            await pushExerciseToAPI(exercise)
        }
    }
    
    @MainActor
    private func pushExerciseToAPI(_ exercise: Exercise) async {
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
            _ = try await APIClient.shared.createExercise(request)
        } catch {
            print("Failed to sync exercise to API: \(error.localizedDescription)")
        }
    }
    
    func updateExercise(_ exercise: Exercise, name: String, targetWeight: Double, targetReps: Int, notes: String) {
        exercise.name = name
        exercise.targetWeight = targetWeight
        exercise.targetReps = targetReps
        exercise.notes = notes
        try? modelContext.save()
        fetchExercises()
        
        Task {
            await pushExerciseUpdateToAPI(exercise)
        }
    }
    
    @MainActor
    private func pushExerciseUpdateToAPI(_ exercise: Exercise) async {
        let request = UpdateExerciseRequest(
            name: exercise.name,
            targetWeight: exercise.targetWeight,
            targetReps: exercise.targetReps,
            notes: exercise.notes,
            workoutType: exercise.workoutType.rawValue,
            orderIndex: exercise.orderIndex
        )
        
        do {
            _ = try await APIClient.shared.updateExercise(id: exercise.id.uuidString, request)
        } catch {
            print("Failed to update exercise on API: \(error.localizedDescription)")
        }
    }
    
    func deleteExercise(_ exercise: Exercise) {
        let exerciseId = exercise.id.uuidString
        modelContext.delete(exercise)
        try? modelContext.save()
        fetchExercises()
        
        Task {
            await deleteExerciseFromAPI(exerciseId)
        }
    }
    
    @MainActor
    private func deleteExerciseFromAPI(_ id: String) async {
        do {
            try await APIClient.shared.deleteExercise(id: id)
        } catch {
            print("Failed to delete exercise from API: \(error.localizedDescription)")
        }
    }
}
