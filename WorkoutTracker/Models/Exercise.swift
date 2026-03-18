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
        (logs ?? []).filter { !$0.isDeleted }
    }

    var latestLog: WorkoutLog? {
        activeLogs.sorted { $0.date > $1.date }.first
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
