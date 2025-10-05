import SwiftUI
internal import CoreData

struct JarPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Jar.entity(), sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)])
    private var jars: FetchedResults<Jar>

    let note: Note
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    @State private var newIcon: String = ""
    @State private var showCreate: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(jars) { jar in
                    Button(action: { toggle(jar) }) {
                        HStack {
                            Text((jar.icon ?? "") + " " + (jar.name ?? ""))
                            Spacer()
                            if isSelected(jar) { Image(systemName: "checkmark") }
                        }
                    }
                }
                Section {
                    Button { showCreate = true } label: { Label("Create new", systemImage: "plus") }
                }
            }
            .navigationTitle("Add to Jar")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showCreate) { createSheet }
        }
    }

    private func isSelected(_ jar: Jar) -> Bool {
        (note.jars as? Set<Jar>)?.contains(jar) ?? false
    }
    private func toggle(_ jar: Jar) {
        if isSelected(jar) { JarStore.shared.remove(note, from: jar, context: viewContext) }
        else { JarStore.shared.add(note, to: jar, context: viewContext) }
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
                        do { _ = try JarStore.shared.create(name: newName, icon: newIcon.isEmpty ? nil : newIcon, colorHex: nil, context: viewContext); showCreate = false }
                        catch { }
                    }
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showCreate = false } }
            }
        }
    }
}


