import SwiftUI
import SwiftData

struct BlockEditorDemoView: View {
    @Environment(\.modelContext) private var context
    @State private var note = SwiftNote(title: "Demo Note")
    @State private var messageBlocks: [Block] = []
    @State private var reflectionBlocks: [Block] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TextField("Title", text: $note.title)
                        .font(.largeTitle.bold())
                        .accessibilityLabel("Note title")

                    Group {
                        Text("Message")
                            .font(.title3.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        
                        BlockEditorView(blocks: messageBlocks)
                            .accessibilityLabel("Message content")
                    }

                    Group {
                        Text("Reflection")
                            .font(.title3.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        
                        BlockEditorView(blocks: reflectionBlocks)
                            .accessibilityLabel("Reflection content")
                    }
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Import Message Markdown") { 
                            importMD(into: \.messageBlocks) 
                        }
                        .accessibilityLabel("Import markdown into message")
                        
                        Button("Export Message Markdown") { 
                            exportMD(from: messageBlocks) 
                        }
                        .accessibilityLabel("Export message as markdown")
                        
                        Button("Import Reflection Markdown") { 
                            importMD(into: \.reflectionBlocks) 
                        }
                        .accessibilityLabel("Import markdown into reflection")
                        
                        Button("Export Reflection Markdown") { 
                            exportMD(from: reflectionBlocks) 
                        }
                        .accessibilityLabel("Export reflection as markdown")
                        
                        Button("Add Sample Content") {
                            addSampleContent()
                        }
                    } label: { 
                        Image(systemName: "arrow.up.arrow.down.square")
                            .accessibilityLabel("Import/Export menu")
                    }
                }
            }
            .onAppear {
                if messageBlocks.isEmpty {
                    addSampleContent()
                }
            }
        }
    }

    private func importMD(into keyPath: ReferenceWritableKeyPath<BlockEditorDemoView, [Block]>) {
        // For demo: pasteboard
        if let md = UIPasteboard.general.string {
            let newBlocks = MarkdownCodec.importMarkdown(md)
            self[keyPath: keyPath] = newBlocks
            Haptic.success()
        } else {
            Haptic.warning()
        }
    }
    
    private func exportMD(from blocks: [Block]) {
        let md = MarkdownCodec.exportMarkdown(blocks: blocks)
        UIPasteboard.general.string = md
        Haptic.success()
    }
    
    private func addSampleContent() {
        messageBlocks = [
            Block(kind: .heading1, text: NSAttributedString(string: "Meeting Notes"), order: 0),
            Block(kind: .paragraph, text: NSAttributedString(string: "This is a sample message with some content."), order: 1),
            Block(kind: .bullet, text: NSAttributedString(string: "First bullet point"), order: 2),
            Block(kind: .bullet, text: NSAttributedString(string: "Second bullet point"), order: 3),
            Block(kind: .checklist, text: NSAttributedString(string: "Follow up on action items"), order: 4, isChecked: false)
        ]
        
        reflectionBlocks = [
            Block(kind: .paragraph, text: NSAttributedString(string: "This meeting was important because..."), order: 0),
            Block(kind: .quote, text: NSAttributedString(string: "Key insight from the discussion"), order: 1)
        ]
    }
}
