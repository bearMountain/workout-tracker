import Foundation
import SwiftData

@Model
final class ContentNote {
    var id: UUID
    var title: String
    var body: String
    var urlString: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String,
        body: String = "",
        urlString: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.urlString = urlString
        self.createdAt = Date()
        self.updatedAt = Date()
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
