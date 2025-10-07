import SwiftUI
import SwiftData

struct SwiftNoteDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.wkTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Bindable var note: SwiftNote
    @State private var showingExport = false
    @State private var selectedTab = 0
    @State private var isEditing = false

    var body: some View {
        ZStack {
            WKThemeBackground()
            
            VStack(spacing: 0) {
                // Title
                    TextField("Title", text: $note.title)
                        .font(.title2)
                        .foregroundStyle(theme.ink)
                    .accessibilityLabel("Note title")
                    .padding(.horizontal, WKTok.pL)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Content Area
                TabView(selection: $selectedTab) {
                    // Message Tab
                    ScrollView {
                        if note.messageBlocks.isEmpty {
                            WKEmptyStateView(
                                title: "Message",
                                placeholder: "Paste or write a memory...",
                                theme: theme,
                                isGlowing: note.jars.isEmpty
                            )
                            .wkCard(theme)
                            .overlay(
                                // Animated halo border for unassigned notes
                Group {
                                    if note.jars.isEmpty {
                                        WKAIHaloBorder(
                                            shape: RoundedRectangle(cornerRadius: WKTok.cL),
                                            theme: theme,
                                            lineWidth: 1.5,
                                            glow: 15,
                                            speed: 6
                                        )
                                    }
                                }
                            )
                            .onTapGesture {
                                // Add a default block when tapping empty state
                                let newBlock = Block(kind: .paragraph, text: NSAttributedString(string: ""), order: 0)
                                note.messageBlocks.append(newBlock)
                                isEditing = true
                            }
                        } else {
                            WKBlockEditorView(blocks: note.messageBlocks)
                                .wkCard(theme)
                                .scaleEffect(isEditing && selectedTab == 0 ? 1.02 : 1.0)
                                .shadow(
                                    color: isEditing && selectedTab == 0 ? WKTok.shadowLift : WKTok.shadowSoft,
                                    radius: isEditing && selectedTab == 0 ? 22 : 14,
                                    y: isEditing && selectedTab == 0 ? 12 : 8
                                )
                                .animation(WKTok.spring, value: isEditing)
                                .onTapGesture {
                                    isEditing = true
                                }
                        }
                    }
                    .padding(.horizontal, WKTok.pL)
                    .padding(.bottom, 100) // Space for tab bar
                    .tag(0)
                    
                    // Journal Tab
                    ScrollView {
                        if note.reflectionBlocks.isEmpty {
                            WKEmptyStateView(
                                title: "Journal",
                                placeholder: "Why this matters...",
                                theme: theme,
                                isGlowing: note.jars.isEmpty
                            )
                            .wkCard(theme)
                            .onTapGesture {
                                // Add a default block when tapping empty state
                                let newBlock = Block(kind: .paragraph, text: NSAttributedString(string: ""), order: 0)
                                note.reflectionBlocks.append(newBlock)
                                isEditing = true
                            }
                        } else {
                            WKBlockEditorView(blocks: note.reflectionBlocks)
                                .wkCard(theme)
                                .scaleEffect(isEditing && selectedTab == 1 ? 1.02 : 1.0)
                                .shadow(
                                    color: isEditing && selectedTab == 1 ? WKTok.shadowLift : WKTok.shadowSoft,
                                    radius: isEditing && selectedTab == 1 ? 22 : 14,
                                    y: isEditing && selectedTab == 1 ? 12 : 8
                                )
                                .animation(WKTok.spring, value: isEditing)
                                .onTapGesture {
                                    isEditing = true
                                }
                        }
                    }
                    .padding(.horizontal, WKTok.pL)
                    .padding(.bottom, 100) // Space for tab bar
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom Tab Bar
                HStack(spacing: 0) {
                    TabButton(
                        title: "Message",
                        icon: "message",
                        isSelected: selectedTab == 0,
                        theme: theme
                    ) {
                        withAnimation(WKTok.spring) {
                            selectedTab = 0
                            isEditing = false
                        }
                    }
                    
                    TabButton(
                        title: "Journal",
                        icon: "book",
                        isSelected: selectedTab == 1,
                        theme: theme
                    ) {
                        withAnimation(WKTok.spring) {
                            selectedTab = 1
                            isEditing = false
                        }
                    }
                }
                .padding(.horizontal, WKTok.pL)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WKTok.cM))
                .overlay(
                    RoundedRectangle(cornerRadius: WKTok.cM)
                        .stroke(theme.mist.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, WKTok.pL)
                .padding(.bottom, 8)
            }
        }
        .wkTheme(colorScheme == .dark ? .dark : .light)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Import Message Markdown") { 
                        importMD(into: \.messageBlocks) 
                    }
                    .accessibilityLabel("Import markdown into message")
                    
                    Button("Export Message Markdown") { 
                        exportMD(from: note.messageBlocks) 
                    }
                    .accessibilityLabel("Export message as markdown")
                    
                    Button("Import Journal Markdown") { 
                        importMD(into: \.reflectionBlocks) 
                    }
                    .accessibilityLabel("Import markdown into journal")
                    
                    Button("Export Journal Markdown") { 
                        exportMD(from: note.reflectionBlocks) 
                    }
                    .accessibilityLabel("Export journal as markdown")
                } label: { 
                    Image(systemName: "arrow.up.arrow.down.square")
                        .foregroundStyle(theme.accent)
                        .accessibilityLabel("Import/Export menu")
                }
            }
        }
        .onDisappear { 
            try? context.save() 
        }
    }

    private func importMD(into keyPath: ReferenceWritableKeyPath<SwiftNote, [Block]>) {
        // For demo: pasteboard
        if let md = UIPasteboard.general.string {
            let newBlocks = MarkdownCodec.importMarkdown(md)
            note[keyPath: keyPath] = newBlocks
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
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let theme: WKTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? theme.accent : theme.subInk)
                
                Text(title)
                    .font(WKFont.meta)
                    .foregroundStyle(isSelected ? theme.accent : theme.subInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? theme.accent.opacity(0.14) : .clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct WKEmptyStateView: View {
    let title: String
    let placeholder: String
    let theme: WKTheme
    let isGlowing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Simple clean icon
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(theme.accent)
            
            VStack(spacing: 6) {
                Text(title)
                    .font(WKFont.h2)
                    .foregroundStyle(theme.subInk)
                
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundStyle(theme.faintInk)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(WKTok.pL)
    }
}