import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var targetWeight: Double
    var targetReps: Int
    var notes: String
    var workoutTypeRaw: String
    var orderIndex: Int
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.exercise)
    var logs: [WorkoutLog]?
    
    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .a }
        set { workoutTypeRaw = newValue.rawValue }
    }
    
    init(
        name: String,
        targetWeight: Double,
        targetReps: Int,
        notes: String = "",
        workoutType: WorkoutType,
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.notes = notes
        self.workoutTypeRaw = workoutType.rawValue
        self.orderIndex = orderIndex
        self.logs = []
    }
    
    var latestLog: WorkoutLog? {
        logs?.sorted { ($0.date) > ($1.date) }.first
    }
    
    var hasImproved: Bool {
        guard let logs = logs, logs.count >= 2 else { return false }
        let sorted = logs.sorted { $0.date > $1.date }
        let latest = sorted[0]
        let previous = sorted[1]
        return latest.actualWeight > previous.actualWeight || 
               (latest.actualWeight == previous.actualWeight && latest.actualReps > previous.actualReps)
    }
}
