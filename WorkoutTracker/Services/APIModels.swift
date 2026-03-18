import Foundation

// MARK: - API Error

struct APIError: Codable {
    let error: String
}

protocol APISyncMutationRequest {
    var idempotencyKey: String { get }
}

// MARK: - Exercise

struct APIExercise: Codable {
    let id: String
    let name: String
    let targetWeight: Double
    let targetReps: Int
    let isMachine: Bool?
    let notes: String
    let workoutType: String
    let orderIndex: Int
    let clientUpdatedAt: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let serverVersion: Int?
    let lastIdempotencyKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case isMachine = "is_machine"
        case workoutType = "workout_type"
        case orderIndex = "order_index"
        case clientUpdatedAt = "client_updated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case serverVersion = "server_version"
        case lastIdempotencyKey = "last_idempotency_key"
    }
}

struct CreateExerciseRequest: Codable, APISyncMutationRequest {
    let id: String?
    let name: String
    let targetWeight: Double
    let targetReps: Int
    let isMachine: Bool
    let notes: String
    let workoutType: String
    let orderIndex: Int
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, notes
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case isMachine = "is_machine"
        case workoutType = "workout_type"
        case orderIndex = "order_index"
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}

struct UpdateExerciseRequest: Codable, APISyncMutationRequest {
    let name: String?
    let targetWeight: Double?
    let targetReps: Int?
    let isMachine: Bool?
    let notes: String?
    let workoutType: String?
    let orderIndex: Int?
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case name, notes
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case isMachine = "is_machine"
        case workoutType = "workout_type"
        case orderIndex = "order_index"
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Workout Log

struct APIWorkoutLog: Codable {
    let id: String
    let exerciseId: String
    let date: String
    let actualWeight: Double
    let actualReps: Int
    let isMachine: Bool?
    let feeling: Int
    let notes: String
    let clientUpdatedAt: String?
    let createdAt: String
    let updatedAt: String?
    let deletedAt: String?
    let serverVersion: Int?
    let lastIdempotencyKey: String?
    let exerciseName: String?
    let workoutType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, notes, feeling
        case exerciseId = "exercise_id"
        case actualWeight = "actual_weight"
        case actualReps = "actual_reps"
        case isMachine = "is_machine"
        case clientUpdatedAt = "client_updated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case serverVersion = "server_version"
        case lastIdempotencyKey = "last_idempotency_key"
        case exerciseName = "exercise_name"
        case workoutType = "workout_type"
    }
}

struct CreateWorkoutLogRequest: Codable, APISyncMutationRequest {
    let id: String?
    let exerciseId: String
    let date: String?
    let actualWeight: Double
    let actualReps: Int
    let isMachine: Bool?
    let feeling: Int
    let notes: String?
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, notes, feeling
        case exerciseId = "exercise_id"
        case actualWeight = "actual_weight"
        case actualReps = "actual_reps"
        case isMachine = "is_machine"
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}

struct UpdateWorkoutLogRequest: Codable, APISyncMutationRequest {
    let date: String?
    let actualWeight: Double?
    let actualReps: Int?
    let isMachine: Bool?
    let feeling: Int?
    let notes: String?
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case date, notes, feeling
        case actualWeight = "actual_weight"
        case actualReps = "actual_reps"
        case isMachine = "is_machine"
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Content Note

struct APIContentNote: Codable {
    let id: String
    let title: String
    let body: String
    let url: String
    let clientUpdatedAt: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let serverVersion: Int?
    let lastIdempotencyKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, url
        case clientUpdatedAt = "client_updated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case serverVersion = "server_version"
        case lastIdempotencyKey = "last_idempotency_key"
    }
}

struct CreateContentNoteRequest: Codable, APISyncMutationRequest {
    let id: String?
    let title: String
    let body: String?
    let url: String?
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, url
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}

struct UpdateContentNoteRequest: Codable, APISyncMutationRequest {
    let title: String?
    let body: String?
    let url: String?
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case title, body, url
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Body Weight

struct APIBodyWeight: Codable {
    let id: String
    let date: String
    let weight: Double
    let notes: String
    let clientUpdatedAt: String?
    let createdAt: String
    let updatedAt: String?
    let deletedAt: String?
    let serverVersion: Int?
    let lastIdempotencyKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, weight, notes
        case clientUpdatedAt = "client_updated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case serverVersion = "server_version"
        case lastIdempotencyKey = "last_idempotency_key"
    }
}

struct CreateBodyWeightRequest: Codable, APISyncMutationRequest {
    let id: String?
    let date: String?
    let weight: Double
    let notes: String?
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, weight, notes
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}

struct UpdateBodyWeightRequest: Codable, APISyncMutationRequest {
    let date: String?
    let weight: Double?
    let notes: String?
    let clientUpdatedAt: String
    let idempotencyKey: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case date, weight, notes
        case clientUpdatedAt = "client_updated_at"
        case idempotencyKey = "idempotency_key"
        case deletedAt = "deleted_at"
    }
}





