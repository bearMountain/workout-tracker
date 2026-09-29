import Foundation
import SwiftData

enum ProgressiveOverloadRules {
    static let repTargetLowerBound = 6
    static let repTargetHit = 8
    static let loadIncreasePounds = 5.0
    static let repTargetLabel = "6–8"

    /// One-time defaults for exercises that already exist. Cue, highlight, and the +5 lb weight default read the checkbox only.
    static let seedNames: Set<String> = [
        "Squats",
        "Dead Lift",
        "Leg Extensions",
        "Pec Deck",
        "Bench Press"
    ]

    static func hitRepTarget(reps: Int) -> Bool {
        reps >= repTargetHit
    }
}

enum ProgressiveOverloadSeed {
    static let defaultsKey = "progressiveOverload.seededExerciseNames.v1"

    @discardableResult
    static func applyIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) -> Bool {
        guard !defaults.bool(forKey: defaultsKey) else { return false }

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        for exercise in exercises where shouldSeed(exercise) {
            exercise.progressiveOverload = true
        }
        try? context.save()
        defaults.set(true, forKey: defaultsKey)
        return true
    }

    private static func shouldSeed(_ exercise: Exercise) -> Bool {
        !exercise.isSoftDeleted
            && !exercise.progressiveOverload
            && ProgressiveOverloadRules.seedNames.contains(exercise.name)
    }
}

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

    static func loggingSet(
        progressiveOverload: Bool,
        logs: [WorkoutLog],
        fallbackWeight: Double,
        fallbackReps: Int,
        fallbackIsMachine: Bool,
        before date: Date = Date(),
        calendar: Calendar = .current
    ) -> PlannedSet {
        let plan = plannedSet(
            in: logs,
            fallbackWeight: fallbackWeight,
            fallbackReps: fallbackReps,
            fallbackIsMachine: fallbackIsMachine,
            before: date,
            calendar: calendar
        )
        guard promptsLoadIncrease(
            progressiveOverload: progressiveOverload,
            logs: logs,
            before: date,
            calendar: calendar
        ),
        let best = bestLogFromLastWorkoutDay(in: logs, before: date, calendar: calendar)
        else {
            return plan
        }

        return PlannedSet(
            weight: best.actualWeight + ProgressiveOverloadRules.loadIncreasePounds,
            reps: plan.reps,
            isMachine: plan.isMachine
        )
    }

    static func promptsLoadIncrease(
        progressiveOverload: Bool,
        logs: [WorkoutLog],
        before date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard progressiveOverload else { return false }
        guard let best = bestLogFromLastWorkoutDay(in: logs, before: date, calendar: calendar) else {
            return false
        }
        return logs.contains { log in
            !log.isSoftDeleted
                && calendar.isDate(log.date, inSameDayAs: best.date)
                && ProgressiveOverloadRules.hitRepTarget(reps: log.actualReps)
        }
    }

    static func reachedRepTarget(
        progressiveOverload: Bool,
        logs: [WorkoutLog],
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard progressiveOverload else { return false }
        return logs.contains { log in
            !log.isSoftDeleted
                && calendar.isDate(log.date, inSameDayAs: date)
                && ProgressiveOverloadRules.hitRepTarget(reps: log.actualReps)
        }
    }

    var loggingSet: PlannedSet {
        Self.loggingSet(
            progressiveOverload: progressiveOverload,
            logs: activeLogs,
            fallbackWeight: targetWeight,
            fallbackReps: targetReps,
            fallbackIsMachine: isMachine
        )
    }

    var promptsLoadIncrease: Bool {
        Self.promptsLoadIncrease(progressiveOverload: progressiveOverload, logs: activeLogs)
    }

    var reachedRepTargetToday: Bool {
        Self.reachedRepTarget(progressiveOverload: progressiveOverload, logs: activeLogs)
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
