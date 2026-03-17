import Foundation
import SwiftData

@Model
final class WorkoutLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var actualWeight: Double
    var actualReps: Int
    var isMachine: Bool
    var feeling: Int
    var notes: String
    
    var exercise: Exercise?
    
    init(
        date: Date = Date(),
        actualWeight: Double,
        actualReps: Int,
        isMachine: Bool = false,
        feeling: Int = 3,
        notes: String = "",
        exercise: Exercise? = nil
    ) {
        self.id = UUID()
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
