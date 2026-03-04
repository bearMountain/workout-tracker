import Foundation
import SwiftData
import SwiftUI

@Observable
class WorkoutViewModel {
    private var modelContext: ModelContext
    
    var exercises: [Exercise] = []
    var recentLogs: [WorkoutLog] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExercises()
        fetchRecentLogs()
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
    }
    
    func updateExerciseTarget(exercise: Exercise, weight: Double, reps: Int) {
        exercise.targetWeight = weight
        exercise.targetReps = reps
        try? modelContext.save()
        fetchExercises()
    }
}
