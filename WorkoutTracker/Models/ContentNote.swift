import Foundation
import SwiftData

@Model
final class ContentNote: SyncableModel {
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
    
    static let entityKind: SyncEntityKind = .contentNote
    
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
    
    var url: URL? {
        guard !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    var hasLink: Bool {
        url != nil
    }
    
    var formattedDate: String {
        updatedAt.formatted(date: .abbreviated, time: .omitted)
    }
}
