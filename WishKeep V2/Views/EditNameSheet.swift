import SwiftUI

struct EditNameSheet: View {
    @Binding var name: String
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Name")) {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Focus the text field when the sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    private func save() {
        onSave()
        // Parent may also dismiss in its save handler, but dismiss here to be safe.
        dismiss()
    }
}

#Preview {
    StatefulPreviewWrapper("") { binding in
        EditNameSheet(name: binding, onSave: {})
    }
}

// Helper for binding previews
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
