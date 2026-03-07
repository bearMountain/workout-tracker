import Foundation
import SwiftData
import SwiftUI

struct ExerciseDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let reps: Int
}

struct BodyWeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

enum DateRange: String, CaseIterable {
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
    case allTime = "All Time"

    var days: Int? {
        switch self {
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime: return nil
        }
    }
}

@Observable
@MainActor
class ProgressViewModel {
    private var modelContext: ModelContext
    private var syncEngine: SyncEngine

    var exercises: [Exercise] = []
    var bodyWeightEntries: [BodyWeightEntry] = []
    var selectedExercise: Exercise?
    var selectedDateRange: DateRange = .thirtyDays

    var isSyncing: Bool { syncEngine.isSyncing }
    var syncError: String? { syncEngine.syncError }

    init(modelContext: ModelContext, syncEngine: SyncEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
        fetchData()
    }

    // MARK: - Data Fetching

    func fetchData() {
        fetchExercises()
        fetchBodyWeightEntries()
    }

    private func fetchExercises() {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        exercises = (try? modelContext.fetch(descriptor)) ?? []
        if selectedExercise == nil {
            selectedExercise = exercises.first
        }
    }

    private func fetchBodyWeightEntries() {
        let descriptor = FetchDescriptor<BodyWeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        bodyWeightEntries = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Exercise Progress Data

    func chartData(for exercise: Exercise) -> [ExerciseDataPoint] {
        guard let logs = exercise.logs else { return [] }

        let filteredLogs = filterByDateRange(logs)
        let grouped = Dictionary(grouping: filteredLogs) { log in
            Calendar.current.startOfDay(for: log.date)
        }

        return grouped.map { date, dayLogs in
            let maxWeight = dayLogs.map(\.actualWeight).max() ?? 0
            let maxReps = dayLogs.filter { $0.actualWeight == maxWeight }.map(\.actualReps).max() ?? 0
            return ExerciseDataPoint(date: date, weight: maxWeight, reps: maxReps)
        }
        .sorted { $0.date < $1.date }
    }

    private func filterByDateRange(_ logs: [WorkoutLog]) -> [WorkoutLog] {
        guard let days = selectedDateRange.days else { return logs }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return logs.filter { $0.date >= cutoffDate }
    }

    // MARK: - Exercise Stats

    func personalBest(for exercise: Exercise) -> (weight: Double, reps: Int)? {
        guard let logs = exercise.logs, !logs.isEmpty else { return nil }
        let maxWeight = logs.map(\.actualWeight).max() ?? 0
        let maxReps = logs.filter { $0.actualWeight == maxWeight }.map(\.actualReps).max() ?? 0
        return (maxWeight, maxReps)
    }

    func isNewPersonalBest(for exercise: Exercise) -> Bool {
        guard let logs = exercise.logs, logs.count >= 2 else { return false }
        let sorted = logs.sorted { $0.date > $1.date }
        guard let latest = sorted.first else { return false }
        let previousMax = sorted.dropFirst().map(\.actualWeight).max() ?? 0
        return latest.actualWeight > previousMax
    }

    func weightTrend(for exercise: Exercise) -> Double? {
        let data = chartData(for: exercise)
        guard data.count >= 2 else { return nil }
        let first = data.first!.weight
        let last = data.last!.weight
        guard first > 0 else { return nil }
        return ((last - first) / first) * 100
    }

    func repsTrend(for exercise: Exercise) -> Double? {
        let data = chartData(for: exercise)
        guard data.count >= 2 else { return nil }
        let first = Double(data.first!.reps)
        let last = Double(data.last!.reps)
        guard first > 0 else { return nil }
        return ((last - first) / first) * 100
    }

    // MARK: - Body Weight Data

    var bodyWeightChartData: [BodyWeightDataPoint] {
        let filtered = filterBodyWeightByDateRange(bodyWeightEntries)
        return filtered.map { entry in
            BodyWeightDataPoint(date: entry.date, weight: entry.weight)
        }
        .sorted { $0.date < $1.date }
    }

    private func filterBodyWeightByDateRange(_ entries: [BodyWeightEntry]) -> [BodyWeightEntry] {
        guard let days = selectedDateRange.days else { return entries }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoffDate }
    }

