import Foundation
import SwiftData

import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID = UUID()
    var title: String = ""
    var encryptedContent: Data = Data()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var category: String?
    var isFavorite: Bool = false

    init(id: UUID = UUID(),
         title: String,
         encryptedContent: Data,
         createdAt: Date = .now,
         modifiedAt: Date = .now,
         category: String? = nil,
         isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.encryptedContent = encryptedContent
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.category = category
        self.isFavorite = isFavorite
    }
}

