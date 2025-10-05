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
    @State private var pickedColor: Color = .blue.opacity(0.5)
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
                HStack {
                    JarIcon(size: 18)
                    TextField("Emoji", text: $newIcon)
                }
                TextField("Name", text: $newName)
                VStack(alignment: .leading) {
                    Text("Color")
                    HStack {
                        ForEach(palette, id: \.self) { c in
                            Circle()
                                .fill(c)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.primary.opacity(0.1)))
                                .onTapGesture { pickedColor = c }
                                .padding(2)
                        }
                    }
                }
            }
            .navigationTitle("New Jar")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let hex = pickedColor.toHexString()
                        do { _ = try JarStore.shared.create(name: newName, icon: newIcon.isEmpty ? nil : newIcon, colorHex: hex, context: viewContext); showCreate = false }
                        catch { }
                    }
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showCreate = false } }
            }
        }
    }
    private var palette: [Color] { [.pink.opacity(0.5), .purple.opacity(0.5), .blue.opacity(0.5), .teal.opacity(0.5), .green.opacity(0.5), .orange.opacity(0.5)] }
}

private extension Color {
    func toHexString() -> String? {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(r * 255), gi = Int(g * 255), bi = Int(b * 255)
        return String(format: "#%02X%02X%02X", ri, gi, bi)
        #else
        return nil
        #endif
    }
}


