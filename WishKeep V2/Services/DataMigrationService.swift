import SwiftData
internal import CoreData
import Foundation

struct DataMigrationService {
    static func migrateFromCoreData(
        coreDataContext: NSManagedObjectContext,
        swiftDataContext: ModelContext
    ) async throws {
        // Fetch all Core Data notes
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Note")
        let coreDataNotes = try coreDataContext.fetch(fetchRequest)
        
        for coreDataNote in coreDataNotes {
            // Create new SwiftData Note
            let swiftDataNote = SwiftNote(
                title: coreDataNote.value(forKey: "contactName") as? String ?? "Migrated Note",
                contactName: coreDataNote.value(forKey: "contactName") as? String,
                text: coreDataNote.value(forKey: "text") as? String ?? "",
                captureMode: coreDataNote.value(forKey: "captureMode") as? String ?? "clipboard",
                createdAt: coreDataNote.value(forKey: "createdAt") as? Date ?? Date()
            )
            
            // Copy additional properties
            swiftDataNote.userEditedContactName = coreDataNote.value(forKey: "userEditedContactName") as? Bool ?? false
            swiftDataNote.textHash = coreDataNote.value(forKey: "textHash") as? String
            swiftDataNote.thumbnail = coreDataNote.value(forKey: "thumbnail") as? Data
            swiftDataNote.isTruncated = coreDataNote.value(forKey: "isTruncated") as? Bool ?? false
            swiftDataNote.isLongMessage = coreDataNote.value(forKey: "isLongMessage") as? Bool ?? false
            swiftDataNote.coverImageLocalIdentifier = coreDataNote.value(forKey: "coverImageLocalIdentifier") as? String
            swiftDataNote.threadGroupId = coreDataNote.value(forKey: "threadGroupId") as? String
            swiftDataNote.isFavorite = coreDataNote.value(forKey: "isFavorite") as? Bool ?? false
            swiftDataNote.reflection = coreDataNote.value(forKey: "reflection") as? String
            swiftDataNote.ocrConfidence = coreDataNote.value(forKey: "ocrConfidence") as? Double ?? 0.0
            swiftDataNote.lineCount = coreDataNote.value(forKey: "lineCount") as? Int32 ?? 0
            swiftDataNote.isMostlyOneSpeaker = coreDataNote.value(forKey: "isMostlyOneSpeaker") as? Bool ?? false
            swiftDataNote.userPreferredMode = coreDataNote.value(forKey: "userPreferredMode") as? String
            swiftDataNote.bubbleRegionsJSON = coreDataNote.value(forKey: "bubbleRegionsJSON") as? String
            swiftDataNote.dateCaptured = coreDataNote.value(forKey: "dateCaptured") as? Date ?? Date()
            swiftDataNote.dateImported = coreDataNote.value(forKey: "dateImported") as? Date ?? Date()
            swiftDataNote.imageLocalIdentifier = coreDataNote.value(forKey: "imageLocalIdentifier") as? String ?? ""
            
            // Convert existing text to blocks
            if !swiftDataNote.text.isEmpty {
                let textBlock = Block(
                    kind: .paragraph,
                    text: NSAttributedString(string: swiftDataNote.text),
                    order: 0
                )
                swiftDataNote.messageBlocks.append(textBlock)
            }
            
            // Convert existing reflection to blocks
            if let reflection = swiftDataNote.reflection, !reflection.isEmpty {
                let reflectionBlock = Block(
                    kind: .paragraph,
                    text: NSAttributedString(string: reflection),
                    order: 0
                )
                swiftDataNote.reflectionBlocks.append(reflectionBlock)
            }
            
            // Insert into SwiftData
            swiftDataContext.insert(swiftDataNote)
        }
        
        // Save SwiftData context
        try swiftDataContext.save()
    }
    
    static func createSampleData(context: ModelContext) {
        let sampleNote = SwiftNote(
            title: "Sample Conversation",
            contactName: "Alice",
            text: "Hey! How are you doing? I wanted to share something important with you.",
            captureMode: "clipboard",
            createdAt: Date()
        )
        
        // Add message blocks
        let messageBlocks = [
            Block(kind: .heading1, text: NSAttributedString(string: "Important Message"), order: 0),
            Block(kind: .paragraph, text: NSAttributedString(string: "Hey! How are you doing? I wanted to share something important with you."), order: 1),
            Block(kind: .bullet, text: NSAttributedString(string: "This is a key point"), order: 2),
            Block(kind: .bullet, text: NSAttributedString(string: "Another important detail"), order: 3),
            Block(kind: .checklist, text: NSAttributedString(string: "Follow up on this"), order: 4, isChecked: false)
        ]
        
        sampleNote.messageBlocks.append(contentsOf: messageBlocks)
        
        // Add reflection blocks
        let reflectionBlocks = [
            Block(kind: .paragraph, text: NSAttributedString(string: "This message means a lot to me because..."), order: 0),
            Block(kind: .quote, text: NSAttributedString(string: "Key insight: Sometimes the most important conversations happen in the simplest messages."), order: 1)
        ]
        
        sampleNote.reflectionBlocks.append(contentsOf: reflectionBlocks)
        
        context.insert(sampleNote)
        
        do {
            try context.save()
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }
}
