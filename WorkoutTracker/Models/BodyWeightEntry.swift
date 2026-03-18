import Foundation
import SwiftData

extension BodyWeightEntry: SyncableModel {
    static let entityKind: SyncEntityKind = .bodyWeight
}

extension BodyWeightEntry {
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedWeight: String {
        String(format: "%.1f", weight)
    }
}
