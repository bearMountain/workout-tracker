import Foundation
import SwiftData

@Model
final class WorkoutLog: SyncableModel {
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
    var date: Date
    var actualWeight: Double
    var actualReps: Int
    var isMachine: Bool
    var feeling: Int
    var notes: String
    
    var exercise: Exercise?
    
    static let entityKind: SyncEntityKind = .workoutLog
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        actualWeight: Double,
        actualReps: Int,
        isMachine: Bool = false,
        feeling: Int = 3,
        notes: String = "",
        exercise: Exercise? = nil
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
        self.lastModifiedAt = date
        self.isDeleted = false
        self.deletedAt = nil
        self.date = date
        self.actualWeight = actualWeight
        self.actualReps = actualReps
        self.isMachine = isMachine
        self.feeling = min(4, max(1, feeling))
        self.notes = notes
        self.exercise = exercise
    }
    
    var feelingLabel: String {
        switch feeling {
        case 1: return "warmup"
        case 2: return "easy work"
        case 3: return "hard but got it"
        case 4: return "0 RIR"
        default: return "hard but got it"
        }
    }
    
    var formattedWeightLabel: String {
        let weightLabel: String
        if actualWeight == 0 {
            weightLabel = "BW"
        } else if actualWeight.rounded(.towardZero) == actualWeight {
            weightLabel = String(Int(actualWeight))
        } else {
            weightLabel = String(format: "%.1f", actualWeight)
        }
        
        return isMachine ? "\(weightLabel)M" : weightLabel
    }
    
    var formattedSetLabel: String {
        "\(formattedWeightLabel) × \(actualReps)"
    }
    
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var metTarget: Bool {
        guard let exercise = exercise else { return false }
        return actualWeight >= exercise.targetWeight && actualReps >= exercise.targetReps
    }
}