    var latestBodyWeight: BodyWeightEntry? {
        bodyWeightEntries.first
    }

    var bodyWeightEntryCount: Int {
        bodyWeightEntries.count
    }

    var bodyWeightTrend: Double? {
        let data = bodyWeightChartData
        guard data.count >= 2 else { return nil }
        let first = data.first!.weight
        let last = data.last!.weight
        guard first > 0 else { return nil }
        return ((last - first) / first) * 100
    }

    var lowestBodyWeight: Double? {
        bodyWeightEntries.map(\.weight).min()
    }

    var highestBodyWeight: Double? {
        bodyWeightEntries.map(\.weight).max()
    }

    // MARK: - Body Weight CRUD

    func addBodyWeight(weight: Double, date: Date = Date(), notes: String = "") {
        let entry = BodyWeightEntry(date: date, weight: weight, notes: notes)
        modelContext.insert(entry)
        try? modelContext.save()
        fetchBodyWeightEntries()

        Task {
            await syncEngine.pushBodyWeight(entry)
        }
    }

    func deleteBodyWeight(_ entry: BodyWeightEntry) {
        let entryId = entry.id.uuidString
        modelContext.delete(entry)
        try? modelContext.save()
        fetchBodyWeightEntries()

        Task {
            await syncEngine.deleteBodyWeight(id: entryId)
        }
    }

    // MARK: - Streak Tracking

    func workoutStreak(for exercise: Exercise) -> Int {
        guard let logs = exercise.logs, !logs.isEmpty else { return 0 }

        let sortedDates = logs.map { Calendar.current.startOfDay(for: $0.date) }
            .sorted(by: >)
            .uniqued()

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for date in sortedDates {
            let daysDiff = Calendar.current.dateComponents([.day], from: date, to: expectedDate).day ?? 0

            if daysDiff <= 7 {
                streak += 1
                expectedDate = date
            } else {
                break
            }
        }

        return streak
    }

    var bodyWeightStreak: Int {
        guard !bodyWeightEntries.isEmpty else { return 0 }

        let sortedDates = bodyWeightEntries.map { Calendar.current.startOfDay(for: $0.date) }
            .sorted(by: >)
            .uniqued()

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for date in sortedDates {
            let daysDiff = Calendar.current.dateComponents([.day], from: date, to: expectedDate).day ?? 0

            if daysDiff <= 7 {
                streak += 1
                expectedDate = date
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Motivational Messages

    private let encouragingMessages = [
        "You're crushing it!",
        "Keep up the momentum!",
        "Every rep counts!",
        "Stronger every day!",
        "Progress, not perfection!",
        "Champion mindset!",
        "Gains incoming!",
        "Beast mode activated!"
    ]

    func motivationalMessage(for exercise: Exercise) -> String? {
        if isNewPersonalBest(for: exercise) {
            return "New Personal Best! You're unstoppable!"
        }

        if let trend = weightTrend(for: exercise), trend > 10 {
            return "Incredible progress! +\(Int(trend))% stronger!"
        }

        if let trend = weightTrend(for: exercise), trend > 0 {
            return "Great progress! Keep pushing!"
        }

        let streak = workoutStreak(for: exercise)
        if streak >= 4 {
            return "\(streak) week streak! Consistency is key!"
        }

        if let logs = exercise.logs, logs.count >= 10 {
            return encouragingMessages.randomElement() ?? "Keep going!"
        }

        if let logs = exercise.logs, logs.count >= 5 {
            return "Building momentum!"
        }

        return nil
    }

    var bodyWeightMotivationalMessage: String? {
        guard let trend = bodyWeightTrend else {
            if bodyWeightEntries.count == 1 {
                return "Great start! Keep logging!"
            }
            return nil
        }

        if abs(trend) < 0.5 {
            return "Steady and consistent!"
        } else if trend < -3 {
            return "Amazing progress! Keep it up!"
        } else if trend < 0 {
            return "Making progress!"
        } else if trend > 3 {
            return "Building strength!"
        } else {
            return "Staying strong!"
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
