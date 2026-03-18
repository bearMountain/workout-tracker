import Foundation
import SwiftData

enum WorkoutTrackerSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Exercise.self, WorkoutLog.self, ContentNote.self, BodyWeightEntry.self]
    }

    @Model
    final class Exercise {
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
        var name: String
        var targetWeight: Double
        var targetReps: Int
        var notes: String
        var workoutTypeRaw: String
        var orderIndex: Int

        @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.exercise)
        var logs: [WorkoutLog]?

        init(
            id: UUID = UUID(),
            name: String,
            targetWeight: Double,
            targetReps: Int,
            notes: String = "",
            workoutType: WorkoutType,
            orderIndex: Int = 0
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
            self.lastModifiedAt = Date()
            self.isDeleted = false
            self.deletedAt = nil
            self.name = name
            self.targetWeight = targetWeight
            self.targetReps = targetReps
            self.notes = notes
            self.workoutTypeRaw = workoutType.rawValue
            self.orderIndex = orderIndex
            self.logs = []
        }
    }

    @Model
    final class WorkoutLog {
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
    }

    @Model
    final class ContentNote {
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
        var title: String
        var body: String
        var urlString: String
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            title: String,
            body: String = "",
            urlString: String = ""
        ) {
            let now = Date()
            self.id = id
            self.localID = id
            self.remoteID = nil
            self.serverVersion = 0
            self.isDirty = true
            self.lastSyncAttempt = nil
            self.syncError = nil
            self.idempotencyKey = UUID()
            self.retryCount = 0
            self.lastModifiedAt = now
            self.isDeleted = false
            self.deletedAt = nil
            self.title = title
            self.body = body
            self.urlString = urlString
            self.createdAt = now
            self.updatedAt = now
        }
    }

    @Model
    final class BodyWeightEntry {
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
        var weight: Double
        var notes: String

        init(
            id: UUID = UUID(),
            date: Date = Date(),
            weight: Double,
            notes: String = ""
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
            self.weight = weight
            self.notes = notes
        }
    }
}

enum WorkoutTrackerSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(2, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Exercise.self, WorkoutLog.self, ContentNote.self, BodyWeightEntry.self]
    }

    @Model
    final class Exercise {
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
        var name: String
        var targetWeight: Double
        var targetReps: Int
        var isMachine: Bool = false
        var notes: String
        var workoutTypeRaw: String
        var orderIndex: Int

        @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.exercise)
        var logs: [WorkoutLog]?

        init(
            id: UUID = UUID(),
            name: String,
            targetWeight: Double,
            targetReps: Int,
            isMachine: Bool = false,
            notes: String = "",
            workoutType: WorkoutType,
            orderIndex: Int = 0
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
            self.lastModifiedAt = Date()
            self.isDeleted = false
            self.deletedAt = nil
            self.name = name
            self.targetWeight = targetWeight
            self.targetReps = targetReps
            self.isMachine = isMachine
            self.notes = notes
            self.workoutTypeRaw = workoutType.rawValue
            self.orderIndex = orderIndex
            self.logs = []
        }
    }

    @Model
    final class WorkoutLog {
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
    }

    @Model
    final class ContentNote {
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
        var title: String
        var body: String
        var urlString: String
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            title: String,
            body: String = "",
            urlString: String = ""
        ) {
            let now = Date()
            self.id = id
            self.localID = id
            self.remoteID = nil
            self.serverVersion = 0
            self.isDirty = true
            self.lastSyncAttempt = nil
            self.syncError = nil
            self.idempotencyKey = UUID()
            self.retryCount = 0
            self.lastModifiedAt = now
            self.isDeleted = false
            self.deletedAt = nil
            self.title = title
            self.body = body
            self.urlString = urlString
            self.createdAt = now
            self.updatedAt = now
        }
    }

    @Model
    final class BodyWeightEntry {
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
        var weight: Double
        var notes: String

        init(
            id: UUID = UUID(),
            date: Date = Date(),
            weight: Double,
            notes: String = ""
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
            self.weight = weight
            self.notes = notes
        }
    }
}

typealias Exercise = WorkoutTrackerSchemaV2.Exercise
typealias WorkoutLog = WorkoutTrackerSchemaV2.WorkoutLog
typealias ContentNote = WorkoutTrackerSchemaV2.ContentNote
typealias BodyWeightEntry = WorkoutTrackerSchemaV2.BodyWeightEntry
