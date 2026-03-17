import Foundation
import SwiftData

@Model
final class BodyWeightEntry: SyncableModel {
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
    
    static let entityKind: SyncEntityKind = .bodyWeight
    
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
    
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var formattedWeight: String {
        String(format: "%.1f", weight)
    }
}
