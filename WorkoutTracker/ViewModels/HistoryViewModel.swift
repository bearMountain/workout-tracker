import Foundation
import SwiftData
import SwiftUI

// MARK: - Grouped Data Structures

struct ExerciseSets: Identifiable {
    let id = UUID()
    let exerciseName: String
    let workoutType: WorkoutType
    let targetWeight: Double
    let targetReps: Int
    let sets: [WorkoutLog]
    
    var metAllTargets: Bool {
        sets.allSatisfy { $0.metTarget }
    }
}

struct WorkoutSession: Identifiable {
    let id = UUID()
    let date: Date
    let workoutType: WorkoutType?
    let exercises: [ExerciseSets]
    
    var formattedDate: String {
        date.formatted(date: .complete, time: .omitted)
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}

@Observable
class HistoryViewModel {
    private var modelContext: ModelContext
    
    var logs: [WorkoutLog] = []
    var sessions: [WorkoutSession] = []
    var isSyncing = false
    var syncError: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchLogs()
    }
    
    // MARK: - API Sync
    
    @MainActor
    func syncFromAPI() async {
        isSyncing = true
        syncError = nil
        
        do {
            let apiLogs = try await APIClient.shared.fetchLogs()
            
            let exerciseDescriptor = FetchDescriptor<Exercise>()
            let exercises = (try? modelContext.fetch(exerciseDescriptor)) ?? []
            
            for apiLog in apiLogs {
                let logExists = logs.contains { $0.id.uuidString == apiLog.id }
                
                if !logExists, let uuid = UUID(uuidString: apiLog.id) {
                    let exercise = exercises.first { $0.id.uuidString == apiLog.exerciseId }
                    
                    let dateFormatter = ISO8601DateFormatter()
                    let date = dateFormatter.date(from: apiLog.date) ?? Date()
                    
                    let newLog = WorkoutLog(
                        date: date,
                        actualWeight: apiLog.actualWeight,
                        actualReps: apiLog.actualReps,
                        feeling: apiLog.feeling,
                        notes: apiLog.notes,
                        exercise: exercise
                    )
                    newLog.id = uuid
                    modelContext.insert(newLog)
                }
            }
            
            try? modelContext.save()
            fetchLogs()
        } catch {
            syncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func fetchLogs() {
        let descriptor = FetchDescriptor<WorkoutLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        logs = (try? modelContext.fetch(descriptor)) ?? []
        buildSessions()
    }
    
    private func buildSessions() {
        let calendar = Calendar.current
        
        let groupedByDate = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.date)
        }
        
        sessions = groupedByDate.map { (date, logsForDate) in
            let groupedByExercise = Dictionary(grouping: logsForDate) { log in
                log.exercise?.id ?? UUID()
            }
            
            let exerciseSets = groupedByExercise.compactMap { (_, exerciseLogs) -> ExerciseSets? in
                guard let firstLog = exerciseLogs.first,
                      let exercise = firstLog.exercise else { return nil }
                
                let sortedSets = exerciseLogs.sorted { $0.date < $1.date }
                
                return ExerciseSets(
                    exerciseName: exercise.name,
                    workoutType: exercise.workoutType,
                    targetWeight: exercise.targetWeight,
                    targetReps: exercise.targetReps,
                    sets: sortedSets
                )
            }.sorted { $0.exerciseName < $1.exerciseName }
            
            let workoutType = exerciseSets.first?.workoutType
            
            return WorkoutSession(
                date: date,
                workoutType: workoutType,
                exercises: exerciseSets
            )
        }.sorted { $0.date > $1.date }
    }
    
    func deleteLog(_ log: WorkoutLog) {
        modelContext.delete(log)
        try? modelContext.save()
        fetchLogs()
    }
    
    var workoutDates: Set<Date> {
        Set(logs.map { Calendar.current.startOfDay(for: $0.date) })
    }
    
    func hasWorkout(on date: Date) -> Bool {
        workoutDates.contains(Calendar.current.startOfDay(for: date))
    }
}
