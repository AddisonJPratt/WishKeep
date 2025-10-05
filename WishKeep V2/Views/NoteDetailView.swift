import SwiftUI
import UIKit
internal import CoreData

struct NoteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: Int = 1 // 0=Bubbles,1=Transcript,2=Reflection
    @State private var editingName: Bool = false
    @State private var nameDraft: String = ""
    @State private var isEditingTranscript: Bool = false
    @State private var transcriptDraft: String = ""
    @State private var showingJarPicker: Bool = false
    let note: Note

    var body: some View {
        VStack(spacing: 0) {
            header
            contentTabs
        }
        .sheet(isPresented: $showingJarPicker) { JarPickerView(note: note) }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(note.isFavorite ? "Remove Favorite" : "Add Favorite")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if selectedTab == 1 {
                    Button(isEditingTranscript ? "Done" : "Edit") {
                        if isEditingTranscript { saveTranscript() }
                        isEditingTranscript.toggle()
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
                Text(note.contactName ?? "Unnamed")
                    .font(.title2).bold()
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
                                Button(role: .destructive) { JarStore.shared.remove(note, from: jar, context: viewContext) } label: { Label("Remove", systemImage: "xmark") }
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
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 280)
                if let data = note.thumbnail, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("Cover screenshot")
            .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var contentTabs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("View", selection: $selectedTab) {
                if !isClipboard { Text("Bubbles").tag(0) }
                Text("Transcript").tag(1)
                Text("Reflection").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedTab) { newValue in
                savePreferredMode(tab: newValue)
            }

            Group { selectedContent }
        }
    }

    @ViewBuilder private var selectedContent: some View {
        switch selectedTab {
        case 0:
            if isClipboard { transcriptView } else { BubblesView(text: note.text ?? "") }
        case 1: transcriptView
        default: reflectionView
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
            if isEditingTranscript {
                TextEditor(text: $transcriptDraft)
                    .padding()
            } else {
                ScrollView { Text(note.text ?? "").textSelection(.enabled).padding(.horizontal) }
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
        TextEditor(text: Binding(get: { note.reflection ?? "" }, set: { newValue in
            note.reflection = newValue
            try? viewContext.save()
        }))
        .padding()
    }

    private func toggleFavorite() {
        note.isFavorite.toggle()
        try? viewContext.save()
    }

    private func saveName() {
        note.contactName = nameDraft.isEmpty ? nil : nameDraft
        note.userEditedContactName = true
        try? viewContext.save()
        editingName = false
    }

    private func saveTranscript() {
        let newText = transcriptDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        note.text = newText
        note.textHash = OCRService.shared.computeTextHash(newText)
        note.isTruncated = false
        try? viewContext.save()
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
        try? viewContext.save()
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

