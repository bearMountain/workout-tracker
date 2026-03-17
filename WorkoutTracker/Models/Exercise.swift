import Foundation
import SwiftData

@Model
final class Exercise: SyncableModel {
    @Attribute(.unique) var id: UUID
    var localID: UUID = UUID()
    var remoteID: String? = nil
    var serverVersion: Int = 0
    var isDirty: Bool = true
    var lastSyncAttempt: Date? = nil
    var syncError: String? = nil
    var idempotencyKey: UUID = UUID()
    var retryCount: Int = 0
    var lastModifiedAt: Date = Date()
    var isDeleted: Bool = false
    var deletedAt: Date? = nil
    var name: String
    var targetWeight: Double
    var targetReps: Int
    var notes: String
    var workoutTypeRaw: String
    var orderIndex: Int
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.exercise)
    var logs: [WorkoutLog]?
    
    static let entityKind: SyncEntityKind = .exercise
    
    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .a }
        set { workoutTypeRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        targetWeight: Double,
        targetReps: Int,
        notes: String = "",
        workoutType: WorkoutType,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.localID = id
        self.remoteID = nil
        self.serverVersion = 0
        self.isDirty = true
        self.lastSyncAttempt = nil
        self.syncError = nil
        self.idempotencyKey = UUID()
        self.retryCount = 0
        self.lastModifiedAt = Date()
        self.isDeleted = false
        self.deletedAt = nil
        self.name = name
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.notes = notes
        self.workoutTypeRaw = workoutType.rawValue
        self.orderIndex = orderIndex
        self.logs = []
    }
    
    var activeLogs: [WorkoutLog] {
        (logs ?? []).filter { !$0.isDeleted }
    }
    
    var latestLog: WorkoutLog? {
        activeLogs.sorted { ($0.date) > ($1.date) }.first
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
