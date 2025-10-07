import Foundation
import SwiftData

@Model
final class SwiftNote {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String
    var contactName: String?
    var userEditedContactName: Bool = false
    var text: String = ""
    var textHash: String?
    var thumbnail: Data?
    var createdAt: Date = Date()
    var isTruncated: Bool = false
    var isLongMessage: Bool = false
    var captureMode: String = "clipboard"
    var coverImageLocalIdentifier: String?
    var threadGroupId: String?
    var isFavorite: Bool = false
    var reflection: String?
    var ocrConfidence: Double = 0.0
    var lineCount: Int32 = 0
    var isMostlyOneSpeaker: Bool = false
    var userPreferredMode: String?
    var bubbleRegionsJSON: String?
    
    // New block-based fields
    @Relationship(deleteRule: .cascade) var messageBlocks: [Block] = []
    @Relationship(deleteRule: .cascade) var reflectionBlocks: [Block] = []
    
    // Jar relationship
    @Relationship(deleteRule: .nullify) var jars: [Jar] = []
    
    // Legacy Core Data compatibility
    var dateCaptured: Date = Date()
    var dateImported: Date = Date()
    var imageLocalIdentifier: String = ""
    
    init(title: String) {
        self.title = title
    }
    
    // Convenience initializer for Core Data migration
    init(
        title: String,
        contactName: String? = nil,
        text: String = "",
        captureMode: String = "clipboard",
        createdAt: Date = Date()
    ) {
        self.title = title
        self.contactName = contactName
        self.text = text
        self.captureMode = captureMode
        self.createdAt = createdAt
        self.dateCaptured = createdAt
        self.dateImported = createdAt
    }
}
