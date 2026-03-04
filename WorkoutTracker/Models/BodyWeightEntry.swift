import Foundation
import SwiftData

@Model
final class BodyWeightEntry {
    var id: UUID
    var date: Date
    var weight: Double
    var notes: String
    
    init(
        date: Date = Date(),
        weight: Double,
        notes: String = ""
    ) {
        self.id = UUID()
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
