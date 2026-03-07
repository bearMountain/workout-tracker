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
@MainActor
class HistoryViewModel {
    private var modelContext: ModelContext
    private var syncEngine: SyncEngine

    var logs: [WorkoutLog] = []
    var sessions: [WorkoutSession] = []

    var isSyncing: Bool { syncEngine.isSyncing }
    var syncError: String? { syncEngine.syncError }

    init(modelContext: ModelContext, syncEngine: SyncEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
        fetchLogs()
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
        let logId = log.id.uuidString
        modelContext.delete(log)
        try? modelContext.save()
        fetchLogs()

        Task {
            await syncEngine.deleteWorkoutLog(id: logId)
        }
    }

    func deleteSession(_ session: WorkoutSession) {
        let logIds = session.exercises.flatMap { $0.sets.map { $0.id.uuidString } }

        for exerciseSets in session.exercises {
            for log in exerciseSets.sets {
                modelContext.delete(log)
            }
        }
        try? modelContext.save()
        fetchLogs()

        Task {
            for logId in logIds {
                await syncEngine.deleteWorkoutLog(id: logId)
            }
        }
    }

    var workoutDates: Set<Date> {
        Set(logs.map { Calendar.current.startOfDay(for: $0.date) })
    }

    func hasWorkout(on date: Date) -> Bool {
        workoutDates.contains(Calendar.current.startOfDay(for: date))
    }
}
