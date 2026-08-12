import Foundation
import SwiftData

extension Exercise: SyncableModel {
    static let entityKind: SyncEntityKind = .exercise
}

extension Exercise {
    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .a }
        set { workoutTypeRaw = newValue.rawValue }
    }

    var activeLogs: [WorkoutLog] {
        (logs ?? []).filter { !$0.isSoftDeleted }
    }

    var latestLog: WorkoutLog? {
        activeLogs.sorted { $0.date > $1.date }.first
    }

    var bestLog: WorkoutLog? {
        Self.bestLog(in: activeLogs)
    }

    struct PlannedSet: Equatable {
        var weight: Double
        var reps: Int
        var isMachine: Bool
    }

    var plannedSet: PlannedSet {
        Self.plannedSet(
            in: activeLogs,
            fallbackWeight: targetWeight,
            fallbackReps: targetReps,
            fallbackIsMachine: isMachine
        )
    }

    static func plannedSet(
        in logs: [WorkoutLog],
        fallbackWeight: Double,
        fallbackReps: Int,
        fallbackIsMachine: Bool,
        before date: Date = Date(),
        calendar: Calendar = .current
    ) -> PlannedSet {
        if let last = bestLogFromLastWorkoutDay(in: logs, before: date, calendar: calendar) {
            return PlannedSet(
                weight: last.actualWeight,
                reps: last.actualReps,
                isMachine: last.isMachine
            )
        }

        return PlannedSet(
            weight: fallbackWeight,
            reps: fallbackReps,
            isMachine: fallbackIsMachine
        )
    }

    static func bestLog(in logs: [WorkoutLog]) -> WorkoutLog? {
        logs.filter { !$0.isSoftDeleted }.max { lhs, rhs in
            if lhs.actualWeight == rhs.actualWeight {
                if lhs.actualReps == rhs.actualReps {
                    return lhs.date < rhs.date
                }

                return lhs.actualReps < rhs.actualReps
            }

            return lhs.actualWeight < rhs.actualWeight
        }
    }

    static func bestLogFromLastWorkoutDay(
        in logs: [WorkoutLog],
        before date: Date = Date(),
        calendar: Calendar = .current
    ) -> WorkoutLog? {
        let currentDay = calendar.startOfDay(for: date)
        let previousLogs = logs.filter {
            !$0.isSoftDeleted && calendar.startOfDay(for: $0.date) < currentDay
        }

        guard let lastWorkoutDay = previousLogs
            .map({ calendar.startOfDay(for: $0.date) })
            .max()
        else {
            return nil
        }

        return bestLog(in: previousLogs.filter {
            calendar.isDate($0.date, inSameDayAs: lastWorkoutDay)
        })
    }

    var todaysLogs: [WorkoutLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return activeLogs
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date < $1.date }
    }

    var hasImproved: Bool {
        guard activeLogs.count >= 2 else { return false }
        let sorted = activeLogs.sorted { $0.date > $1.date }
        let latest = sorted[0]
        let previous = sorted[1]
        return latest.actualWeight > previous.actualWeight ||
            (latest.actualWeight == previous.actualWeight && latest.actualReps > previous.actualReps)
    }
}
