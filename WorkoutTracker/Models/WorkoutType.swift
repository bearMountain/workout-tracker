import Foundation

enum WorkoutType: String, Codable, CaseIterable {
    case a = "A"
    case b = "B"
    
    var displayName: String {
        switch self {
        case .a: return "Workout A"
        case .b: return "Workout B"
        }
    }
    
    var description: String {
        switch self {
        case .a: return "Legs & Calves"
        case .b: return "Upper Body"
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
