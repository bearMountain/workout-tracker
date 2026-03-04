import Foundation
import SwiftData
import SwiftUI

@Observable
class HistoryViewModel {
    private var modelContext: ModelContext
    
    var logs: [WorkoutLog] = []
    var groupedLogs: [Date: [WorkoutLog]] = [:]
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
        groupLogsByDate()
    }
    
    private func groupLogsByDate() {
        groupedLogs = Dictionary(grouping: logs) { log in
            Calendar.current.startOfDay(for: log.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedLogs.keys.sorted(by: >)
    }
    
    func logs(for date: Date) -> [WorkoutLog] {
        groupedLogs[date] ?? []
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
