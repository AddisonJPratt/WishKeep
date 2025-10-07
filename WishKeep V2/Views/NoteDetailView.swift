import SwiftUI
import UIKit
import PhotosUI
import SwiftData

struct NoteDetailView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab: Int = 1 // 0=Bubbles,1=Transcript,2=Reflection,3=BlockEditor
    @State private var editingName: Bool = false
    @State private var nameDraft: String = ""
    @State private var isEditingTranscript: Bool = false
    @State private var transcriptDraft: String = ""
    @State private var showingJarPicker: Bool = false
    @State private var coverVisible: Bool = false
    @State private var starBounce: Bool = false
    @State private var reflectPulse: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingFormatSheet: Bool = false
    @FocusState private var transcriptFocused: Bool
    @State private var isEditingReflection: Bool = false
    @FocusState private var reflectionFocused: Bool
    let note: SwiftNote

    var body: some View {
        VStack(spacing: 0) {
            header
            contentTabs
        }
        .safeAreaInset(edge: .bottom) { bottomActionBar }
        .background(Theme.Colors.canvas.ignoresSafeArea())
        .sheet(isPresented: $showingJarPicker) { JarPickerView(note: note) }
        .sheet(isPresented: $showingFormatSheet) {
            TextFormatMenu(
                onBody: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.applyBody() } },
                onTitle: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.applyTitle() } },
                onSubtitle: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.applySubtitle() } },
                onList: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.toggleList() } },
                onIndent: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.indent() } }
            )
            .presentationDetents([.medium])
        }
        .onChange(of: pickerItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    note.thumbnail = image.jpegData(compressionQuality: 0.8)
                    try? context.save()
                }
            }
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .scaleEffect(starBounce ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.18), value: starBounce)
                }
                .accessibilityLabel(note.isFavorite ? "Remove Favorite" : "Add Favorite")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if selectedTab == 1 {
                    Button(isEditingTranscript ? "Done" : "Edit") {
                        if isEditingTranscript {
                            saveTranscript()
                            transcriptFocused = false
                        } else {
                            isEditingTranscript = true
                            transcriptFocused = true
                        }
                    }
                } else if selectedTab == 2 {
                    Button(isEditingReflection ? "Done" : "Edit") {
                        if isEditingReflection {
                            reflectionFocused = false
                            isEditingReflection = false
                        } else {
                            isEditingReflection = true
                            reflectionFocused = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $editingName) {
            EditNameSheet(name: $nameDraft) { saveName() }
        }
        .onAppear {
            nameDraft = note.contactName ?? ""
            // Set default display using stored preference or heuristics
            if let pref = note.userPreferredMode {
                selectedTab = (pref == "bubbles" && !isClipboard) ? 0 : (pref == "reflection" ? 2 : 1)
            } else {
                let defaultToTranscript = (note.ocrConfidence < 0.7) || (note.lineCount > 20) || (note.isMostlyOneSpeaker == true) || isClipboard
                selectedTab = defaultToTranscript ? 1 : 0
            }
            transcriptDraft = note.text ?? ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(note.contactName ?? "Unnamed").titleStyle(.h2)
                Button { editingName = true } label: { Image(systemName: "pencil") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit name")
                Spacer()
            }
            // Jars chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let set = note.jars as? Set<Jar> {
                        ForEach(Array(set).sorted { ($0.sortOrder) < ($1.sortOrder) }) { jar in
                            HStack(spacing: 4) {
                                Text((jar.icon ?? "") + (jar.name ?? ""))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(.secondarySystemBackground)))
                            .contextMenu {
                                Button(role: .destructive) { JarStore.shared.remove(note, from: jar, context: context) } label: { Label("Remove", systemImage: "xmark") }
                            }
                        }
                    }
                    Button(action: { showingJarPicker = true }) { Label("Add", systemImage: "plus") }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(.tertiarySystemBackground)))
                }
                .padding(.vertical, 4)
            }
            // No cover image block; focus on text content
        }
        .padding(.horizontal)
        .padding(.top, 32)
    }

    private var contentTabs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group { selectedContent }
                .transition(.opacity)
        }
    }

    @ViewBuilder private var selectedContent: some View {
        switch selectedTab {
        case 0:
            if isClipboard { transcriptView } else { BubblesView(text: note.text ?? "") }
        case 1: transcriptView
        case 2: reflectionView
        default: blockEditorView
        }
    }

    private var transcriptView: some View {
        VStack(spacing: 0) {
            if (note.ocrConfidence < 0.7) || (note.lineCount > 20) {
                HStack {
                    Text("Bubbles may not display accurately → Showing Transcript")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !isClipboard {
                        Button("Switch to Bubbles") { selectedTab = 0 }
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            ScrollView {
                if isEditingTranscript {
                    TextEditor(text: $transcriptDraft)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .textInputAutocapitalization(.sentences)
                        .focused($transcriptFocused)
                } else {
                    Text(note.text ?? "")
                        .textSelection(.enabled)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                        .font(.body)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isEditingTranscript && transcriptFocused {
                RichTextToolbar(
                    state: .constant(.init()),
                    onBody: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.applyBody() } },
                    onTitle: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.applyTitle() } },
                    onSubtitle: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.applySubtitle() } },
                    onList: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.toggleList() } },
                    onIndent: { transcriptDraft = RichTextModel(text: transcriptDraft).applyReturning { $0.indent() } },
                    onMore: { showingFormatSheet = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if note.isTruncated {
                Text("Looks cut off — Paste full text?")
                    .font(.caption)
                    .padding(8)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                    .padding()
            }
        }
    }

    private var reflectionView: some View {
        ZStack(alignment: .trailing) {
            TextEditor(text: Binding(get: { note.reflection ?? "" }, set: { newValue in
                note.reflection = newValue
                try? context.save()
                reflectPulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { reflectPulse = false }
            }))
            .padding()
            .focused($reflectionFocused)
            if reflectPulse {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: reflectPulse)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isEditingReflection && reflectionFocused {
                RichTextToolbar(
                    state: .constant(.init()),
                    onBody: {
                        let new = RichTextModel(text: note.reflection ?? "").applyReturning { $0.applyBody() }
                        note.reflection = new; try? context.save()
                    },
                    onTitle: {
                        let new = RichTextModel(text: note.reflection ?? "").applyReturning { $0.applyTitle() }
                        note.reflection = new; try? context.save()
                    },
                    onSubtitle: {
                        let new = RichTextModel(text: note.reflection ?? "").applyReturning { $0.applySubtitle() }
                        note.reflection = new; try? context.save()
                    },
                    onList: {
                        let new = RichTextModel(text: note.reflection ?? "").applyReturning { $0.toggleList() }
                        note.reflection = new; try? context.save()
                    },
                    onIndent: {
                        let new = RichTextModel(text: note.reflection ?? "").applyReturning { $0.indent() }
                        note.reflection = new; try? context.save()
                    },
                    onMore: { showingFormatSheet = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }
    
    private var blockEditorView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Message")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                
                // For now, we'll create a simple text editor that can be enhanced later
                // This is a placeholder until we fully integrate the block-based system
                TextEditor(text: Binding(
                    get: { note.text ?? "" },
                    set: { newValue in
                        note.text = newValue
                        try? context.save()
                    }
                ))
                .frame(minHeight: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Message content")
                
                Text("Reflection")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                
                TextEditor(text: Binding(
                    get: { note.reflection ?? "" },
                    set: { newValue in
                        note.reflection = newValue
                        try? context.save()
                    }
                ))
                .frame(minHeight: 150)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .accessibilityLabel("Reflection content")
            }
            .padding(20)
        }
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack { 
            Picker("View", selection: $selectedTab) {
                if !isClipboard { Text("Bubbles").tag(0) }
                Text("Transcript").tag(1)
                Text("Reflection").tag(2)
                Text("Editor").tag(3)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTab) { newValue in
                withAnimation(.easeInOut(duration: 0.2)) { }
                savePreferredMode(tab: newValue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider().background(Theme.Colors.divider), alignment: .top)
        .accessibilityLabel("View selector")
    }

    private func shareNote() {
        let text = note.text ?? ""
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true)
    }


    private func toggleFavorite() {
        note.isFavorite.toggle()
        try? context.save()
        Haptic.light()
        starBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { starBounce = false }
    }

    private func saveName() {
        note.contactName = nameDraft.isEmpty ? nil : nameDraft
        note.userEditedContactName = true
        try? context.save()
        editingName = false
    }

    private func saveTranscript() {
        let newText = transcriptDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        note.text = newText
        note.textHash = ImportService.shared.computeTextHash(newText)
        note.isTruncated = false
        try? context.save()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private var isClipboard: Bool {
        return note.captureMode == CaptureMode.clipboard.rawValue
    }

    private func savePreferredMode(tab: Int) {
        let mode = (tab == 0 && !isClipboard) ? "bubbles" : (tab == 2 ? "reflection" : "transcript")
        note.userPreferredMode = mode
        try? context.save()
    }
}

private struct BubblesView: View {
    let text: String
    @State private var hiddenIndices: Set<Int> = []
    var body: some View {
        let lines = text.split(separator: "\n").map(String.init)
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                    if !hiddenIndices.contains(idx) {
                        let isYou = heuristicsIsYou(line: line, index: idx)
                        HStack(alignment: .bottom) {
                            if isYou { Spacer(minLength: 32) }
                            Text(line)
                                .padding(12)
                                .foregroundStyle(isYou ? .white : .primary)
                                .background(RoundedRectangle(cornerRadius: 18).fill(isYou ? Color.blue : Color(.secondarySystemBackground)))
                                .contextMenu {
                                    Button(role: .destructive) { hiddenIndices.insert(idx) } label: { Label("Remove bubble", systemImage: "trash") }
                                }
                                .accessibilityLabel("Chat bubble: \(line)")
                            if !isYou { Spacer(minLength: 32) }
                        }
                        .animation(.default, value: hiddenIndices)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func heuristicsIsYou(line: String, index: Int) -> Bool {
        if index % 2 == 1 { return true }
        let youHints = ["you", "yeah", "ok", "i "]
        return youHints.contains(where: { line.lowercased().contains($0) })
    }
}

