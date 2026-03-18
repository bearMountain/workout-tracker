import Foundation
import SwiftData

extension ContentNote: SyncableModel {
    static let entityKind: SyncEntityKind = .contentNote
}

extension ContentNote {
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
