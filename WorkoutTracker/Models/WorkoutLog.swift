import Foundation
import SwiftData

@Model
final class WorkoutLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var actualWeight: Double
    var actualReps: Int
    var feeling: Int
    var notes: String
    
    var exercise: Exercise?
    
    init(
        date: Date = Date(),
        actualWeight: Double,
        actualReps: Int,
        feeling: Int = 3,
        notes: String = "",
        exercise: Exercise? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.actualWeight = actualWeight
        self.actualReps = actualReps
        self.feeling = min(5, max(1, feeling))
        self.notes = notes
        self.exercise = exercise
    }
    
    var feelingEmoji: String {
        switch feeling {
        case 1: return "😫"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "💪"
        default: return "😐"
        }
    }
    
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var metTarget: Bool {
        guard let exercise = exercise else { return false }
        return actualWeight >= exercise.targetWeight && actualReps >= exercise.targetReps
    }
}
