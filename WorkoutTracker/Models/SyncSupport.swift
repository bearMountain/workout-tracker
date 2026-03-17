import Foundation
import SwiftData

enum SyncEntityKind: String, Codable, CaseIterable {
    case exercise = "exercises"
    case workoutLog = "logs"
    case bodyWeight = "body-weights"
    case contentNote = "notes"
}

protocol SyncableModel: PersistentModel {
    var localID: UUID { get set }
    var remoteID: String? { get set }
    var serverVersion: Int { get set }
    var isDirty: Bool { get set }
    var lastSyncAttempt: Date? { get set }
    var syncError: String? { get set }
    var idempotencyKey: UUID { get set }
    var retryCount: Int { get set }
    var lastModifiedAt: Date { get set }
    var isDeleted: Bool { get set }
    var deletedAt: Date? { get set }
    static var entityKind: SyncEntityKind { get }
}

extension SyncableModel {
    var effectiveRemoteID: String {
        remoteID ?? localID.uuidString
    }
    
    var shouldSync: Bool {
        isDirty
    }
    
    func markDirty(at date: Date = Date(), error: String? = nil) {
        isDirty = true
        lastModifiedAt = date
        lastSyncAttempt = nil
        syncError = error
        retryCount = 0
        if remoteID == nil {
            remoteID = localID.uuidString
        }
    }
    
    func markSyncAttemptFailed(_ error: String, at date: Date = Date()) {
        lastSyncAttempt = date
        retryCount += 1
        syncError = error
        isDirty = true
    }
    
    func markSynced(remoteID: String?, serverVersion: Int, at date: Date = Date()) {
        self.remoteID = remoteID ?? self.remoteID ?? localID.uuidString
        self.serverVersion = serverVersion
        isDirty = false
        lastSyncAttempt = date
        syncError = nil
        retryCount = 0
        if !isDeleted {
            deletedAt = nil
        }
        idempotencyKey = UUID()
    }
    
    func markDeleted(at date: Date = Date()) {
        isDeleted = true
        deletedAt = date
        markDirty(at: date)
    }
}
