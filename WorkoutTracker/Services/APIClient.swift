import Foundation

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

actor APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://workout-tracker-jim-brews-projects.vercel.app"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Exercises
    
    func fetchExercises(workoutType: String? = nil) async throws -> [APIExercise] {
        var urlString = "\(baseURL)/api/exercises"
        if let type = workoutType {
            urlString += "?workout_type=\(type)"
        }
        return try await get(urlString)
    }
    
    func fetchExercise(id: String) async throws -> APIExercise {
        return try await get("\(baseURL)/api/exercises/\(id)")
    }
    
    func createExercise(_ input: CreateExerciseRequest) async throws -> APIExercise {
        return try await post("\(baseURL)/api/exercises", body: input)
    }
    
    func updateExercise(id: String, _ input: UpdateExerciseRequest) async throws -> APIExercise {
        return try await put("\(baseURL)/api/exercises/\(id)", body: input)
    }
    
    func deleteExercise(id: String) async throws {
        try await delete("\(baseURL)/api/exercises/\(id)")
    }
    
    // MARK: - Workout Logs
    
    func fetchLogs(exerciseId: String? = nil, limit: Int = 50) async throws -> [APIWorkoutLog] {
        var urlString = "\(baseURL)/api/logs?limit=\(limit)"
        if let exerciseId = exerciseId {
            urlString += "&exercise_id=\(exerciseId)"
        }
        return try await get(urlString)
    }
    
    func fetchLog(id: String) async throws -> APIWorkoutLog {
        return try await get("\(baseURL)/api/logs/\(id)")
    }
    
    func createLog(_ input: CreateWorkoutLogRequest) async throws -> APIWorkoutLog {
        return try await post("\(baseURL)/api/logs", body: input)
    }
    
    func updateLog(id: String, _ input: UpdateWorkoutLogRequest) async throws -> APIWorkoutLog {
        return try await put("\(baseURL)/api/logs/\(id)", body: input)
    }
    
    func deleteLog(id: String) async throws {
        try await delete("\(baseURL)/api/logs/\(id)")
    }
    
    // MARK: - Notes
    
    func fetchNotes(limit: Int = 50) async throws -> [APIContentNote] {
        return try await get("\(baseURL)/api/notes?limit=\(limit)")
    }
    
    func fetchNote(id: String) async throws -> APIContentNote {
        return try await get("\(baseURL)/api/notes/\(id)")
    }
    
    func createNote(_ input: CreateContentNoteRequest) async throws -> APIContentNote {
        return try await post("\(baseURL)/api/notes", body: input)
    }
    
    func updateNote(id: String, _ input: UpdateContentNoteRequest) async throws -> APIContentNote {
        return try await put("\(baseURL)/api/notes/\(id)", body: input)
    }
    
    func deleteNote(id: String) async throws {
        try await delete("\(baseURL)/api/notes/\(id)")
    }
    
    // MARK: - Private Helpers
    
    private func get<T: Decodable>(_ urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return try await perform(request)
    }
    
    private func post<T: Decodable, B: Encodable>(_ urlString: String, body: B) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        
        return try await perform(request)
    }
    
    private func put<T: Decodable, B: Encodable>(_ urlString: String, body: B) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        
        return try await perform(request)
    }
    
    private func delete(_ urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw APIClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = (try? decoder.decode(APIError.self, from: data))?.error ?? "Unknown error"
            throw APIClientError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("🔴 Network error: \(error)")
            throw APIClientError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔴 Invalid response type")
            throw APIClientError.invalidResponse
        }
        
        // Log raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📡 API Response [\(httpResponse.statusCode)]: \(jsonString.prefix(500))")
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = (try? decoder.decode(APIError.self, from: data))?.error ?? "Unknown error"
            print("🔴 HTTP Error \(httpResponse.statusCode): \(errorMessage)")
            throw APIClientError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("🔴 Decoding error for \(T.self): \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔴 Raw JSON that failed to decode: \(jsonString)")
            }
            throw APIClientError.decodingError(error)
        }
    }
}
