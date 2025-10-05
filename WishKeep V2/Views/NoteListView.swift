import SwiftUI
internal import CoreData
import UIKit

struct NoteListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var editingNoteId: NSManagedObjectID?
    @State private var editedName: String = ""
    @FocusState private var nameFieldFocused: Bool
    @State private var showJarPicker: Bool = false
    @State private var selectedNoteForJar: Note?
    @State private var showCreateJar: Bool = false
    @State private var newJarName: String = ""
    @State private var newJarIcon: String = ""
    @State private var animateTitle: Bool = false
    @State private var activeJarId: NSManagedObjectID?

    @FetchRequest(entity: Jar.entity(), sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true), NSSortDescriptor(key: "name", ascending: true)])
    private var jars: FetchedResults<Jar>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "dateCaptured", ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>

    var body: some View {
        let filtered: [Note] = filteredNotes()
        return ZStack(alignment: .top) {
            List {
                Section {
                    headerTitle
                    jarChipsRow
                    if let favorite = memoryMoment() {
                        MemoryMomentCard(note: favorite)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                ForEach(filtered, id: \.objectID) { note in
                    noteRowLink(note)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Inbox")
            .refreshable { ImportService.shared.scanForNewScreenshots(context: viewContext) }

            if notes.isEmpty {
                EmptyStateView()
                    .padding(.top, 60)
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

    private func memoryMoment() -> Note? {
        notes.first(where: { $0.isFavorite })
    }
}

private struct NoteRow: View {
    let note: Note
    let isEditing: Bool
    @Binding var nameDraft: String
    let onStartEdit: () -> Void
    let onCommit: () -> Void
    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if note.captureMode != CaptureMode.clipboard.rawValue {
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
                if let set = note.jars as? Set<Jar>, !set.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(set).sorted { $0.sortOrder < $1.sortOrder }) { jar in
                                HStack(spacing: 4) {
                                    JarIcon(size: 14)
                                    Text((jar.icon ?? "") + " " + (jar.name ?? ""))
                                }
                                    .font(.caption)
                                    .chipStyle()
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .cardStyle()
        .scaleEffect(pulse ? 1.03 : 1.0)
        .onReceive(NotificationCenter.default.publisher(for: .jarAddedPing)) { notif in
            guard let id = notif.object as? NSManagedObjectID, id == note.objectID else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                pulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation {
                    pulse = false
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

private extension NoteListView {
    var headerTitle: some View {
        HStack {
            Text("Wishkeep ✨")
                .largeTitle()
                .scaleEffect(animateTitle ? 1.02 : 1.0)
                .opacity(animateTitle ? 1 : 0.9)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
                        animateTitle.toggle()
                    }
                }
            Spacer()
        }
        .padding(.horizontal, Theme.Metrics.padding)
        .padding(.top, 8)
    }

    var jarChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { activeJarId = nil }) {
                    Text("All")
                        .chipStyle(active: activeJarId == nil)
                }
                ForEach(jars) { jar in
                    let active = activeJarId == jar.objectID
                    Button(action: { activeJarId = active ? nil : jar.objectID }) {
                        Text((jar.icon ?? "") + " " + (jar.name ?? ""))
                            .chipStyle(active: active)
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.padding)
        }
    }

    func filteredNotes() -> [Note] {
        let base = Array(notes)
        guard let id = activeJarId, let jar = jars.first(where: { $0.objectID == id }) else { return base }
        return base.filter { ($0.jars as? Set<Jar>)?.contains(jar) ?? false }
    }

    @ViewBuilder
    func noteRowLink(_ note: Note) -> some View {
        NavigationLink(destination: NoteDetailView(note: note)) {
            NoteRow(
                note: note,
                isEditing: editingNoteId == note.objectID,
                nameDraft: $editedName,
                onStartEdit: { startEditing(note) },
                onCommit: { saveEditedName() }
            )
            .focused($nameFieldFocused)
        }
        .swipeActions(edge: .trailing) {
            Button {
                selectedNoteForJar = note
                showJarPicker = true
            } label: { Label("Add to Jar", systemImage: "tray.and.arrow.down") }
            .tint(.blue)
        }
        .listRowSeparator(.hidden)
        .padding(.vertical, 4)
    }

    struct MemoryMomentCard: View {
        let note: Note
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Favorite")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(note.contactName ?? "")
                    .foregroundStyle(.white.opacity(0.95))
                Text(note.text ?? "")
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

