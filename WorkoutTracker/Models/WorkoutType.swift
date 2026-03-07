import Foundation

enum WorkoutType: String, Codable, CaseIterable {
    case a = "A"
    case b = "B"
    
    var displayName: String {
        switch self {
        case .a: return "A: Legs"
        case .b: return "B: Deadlift + Upper Body"
        }
    }
    
    var description: String {
        switch self {
        case .a: return "Legs"
        case .b: return "Deadlift + Upper Body"
        }
    }
    
    var iconName: String {
        switch self {
        case .a: return "figure.walk"
        case .b: return "figure.arms.open"
        }
    }
    
    var next: WorkoutType {
        switch self {
        case .a: return .b
        case .b: return .a
        }
    }
}
