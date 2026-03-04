import Foundation
import SwiftData
import SwiftUI

@Observable
class HistoryViewModel {
    private var modelContext: ModelContext
    
    var logs: [WorkoutLog] = []
    var groupedLogs: [Date: [WorkoutLog]] = [:]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchLogs()
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
