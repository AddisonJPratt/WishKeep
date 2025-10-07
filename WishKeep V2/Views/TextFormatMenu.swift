import SwiftUI

struct TextFormatMenu: View {
    @Environment(\.dismiss) private var dismiss
    var onBody: () -> Void
    var onTitle: () -> Void
    var onSubtitle: () -> Void
    var onList: () -> Void
    var onIndent: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Text Style") {
                    Button("Body") { onBody(); dismiss() }
                    Button("Title") { onTitle(); dismiss() }
                    Button("Subtitle") { onSubtitle(); dismiss() }
                }
                Section("Structure") {
                    Button("Bullet List") { onList(); dismiss() }
                    Button("Indent") { onIndent(); dismiss() }
                }
            }
            .navigationTitle("Formatting")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button("Done") { dismiss() } } }
        }
    }
}


