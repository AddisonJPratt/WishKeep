import SwiftUI
import SwiftData

struct SwiftDataTestView: View {
    @Environment(\.modelContext) private var context
    @Query private var notes: [SwiftNote]
    @State private var showingBlockEditor = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    NavigationLink(destination: SwiftNoteDetailView(note: note)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.headline)
                            Text("Message blocks: \(note.messageBlocks.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Reflection blocks: \(note.reflectionBlocks.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("SwiftData Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Note") {
                        let newNote = SwiftNote(title: "New Note \(notes.count + 1)")
                        context.insert(newNote)
                        
                        // Add some default blocks
                        let messageBlock = Block(kind: .paragraph, text: NSAttributedString(string: "Start typing your message here..."), order: 0)
                        let reflectionBlock = Block(kind: .paragraph, text: NSAttributedString(string: "Add your reflection here..."), order: 0)
                        
                        newNote.messageBlocks.append(messageBlock)
                        newNote.reflectionBlocks.append(reflectionBlock)
                        
                        try? context.save()
                    }
                }
            }
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        for index in offsets {
            context.delete(notes[index])
        }
        try? context.save()
    }
}
