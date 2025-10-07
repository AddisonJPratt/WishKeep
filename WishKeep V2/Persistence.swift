//
//  Persistence.swift
//  WishKeep V2
//
//  Created by Addison Pratt on 10/4/25.
//

import SwiftData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()
    
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.mainContext
        
        // Create sample data for preview
        let sampleNote = SwiftNote(title: "Sample Note")
        context.insert(sampleNote)
        
        // Add some sample blocks
        let messageBlock = Block(kind: .paragraph, text: NSAttributedString(string: "This is a sample message."), order: 0)
        let reflectionBlock = Block(kind: .paragraph, text: NSAttributedString(string: "This is a sample reflection."), order: 0)
        
        sampleNote.messageBlocks.append(messageBlock)
        sampleNote.reflectionBlocks.append(reflectionBlock)
        
        do {
            try context.save()
        } catch {
            fatalError("Preview data creation failed: \(error)")
        }
        
        return result
    }()
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                SwiftNote.self,
                Block.self,
                Jar.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

