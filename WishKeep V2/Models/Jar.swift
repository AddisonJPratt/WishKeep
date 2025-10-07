import SwiftData
import Foundation

@Model
final class Jar {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String?
    var colorHex: String?
    var createdAt: Date = Date()
    var sortOrder: Int16 = 0
    
    // Relationship to notes
    @Relationship(deleteRule: .nullify) var notes: [SwiftNote] = []
    
    init(name: String, icon: String? = nil, colorHex: String? = nil) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
