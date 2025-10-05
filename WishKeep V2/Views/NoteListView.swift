import SwiftUI
internal import CoreData
import UIKit

struct NoteListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var editingNoteId: NSManagedObjectID?
    @State private var editedName: String = ""
    @FocusState private var nameFieldFocused: Bool
    @State private var showPasteBanner: Bool = false
    @State private var showJarPicker: Bool = false
    @State private var selectedNoteForJar: Note?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateCaptured, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>

    var body: some View {
        ZStack(alignment: .top) {
            List {
                ForEach(notes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        NoteRow(
                            note: note,
                            isEditing: editingNoteId == note.objectID,
                            nameDraft: $editedName,
                            onStartEdit: { startEditing(note) },
                            onCommit: { saveEditedName() }
                        )
                        .focused($nameFieldFocused, equals: editingNoteId == note.objectID)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            selectedNoteForJar = note
                            showJarPicker = true
                        } label: { Label("Add to Jar", systemImage: "tray.and.arrow.down") }
                        .tint(.blue)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Inbox")
            .refreshable { ImportService.shared.scanForNewScreenshots(context: viewContext) }
            .onAppear { updatePasteBanner() }
            .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in updatePasteBanner() }

            if showPasteBanner {
                PasteBanner {
                    ClipboardManager.shared.saveClipboardIfAvailable(context: viewContext)
                    updatePasteBanner()
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showJarPicker) {
            if let n = selectedNoteForJar { JarPickerView(note: n) }
        }
    }

    private func startEditing(_ note: Note) {
        editingNoteId = note.objectID
        editedName = note.contactName ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { nameFieldFocused = true }
    }

    private func saveEditedName() {
        guard let id = editingNoteId, let note = try? viewContext.existingObject(with: id) as? Note else { return }
        viewContext.perform {
            note.contactName = editedName.isEmpty ? nil : editedName
            note.userEditedContactName = true
            try? viewContext.save()
        }
        editingNoteId = nil
    }

    private func updatePasteBanner() {
        showPasteBanner = UIPasteboard.general.hasStrings
    }
}

private struct NoteRow: View {
    let note: Note
    let isEditing: Bool
    @Binding var nameDraft: String
    let onStartEdit: () -> Void
    let onCommit: () -> Void
    @State private var showJarPicker: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let data = note.thumbnail, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipped()
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if isEditing {
                        TextField("Unnamed", text: $nameDraft, onCommit: onCommit)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 240)
                    } else {
                        Text(note.contactName ?? "Unnamed")
                            .font(.headline)
                            .lineLimit(1)
                    }
                    Button(action: { isEditing ? onCommit() : onStartEdit() }) { Image(systemName: isEditing ? "checkmark" : "pencil").font(.subheadline) }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isEditing ? "Save name" : "Edit name")
                }
                Text(note.text ?? "[pending OCR]")
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                if let dc = note.dateCaptured { Text(dc, formatter: Self.dateFormatter).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .padding(12)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

private struct CaptureBadge: View {
    let mode: String?
    var body: some View {
        let label: String
        switch mode {
        case CaptureMode.screenshots.rawValue: label = "Screenshot"
        case CaptureMode.clipboard.rawValue: label = "Clipboard"
        case CaptureMode.mixed.rawValue: label = "Mixed"
        default: label = ""
        }
        return Text(label)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.blue.opacity(0.15)))
    }
}

private struct PasteBanner: View {
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Label("Paste to Wishkeep?", systemImage: "doc.on.clipboard")
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
