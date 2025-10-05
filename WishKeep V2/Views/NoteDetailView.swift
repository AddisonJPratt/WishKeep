import SwiftUI
import UIKit
import PhotosUI
internal import CoreData

struct NoteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: Int = 1 // 0=Bubbles,1=Transcript,2=Reflection
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
    let note: Note

    var body: some View {
        VStack(spacing: 0) {
            header
            contentTabs
        }
        .sheet(isPresented: $showingJarPicker) { JarPickerView(note: note) }
        .onChange(of: pickerItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    note.thumbnail = image.jpegData(compressionQuality: 0.8)
                    try? viewContext.save()
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
            // Jars chips + Add Image
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
                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        Label("Add Image", systemImage: "photo.badge.plus")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(.tertiarySystemBackground)))
                    }
                }
                .padding(.vertical, 4)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.card)
                    .frame(height: 160)
                if let data = note.thumbnail, let ui = UIImage(data: data) {
                    // blurred background
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .blur(radius: 18)
                        .opacity(0.5)
                        .clipped()
                        .cornerRadius(16)
                    // main image with fade-in
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 120)
                        .cornerRadius(12)
                        .opacity(coverVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 0.25), value: coverVisible)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundStyle(.secondary)
                        .opacity(coverVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 0.25), value: coverVisible)
                }
            }
            .accessibilityLabel("Cover screenshot")
            .padding(.bottom, 8)
            .onAppear { coverVisible = true }
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
                withAnimation(.easeInOut(duration: 0.2)) { }
                savePreferredMode(tab: newValue)
            }

            Group { selectedContent }
                .transition(.opacity)
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
            ScrollView {
                if isEditingTranscript {
                    TextEditor(text: $transcriptDraft)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .textInputAutocapitalization(.sentences)
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
                try? viewContext.save()
                reflectPulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { reflectPulse = false }
            }))
            .padding()
            if reflectPulse {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: reflectPulse)
            }
        }
    }

    private func toggleFavorite() {
        note.isFavorite.toggle()
        try? viewContext.save()
        starBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { starBounce = false }
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

