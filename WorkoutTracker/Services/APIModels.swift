import Foundation

// MARK: - API Error

struct APIError: Codable {
    let error: String
}

// MARK: - Exercise

struct APIExercise: Codable {
    let id: String
    let name: String
    let targetWeight: Double
    let targetReps: Int
    let notes: String
    let workoutType: String
    let orderIndex: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case workoutType = "workout_type"
        case orderIndex = "order_index"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateExerciseRequest: Codable {
    let id: String?
    let name: String
    let targetWeight: Double
    let targetReps: Int
    let notes: String
    let workoutType: String
    let orderIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case workoutType = "workout_type"
        case orderIndex = "order_index"
    }
}

struct UpdateExerciseRequest: Codable {
    let name: String?
    let targetWeight: Double?
    let targetReps: Int?
    let notes: String?
    let workoutType: String?
    let orderIndex: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, notes
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case workoutType = "workout_type"
        case orderIndex = "order_index"
    }
}

// MARK: - Workout Log

struct APIWorkoutLog: Codable {
    let id: String
    let exerciseId: String
    let date: String
    let actualWeight: Double
    let actualReps: Int
    let feeling: Int
    let notes: String
    let createdAt: String
    let exerciseName: String?
    let workoutType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, notes, feeling
        case exerciseId = "exercise_id"
        case actualWeight = "actual_weight"
        case actualReps = "actual_reps"
        case createdAt = "created_at"
        case exerciseName = "exercise_name"
        case workoutType = "workout_type"
    }
}

struct CreateWorkoutLogRequest: Codable {
    let id: String?
    let exerciseId: String
    let date: String?
    let actualWeight: Double
    let actualReps: Int
    let feeling: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, notes, feeling
        case exerciseId = "exercise_id"
        case actualWeight = "actual_weight"
        case actualReps = "actual_reps"
    }
}

struct UpdateWorkoutLogRequest: Codable {
    let date: String?
    let actualWeight: Double?
    let actualReps: Int?
    let feeling: Int?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case date, notes, feeling
        case actualWeight = "actual_weight"
        case actualReps = "actual_reps"
    }
}

// MARK: - Content Note

struct APIContentNote: Codable {
    let id: String
    let title: String
    let body: String
    let url: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, url
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateContentNoteRequest: Codable {
    let title: String
    let body: String?
    let url: String?
}

struct UpdateContentNoteRequest: Codable {
    let title: String?
    let body: String?
    let url: String?
}

// MARK: - Body Weight

struct APIBodyWeight: Codable {
    let id: String
    let date: String
    let weight: Double
    let notes: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, date, weight, notes
        case createdAt = "created_at"
    }
}

struct CreateBodyWeightRequest: Codable {
    let id: String?
    let date: String?
    let weight: Double
    let notes: String?
}

struct UpdateBodyWeightRequest: Codable {
    let date: String?
    let weight: Double?
    let notes: String?
}




