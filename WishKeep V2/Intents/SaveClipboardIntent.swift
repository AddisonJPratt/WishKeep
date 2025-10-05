import Foundation
import AppIntents
internal import CoreData

struct SaveClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Save Clipboard to Wishkeep"
    static var description = IntentDescription("Saves the current clipboard text to Wishkeep and merges with recent screenshots if appropriate.")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            let context = PersistenceController.shared.container.viewContext
            ClipboardManager.shared.saveClipboardIfAvailable(context: context)
        }
        return .result()
    }
}

struct WishkeepShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SaveClipboardIntent(), phrases: [
            "Save Clipboard in \(.applicationName)",
            "Save to \(.applicationName)",
            "Save clipboard to \(.applicationName)"
        ], shortTitle: "Save Clipboard", systemImageName: "doc.on.clipboard")
    }
}

