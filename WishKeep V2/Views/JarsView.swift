import SwiftUI
internal import CoreData

struct JarsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Jar.entity(), sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true), NSSortDescriptor(key: "name", ascending: true)])
    private var jars: FetchedResults<Jar>

    @FetchRequest(entity: Note.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateCaptured, ascending: false)])
    private var allNotes: FetchedResults<Note>

    @State private var showingCreate: Bool = false
    @State private var newName: String = ""
    @State private var newIcon: String = ""

    var body: some View {
        List {
            Section("Smart") {
                NavigationLink(destination: JarNotesView(selectedJar: nil, filter: .all)) {
                    HStack { Label("All", systemImage: "tray.full"); Spacer(); Text("\(allNotes.count)") }
                }
                NavigationLink(destination: JarNotesView(selectedJar: nil, filter: .inbox)) {
                    HStack { Label("Inbox (Unsorted)", systemImage: "tray"); Spacer(); Text("\(unsortedCount())") }
                }
            }
            Section("Your Jars") {
                ForEach(jars) { jar in
                    NavigationLink(destination: JarNotesView(selectedJar: jar, filter: .jar(jar))) {
                        HStack {
                            if let imgName = "Icon_Jar" as String? { JarIcon(size: 18) }
                            Text((jar.icon ?? "") + " " + (jar.name ?? ""))
                            Spacer()
                            Text("\(((jar.notes as? Set<Note>)?.count ?? 0))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
                Button { showingCreate = true } label: { Label("New Jar", systemImage: "plus") }
            }
        }
        .navigationTitle("Jars")
        .toolbar { EditButton() }
        .sheet(isPresented: $showingCreate) { createSheet }
    }

    private func unsortedCount() -> Int {
        allNotes.filter { ($0.jars as? Set<Jar>)?.isEmpty ?? true }.count
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets { viewContext.delete(jars[idx]) }
        try? viewContext.save()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var array = Array(jars)
        array.move(fromOffsets: source, toOffset: destination)
        JarStore.shared.reorder(array, context: viewContext)
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                TextField("Emoji", text: $newIcon)
                TextField("Name", text: $newName)
            }
            .navigationTitle("New Jar")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do { _ = try JarStore.shared.create(name: newName, icon: newIcon.isEmpty ? nil : newIcon, colorHex: nil, context: viewContext); showingCreate = false; newName = ""; newIcon = "" } catch { }
                    }
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreate = false } }
            }
        }
    }
}

struct JarNotesView: View {
    enum Filter { case all, inbox, jar(Jar) }

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Jar.entity(), sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true), NSSortDescriptor(key: "name", ascending: true)])
    private var jars: FetchedResults<Jar>

    @FetchRequest(entity: Note.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Note.dateCaptured, ascending: false)])
    private var allNotes: FetchedResults<Note>

    var selectedJar: Jar?
    var filter: Filter
    @State private var topFilter: Int = 0 // 0=All,1=Inbox
    @State private var activeJarId: NSManagedObjectID?

    var body: some View {
        VStack {
            Picker("Mode", selection: $topFilter) {
                Text("All").tag(0)
                Text("Inbox").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(jars) { jar in
                        let isActive = activeJarId == jar.objectID
                        Button(action: { activeJarId = jar.objectID }) {
                            Text((jar.icon ?? "") + " " + (jar.name ?? ""))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(isActive ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground)))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }

            List(filteredNotes()) { note in
                NavigationLink(destination: NoteDetailView(note: note)) {
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
                        VStack(alignment: .leading) {
                            Text(note.contactName ?? "Unnamed").font(.headline)
                            Text(note.text ?? "[pending OCR]").lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(title())
    }

    private func title() -> String {
        if let j = selectedJar { return (j.icon ?? "") + " " + (j.name ?? "Jar") }
        switch filter { case .all: return "All"; case .inbox: return "Inbox"; default: return "Notes" }
    }

    private func filteredNotes() -> [Note] {
        let base = Array(allNotes)
        // top filter
        let topFiltered = topFilter == 1 ? base.filter { ($0.jars as? Set<Jar>)?.isEmpty ?? true } : base
        if let id = activeJarId, let jar = jars.first(where: { $0.objectID == id }) {
            return topFiltered.filter { ($0.jars as? Set<Jar>)?.contains(jar) ?? false }
        }
        switch filter {
        case .all: return topFiltered
        case .inbox: return topFiltered.filter { ($0.jars as? Set<Jar>)?.isEmpty ?? true }
        case .jar(let j): return topFiltered.filter { ($0.jars as? Set<Jar>)?.contains(j) ?? false }
        }
    }
}


