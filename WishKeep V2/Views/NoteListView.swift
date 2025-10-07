import SwiftUI
import SwiftData
import UIKit

struct NoteListView: View {
    @Environment(\.modelContext) private var context
    @State private var editingNoteId: UUID?
    @State private var editedName: String = ""
    @FocusState private var nameFieldFocused: Bool
    @State private var showJarPicker: Bool = false
    @State private var selectedNoteForJar: SwiftNote?
    @State private var showCreateJar: Bool = false
    @State private var newJarName: String = ""
    @State private var newJarIcon: String = ""
    @State private var animateTitle: Bool = false
    @State private var activeJarId: UUID?

    @Query(sort: \Jar.sortOrder, order: .forward)
    private var jars: [Jar]

    @Query(sort: \SwiftNote.dateCaptured, order: .reverse)
    private var notes: [SwiftNote]

    var body: some View {
        let filtered: [SwiftNote] = filteredNotes()
        return ZStack(alignment: .bottomTrailing) {
            List {
                Section {
                    jarChipsRow
                    if let favorite = memoryMoment() {
                        MemoryMomentCard(note: favorite)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                ForEach(filtered, id: \.id) { note in
                    NavigationLink(destination: SwiftNoteDetailView(note: note)) {
                        NoteCard(
                            note: note,
                            isEditing: editingNoteId == note.id,
                            nameDraft: $editedName,
                            onStartEdit: { startEditing(note) },
                            onCommit: { saveEditedName() }
                        )
                        .focused($nameFieldFocused)
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                    .swipeActions(edge: .trailing) {
                        Button {
                            selectedNoteForJar = note
                            showJarPicker = true
                        } label: { Label("Add to Jar", systemImage: "tray.and.arrow.down") }
                        .tint(.blue)
                        .accessibilityLabel("Add note to a Jar")
                    }
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Memories")
            .refreshable { ImportService.shared.scanForNewScreenshots(context: context) }

            if notes.isEmpty {
                EmptyStateView()
                    .padding(.top, 60)
            }

            Menu {
                Button { ImportService.shared.scanForNewScreenshots(context: context) } label: { Label("Import Screenshot", systemImage: "photo.on.rectangle") }
                Button { if UIPasteboard.general.hasStrings { ClipboardManager.shared.saveClipboardIfAvailable(context: context) } } label: { Label("Paste Clipboard", systemImage: "doc.on.clipboard") }
                Button { showCreateJar = true } label: { Label("New Jar", systemImage: "tray") }
            } label: {
                ZStack {
                    Circle().fill(Theme.Colors.highlight)
                        .frame(width: 56, height: 56)
                        .softShadow()
                    Image(systemName: "+").foregroundStyle(.white)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showJarPicker) {
            if let n = selectedNoteForJar { JarPickerView(note: n) }
        }
    }

    private func startEditing(_ note: SwiftNote) {
        editingNoteId = note.id
        editedName = note.contactName ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { nameFieldFocused = true }
    }

    private func saveEditedName() {
        guard let id = editingNoteId, let note = notes.first(where: { $0.id == id }) else { return }
        note.contactName = editedName.isEmpty ? nil : editedName
        note.userEditedContactName = true
        try? context.save()
        editingNoteId = nil
    }

    private func memoryMoment() -> SwiftNote? {
        notes.first(where: { $0.isFavorite })
    }
}

private struct NoteCard: View {
    @Environment(\.wkTheme) var theme
    let note: SwiftNote
    let isEditing: Bool
    @Binding var nameDraft: String
    let onStartEdit: () -> Void
    let onCommit: () -> Void
    @State private var pulse: Bool = false
    @State private var glowAnimation = false

    var body: some View {
        HStack(spacing: 8) {
            if note.captureMode != CaptureMode.clipboard.rawValue {
                if let data = note.thumbnail, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipped()
                        .cornerRadius(6)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Show message content instead of "Unnamed"
                let messageText = getMessagePreview()
                Text(messageText)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(theme.ink)
                
                // Show categories if assigned
                if !note.jars.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(note.jars.prefix(2), id: \.id) { jar in
                            Text(jar.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(theme.accent.opacity(0.2))
                                )
                                .foregroundStyle(theme.accent)
                        }
                        if note.jars.count > 2 {
                            Text("+\(note.jars.count - 2)")
                                .font(.caption2)
                                .foregroundStyle(theme.faintInk)
                        }
                    }
                } else {
                    Text("Unassigned")
                        .font(.caption2)
                        .foregroundStyle(theme.faintInk)
                        .italic()
                }
                
                Text(note.dateCaptured, formatter: Self.dateFormatter)
                    .font(.caption2)
                    .foregroundStyle(theme.faintInk)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: WKTok.shadowSoft, radius: 4, y: 2)
        )
        .onReceive(NotificationCenter.default.publisher(for: .jarAddedPing)) { notif in
            guard let id = notif.object as? UUID, id == note.id else { return }
            withAnimation(.easeInOut(duration: 0.2)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { withAnimation { pulse = false } }
        }
    }
    
    private func getMessagePreview() -> String {
        // Get the first message block content
        if let firstBlock = note.messageBlocks.first, !firstBlock.attributed.string.isEmpty {
            return firstBlock.attributed.string
        }
        
        // Fallback to legacy text field
        if !note.text.isEmpty {
            return note.text
        }
        
        // Show placeholder for empty notes
        return "[Tap to add text]"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

private extension NoteListView {
    var headerTitle: some View { EmptyView() }

    var jarChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { activeJarId = nil }) { Text("All").chipStyle(active: activeJarId == nil) }
                ForEach(jars) { jar in
                    let active = activeJarId == jar.id
                    Button(action: { activeJarId = active ? nil : jar.id }) {
                        Text((jar.icon ?? "") + " " + jar.name)
                            .chipStyle(active: active)
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.padding)
        }
    }

    func filteredNotes() -> [SwiftNote] {
        let base = Array(notes)
        guard let id = activeJarId, let jar = jars.first(where: { $0.id == id }) else { return base }
        return base.filter { $0.jars.contains(jar) }
    }

    struct MemoryMomentCard: View {
        let note: SwiftNote
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Favorite")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(note.contactName ?? "")
                    .foregroundStyle(.white.opacity(0.95))
                Text(note.text)
                    .lineLimit(2)
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            )
            .padding(.horizontal, Theme.Metrics.padding)
            .padding(.bottom, 4)
        }
    }

    struct EmptyStateView: View {
        var body: some View {
            VStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Screenshot or copy a message you love — I’ll save it here.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

