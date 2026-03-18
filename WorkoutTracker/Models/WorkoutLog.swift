import Foundation
import SwiftData

extension WorkoutLog: SyncableModel {
    static let entityKind: SyncEntityKind = .workoutLog
}

extension WorkoutLog {
    var feelingLabel: String {
        switch feeling {
        case 1: return "warmup"
        case 2: return "medium"
        case 3: return "hard"
        case 4: return "0 RIR"
        default: return "hard"
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
        let matchesEquipment = isMachine == exercise.isMachine
        return matchesEquipment && actualWeight >= exercise.targetWeight && actualReps >= exercise.targetReps
    }
}
